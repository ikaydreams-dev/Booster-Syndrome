module PatternMatching
  class Pattern
    def match(value)
      raise NotImplementedError
    end

    def ===(value)
      match(value)
    rescue MatchError
      false
    end
  end

  class LiteralPattern < Pattern
    def initialize(literal)
      @literal = literal
    end

    def match(value)
      if value == @literal
        {}
      else
        raise MatchError, "Value #{value} does not match literal #{@literal}"
      end
    end
  end

  class WildcardPattern < Pattern
    def match(value)
      {}
    end
  end

  class VariablePattern < Pattern
    def initialize(name)
      @name = name
    end

    def match(value)
      { @name => value }
    end
  end

  class ArrayPattern < Pattern
    def initialize(*patterns)
      @patterns = patterns
    end

    def match(value)
      raise MatchError, "Not an array" unless value.is_a?(Array)
      raise MatchError, "Array length mismatch" unless value.length == @patterns.length

      bindings = {}
      @patterns.each_with_index do |pattern, index|
        result = pattern.match(value[index])
        bindings.merge!(result)
      end
      bindings
    end
  end

  class HashPattern < Pattern
    def initialize(pattern_hash)
      @pattern_hash = pattern_hash
    end

    def match(value)
      raise MatchError, "Not a hash" unless value.is_a?(Hash)

      bindings = {}
      @pattern_hash.each do |key, pattern|
        raise MatchError, "Missing key: #{key}" unless value.key?(key)
        result = pattern.match(value[key])
        bindings.merge!(result)
      end
      bindings
    end
  end

  class TypePattern < Pattern
    def initialize(type)
      @type = type
    end

    def match(value)
      if value.is_a?(@type)
        {}
      else
        raise MatchError, "Type mismatch: expected #{@type}, got #{value.class}"
      end
    end
  end

  class GuardPattern < Pattern
    def initialize(pattern, guard)
      @pattern = pattern
      @guard = guard
    end

    def match(value)
      bindings = @pattern.match(value)
      if @guard.call(value)
        bindings
      else
        raise MatchError, "Guard failed"
      end
    end
  end

  class OrPattern < Pattern
    def initialize(*patterns)
      @patterns = patterns
    end

    def match(value)
      @patterns.each do |pattern|
        begin
          return pattern.match(value)
        rescue MatchError
          next
        end
      end
      raise MatchError, "No patterns matched"
    end
  end

  class AndPattern < Pattern
    def initialize(*patterns)
      @patterns = patterns
    end

    def match(value)
      bindings = {}
      @patterns.each do |pattern|
        result = pattern.match(value)
        bindings.merge!(result)
      end
      bindings
    end
  end

  class ConsPattern < Pattern
    def initialize(head_pattern, tail_pattern)
      @head_pattern = head_pattern
      @tail_pattern = tail_pattern
    end

    def match(value)
      raise MatchError, "Not an array" unless value.is_a?(Array)
      raise MatchError, "Array is empty" if value.empty?

      bindings = @head_pattern.match(value.first)
      tail_bindings = @tail_pattern.match(value[1..-1])
      bindings.merge!(tail_bindings)
    end
  end

  class RangePattern < Pattern
    def initialize(min, max)
      @min = min
      @max = max
    end

    def match(value)
      if value >= @min && value <= @max
        {}
      else
        raise MatchError, "Value #{value} not in range #{@min}..#{@max}"
      end
    end
  end

  class RegexPattern < Pattern
    def initialize(regex)
      @regex = regex
    end

    def match(value)
      if value.is_a?(String) && value.match?(@regex)
        {}
      else
        raise MatchError, "String does not match regex"
      end
    end
  end

  class MatchError < StandardError; end

  class Matcher
    def initialize
      @cases = []
    end

    def case(pattern, &block)
      @cases << [pattern, block]
      self
    end

    def match(value)
      @cases.each do |pattern, block|
        begin
          bindings = pattern.match(value)
          return block.call(bindings)
        rescue MatchError
          next
        end
      end
      raise MatchError, "No pattern matched value: #{value}"
    end

    def match_partial(value)
      @cases.each do |pattern, block|
        begin
          bindings = pattern.match(value)
          return [true, block.call(bindings)]
        rescue MatchError
          next
        end
      end
      [false, nil]
    end
  end

  def self.match(value, &block)
    matcher = Matcher.new
    matcher.instance_eval(&block)
    matcher.match(value)
  end

  def self.literal(value)
    LiteralPattern.new(value)
  end

  def self.wildcard
    WildcardPattern.new
  end

  def self.var(name)
    VariablePattern.new(name)
  end

  def self.array(*patterns)
    ArrayPattern.new(*patterns)
  end

  def self.hash(pattern_hash)
    HashPattern.new(pattern_hash)
  end

  def self.type(type)
    TypePattern.new(type)
  end

  def self.guard(pattern, &predicate)
    GuardPattern.new(pattern, predicate)
  end

  def self.or_pattern(*patterns)
    OrPattern.new(*patterns)
  end

  def self.and_pattern(*patterns)
    AndPattern.new(*patterns)
  end

  def self.cons(head, tail)
    ConsPattern.new(head, tail)
  end

  def self.range(min, max)
    RangePattern.new(min, max)
  end

  def self.regex(pattern)
    RegexPattern.new(pattern)
  end

  class DeconstructPattern < Pattern
    def initialize(klass, *patterns)
      @klass = klass
      @patterns = patterns
    end

    def match(value)
      raise MatchError, "Type mismatch" unless value.is_a?(@klass)

      if value.respond_to?(:deconstruct)
        parts = value.deconstruct
        raise MatchError, "Deconstruct length mismatch" unless parts.length == @patterns.length

        bindings = {}
        @patterns.each_with_index do |pattern, index|
          result = pattern.match(parts[index])
          bindings.merge!(result)
        end
        bindings
      else
        raise MatchError, "Object does not support deconstruct"
      end
    end
  end

  class DeconstructKeysPattern < Pattern
    def initialize(klass, pattern_hash)
      @klass = klass
      @pattern_hash = pattern_hash
    end

    def match(value)
      raise MatchError, "Type mismatch" unless value.is_a?(@klass)

      if value.respond_to?(:deconstruct_keys)
        keys_hash = value.deconstruct_keys(@pattern_hash.keys)

        bindings = {}
        @pattern_hash.each do |key, pattern|
          raise MatchError, "Missing key: #{key}" unless keys_hash.key?(key)
          result = pattern.match(keys_hash[key])
          bindings.merge!(result)
        end
        bindings
      else
        raise MatchError, "Object does not support deconstruct_keys"
      end
    end
  end

  def self.deconstruct(klass, *patterns)
    DeconstructPattern.new(klass, *patterns)
  end

  def self.deconstruct_keys(klass, pattern_hash)
    DeconstructKeysPattern.new(klass, pattern_hash)
  end

  class AsPattern < Pattern
    def initialize(pattern, name)
      @pattern = pattern
      @name = name
    end

    def match(value)
      bindings = @pattern.match(value)
      bindings.merge!(@name => value)
    end
  end

  def self.as(pattern, name)
    AsPattern.new(pattern, name)
  end

  class RestPattern < Pattern
    def initialize(name = nil)
      @name = name
    end

    def match(values)
      @name ? { @name => values } : {}
    end
  end

  def self.rest(name = nil)
    RestPattern.new(name)
  end

  class ArrayRestPattern < Pattern
    def initialize(*patterns, rest: nil)
      @patterns = patterns
      @rest = rest
    end

    def match(value)
      raise MatchError, "Not an array" unless value.is_a?(Array)
      raise MatchError, "Array too short" if value.length < @patterns.length

      bindings = {}
      @patterns.each_with_index do |pattern, index|
        result = pattern.match(value[index])
        bindings.merge!(result)
      end

      if @rest
        rest_values = value[@patterns.length..-1]
        bindings.merge!(@rest => rest_values)
      end

      bindings
    end
  end

  def self.array_rest(*patterns, rest: nil)
    ArrayRestPattern.new(*patterns, rest: rest)
  end

  class PinPattern < Pattern
    def initialize(variable)
      @variable = variable
    end

    def match(value)
      if value == @variable
        {}
      else
        raise MatchError, "Pinned value mismatch"
      end
    end
  end

  def self.pin(variable)
    PinPattern.new(variable)
  end
end
