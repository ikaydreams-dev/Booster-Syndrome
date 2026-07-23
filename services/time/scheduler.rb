require 'rufus-scheduler'

module TimeScheduler
  class JobScheduler
    def initialize
      @scheduler = Rufus::Scheduler.new
      @jobs = {}
    end

    def schedule_daily(name, time, &block)
      job = @scheduler.cron "0 #{time} * * *" do
        block.call
      end
      @jobs[name] = job
    end

    def schedule_hourly(name, &block)
      job = @scheduler.every '1h' do
        block.call
      end
      @jobs[name] = job
    end

    def schedule_interval(name, interval, &block)
      job = @scheduler.every interval do
        block.call
      end
      @jobs[name] = job
    end

    def schedule_at(name, time, &block)
      job = @scheduler.at time do
        block.call
      end
      @jobs[name] = job
    end

    def unschedule(name)
      job = @jobs.delete(name)
      job.unschedule if job
    end

    def shutdown
      @scheduler.shutdown
    end

    def running_jobs
      @jobs.keys
    end
  end

  class TaskRunner
    def self.run_async(&block)
      Thread.new do
        begin
          block.call
        rescue => e
          puts "Task failed: #{e.message}"
        end
      end
    end

    def self.run_with_timeout(timeout, &block)
      require 'timeout'
      Timeout.timeout(timeout) do
        block.call
      end
    rescue Timeout::Error
      puts "Task timed out after #{timeout} seconds"
    end
  end
end
