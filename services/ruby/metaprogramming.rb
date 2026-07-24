module Metaprogramming
  class ClassBuilder
    def initialize(name, superclass = Object)
      @klass = Class.new(superclass)
      Object.const_set(name, @klass) if name
    end

    def define_method(name, &block)
      @klass.class_eval do
        define_method(name, &block)
      end
      self
    end

    def define_class_method(name, &block)
      @klass.define_singleton_method(name, &block)
      self
    end

    def attr_accessor(*names)
      @klass.class_eval do
        attr_accessor(*names)
      end
      self
    end

    def attr_reader(*names)
      @klass.class_eval do
        attr_reader(*names)
      end
      self
    end

    def attr_writer(*names)
      @klass.class_eval do
        attr_writer(*names)
      end
      self
    end

    def include_module(mod)
      @klass.include(mod)
      self
    end

    def extend_module(mod)
      @klass.extend(mod)
      self
    end

    def build
      @klass
    end
  end

  module MethodMissing
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def dynamic_methods(&block)
        @dynamic_method_handler = block
      end

      def method_missing(method_name, *args, &block)
        if @dynamic_method_handler
          @dynamic_method_handler.call(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @dynamic_method_handler ? true : super
      end
    end
  end

  class DSL
    def initialize(&block)
      @commands = []
      instance_eval(&block) if block_given?
    end

    def method_missing(method_name, *args, &block)
      @commands << { method: method_name, args: args, block: block }
    end

    def respond_to_missing?(method_name, include_private = false)
      true
    end

    def commands
      @commands
    end

    def execute(context)
      @commands.each do |cmd|
        context.send(cmd[:method], *cmd[:args], &cmd[:block])
      end
    end
  end

  class Proxy
    def initialize(target)
      @target = target
      @before_hooks = Hash.new { |h, k| h[k] = [] }
      @after_hooks = Hash.new { |h, k| h[k] = [] }
      @around_hooks = Hash.new { |h, k| h[k] = [] }
    end

    def before(method_name, &block)
      @before_hooks[method_name] << block
    end

    def after(method_name, &block)
      @after_hooks[method_name] << block
    end

    def around(method_name, &block)
      @around_hooks[method_name] << block
    end

    def method_missing(method_name, *args, &block)
      @before_hooks[method_name].each { |hook| hook.call(*args) }

      result = if @around_hooks[method_name].any?
        @around_hooks[method_name].reduce(-> { @target.send(method_name, *args, &block) }) do |chain, hook|
          -> { hook.call(chain) }
        end.call
      else
        @target.send(method_name, *args, &block)
      end

      @after_hooks[method_name].each { |hook| hook.call(result) }

      result
    end

    def respond_to_missing?(method_name, include_private = false)
      @target.respond_to?(method_name, include_private)
    end
  end

  module AttributeAccessor
    def lazy_attr_reader(name, &block)
      define_method(name) do
        ivar = "@#{name}"
        if instance_variable_defined?(ivar)
          instance_variable_get(ivar)
        else
          value = instance_eval(&block)
          instance_variable_set(ivar, value)
          value
        end
      end
    end

    def memoize(method_name)
      original_method = instance_method(method_name)

      define_method(method_name) do |*args|
        @_memoize_cache ||= {}
        cache_key = [method_name, args]

        if @_memoize_cache.key?(cache_key)
          @_memoize_cache[cache_key]
        else
          result = original_method.bind(self).call(*args)
          @_memoize_cache[cache_key] = result
          result
        end
      end
    end

    def delegate(*methods, to:, prefix: nil, allow_nil: false)
      methods.each do |method|
        method_name = prefix ? "#{prefix}_#{method}" : method

        define_method(method_name) do |*args, &block|
          target = send(to)

          if target.nil?
            raise "#{to} is nil" unless allow_nil
            return nil
          end

          target.send(method, *args, &block)
        end
      end
    end

    def alias_method_chain(target, feature)
      aliased_target = "#{target}_without_#{feature}"
      alias_method aliased_target, target
      alias_method target, "#{target}_with_#{feature}"
    end
  end

  class MethodDecorator
    def self.decorate(klass, method_name, &decorator)
      original_method = klass.instance_method(method_name)

      klass.define_method(method_name) do |*args, &block|
        decorator.call(self, original_method.bind(self), *args, &block)
      end
    end

    def self.benchmark(klass, method_name)
      decorate(klass, method_name) do |obj, original, *args, &block|
        start_time = Time.now
        result = original.call(*args, &block)
        elapsed = Time.now - start_time
        puts "#{klass}##{method_name} took #{elapsed}s"
        result
      end
    end

    def self.retry_on_failure(klass, method_name, max_retries: 3, delay: 1)
      decorate(klass, method_name) do |obj, original, *args, &block|
        retries = 0
        begin
          original.call(*args, &block)
        rescue => e
          retries += 1
          if retries < max_retries
            sleep delay
            retry
          else
            raise e
          end
        end
      end
    end

    def self.log_calls(klass, method_name)
      decorate(klass, method_name) do |obj, original, *args, &block|
        puts "Calling #{klass}##{method_name} with args: #{args.inspect}"
        result = original.call(*args, &block)
        puts "#{klass}##{method_name} returned: #{result.inspect}"
        result
      end
    end
  end

  module Singleton
    def self.included(base)
      base.class_eval do
        @instance = nil
        @mutex = Mutex.new

        def self.instance
          return @instance if @instance

          @mutex.synchronize do
            @instance ||= new
          end
        end

        private_class_method :new
      end
    end
  end

  class ObjectSpace
    def self.each_object(klass = Object, &block)
      ::ObjectSpace.each_object(klass, &block)
    end

    def self.count_objects(klass = Object)
      count = 0
      each_object(klass) { count += 1 }
      count
    end

    def self.find_instances(klass)
      instances = []
      each_object(klass) { |obj| instances << obj }
      instances
    end

    def self.deep_copy(obj)
      Marshal.load(Marshal.dump(obj))
    end
  end

  module Hooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def inherited(subclass)
        super
        @inherited_callbacks&.each { |callback| callback.call(subclass) }
      end

      def on_inherited(&block)
        @inherited_callbacks ||= []
        @inherited_callbacks << block
      end

      def method_added(method_name)
        super
        @method_added_callbacks&.each { |callback| callback.call(method_name) }
      end

      def on_method_added(&block)
        @method_added_callbacks ||= []
        @method_added_callbacks << block
      end

      def singleton_method_added(method_name)
        super
        @singleton_method_added_callbacks&.each { |callback| callback.call(method_name) }
      end

      def on_singleton_method_added(&block)
        @singleton_method_added_callbacks ||= []
        @singleton_method_added_callbacks << block
      end
    end
  end

  class ConstantWatcher
    def self.watch(const_name, &block)
      ::Module.prepend(Module.new do
        define_method(:const_set) do |name, value|
          if name == const_name
            block.call(name, value)
          end
          super(name, value)
        end
      end)
    end

    def self.all_constants(mod = Object, visited = Set.new)
      return [] if visited.include?(mod)
      visited << mod

      constants = []
      mod.constants(false).each do |const|
        begin
          value = mod.const_get(const)
          constants << "#{mod}::#{const}"

          if value.is_a?(Module)
            constants += all_constants(value, visited)
          end
        rescue
          next
        end
      end

      constants
    end
  end

  module DynamicModule
    def self.create(name = nil, &block)
      mod = Module.new
      mod.module_eval(&block) if block_given?
      Object.const_set(name, mod) if name
      mod
    end

    def self.merge(*modules)
      Module.new do
        modules.each { |mod| include mod }
      end
    end
  end

  class TracePoint
    def self.trace_calls(klass, method_name)
      ::TracePoint.new(:call) do |tp|
        if tp.defined_class == klass && tp.method_id == method_name
          puts "Called #{klass}##{method_name} at #{tp.path}:#{tp.lineno}"
        end
      end.enable
    end

    def self.trace_all_methods(klass)
      ::TracePoint.new(:call) do |tp|
        if tp.defined_class == klass
          puts "Called #{klass}##{tp.method_id}"
        end
      end.enable
    end
  end

  class Introspection
    def self.method_source(klass, method_name)
      method = klass.instance_method(method_name)
      file, line = method.source_location
      { file: file, line: line }
    end

    def self.method_arity(klass, method_name)
      klass.instance_method(method_name).arity
    end

    def self.method_parameters(klass, method_name)
      klass.instance_method(method_name).parameters
    end

    def self.ancestors_chain(klass)
      klass.ancestors
    end

    def self.method_lookup_path(klass, method_name)
      klass.ancestors.select { |ancestor| ancestor.method_defined?(method_name) }
    end
  end
end
