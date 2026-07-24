require 'redis'

module Workers
  class CacheWorker
    def initialize(redis: nil)
      @redis = redis || Redis.new
    end

    def perform(job)
      case job[:action]
      when 'warm'
        warm_cache(job[:key], job[:data])
      when 'invalidate'
        invalidate_cache(job[:key])
      when 'refresh'
        refresh_cache(job[:key], job[:fetcher])
      end
    end

    private

    def warm_cache(key, data)
      @redis.set(key, data.to_json, ex: 3600)
    end

    def invalidate_cache(key)
      if key.include?('*')
        keys = @redis.keys(key)
        @redis.del(*keys) unless keys.empty?
      else
        @redis.del(key)
      end
    end

    def refresh_cache(key, fetcher)
      data = fetcher.call
      @redis.set(key, data.to_json, ex: 3600)
    end
  end
end
