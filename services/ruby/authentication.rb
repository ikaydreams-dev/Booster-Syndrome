require 'openssl'
require 'securerandom'
require 'base64'
require 'json'

module Authentication
  class PasswordHasher
    ITERATIONS = 100_000
    DIGEST = OpenSSL::Digest::SHA256

    def self.hash(password, salt: nil)
      salt ||= SecureRandom.hex(16)
      hash = OpenSSL::PKCS5.pbkdf2_hmac(
        password,
        salt,
        ITERATIONS,
        DIGEST.new.digest_length,
        DIGEST.new
      )

      encoded_hash = Base64.strict_encode64(hash)
      "#{salt}$#{encoded_hash}"
    end

    def self.verify(password, stored_hash)
      salt, encoded_hash = stored_hash.split('$')
      return false unless salt && encoded_hash

      new_hash = hash(password, salt: salt)
      secure_compare(new_hash, stored_hash)
    end

    private

    def self.secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      result = 0
      a.bytes.zip(b.bytes).each do |x, y|
        result |= x ^ y
      end
      result == 0
    end
  end

  class JWT
    ALGORITHM = 'HS256'

    def self.encode(payload, secret, exp: 3600)
      payload = payload.merge(
        exp: Time.now.to_i + exp,
        iat: Time.now.to_i
      )

      header = { alg: ALGORITHM, typ: 'JWT' }

      encoded_header = base64_url_encode(header.to_json)
      encoded_payload = base64_url_encode(payload.to_json)

      signature = sign("#{encoded_header}.#{encoded_payload}", secret)
      encoded_signature = base64_url_encode(signature)

      "#{encoded_header}.#{encoded_payload}.#{encoded_signature}"
    end

    def self.decode(token, secret, verify: true)
      header_b64, payload_b64, signature_b64 = token.split('.')
      return nil unless header_b64 && payload_b64 && signature_b64

      if verify
        expected_signature = sign("#{header_b64}.#{payload_b64}", secret)
        actual_signature = base64_url_decode(signature_b64)

        return nil unless secure_compare(expected_signature, actual_signature)
      end

      payload_json = base64_url_decode(payload_b64)
      payload = JSON.parse(payload_json, symbolize_names: true)

      if verify && payload[:exp]
        return nil if Time.now.to_i > payload[:exp]
      end

      payload
    rescue JSON::ParserError
      nil
    end

    private

    def self.base64_url_encode(data)
      Base64.urlsafe_encode64(data, padding: false)
    end

    def self.base64_url_decode(data)
      Base64.urlsafe_decode64(data)
    end

    def self.sign(data, secret)
      OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), secret, data)
    end

    def self.secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      result = 0
      a.bytes.zip(b.bytes).each do |x, y|
        result |= x ^ y
      end
      result == 0
    end
  end

  class SessionStore
    def initialize
      @sessions = {}
      @mutex = Mutex.new
    end

    def create(user_id, data: {})
      session_id = SecureRandom.uuid

      @mutex.synchronize do
        @sessions[session_id] = {
          id: session_id,
          user_id: user_id,
          data: data,
          created_at: Time.now,
          last_accessed: Time.now
        }
      end

      session_id
    end

    def get(session_id)
      @mutex.synchronize do
        session = @sessions[session_id]
        if session
          session[:last_accessed] = Time.now
          session
        end
      end
    end

    def update(session_id, data)
      @mutex.synchronize do
        session = @sessions[session_id]
        if session
          session[:data].merge!(data)
          session[:last_accessed] = Time.now
        end
      end
    end

    def destroy(session_id)
      @mutex.synchronize do
        @sessions.delete(session_id)
      end
    end

    def cleanup(max_age: 3600)
      cutoff = Time.now - max_age

      @mutex.synchronize do
        @sessions.delete_if do |_, session|
          session[:last_accessed] < cutoff
        end
      end
    end

    def exists?(session_id)
      @mutex.synchronize do
        @sessions.key?(session_id)
      end
    end

    def clear
      @mutex.synchronize do
        @sessions.clear
      end
    end
  end

  class TokenGenerator
    def self.generate(length: 32)
      SecureRandom.hex(length)
    end

    def self.generate_url_safe(length: 32)
      SecureRandom.urlsafe_base64(length)
    end

    def self.generate_numeric(length: 6)
      SecureRandom.random_number(10**length).to_s.rjust(length, '0')
    end
  end

  class OAuth2
    class AuthorizationCode
      attr_reader :code, :client_id, :redirect_uri, :scope, :user_id

      def initialize(client_id:, redirect_uri:, scope:, user_id:)
        @code = TokenGenerator.generate
        @client_id = client_id
        @redirect_uri = redirect_uri
        @scope = scope
        @user_id = user_id
        @created_at = Time.now
        @used = false
      end

      def valid?
        !@used && (Time.now - @created_at) < 600
      end

      def use!
        @used = true
      end
    end

    class AccessToken
      attr_reader :token, :refresh_token, :scope, :user_id

      def initialize(user_id:, scope:, expires_in: 3600)
        @token = TokenGenerator.generate
        @refresh_token = TokenGenerator.generate
        @user_id = user_id
        @scope = scope
        @expires_at = Time.now + expires_in
      end

      def valid?
        Time.now < @expires_at
      end

      def expired?
        !valid?
      end
    end

    class Server
      def initialize
        @codes = {}
        @tokens = {}
        @clients = {}
      end

      def register_client(client_id, client_secret, redirect_uris)
        @clients[client_id] = {
          secret: client_secret,
          redirect_uris: redirect_uris
        }
      end

      def authorize(client_id:, redirect_uri:, scope:, user_id:)
        client = @clients[client_id]
        return nil unless client
        return nil unless client[:redirect_uris].include?(redirect_uri)

        code = AuthorizationCode.new(
          client_id: client_id,
          redirect_uri: redirect_uri,
          scope: scope,
          user_id: user_id
        )

        @codes[code.code] = code
        code.code
      end

      def exchange_code(code:, client_id:, client_secret:, redirect_uri:)
        auth_code = @codes[code]
        return nil unless auth_code
        return nil unless auth_code.valid?
        return nil unless auth_code.client_id == client_id

        client = @clients[client_id]
        return nil unless client
        return nil unless client[:secret] == client_secret
        return nil unless auth_code.redirect_uri == redirect_uri

        auth_code.use!

        token = AccessToken.new(
          user_id: auth_code.user_id,
          scope: auth_code.scope
        )

        @tokens[token.token] = token
        @codes.delete(code)

        {
          access_token: token.token,
          refresh_token: token.refresh_token,
          token_type: 'Bearer',
          expires_in: 3600
        }
      end

      def verify_token(token)
        access_token = @tokens[token]
        return nil unless access_token
        return nil unless access_token.valid?

        access_token
      end

      def refresh_token(refresh_token)
        token = @tokens.values.find { |t| t.refresh_token == refresh_token }
        return nil unless token

        @tokens.delete(token.token)

        new_token = AccessToken.new(
          user_id: token.user_id,
          scope: token.scope
        )

        @tokens[new_token.token] = new_token

        {
          access_token: new_token.token,
          refresh_token: new_token.refresh_token,
          token_type: 'Bearer',
          expires_in: 3600
        }
      end

      def revoke_token(token)
        @tokens.delete(token)
      end
    end
  end

  class TwoFactorAuth
    def self.generate_secret(length: 16)
      Base32.encode(SecureRandom.random_bytes(length))
    end

    def self.generate_totp(secret, time: Time.now, period: 30)
      counter = (time.to_i / period).to_i
      hmac = OpenSSL::HMAC.digest(
        OpenSSL::Digest.new('SHA1'),
        Base32.decode(secret),
        [counter].pack('Q>')
      )

      offset = hmac[-1].ord & 0x0f
      code = (hmac[offset, 4].unpack1('N') & 0x7fffffff) % 1_000_000
      code.to_s.rjust(6, '0')
    end

    def self.verify_totp(secret, code, time: Time.now, window: 1)
      (-window..window).any? do |offset|
        expected = generate_totp(secret, time: time + offset * 30)
        secure_compare(expected, code)
      end
    end

    private

    def self.secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      result = 0
      a.bytes.zip(b.bytes).each do |x, y|
        result |= x ^ y
      end
      result == 0
    end
  end

  module Base32
    ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'

    def self.encode(data)
      bits = data.bytes.map { |b| b.to_s(2).rjust(8, '0') }.join
      result = ''

      bits.scan(/.{1,5}/) do |chunk|
        chunk = chunk.ljust(5, '0')
        result << ALPHABET[chunk.to_i(2)]
      end

      result
    end

    def self.decode(str)
      bits = str.upcase.chars.map do |char|
        ALPHABET.index(char).to_s(2).rjust(5, '0')
      end.join

      bits.scan(/.{8}/).map { |byte| byte.to_i(2).chr }.join
    end
  end
end
