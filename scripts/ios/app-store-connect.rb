# Shared read-only App Store Connect client. Never log credentials or API bodies.
require 'openssl'
require 'base64'
require 'json'
require 'net/http'
require 'uri'

class AppStoreConnect
  class Error < StandardError; end

  def initialize(private_key:, key_id:, issuer:, transport: nil)
    @key = OpenSSL::PKey.read(private_key)
    unless @key.is_a?(OpenSSL::PKey::EC) && @key.private? && @key.group.curve_name == 'prime256v1'
      raise Error, 'APPLE_API_KEY_BASE64 must contain a private P-256 App Store Connect key.'
    end
    @key_id, @issuer, @transport = key_id, issuer, transport
  rescue OpenSSL::PKey::PKeyError, OpenSSL::PKey::ECError, ArgumentError
    raise Error, 'Unable to decode the App Store Connect private key.'
  end

  def get(route, params = {})
    uri = URI("https://api.appstoreconnect.apple.com/v1/#{route}")
    uri.query = URI.encode_www_form(params) unless params.empty?
    headers = { 'Authorization' => "Bearer #{token}" }
    response = if @transport
      @transport.call(uri, headers)
    else
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 30, read_timeout: 60) do |http|
        http.get(uri.request_uri, headers)
      end
    end
    case response.code.to_i
    when 200..299 then JSON.parse(response.body)
    when 401 then raise Error, 'Apple API authentication failed (HTTP 401). Check the existing APPLE_API_* secrets and whether the key was revoked.'
    when 403 then raise Error, 'Apple API access denied (HTTP 403). Check the key role and App Store Connect permissions.'
    when 404 then raise Error, 'Apple API resource not found (HTTP 404). Check ASC_APP_ID and app access.'
    else raise Error, "Apple API request failed (HTTP #{response.code.to_i}); retry or inspect App Store Connect."
    end
  rescue JSON::ParserError
    raise Error, 'Apple API returned an invalid JSON response.'
  rescue IOError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
    raise Error, 'Unable to reach App Store Connect securely; retry the access check.'
  end

  private

  def token
    encode = ->(value) { Base64.urlsafe_encode64(value, padding: false) }
    now = Time.now.to_i
    header = encode.call(JSON.generate(alg: 'ES256', kid: @key_id, typ: 'JWT'))
    payload = encode.call(JSON.generate(iss: @issuer, iat: now, exp: now + 300, aud: 'appstoreconnect-v1'))
    body = "#{header}.#{payload}"
    signature = OpenSSL::ASN1.decode(@key.sign('SHA256', body)).value.map { |n| n.value.to_s(2).rjust(32, "\0") }.join
    "#{body}.#{encode.call(signature)}"
  end
end
