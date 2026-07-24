module ConcurrencyPrimitives
  class Future
    def initialize(&block)
      @mutex = Mutex.new
      @condition = ConditionVariable.new
      @value = nil
      @error = nil
      @completed = false

      Thread.new do
        begin
          result = block.call
          @mutex.synchronize do
            @value = result
            @completed = true
            @condition.broadcast
          end
        rescue => e
          @mutex.synchronize do
            @error = e
            @completed = true
            @condition.broadcast
          end
        end
      end
    end

    def get(timeout = nil)
      @mutex.synchronize do
        unless @completed
          if timeout
            @condition.wait(@mutex, timeout)
            raise TimeoutError unless @completed
          else
            @condition.wait(@mutex)
          end
        end

        raise @error if @error
        @value
      end
    end

    def completed?
      @mutex.synchronize { @completed }
    end

    def map(&transform)
      Future.new { transform.call(get) }
    end

    def flat_map(&transform)
      Future.new { transform.call(get).get }
    end

    def rescue(&handler)
      Future.new do
        begin
          get
        rescue => e
          handler.call(e)
        end
      end
    end

    def self.all(futures)
      Future.new { futures.map(&:get) }
    end

    def self.race(futures)
      Future.new do
        result_queue = Queue.new
        futures.each do |future|
          Thread.new { result_queue << future.get }
        end
        result_queue.pop
      end
    end
  end

  class Promise
    def initialize
      @mutex = Mutex.new
      @condition = ConditionVariable.new
      @value = nil
      @error = nil
      @state = :pending
      @callbacks = []
    end

    def resolve(value)
      @mutex.synchronize do
        return unless @state == :pending
        @value = value
        @state = :resolved
        @callbacks.each { |cb| cb.call(value, nil) }
        @condition.broadcast
      end
    end

    def reject(error)
      @mutex.synchronize do
        return unless @state == :pending
        @error = error
        @state = :rejected
        @callbacks.each { |cb| cb.call(nil, error) }
        @condition.broadcast
      end
    end

    def then(&on_resolve)
      promise = Promise.new
      @mutex.synchronize do
        callback = lambda do |value, error|
          if error
            promise.reject(error)
          else
            begin
              result = on_resolve.call(value)
              promise.resolve(result)
            rescue => e
              promise.reject(e)
            end
          end
        end

        if @state == :resolved
          callback.call(@value, nil)
        elsif @state == :rejected
          callback.call(nil, @error)
        else
          @callbacks << callback
        end
      end
      promise
    end

    def rescue(&on_reject)
      promise = Promise.new
      @mutex.synchronize do
        callback = lambda do |value, error|
          if error
            begin
              result = on_reject.call(error)
              promise.resolve(result)
            rescue => e
              promise.reject(e)
            end
          else
            promise.resolve(value)
          end
        end

        if @state == :resolved
          callback.call(@value, nil)
        elsif @state == :rejected
          callback.call(nil, @error)
        else
          @callbacks << callback
        end
      end
      promise
    end

    def self.all(promises)
      result_promise = Promise.new
      results = Array.new(promises.length)
      completed = 0
      mutex = Mutex.new

      promises.each_with_index do |promise, index|
        promise.then do |value|
          mutex.synchronize do
            results[index] = value
            completed += 1
            result_promise.resolve(results) if completed == promises.length
          end
        end.rescue { |error| result_promise.reject(error) }
      end

      result_promise
    end

    def self.race(promises)
      result_promise = Promise.new
      promises.each do |promise|
        promise.then { |value| result_promise.resolve(value) }
               .rescue { |error| result_promise.reject(error) }
      end
      result_promise
    end
  end

  class Channel
    def initialize(buffer_size = 0)
      @buffer_size = buffer_size
      @queue = Queue.new
      @closed = false
      @mutex = Mutex.new
    end

    def send(value)
      @mutex.synchronize do
        raise "Channel closed" if @closed
        @queue << value
      end
    end

    def receive
      @mutex.synchronize do
        raise "Channel closed" if @closed && @queue.empty?
        @queue.pop(true)
      end
    rescue ThreadError
      nil
    end

    def close
      @mutex.synchronize { @closed = true }
    end

    def closed?
      @mutex.synchronize { @closed }
    end

    def each(&block)
      loop do
        value = receive
        break if value.nil?
        block.call(value)
      end
    end
  end

  class Semaphore
    def initialize(count)
      @count = count
      @mutex = Mutex.new
      @condition = ConditionVariable.new
    end

    def acquire
      @mutex.synchronize do
        @condition.wait(@mutex) while @count <= 0
        @count -= 1
      end
    end

    def release
      @mutex.synchronize do
        @count += 1
        @condition.signal
      end
    end

    def with
      acquire
      begin
        yield
      ensure
        release
      end
    end
  end

  class CountDownLatch
    def initialize(count)
      @count = count
      @mutex = Mutex.new
      @condition = ConditionVariable.new
    end

    def count_down
      @mutex.synchronize do
        @count -= 1
        @condition.broadcast if @count <= 0
      end
    end

    def wait
      @mutex.synchronize do
        @condition.wait(@mutex) while @count > 0
      end
    end
  end

  class CyclicBarrier
    def initialize(parties, &action)
      @parties = parties
      @action = action
      @count = parties
      @mutex = Mutex.new
      @condition = ConditionVariable.new
      @generation = 0
    end

    def await
      @mutex.synchronize do
        generation = @generation
        @count -= 1

        if @count == 0
          @action&.call
          @count = @parties
          @generation += 1
          @condition.broadcast
        else
          @condition.wait(@mutex) while generation == @generation
        end
      end
    end
  end

  class ReadWriteLock
    def initialize
      @readers = 0
      @writers = 0
      @write_waiting = 0
      @mutex = Mutex.new
      @read_condition = ConditionVariable.new
      @write_condition = ConditionVariable.new
    end

    def read_lock
      @mutex.synchronize do
        @read_condition.wait(@mutex) while @writers > 0 || @write_waiting > 0
        @readers += 1
      end
    end

    def read_unlock
      @mutex.synchronize do
        @readers -= 1
        @write_condition.signal if @readers == 0
      end
    end

    def write_lock
      @mutex.synchronize do
        @write_waiting += 1
        @write_condition.wait(@mutex) while @readers > 0 || @writers > 0
        @write_waiting -= 1
        @writers += 1
      end
    end

    def write_unlock
      @mutex.synchronize do
        @writers -= 1
        @write_condition.signal
        @read_condition.broadcast
      end
    end

    def with_read_lock
      read_lock
      begin
        yield
      ensure
        read_unlock
      end
    end

    def with_write_lock
      write_lock
      begin
        yield
      ensure
        write_unlock
      end
    end
  end

  class ThreadPool
    def initialize(size)
      @size = size
      @queue = Queue.new
      @workers = []
      @mutex = Mutex.new
      @running = true

      @size.times do
        @workers << Thread.new { worker_loop }
      end
    end

    def submit(&block)
      @mutex.synchronize do
        raise "ThreadPool is shutdown" unless @running
        @queue << block
      end
    end

    def shutdown
      @mutex.synchronize { @running = false }
      @size.times { @queue << nil }
      @workers.each(&:join)
    end

    private

    def worker_loop
      loop do
        task = @queue.pop
        break if task.nil?
        begin
          task.call
        rescue => e
          warn "Task failed: #{e.message}"
        end
      end
    end
  end

  class Atomic
    def initialize(value)
      @value = value
      @mutex = Mutex.new
    end

    def get
      @mutex.synchronize { @value }
    end

    def set(new_value)
      @mutex.synchronize { @value = new_value }
    end

    def compare_and_set(expected, new_value)
      @mutex.synchronize do
        if @value == expected
          @value = new_value
          true
        else
          false
        end
      end
    end

    def get_and_set(new_value)
      @mutex.synchronize do
        old_value = @value
        @value = new_value
        old_value
      end
    end

    def update(&block)
      @mutex.synchronize { @value = block.call(@value) }
    end
  end
end
