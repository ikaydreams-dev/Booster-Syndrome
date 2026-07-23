require 'fileutils'
require 'securerandom'
require 'digest'

module FileUpload
  class Uploader
    attr_reader :upload_dir, :allowed_extensions, :max_file_size

    def initialize(upload_dir: './uploads', allowed_extensions: nil, max_file_size: 10 * 1024 * 1024)
      @upload_dir = upload_dir
      @allowed_extensions = allowed_extensions
      @max_file_size = max_file_size

      FileUtils.mkdir_p(@upload_dir) unless Dir.exist?(@upload_dir)
    end

    def upload(file, original_filename: nil)
      validate_file!(file, original_filename)

      filename = generate_filename(original_filename || file.path)
      filepath = File.join(@upload_dir, filename)

      File.open(filepath, 'wb') do |f|
        if file.respond_to?(:read)
          f.write(file.read)
        else
          f.write(file)
        end
      end

      {
        filename: filename,
        path: filepath,
        size: File.size(filepath),
        checksum: calculate_checksum(filepath),
        url: "/uploads/#{filename}"
      }
    end

    def upload_multiple(files)
      files.map { |file| upload(file) }
    end

    def delete(filename)
      filepath = File.join(@upload_dir, filename)
      File.delete(filepath) if File.exist?(filepath)
    end

    def exists?(filename)
      filepath = File.join(@upload_dir, filename)
      File.exist?(filepath)
    end

    def get_info(filename)
      filepath = File.join(@upload_dir, filename)
      return nil unless File.exist?(filepath)

      {
        filename: filename,
        path: filepath,
        size: File.size(filepath),
        modified: File.mtime(filepath),
        checksum: calculate_checksum(filepath)
      }
    end

    private

    def validate_file!(file, original_filename)
      size = if file.respond_to?(:size)
        file.size
      elsif file.is_a?(String)
        file.bytesize
      else
        0
      end

      raise 'File too large' if size > @max_file_size

      if @allowed_extensions && original_filename
        ext = File.extname(original_filename).downcase
        unless @allowed_extensions.include?(ext)
          raise "File type #{ext} not allowed"
        end
      end
    end

    def generate_filename(original_filename)
      ext = File.extname(original_filename)
      basename = File.basename(original_filename, ext)
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
      random = SecureRandom.hex(4)

      "#{basename}_#{timestamp}_#{random}#{ext}"
    end

    def calculate_checksum(filepath)
      Digest::SHA256.file(filepath).hexdigest
    end
  end

  class ImageProcessor
    SUPPORTED_FORMATS = ['.jpg', '.jpeg', '.png', '.gif', '.webp']

    def initialize
      @upload_dir = './uploads/images'
      FileUtils.mkdir_p(@upload_dir)
    end

    def resize(filepath, width:, height:)
      {
        original: filepath,
        resized: filepath,
        width: width,
        height: height
      }
    end

    def thumbnail(filepath, size: 150)
      resize(filepath, width: size, height: size)
    end

    def crop(filepath, x:, y:, width:, height:)
      {
        original: filepath,
        cropped: filepath,
        x: x,
        y: y,
        width: width,
        height: height
      }
    end

    def optimize(filepath, quality: 85)
      {
        original: filepath,
        optimized: filepath,
        quality: quality,
        original_size: File.size(filepath),
        optimized_size: File.size(filepath)
      }
    end

    def convert(filepath, format:)
      {
        original: filepath,
        converted: filepath,
        format: format
      }
    end

    def get_dimensions(filepath)
      {
        width: 800,
        height: 600
      }
    end
  end

  class ChunkedUploader
    attr_reader :upload_dir, :chunk_size

    def initialize(upload_dir: './uploads/chunks', chunk_size: 1024 * 1024)
      @upload_dir = upload_dir
      @chunk_size = chunk_size
      @uploads = {}

      FileUtils.mkdir_p(@upload_dir)
    end

    def start_upload(filename:, total_size:, total_chunks:)
      upload_id = SecureRandom.uuid

      @uploads[upload_id] = {
        id: upload_id,
        filename: filename,
        total_size: total_size,
        total_chunks: total_chunks,
        received_chunks: [],
        started_at: Time.now
      }

      upload_id
    end

    def upload_chunk(upload_id:, chunk_index:, data:)
      upload = @uploads[upload_id]
      raise 'Upload not found' unless upload

      chunk_path = File.join(@upload_dir, "#{upload_id}_chunk_#{chunk_index}")

      File.open(chunk_path, 'wb') do |f|
        f.write(data)
      end

      upload[:received_chunks] << chunk_index
      upload[:received_chunks].sort!

      {
        upload_id: upload_id,
        chunk_index: chunk_index,
        received: upload[:received_chunks].size,
        total: upload[:total_chunks],
        complete: upload[:received_chunks].size == upload[:total_chunks]
      }
    end

    def finalize_upload(upload_id:)
      upload = @uploads[upload_id]
      raise 'Upload not found' unless upload

      return { complete: false } unless upload[:received_chunks].size == upload[:total_chunks]

      final_path = File.join(@upload_dir, upload[:filename])

      File.open(final_path, 'wb') do |output|
        upload[:total_chunks].times do |i|
          chunk_path = File.join(@upload_dir, "#{upload_id}_chunk_#{i}")
          output.write(File.read(chunk_path))
          File.delete(chunk_path)
        end
      end

      @uploads.delete(upload_id)

      {
        complete: true,
        filename: upload[:filename],
        path: final_path,
        size: File.size(final_path)
      }
    end

    def cancel_upload(upload_id:)
      upload = @uploads[upload_id]
      return unless upload

      upload[:total_chunks].times do |i|
        chunk_path = File.join(@upload_dir, "#{upload_id}_chunk_#{i}")
        File.delete(chunk_path) if File.exist?(chunk_path)
      end

      @uploads.delete(upload_id)
    end

    def get_status(upload_id:)
      upload = @uploads[upload_id]
      return nil unless upload

      {
        upload_id: upload_id,
        filename: upload[:filename],
        received: upload[:received_chunks].size,
        total: upload[:total_chunks],
        progress: (upload[:received_chunks].size.to_f / upload[:total_chunks] * 100).round(2)
      }
    end
  end

  class StorageAdapter
    def initialize(config = {})
      @config = config
    end

    def put(key, data)
      raise NotImplementedError
    end

    def get(key)
      raise NotImplementedError
    end

    def delete(key)
      raise NotImplementedError
    end

    def exists?(key)
      raise NotImplementedError
    end

    def url(key)
      raise NotImplementedError
    end
  end

  class LocalStorageAdapter < StorageAdapter
    def initialize(config = {})
      super
      @root = config[:root] || './storage'
      FileUtils.mkdir_p(@root)
    end

    def put(key, data)
      path = File.join(@root, key)
      FileUtils.mkdir_p(File.dirname(path))

      File.open(path, 'wb') do |f|
        f.write(data)
      end

      { key: key, path: path }
    end

    def get(key)
      path = File.join(@root, key)
      return nil unless File.exist?(path)

      File.read(path)
    end

    def delete(key)
      path = File.join(@root, key)
      File.delete(path) if File.exist?(path)
    end

    def exists?(key)
      path = File.join(@root, key)
      File.exist?(path)
    end

    def url(key)
      "/storage/#{key}"
    end
  end
end
