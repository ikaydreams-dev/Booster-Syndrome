require 'redis'

class PushNotifier
  def initialize
    @redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
  end

  def send_push_notification(user_id:, title:, body:, data: {})
    notification = {
      user_id: user_id,
      title: title,
      body: body,
      data: data,
      timestamp: Time.now.to_i
    }

    @redis.lpush('push_notifications', notification.to_json)

    { status: 'queued', notification: notification }
  rescue => e
    { status: 'failed', error: e.message }
  end

  def get_pending_notifications(limit = 10)
    notifications = @redis.lrange('push_notifications', 0, limit - 1)
    notifications.map { |n| JSON.parse(n) }
  end

  def clear_notifications(count = 1)
    count.times { @redis.rpop('push_notifications') }
  end
end
