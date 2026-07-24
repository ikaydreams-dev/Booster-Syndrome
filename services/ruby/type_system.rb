module TypeSystem
  class Type
    def self.check(value)
      raise NotImplementedError
    end

    def self.===(value)
      check(value)
    rescue
      false
    end
  end

  class IntegerType < Type
    def self.check(value)
      raise TypeError, "Expected Integer, got #{value.class}" unless value.is_a?(Integer)
      value
    end
  end

  class StringType < Type
    def self.check(value)
      raise TypeError, "Expected String, got #{value.class}" unless value.is_a?(String)
      value
    end
  end

  class BooleanType < Type
    def self.check(value)
      raise TypeError, "Expected Boolean" unless [true, false].include?(value)
      value
    end
  end

  class ArrayType < Type
    def initialize(element_type)
      @element_type = element_type
    end

    def check(value)
      raise TypeError, "Expected Array" unless value.is_a?(Array)
      value.each { |item| @element_type.check(item) }
      value
    end

    def ===(value)
      check(value)
    rescue
      false
    end
  end

  class HashType < Type
    def initialize(key_type, value_type)
      @key_type = key_type
      @value_type = value_type
    end

    def check(value)
      raise TypeError, "Expected Hash" unless value.is_a?(Hash)
      value.each do |k, v|
        @key_type.check(k)
        @value_type.check(v)
      end
      value
    end

    def ===(value)
      check(value)
    rescue
      false
    end
  end

  class UnionType < Type
    def initialize(*types)
      @types = types
    end

    def check(value)
      @types.each do |type|
        begin
          return type.check(value)
        rescue TypeError
          next
        end
      end
      raise TypeError, "Value does not match any type in union"
    end

    def ===(value)
      check(value)
    rescue
      false
    end
  end

  class NullableType < Type
    def initialize(type)
      @type = type
    end

    def check(value)
      return nil if value.nil?
      @type.check(value)
    end

    def ===(value)
      check(value)
    rescue
      false
    end
  end

  class StructType < Type
    def initialize(fields)
      @fields = fields
    end

    def check(value)
      raise TypeError, "Expected Hash" unless value.is_a?(Hash)

      @fields.each do |field_name, field_type|
        raise TypeError, "Missing field: #{field_name}" unless value.key?(field_name)
        field_type.check(value[field_name])
      end

      value
    end

    def ===(value)
      check(value)
    rescue
      false
    end
  end

  class EnumType < Type
    def initialize(*values)
      @values = values
    end

    def check(value)
      raise TypeError, "Value not in enum" unless @values.include?(value)
      value
    end

    def ===(value)
      check(value)
    rescue
      false
    end
  end

  class FunctionType < Type
    def initialize(param_types, return_type)
      @param_types = param_types
      @return_type = return_type
    end

    def check(func)
      raise TypeError, "Expected Proc" unless func.is_a?(Proc)
      func
    end

    def call(func, *args)
      @param_types.each_with_index do |param_type, index|
        param_type.check(args[index])
      end

      result = func.call(*args)
      @return_type.check(result)
    end
  end

  class TupleType < Type
    def initialize(*types)
      @types = types
    end

    def check(value)
      raise TypeError, "Expected Array" unless value.is_a?(Array)
      raise TypeError, "Tuple length mismatch" unless value.length == @types.length

      value.each_with_index do |item, index|
        @types[index].check(item)
      end

      value
    end

    def ===(value)
      check(value)
    rescue
      false
    end
  end

  module TypedMethods
    def typed_method(name, param_types, return_type, &block)
      define_method(name) do |*args|
        param_types.each_with_index do |param_type, index|
          param_type.check(args[index])
        end

        result = block.call(*args)
        return_type.check(result)
      end
    end

    def typed_attr_accessor(name, type)
      define_method(name) do
        instance_variable_get("@#{name}")
      end

      define_method("#{name}=") do |value|
        type.check(value)
        instance_variable_set("@#{name}", value)
      end
    end

    def typed_attr_reader(name, type)
      define_method(name) do
        instance_variable_get("@#{name}")
      end
    end

    def typed_attr_writer(name, type)
      define_method("#{name}=") do |value|
        type.check(value)
        instance_variable_set("@#{name}", value)
      end
    end
  end

  class TypeInference
    def initialize
      @type_env = {}
    end

    def infer(value)
      case value
      when Integer
        IntegerType
      when String
        StringType
      when TrueClass, FalseClass
        BooleanType
      when Array
        element_types = value.map { |item| infer(item) }.uniq
        if element_types.length == 1
          ArrayType.new(element_types.first)
        else
          ArrayType.new(UnionType.new(*element_types))
        end
      when Hash
        key_types = value.keys.map { |k| infer(k) }.uniq
        value_types = value.values.map { |v| infer(v) }.uniq

        key_type = key_types.length == 1 ? key_types.first : UnionType.new(*key_types)
        value_type = value_types.length == 1 ? value_types.first : UnionType.new(*value_types)

        HashType.new(key_type, value_type)
      when NilClass
        NullableType.new(Type)
      else
        Type
      end
    end

    def unify(type1, type2)
      return type1 if type1 == type2

      if type1.is_a?(UnionType) || type2.is_a?(UnionType)
        types = []
        types += type1.instance_variable_get(:@types) if type1.is_a?(UnionType)
        types += type2.instance_variable_get(:@types) if type2.is_a?(UnionType)
        types << type1 unless type1.is_a?(UnionType)
        types << type2 unless type2.is_a?(UnionType)
        return UnionType.new(*types.uniq)
      end

      UnionType.new(type1, type2)
    end
  end

  class TypeChecker
    def initialize
      @type_env = {}
      @inference = TypeInference.new
    end

    def check_assignment(var_name, value, expected_type = nil)
      inferred_type = @inference.infer(value)

      if expected_type
        expected_type.check(value)
        @type_env[var_name] = expected_type
      else
        @type_env[var_name] = inferred_type
      end

      value
    end

    def check_variable(var_name)
      @type_env[var_name]
    end

    def check_binary_op(op, left, right)
      left_type = @inference.infer(left)
      right_type = @inference.infer(right)

      case op
      when :+, :-, :*, :/
        if left_type == IntegerType && right_type == IntegerType
          IntegerType
        elsif left_type == StringType && right_type == StringType && op == :+
          StringType
        else
          raise TypeError, "Invalid operands for #{op}"
        end
      when :==, :!=, :<, :>, :<=, :>=
        BooleanType
      when :&&, :||
        if left_type == BooleanType && right_type == BooleanType
          BooleanType
        else
          raise TypeError, "Logical operators require boolean operands"
        end
      else
        raise TypeError, "Unknown operator: #{op}"
      end
    end

    def check_function_call(func_type, *args)
      raise TypeError, "Not a function type" unless func_type.is_a?(FunctionType)

      param_types = func_type.instance_variable_get(:@param_types)
      return_type = func_type.instance_variable_get(:@return_type)

      raise TypeError, "Argument count mismatch" unless args.length == param_types.length

      args.each_with_index do |arg, index|
        param_types[index].check(arg)
      end

      return_type
    end
  end

  class Contract
    def initialize
      @preconditions = []
      @postconditions = []
      @invariants = []
    end

    def requires(&condition)
      @preconditions << condition
    end

    def ensures(&condition)
      @postconditions << condition
    end

    def invariant(&condition)
      @invariants << condition
    end

    def check_preconditions(*args)
      @preconditions.each do |condition|
        raise ContractViolation, "Precondition failed" unless condition.call(*args)
      end
    end

    def check_postconditions(result, *args)
      @postconditions.each do |condition|
        raise ContractViolation, "Postcondition failed" unless condition.call(result, *args)
      end
    end

    def check_invariants(obj)
      @invariants.each do |condition|
        raise ContractViolation, "Invariant failed" unless condition.call(obj)
      end
    end

    def wrap_method(obj, method_name, &block)
      original_method = obj.method(method_name)

      obj.define_singleton_method(method_name) do |*args|
        check_preconditions(*args)
        result = original_method.call(*args)
        check_postconditions(result, *args)
        check_invariants(obj)
        result
      end
    end
  end

  class ContractViolation < StandardError; end

  module RefinementTypes
    def refine_type(base_type, &predicate)
      Class.new(Type) do
        define_singleton_method(:check) do |value|
          base_type.check(value)
          raise TypeError, "Refinement failed" unless predicate.call(value)
          value
        end
      end
    end

    def positive_integer
      refine_type(IntegerType) { |n| n > 0 }
    end

    def non_empty_string
      refine_type(StringType) { |s| !s.empty? }
    end

    def bounded_integer(min, max)
      refine_type(IntegerType) { |n| n >= min && n <= max }
    end

    def email_string
      refine_type(StringType) { |s| s.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i) }
    end
  end

  class DependentType < Type
    def initialize(base_type, &constraint)
      @base_type = base_type
      @constraint = constraint
    end

    def check(value, context = {})
      @base_type.check(value)
      raise TypeError, "Dependent type constraint failed" unless @constraint.call(value, context)
      value
    end
  end

  class PolymorphicType
    def initialize(type_var)
      @type_var = type_var
      @concrete_type = nil
    end

    def bind(concrete_type)
      @concrete_type = concrete_type
    end

    def check(value)
      if @concrete_type
        @concrete_type.check(value)
      else
        value
      end
    end
  end

  class TypeAlias
    @@aliases = {}

    def self.define(name, type)
      @@aliases[name] = type
    end

    def self.resolve(name)
      @@aliases[name] || raise(TypeError, "Unknown type alias: #{name}")
    end
  end
end
