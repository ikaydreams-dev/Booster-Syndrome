module DependencyInjection
  class Container
    def initialize
      @services = {}
      @singletons = {}
      @factories = {}
      @mutex = Mutex.new
    end

    def register(name, klass = nil, singleton: false, &block)
      @mutex.synchronize do
        if block_given?
          @factories[name] = block
        else
          @services[name] = klass
        end

        @singletons[name] = true if singleton
      end
    end

    def singleton(name, klass = nil, &block)
      register(name, klass, singleton: true, &block)
    end

    def resolve(name, **args)
      @mutex.synchronize do
        if @singletons[name] && @instances&.key?(name)
          return @instances[name]
        end

        instance = create_instance(name, **args)

        if @singletons[name]
          @instances ||= {}
          @instances[name] = instance
        end

        instance
      end
    end

    def registered?(name)
      @services.key?(name) || @factories.key?(name)
    end

    def clear
      @mutex.synchronize do
        @services.clear
        @factories.clear
        @singletons.clear
        @instances&.clear
      end
    end

    private

    def create_instance(name, **args)
      if @factories[name]
        @factories[name].call(**args)
      elsif @services[name]
        klass = @services[name]
        klass.new(**args)
      else
        raise "Service '#{name}' not registered"
      end
    end
  end

  module Injectable
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def inject(*dependencies)
        @dependencies = dependencies

        define_method(:initialize) do |**args|
          dependencies.each do |dep|
            instance_variable_set("@#{dep}", args[dep])
          end
        end

        attr_reader(*dependencies)
      end

      def dependencies
        @dependencies || []
      end
    end
  end

  class ServiceLocator
    @@container = Container.new

    def self.register(name, klass = nil, singleton: false, &block)
      @@container.register(name, klass, singleton: singleton, &block)
    end

    def self.singleton(name, klass = nil, &block)
      @@container.singleton(name, klass, &block)
    end

    def self.resolve(name, **args)
      @@container.resolve(name, **args)
    end

    def self.registered?(name)
      @@container.registered?(name)
    end

    def self.clear
      @@container.clear
    end
  end

  class Builder
    def initialize
      @dependencies = {}
    end

    def with(name, value)
      @dependencies[name] = value
      self
    end

    def build(klass)
      instance = klass.allocate

      if klass.respond_to?(:dependencies)
        klass.dependencies.each do |dep|
          value = @dependencies[dep] || raise("Missing dependency: #{dep}")
          instance.instance_variable_set("@#{dep}", value)
        end
      end

      instance.send(:initialize) if instance.respond_to?(:initialize, true)
      instance
    end
  end

  class AutoWiring
    def initialize(container)
      @container = container
    end

    def create(klass, **explicit_args)
      if klass.respond_to?(:dependencies)
        deps = klass.dependencies
        args = {}

        deps.each do |dep|
          if explicit_args.key?(dep)
            args[dep] = explicit_args[dep]
          elsif @container.registered?(dep)
            args[dep] = @container.resolve(dep)
          else
            raise "Cannot autowire dependency: #{dep}"
          end
        end

        klass.new(**args)
      else
        klass.new(**explicit_args)
      end
    end
  end
end
