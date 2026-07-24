module ActorModel
  class Actor
    def initialize
      @mailbox = Queue.new
      @running = false
      @thread = nil
    end

    def start
      return if @running
      @running = true
      @thread = Thread.new { process_messages }
    end

    def stop
      @running = false
      @thread&.join
    end

    def send_message(message)
      @mailbox << message
    end

    def receive(pattern = nil, &block)
      if pattern
        @mailbox.select { |msg| pattern === msg }.first
      else
        @mailbox.pop
      end
    end

    private

    def process_messages
      while @running
        begin
          message = @mailbox.pop(true)
          handle_message(message)
        rescue ThreadError
          sleep 0.01
        end
      end
    end

    def handle_message(message)
      raise NotImplementedError, "Subclasses must implement handle_message"
    end
  end

  class Supervisor < Actor
    def initialize(strategy: :one_for_one)
      super()
      @strategy = strategy
      @children = []
      @max_restarts = 5
      @restart_window = 60
      @restart_times = []
    end

    def add_child(child)
      @children << child
      child.start
    end

    def remove_child(child)
      @children.delete(child)
      child.stop
    end

    def handle_message(message)
      case message[:type]
      when :child_died
        restart_child(message[:child])
      when :get_children
        message[:sender].send_message(@children)
      end
    end

    private

    def restart_child(child)
      @restart_times << Time.now
      @restart_times.reject! { |t| t < Time.now - @restart_window }

      if @restart_times.length > @max_restarts
        raise "Too many restarts"
      end

      case @strategy
      when :one_for_one
        child.stop
        child.start
      when :one_for_all
        @children.each(&:stop)
        @children.each(&:start)
      when :rest_for_one
        idx = @children.index(child)
        @children[idx..-1].each(&:stop)
        @children[idx..-1].each(&:start)
      end
    end
  end

  class GenServer < Actor
    def initialize(state = nil)
      super()
      @state = state
      @handlers = {}
    end

    def call(request, timeout = 5)
      response_queue = Queue.new
      send_message({ type: :call, request: request, sender: response_queue })
      Timeout.timeout(timeout) { response_queue.pop }
    end

    def cast(request)
      send_message({ type: :cast, request: request })
    end

    def handle_call(request, state)
      raise NotImplementedError
    end

    def handle_cast(request, state)
      raise NotImplementedError
    end

    def handle_message(message)
      case message[:type]
      when :call
        response, new_state = handle_call(message[:request], @state)
        @state = new_state
        message[:sender] << response
      when :cast
        new_state = handle_cast(message[:request], @state)
        @state = new_state
      end
    end
  end

  class Counter < GenServer
    def initialize(initial = 0)
      super(initial)
    end

    def handle_call(request, state)
      case request[:action]
      when :get
        [state, state]
      when :increment
        new_state = state + (request[:value] || 1)
        [new_state, new_state]
      when :decrement
        new_state = state - (request[:value] || 1)
        [new_state, new_state]
      else
        [{ error: "Unknown action" }, state]
      end
    end

    def handle_cast(request, state)
      case request[:action]
      when :reset
        0
      else
        state
      end
    end
  end

  class KeyValueStore < GenServer
    def initialize
      super({})
    end

    def handle_call(request, state)
      case request[:action]
      when :get
        [state[request[:key]], state]
      when :put
        new_state = state.merge(request[:key] => request[:value])
        [:ok, new_state]
      when :delete
        new_state = state.dup
        new_state.delete(request[:key])
        [:ok, new_state]
      when :keys
        [state.keys, state]
      when :values
        [state.values, state]
      else
        [{ error: "Unknown action" }, state]
      end
    end

    def handle_cast(request, state)
      case request[:action]
      when :clear
        {}
      else
        state
      end
    end
  end

  class PubSub < GenServer
    def initialize
      super({ subscribers: {}, messages: [] })
    end

    def handle_call(request, state)
      case request[:action]
      when :subscribe
        topic = request[:topic]
        subscriber = request[:subscriber]
        subscribers = state[:subscribers][topic] || []
        new_subscribers = state[:subscribers].merge(topic => (subscribers + [subscriber]))
        [:ok, state.merge(subscribers: new_subscribers)]
      when :unsubscribe
        topic = request[:topic]
        subscriber = request[:subscriber]
        subscribers = state[:subscribers][topic] || []
        new_subscribers = state[:subscribers].merge(topic => (subscribers - [subscriber]))
        [:ok, state.merge(subscribers: new_subscribers)]
      when :get_subscribers
        [state[:subscribers][request[:topic]] || [], state]
      else
        [{ error: "Unknown action" }, state]
      end
    end

    def handle_cast(request, state)
      case request[:action]
      when :publish
        topic = request[:topic]
        message = request[:message]
        subscribers = state[:subscribers][topic] || []
        subscribers.each { |s| s.send_message({ topic: topic, message: message }) }
        messages = state[:messages] + [{ topic: topic, message: message, timestamp: Time.now }]
        state.merge(messages: messages)
      else
        state
      end
    end
  end

  class TaskQueue < GenServer
    def initialize
      super({ queue: [], running: {} })
    end

    def handle_call(request, state)
      case request[:action]
      when :enqueue
        task = request[:task]
        queue = state[:queue] + [task]
        [:ok, state.merge(queue: queue)]
      when :dequeue
        queue = state[:queue]
        if queue.empty?
          [nil, state]
        else
          task = queue.first
          new_queue = queue[1..-1]
          [task, state.merge(queue: new_queue)]
        end
      when :status
        task_id = request[:task_id]
        [state[:running][task_id], state]
      when :size
        [state[:queue].length, state]
      else
        [{ error: "Unknown action" }, state]
      end
    end

    def handle_cast(request, state)
      case request[:action]
      when :mark_running
        task_id = request[:task_id]
        running = state[:running].merge(task_id => :running)
        state.merge(running: running)
      when :mark_done
        task_id = request[:task_id]
        running = state[:running].dup
        running.delete(task_id)
        state.merge(running: running)
      else
        state
      end
    end
  end

  class Registry
    def initialize
      @processes = {}
      @mutex = Mutex.new
    end

    def register(name, actor)
      @mutex.synchronize do
        @processes[name] = actor
      end
    end

    def unregister(name)
      @mutex.synchronize do
        @processes.delete(name)
      end
    end

    def lookup(name)
      @mutex.synchronize do
        @processes[name]
      end
    end

    def list
      @mutex.synchronize do
        @processes.keys
      end
    end
  end

  class Link
    def initialize(actor1, actor2)
      @actor1 = actor1
      @actor2 = actor2
      monitor_actors
    end

    private

    def monitor_actors
      Thread.new do
        loop do
          unless @actor1.alive? && @actor2.alive?
            @actor1.stop
            @actor2.stop
            break
          end
          sleep 0.1
        end
      end
    end
  end

  class Monitor
    def initialize(watcher, watched)
      @watcher = watcher
      @watched = watched
      start_monitoring
    end

    private

    def start_monitoring
      Thread.new do
        loop do
          unless @watched.alive?
            @watcher.send_message({ type: :down, actor: @watched })
            break
          end
          sleep 0.1
        end
      end
    end
  end
end
