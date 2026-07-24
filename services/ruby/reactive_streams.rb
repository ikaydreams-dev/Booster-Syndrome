module ReactiveStreams
  class Observable
    def initialize(&producer)
      @producer = producer
    end

    def subscribe(observer)
      @producer.call(observer)
    end

    def map(&transform)
      Observable.new do |observer|
        subscribe(MapObserver.new(observer, transform))
      end
    end

    def filter(&predicate)
      Observable.new do |observer|
        subscribe(FilterObserver.new(observer, predicate))
      end
    end

    def flat_map(&transform)
      Observable.new do |observer|
        subscribe(FlatMapObserver.new(observer, transform))
      end
    end

    def take(count)
      Observable.new do |observer|
        subscribe(TakeObserver.new(observer, count))
      end
    end

    def skip(count)
      Observable.new do |observer|
        subscribe(SkipObserver.new(observer, count))
      end
    end

    def debounce(duration)
      Observable.new do |observer|
        subscribe(DebounceObserver.new(observer, duration))
      end
    end

    def throttle(duration)
      Observable.new do |observer|
        subscribe(ThrottleObserver.new(observer, duration))
      end
    end

    def distinct
      Observable.new do |observer|
        subscribe(DistinctObserver.new(observer))
      end
    end

    def distinct_until_changed
      Observable.new do |observer|
        subscribe(DistinctUntilChangedObserver.new(observer))
      end
    end

    def merge(other)
      Observable.new do |observer|
        subscribe(observer)
        other.subscribe(observer)
      end
    end

    def combine_latest(other)
      Observable.new do |observer|
        values = {}
        mutex = Mutex.new

        self.subscribe(Observer.new(
          on_next: ->(value) {
            mutex.synchronize do
              values[:left] = value
              observer.on_next([values[:left], values[:right]]) if values[:right]
            end
          }
        ))

        other.subscribe(Observer.new(
          on_next: ->(value) {
            mutex.synchronize do
              values[:right] = value
              observer.on_next([values[:left], values[:right]]) if values[:left]
            end
          }
        ))
      end
    end

    def zip(other)
      Observable.new do |observer|
        left_buffer = []
        right_buffer = []
        mutex = Mutex.new

        self.subscribe(Observer.new(
          on_next: ->(value) {
            mutex.synchronize do
              left_buffer << value
              if right_buffer.any?
                observer.on_next([left_buffer.shift, right_buffer.shift])
              end
            end
          }
        ))

        other.subscribe(Observer.new(
          on_next: ->(value) {
            mutex.synchronize do
              right_buffer << value
              if left_buffer.any?
                observer.on_next([left_buffer.shift, right_buffer.shift])
              end
            end
          }
        ))
      end
    end

    def scan(initial, &accumulator)
      Observable.new do |observer|
        acc = initial
        subscribe(Observer.new(
          on_next: ->(value) {
            acc = accumulator.call(acc, value)
            observer.on_next(acc)
          }
        ))
      end
    end

    def reduce(initial, &accumulator)
      Observable.new do |observer|
        acc = initial
        subscribe(Observer.new(
          on_next: ->(value) { acc = accumulator.call(acc, value) },
          on_complete: -> { observer.on_next(acc); observer.on_complete }
        ))
      end
    end

    def self.from_array(array)
      Observable.new do |observer|
        array.each { |item| observer.on_next(item) }
        observer.on_complete
      end
    end

    def self.from_range(start, finish)
      Observable.new do |observer|
        (start..finish).each { |i| observer.on_next(i) }
        observer.on_complete
      end
    end

    def self.interval(duration)
      Observable.new do |observer|
        Thread.new do
          loop do
            observer.on_next(Time.now)
            sleep duration
          end
        end
      end
    end

    def self.timer(duration)
      Observable.new do |observer|
        Thread.new do
          sleep duration
          observer.on_next(Time.now)
          observer.on_complete
        end
      end
    end

    def self.empty
      Observable.new do |observer|
        observer.on_complete
      end
    end

    def self.never
      Observable.new { |observer| }
    end

    def self.throw(error)
      Observable.new do |observer|
        observer.on_error(error)
      end
    end
  end

  class Observer
    attr_reader :on_next, :on_error, :on_complete

    def initialize(on_next: nil, on_error: nil, on_complete: nil)
      @on_next = on_next || ->(value) { }
      @on_error = on_error || ->(error) { raise error }
      @on_complete = on_complete || -> { }
    end
  end

  class MapObserver < Observer
    def initialize(downstream, transform)
      @downstream = downstream
      @transform = transform
      super(
        on_next: ->(value) { @downstream.on_next.call(@transform.call(value)) },
        on_error: ->(error) { @downstream.on_error.call(error) },
        on_complete: -> { @downstream.on_complete.call }
      )
    end
  end

  class FilterObserver < Observer
    def initialize(downstream, predicate)
      @downstream = downstream
      @predicate = predicate
      super(
        on_next: ->(value) {
          @downstream.on_next.call(value) if @predicate.call(value)
        },
        on_error: ->(error) { @downstream.on_error.call(error) },
        on_complete: -> { @downstream.on_complete.call }
      )
    end
  end

  class FlatMapObserver < Observer
    def initialize(downstream, transform)
      @downstream = downstream
      @transform = transform
      super(
        on_next: ->(value) {
          inner = @transform.call(value)
          inner.subscribe(Observer.new(
            on_next: ->(inner_value) { @downstream.on_next.call(inner_value) }
          ))
        },
        on_error: ->(error) { @downstream.on_error.call(error) },
        on_complete: -> { @downstream.on_complete.call }
      )
    end
  end

  class TakeObserver < Observer
    def initialize(downstream, count)
      @downstream = downstream
      @count = count
      @taken = 0
      super(
        on_next: ->(value) {
          if @taken < @count
            @downstream.on_next.call(value)
            @taken += 1
            @downstream.on_complete.call if @taken == @count
          end
        },
        on_error: ->(error) { @downstream.on_error.call(error) },
        on_complete: -> { @downstream.on_complete.call }
      )
    end
  end

  class SkipObserver < Observer
    def initialize(downstream, count)
      @downstream = downstream
      @count = count
      @skipped = 0
      super(
        on_next: ->(value) {
          if @skipped < @count
            @skipped += 1
          else
            @downstream.on_next.call(value)
          end
        },
        on_error: ->(error) { @downstream.on_error.call(error) },
        on_complete: -> { @downstream.on_complete.call }
      )
    end
  end

  class DebounceObserver < Observer
    def initialize(downstream, duration)
      @downstream = downstream
      @duration = duration
      @timer = nil
      @mutex = Mutex.new
      super(
        on_next: ->(value) {
          @mutex.synchronize do
            @timer&.kill
            @timer = Thread.new do
              sleep @duration
              @downstream.on_next.call(value)
            end
          end
        },
        on_error: ->(error) { @downstream.on_error.call(error) },
        on_complete: -> { @downstream.on_complete.call }
      )
    end
  end

  class ThrottleObserver < Observer
    def initialize(downstream, duration)
      @downstream = downstream
      @duration = duration
      @last_emit = Time.at(0)
      @mutex = Mutex.new
      super(
        on_next: ->(value) {
          @mutex.synchronize do
            now = Time.now
            if now - @last_emit >= @duration
              @downstream.on_next.call(value)
              @last_emit = now
            end
          end
        },
        on_error: ->(error) { @downstream.on_error.call(error) },
        on_complete: -> { @downstream.on_complete.call }
      )
    end
  end

  class DistinctObserver < Observer
    def initialize(downstream)
      @downstream = downstream
      @seen = Set.new
      super(
        on_next: ->(value) {
          unless @seen.include?(value)
            @seen.add(value)
            @downstream.on_next.call(value)
          end
        },
        on_error: ->(error) { @downstream.on_error.call(error) },
        on_complete: -> { @downstream.on_complete.call }
      )
    end
  end

  class DistinctUntilChangedObserver < Observer
    def initialize(downstream)
      @downstream = downstream
      @last = nil
      @has_last = false
      super(
        on_next: ->(value) {
          if !@has_last || @last != value
            @downstream.on_next.call(value)
            @last = value
            @has_last = true
          end
        },
        on_error: ->(error) { @downstream.on_error.call(error) },
        on_complete: -> { @downstream.on_complete.call }
      )
    end
  end

  class Subject < Observable
    def initialize
      @observers = []
      @mutex = Mutex.new
      super { |observer| @mutex.synchronize { @observers << observer } }
    end

    def next(value)
      @mutex.synchronize { @observers.each { |o| o.on_next.call(value) } }
    end

    def error(error)
      @mutex.synchronize { @observers.each { |o| o.on_error.call(error) } }
    end

    def complete
      @mutex.synchronize { @observers.each { |o| o.on_complete.call } }
    end
  end

  class BehaviorSubject < Subject
    def initialize(initial_value)
      super()
      @value = initial_value
    end

    def subscribe(observer)
      observer.on_next.call(@value)
      super
    end

    def next(value)
      @value = value
      super
    end
  end

  class ReplaySubject < Subject
    def initialize(buffer_size = nil)
      super()
      @buffer = []
      @buffer_size = buffer_size
    end

    def subscribe(observer)
      @buffer.each { |value| observer.on_next.call(value) }
      super
    end

    def next(value)
      @buffer << value
      @buffer.shift if @buffer_size && @buffer.length > @buffer_size
      super
    end
  end
end
