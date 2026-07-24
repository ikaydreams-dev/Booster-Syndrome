module Validators
  class UserValidator
    def self.validate_create(params)
      errors = []
      
      errors << "Email is required" if params[:email].nil? || params[:email].empty?
      errors << "Email is invalid" unless valid_email?(params[:email])
      errors << "Password is required" if params[:password].nil? || params[:password].empty?
      errors << "Password must be at least 8 characters" if params[:password] && params[:password].length < 8
      errors << "Password must contain uppercase letter" unless params[:password]&.match?(/[A-Z]/)
      errors << "Password must contain lowercase letter" unless params[:password]&.match?(/[a-z]/)
      errors << "Password must contain number" unless params[:password]&.match?(/[0-9]/)
      
      errors
    end

    def self.validate_update(params)
      errors = []
      
      if params[:email]
        errors << "Email is invalid" unless valid_email?(params[:email])
      end
      
      if params[:password]
        errors << "Password must be at least 8 characters" if params[:password].length < 8
        errors << "Password must contain uppercase letter" unless params[:password].match?(/[A-Z]/)
        errors << "Password must contain lowercase letter" unless params[:password].match?(/[a-z]/)
        errors << "Password must contain number" unless params[:password].match?(/[0-9]/)
      end
      
      errors
    end

    private

    def self.valid_email?(email)
      return false unless email
      email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    end
  end
end
