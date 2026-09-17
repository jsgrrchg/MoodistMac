#!/usr/bin/env ruby
require_relative 'app-store-connect'

module AppleAccessCheck
  BUNDLE_ID = 'com.josegurruchaga.MoodistIOS'.freeze
  REQUIRED = %w[APPLE_API_KEY_ID APPLE_API_ISSUER_ID APPLE_API_KEY_BASE64 APPLE_TEAM_ID].freeze

  def self.run(env: ENV, output: $stdout, client: nil)
    missing = REQUIRED.select { |name| env[name].to_s.empty? }
    raise AppStoreConnect::Error, "Missing existing GitHub secrets: #{missing.join(', ')}" unless missing.empty?
    unless env['APPLE_TEAM_ID'].match?(/\A[A-Z0-9]{10}\z/)
      raise AppStoreConnect::Error, 'APPLE_TEAM_ID must be a 10-character Apple team identifier.'
    end
    client ||= AppStoreConnect.new(private_key: Base64.strict_decode64(env['APPLE_API_KEY_BASE64'].gsub(/\s/, '')),
                                  key_id: env['APPLE_API_KEY_ID'], issuer: env['APPLE_API_ISSUER_ID'])
    result = client.get('apps', 'filter[bundleId]' => BUNDLE_ID, 'fields[apps]' => 'bundleId', 'limit' => '2')
    output.puts 'Apple API authentication and app-list access succeeded using the existing APPLE_API_* secrets.'
    apps = result.fetch('data')
    app = apps.find { |item| item.dig('attributes', 'bundleId') == BUNDLE_ID }
    unless app && apps.length == 1
      raise AppStoreConnect::Error, 'Moodist iOS is not uniquely accessible in App Store Connect. Create its app record or check app access; build permissions have not been verified.'
    end
    app_id = app.fetch('id')
    unless app_id.match?(/\A[0-9]+\z/)
      raise AppStoreConnect::Error, 'Apple returned an invalid app identifier.'
    end
    configured = env['ASC_APP_ID'].to_s
    if !configured.empty? && configured != app_id
      raise AppStoreConnect::Error, 'ASC_APP_ID does not match the Moodist iOS bundle identifier.'
    end
    builds = client.get('builds', 'filter[app]' => app_id, 'limit' => '1')
    raise AppStoreConnect::Error, 'Apple returned an invalid build list.' unless builds['data'].is_a?(Array)
    output.puts "Moodist iOS app access and build-list access succeeded. ASC_APP_ID=#{app_id}"
    output.puts 'No data was changed or uploaded. Read access does not prove upload authorization; confirm the key role permits uploading builds.'
    output.puts 'The signing profile will validate APPLE_TEAM_ID against the certificate/app configuration during release.'
    app_id
  rescue ArgumentError
    raise AppStoreConnect::Error, 'APPLE_API_KEY_BASE64 is not valid Base64.'
  rescue KeyError, NoMethodError
    raise AppStoreConnect::Error, 'Apple API returned an unexpected app response.'
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    AppleAccessCheck.run
  rescue AppStoreConnect::Error => error
    warn error.message
    exit 1
  end
end
