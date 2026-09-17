#!/usr/bin/env ruby
# Uses Ruby/OpenSSL from the runner; no external token service or persistent JWT.
require_relative 'app-store-connect'

key_path, key_id, issuer, app_id, version, build = ARGV
abort 'Expected key path, key ID, issuer, app ID, version and build' unless build
begin
  client = AppStoreConnect.new(private_key: File.read(key_path), key_id: key_id, issuer: issuer)
  request = ->(route, params) { client.get(route, params) }

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

rescue AppStoreConnect::Error
  abort 'App Store Connect processing check failed. Verify API credentials/access and inspect the uploaded build before retrying.'
end
