require 'sinatra/base'
require 'json'

module NotificationService
  class Config
    attr_accessor :smtp_host, :smtp_port, :smtp_user, :smtp_password
    attr_accessor :twilio_account_sid, :twilio_auth_token, :twilio_phone
    attr_accessor :fcm_server_key, :apns_key_id, :apns_team_id
    attr_accessor :redis_url, :database_url

    def initialize
      load_from_env
    end

    def load_from_env
      # SMTP Configuration
      @smtp_host = ENV['SMTP_HOST'] || 'smtp.sendgrid.net'
      @smtp_port = ENV['SMTP_PORT'] || 587
      @smtp_user = ENV['SMTP_USER']
      @smtp_password = ENV['SMTP_PASSWORD']

      # Twilio Configuration
      @twilio_account_sid = ENV['TWILIO_ACCOUNT_SID']
      @twilio_auth_token = ENV['TWILIO_AUTH_TOKEN']
      @twilio_phone = ENV['TWILIO_PHONE_NUMBER']

      # Push Notification Configuration
      @fcm_server_key = ENV['FCM_SERVER_KEY']
      @apns_key_id = ENV['APNS_KEY_ID']
      @apns_team_id = ENV['APNS_TEAM_ID']

      # Database
      @redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379'
      @database_url = ENV['DATABASE_URL']
    end

    def self.instance
      @instance ||= new
    end
  end

  class EmailProvider
    def initialize(config)
      @config = config
    end

    def send_email(to:, subject:, body:, html: nil)
      # Email sending logic
      {
        status: 'sent',
        to: to,
        subject: subject,
        timestamp: Time.now.to_i
      }
    end
  end

  class SmsProvider
    def initialize(config)
      @config = config
    end

    def send_sms(to:, message:)
      # SMS sending logic using Twilio
      {
        status: 'sent',
        to: to,
        message: message,
        timestamp: Time.now.to_i
      }
    end
  end

  class PushProvider
    def initialize(config)
      @config = config
    end

    def send_push(device_token:, title:, body:, data: {})
      # Push notification logic
      {
        status: 'sent',
        device_token: device_token,
        title: title,
        timestamp: Time.now.to_i
      }
    end
  end
end
