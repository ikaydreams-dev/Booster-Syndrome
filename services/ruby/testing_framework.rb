module Testing
  class TestCase
    attr_reader :name, :passed, :failed, :errors

    def initialize(name)
      @name = name
      @passed = []
      @failed = []
      @errors = []
      @setup_blocks = []
      @teardown_blocks = []
    end

    def setup(&block)
      @setup_blocks << block
    end

    def teardown(&block)
      @teardown_blocks << block
    end

    def test(name, &block)
      @setup_blocks.each(&:call)

      begin
        TestContext.new(self).instance_eval(&block)
        @passed << name
      rescue AssertionError => e
        @failed << { test: name, error: e.message }
      rescue => e
        @errors << { test: name, error: e.message, backtrace: e.backtrace }
      ensure
        @teardown_blocks.each(&:call)
      end
    end

    def run
      self
    end

    def summary
      total = @passed.size + @failed.size + @errors.size

      {
        name: @name,
        total: total,
        passed: @passed.size,
        failed: @failed.size,
        errors: @errors.size,
        failures: @failed,
        error_details: @errors
      }
    end
  end

  class TestContext
    def initialize(test_case)
      @test_case = test_case
    end

    def assert(condition, message = 'Assertion failed')
      raise AssertionError, message unless condition
    end

    def assert_equal(expected, actual, message = nil)
      message ||= "Expected #{expected.inspect} but got #{actual.inspect}"
      raise AssertionError, message unless expected == actual
    end

    def assert_not_equal(expected, actual, message = nil)
      message ||= "Expected not to equal #{expected.inspect}"
      raise AssertionError, message if expected == actual
    end

    def assert_nil(value, message = nil)
      message ||= "Expected nil but got #{value.inspect}"
      raise AssertionError, message unless value.nil?
    end

    def assert_not_nil(value, message = 'Expected non-nil value')
      raise AssertionError, message if value.nil?
    end

    def assert_true(value, message = 'Expected true')
      raise AssertionError, message unless value == true
    end

    def assert_false(value, message = 'Expected false')
      raise AssertionError, message unless value == false
    end

    def assert_raises(exception_class, &block)
      begin
        yield
        raise AssertionError, "Expected #{exception_class} to be raised"
      rescue exception_class
      rescue => e
        raise AssertionError, "Expected #{exception_class} but got #{e.class}"
      end
    end

    def assert_includes(collection, item, message = nil)
      message ||= "Expected #{collection.inspect} to include #{item.inspect}"
      raise AssertionError, message unless collection.include?(item)
    end

    def assert_empty(collection, message = nil)
      message ||= "Expected empty collection but got #{collection.inspect}"
      raise AssertionError, message unless collection.empty?
    end

    def assert_match(pattern, string, message = nil)
      message ||= "Expected #{string.inspect} to match #{pattern.inspect}"
      raise AssertionError, message unless pattern.match(string)
    end
  end

  class AssertionError < StandardError; end

  class TestSuite
    def initialize
      @test_cases = []
    end

    def add(test_case)
      @test_cases << test_case
    end

    def run
      @test_cases.each(&:run)
      self
    end

    def summary
      totals = {
        total_tests: 0,
        total_passed: 0,
        total_failed: 0,
        total_errors: 0,
        test_cases: []
      }

      @test_cases.each do |test_case|
        summary = test_case.summary
        totals[:total_tests] += summary[:total]
        totals[:total_passed] += summary[:passed]
        totals[:total_failed] += summary[:failed]
        totals[:total_errors] += summary[:errors]
        totals[:test_cases] << summary
      end

      totals
    end

    def report
      summary = self.summary

      puts "\n" + "=" * 60
      puts "Test Suite Results"
      puts "=" * 60

      puts "\nTotal Tests: #{summary[:total_tests]}"
      puts "Passed: #{summary[:total_passed]}"
      puts "Failed: #{summary[:total_failed]}"
      puts "Errors: #{summary[:total_errors]}"

      if summary[:total_failed] > 0 || summary[:total_errors] > 0
        puts "\nFailures and Errors:"
        summary[:test_cases].each do |tc|
          if tc[:failures].any? || tc[:error_details].any?
            puts "\n#{tc[:name]}:"

            tc[:failures].each do |failure|
              puts "  FAIL: #{failure[:test]} - #{failure[:error]}"
            end

            tc[:error_details].each do |error|
              puts "  ERROR: #{error[:test]} - #{error[:error]}"
            end
          end
        end
      end

      puts "\n" + "=" * 60
      puts summary[:total_failed] == 0 && summary[:total_errors] == 0 ? "ALL TESTS PASSED" : "TESTS FAILED"
      puts "=" * 60
    end
  end

  class Mock
    def initialize
      @expectations = {}
      @calls = Hash.new { |h, k| h[k] = [] }
    end

    def expect(method_name, return_value = nil, &block)
      @expectations[method_name] = {
        return_value: return_value,
        block: block
      }

      define_singleton_method(method_name) do |*args, &blk|
        @calls[method_name] << { args: args, block: blk }

        if @expectations[method_name][:block]
          @expectations[method_name][:block].call(*args, &blk)
        else
          @expectations[method_name][:return_value]
        end
      end
    end

    def received?(method_name, *expected_args)
      calls = @calls[method_name]
      return false if calls.empty?

      if expected_args.empty?
        true
      else
        calls.any? { |call| call[:args] == expected_args }
      end
    end

    def call_count(method_name)
      @calls[method_name].size
    end

    def reset
      @calls.clear
    end
  end

  class Spy
    def initialize(target)
      @target = target
      @calls = Hash.new { |h, k| h[k] = [] }
    end

    def method_missing(method, *args, &block)
      @calls[method] << { args: args, block: block }
      @target.send(method, *args, &block)
    end

    def respond_to_missing?(method, include_private = false)
      @target.respond_to?(method, include_private)
    end

    def received?(method, *expected_args)
      calls = @calls[method]
      return false if calls.empty?

      if expected_args.empty?
        true
      else
        calls.any? { |call| call[:args] == expected_args }
      end
    end

    def call_count(method)
      @calls[method].size
    end
  end

  class Stub
    def initialize
      @stubs = {}
    end

    def stub(method_name, return_value)
      @stubs[method_name] = return_value

      define_singleton_method(method_name) do |*args|
        @stubs[method_name]
      end
    end

    def method_missing(method, *args, &block)
      nil
    end
  end

  class Benchmark
    def self.measure(&block)
      start_time = Time.now
      result = yield
      end_time = Time.now

      {
        result: result,
        time: end_time - start_time,
        time_ms: (end_time - start_time) * 1000
      }
    end

    def self.compare(iterations: 1000, &block)
      results = []

      iterations.times do
        measurement = measure(&block)
        results << measurement[:time]
      end

      {
        iterations: iterations,
        total_time: results.sum,
        average_time: results.sum / results.size,
        min_time: results.min,
        max_time: results.max,
        median_time: results.sort[results.size / 2]
      }
    end
  end
end
