require 'json'

module Messaging
  class Message
    attr_reader :id, :topic, :payload, :timestamp, :headers

    def initialize(topic, payload, headers: {})
      @id = SecureRandom.uuid
      @topic = topic
      @payload = payload
      @timestamp = Time.now
      @headers = headers
      @attempts = 0
    end

    def increment_attempts
      @attempts += 1
    end

    def attempts
      @attempts
    end

    def to_h
      {
        id: @id,
        topic: @topic,
        payload: @payload,
        timestamp: @timestamp.iso8601,
        headers: @headers,
        attempts: @attempts
      }
    end
  end

  class Queue
    def initialize(name)
      @name = name
      @messages = []
      @processing = []
      @dead_letter = []
      @mutex = Mutex.new
      @condition = ConditionVariable.new
    end

    def enqueue(message)
      @mutex.synchronize do
        @messages << message
        @condition.signal
      end
    end

    def dequeue(timeout: nil)
      @mutex.synchronize do
        if @messages.empty? && timeout
          @condition.wait(@mutex, timeout)
        end

        message = @messages.shift
        @processing << message if message
        message
      end
    end

    def ack(message_id)
      @mutex.synchronize do
        @processing.reject! { |m| m.id == message_id }
      end
    end

    def nack(message_id, requeue: true)
      @mutex.synchronize do
        message = @processing.find { |m| m.id == message_id }
        return unless message

        @processing.delete(message)

        if requeue && message.attempts < 3
          message.increment_attempts
          @messages.unshift(message)
        else
          @dead_letter << message
        end
      end
    end

    def size
      @mutex.synchronize { @messages.size }
    end

    def processing_count
      @mutex.synchronize { @processing.size }
    end

    def dead_letter_count
      @mutex.synchronize { @dead_letter.size }
    end

    def purge
      @mutex.synchronize do
        @messages.clear
        @processing.clear
      end
    end
  end

  class Topic
    def initialize(name)
      @name = name
      @subscribers = []
      @mutex = Mutex.new
    end

    def subscribe(subscriber)
      @mutex.synchronize do
        @subscribers << subscriber unless @subscribers.include?(subscriber)
      end
    end

    def unsubscribe(subscriber)
      @mutex.synchronize do
        @subscribers.delete(subscriber)
      end
    end

    def publish(message)
      subscribers = @mutex.synchronize { @subscribers.dup }

      subscribers.each do |subscriber|
        Thread.new do
          begin
            subscriber.call(message)
          rescue => e
            puts "Subscriber error: #{e.message}"
          end
        end
      end
    end

    def subscriber_count
      @mutex.synchronize { @subscribers.size }
    end
  end

  class PubSub
    def initialize
      @topics = {}
      @mutex = Mutex.new
    end

    def create_topic(name)
      @mutex.synchronize do
        @topics[name] ||= Topic.new(name)
      end
    end

    def subscribe(topic_name, &block)
      topic = create_topic(topic_name)
      topic.subscribe(block)
    end

    def publish(topic_name, payload, headers: {})
      topic = @mutex.synchronize { @topics[topic_name] }
      return unless topic

      message = Message.new(topic_name, payload, headers: headers)
      topic.publish(message)
    end

    def topics
      @mutex.synchronize { @topics.keys }
    end
  end

  class Consumer
    def initialize(queue)
      @queue = queue
      @running = false
      @thread = nil
      @handler = nil
    end

    def on_message(&block)
      @handler = block
    end

    def start
      return if @running

      @running = true
      @thread = Thread.new { consume_loop }
    end

    def stop
      @running = false
      @thread&.join
    end

    private

    def consume_loop
      while @running
        message = @queue.dequeue(timeout: 1)
        next unless message

        begin
          @handler&.call(message)
          @queue.ack(message.id)
        rescue => e
          puts "Message processing failed: #{e.message}"
          @queue.nack(message.id, requeue: true)
        end
      end
    end
  end

  class Producer
    def initialize(queue)
      @queue = queue
    end

    def send(topic, payload, headers: {})
      message = Message.new(topic, payload, headers: headers)
      @queue.enqueue(message)
      message
    end

    def send_batch(messages)
      messages.map do |msg|
        send(msg[:topic], msg[:payload], headers: msg[:headers] || {})
      end
    end
  end

  class DelayedQueue < Queue
    def enqueue(message, delay: 0)
      if delay > 0
        Thread.new do
          sleep delay
          super(message)
        end
      else
        super(message)
      end
    end
  end

  class PriorityQueue < Queue
    def enqueue(message)
      @mutex.synchronize do
        priority = message.headers[:priority] || 0
        index = @messages.bsearch_index { |m| (m.headers[:priority] || 0) < priority } || @messages.size
        @messages.insert(index, message)
        @condition.signal
      end
    end
  end

  class MessageBroker
    def initialize
      @queues = {}
      @topics = {}
      @mutex = Mutex.new
    end

    def create_queue(name, type: :standard)
      @mutex.synchronize do
        @queues[name] ||= case type
        when :standard
          Queue.new(name)
        when :delayed
          DelayedQueue.new(name)
        when :priority
          PriorityQueue.new(name)
        else
          Queue.new(name)
        end
      end
    end

    def get_queue(name)
      @mutex.synchronize { @queues[name] }
    end

    def create_topic(name)
      @mutex.synchronize do
        @topics[name] ||= Topic.new(name)
      end
    end

    def get_topic(name)
      @mutex.synchronize { @topics[name] }
    end

    def stats
      {
        queues: @queues.transform_values { |q|
          {
            size: q.size,
            processing: q.processing_count,
            dead_letter: q.dead_letter_count
          }
        },
        topics: @topics.transform_values { |t|
          { subscribers: t.subscriber_count }
        }
      }
    end
  end
end
