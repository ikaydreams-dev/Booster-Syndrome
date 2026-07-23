require 'openssl'
require 'base64'
require 'json'

module Secrets
  class Vault
    def initialize(master_key)
      @master_key = master_key
      @secrets = {}
      @mutex = Mutex.new
    end

    def set(key, value)
      @mutex.synchronize do
        encrypted = encrypt(value.to_s)
        @secrets[key] = encrypted
      end
    end

    def get(key)
      @mutex.synchronize do
        encrypted = @secrets[key]
        return nil unless encrypted

        decrypt(encrypted)
      end
    end

    def delete(key)
      @mutex.synchronize do
        @secrets.delete(key)
      end
    end

    def exists?(key)
      @mutex.synchronize do
        @secrets.key?(key)
      end
    end

    def list_keys
      @mutex.synchronize do
        @secrets.keys
      end
    end

    def export(encryption_key)
      @mutex.synchronize do
        data = @secrets.to_json
        cipher = OpenSSL::Cipher.new('AES-256-CBC')
        cipher.encrypt
        cipher.key = derive_key(encryption_key)
        iv = cipher.random_iv

        encrypted = cipher.update(data) + cipher.final

        {
          data: Base64.strict_encode64(encrypted),
          iv: Base64.strict_encode64(iv)
        }
      end
    end

    def import(encrypted_data, encryption_key)
      cipher = OpenSSL::Cipher.new('AES-256-CBC')
      cipher.decrypt
      cipher.key = derive_key(encryption_key)
      cipher.iv = Base64.strict_decode64(encrypted_data[:iv])

      encrypted = Base64.strict_decode64(encrypted_data[:data])
      decrypted = cipher.update(encrypted) + cipher.final

      imported = JSON.parse(decrypted)

      @mutex.synchronize do
        @secrets.merge!(imported)
      end
    end

    private

    def encrypt(plaintext)
      cipher = OpenSSL::Cipher.new('AES-256-CBC')
      cipher.encrypt
      cipher.key = derive_key(@master_key)
      iv = cipher.random_iv

      encrypted = cipher.update(plaintext) + cipher.final

      {
        data: Base64.strict_encode64(encrypted),
        iv: Base64.strict_encode64(iv)
      }
    end

    def decrypt(encrypted_data)
      cipher = OpenSSL::Cipher.new('AES-256-CBC')
      cipher.decrypt
      cipher.key = derive_key(@master_key)
      cipher.iv = Base64.strict_decode64(encrypted_data[:iv])

      encrypted = Base64.strict_decode64(encrypted_data[:data])
      cipher.update(encrypted) + cipher.final
    end

    def derive_key(password)
      OpenSSL::PKCS5.pbkdf2_hmac(
        password,
        'salt',
        10000,
        32,
        OpenSSL::Digest::SHA256.new
      )
    end
  end

  class EnvironmentLoader
    def self.load(file_path)
      return {} unless File.exist?(file_path)

      env = {}

      File.readlines(file_path).each do |line|
        line = line.strip
        next if line.empty? || line.start_with?('#')

        key, value = line.split('=', 2)
        next unless key && value

        env[key.strip] = parse_value(value.strip)
      end

      env
    end

    def self.save(env, file_path)
      File.open(file_path, 'w') do |f|
        env.each do |key, value|
          f.puts "#{key}=#{value}"
        end
      end
    end

    private

    def self.parse_value(value)
      if value.start_with?('"') && value.end_with?('"')
        value[1..-2]
      elsif value.start_with?("'") && value.end_with?("'")
        value[1..-2]
      else
        value
      end
    end
  end

  class ConfigManager
    def initialize(environment: 'development')
      @environment = environment
      @config = {}
      @secrets = {}
      @mutex = Mutex.new
    end

    def load_from_file(file_path)
      return unless File.exist?(file_path)

      data = JSON.parse(File.read(file_path), symbolize_names: true)

      @mutex.synchronize do
        if data[@environment.to_sym]
          @config.merge!(data[@environment.to_sym])
        end

        if data[:shared]
          @config = data[:shared].merge(@config)
        end
      end
    end

    def load_from_env
      @mutex.synchronize do
        ENV.each do |key, value|
          @config[key.downcase.to_sym] = value
        end
      end
    end

    def set(key, value)
      @mutex.synchronize do
        @config[key.to_sym] = value
      end
    end

    def get(key, default = nil)
      @mutex.synchronize do
        @config[key.to_sym] || default
      end
    end

    def get!(key)
      value = get(key)
      raise "Configuration key '#{key}' not found" unless value
      value
    end

    def has_key?(key)
      @mutex.synchronize do
        @config.key?(key.to_sym)
      end
    end

    def all
      @mutex.synchronize do
        @config.dup
      end
    end

    def merge(hash)
      @mutex.synchronize do
        @config.merge!(hash.transform_keys(&:to_sym))
      end
    end
  end

  class SecretRotation
    def initialize(vault)
      @vault = vault
      @rotation_callbacks = {}
    end

    def register_rotation(key, &callback)
      @rotation_callbacks[key] = callback
    end

    def rotate(key)
      callback = @rotation_callbacks[key]
      return false unless callback

      new_value = callback.call

      if new_value
        @vault.set(key, new_value)
        true
      else
        false
      end
    end

    def rotate_all
      results = {}

      @rotation_callbacks.each_key do |key|
        results[key] = rotate(key)
      end

      results
    end
  end

  class AccessControl
    def initialize
      @permissions = Hash.new { |h, k| h[k] = [] }
      @mutex = Mutex.new
    end

    def grant(user, secret_key)
      @mutex.synchronize do
        @permissions[user] << secret_key unless @permissions[user].include?(secret_key)
      end
    end

    def revoke(user, secret_key)
      @mutex.synchronize do
        @permissions[user].delete(secret_key)
      end
    end

    def can_access?(user, secret_key)
      @mutex.synchronize do
        @permissions[user].include?(secret_key)
      end
    end

    def list_permissions(user)
      @mutex.synchronize do
        @permissions[user].dup
      end
    end
  end
end
