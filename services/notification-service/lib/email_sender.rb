require 'mail'

class EmailSender
  def initialize
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

  def send_email(to:, subject:, body:, from: nil)
    mail = Mail.new do
      from    from || ENV.fetch('DEFAULT_FROM_EMAIL', 'noreply@example.com')
      to      to
      subject subject
      body    body
    end

    mail.deliver!
    { status: 'sent', message_id: mail.message_id }
  rescue => e
    { status: 'failed', error: e.message }
  end

  def send_template_email(to:, template:, data:)
    subject = render_template(template[:subject], data)
    body = render_template(template[:body], data)

    send_email(to: to, subject: subject, body: body)
  end

  private

  def render_template(template, data)
    result = template.dup
    data.each do |key, value|
      result.gsub!("{{#{key}}}", value.to_s)
    end
    result
  end
end
