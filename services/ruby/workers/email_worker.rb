module Workers
  class EmailWorker
    def initialize(mailer)
      @mailer = mailer
    end

    def perform(job)
      case job[:type]
      when 'welcome'
        send_welcome_email(job[:data])
      when 'notification'
        send_notification_email(job[:data])
      when 'password_reset'
        send_password_reset_email(job[:data])
      else
        raise "Unknown email type: #{job[:type]}"
      end
    end

    private

    def send_welcome_email(data)
      @mailer.send(
        to: data[:email],
        subject: 'Welcome to Booster Syndrome',
        body: "Welcome #{data[:name]}! Thanks for joining."
      )
    end

    def send_notification_email(data)
      @mailer.send(
        to: data[:email],
        subject: data[:subject],
        body: data[:body]
      )
    end

    def send_password_reset_email(data)
      @mailer.send(
        to: data[:email],
        subject: 'Password Reset Request',
        body: "Reset your password: #{data[:reset_url]}"
      )
    end
  end
end
