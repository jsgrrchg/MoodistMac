#!/usr/bin/env ruby
# Uses Ruby/OpenSSL from the runner; no external token service or persistent JWT.
require 'openssl'
require 'base64'
require 'json'
require 'net/http'
require 'uri'

key_path, key_id, issuer, app_id, version, build = ARGV
abort 'Expected key path, key ID, issuer, app ID, version and build' unless build
key = OpenSSL::PKey.read(File.read(key_path))
encode = ->(value) { Base64.urlsafe_encode64(value, padding: false) }
request = lambda do |route, params|
  now = Time.now.to_i
  header = encode.call(JSON.generate(alg: 'ES256', kid: key_id, typ: 'JWT'))
  payload = encode.call(JSON.generate(iss: issuer, iat: now, exp: now + 300, aud: 'appstoreconnect-v1'))
  body = "#{header}.#{payload}"
  der = key.sign('SHA256', body)
  signature = OpenSSL::ASN1.decode(der).value.map { |n| n.value.to_s(2).rjust(32, "\0") }.join
  token = "#{body}.#{encode.call(signature)}"
  uri = URI("https://api.appstoreconnect.apple.com/v1/#{route}")
  uri.query = URI.encode_www_form(params)
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 30, read_timeout: 60) do |http|
    http.get(uri.request_uri, 'Authorization' => "Bearer #{token}")
  end
  abort "App Store Connect returned HTTP #{response.code}; inspect the build in App Store Connect" unless response.is_a?(Net::HTTPSuccess)
  JSON.parse(response.body)
end

90.times do
  releases = request.call('preReleaseVersions', 'filter[app]' => app_id, 'filter[version]' => version, 'filter[platform]' => 'IOS')
  release = releases.fetch('data').find { |r| r.dig('attributes', 'version') == version }
  if release
    builds = request.call('builds', 'filter[app]' => app_id, 'filter[preReleaseVersion]' => release['id'], 'filter[version]' => build)
    found = builds.fetch('data').find { |b| b.dig('attributes', 'version') == build }
    state = found&.dig('attributes', 'processingState')
    if state == 'VALID'
      puts "App Store Connect processed iOS #{version} (#{build}), build ID #{found['id']}. Tester assignment/review is separate."
      exit 0
    end
    abort "Apple processing failed for #{version} (#{build}): #{state}" if %w[FAILED INVALID].include?(state)
    puts "Waiting for iOS #{version} (#{build}): #{state || 'not visible yet'}"
  else
    puts "Waiting for iOS #{version} to appear in App Store Connect"
  end
  sleep 20
end
abort 'Processing exceeded 30 minutes. Upload may have succeeded; check App Store Connect before retrying.'
