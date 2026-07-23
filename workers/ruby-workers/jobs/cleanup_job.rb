require 'redis'

class CleanupJob
  def initialize
    @redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
  end

  def perform
    puts "Running cleanup job at #{Time.now}"

    cleanup_old_sessions
    cleanup_expired_tokens
    cleanup_temp_files

    puts "Cleanup complete!"
  end

  private

  def cleanup_old_sessions
    # Remove sessions older than 24 hours
    cutoff = Time.now.to_i - (24 * 60 * 60)
    @redis.zremrangebyscore('sessions', '-inf', cutoff)
  end

  def cleanup_expired_tokens
    # Remove expired JWT tokens
    @redis.keys('token:*').each do |key|
      ttl = @redis.ttl(key)
      @redis.del(key) if ttl < 0
    end
  end

  def cleanup_temp_files
    # Remove temporary files
    Dir.glob('/tmp/booster_*').each do |file|
      File.delete(file) if File.mtime(file) < Time.now - 3600
    end
  end
end
