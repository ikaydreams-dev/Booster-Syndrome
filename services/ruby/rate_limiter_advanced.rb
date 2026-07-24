module RateLimiting
  class TokenBucket
    def initialize(capacity:, refill_rate:)
      @capacity = capacity
      @refill_rate = refill_rate
      @tokens = capacity
      @last_refill = Time.now
      @mutex = Mutex.new
    end

    def allow?(tokens_requested = 1)
      @mutex.synchronize do
        refill

        if @tokens >= tokens_requested
          @tokens -= tokens_requested
          true
        else
          false
        end
      end
    end

    def reset
      @mutex.synchronize do
        @tokens = @capacity
        @last_refill = Time.now
      end
    end

    def available_tokens
      @mutex.synchronize do
        refill
        @tokens
      end
    end

    private

    def refill
      now = Time.now
      elapsed = now - @last_refill
      tokens_to_add = (elapsed * @refill_rate).floor

      if tokens_to_add > 0
        @tokens = [@tokens + tokens_to_add, @capacity].min
        @last_refill = now
      end
    end
  end

  class LeakyBucket
    def initialize(capacity:, leak_rate:)
      @capacity = capacity
      @leak_rate = leak_rate
      @level = 0
      @last_leak = Time.now
      @mutex = Mutex.new
    end

    def allow?
      @mutex.synchronize do
        leak

        if @level < @capacity
          @level += 1
          true
        else
          false
        end
      end
    end

    def current_level
      @mutex.synchronize do
        leak
        @level
      end
    end

    private

    def leak
      now = Time.now
      elapsed = now - @last_leak
      leaked = (elapsed * @leak_rate).floor

      if leaked > 0
        @level = [@level - leaked, 0].max
        @last_leak = now
      end
    end
  end

  class SlidingWindow
    def initialize(limit:, window:)
      @limit = limit
      @window = window
      @requests = []
      @mutex = Mutex.new
    end

    def allow?
      @mutex.synchronize do
        cleanup

        if @requests.size < @limit
          @requests << Time.now
          true
        else
          false
        end
      end
    end

    def count
      @mutex.synchronize do
        cleanup
        @requests.size
      end
    end

    private

    def cleanup
      cutoff = Time.now - @window
      @requests.reject! { |time| time < cutoff }
    end
  end

  class FixedWindow
    def initialize(limit:, window:)
      @limit = limit
      @window = window
      @windows = {}
      @mutex = Mutex.new
    end

    def allow?(key = 'default')
      @mutex.synchronize do
        current_window = (Time.now.to_i / @window).floor
        cleanup

        @windows[key] ||= {}
        @windows[key][current_window] ||= 0

        if @windows[key][current_window] < @limit
          @windows[key][current_window] += 1
          true
        else
          false
        end
      end
    end

    private

    def cleanup
      current_window = (Time.now.to_i / @window).floor

      @windows.each do |key, windows|
        windows.delete_if { |w, _| w < current_window - 1 }
      end
    end
  end

  class AdaptiveRateLimiter
    def initialize(base_limit:, window:)
      @base_limit = base_limit
      @current_limit = base_limit
      @window = window
      @success_count = 0
      @failure_count = 0
      @limiter = SlidingWindow.new(limit: @current_limit, window: @window)
      @mutex = Mutex.new
    end

    def allow?
      result = @limiter.allow?

      @mutex.synchronize do
        if result
          @success_count += 1
        else
          @failure_count += 1
        end

        adjust_limit
      end

      result
    end

    private

    def adjust_limit
      total = @success_count + @failure_count
      return if total < 100

      success_rate = @success_count / total.to_f

      if success_rate > 0.95
        @current_limit = [@current_limit * 1.1, @base_limit * 2].min
      elsif success_rate < 0.5
        @current_limit = [@current_limit * 0.9, @base_limit * 0.5].max
      end

      @limiter = SlidingWindow.new(limit: @current_limit.to_i, window: @window)
      @success_count = 0
      @failure_count = 0
    end
  end

  class DistributedRateLimiter
    def initialize(redis_client, limit:, window:)
      @redis = redis_client
      @limit = limit
      @window = window
    end

    def allow?(key)
      current_time = Time.now.to_i
      window_start = current_time - @window

      count = @redis.zcount(key, window_start, current_time)

      if count < @limit
        @redis.zadd(key, current_time, "#{current_time}:#{SecureRandom.uuid}")
        @redis.expire(key, @window * 2)
        true
      else
        false
      end
    end

    def cleanup(key)
      current_time = Time.now.to_i
      window_start = current_time - @window
      @redis.zremrangebyscore(key, 0, window_start)
    end
  end
end
