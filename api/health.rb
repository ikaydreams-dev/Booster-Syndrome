# Health check endpoint for Ruby services
require 'json'

class HealthCheck
  def self.check
    {
      status: 'healthy',
      timestamp: Time.now.iso8601,
      service: 'ruby',
      version: '1.0.0',
      uptime: Process.clock_gettime(Process::CLOCK_MONOTONIC).to_i,
      dependencies: check_dependencies
    }
  end

  def self.check_dependencies
    {
      database: check_database,
      redis: check_redis,
      memory: check_memory
    }
  end

  def self.check_database
    # Simulated database check
    { status: 'connected', latency_ms: 5 }
  end

  def self.check_redis
    # Simulated Redis check
    { status: 'connected', latency_ms: 2 }
  end

  def self.check_memory
    memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    { used_mb: memory_mb, limit_mb: 512 }
  end
end

# HTTP endpoint handler
def health_endpoint
  health = HealthCheck.check
  [200, { 'Content-Type' => 'application/json' }, [health.to_json]]
end
