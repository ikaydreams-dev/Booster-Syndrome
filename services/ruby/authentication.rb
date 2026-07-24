# Ruby Authentication Service
module Authentication
  class TokenManager
    def initialize(secret_key)
      @secret_key = secret_key
      @tokens = {}
    end

    def generate_token(payload)
      token = SecureRandom.hex(32)
      @tokens[token] = payload
      token
    end

    def validate_token(token)
      @tokens[token]
    end
  end
end
