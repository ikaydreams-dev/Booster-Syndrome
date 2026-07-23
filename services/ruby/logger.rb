require 'time'
require 'json'

module Logging
  LEVELS = {
    debug: 0,
    info: 1,
    warn: 2,
    error: 3,
    fatal: 4
  }

  class Logger
    attr_accessor :level, :formatter

    def initialize(output: $stdout, level: :info, formatter: nil)
      @output = output
      @level = LEVELS[level]
      @formatter = formatter || DefaultFormatter.new
      @mutex = Mutex.new
    end

    def debug(message = nil, **metadata, &block)
      log(:debug, message, metadata, &block)
    end

    def info(message = nil, **metadata, &block)
      log(:info, message, metadata, &block)
    end

    def warn(message = nil, **metadata, &block)
      log(:warn, message, metadata, &block)
    end

    def error(message = nil, **metadata, &block)
      log(:error, message, metadata, &block)
    end

    def fatal(message = nil, **metadata, &block)
      log(:fatal, message, metadata, &block)
    end

    def log(level, message = nil, metadata = {}, &block)
      return if LEVELS[level] < @level

      message = block.call if block_given?

      entry = LogEntry.new(
        level: level,
        message: message,
        metadata: metadata,
        timestamp: Time.now
      )

      write(entry)
    end

    private

    def write(entry)
      formatted = @formatter.format(entry)

      @mutex.synchronize do
        @output.puts(formatted)
        @output.flush if @output.respond_to?(:flush)
      end
    end
  end

  class LogEntry
    attr_reader :level, :message, :metadata, :timestamp

    def initialize(level:, message:, metadata:, timestamp:)
      @level = level
      @message = message
      @metadata = metadata
      @timestamp = timestamp
    end

    def to_h
      {
        level: @level,
        message: @message,
        timestamp: @timestamp.iso8601,
        **@metadata
      }
    end
  end

  class DefaultFormatter
    def format(entry)
      timestamp = entry.timestamp.strftime('%Y-%m-%d %H:%M:%S')
      level = entry.level.to_s.upcase.ljust(5)

      parts = ["[#{timestamp}]", level, entry.message]

      unless entry.metadata.empty?
        metadata_str = entry.metadata.map { |k, v| "#{k}=#{v}" }.join(' ')
        parts << metadata_str
      end

      parts.join(' ')
    end
  end

  class JSONFormatter
    def format(entry)
      entry.to_h.to_json
    end
  end

  class ColoredFormatter
    COLORS = {
      debug: "\e[36m",
      info: "\e[32m",
      warn: "\e[33m",
      error: "\e[31m",
      fatal: "\e[35m"
    }
    RESET = "\e[0m"

    def format(entry)
      timestamp = entry.timestamp.strftime('%Y-%m-%d %H:%M:%S')
      color = COLORS[entry.level]
      level = entry.level.to_s.upcase.ljust(5)

      parts = [
        "#{color}[#{timestamp}]",
        level,
        "#{entry.message}#{RESET}"
      ]

      unless entry.metadata.empty?
        metadata_str = entry.metadata.map { |k, v| "#{k}=#{v}" }.join(' ')
        parts << metadata_str
      end

      parts.join(' ')
    end
  end

  class FileLogger < Logger
    def initialize(filepath, level: :info, formatter: nil, max_size: 10 * 1024 * 1024)
      @filepath = filepath
      @max_size = max_size
      @file = File.open(filepath, 'a')

      super(output: @file, level: level, formatter: formatter)
    end

    def close
      @file.close
    end

    private

    def write(entry)
      rotate_if_needed
      super
    end

    def rotate_if_needed
      return if File.size(@filepath) < @max_size

      @file.close

      if File.exist?("#{@filepath}.1")
        File.delete("#{@filepath}.1")
      end

      File.rename(@filepath, "#{@filepath}.1")
      @file = File.open(@filepath, 'a')
      @output = @file
    end
  end

  class MultiLogger
    def initialize
      @loggers = []
    end

    def add_logger(logger)
      @loggers << logger
    end

    def debug(message = nil, **metadata, &block)
      @loggers.each { |logger| logger.debug(message, **metadata, &block) }
    end

    def info(message = nil, **metadata, &block)
      @loggers.each { |logger| logger.info(message, **metadata, &block) }
    end

    def warn(message = nil, **metadata, &block)
      @loggers.each { |logger| logger.warn(message, **metadata, &block) }
    end

    def error(message = nil, **metadata, &block)
      @loggers.each { |logger| logger.error(message, **metadata, &block) }
    end

    def fatal(message = nil, **metadata, &block)
      @loggers.each { |logger| logger.fatal(message, **metadata, &block) }
    end
  end

  class StructuredLogger < Logger
    def initialize(output: $stdout, level: :info, service: nil, environment: nil)
      @service = service
      @environment = environment
      super(output: output, level: level, formatter: JSONFormatter.new)
    end

    def log(level, message = nil, metadata = {}, &block)
      enriched_metadata = metadata.dup
      enriched_metadata[:service] = @service if @service
      enriched_metadata[:environment] = @environment if @environment
      enriched_metadata[:hostname] = `hostname`.strip

      super(level, message, enriched_metadata, &block)
    end
  end

  class LogBuffer
    def initialize(max_size: 1000)
      @buffer = []
      @max_size = max_size
      @mutex = Mutex.new
    end

    def add(entry)
      @mutex.synchronize do
        @buffer << entry
        @buffer.shift if @buffer.size > @max_size
      end
    end

    def flush
      @mutex.synchronize do
        entries = @buffer.dup
        @buffer.clear
        entries
      end
    end

    def size
      @mutex.synchronize { @buffer.size }
    end

    def clear
      @mutex.synchronize { @buffer.clear }
    end

    def get(limit: nil)
      @mutex.synchronize do
        limit ? @buffer.last(limit) : @buffer.dup
      end
    end
  end

  class BufferedLogger < Logger
    def initialize(buffer:, **options)
      @buffer = buffer
      super(**options)
    end

    private

    def write(entry)
      @buffer.add(entry)
      super
    end
  end
end
