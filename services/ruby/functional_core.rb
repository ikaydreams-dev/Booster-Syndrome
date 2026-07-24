module FunctionalCore
  class Maybe
    def self.just(value)
      Just.new(value)
    end

    def self.nothing
      Nothing.instance
    end

    def self.from_nullable(value)
      value.nil? ? Nothing.instance : Just.new(value)
    end
  end

  class Just < Maybe
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def map(&block)
      Just.new(block.call(@value))
    end

    def flat_map(&block)
      block.call(@value)
    end

    def filter(&predicate)
      predicate.call(@value) ? self : Nothing.instance
    end

    def get_or_else(_default)
      @value
    end

    def or_else(_alternative)
      self
    end

    def fold(on_nothing:, on_just:)
      on_just.call(@value)
    end

    def nothing?
      false
    end

    def just?
      true
    end
  end

  class Nothing < Maybe
    include Singleton

    def map(&block)
      self
    end

    def flat_map(&block)
      self
    end

    def filter(&predicate)
      self
    end

    def get_or_else(default)
      default
    end

    def or_else(alternative)
      alternative
    end

    def fold(on_nothing:, on_just:)
      on_nothing.call
    end

    def nothing?
      true
    end

    def just?
      false
    end
  end

  class Either
    def self.left(value)
      Left.new(value)
    end

    def self.right(value)
      Right.new(value)
    end

    def self.try(&block)
      Right.new(block.call)
    rescue => e
      Left.new(e)
    end
  end

  class Left < Either
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def map(&block)
      self
    end

    def flat_map(&block)
      self
    end

    def map_left(&block)
      Left.new(block.call(@value))
    end

    def fold(on_left:, on_right:)
      on_left.call(@value)
    end

    def get_or_else(default)
      default
    end

    def left?
      true
    end

    def right?
      false
    end
  end

  class Right < Either
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def map(&block)
      Right.new(block.call(@value))
    end

    def flat_map(&block)
      block.call(@value)
    end

    def map_left(&block)
      self
    end

    def fold(on_left:, on_right:)
      on_right.call(@value)
    end

    def get_or_else(_default)
      @value
    end

    def left?
      false
    end

    def right?
      true
    end
  end

  class IO
    def initialize(&effect)
      @effect = effect
    end

    def run
      @effect.call
    end

    def map(&transform)
      IO.new { transform.call(@effect.call) }
    end

    def flat_map(&transform)
      IO.new { transform.call(@effect.call).run }
    end

    def self.pure(value)
      IO.new { value }
    end

    def self.lift(&block)
      IO.new(&block)
    end
  end

  class Reader
    def initialize(&computation)
      @computation = computation
    end

    def run(env)
      @computation.call(env)
    end

    def map(&transform)
      Reader.new { |env| transform.call(@computation.call(env)) }
    end

    def flat_map(&transform)
      Reader.new { |env| transform.call(@computation.call(env)).run(env) }
    end

    def self.ask
      Reader.new { |env| env }
    end

    def self.pure(value)
      Reader.new { |_env| value }
    end
  end

  class Writer
    attr_reader :value, :log

    def initialize(value, log = [])
      @value = value
      @log = log
    end

    def map(&transform)
      Writer.new(transform.call(@value), @log)
    end

    def flat_map(&transform)
      result = transform.call(@value)
      Writer.new(result.value, @log + result.log)
    end

    def self.tell(message)
      Writer.new(nil, [message])
    end

    def self.pure(value)
      Writer.new(value, [])
    end
  end

  class State
    def initialize(&computation)
      @computation = computation
    end

    def run(state)
      @computation.call(state)
    end

    def map(&transform)
      State.new do |state|
        value, new_state = @computation.call(state)
        [transform.call(value), new_state]
      end
    end

    def flat_map(&transform)
      State.new do |state|
        value, new_state = @computation.call(state)
        transform.call(value).run(new_state)
      end
    end

    def self.get
      State.new { |state| [state, state] }
    end

    def self.put(new_state)
      State.new { |_state| [nil, new_state] }
    end

    def self.modify(&transform)
      State.new { |state| [nil, transform.call(state)] }
    end

    def self.pure(value)
      State.new { |state| [value, state] }
    end
  end

  class Lazy
    def initialize(&computation)
      @computation = computation
      @value = nil
      @evaluated = false
      @mutex = Mutex.new
    end

    def force
      @mutex.synchronize do
        unless @evaluated
          @value = @computation.call
          @evaluated = true
        end
        @value
      end
    end

    def map(&transform)
      Lazy.new { transform.call(force) }
    end

    def flat_map(&transform)
      Lazy.new { transform.call(force).force }
    end

    def self.pure(value)
      Lazy.new { value }
    end
  end

  class Validation
    def self.success(value)
      Success.new(value)
    end

    def self.failure(*errors)
      Failure.new(errors)
    end
  end

  class Success < Validation
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def map(&transform)
      Success.new(transform.call(@value))
    end

    def flat_map(&transform)
      transform.call(@value)
    end

    def map_errors(&transform)
      self
    end

    def fold(on_failure:, on_success:)
      on_success.call(@value)
    end

    def success?
      true
    end

    def failure?
      false
    end
  end

  class Failure < Validation
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end

    def map(&transform)
      self
    end

    def flat_map(&transform)
      self
    end

    def map_errors(&transform)
      Failure.new(@errors.map { |e| transform.call(e) })
    end

    def fold(on_failure:, on_success:)
      on_failure.call(@errors)
    end

    def success?
      false
    end

    def failure?
      true
    end

    def +(other)
      if other.is_a?(Failure)
        Failure.new(@errors + other.errors)
      else
        self
      end
    end
  end

  module Functor
    def fmap(&block)
      map(&block)
    end
  end

  module Applicative
    include Functor

    def ap(wrapped_function)
      flat_map do |value|
        wrapped_function.map { |f| f.call(value) }
      end
    end

    def self.pure(value)
      raise NotImplementedError
    end
  end

  module Monad
    include Applicative

    def bind(&block)
      flat_map(&block)
    end

    def chain(&block)
      flat_map(&block)
    end

    def >>(&block)
      flat_map { |_| block.call }
    end
  end

  module Compose
    def self.compose(*functions)
      ->(x) { functions.reverse.reduce(x) { |acc, f| f.call(acc) } }
    end

    def self.pipe(*functions)
      ->(x) { functions.reduce(x) { |acc, f| f.call(acc) } }
    end

    def self.curry(func, arity = nil)
      arity ||= func.arity

      lambda do |*args|
        if args.length >= arity
          func.call(*args.take(arity))
        else
          curry(lambda { |*more_args| func.call(*args, *more_args) }, arity - args.length)
        end
      end
    end

    def self.partial(func, *bound_args)
      lambda { |*args| func.call(*bound_args, *args) }
    end

    def self.flip(func)
      lambda { |a, b| func.call(b, a) }
    end

    def self.memoize(func)
      cache = {}
      lambda do |*args|
        cache[args] ||= func.call(*args)
      end
    end
  end

  module Traversable
    def traverse(applicative_class, &func)
      reduce(applicative_class.pure([])) do |acc, item|
        result = func.call(item)
        result.flat_map do |value|
          acc.map { |list| list + [value] }
        end
      end
    end

    def sequence(applicative_class)
      traverse(applicative_class) { |x| x }
    end
  end

  class Free
    def self.pure(value)
      Pure.new(value)
    end

    def self.lift(value)
      Suspend.new(value)
    end
  end

  class Pure < Free
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def flat_map(&block)
      block.call(@value)
    end

    def fold(on_pure:, on_suspend:)
      on_pure.call(@value)
    end
  end

  class Suspend < Free
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def flat_map(&block)
      FlatMap.new(self, block)
    end

    def fold(on_pure:, on_suspend:)
      on_suspend.call(@value)
    end
  end

  class FlatMap < Free
    def initialize(sub, cont)
      @sub = sub
      @cont = cont
    end

    def flat_map(&block)
      FlatMap.new(self, block)
    end

    def fold(on_pure:, on_suspend:)
      @sub.fold(
        on_pure: ->(value) { @cont.call(value).fold(on_pure: on_pure, on_suspend: on_suspend) },
        on_suspend: ->(value) { on_suspend.call(FlatMap.new(value, @cont)) }
      )
    end
  end

  module Kleisli
    def self.compose(f, g)
      ->(x) { f.call(x).flat_map(&g) }
    end

    def self.lift(func)
      ->(x) { Maybe.just(func.call(x)) }
    end
  end

  class Cont
    def initialize(&computation)
      @computation = computation
    end

    def run(callback)
      @computation.call(callback)
    end

    def map(&transform)
      Cont.new do |callback|
        @computation.call(->(value) { callback.call(transform.call(value)) })
      end
    end

    def flat_map(&transform)
      Cont.new do |callback|
        @computation.call(->(value) { transform.call(value).run(callback) })
      end
    end

    def self.call_cc(&block)
      Cont.new do |callback|
        escape = ->(value) { Cont.new { |_| callback.call(value) } }
        block.call(escape).run(callback)
      end
    end

    def self.pure(value)
      Cont.new { |callback| callback.call(value) }
    end
  end
end
