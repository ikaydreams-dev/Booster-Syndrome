module ServiceLayer
  class BaseService
    def self.call(*args, **kwargs, &block)
      new(*args, **kwargs).call(&block)
    end

    def call
      raise NotImplementedError, "Subclasses must implement #call"
    end

    def success(data = nil)
      Result.success(data)
    end

    def failure(error)
      Result.failure(error)
    end
  end

  class Result
    attr_reader :data, :error

    def initialize(success, data = nil, error = nil)
      @success = success
      @data = data
      @error = error
    end

    def self.success(data = nil)
      new(true, data, nil)
    end

    def self.failure(error)
      new(false, nil, error)
    end

    def success?
      @success
    end

    def failure?
      !@success
    end

    def on_success(&block)
      block.call(@data) if success?
      self
    end

    def on_failure(&block)
      block.call(@error) if failure?
      self
    end

    def map(&block)
      success? ? Result.success(block.call(@data)) : self
    end

    def flat_map(&block)
      success? ? block.call(@data) : self
    end

    def value_or(default)
      success? ? @data : default
    end
  end

  class Pipeline
    def initialize
      @steps = []
    end

    def step(service_class, *args, **kwargs)
      @steps << { service: service_class, args: args, kwargs: kwargs }
      self
    end

    def execute(input = nil)
      result = Result.success(input)

      @steps.each do |step|
        return result if result.failure?

        result = result.flat_map do |data|
          step[:service].call(data, *step[:args], **step[:kwargs])
        end
      end

      result
    end
  end

  class Transaction
    def self.run(&block)
      ActiveRecord::Base.transaction do
        result = block.call
        raise ActiveRecord::Rollback if result.failure?
        result
      end
    end
  end

  class Validator
    def self.validate(data, rules)
      errors = []

      rules.each do |field, validations|
        value = data[field]

        validations.each do |validation, param|
          case validation
          when :presence
            errors << "#{field} is required" if value.nil? || value.to_s.empty?
          when :type
            errors << "#{field} must be a #{param}" unless value.is_a?(param)
          when :format
            errors << "#{field} format is invalid" unless value.to_s.match?(param)
          when :length
            if param[:min] && value.to_s.length < param[:min]
              errors << "#{field} is too short (minimum is #{param[:min]} characters)"
            end
            if param[:max] && value.to_s.length > param[:max]
              errors << "#{field} is too long (maximum is #{param[:max]} characters)"
            end
          when :inclusion
            errors << "#{field} is not included in the list" unless param.include?(value)
          when :exclusion
            errors << "#{field} is reserved" if param.include?(value)
          when :numericality
            errors << "#{field} is not a number" unless value.is_a?(Numeric)
            if param[:greater_than] && value <= param[:greater_than]
              errors << "#{field} must be greater than #{param[:greater_than]}"
            end
            if param[:less_than] && value >= param[:less_than]
              errors << "#{field} must be less than #{param[:less_than]}"
            end
          when :custom
            custom_error = param.call(value)
            errors << custom_error if custom_error
          end
        end
      end

      errors.empty? ? Result.success(data) : Result.failure(errors)
    end
  end

  class Interactor
    def self.call(context = {})
      new(context).tap(&:run)
    end

    def initialize(context = {})
      @context = OpenStruct.new(context)
      @context.success = true
    end

    def run
      raise NotImplementedError
    end

    def fail!(error)
      @context.success = false
      @context.error = error
      raise InteractorError, error
    end

    def context
      @context
    end

    def success?
      @context.success
    end

    def failure?
      !@context.success
    end

    class InteractorError < StandardError; end
  end

  class Organizer
    def self.call(context = {})
      new(context).run
    end

    def initialize(context = {})
      @context = OpenStruct.new(context)
      @context.success = true
    end

    def self.organize(*interactors)
      @interactors = interactors
    end

    def self.interactors
      @interactors || []
    end

    def run
      self.class.interactors.each do |interactor|
        begin
          result = interactor.call(@context.to_h)
          @context = result.context
          return @context unless result.success?
        rescue Interactor::InteractorError
          return @context
        end
      end
      @context
    end
  end

  class Command
    attr_reader :executed

    def initialize
      @executed = false
      @undone = false
    end

    def execute
      raise NotImplementedError
    end

    def undo
      raise NotImplementedError
    end

    def mark_executed
      @executed = true
      @undone = false
    end

    def mark_undone
      @undone = true
      @executed = false
    end

    def executed?
      @executed
    end

    def undone?
      @undone
    end
  end

  class CommandInvoker
    def initialize
      @history = []
      @current = -1
    end

    def execute(command)
      command.execute
      command.mark_executed

      @history = @history[0..@current]
      @history << command
      @current += 1
    end

    def undo
      return unless can_undo?

      command = @history[@current]
      command.undo
      command.mark_undone
      @current -= 1
    end

    def redo
      return unless can_redo?

      @current += 1
      command = @history[@current]
      command.execute
      command.mark_executed
    end

    def can_undo?
      @current >= 0
    end

    def can_redo?
      @current < @history.length - 1
    end

    def clear_history
      @history.clear
      @current = -1
    end
  end

  class EventBus
    def initialize
      @subscribers = Hash.new { |h, k| h[k] = [] }
      @mutex = Mutex.new
    end

    def subscribe(event_type, &handler)
      @mutex.synchronize do
        @subscribers[event_type] << handler
      end
    end

    def publish(event)
      handlers = @mutex.synchronize do
        @subscribers[event.class].dup
      end

      handlers.each { |handler| handler.call(event) }
    end

    def unsubscribe(event_type, handler)
      @mutex.synchronize do
        @subscribers[event_type].delete(handler)
      end
    end

    def clear
      @mutex.synchronize do
        @subscribers.clear
      end
    end
  end

  class Event
    attr_reader :occurred_at, :metadata

    def initialize(**metadata)
      @occurred_at = Time.now
      @metadata = metadata
    end

    def type
      self.class.name
    end
  end

  class Repository
    def initialize(model_class)
      @model_class = model_class
    end

    def find(id)
      @model_class.find(id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def find!(id)
      @model_class.find(id)
    end

    def all
      @model_class.all
    end

    def where(conditions)
      @model_class.where(conditions)
    end

    def create(attributes)
      @model_class.create(attributes)
    end

    def update(id, attributes)
      record = find(id)
      return nil unless record

      record.update(attributes)
      record
    end

    def delete(id)
      record = find(id)
      return false unless record

      record.destroy
      true
    end

    def exists?(id)
      @model_class.exists?(id)
    end

    def count
      @model_class.count
    end

    def first
      @model_class.first
    end

    def last
      @model_class.last
    end
  end

  class Specification
    def satisfied_by?(candidate)
      raise NotImplementedError
    end

    def and(other)
      AndSpecification.new(self, other)
    end

    def or(other)
      OrSpecification.new(self, other)
    end

    def not
      NotSpecification.new(self)
    end
  end

  class AndSpecification < Specification
    def initialize(left, right)
      @left = left
      @right = right
    end

    def satisfied_by?(candidate)
      @left.satisfied_by?(candidate) && @right.satisfied_by?(candidate)
    end
  end

  class OrSpecification < Specification
    def initialize(left, right)
      @left = left
      @right = right
    end

    def satisfied_by?(candidate)
      @left.satisfied_by?(candidate) || @right.satisfied_by?(candidate)
    end
  end

  class NotSpecification < Specification
    def initialize(spec)
      @spec = spec
    end

    def satisfied_by?(candidate)
      !@spec.satisfied_by?(candidate)
    end
  end

  class Decorator
    def initialize(component)
      @component = component
    end

    def method_missing(method, *args, &block)
      @component.send(method, *args, &block)
    end

    def respond_to_missing?(method, include_private = false)
      @component.respond_to?(method, include_private) || super
    end
  end

  class Factory
    def self.create(type, *args, **kwargs)
      registry[type].new(*args, **kwargs)
    end

    def self.register(type, klass)
      registry[type] = klass
    end

    def self.registry
      @registry ||= {}
    end
  end

  class Builder
    def initialize
      @product = {}
    end

    def method_missing(method, *args, &block)
      if method.to_s.end_with?('=')
        @product[method.to_s.chomp('=').to_sym] = args.first
      else
        @product[method] = args.first
      end
      self
    end

    def respond_to_missing?(method, include_private = false)
      true
    end

    def build
      @product
    end
  end

  class Strategy
    def execute
      raise NotImplementedError
    end
  end

  class Context
    def initialize(strategy)
      @strategy = strategy
    end

    def strategy=(strategy)
      @strategy = strategy
    end

    def execute
      @strategy.execute
    end
  end

  class Observer
    def update(subject)
      raise NotImplementedError
    end
  end

  class Subject
    def initialize
      @observers = []
    end

    def attach(observer)
      @observers << observer
    end

    def detach(observer)
      @observers.delete(observer)
    end

    def notify
      @observers.each { |observer| observer.update(self) }
    end
  end
end
