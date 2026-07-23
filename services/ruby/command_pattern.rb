module Commands
  class Command
    def execute
      raise NotImplementedError
    end

    def undo
      raise NotImplementedError
    end

    def redo
      execute
    end
  end

  class CommandHistory
    def initialize(max_size: 100)
      @history = []
      @current = -1
      @max_size = max_size
    end

    def execute(command)
      command.execute

      @current += 1
      @history = @history[0...@current]
      @history << command

      if @history.size > @max_size
        @history.shift
        @current -= 1
      end
    end

    def undo
      return false if @current < 0

      command = @history[@current]
      command.undo
      @current -= 1

      true
    end

    def redo
      return false if @current >= @history.size - 1

      @current += 1
      command = @history[@current]
      command.redo

      true
    end

    def can_undo?
      @current >= 0
    end

    def can_redo?
      @current < @history.size - 1
    end

    def clear
      @history.clear
      @current = -1
    end

    def size
      @history.size
    end
  end

  class MacroCommand < Command
    def initialize
      @commands = []
    end

    def add(command)
      @commands << command
      self
    end

    def execute
      @commands.each(&:execute)
    end

    def undo
      @commands.reverse_each(&:undo)
    end
  end

  class ConditionalCommand < Command
    def initialize(condition, command)
      @condition = condition
      @command = command
    end

    def execute
      @command.execute if @condition.call
    end

    def undo
      @command.undo if @condition.call
    end
  end

  class AsyncCommand < Command
    def initialize(&block)
      @block = block
      @thread = nil
    end

    def execute
      @thread = Thread.new { @block.call }
      self
    end

    def wait
      @thread&.join
      self
    end

    def undo
    end
  end

  class TransactionalCommand < Command
    def initialize
      @commands = []
      @executed = []
    end

    def add(command)
      @commands << command
      self
    end

    def execute
      @executed.clear

      begin
        @commands.each do |command|
          command.execute
          @executed << command
        end
      rescue => e
        rollback
        raise e
      end
    end

    def undo
      rollback
    end

    private

    def rollback
      @executed.reverse_each do |command|
        command.undo rescue nil
      end
      @executed.clear
    end
  end

  class CommandQueue
    def initialize
      @queue = []
      @mutex = Mutex.new
      @processing = false
    end

    def enqueue(command)
      @mutex.synchronize do
        @queue << command
      end

      process_queue unless @processing
    end

    def size
      @mutex.synchronize { @queue.size }
    end

    def clear
      @mutex.synchronize do
        @queue.clear
      end
    end

    private

    def process_queue
      return if @processing

      @processing = true

      Thread.new do
        loop do
          command = @mutex.synchronize { @queue.shift }
          break unless command

          begin
            command.execute
          rescue => e
            puts "Command failed: #{e.message}"
          end
        end

        @processing = false
      end
    end
  end
end
