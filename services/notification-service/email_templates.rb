module NotificationService
  class EmailTemplates
    def self.welcome_email(user)
      {
        subject: "Welcome to Booster Syndrome!",
        body: <<~HTML
          <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h1 style="color: #4F46E5;">Welcome #{user[:username]}!</h1>
              <p>Thank you for joining Booster Syndrome. We're excited to have you on board.</p>
              <p>Get started by completing your profile and exploring our features.</p>
              <a href="https://boostersyndrome.com/dashboard" style="display: inline-block; padding: 10px 20px; background-color: #4F46E5; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0;">Go to Dashboard</a>
              <p style="color: #666; font-size: 12px;">If you have any questions, please contact our support team.</p>
            </body>
          </html>
        HTML
      }
    end

    def self.password_reset(user, token)
      {
        subject: "Reset Your Password",
        body: <<~HTML
          <html>
            <body style="font-family: Arial, sans-serif;">
              <h2>Password Reset Request</h2>
              <p>Hi #{user[:username]},</p>
              <p>We received a request to reset your password. Click the button below to reset it:</p>
              <a href="https://boostersyndrome.com/reset-password?token=#{token}" style="display: inline-block; padding: 10px 20px; background-color: #EF4444; color: white; text-decoration: none;">Reset Password</a>
              <p>This link expires in 1 hour.</p>
              <p>If you didn't request this, please ignore this email.</p>
            </body>
          </html>
        HTML
      }
    end

    def self.notification_digest(user, notifications)
      {
        subject: "Your Daily Digest",
        body: <<~HTML
          <html>
            <body>
              <h2>Daily Digest for #{user[:username]}</h2>
              <p>Here's what happened today:</p>
              <ul>
                #{notifications.map { |n| "<li>#{n[:message]}</li>" }.join}
              </ul>
            </body>
          </html>
        HTML
      }
    end
  end
end
