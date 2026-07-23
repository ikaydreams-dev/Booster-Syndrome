module Web
  class Route
    attr_reader :method, :path, :handler, :params

    def initialize(method, path, handler)
      @method = method.to_s.upcase
      @path = path
      @handler = handler
      @params = {}
      @regex = compile_path_to_regex(path)
    end

    def match?(method, path)
      return false unless @method == method.to_s.upcase

      match = @regex.match(path)
      if match
        @params = match.names.zip(match.captures).to_h
        true
      else
        false
      end
    end

    private

    def compile_path_to_regex(path)
      pattern = path.gsub(/:\w+/) do |param|
        param_name = param[1..-1]
        "(?<#{param_name}>[^/]+)"
      end

      Regexp.new("^#{pattern}$")
    end
  end

  class Router
    def initialize
      @routes = []
      @middleware = []
      @error_handlers = {}
    end

    def get(path, &handler)
      add_route(:GET, path, handler)
    end

    def post(path, &handler)
      add_route(:POST, path, handler)
    end

    def put(path, &handler)
      add_route(:PUT, path, handler)
    end

    def patch(path, &handler)
      add_route(:PATCH, path, handler)
    end

    def delete(path, &handler)
      add_route(:DELETE, path, handler)
    end

    def use(&middleware)
      @middleware << middleware
    end

    def on_error(status, &handler)
      @error_handlers[status] = handler
    end

    def dispatch(method, path, context = {})
      request = { method: method, path: path, params: {}, context: context }

      begin
        @middleware.each do |mw|
          request = mw.call(request)
        end

        route = find_route(method, path)

        if route
          request[:params] = route.params
          route.handler.call(request)
        else
          handle_error(404, request)
        end
      rescue => e
        handle_error(500, request, e)
      end
    end

    private

    def add_route(method, path, handler)
      @routes << Route.new(method, path, handler)
    end

    def find_route(method, path)
      @routes.find { |route| route.match?(method, path) }
    end

    def handle_error(status, request, error = nil)
      if @error_handlers[status]
        @error_handlers[status].call(request, error)
      else
        { status: status, body: error&.message || "Error #{status}" }
      end
    end
  end

  class Middleware
    def self.logger
      ->(request) do
        puts "[#{Time.now}] #{request[:method]} #{request[:path]}"
        request
      end
    end

    def self.cors(origin: '*')
      ->(request) do
        request[:headers] ||= {}
        request[:headers]['Access-Control-Allow-Origin'] = origin
        request[:headers]['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE'
        request
      end
    end

    def self.auth(token_validator)
      ->(request) do
        auth_header = request.dig(:headers, 'Authorization')

        if auth_header && auth_header.start_with?('Bearer ')
          token = auth_header.split(' ')[1]
          if token_validator.call(token)
            request[:user] = { authenticated: true }
          else
            raise 'Unauthorized'
          end
        else
          raise 'Missing authorization header'
        end

        request
      end
    end

    def self.rate_limit(max_requests: 100, window: 60)
      requests = Hash.new { |h, k| h[k] = [] }

      ->(request) do
        ip = request[:ip] || 'unknown'
        now = Time.now

        requests[ip].reject! { |time| now - time > window }

        if requests[ip].size >= max_requests
          raise 'Rate limit exceeded'
        end

        requests[ip] << now
        request
      end
    end

    def self.json_parser
      ->(request) do
        if request[:body] && request.dig(:headers, 'Content-Type')&.include?('application/json')
          require 'json'
          request[:json] = JSON.parse(request[:body])
        end
        request
      end
    end
  end

  class Application
    def initialize
      @router = Router.new
    end

    def get(path, &handler)
      @router.get(path, &handler)
    end

    def post(path, &handler)
      @router.post(path, &handler)
    end

    def put(path, &handler)
      @router.put(path, &handler)
    end

    def patch(path, &handler)
      @router.patch(path, &handler)
    end

    def delete(path, &handler)
      @router.delete(path, &handler)
    end

    def use(&middleware)
      @router.use(&middleware)
    end

    def on_error(status, &handler)
      @router.on_error(status, &handler)
    end

    def call(env)
      method = env['REQUEST_METHOD']
      path = env['PATH_INFO']

      @router.dispatch(method, path, env)
    end
  end
end
