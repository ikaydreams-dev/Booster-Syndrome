module Streams
  class LazyIterator
    include Enumerable

    def initialize(collection)
      @collection = collection
    end

    def each(&block)
      @collection.each(&block)
    end

    def map(&block)
      LazyIterator.new(
        Enumerator.new do |yielder|
          @collection.each do |item|
            yielder << block.call(item)
          end
        end
      )
    end

    def filter(&block)
      LazyIterator.new(
        Enumerator.new do |yielder|
          @collection.each do |item|
            yielder << item if block.call(item)
          end
        end
      )
    end

    def reduce(initial = nil, &block)
      if initial.nil?
        accumulator = nil
        first = true
        @collection.each do |item|
          if first
            accumulator = item
            first = false
          else
            accumulator = block.call(accumulator, item)
          end
        end
        accumulator
      else
        @collection.reduce(initial, &block)
      end
    end

    def take(n)
      LazyIterator.new(
        Enumerator.new do |yielder|
          count = 0
          @collection.each do |item|
            break if count >= n
            yielder << item
            count += 1
          end
        end
      )
    end

    def drop(n)
      LazyIterator.new(
        Enumerator.new do |yielder|
          count = 0
          @collection.each do |item|
            if count >= n
              yielder << item
            end
            count += 1
          end
        end
      )
    end

    def flat_map(&block)
      LazyIterator.new(
        Enumerator.new do |yielder|
          @collection.each do |item|
            result = block.call(item)
            if result.respond_to?(:each)
              result.each { |r| yielder << r }
            else
              yielder << result
            end
          end
        end
      )
    end

    def chunk_while(&block)
      LazyIterator.new(
        Enumerator.new do |yielder|
          chunk = []
          prev = nil

          @collection.each do |item|
            if prev.nil? || block.call(prev, item)
              chunk << item
            else
              yielder << chunk unless chunk.empty?
              chunk = [item]
            end
            prev = item
          end

          yielder << chunk unless chunk.empty?
        end
      )
    end

    def to_a
      @collection.to_a
    end
  end

  class Stream
    def self.of(*elements)
      new(elements)
    end

    def self.range(start, stop, step = 1)
      new((start..stop).step(step))
    end

    def self.generate(&block)
      new(
        Enumerator.new do |yielder|
          loop { yielder << block.call }
        end
      )
    end

    def self.iterate(seed, &block)
      new(
        Enumerator.new do |yielder|
          current = seed
          loop do
            yielder << current
            current = block.call(current)
          end
        end
      )
    end

    def initialize(source)
      @source = source
      @operations = []
    end

    def map(&block)
      stream = dup
      stream.operations << [:map, block]
      stream
    end

    def filter(&block)
      stream = dup
      stream.operations << [:filter, block]
      stream
    end

    def flat_map(&block)
      stream = dup
      stream.operations << [:flat_map, block]
      stream
    end

    def take(n)
      stream = dup
      stream.operations << [:take, n]
      stream
    end

    def drop(n)
      stream = dup
      stream.operations << [:drop, n]
      stream
    end

    def distinct
      stream = dup
      stream.operations << [:distinct, nil]
      stream
    end

    def sorted(&block)
      stream = dup
      stream.operations << [:sorted, block]
      stream
    end

    def peek(&block)
      stream = dup
      stream.operations << [:peek, block]
      stream
    end

    def collect
      result = @source

      @operations.each do |op, arg|
        case op
        when :map
          result = result.map(&arg)
        when :filter
          result = result.select(&arg)
        when :flat_map
          result = result.flat_map(&arg)
        when :take
          result = result.take(arg)
        when :drop
          result = result.drop(arg)
        when :distinct
          result = result.uniq
        when :sorted
          result = arg ? result.sort(&arg) : result.sort
        when :peek
          result = result.map { |item| arg.call(item); item }
        end
      end

      result.to_a
    end

    def to_a
      collect
    end

    def each(&block)
      collect.each(&block)
    end

    def reduce(initial = nil, &block)
      collect.reduce(initial, &block)
    end

    def count
      collect.size
    end

    protected

    attr_accessor :operations

    def dup
      stream = super
      stream.operations = @operations.dup
      stream
    end
  end
end
