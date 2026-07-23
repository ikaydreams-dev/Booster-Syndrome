require 'json'
require 'securerandom'

module Jobs
  class Job
    attr_reader :id, :queue, :data, :priority, :created_at, :status

    def initialize(queue, data, priority: 0)
      @id = SecureRandom.uuid
      @queue = queue
      @data = data
      @priority = priority
      @created_at = Time.now
      @status = :pending
      @attempts = 0
      @max_attempts = 3
    end

    def to_h
      {
        id: @id,
        queue: @queue,
        data: @data,
        priority: @priority,
        created_at: @created_at.to_i,
        status: @status,
        attempts: @attempts
      }
    end

    def perform!
      @status = :processing
      @attempts += 1
      yield(@data)
      @status = :completed
    rescue => e
      @status = :failed
      raise e
    end

    def retry?
      @attempts < @max_attempts
    end

    def failed?
      @status == :failed
    end

    def completed?
      @status == :completed
    end
  end

  class Queue
    def initialize(name)
      @name = name
      @jobs = []
      @processing = []
      @failed = []
      @completed = []
      @mutex = Mutex.new
    end

    def enqueue(data, priority: 0)
      job = Job.new(@name, data, priority: priority)
      @mutex.synchronize do
        @jobs << job
        @jobs.sort_by! { |j| [-j.priority, j.created_at] }
      end
      job
    end

    def dequeue
      @mutex.synchronize do
        job = @jobs.shift
        @processing << job if job
        job
      end
    end

    def complete(job)
      @mutex.synchronize do
        @processing.delete(job)
        @completed << job
      end
    end

    def fail(job)
      @mutex.synchronize do
        @processing.delete(job)

        if job.retry?
          @jobs.unshift(job)
        else
          @failed << job
        end
      end
    end

    def size
      @mutex.synchronize { @jobs.size }
    end

    def processing_count
      @mutex.synchronize { @processing.size }
    end

    def failed_count
      @mutex.synchronize { @failed.size }
    end

    def completed_count
      @mutex.synchronize { @completed.size }
    end

    def clear
      @mutex.synchronize do
        @jobs.clear
        @processing.clear
        @failed.clear
        @completed.clear
      end
    end

    def stats
      @mutex.synchronize do
        {
          name: @name,
          pending: @jobs.size,
          processing: @processing.size,
          completed: @completed.size,
          failed: @failed.size
        }
      end
    end
  end

  class Worker
    def initialize(queue, concurrency: 1)
      @queue = queue
      @concurrency = concurrency
      @running = false
      @threads = []
      @handlers = {}
    end

    def handle(job_type, &block)
      @handlers[job_type] = block
    end

    def start
      @running = true

      @concurrency.times do
        @threads << Thread.new do
          while @running
            process_job
            sleep 0.1
          end
        end
      end

      self
    end

    def stop
      @running = false
      @threads.each(&:join)
    end

    def running?
      @running
    end

    private

    def process_job
      job = @queue.dequeue
      return unless job

      begin
        handler = @handlers[job.data[:type]]

        if handler
          job.perform! { |data| handler.call(data) }
          @queue.complete(job)
        else
          raise "No handler for job type: #{job.data[:type]}"
        end
      rescue => e
        puts "Job failed: #{e.message}"
        @queue.fail(job)
      end
    end
  end

  class Scheduler
    def initialize
      @jobs = []
      @mutex = Mutex.new
      @running = false
      @thread = nil
    end

    def every(interval, &block)
      @mutex.synchronize do
        @jobs << {
          type: :interval,
          interval: interval,
          block: block,
          last_run: nil
        }
      end
    end

    def at(time, &block)
      @mutex.synchronize do
        @jobs << {
          type: :at,
          time: time,
          block: block,
          executed: false
        }
      end
    end

    def cron(expression, &block)
      @mutex.synchronize do
        @jobs << {
          type: :cron,
          expression: expression,
          block: block,
          last_run: nil
        }
      end
    end

    def start
      @running = true
      @thread = Thread.new do
        while @running
          check_and_run_jobs
          sleep 1
        end
      end
    end

    def stop
      @running = false
      @thread&.join
    end

    private

    def check_and_run_jobs
      now = Time.now

      @mutex.synchronize do
        @jobs.each do |job|
          case job[:type]
          when :interval
            if job[:last_run].nil? || (now - job[:last_run]) >= job[:interval]
              Thread.new { job[:block].call }
              job[:last_run] = now
            end
          when :at
            if !job[:executed] && now >= job[:time]
              Thread.new { job[:block].call }
              job[:executed] = true
            end
          when :cron
            if should_run_cron?(job[:expression], job[:last_run], now)
              Thread.new { job[:block].call }
              job[:last_run] = now
            end
          end
        end
      end
    end

    def should_run_cron?(expression, last_run, now)
      return true if last_run.nil?

      parts = expression.split
      return false unless parts.size == 5

      minute, hour, day, month, weekday = parts

      now.min.to_s == minute.gsub('*', now.min.to_s) &&
        now.hour.to_s == hour.gsub('*', now.hour.to_s) &&
        now.day.to_s == day.gsub('*', now.day.to_s)
    end
  end

  class JobManager
    def initialize
      @queues = {}
      @workers = {}
      @scheduler = Scheduler.new
    end

    def queue(name)
      @queues[name] ||= Queue.new(name)
    end

    def enqueue(queue_name, data, priority: 0)
      queue(queue_name).enqueue(data, priority: priority)
    end

    def create_worker(queue_name, concurrency: 1)
      q = queue(queue_name)
      worker = Worker.new(q, concurrency: concurrency)
      @workers[queue_name] = worker
      worker
    end

    def start_worker(queue_name)
      @workers[queue_name]&.start
    end

    def stop_worker(queue_name)
      @workers[queue_name]&.stop
    end

    def start_all
      @workers.values.each(&:start)
      @scheduler.start
    end

    def stop_all
      @workers.values.each(&:stop)
      @scheduler.stop
    end

    def schedule(&block)
      block.call(@scheduler)
    end

    def stats
      @queues.transform_values(&:stats)
    end
  end
end
