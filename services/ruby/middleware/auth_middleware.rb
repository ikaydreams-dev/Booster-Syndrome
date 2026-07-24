module Middleware
  class AuthMiddleware
    def initialize(app, token_manager)
      @app = app
      @token_manager = token_manager
    end

    def call(env)
      return @app.call(env) if public_path?(env['PATH_INFO'])

      token = extract_token(env)
      
      unless token
        return [401, { 'Content-Type' => 'application/json' }, 
                [{ error: 'No token provided' }.to_json]]
      end

      result = @token_manager.verify(token)
      
      if result.success?
        env['current_user'] = result.value
        @app.call(env)
      else
        [401, { 'Content-Type' => 'application/json' }, 
         [{ error: 'Invalid token' }.to_json]]
      end
    end

    private

    def extract_token(env)
      auth_header = env['HTTP_AUTHORIZATION']
      return nil unless auth_header
      
      match = auth_header.match(/^Bearer (.+)$/)
      match[1] if match
    end

    def public_path?(path)
      public_paths = ['/auth/login', '/auth/register', '/health']
      public_paths.any? { |p| path.start_with?(p) }
    end
  end
end
