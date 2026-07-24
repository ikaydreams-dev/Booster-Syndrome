require 'redis'

module Middleware
  class RateLimitMiddleware
    def initialize(app, redis: nil, max_requests: 100, window: 60)
      @app = app
      @redis = redis || Redis.new
      @max_requests = max_requests
      @window = window
    end

    def call(env)
      identifier = get_identifier(env)
      key = "rate_limit:#{identifier}"
      
      current = @redis.get(key).to_i
      
      if current >= @max_requests
        remaining_ttl = @redis.ttl(key)
        return [
          429,
          {
            'Content-Type' => 'application/json',
            'X-RateLimit-Limit' => @max_requests.to_s,
            'X-RateLimit-Remaining' => '0',
            'X-RateLimit-Reset' => (Time.now.to_i + remaining_ttl).to_s
          },
          [{ error: 'Rate limit exceeded' }.to_json]
        ]
      end
      
      @redis.multi do |r|
        r.incr(key)
        r.expire(key, @window) if current == 0
      end
      
      status, headers, body = @app.call(env)
      
      headers['X-RateLimit-Limit'] = @max_requests.to_s
      headers['X-RateLimit-Remaining'] = (@max_requests - current - 1).to_s
      headers['X-RateLimit-Reset'] = (Time.now.to_i + @window).to_s
      
      [status, headers, body]
    end

    private

    def get_identifier(env)
      env['current_user']&.[](:id) || env['REMOTE_ADDR']
    end
  end
end
