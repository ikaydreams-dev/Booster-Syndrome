module Workers
  class NotificationWorker
    def initialize(notification_service)
      @notification_service = notification_service
    end

    def perform(job)
      user_id = job[:user_id]
      type = job[:type]
      data = job[:data]

      @notification_service.create(
        user_id: user_id,
        type: type,
        title: data[:title],
        message: data[:message],
        data: data[:metadata]
      )
    end

    def perform_batch(jobs)
      jobs.each do |job|
        perform(job)
      rescue StandardError => e
        log_error(e, job)
      end
    end

    private

    def log_error(error, job)
      puts "Error processing notification job: #{error.message}"
      puts "Job data: #{job.inspect}"
    end
  end
end
