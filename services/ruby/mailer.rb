require 'net/smtp'
require 'mail'

module Email
  class Message
    attr_accessor :from, :to, :subject, :body, :cc, :bcc, :attachments, :headers

    def initialize
      @from = nil
      @to = []
      @cc = []
      @bcc = []
      @subject = ''
      @body = ''
      @attachments = []
      @headers = {}
      @html_body = nil
    end

    def html(content)
      @html_body = content
    end

    def attach(filename, content)
      @attachments << { filename: filename, content: content }
    end

    def to_s
      parts = []

      parts << "From: #{@from}"
      parts << "To: #{@to.join(', ')}" if @to.any?
      parts << "Cc: #{@cc.join(', ')}" if @cc.any?
      parts << "Bcc: #{@bcc.join(', ')}" if @bcc.any?
      parts << "Subject: #{@subject}"

      @headers.each do |key, value|
        parts << "#{key}: #{value}"
      end

      if @html_body
        boundary = "----=_Part_#{SecureRandom.hex(8)}"
        parts << "MIME-Version: 1.0"
        parts << "Content-Type: multipart/alternative; boundary=\"#{boundary}\""
        parts << ""
        parts << "--#{boundary}"
        parts << "Content-Type: text/plain; charset=UTF-8"
        parts << ""
        parts << @body
        parts << ""
        parts << "--#{boundary}"
        parts << "Content-Type: text/html; charset=UTF-8"
        parts << ""
        parts << @html_body
        parts << ""
        parts << "--#{boundary}--"
      else
        parts << ""
        parts << @body
      end

      parts.join("\r\n")
    end
  end

  class Mailer
    def initialize(smtp_host:, smtp_port: 587, username: nil, password: nil, use_tls: true)
      @smtp_host = smtp_host
      @smtp_port = smtp_port
      @username = username
      @password = password
      @use_tls = use_tls
    end

    def send(message)
      recipients = message.to + message.cc + message.bcc

      Net::SMTP.start(@smtp_host, @smtp_port, 'localhost',
                      @username, @password,
                      @use_tls ? :tls : :plain) do |smtp|
        smtp.send_message(message.to_s, message.from, recipients)
      end
    end

    def send_mail(from:, to:, subject:, body:, **options)
      message = Message.new
      message.from = from
      message.to = Array(to)
      message.subject = subject
      message.body = body
      message.cc = Array(options[:cc]) if options[:cc]
      message.bcc = Array(options[:bcc]) if options[:bcc]
      message.html(options[:html]) if options[:html]

      send(message)
    end
  end

  class TemplateMailer
    def initialize(mailer, template_dir: './email_templates')
      @mailer = mailer
      @template_dir = template_dir
    end

    def send_template(template_name, from:, to:, subject:, data: {})
      template_path = File.join(@template_dir, "#{template_name}.html.erb")
      template = File.read(template_path)

      html_body = render_template(template, data)

      @mailer.send_mail(
        from: from,
        to: to,
        subject: subject,
        body: strip_html(html_body),
        html: html_body
      )
    end

    private

    def render_template(template, data)
      context = TemplateContext.new(data)
      template.gsub(/\{\{(.+?)\}\}/) do
        key = $1.strip
        context.get(key)
      end
    end

    def strip_html(html)
      html.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip
    end
  end

  class TemplateContext
    def initialize(data)
      @data = data
    end

    def get(key)
      keys = key.split('.')
      result = @data

      keys.each do |k|
        result = result.is_a?(Hash) ? result[k.to_sym] || result[k] : nil
        break if result.nil?
      end

      result
    end
  end

  class Queue
    def initialize(mailer)
      @mailer = mailer
      @queue = []
      @mutex = Mutex.new
      @processing = false
    end

    def enqueue(message)
      @mutex.synchronize do
        @queue << message
      end

      process_queue unless @processing
    end

    def size
      @mutex.synchronize { @queue.size }
    end

    private

    def process_queue
      return if @processing

      @processing = true

      Thread.new do
        loop do
          message = @mutex.synchronize { @queue.shift }
          break unless message

          begin
            @mailer.send(message)
          rescue => e
            puts "Failed to send email: #{e.message}"
          end

          sleep 0.1
        end

        @processing = false
      end
    end
  end

  class BatchMailer
    def initialize(mailer, batch_size: 50, delay: 1)
      @mailer = mailer
      @batch_size = batch_size
      @delay = delay
    end

    def send_batch(messages)
      messages.each_slice(@batch_size) do |batch|
        batch.each do |message|
          begin
            @mailer.send(message)
          rescue => e
            puts "Failed to send email: #{e.message}"
          end
        end

        sleep @delay if messages.size > @batch_size
      end
    end

    def send_to_list(from:, recipients:, subject:, body:, **options)
      messages = recipients.map do |recipient|
        message = Message.new
        message.from = from
        message.to = [recipient]
        message.subject = subject
        message.body = body
        message.html(options[:html]) if options[:html]
        message
      end

      send_batch(messages)
    end
  end

  class Newsletter
    def initialize(mailer)
      @mailer = mailer
      @subscribers = []
    end

    def subscribe(email)
      @subscribers << email unless @subscribers.include?(email)
    end

    def unsubscribe(email)
      @subscribers.delete(email)
    end

    def send_newsletter(from:, subject:, body:, **options)
      batch_mailer = BatchMailer.new(@mailer)
      batch_mailer.send_to_list(
        from: from,
        recipients: @subscribers,
        subject: subject,
        body: body,
        **options
      )
    end

    def subscriber_count
      @subscribers.size
    end
  end

  class SMTPTester
    def self.test_connection(host:, port:, username: nil, password: nil, use_tls: true)
      begin
        Net::SMTP.start(host, port, 'localhost',
                       username, password,
                       use_tls ? :tls : :plain) do |smtp|
          return { success: true, message: 'Connection successful' }
        end
      rescue => e
        return { success: false, message: e.message }
      end
    end

    def self.test_send(mailer, to:)
      message = Message.new
      message.from = 'test@example.com'
      message.to = [to]
      message.subject = 'Test Email'
      message.body = 'This is a test email.'

      begin
        mailer.send(message)
        { success: true, message: 'Test email sent' }
      rescue => e
        { success: false, message: e.message }
      end
    end
  end
end
