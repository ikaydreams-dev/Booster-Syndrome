require 'net/http'
require 'uri'
require 'json'

module HTTP
  class Client
    attr_accessor :base_url, :headers, :timeout

    def initialize(base_url, timeout: 30)
      @base_url = base_url
      @headers = {}
      @timeout = timeout
    end

    def get(path, params: {}, headers: {})
      uri = build_uri(path, params)
      request = Net::HTTP::Get.new(uri)
      execute_request(uri, request, headers)
    end

    def post(path, body: nil, params: {}, headers: {})
      uri = build_uri(path, params)
      request = Net::HTTP::Post.new(uri)
      request.body = body.is_a?(Hash) ? body.to_json : body
      execute_request(uri, request, headers)
    end

    def put(path, body: nil, params: {}, headers: {})
      uri = build_uri(path, params)
      request = Net::HTTP::Put.new(uri)
      request.body = body.is_a?(Hash) ? body.to_json : body
      execute_request(uri, request, headers)
    end

    def patch(path, body: nil, params: {}, headers: {})
      uri = build_uri(path, params)
      request = Net::HTTP::Patch.new(uri)
      request.body = body.is_a?(Hash) ? body.to_json : body
      execute_request(uri, request, headers)
    end

    def delete(path, params: {}, headers: {})
      uri = build_uri(path, params)
      request = Net::HTTP::Delete.new(uri)
      execute_request(uri, request, headers)
    end

    private

    def build_uri(path, params)
      url = @base_url + path
      uri = URI.parse(url)

      unless params.empty?
        uri.query = URI.encode_www_form(params)
      end

      uri
    end

    def execute_request(uri, request, custom_headers)
      merged_headers = @headers.merge(custom_headers)
      merged_headers.each { |key, value| request[key] = value }

      Net::HTTP.start(uri.hostname, uri.port,
                     use_ssl: uri.scheme == 'https',
                     read_timeout: @timeout,
                     open_timeout: @timeout) do |http|
        response = http.request(request)
        Response.new(response)
      end
    end
  end

  class Response
    attr_reader :status, :headers, :body

    def initialize(net_http_response)
      @status = net_http_response.code.to_i
      @headers = net_http_response.to_hash
      @body = net_http_response.body
    end

    def success?
      @status >= 200 && @status < 300
    end

    def json
      JSON.parse(@body)
    rescue JSON::ParserError
      nil
    end

    def error?
      @status >= 400
    end

    def client_error?
      @status >= 400 && @status < 500
    end

    def server_error?
      @status >= 500
    end
  end

  class RequestBuilder
    def initialize(client)
      @client = client
      @path = ''
      @params = {}
      @headers = {}
      @body = nil
    end

    def path(p)
      @path = p
      self
    end

    def params(p)
      @params.merge!(p)
      self
    end

    def headers(h)
      @headers.merge!(h)
      self
    end

    def body(b)
      @body = b
      self
    end

    def get
      @client.get(@path, params: @params, headers: @headers)
    end

    def post
      @client.post(@path, body: @body, params: @params, headers: @headers)
    end

    def put
      @client.put(@path, body: @body, params: @params, headers: @headers)
    end

    def patch
      @client.patch(@path, body: @body, params: @params, headers: @headers)
    end

    def delete
      @client.delete(@path, params: @params, headers: @headers)
    end
  end
end
