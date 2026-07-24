module Middleware
  class ErrorHandlerMiddleware
    def initialize(app, logger: nil)
      @app = app
      @logger = logger || Logger.new(STDOUT)
    end

    def call(env)
      @app.call(env)
    rescue StandardError => e
      log_error(e, env)
      error_response(e)
    end

    private

    def log_error(error, env)
      @logger.error({
        error: error.class.name,
        message: error.message,
        backtrace: error.backtrace&.first(5),
        path: env['PATH_INFO'],
        method: env['REQUEST_METHOD'],
        params: env['rack.request.query_hash']
      }.to_json)
    end

    def error_response(error)
      case error
      when ArgumentError, NoMethodError
        [400, error_headers, [format_error('Bad Request', error)]]
      when SecurityError
        [403, error_headers, [format_error('Forbidden', error)]]
      when Errno::ENOENT
        [404, error_headers, [format_error('Not Found', error)]]
      else
        [500, error_headers, [format_error('Internal Server Error', error)]]
      end
    end

    def error_headers
      { 'Content-Type' => 'application/json' }
    end

    def format_error(type, error)
      {
        error: type,
        message: error.message,
        timestamp: Time.now.iso8601
      }.to_json
    end
  end
end
