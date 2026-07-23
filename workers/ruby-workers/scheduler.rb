require 'rufus-scheduler'
require 'redis'
require 'json'

redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
scheduler = Rufus::Scheduler.new

scheduler.every '1m' do
  puts "Running scheduled task: #{Time.now}"

  redis.lpush('jobs', { type: 'cleanup', timestamp: Time.now.to_i }.to_json)
end

scheduler.every '5m' do
  puts "Running analytics aggregation: #{Time.now}"

  redis.lpush('jobs', { type: 'analytics', timestamp: Time.now.to_i }.to_json)
end

scheduler.cron '0 0 * * *' do
  puts "Running daily report: #{Time.now}"

  redis.lpush('jobs', { type: 'daily_report', timestamp: Time.now.to_i }.to_json)
end

puts "Ruby scheduler started..."
scheduler.join
