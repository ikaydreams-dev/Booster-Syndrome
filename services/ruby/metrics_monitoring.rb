module Metrics
  class Counter
    attr_reader :name, :value, :labels

    def initialize(name, labels: {})
      @name = name
      @value = 0
      @labels = labels
      @mutex = Mutex.new
    end

    def increment(amount = 1)
      @mutex.synchronize do
        @value += amount
      end
    end

    def decrement(amount = 1)
      @mutex.synchronize do
        @value -= amount
      end
    end

    def reset
      @mutex.synchronize do
        @value = 0
      end
    end

    def to_h
      {
        name: @name,
        type: 'counter',
        value: @value,
        labels: @labels
      }
    end
  end

  class Gauge
    attr_reader :name, :value, :labels

    def initialize(name, labels: {})
      @name = name
      @value = 0
      @labels = labels
      @mutex = Mutex.new
    end

    def set(value)
      @mutex.synchronize do
        @value = value
      end
    end

    def increment(amount = 1)
      @mutex.synchronize do
        @value += amount
      end
    end

    def decrement(amount = 1)
      @mutex.synchronize do
        @value -= amount
      end
    end

    def to_h
      {
        name: @name,
        type: 'gauge',
        value: @value,
        labels: @labels
      }
    end
  end

  class Histogram
    attr_reader :name, :sum, :count, :labels

    def initialize(name, buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10], labels: {})
      @name = name
      @buckets = buckets.sort
      @bucket_counts = Hash.new(0)
      @sum = 0
      @count = 0
      @labels = labels
      @mutex = Mutex.new
    end

    def observe(value)
      @mutex.synchronize do
        @sum += value
        @count += 1

        @buckets.each do |bucket|
          @bucket_counts[bucket] += 1 if value <= bucket
        end
      end
    end

    def quantile(q)
      @mutex.synchronize do
        return 0 if @count == 0

        target = (@count * q).ceil

        @buckets.each do |bucket|
          return bucket if @bucket_counts[bucket] >= target
        end

        @buckets.last
      end
    end

    def mean
      @mutex.synchronize do
        @count > 0 ? @sum / @count.to_f : 0
      end
    end

    def to_h
      {
        name: @name,
        type: 'histogram',
        sum: @sum,
        count: @count,
        buckets: @bucket_counts,
        labels: @labels
      }
    end
  end

  class Summary
    attr_reader :name, :sum, :count, :labels

    def initialize(name, labels: {}, max_age: 600, age_buckets: 5)
      @name = name
      @sum = 0
      @count = 0
      @labels = labels
      @observations = []
      @max_age = max_age
      @age_buckets = age_buckets
      @mutex = Mutex.new
    end

    def observe(value)
      @mutex.synchronize do
        @sum += value
        @count += 1
        @observations << { value: value, timestamp: Time.now }

        cleanup_old_observations
      end
    end

    def quantile(q)
      @mutex.synchronize do
        return 0 if @observations.empty?

        values = @observations.map { |o| o[:value] }.sort
        index = (values.size * q).ceil - 1
        values[[index, 0].max]
      end
    end

    def mean
      @mutex.synchronize do
        @count > 0 ? @sum / @count.to_f : 0
      end
    end

    private

    def cleanup_old_observations
      cutoff = Time.now - @max_age
      @observations.reject! { |o| o[:timestamp] < cutoff }
    end

    def to_h
      {
        name: @name,
        type: 'summary',
        sum: @sum,
        count: @count,
        labels: @labels
      }
    end
  end

  class Registry
    def initialize
      @metrics = {}
      @mutex = Mutex.new
    end

    def counter(name, labels: {})
      @mutex.synchronize do
        key = metric_key(name, labels)
        @metrics[key] ||= Counter.new(name, labels: labels)
      end
    end

    def gauge(name, labels: {})
      @mutex.synchronize do
        key = metric_key(name, labels)
        @metrics[key] ||= Gauge.new(name, labels: labels)
      end
    end

    def histogram(name, buckets: nil, labels: {})
      @mutex.synchronize do
        key = metric_key(name, labels)
        @metrics[key] ||= Histogram.new(name, buckets: buckets || [], labels: labels)
      end
    end

    def summary(name, labels: {})
      @mutex.synchronize do
        key = metric_key(name, labels)
        @metrics[key] ||= Summary.new(name, labels: labels)
      end
    end

    def all
      @mutex.synchronize do
        @metrics.values.map(&:to_h)
      end
    end

    def export_prometheus
      lines = []

      @mutex.synchronize do
        @metrics.values.group_by(&:name).each do |name, metrics|
          type = metrics.first.to_h[:type]
          lines << "# TYPE #{name} #{type}"

          metrics.each do |metric|
            labels_str = format_labels(metric.labels)
            lines << "#{name}#{labels_str} #{metric.value}"
          end
        end
      end

      lines.join("\n")
    end

    private

    def metric_key(name, labels)
      "#{name}:#{labels.sort.to_h}"
    end

    def format_labels(labels)
      return '' if labels.empty?

      pairs = labels.map { |k, v| "#{k}=\"#{v}\"" }.join(',')
      "{#{pairs}}"
    end
  end

  class Timer
    def self.measure(metric)
      start = Time.now
      result = yield
      duration = Time.now - start

      metric.observe(duration)

      result
    end
  end

  class HealthCheck
    attr_reader :name, :status, :message, :last_check

    def initialize(name, &check)
      @name = name
      @check = check
      @status = :unknown
      @message = nil
      @last_check = nil
    end

    def run
      begin
        result = @check.call

        if result == true || result[:healthy] == true
          @status = :healthy
          @message = result.is_a?(Hash) ? result[:message] : 'OK'
        else
          @status = :unhealthy
          @message = result.is_a?(Hash) ? result[:message] : 'Check failed'
        end
      rescue => e
        @status = :unhealthy
        @message = e.message
      end

      @last_check = Time.now

      {
        name: @name,
        status: @status,
        message: @message,
        timestamp: @last_check
      }
    end

    def healthy?
      @status == :healthy
    end
  end

  class HealthCheckRegistry
    def initialize
      @checks = {}
      @mutex = Mutex.new
    end

    def register(name, &check)
      @mutex.synchronize do
        @checks[name] = HealthCheck.new(name, &check)
      end
    end

    def run_all
      results = {}

      @mutex.synchronize do
        @checks.each do |name, check|
          results[name] = check.run
        end
      end

      {
        status: results.values.all? { |r| r[:status] == :healthy } ? :healthy : :unhealthy,
        checks: results,
        timestamp: Time.now
      }
    end

    def run_check(name)
      @mutex.synchronize do
        check = @checks[name]
        return nil unless check

        check.run
      end
    end
  end
end
