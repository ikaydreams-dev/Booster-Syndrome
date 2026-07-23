require 'net/http'
require 'json'
require 'uri'

module API
  class Client
    attr_reader :base_url, :headers

    def initialize(base_url, headers: {}, timeout: 30)
      @base_url = base_url
      @headers = { 'Content-Type' => 'application/json' }.merge(headers)
      @timeout = timeout
      @retry_count = 3
      @retry_delay = 1
    end

    def get(path, params: {}, headers: {})
      request(:get, path, params: params, headers: headers)
    end

    def post(path, body: nil, headers: {})
      request(:post, path, body: body, headers: headers)
    end

    def put(path, body: nil, headers: {})
      request(:put, path, body: body, headers: headers)
    end

    def patch(path, body: nil, headers: {})
      request(:patch, path, body: body, headers: headers)
    end

    def delete(path, headers: {})
      request(:delete, path, headers: headers)
    end

    def request(method, path, params: {}, body: nil, headers: {})
      uri = build_uri(path, params)
      http = create_http_client(uri)

      request = create_request(method, uri, body, headers)

      attempt = 0
      begin
        attempt += 1
        response = http.request(request)
        handle_response(response)
      rescue => e
        if attempt < @retry_count
          sleep @retry_delay * attempt
          retry
        else
          { success: false, error: e.message }
        end
      end
    end

    private

    def build_uri(path, params)
      url = "#{@base_url}#{path}"
      uri = URI.parse(url)

      unless params.empty?
        uri.query = URI.encode_www_form(params)
      end

      uri
    end

    def create_http_client(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = @timeout
      http.open_timeout = @timeout
      http
    end

    def create_request(method, uri, body, custom_headers)
      request_class = case method
      when :get then Net::HTTP::Get
      when :post then Net::HTTP::Post
      when :put then Net::HTTP::Put
      when :patch then Net::HTTP::Patch
      when :delete then Net::HTTP::Delete
      end

      request = request_class.new(uri.request_uri)

      merged_headers = @headers.merge(custom_headers)
      merged_headers.each { |key, value| request[key] = value }

      if body
        request.body = body.is_a?(String) ? body : body.to_json
      end

      request
    end

    def handle_response(response)
      status = response.code.to_i
      body = response.body

      parsed_body = begin
        JSON.parse(body, symbolize_names: true)
      rescue JSON::ParserError
        body
      end

      {
        success: status >= 200 && status < 300,
        status: status,
        body: parsed_body,
        headers: response.to_hash
      }
    end
  end

  class RateLimiter
    def initialize(max_requests:, window:)
      @max_requests = max_requests
      @window = window
      @requests = []
      @mutex = Mutex.new
    end

    def allow?
      @mutex.synchronize do
        now = Time.now
        cutoff = now - @window

        @requests.reject! { |time| time < cutoff }

        if @requests.size < @max_requests
          @requests << now
          true
        else
          false
        end
      end
    end

    def wait_if_needed
      until allow?
        sleep 0.1
      end
    end

    def reset
      @mutex.synchronize do
        @requests.clear
      end
    end
  end

  class CircuitBreaker
    STATES = [:closed, :open, :half_open]

    def initialize(failure_threshold: 5, timeout: 60)
      @failure_threshold = failure_threshold
      @timeout = timeout
      @state = :closed
      @failure_count = 0
      @last_failure_time = nil
      @mutex = Mutex.new
    end

    def call(&block)
      @mutex.synchronize do
        if @state == :open
          if Time.now - @last_failure_time > @timeout
            @state = :half_open
          else
            raise 'Circuit breaker is open'
          end
        end
      end

      begin
        result = yield
        on_success
        result
      rescue => e
        on_failure
        raise e
      end
    end

    def state
      @mutex.synchronize { @state }
    end

    private

    def on_success
      @mutex.synchronize do
        @failure_count = 0
        @state = :closed
      end
    end

    def on_failure
      @mutex.synchronize do
        @failure_count += 1
        @last_failure_time = Time.now

        if @failure_count >= @failure_threshold
          @state = :open
        end
      end
    end
  end

  class Cache
    def initialize(ttl: 300)
      @cache = {}
      @ttl = ttl
      @mutex = Mutex.new
    end

    def get(key)
      @mutex.synchronize do
        entry = @cache[key]
        return nil unless entry

        if Time.now - entry[:timestamp] > @ttl
          @cache.delete(key)
          return nil
        end

        entry[:value]
      end
    end

    def set(key, value)
      @mutex.synchronize do
        @cache[key] = {
          value: value,
          timestamp: Time.now
        }
      end
    end

    def delete(key)
      @mutex.synchronize do
        @cache.delete(key)
      end
    end

    def clear
      @mutex.synchronize do
        @cache.clear
      end
    end
  end

  class CachedClient < Client
    def initialize(base_url, cache_ttl: 300, **options)
      super(base_url, **options)
      @cache = Cache.new(ttl: cache_ttl)
    end

    def get(path, params: {}, headers: {}, use_cache: true)
      if use_cache
        cache_key = "#{path}:#{params.to_json}"
        cached = @cache.get(cache_key)
        return cached if cached

        result = super(path, params: params, headers: headers)
        @cache.set(cache_key, result) if result[:success]
        result
      else
        super(path, params: params, headers: headers)
      end
    end

    def clear_cache
      @cache.clear
    end
  end

  class BatchRequest
    def initialize(client)
      @client = client
      @requests = []
    end

    def add(method, path, **options)
      @requests << { method: method, path: path, options: options }
      self
    end

    def execute(parallel: true)
      if parallel
        threads = @requests.map do |req|
          Thread.new do
            @client.request(req[:method], req[:path], **req[:options])
          end
        end

        threads.map(&:value)
      else
        @requests.map do |req|
          @client.request(req[:method], req[:path], **req[:options])
        end
      end
    end
  end

  class Pagination
    def initialize(client, path, params: {}, per_page: 20)
      @client = client
      @path = path
      @params = params
      @per_page = per_page
      @current_page = 1
    end

    def each_page(&block)
      loop do
        response = fetch_page(@current_page)
        break unless response[:success]

        items = response[:body][:items] || response[:body][:data] || []
        break if items.empty?

        yield items, @current_page

        break unless has_next_page?(response)
        @current_page += 1
      end
    end

    def all
      results = []
      each_page { |items, _| results.concat(items) }
      results
    end

    private

    def fetch_page(page)
      params = @params.merge(page: page, per_page: @per_page)
      @client.get(@path, params: params)
    end

    def has_next_page?(response)
      body = response[:body]
      return false unless body.is_a?(Hash)

      if body[:pagination]
        body[:pagination][:has_next] || body[:pagination][:next_page]
      elsif body[:meta]
        body[:meta][:has_next] || body[:meta][:next_page]
      else
        items = body[:items] || body[:data] || []
        items.size >= @per_page
      end
    end
  end
end
