module TransactionalMemory
  class STM
    def initialize
      @global_clock = Atomic.new(0)
      @transaction_local = Thread.current.thread_variable_get(:stm_transaction)
    end

    def atomic(&block)
      max_retries = 100
      retries = 0

      loop do
        transaction = Transaction.new(@global_clock.get)
        Thread.current.thread_variable_set(:stm_transaction, transaction)

        begin
          result = block.call
          if transaction.commit(@global_clock)
            Thread.current.thread_variable_set(:stm_transaction, nil)
            return result
          else
            retries += 1
            raise "Transaction failed after #{max_retries} retries" if retries >= max_retries
          end
        rescue => e
          Thread.current.thread_variable_set(:stm_transaction, nil)
          raise e
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

      def set(value)
        @mutex.synchronize { @value = value }
      end

      def compare_and_swap(expected, new_value)
        @mutex.synchronize do
          if @value == expected
            @value = new_value
            true
          else
            false
          end
        end
      end
    end
  end

  class Transaction
    def initialize(read_version)
      @read_version = read_version
      @read_set = {}
      @write_set = {}
      @mutex = Mutex.new
    end

    def read(ref)
      @mutex.synchronize do
        return @write_set[ref] if @write_set.key?(ref)

        value = ref.read(@read_version)
        @read_set[ref] = value
        value
      end
    end

    def write(ref, value)
      @mutex.synchronize do
        @write_set[ref] = value
      end
    end

    def commit(global_clock)
      @mutex.synchronize do
        return true if @write_set.empty?

        @read_set.each do |ref, value|
          return false unless ref.validate(@read_version)
        end

        write_version = global_clock.get + 1
        @write_set.each do |ref, value|
          ref.commit(value, write_version)
        end

        global_clock.set(write_version)
        true
      end
    end
  end

  class TVar
    def initialize(initial_value)
      @versions = { 0 => initial_value }
      @current_version = 0
      @mutex = Mutex.new
    end

    def read(read_version)
      @mutex.synchronize do
        @versions.select { |v, _| v <= read_version }.max_by { |v, _| v }&.last
      end
    end

    def write(value)
      transaction = Thread.current.thread_variable_get(:stm_transaction)
      raise "Not in transaction" unless transaction
      transaction.write(self, value)
    end

    def deref
      transaction = Thread.current.thread_variable_get(:stm_transaction)
      if transaction
        transaction.read(self)
      else
        @mutex.synchronize { @versions[@current_version] }
      end
    end

    def validate(read_version)
      @mutex.synchronize { @current_version == read_version }
    end

    def commit(value, version)
      @mutex.synchronize do
        @versions[version] = value
        @current_version = version
        cleanup_old_versions
      end
    end

    private

    def cleanup_old_versions
      if @versions.size > 10
        versions_to_keep = @versions.keys.sort.last(5)
        @versions.select! { |v, _| versions_to_keep.include?(v) }
      end
    end
  end

  class TRef
    def initialize(value)
      @tvar = TVar.new(value)
    end

    def deref
      @tvar.deref
    end

    def set!(value)
      @tvar.write(value)
    end

    def swap!(&transform)
      old_value = @tvar.deref
      new_value = transform.call(old_value)
      @tvar.write(new_value)
      new_value
    end

    def compare_and_set!(expected, new_value)
      old_value = @tvar.deref
      if old_value == expected
        @tvar.write(new_value)
        true
      else
        false
      end
    end
  end

  class TArray
    def initialize(size, initial_value = nil)
      @refs = Array.new(size) { TRef.new(initial_value) }
    end

    def [](index)
      @refs[index].deref
    end

    def []=(index, value)
      @refs[index].set!(value)
    end

    def length
      @refs.length
    end

    def each
      @refs.each_with_index do |ref, index|
        yield ref.deref, index
      end
    end

    def map(&block)
      @refs.map.with_index { |ref, index| block.call(ref.deref, index) }
    end

    def swap!(index, &transform)
      @refs[index].swap!(&transform)
    end
  end

  class THash
    def initialize
      @ref = TRef.new({})
    end

    def [](key)
      @ref.deref[key]
    end

    def []=(key, value)
      @ref.swap! { |hash| hash.merge(key => value) }
    end

    def delete(key)
      @ref.swap! do |hash|
        new_hash = hash.dup
        new_hash.delete(key)
        new_hash
      end
    end

    def keys
      @ref.deref.keys
    end

    def values
      @ref.deref.values
    end

    def each
      @ref.deref.each { |k, v| yield k, v }
    end

    def size
      @ref.deref.size
    end
  end

  class Agent
    def initialize(initial_value)
      @value = initial_value
      @queue = Queue.new
      @mutex = Mutex.new
      @error_handler = nil
      @validator = nil

      @worker = Thread.new { worker_loop }
    end

    def send_off(&action)
      @queue << action
    end

    def send(&action)
      send_off(&action)
    end

    def deref
      @mutex.synchronize { @value }
    end

    def await(timeout = nil)
      deadline = timeout ? Time.now + timeout : nil

      loop do
        return if @queue.empty?
        sleep 0.01
        raise TimeoutError if deadline && Time.now > deadline
      end
    end

    def on_error(&handler)
      @error_handler = handler
    end

    def set_validator(&validator)
      @validator = validator
    end

    def shutdown
      @queue << nil
      @worker.join
    end

    private

    def worker_loop
      loop do
        action = @queue.pop
        return if action.nil?

        begin
          new_value = action.call(@value)

          if @validator && !@validator.call(new_value)
            raise "Validation failed for value: #{new_value}"
          end

          @mutex.synchronize { @value = new_value }
        rescue => e
          @error_handler&.call(self, e)
        end
      end
    end
  end

  class Atom
    def initialize(value)
      @value = value
      @mutex = Mutex.new
      @validator = nil
      @watchers = {}
    end

    def deref
      @mutex.synchronize { @value }
    end

    def swap!(&transform)
      @mutex.synchronize do
        old_value = @value
        new_value = transform.call(old_value)

        if @validator && !@validator.call(new_value)
          raise "Validation failed for value: #{new_value}"
        end

        @value = new_value
        notify_watchers(old_value, new_value)
        new_value
      end
    end

    def reset!(new_value)
      @mutex.synchronize do
        if @validator && !@validator.call(new_value)
          raise "Validation failed for value: #{new_value}"
        end

        old_value = @value
        @value = new_value
        notify_watchers(old_value, new_value)
        new_value
      end
    end

    def compare_and_set!(expected, new_value)
      @mutex.synchronize do
        if @value == expected
          if @validator && !@validator.call(new_value)
            raise "Validation failed for value: #{new_value}"
          end

          old_value = @value
          @value = new_value
          notify_watchers(old_value, new_value)
          true
        else
          false
        end
      end
    end

    def add_watch(key, &callback)
      @mutex.synchronize do
        @watchers[key] = callback
      end
    end

    def remove_watch(key)
      @mutex.synchronize do
        @watchers.delete(key)
      end
    end

    def set_validator(&validator)
      @validator = validator
    end

    private

    def notify_watchers(old_value, new_value)
      @watchers.each do |key, callback|
        Thread.new { callback.call(key, self, old_value, new_value) }
      end
    end
  end

  class Ref
    def initialize(value)
      @value = value
      @mutex = Mutex.new
      @in_transaction = false
      @transaction_value = nil
    end

    def deref
      if @in_transaction
        @transaction_value
      else
        @mutex.synchronize { @value }
      end
    end

    def set!(value)
      raise "Must be in transaction" unless @in_transaction
      @transaction_value = value
    end

    def alter!(&transform)
      raise "Must be in transaction" unless @in_transaction
      @transaction_value = transform.call(@transaction_value)
    end

    def commute!(&transform)
      raise "Must be in transaction" unless @in_transaction
      @transaction_value = transform.call(@transaction_value)
    end

    def begin_transaction
      @mutex.synchronize do
        @in_transaction = true
        @transaction_value = @value
      end
    end

    def commit_transaction
      @mutex.synchronize do
        @value = @transaction_value
        @in_transaction = false
        @transaction_value = nil
      end
    end

    def rollback_transaction
      @mutex.synchronize do
        @in_transaction = false
        @transaction_value = nil
      end
    end
  end

  def self.dosync(&block)
    stm = STM.new
    stm.atomic(&block)
  end
end
