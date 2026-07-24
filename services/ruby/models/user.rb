require 'bcrypt'

module Models
  class User
    attr_accessor :id, :email, :password_hash, :created_at, :updated_at

    def initialize(attributes = {})
      @id = attributes[:id]
      @email = attributes[:email]
      @password_hash = attributes[:password_hash]
      @created_at = attributes[:created_at] || Time.now
      @updated_at = attributes[:updated_at] || Time.now
    end

    def password=(new_password)
      @password_hash = BCrypt::Password.create(new_password)
    end

    def authenticate(password)
      BCrypt::Password.new(@password_hash) == password
    rescue BCrypt::Errors::InvalidHash
      false
    end

    def to_h
      {
        id: @id,
        email: @email,
        created_at: @created_at,
        updated_at: @updated_at
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
