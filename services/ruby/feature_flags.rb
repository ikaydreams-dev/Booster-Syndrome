module FeatureFlags
  class Flag
    attr_reader :name, :enabled, :description, :metadata

    def initialize(name, enabled: false, description: '', metadata: {})
      @name = name
      @enabled = enabled
      @description = description
      @metadata = metadata
      @rules = []
    end

    def enable
      @enabled = true
    end

    def disable
      @enabled = false
    end

    def enabled?
      @enabled
    end

    def add_rule(&block)
      @rules << block
    end

    def evaluate(context = {})
      return false unless @enabled

      @rules.all? { |rule| rule.call(context) }
    end

    def to_h
      {
        name: @name,
        enabled: @enabled,
        description: @description,
        metadata: @metadata
      }
    end
  end

  class Manager
    def initialize
      @flags = {}
      @mutex = Mutex.new
    end

    def register(name, enabled: false, description: '', metadata: {})
      @mutex.synchronize do
        @flags[name] = Flag.new(name, enabled: enabled, description: description, metadata: metadata)
      end
    end

    def enable(name)
      flag = get_flag(name)
      flag&.enable
    end

    def disable(name)
      flag = get_flag(name)
      flag&.disable
    end

    def enabled?(name, context = {})
      flag = get_flag(name)
      return false unless flag

      flag.evaluate(context)
    end

    def add_rule(name, &block)
      flag = get_flag(name)
      flag&.add_rule(&block)
    end

    def all_flags
      @mutex.synchronize do
        @flags.values.map(&:to_h)
      end
    end

    def get_flag(name)
      @mutex.synchronize do
        @flags[name]
      end
    end

    def remove(name)
      @mutex.synchronize do
        @flags.delete(name)
      end
    end

    def percentage_rollout(name, percentage)
      add_rule(name) do |context|
        user_id = context[:user_id]
        next false unless user_id

        hash = user_id.to_s.bytes.sum % 100
        hash < percentage
      end
    end

    def user_list(name, user_ids)
      add_rule(name) do |context|
        user_id = context[:user_id]
        user_ids.include?(user_id)
      end
    end

    def environment(name, environments)
      add_rule(name) do |context|
        env = context[:environment]
        environments.include?(env)
      end
    end
  end

  class Experiment
    attr_reader :name, :variants, :control

    def initialize(name, variants:, control:)
      @name = name
      @variants = variants
      @control = control
      @assignments = {}
      @mutex = Mutex.new
    end

    def assign(user_id)
      @mutex.synchronize do
        return @assignments[user_id] if @assignments[user_id]

        variant = select_variant(user_id)
        @assignments[user_id] = variant
        variant
      end
    end

    def track_result(user_id, metric, value)
    end

    def results
      @mutex.synchronize do
        @assignments.dup
      end
    end

    private

    def select_variant(user_id)
      hash = user_id.to_s.bytes.sum % 100
      cumulative = 0

      @variants.each do |variant, weight|
        cumulative += weight
        return variant if hash < cumulative
      end

      @control
    end
  end

  class ABTest < Experiment
    def initialize(name, variant_a: 'A', variant_b: 'B')
      super(name, variants: { variant_a => 50, variant_b => 50 }, control: variant_a)
    end
  end

  class Storage
    def initialize(file_path)
      @file_path = file_path
      @mutex = Mutex.new
    end

    def save(flags)
      @mutex.synchronize do
        data = flags.map(&:to_h)
        File.write(@file_path, JSON.pretty_generate(data))
      end
    end

    def load
      @mutex.synchronize do
        return [] unless File.exist?(@file_path)

        data = JSON.parse(File.read(@file_path), symbolize_names: true)
        data.map do |flag_data|
          Flag.new(
            flag_data[:name],
            enabled: flag_data[:enabled],
            description: flag_data[:description],
            metadata: flag_data[:metadata]
          )
        end
      end
    end
  end

  class RemoteConfig
    def initialize(api_url, api_key)
      @api_url = api_url
      @api_key = api_key
      @cache = {}
      @mutex = Mutex.new
    end

    def fetch
      uri = URI.parse(@api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      request = Net::HTTP::Get.new(uri.path)
      request['Authorization'] = "Bearer #{@api_key}"

      response = http.request(request)

      if response.code.to_i == 200
        data = JSON.parse(response.body, symbolize_names: true)

        @mutex.synchronize do
          @cache = data
        end

        data
      else
        @mutex.synchronize { @cache }
      end
    rescue => e
      puts "Failed to fetch remote config: #{e.message}"
      @mutex.synchronize { @cache }
    end

    def get(key, default = nil)
      @mutex.synchronize do
        @cache[key] || default
      end
    end
  end
end
