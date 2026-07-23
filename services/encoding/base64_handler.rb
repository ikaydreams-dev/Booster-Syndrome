require 'base64'

module Encoding
  class Base64Handler
    def self.encode(data)
      Base64.strict_encode64(data)
    end

    def self.decode(encoded_data)
      Base64.strict_decode64(encoded_data)
    end

    def self.url_encode(data)
      Base64.urlsafe_encode64(data)
    end

    def self.url_decode(encoded_data)
      Base64.urlsafe_decode64(encoded_data)
    end

    def self.encode_file(file_path)
      data = File.binread(file_path)
      encode(data)
    end

    def self.decode_to_file(encoded_data, output_path)
      decoded = decode(encoded_data)
      File.binwrite(output_path, decoded)
    end
  end

  class HexHandler
    def self.encode(data)
      data.unpack1('H*')
    end

    def self.decode(hex_string)
      [hex_string].pack('H*')
    end

    def self.bytes_to_hex(bytes)
      bytes.map { |b| '%02x' % b }.join
    end

    def self.hex_to_bytes(hex_string)
      hex_string.scan(/../).map { |x| x.hex }
    end
  end
end
