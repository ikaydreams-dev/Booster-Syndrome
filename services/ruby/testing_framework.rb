module TestingFramework
  class TestCase
    attr_reader :name, :passed, :failed, :skipped

    def initialize(name)
      @name = name
      @passed = []
      @failed = []
      @skipped = []
      @before_hooks = []
      @after_hooks = []
      @before_each_hooks = []
      @after_each_hooks = []
    end

    def before(&block)
      @before_hooks << block
    end

    def after(&block)
      @after_hooks << block
    end

    def before_each(&block)
      @before_each_hooks << block
    end

    def after_each(&block)
      @after_each_hooks << block
    end

    def test(name, &block)
      @tests ||= []
      @tests << { name: name, block: block }
    end

    def run
      @before_hooks.each(&:call)

      @tests.each do |test|
        begin
          @before_each_hooks.each(&:call)
          test[:block].call
          @passed << test[:name]
        rescue Assertion::AssertionError => e
          @failed << { name: test[:name], error: e.message }
        rescue => e
          @failed << { name: test[:name], error: "#{e.class}: #{e.message}" }
        ensure
          @after_each_hooks.each(&:call)
        end
      end

      @after_hooks.each(&:call)

      print_results
    end

    def print_results
      total = @passed.length + @failed.length + @skipped.length

      puts "\n#{@name}"
      puts "=" * 50

      @failed.each do |failure|
        puts "  FAIL: #{failure[:name]}"
        puts "    #{failure[:error]}"
      end

      puts "\n#{@passed.length} passed, #{@failed.length} failed, #{@skipped.length} skipped out of #{total}"
    end
  end

  module Assertion
    class AssertionError < StandardError; end

    def assert(condition, message = "Assertion failed")
      raise AssertionError, message unless condition
    end

    def assert_equal(expected, actual, message = nil)
      message ||= "Expected #{expected.inspect} but got #{actual.inspect}"
      raise AssertionError, message unless expected == actual
    end

    def assert_not_equal(expected, actual, message = nil)
      message ||= "Expected #{expected.inspect} to not equal #{actual.inspect}"
      raise AssertionError, message if expected == actual
    end

    def assert_nil(object, message = nil)
      message ||= "Expected nil but got #{object.inspect}"
      raise AssertionError, message unless object.nil?
    end

    def assert_not_nil(object, message = nil)
      message ||= "Expected not nil but got nil"
      raise AssertionError, message if object.nil?
    end

    def assert_true(condition, message = nil)
      message ||= "Expected true but got #{condition.inspect}"
      raise AssertionError, message unless condition == true
    end

    def assert_false(condition, message = nil)
      message ||= "Expected false but got #{condition.inspect}"
      raise AssertionError, message unless condition == false
    end

    def assert_raises(exception_class, message = nil, &block)
      begin
        block.call
        message ||= "Expected #{exception_class} to be raised but nothing was raised"
        raise AssertionError, message
      rescue exception_class
        # Test passes
      rescue => e
        message ||= "Expected #{exception_class} but got #{e.class}"
        raise AssertionError, message
      end
    end

    def assert_nothing_raised(&block)
      begin
        block.call
      rescue => e
        raise AssertionError, "Expected nothing to be raised but got #{e.class}: #{e.message}"
      end
    end

    def assert_match(pattern, string, message = nil)
      message ||= "Expected #{string.inspect} to match #{pattern.inspect}"
      raise AssertionError, message unless string.match?(pattern)
    end

    def assert_no_match(pattern, string, message = nil)
      message ||= "Expected #{string.inspect} to not match #{pattern.inspect}"
      raise AssertionError, message if string.match?(pattern)
    end

    def assert_includes(collection, object, message = nil)
      message ||= "Expected #{collection.inspect} to include #{object.inspect}"
      raise AssertionError, message unless collection.include?(object)
    end

    def assert_not_includes(collection, object, message = nil)
      message ||= "Expected #{collection.inspect} to not include #{object.inspect}"
      raise AssertionError, message if collection.include?(object)
    end

    def assert_instance_of(klass, object, message = nil)
      message ||= "Expected #{object.inspect} to be instance of #{klass}"
      raise AssertionError, message unless object.is_a?(klass)
    end

    def assert_kind_of(klass, object, message = nil)
      message ||= "Expected #{object.inspect} to be kind of #{klass}"
      raise AssertionError, message unless object.kind_of?(klass)
    end

    def assert_respond_to(object, method, message = nil)
      message ||= "Expected #{object.inspect} to respond to #{method}"
      raise AssertionError, message unless object.respond_to?(method)
    end

    def assert_empty(collection, message = nil)
      message ||= "Expected #{collection.inspect} to be empty"
      raise AssertionError, message unless collection.empty?
    end

    def assert_not_empty(collection, message = nil)
      message ||= "Expected #{collection.inspect} to not be empty"
      raise AssertionError, message if collection.empty?
    end
  end

  class Mock
    def initialize
      @expectations = {}
      @calls = Hash.new { |h, k| h[k] = [] }
    end

    def expect(method_name, return_value = nil, &block)
      @expectations[method_name] = { return_value: return_value, block: block }

      define_singleton_method(method_name) do |*args, &blk|
        @calls[method_name] << args
        block ? block.call(*args, &blk) : return_value
      end
    end

    def verify
      @expectations.each do |method_name, _|
        raise "Expected #{method_name} to be called" if @calls[method_name].empty?
      end
    end

    def called?(method_name)
      @calls[method_name].any?
    end

    def call_count(method_name)
      @calls[method_name].length
    end

    def called_with?(method_name, *args)
      @calls[method_name].include?(args)
    end
  end

  class Spy
    def initialize(target)
      @target = target
      @calls = Hash.new { |h, k| h[k] = [] }
    end

    def method_missing(method_name, *args, &block)
      @calls[method_name] << args
      @target.send(method_name, *args, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      @target.respond_to?(method_name, include_private)
    end

    def called?(method_name)
      @calls[method_name].any?
    end

    def call_count(method_name)
      @calls[method_name].length
    end

    def called_with?(method_name, *args)
      @calls[method_name].include?(args)
    end

    def reset
      @calls.clear
    end
  end

  class Stub
    def initialize
      @stubs = {}
    end

    def stub(method_name, return_value = nil, &block)
      @stubs[method_name] = block || -> (*args) { return_value }

      define_singleton_method(method_name) do |*args|
        @stubs[method_name].call(*args)
      end
    end

    def unstub(method_name)
      @stubs.delete(method_name)
      singleton_class.send(:remove_method, method_name)
    end
  end

  class Fixture
    def self.load(name)
      path = File.join('fixtures', "#{name}.yml")
      YAML.load_file(path)
    end

    def self.create(name, data)
      path = File.join('fixtures', "#{name}.yml")
      File.write(path, YAML.dump(data))
    end
  end

  class FactoryBot
    @@factories = {}

    def self.define(name, &block)
      @@factories[name] = block
    end

    def self.build(name, attributes = {})
      factory = @@factories[name]
      raise "Factory #{name} not found" unless factory

      instance = OpenStruct.new
      factory.call(instance)
      attributes.each { |k, v| instance.send("#{k}=", v) }
      instance
    end

    def self.create(name, attributes = {})
      object = build(name, attributes)
      object.save if object.respond_to?(:save)
      object
    end

    def self.build_list(name, count, attributes = {})
      count.times.map { build(name, attributes) }
    end

    def self.create_list(name, count, attributes = {})
      count.times.map { create(name, attributes) }
    end
  end

  class Benchmark
    def self.measure(&block)
      start_time = Time.now
      result = block.call
      end_time = Time.now

      {
        result: result,
        duration: end_time - start_time,
        memory_before: memory_usage,
        memory_after: memory_usage
      }
    end

    def self.compare(iterations = 1000, &block)
      results = []

      iterations.times do
        start_time = Time.now
        block.call
        end_time = Time.now
        results << (end_time - start_time)
      end

      {
        iterations: iterations,
        total: results.sum,
        average: results.sum / results.length,
        min: results.min,
        max: results.max,
        median: results.sort[results.length / 2]
      }
    end

    def self.memory_usage
      GC.stat[:total_allocated_objects]
    end
  end

  class Coverage
    @@covered_lines = Set.new
    @@total_lines = Set.new

    def self.start
      TracePoint.new(:line) do |tp|
        @@covered_lines << "#{tp.path}:#{tp.lineno}"
      end.enable
    end

    def self.result
      {
        covered: @@covered_lines.size,
        total: @@total_lines.size,
        percentage: (@@covered_lines.size.to_f / @@total_lines.size * 100).round(2)
      }
    end
  end

  class TestRunner
    def initialize
      @test_cases = []
    end

    def add_test_case(test_case)
      @test_cases << test_case
    end

    def run_all
      total_passed = 0
      total_failed = 0
      total_skipped = 0

      @test_cases.each do |test_case|
        test_case.run
        total_passed += test_case.passed.length
        total_failed += test_case.failed.length
        total_skipped += test_case.skipped.length
      end

      puts "\n" + "=" * 50
      puts "TOTAL: #{total_passed} passed, #{total_failed} failed, #{total_skipped} skipped"
      puts "=" * 50
    end
  end

  module Matchers
    def eq(expected)
      ->(actual) { actual == expected }
    end

    def be_nil
      ->(actual) { actual.nil? }
    end

    def be_truthy
      ->(actual) { !!actual }
    end

    def be_falsey
      ->(actual) { !actual }
    end

    def include(item)
      ->(actual) { actual.include?(item) }
    end

    def match(pattern)
      ->(actual) { actual.match?(pattern) }
    end

    def be_instance_of(klass)
      ->(actual) { actual.is_a?(klass) }
    end

    def respond_to(method)
      ->(actual) { actual.respond_to?(method) }
    end

    def be_within(delta)
      lambda do |expected|
        ->(actual) { (actual - expected).abs <= delta }
      end
    end

    def raise_error(exception_class)
      lambda do |&block|
        begin
          block.call
          false
        rescue exception_class
          true
        rescue
          false
        end
      end
    end
  end
end
