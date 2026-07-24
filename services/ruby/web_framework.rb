module WebFramework
  class Application
    def initialize
      @routes = {}
      @middleware = []
      @before_filters = []
      @after_filters = []
    end

    def use(middleware)
      @middleware << middleware
    end

    def before(&block)
      @before_filters << block
    end

    def after(&block)
      @after_filters << block
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

    def delete(path, &handler)
      add_route(:DELETE, path, handler)
    end

    def patch(path, &handler)
      add_route(:PATCH, path, handler)
    end

    def add_route(method, path, handler)
      @routes[method] ||= []
      @routes[method] << { path: compile_path(path), handler: handler, original_path: path }
    end

    def compile_path(path)
      pattern = path.gsub(/:(\w+)/, '(?<\1>[^/]+)')
      Regexp.new("^#{pattern}$")
    end

    def call(env)
      request = Request.new(env)
      response = Response.new

      @before_filters.each { |filter| filter.call(request, response) }

      route = find_route(request.method, request.path)

      if route
        matches = route[:path].match(request.path)
        request.params.merge!(matches.named_captures) if matches

        begin
          result = route[:handler].call(request, response)
          response.body = result if result.is_a?(String)
        rescue => e
          response.status = 500
          response.body = "Internal Server Error: #{e.message}"
        end
      else
        response.status = 404
        response.body = "Not Found"
      end

      @after_filters.each { |filter| filter.call(request, response) }

      [response.status, response.headers, [response.body]]
    end

    def find_route(method, path)
      return nil unless @routes[method.to_sym]

      @routes[method.to_sym].find do |route|
        route[:path].match?(path)
      end
    end
  end

  class Request
    attr_reader :env, :method, :path, :params, :headers, :body

    def initialize(env)
      @env = env
      @method = env['REQUEST_METHOD']
      @path = env['PATH_INFO']
      @params = parse_query_string(env['QUERY_STRING'] || '')
      @headers = extract_headers(env)
      @body = env['rack.input']&.read
    end

    def parse_query_string(query_string)
      query_string.split('&').each_with_object({}) do |pair, params|
        key, value = pair.split('=')
        params[key] = value if key
      end
    end

    def extract_headers(env)
      env.select { |k, v| k.start_with?('HTTP_') }
         .transform_keys { |k| k.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-') }
    end

    def get?
      @method == 'GET'
    end

    def post?
      @method == 'POST'
    end

    def put?
      @method == 'PUT'
    end

    def delete?
      @method == 'DELETE'
    end

    def patch?
      @method == 'PATCH'
    end
  end

  class Response
    attr_accessor :status, :headers, :body

    def initialize
      @status = 200
      @headers = { 'Content-Type' => 'text/html' }
      @body = ''
    end

    def set_header(key, value)
      @headers[key] = value
    end

    def json(data)
      @headers['Content-Type'] = 'application/json'
      @body = JSON.generate(data)
    end

    def redirect(location, status = 302)
      @status = status
      @headers['Location'] = location
      @body = ''
    end

    def set_cookie(name, value, options = {})
      cookie = "#{name}=#{value}"
      cookie += "; Path=#{options[:path]}" if options[:path]
      cookie += "; Domain=#{options[:domain]}" if options[:domain]
      cookie += "; Max-Age=#{options[:max_age]}" if options[:max_age]
      cookie += "; Secure" if options[:secure]
      cookie += "; HttpOnly" if options[:http_only]

      @headers['Set-Cookie'] = cookie
    end
  end

  class Session
    def initialize(env)
      @env = env
      @data = {}
      load_session
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      @data[key] = value
    end

    def delete(key)
      @data.delete(key)
    end

    def clear
      @data.clear
    end

    def load_session
      cookie = @env['HTTP_COOKIE']
      return unless cookie

      session_id = cookie.split(';').find { |c| c.strip.start_with?('session_id=') }
      return unless session_id

      # Load session data from store
    end

    def save
      # Save session data to store
    end
  end

  class TemplateEngine
    def initialize(template_dir)
      @template_dir = template_dir
      @cache = {}
    end

    def render(template_name, locals = {})
      template = load_template(template_name)
      context = RenderContext.new(locals)
      context.instance_eval(template)
    end

    def load_template(name)
      return @cache[name] if @cache[name]

      path = File.join(@template_dir, "#{name}.erb")
      content = File.read(path)
      @cache[name] = ERB.new(content)
    end

    class RenderContext
      def initialize(locals)
        locals.each do |key, value|
          instance_variable_set("@#{key}", value)
          self.class.send(:attr_accessor, key)
          send("#{key}=", value)
        end
      end
    end
  end

  class Logger
    LEVELS = { debug: 0, info: 1, warn: 2, error: 3, fatal: 4 }

    def initialize(output = STDOUT, level: :info)
      @output = output
      @level = LEVELS[level]
    end

    def debug(message)
      log(:debug, message)
    end

    def info(message)
      log(:info, message)
    end

    def warn(message)
      log(:warn, message)
    end

    def error(message)
      log(:error, message)
    end

    def fatal(message)
      log(:fatal, message)
    end

    def log(level, message)
      return if LEVELS[level] < @level

      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      @output.puts "[#{timestamp}] #{level.to_s.upcase}: #{message}"
    end
  end

  class Middleware
    class Static
      def initialize(app, root:)
        @app = app
        @root = root
      end

      def call(env)
        path = env['PATH_INFO']
        file_path = File.join(@root, path)

        if File.exist?(file_path) && File.file?(file_path)
          content = File.read(file_path)
          content_type = determine_content_type(file_path)

          [200, { 'Content-Type' => content_type }, [content]]
        else
          @app.call(env)
        end
      end

      def determine_content_type(path)
        case File.extname(path)
        when '.html' then 'text/html'
        when '.css' then 'text/css'
        when '.js' then 'application/javascript'
        when '.json' then 'application/json'
        when '.png' then 'image/png'
        when '.jpg', '.jpeg' then 'image/jpeg'
        when '.gif' then 'image/gif'
        else 'text/plain'
        end
      end
    end

    class Logger
      def initialize(app, logger:)
        @app = app
        @logger = logger
      end

      def call(env)
        start_time = Time.now
        status, headers, body = @app.call(env)
        duration = Time.now - start_time

        @logger.info "#{env['REQUEST_METHOD']} #{env['PATH_INFO']} - #{status} (#{duration}s)"

        [status, headers, body]
      end
    end

    class CORS
      def initialize(app, origins: '*', methods: %w[GET POST PUT DELETE], headers: '*')
        @app = app
        @origins = origins
        @methods = methods
        @headers = headers
      end

      def call(env)
        status, headers, body = @app.call(env)

        headers['Access-Control-Allow-Origin'] = @origins
        headers['Access-Control-Allow-Methods'] = @methods.join(', ')
        headers['Access-Control-Allow-Headers'] = @headers

        [status, headers, body]
      end
    end

    class JSONParser
      def initialize(app)
        @app = app
      end

      def call(env)
        if env['CONTENT_TYPE'] == 'application/json' && env['rack.input']
          body = env['rack.input'].read
          env['rack.input'].rewind
          env['parsed_json'] = JSON.parse(body) rescue {}
        end

        @app.call(env)
      end
    end

    class ErrorHandler
      def initialize(app)
        @app = app
      end

      def call(env)
        begin
          @app.call(env)
        rescue => e
          [500, { 'Content-Type' => 'application/json' }, [JSON.generate(error: e.message, backtrace: e.backtrace)]]
        end
      end
    end
  end

  class Validator
    def self.email(value)
      value.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    end

    def self.url(value)
      value.match?(/\Ahttps?:\/\/[\S]+\z/)
    end

    def self.numeric(value)
      value.to_s.match?(/\A\d+(\.\d+)?\z/)
    end

    def self.length(value, min: nil, max: nil)
      len = value.to_s.length
      (min.nil? || len >= min) && (max.nil? || len <= max)
    end

    def self.presence(value)
      !value.nil? && !value.to_s.empty?
    end

    def self.format(value, pattern)
      value.to_s.match?(pattern)
    end
  end

  class Cache
    def initialize
      @store = {}
      @mutex = Mutex.new
    end

    def get(key)
      @mutex.synchronize { @store[key] }
    end

    def set(key, value, ttl: nil)
      @mutex.synchronize do
        @store[key] = { value: value, expires_at: ttl ? Time.now + ttl : nil }
      end
    end

    def delete(key)
      @mutex.synchronize { @store.delete(key) }
    end

    def clear
      @mutex.synchronize { @store.clear }
    end

    def cleanup
      @mutex.synchronize do
        now = Time.now
        @store.delete_if { |_, v| v[:expires_at] && v[:expires_at] < now }
      end
    end
  end

  class Router
    def initialize
      @routes = []
      @namespaces = []
    end

    def namespace(prefix, &block)
      @namespaces << prefix
      instance_eval(&block)
      @namespaces.pop
    end

    def resource(name, controller:, only: nil, except: nil)
      actions = [:index, :show, :create, :update, :destroy]
      actions &= only if only
      actions -= except if except

      prefix = @namespaces.join('')

      actions.each do |action|
        case action
        when :index
          get "#{prefix}/#{name}", to: "#{controller}#index"
        when :show
          get "#{prefix}/#{name}/:id", to: "#{controller}#show"
        when :create
          post "#{prefix}/#{name}", to: "#{controller}#create"
        when :update
          put "#{prefix}/#{name}/:id", to: "#{controller}#update"
        when :destroy
          delete "#{prefix}/#{name}/:id", to: "#{controller}#destroy"
        end
      end
    end

    def get(path, to: nil, &block)
      add_route(:GET, path, to, block)
    end

    def post(path, to: nil, &block)
      add_route(:POST, path, to, block)
    end

    def put(path, to: nil, &block)
      add_route(:PUT, path, to, block)
    end

    def delete(path, to: nil, &block)
      add_route(:DELETE, path, to, block)
    end

    def add_route(method, path, controller_action, block)
      prefix = @namespaces.join('')
      full_path = "#{prefix}#{path}"

      @routes << {
        method: method,
        path: full_path,
        controller_action: controller_action,
        handler: block
      }
    end

    def routes
      @routes
    end
  end
end
