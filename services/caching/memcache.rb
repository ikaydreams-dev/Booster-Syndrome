module Caching
  class MemoryCache
    def initialize(max_size: 1000, ttl: 3600)
      @cache = {}
      @access_times = {}
      @max_size = max_size
      @ttl = ttl
    end

    def get(key)
      cleanup_expired

      if @cache.key?(key)
        @access_times[key] = Time.now
        @cache[key][:value]
      else
        nil
      end
    end

    def set(key, value, ttl: nil)
      cleanup_expired
      evict_if_needed

      @cache[key] = {
        value: value,
        expires_at: Time.now + (ttl || @ttl)
      }
      @access_times[key] = Time.now

      value
    end

    def delete(key)
      @cache.delete(key)
      @access_times.delete(key)
    end

    def exists?(key)
      cleanup_expired
      @cache.key?(key)
    end

    def clear
      @cache.clear
      @access_times.clear
    end

    def size
      cleanup_expired
      @cache.size
    end

    def keys
      cleanup_expired
      @cache.keys
    end

    def increment(key, amount = 1)
      value = get(key) || 0
      new_value = value + amount
      set(key, new_value)
      new_value
    end

    def decrement(key, amount = 1)
      increment(key, -amount)
    end

    def multi_get(keys)
      keys.map { |key| [key, get(key)] }.to_h
    end

    def multi_set(hash, ttl: nil)
      hash.each { |key, value| set(key, value, ttl: ttl) }
    end

    private

    def cleanup_expired
      now = Time.now
      @cache.delete_if { |_, entry| entry[:expires_at] < now }
    end

    def evict_if_needed
      return if @cache.size < @max_size

      oldest_key = @access_times.min_by { |_, time| time }[0]
      delete(oldest_key)
    end
  end

  class LRUCache
    def initialize(capacity)
      @capacity = capacity
      @cache = {}
      @order = []
    end

    def get(key)
      return nil unless @cache.key?(key)

      @order.delete(key)
      @order.push(key)
      @cache[key]
    end

    def put(key, value)
      if @cache.key?(key)
        @order.delete(key)
      elsif @cache.size >= @capacity
        oldest = @order.shift
        @cache.delete(oldest)
      end

      @cache[key] = value
      @order.push(key)
    end

    def delete(key)
      @order.delete(key)
      @cache.delete(key)
    end

    def clear
      @cache.clear
      @order.clear
    end

    def size
      @cache.size
    end

    def keys
      @order.dup
    end
  end

  class CacheStats
    attr_reader :hits, :misses, :sets, :deletes

    def initialize
      @hits = 0
      @misses = 0
      @sets = 0
      @deletes = 0
    end

    def record_hit
      @hits += 1
    end

    def record_miss
      @misses += 1
    end

    def record_set
      @sets += 1
    end

    def record_delete
      @deletes += 1
    end

    def hit_rate
      total = @hits + @misses
      return 0.0 if total.zero?
      @hits.to_f / total
    end

    def miss_rate
      1.0 - hit_rate
    end

    def reset
      @hits = 0
      @misses = 0
      @sets = 0
      @deletes = 0
    end

    def to_h
      {
        hits: @hits,
        misses: @misses,
        sets: @sets,
        deletes: @deletes,
        hit_rate: hit_rate,
        miss_rate: miss_rate
      }
    end
  end

  class InstrumentedCache
    def initialize(cache)
      @cache = cache
      @stats = CacheStats.new
    end

    def get(key)
      value = @cache.get(key)
      if value.nil?
        @stats.record_miss
      else
        @stats.record_hit
      end
      value
    end

    def set(key, value, **options)
      @stats.record_set
      @cache.set(key, value, **options)
    end

    def delete(key)
      @stats.record_delete
      @cache.delete(key)
    end

    def stats
      @stats
    end

    def method_missing(method, *args, &block)
      @cache.send(method, *args, &block)
    end

    def respond_to_missing?(method, include_private = false)
      @cache.respond_to?(method, include_private)
    end
  end
end
