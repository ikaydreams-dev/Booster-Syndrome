module Workers
  class ImportWorker
    def initialize(import_service)
      @import_service = import_service
    end

    def perform(job)
      file_path = job[:file_path]
      user_id = job[:user_id]
      options = job[:options] || {}

      result = @import_service.import_file(
        file_path: file_path,
        user_id: user_id,
        options: options
      )

      if result.success?
        notify_success(user_id, result.value)
      else
        notify_failure(user_id, result.errors)
      end
    end

    private

    def notify_success(user_id, stats)
      puts "Import completed for user #{user_id}: #{stats[:imported]} records imported"
    end

    def notify_failure(user_id, errors)
      puts "Import failed for user #{user_id}: #{errors.join(', ')}"
    end
  end
end
