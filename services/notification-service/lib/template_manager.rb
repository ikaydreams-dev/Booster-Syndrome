class TemplateManager
  TEMPLATES = {
    welcome: {
      subject: 'Welcome to {{app_name}}!',
      body: "Hello {{name}},\n\nWelcome to {{app_name}}! We're excited to have you onboard.\n\nBest regards,\nThe Team"
    },
    password_reset: {
      subject: 'Reset Your Password',
      body: "Hello {{name}},\n\nClick the link below to reset your password:\n{{reset_link}}\n\nIf you didn't request this, please ignore this email."
    },
    verification: {
      subject: 'Verify Your Email',
      body: "Hello {{name}},\n\nYour verification code is: {{code}}\n\nThis code will expire in 10 minutes."
    },
    notification: {
      subject: 'New Notification',
      body: "Hello {{name}},\n\n{{message}}\n\nBest regards,\nThe Team"
    }
  }.freeze

  def self.get_template(name)
    TEMPLATES[name.to_sym]
  end

  def self.render(name, data)
    template = get_template(name)
    return nil unless template

    {
      subject: render_string(template[:subject], data),
      body: render_string(template[:body], data)
    }
  end

  private

  def self.render_string(template, data)
    result = template.dup
    data.each do |key, value|
      result.gsub!("{{#{key}}}", value.to_s)
    end
    result
  end
end
