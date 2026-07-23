module Events
  class EventEmitter
    def initialize
      @listeners = Hash.new { |h, k| h[k] = [] }
      @max_listeners = 10
    end

    def on(event, &block)
      check_listener_limit(event)
      @listeners[event] << block
      self
    end

    alias_method :add_listener, :on

    def once(event, &block)
      wrapper = lambda do |*args|
        block.call(*args)
        remove_listener(event, wrapper)
      end

      on(event, &wrapper)
    end

    def emit(event, *args)
      return false unless @listeners.key?(event)

      @listeners[event].each do |listener|
        listener.call(*args)
      end

      true
    end

    def remove_listener(event, listener)
      @listeners[event].delete(listener)
      self
    end

    def remove_all_listeners(event = nil)
      if event
        @listeners.delete(event)
      else
        @listeners.clear
      end
      self
    end

    def listeners(event)
      @listeners[event].dup
    end

    def listener_count(event)
      @listeners[event].size
    end

    def event_names
      @listeners.keys
    end

    def set_max_listeners(n)
      @max_listeners = n
      self
    end

    private

    def check_listener_limit(event)
      count = @listeners[event].size
      if count >= @max_listeners
        warn "Warning: Possible EventEmitter memory leak detected. " \
             "#{count + 1} listeners added for event '#{event}'. " \
             "Use set_max_listeners to increase limit."
      end
    end
  end

  class AsyncEventEmitter < EventEmitter
    def emit(event, *args)
      return false unless @listeners.key?(event)

      @listeners[event].each do |listener|
        Thread.new { listener.call(*args) }
      end

      true
    end
  end

  class PriorityEventEmitter
    def initialize
      @listeners = Hash.new { |h, k| h[k] = [] }
    end

    def on(event, priority: 0, &block)
      @listeners[event] << { priority: priority, handler: block }
      @listeners[event].sort_by! { |l| -l[:priority] }
      self
    end

    def emit(event, *args)
      return false unless @listeners.key?(event)

      @listeners[event].each do |listener|
        listener[:handler].call(*args)
      end

      true
    end

    def remove_listener(event, handler)
      @listeners[event].reject! { |l| l[:handler] == handler }
      self
    end

    def remove_all_listeners(event = nil)
      if event
        @listeners.delete(event)
      else
        @listeners.clear
      end
      self
    end
  end

  class EventBus
    def self.instance
      @instance ||= new
    end

    def initialize
      @emitter = EventEmitter.new
    end

    def subscribe(event, &block)
      @emitter.on(event, &block)
    end

    def publish(event, *args)
      @emitter.emit(event, *args)
    end

    def unsubscribe(event, listener = nil)
      if listener
        @emitter.remove_listener(event, listener)
      else
        @emitter.remove_all_listeners(event)
      end
    end

    def clear
      @emitter.remove_all_listeners
    end
  end
end
