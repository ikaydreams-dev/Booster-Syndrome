require 'json'
require 'net/http'

module Notifications
  class Notification
    attr_accessor :id, :type, :title, :message, :data, :recipient, :read, :created_at

    def initialize(type:, title:, message:, recipient:, data: {})
      @id = SecureRandom.uuid
      @type = type
      @title = title
      @message = message
      @data = data
      @recipient = recipient
      @read = false
      @created_at = Time.now
    end

    def mark_as_read
      @read = true
    end

    def to_h
      {
        id: @id,
        type: @type,
        title: @title,
        message: @message,
        data: @data,
        recipient: @recipient,
        read: @read,
        created_at: @created_at.iso8601
      }
    end
  end

  class NotificationCenter
    def initialize
      @notifications = {}
      @subscribers = Hash.new { |h, k| h[k] = [] }
      @mutex = Mutex.new
    end

    def send_notification(recipient:, type:, title:, message:, data: {})
      notification = Notification.new(
        type: type,
        title: title,
        message: message,
        recipient: recipient,
        data: data
      )

      @mutex.synchronize do
        @notifications[notification.id] = notification

        if @subscribers[recipient]
          @subscribers[recipient].each do |callback|
            Thread.new { callback.call(notification) }
          end
        end
      end

      notification
    end

    def get_notifications(recipient, unread_only: false)
      @mutex.synchronize do
        notifications = @notifications.values.select { |n| n.recipient == recipient }
        notifications = notifications.reject(&:read) if unread_only
        notifications.sort_by { |n| -n.created_at.to_i }
      end
    end

    def mark_as_read(notification_id)
      @mutex.synchronize do
        notification = @notifications[notification_id]
        notification&.mark_as_read
      end
    end

    def mark_all_as_read(recipient)
      @mutex.synchronize do
        @notifications.values
          .select { |n| n.recipient == recipient }
          .each(&:mark_as_read)
      end
    end

    def delete(notification_id)
      @mutex.synchronize do
        @notifications.delete(notification_id)
      end
    end

    def subscribe(recipient, &callback)
      @mutex.synchronize do
        @subscribers[recipient] << callback
      end
    end

    def unsubscribe(recipient)
      @mutex.synchronize do
        @subscribers.delete(recipient)
      end
    end

    def count_unread(recipient)
      @mutex.synchronize do
        @notifications.values.count { |n| n.recipient == recipient && !n.read }
      end
    end
  end

  class PushNotificationService
    def initialize(api_key:, api_url:)
      @api_key = api_key
      @api_url = api_url
    end

    def send_push(device_token:, title:, body:, data: {})
      payload = {
        to: device_token,
        notification: {
          title: title,
          body: body
        },
        data: data
      }

      uri = URI.parse(@api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.path)
      request['Authorization'] = "key=#{@api_key}"
      request['Content-Type'] = 'application/json'
      request.body = payload.to_json

      response = http.request(request)

      {
        success: response.code.to_i == 200,
        response: JSON.parse(response.body)
      }
    rescue => e
      { success: false, error: e.message }
    end

    def send_to_multiple(device_tokens:, title:, body:, data: {})
      results = device_tokens.map do |token|
        send_push(device_token: token, title: title, body: body, data: data)
      end

      {
        total: results.size,
        successful: results.count { |r| r[:success] },
        failed: results.count { |r| !r[:success] }
      }
    end
  end

  class SMSService
    def initialize(api_key:, api_url:, from_number:)
      @api_key = api_key
      @api_url = api_url
      @from_number = from_number
    end

    def send_sms(to:, message:)
      payload = {
        from: @from_number,
        to: to,
        body: message
      }

      uri = URI.parse(@api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.path)
      request.basic_auth(@api_key, '')
      request.set_form_data(payload)

      response = http.request(request)

      {
        success: response.code.to_i == 200 || response.code.to_i == 201,
        response: JSON.parse(response.body)
      }
    rescue => e
      { success: false, error: e.message }
    end

    def send_batch(numbers:, message:)
      results = numbers.map do |number|
        send_sms(to: number, message: message)
      end

      {
        total: results.size,
        successful: results.count { |r| r[:success] },
        failed: results.count { |r| !r[:success] }
      }
    end
  end

  class WebhookNotifier
    def initialize
      @webhooks = {}
      @mutex = Mutex.new
    end

    def register_webhook(event:, url:, secret: nil)
      webhook_id = SecureRandom.uuid

      @mutex.synchronize do
        @webhooks[webhook_id] = {
          id: webhook_id,
          event: event,
          url: url,
          secret: secret
        }
      end

      webhook_id
    end

    def unregister_webhook(webhook_id)
      @mutex.synchronize do
        @webhooks.delete(webhook_id)
      end
    end

    def notify(event:, data:)
      webhooks = @mutex.synchronize do
        @webhooks.values.select { |w| w[:event] == event }
      end

      webhooks.map do |webhook|
        Thread.new { send_webhook(webhook, data) }
      end
    end

    private

    def send_webhook(webhook, data)
      uri = URI.parse(webhook[:url])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.path)
      request['Content-Type'] = 'application/json'

      if webhook[:secret]
        signature = OpenSSL::HMAC.hexdigest('SHA256', webhook[:secret], data.to_json)
        request['X-Webhook-Signature'] = signature
      end

      request.body = data.to_json

      response = http.request(request)

      {
        webhook_id: webhook[:id],
        success: response.code.to_i >= 200 && response.code.to_i < 300,
        status: response.code.to_i
      }
    rescue => e
      {
        webhook_id: webhook[:id],
        success: false,
        error: e.message
      }
    end
  end

  class NotificationTemplate
    attr_reader :name, :title, :body

    def initialize(name:, title:, body:)
      @name = name
      @title = title
      @body = body
    end

    def render(data = {})
      rendered_title = interpolate(@title, data)
      rendered_body = interpolate(@body, data)

      {
        title: rendered_title,
        body: rendered_body
      }
    end

    private

    def interpolate(template, data)
      template.gsub(/\{\{(\w+)\}\}/) do |match|
        key = $1.to_sym
        data[key] || match
      end
    end
  end

  class TemplateManager
    def initialize
      @templates = {}
    end

    def register(name, title:, body:)
      @templates[name] = NotificationTemplate.new(
        name: name,
        title: title,
        body: body
      )
    end

    def get(name)
      @templates[name]
    end

    def render(name, data = {})
      template = @templates[name]
      return nil unless template

      template.render(data)
    end
  end
end
