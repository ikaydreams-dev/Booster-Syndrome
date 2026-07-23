module Reliability
  class CircuitBreaker
    STATES = [:closed, :open, :half_open].freeze

    attr_reader :state, :failure_count, :success_count

    def initialize(
      failure_threshold: 5,
      success_threshold: 2,
      timeout: 60,
      on_open: nil,
      on_half_open: nil,
      on_close: nil
    )
      @failure_threshold = failure_threshold
      @success_threshold = success_threshold
      @timeout = timeout
      @state = :closed
      @failure_count = 0
      @success_count = 0
      @last_failure_time = nil
      @mutex = Mutex.new
      @on_open = on_open
      @on_half_open = on_half_open
      @on_close = on_close
    end

    def call(&block)
      @mutex.synchronize do
        case @state
        when :open
          if should_attempt_reset?
            attempt_reset
          else
            raise CircuitOpenError, 'Circuit breaker is open'
          end
        when :half_open
        when :closed
        end
      end

      execute_with_monitoring(&block)
    end

    def closed?
      @state == :closed
    end

    def open?
      @state == :open
    end

    def half_open?
      @state == :half_open
    end

    def reset
      @mutex.synchronize do
        @state = :closed
        @failure_count = 0
        @success_count = 0
        @last_failure_time = nil
      end
    end

    def stats
      @mutex.synchronize do
        {
          state: @state,
          failure_count: @failure_count,
          success_count: @success_count,
          last_failure_time: @last_failure_time
        }
      end
    end

    private

    def execute_with_monitoring
      begin
        result = yield
        on_success
        result
      rescue => e
        on_failure
        raise e
      end
    end

    def on_success
      @mutex.synchronize do
        case @state
        when :half_open
          @success_count += 1
          if @success_count >= @success_threshold
            close_circuit
          end
        when :closed
          @failure_count = 0
        end
      end
    end

    def on_failure
      @mutex.synchronize do
        @failure_count += 1
        @last_failure_time = Time.now

        case @state
        when :half_open
          open_circuit
        when :closed
          if @failure_count >= @failure_threshold
            open_circuit
          end
        end
      end
    end

    def should_attempt_reset?
      @last_failure_time && (Time.now - @last_failure_time) >= @timeout
    end

    def attempt_reset
      @state = :half_open
      @failure_count = 0
      @success_count = 0
      @on_half_open&.call
    end

    def open_circuit
      @state = :open
      @on_open&.call
    end

    def close_circuit
      @state = :closed
      @failure_count = 0
      @success_count = 0
      @on_close&.call
    end
  end

  class CircuitOpenError < StandardError; end

  class RetryPolicy
    def initialize(max_attempts: 3, backoff: :exponential, initial_delay: 1, max_delay: 60)
      @max_attempts = max_attempts
      @backoff = backoff
      @initial_delay = initial_delay
      @max_delay = max_delay
    end

    def execute(&block)
      attempt = 0
      last_error = nil

      while attempt < @max_attempts
        begin
          return yield
        rescue => e
          last_error = e
          attempt += 1

          if attempt < @max_attempts
            delay = calculate_delay(attempt)
            sleep delay
          end
        end
      end

      raise last_error
    end

    private

    def calculate_delay(attempt)
      delay = case @backoff
      when :exponential
        @initial_delay * (2 ** (attempt - 1))
      when :linear
        @initial_delay * attempt
      when :fixed
        @initial_delay
      else
        @initial_delay
      end

      [delay, @max_delay].min
    end
  end

  class Bulkhead
    def initialize(max_concurrent: 10, queue_size: 10)
      @max_concurrent = max_concurrent
      @queue_size = queue_size
      @current = 0
      @queue = []
      @mutex = Mutex.new
    end

    def execute(&block)
      acquire

      begin
        yield
      ensure
        release
      end
    end

    def stats
      @mutex.synchronize do
        {
          current: @current,
          max_concurrent: @max_concurrent,
          queue_size: @queue.size,
          queue_limit: @queue_size
        }
      end
    end

    private

    def acquire
      @mutex.synchronize do
        if @current < @max_concurrent
          @current += 1
        elsif @queue.size < @queue_size
          condition = ConditionVariable.new
          @queue << condition
          condition.wait(@mutex)
        else
          raise 'Bulkhead is full'
        end
      end
    end

    def release
      @mutex.synchronize do
        if @queue.any?
          condition = @queue.shift
          condition.signal
        else
          @current -= 1
        end
      end
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

    def execute(&block)
      unless allow?
        raise RateLimitExceededError, 'Rate limit exceeded'
      end

      yield
    end

    def wait_and_execute(&block)
      until allow?
        sleep 0.1
      end

      yield
    end

    def reset
      @mutex.synchronize do
        @requests.clear
      end
    end

    def stats
      @mutex.synchronize do
        {
          current_requests: @requests.size,
          max_requests: @max_requests,
          window: @window
        }
      end
    end
  end

  class RateLimitExceededError < StandardError; end

  class Timeout
    def self.execute(seconds, &block)
      result = nil
      thread = Thread.new { result = yield }

      unless thread.join(seconds)
        thread.kill
        raise TimeoutError, "Operation timed out after #{seconds} seconds"
      end

      result
    end
  end

  class TimeoutError < StandardError; end
end
