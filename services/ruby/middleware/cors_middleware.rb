module Middleware
  class CorsMiddleware
    def initialize(app, allowed_origins: ['*'], allowed_methods: nil, allowed_headers: nil)
      @app = app
      @allowed_origins = allowed_origins
      @allowed_methods = allowed_methods || ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH']
      @allowed_headers = allowed_headers || ['Content-Type', 'Authorization', 'X-Requested-With']
    end

    def call(env)
      origin = env['HTTP_ORIGIN']
      
      if env['REQUEST_METHOD'] == 'OPTIONS'
        return [
          204,
          cors_headers(origin),
          []
        ]
      end
      
      status, headers, body = @app.call(env)
      headers.merge!(cors_headers(origin))
      
      [status, headers, body]
    end

    private

    def cors_headers(origin)
      headers = {}
      
      if origin_allowed?(origin)
        headers['Access-Control-Allow-Origin'] = origin || @allowed_origins.first
        headers['Access-Control-Allow-Methods'] = @allowed_methods.join(', ')
        headers['Access-Control-Allow-Headers'] = @allowed_headers.join(', ')
        headers['Access-Control-Allow-Credentials'] = 'true'
        headers['Access-Control-Max-Age'] = '86400'
      end
      
      headers
    end

    def origin_allowed?(origin)
      return true if @allowed_origins.include?('*')
      return false unless origin
      
      @allowed_origins.include?(origin)
    end
  end
end
