#!/usr/bin/env ruby
require 'minitest/autorun'
require 'stringio'
require 'yaml'
require_relative 'check-apple-access'

class AppleAccessTests < Minitest::Test
  Response = Struct.new(:code, :body)
  class FakeClient
    attr_reader :calls
    def initialize(apps:, builds: { 'data' => [] }, deny_builds: false)
      @apps, @builds, @deny_builds, @calls = apps, builds, deny_builds, []
    end
    def get(route, params)
      @calls << [route, params]
      return @apps if route == 'apps'
      raise AppStoreConnect::Error, 'Apple API access denied (HTTP 403).' if @deny_builds
      raise "Unexpected route #{route}" unless route == 'builds'
      @builds
    end
  end

  def env
    { 'APPLE_API_KEY_ID' => 'TESTKEY', 'APPLE_API_ISSUER_ID' => 'test-issuer',
      'APPLE_API_KEY_BASE64' => Base64.strict_encode64('fixture'), 'APPLE_TEAM_ID' => 'TESTTEAM01' }
  end

  def apps
    { 'data' => [{ 'id' => '123456', 'attributes' => { 'bundleId' => AppleAccessCheck::BUNDLE_ID } }] }
  end

  def test_authentication_and_empty_build_list_are_valid_read_access
    client = FakeClient.new(apps: apps)
    output = StringIO.new
    assert_equal '123456', AppleAccessCheck.run(env: env, client: client, output: output)
    assert_equal %w[apps builds], client.calls.map(&:first)
    assert_equal '123456', client.calls.last[1]['filter[app]']
    assert_includes output.string, 'does not prove upload authorization'
    refute_includes output.string, env['APPLE_API_KEY_BASE64']
  end

  def test_missing_app_is_distinct_from_invalid_authentication
    output = StringIO.new
    client = FakeClient.new(apps: { 'data' => [] })
    error = assert_raises(AppStoreConnect::Error) { AppleAccessCheck.run(env: env, client: client, output: output) }
    assert_includes output.string, 'authentication and app-list access succeeded'
    assert_includes error.message, 'build permissions have not been verified'
    assert_equal 1, client.calls.length
  end

  def test_wrong_app_id_is_rejected_before_build_request
    client = FakeClient.new(apps: apps)
    error = assert_raises(AppStoreConnect::Error) do
      AppleAccessCheck.run(env: env.merge('ASC_APP_ID' => '999'), client: client, output: StringIO.new)
    end
    assert_includes error.message, 'does not match'
    assert_equal 1, client.calls.length
  end

  def test_denied_build_access_fails
    client = FakeClient.new(apps: apps, deny_builds: true)
    assert_raises(AppStoreConnect::Error) { AppleAccessCheck.run(env: env, client: client, output: StringIO.new) }
  end

  def test_missing_shared_secret_fails_without_a_request
    client = FakeClient.new(apps: apps)
    error = assert_raises(AppStoreConnect::Error) do
      AppleAccessCheck.run(env: env.reject { |k, _| k == 'APPLE_API_KEY_BASE64' }, client: client)
    end
    assert_includes error.message, 'APPLE_API_KEY_BASE64'
    assert_empty client.calls
  end

  def test_invalid_base64_and_non_private_key_fail_without_network
    assert_raises(AppStoreConnect::Error) { AppleAccessCheck.run(env: env.merge('APPLE_API_KEY_BASE64' => '!')) }
    key = OpenSSL::PKey::EC.generate('prime256v1')
    assert_raises(AppStoreConnect::Error) do
      AppStoreConnect.new(private_key: OpenSSL::PKey::RSA.new(1024).public_key.to_pem, key_id: 'key', issuer: 'issuer')
    end
  end

  def test_jwt_signature_and_fixed_https_endpoint
    key = OpenSSL::PKey::EC.generate('prime256v1')
    transport = lambda do |uri, headers|
      assert_equal 'https', uri.scheme
      assert_equal 'api.appstoreconnect.apple.com', uri.host
      assert_equal '/v1/apps', uri.path
      assert_equal [['filter[bundleId]', AppleAccessCheck::BUNDLE_ID]], URI.decode_www_form(uri.query)
      encoded_header, encoded_payload, signature = headers.fetch('Authorization').delete_prefix('Bearer ').split('.')
      payload = JSON.parse(Base64.urlsafe_decode64(encoded_payload))
      assert_equal 'appstoreconnect-v1', payload['aud']
      assert_equal 300, payload['exp'] - payload['iat']
      raw = Base64.urlsafe_decode64(signature)
      assert_equal 64, raw.bytesize
      values = [raw[0, 32], raw[32, 32]].map { |s| OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(s, 2)) }
      assert key.verify('SHA256', OpenSSL::ASN1::Sequence.new(values).to_der, "#{encoded_header}.#{encoded_payload}")
      Response.new('200', '{"data":[]}')
    end
    client = AppStoreConnect.new(private_key: key.to_pem, key_id: 'key', issuer: 'issuer', transport: transport)
    assert_equal({ 'data' => [] }, client.get('apps', 'filter[bundleId]' => AppleAccessCheck::BUNDLE_ID))
  end

  def test_http_errors_do_not_expose_response_body
    key = OpenSSL::PKey::EC.generate('prime256v1')
    %w[401 403 404 429 500].each do |status|
      client = AppStoreConnect.new(private_key: key.to_pem, key_id: 'key', issuer: 'issuer',
                                  transport: ->(_, _) { Response.new(status, 'SECRET_RESPONSE_SENTINEL') })
      error = assert_raises(AppStoreConnect::Error) { client.get('apps') }
      assert_includes error.message, status
      refute_includes error.message, 'SECRET_RESPONSE_SENTINEL'
    end
  end
  def test_release_reuses_existing_secret_names
    workflow = YAML.load_file(File.expand_path('../../.github/workflows/release-ios.yml', __dir__))
    steps = workflow.fetch('jobs').fetch('archive').fetch('steps')
    checks = steps.select { |step| step.fetch('env', {}).key?('APPLE_API_KEY_ID') }
    assert_equal 2, checks.length
    checks.each do |step|
      AppleAccessCheck::REQUIRED.each do |name|
        assert_equal "${{ secrets.#{name} }}", step['env'][name]
      end
    end
  end

  def test_read_only_workflow_does_not_use_pr_events_tags_or_signing_secrets
    workflow = YAML.load_file(File.expand_path('../../.github/workflows/apple-api-access.yml', __dir__))
    triggers = workflow['on'] || workflow[true] # YAML 1.1 treats on as a boolean.
    assert_equal %w[push workflow_dispatch], triggers.keys.sort
    assert triggers['push'].key?('branches')
    refute triggers['push'].key?('tags')
    secrets = workflow.fetch('jobs').fetch('check-access').fetch('steps').flat_map do |step|
      step.fetch('env', {}).keys.grep(/^(APPLE_|IOS_)/)
    end
    assert_equal AppleAccessCheck::REQUIRED.sort, secrets.sort
  end

end
