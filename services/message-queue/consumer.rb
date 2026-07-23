require 'bunny'
require 'json'

module MessageQueue
  class Consumer
    def initialize(queue_name)
      @queue_name = queue_name
      @connection = Bunny.new(automatically_recover: false)
      @connection.start

      @channel = @connection.create_channel
      @queue = @channel.queue(@queue_name, durable: true)
    end

    def start
      puts "Starting consumer for queue: #{@queue_name}"

      @queue.subscribe(block: true, manual_ack: true) do |delivery_info, properties, body|
        begin
          message = JSON.parse(body)
          process_message(message)

          @channel.ack(delivery_info.delivery_tag)
          puts "Processed message: #{message}"
        rescue StandardError => e
          puts "Error processing message: #{e.message}"
          @channel.nack(delivery_info.delivery_tag, false, true)
        end
      end
    end

    def stop
      @channel.close
      @connection.close
    end

    private

    def process_message(message)
      case message['type']
      when 'email'
        send_email(message)
      when 'notification'
        send_notification(message)
      when 'analytics'
        track_analytics(message)
      else
        puts "Unknown message type: #{message['type']}"
      end
    end

    def send_email(message)
      puts "Sending email to: #{message['to']}"
    end

    def send_notification(message)
      puts "Sending notification to user: #{message['user_id']}"
    end

    def track_analytics(message)
      puts "Tracking analytics event: #{message['event_name']}"
    end
  end

  class EmailConsumer < Consumer
    def initialize
      super('emails')
    end

    private

    def process_message(message)
      send_email(message)
    end
  end

  class NotificationConsumer < Consumer
    def initialize
      super('notifications')
    end

    private

    def process_message(message)
      send_notification(message)
    end
  end
end
