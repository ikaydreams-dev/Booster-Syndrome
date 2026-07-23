require 'redis'
require 'json'

module RedisOps
  class CacheOperations
    def initialize(host: 'localhost', port: 6379, db: 0)
      @redis = Redis.new(host: host, port: port, db: db)
    end

    def set(key, value, ttl: nil)
      value_json = value.to_json
      if ttl
        @redis.setex(key, ttl, value_json)
      else
        @redis.set(key, value_json)
      end
    end

    def get(key)
      value = @redis.get(key)
      value ? JSON.parse(value) : nil
    end

    def delete(key)
      @redis.del(key)
    end

    def exists?(key)
      @redis.exists?(key)
    end

    def increment(key, by: 1)
      @redis.incrby(key, by)
    end

    def decrement(key, by: 1)
      @redis.decrby(key, by)
    end

    def expire(key, seconds)
      @redis.expire(key, seconds)
    end

    def ttl(key)
      @redis.ttl(key)
    end

    def keys(pattern = '*')
      @redis.keys(pattern)
    end

    def flush_all
      @redis.flushall
    end

    def hash_set(key, field, value)
      @redis.hset(key, field, value.to_json)
    end

    def hash_get(key, field)
      value = @redis.hget(key, field)
      value ? JSON.parse(value) : nil
    end

    def hash_get_all(key)
      hash = @redis.hgetall(key)
      hash.transform_values { |v| JSON.parse(v) }
    end

    def list_push(key, *values)
      @redis.rpush(key, values.map(&:to_json))
    end

    def list_pop(key)
      value = @redis.lpop(key)
      value ? JSON.parse(value) : nil
    end

    def list_range(key, start_idx, end_idx)
      @redis.lrange(key, start_idx, end_idx).map { |v| JSON.parse(v) }
    end

    def set_add(key, *members)
      @redis.sadd(key, members.map(&:to_json))
    end

    def set_members(key)
      @redis.smembers(key).map { |v| JSON.parse(v) }
    end

    def set_is_member?(key, member)
      @redis.sismember(key, member.to_json)
    end

    def close
      @redis.quit
    end
  end
end
