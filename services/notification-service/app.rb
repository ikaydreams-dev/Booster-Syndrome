require 'sinatra/base'
require 'json'
require 'sequel'
require 'redis'
require 'mail'
require 'dotenv/load'

class NotificationService < Sinatra::Base
  configure do
    set :port, ENV.fetch('PORT', 8004)
    set :bind, '0.0.0.0'

    DB = Sequel.connect(ENV.fetch('DATABASE_URL', 'postgres://localhost/notifications_db'))
    REDIS = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))

    Mail.defaults do
      delivery_method :smtp, {
        address: ENV.fetch('SMTP_HOST', 'localhost'),
        port: ENV.fetch('SMTP_PORT', 587),
        user_name: ENV['SMTP_USERNAME'],
        password: ENV['SMTP_PASSWORD'],
        authentication: 'plain',
        enable_starttls_auto: true
      }
    end
  end

  before do
    content_type :json
  end

  get '/health' do
    {
      status: 'healthy',
      service: 'notification-service',
      version: '1.0.0'
    }.to_json
  end

  post '/api/v1/notifications/email' do
    data = JSON.parse(request.body.read)

    mail = Mail.new do
      from    data['from'] || ENV['DEFAULT_FROM_EMAIL']
      to      data['to']
      subject data['subject']
      body    data['body']
    end

    mail.deliver!

    { status: 'sent', message_id: mail.message_id }.to_json
  rescue => e
    status 500
    { error: e.message }.to_json
  end

  post '/api/v1/notifications/push' do
    data = JSON.parse(request.body.read)

    REDIS.lpush('push_notifications', data.to_json)

    { status: 'queued' }.to_json
  end

  get '/api/v1/notifications/:user_id' do
    user_id = params['user_id']

    notifications = DB[:notifications]
      .where(user_id: user_id)
      .order(Sequel.desc(:created_at))
      .limit(50)
      .all

    notifications.to_json
  end

  run! if app_file == $0
end
