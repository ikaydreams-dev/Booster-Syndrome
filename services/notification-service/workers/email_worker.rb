require 'sidekiq'
require 'mail'
require 'logger'

module NotificationService
  class EmailWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'emails', retry: 3, backtrace: true

    def perform(recipient, subject, body, options = {})
      logger.info "Sending email to #{recipient}"

      begin
        send_email(recipient, subject, body, options)
        logger.info "Email sent successfully to #{recipient}"
      rescue StandardError => e
        logger.error "Failed to send email: #{e.message}"
        raise e
      end
    end

    private

    def send_email(recipient, subject, body, options)
      mail = Mail.new do
        from    options['from'] || ENV['SMTP_FROM_EMAIL']
        to      recipient
        subject subject
        body    body

        if options['html']
          content_type 'text/html; charset=UTF-8'
        end

        if options['attachments']
          options['attachments'].each do |attachment|
            add_file attachment
          end
        end
      end

      mail.delivery_method :smtp, {
        address:              ENV['SMTP_HOST'],
        port:                 ENV['SMTP_PORT'],
        user_name:            ENV['SMTP_USER'],
        password:             ENV['SMTP_PASSWORD'],
        authentication:       'plain',
        enable_starttls_auto: true
      }

      mail.deliver!
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end

  class SmsWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'sms', retry: 3

    def perform(phone_number, message)
      logger.info "Sending SMS to #{phone_number}"

      # Twilio SMS sending logic
      # Implementation here

      logger.info "SMS sent successfully"
    end

    private

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end

  class PushWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'push_notifications', retry: 2

    def perform(device_token, notification_data)
      logger.info "Sending push notification to #{device_token}"

      # FCM/APNS push notification logic
      # Implementation here

      logger.info "Push notification sent successfully"
    end

    private

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
