require 'time'

module Scheduling
  class CronExpression
    DAYS_OF_WEEK = {
      'sun' => 0, 'mon' => 1, 'tue' => 2, 'wed' => 3,
      'thu' => 4, 'fri' => 5, 'sat' => 6
    }

    MONTHS = {
      'jan' => 1, 'feb' => 2, 'mar' => 3, 'apr' => 4,
      'may' => 5, 'jun' => 6, 'jul' => 7, 'aug' => 8,
      'sep' => 9, 'oct' => 10, 'nov' => 11, 'dec' => 12
    }

    attr_reader :expression

    def initialize(expression)
      @expression = expression
      @parts = parse_expression(expression)
    end

    def match?(time)
      return false unless @parts

      @parts[:minute].include?(time.min) &&
        @parts[:hour].include?(time.hour) &&
        @parts[:day].include?(time.day) &&
        @parts[:month].include?(time.month) &&
        @parts[:weekday].include?(time.wday)
    end

    def next_occurrence(from_time = Time.now)
      test_time = from_time + 60

      10000.times do
        return test_time if match?(test_time)
        test_time += 60
      end

      nil
    end

    private

    def parse_expression(expr)
      parts = expr.split

      return nil unless parts.size == 5

      {
        minute: parse_field(parts[0], 0..59),
        hour: parse_field(parts[1], 0..23),
        day: parse_field(parts[2], 1..31),
        month: parse_field(parts[3], 1..12),
        weekday: parse_field(parts[4], 0..6)
      }
    end

    def parse_field(field, range)
      return range.to_a if field == '*'

      values = []

      field.split(',').each do |part|
        if part.include?('-')
          start, finish = part.split('-').map(&:to_i)
          values.concat((start..finish).to_a)
        elsif part.include?('/')
          base, step = part.split('/')
          base_values = base == '*' ? range.to_a : [base.to_i]
          base_values.each { |v| values << v if (v % step.to_i).zero? }
        else
          values << part.to_i
        end
      end

      values.uniq.sort
    end
  end

  class Job
    attr_reader :id, :name, :schedule, :last_run, :next_run, :enabled

    def initialize(name:, schedule:, &block)
      @id = SecureRandom.uuid
      @name = name
      @schedule = CronExpression.new(schedule)
      @block = block
      @enabled = true
      @last_run = nil
      @next_run = @schedule.next_occurrence
      @run_count = 0
    end

    def execute
      return unless @enabled

      begin
        @block.call
        @last_run = Time.now
        @next_run = @schedule.next_occurrence
        @run_count += 1
      rescue => e
        puts "Job #{@name} failed: #{e.message}"
      end
    end

    def should_run?(time = Time.now)
      @enabled && @schedule.match?(time)
    end

    def enable
      @enabled = true
    end

    def disable
      @enabled = false
    end

    def run_count
      @run_count
    end

    def to_h
      {
        id: @id,
        name: @name,
        schedule: @schedule.expression,
        enabled: @enabled,
        last_run: @last_run&.iso8601,
        next_run: @next_run&.iso8601,
        run_count: @run_count
      }
    end
  end

  class Scheduler
    def initialize
      @jobs = {}
      @running = false
      @thread = nil
      @mutex = Mutex.new
    end

    def schedule(name, cron:, &block)
      job = Job.new(name: name, schedule: cron, &block)

      @mutex.synchronize do
        @jobs[job.id] = job
      end

      job
    end

    def start
      return if @running

      @running = true
      @thread = Thread.new { run_loop }
    end

    def stop
      @running = false
      @thread&.join
    end

    def running?
      @running
    end

    def get_job(job_id)
      @mutex.synchronize do
        @jobs[job_id]
      end
    end

    def list_jobs
      @mutex.synchronize do
        @jobs.values.map(&:to_h)
      end
    end

    def remove_job(job_id)
      @mutex.synchronize do
        @jobs.delete(job_id)
      end
    end

    def enable_job(job_id)
      job = get_job(job_id)
      job&.enable
    end

    def disable_job(job_id)
      job = get_job(job_id)
      job&.disable
    end

    private

    def run_loop
      while @running
        current_time = Time.now

        jobs_to_run = @mutex.synchronize do
          @jobs.values.select { |job| job.should_run?(current_time) }
        end

        jobs_to_run.each do |job|
          Thread.new { job.execute }
        end

        sleep_until_next_minute(current_time)
      end
    end

    def sleep_until_next_minute(current_time)
      seconds_to_next_minute = 60 - current_time.sec
      sleep seconds_to_next_minute
    end
  end

  class IntervalJob
    attr_reader :id, :name, :interval, :last_run, :enabled

    def initialize(name:, interval:, &block)
      @id = SecureRandom.uuid
      @name = name
      @interval = interval
      @block = block
      @enabled = true
      @last_run = nil
      @run_count = 0
    end

    def execute
      return unless @enabled

      begin
        @block.call
        @last_run = Time.now
        @run_count += 1
      rescue => e
        puts "Job #{@name} failed: #{e.message}"
      end
    end

    def should_run?(time = Time.now)
      return false unless @enabled
      return true if @last_run.nil?

      (time - @last_run) >= @interval
    end

    def enable
      @enabled = true
    end

    def disable
      @enabled = false
    end

    def run_count
      @run_count
    end
  end

  class IntervalScheduler
    def initialize
      @jobs = {}
      @running = false
      @thread = nil
      @mutex = Mutex.new
    end

    def every(interval, name: nil, &block)
      job = IntervalJob.new(
        name: name || "interval_#{SecureRandom.hex(4)}",
        interval: interval,
        &block
      )

      @mutex.synchronize do
        @jobs[job.id] = job
      end

      job
    end

    def start
      return if @running

      @running = true
      @thread = Thread.new { run_loop }
    end

    def stop
      @running = false
      @thread&.join
    end

    def running?
      @running
    end

    private

    def run_loop
      while @running
        current_time = Time.now

        jobs_to_run = @mutex.synchronize do
          @jobs.values.select { |job| job.should_run?(current_time) }
        end

        jobs_to_run.each do |job|
          Thread.new { job.execute }
        end

        sleep 1
      end
    end
  end

  class DelayedJob
    attr_reader :id, :run_at, :executed

    def initialize(run_at:, &block)
      @id = SecureRandom.uuid
      @run_at = run_at
      @block = block
      @executed = false
    end

    def execute
      return if @executed

      @block.call
      @executed = true
    end

    def should_run?(time = Time.now)
      !@executed && time >= @run_at
    end
  end

  class DelayedScheduler
    def initialize
      @jobs = {}
      @running = false
      @thread = nil
      @mutex = Mutex.new
    end

    def schedule_at(time, &block)
      job = DelayedJob.new(run_at: time, &block)

      @mutex.synchronize do
        @jobs[job.id] = job
      end

      job
    end

    def schedule_in(seconds, &block)
      schedule_at(Time.now + seconds, &block)
    end

    def start
      return if @running

      @running = true
      @thread = Thread.new { run_loop }
    end

    def stop
      @running = false
      @thread&.join
    end

    private

    def run_loop
      while @running
        current_time = Time.now

        jobs_to_run = @mutex.synchronize do
          @jobs.values.select { |job| job.should_run?(current_time) }
        end

        jobs_to_run.each do |job|
          Thread.new do
            job.execute
            @mutex.synchronize { @jobs.delete(job.id) }
          end
        end

        sleep 1
      end
    end
  end
end
