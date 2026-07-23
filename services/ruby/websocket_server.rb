require 'socket'
require 'digest/sha1'
require 'base64'

module WebSocket
  class Frame
    OPCODES = {
      continuation: 0x0,
      text: 0x1,
      binary: 0x2,
      close: 0x8,
      ping: 0x9,
      pong: 0xA
    }

    attr_reader :fin, :opcode, :payload

    def initialize(fin: true, opcode: :text, payload: '')
      @fin = fin
      @opcode = opcode
      @payload = payload
    end

    def to_bytes
      frame = []

      first_byte = @fin ? 0x80 : 0x00
      first_byte |= OPCODES[@opcode]
      frame << first_byte

      length = @payload.bytesize

      if length < 126
        frame << length
      elsif length < 65536
        frame << 126
        frame << (length >> 8) & 0xFF
        frame << length & 0xFF
      else
        frame << 127
        frame << (length >> 56) & 0xFF
        frame << (length >> 48) & 0xFF
        frame << (length >> 40) & 0xFF
        frame << (length >> 32) & 0xFF
        frame << (length >> 24) & 0xFF
        frame << (length >> 16) & 0xFF
        frame << (length >> 8) & 0xFF
        frame << length & 0xFF
      end

      frame.pack('C*') + @payload
    end

    def self.parse(data)
      return nil if data.bytesize < 2

      first_byte = data.bytes[0]
      second_byte = data.bytes[1]

      fin = (first_byte & 0x80) != 0
      opcode_value = first_byte & 0x0F
      opcode = OPCODES.key(opcode_value)

      masked = (second_byte & 0x80) != 0
      payload_length = second_byte & 0x7F

      offset = 2

      if payload_length == 126
        payload_length = (data.bytes[2] << 8) | data.bytes[3]
        offset = 4
      elsif payload_length == 127
        payload_length = 0
        (0..7).each do |i|
          payload_length |= data.bytes[2 + i] << (56 - i * 8)
        end
        offset = 10
      end

      if masked
        mask = data.bytes[offset, 4]
        offset += 4

        payload_bytes = data.bytes[offset, payload_length]
        payload = payload_bytes.each_with_index.map do |byte, i|
          byte ^ mask[i % 4]
        end.pack('C*')
      else
        payload = data[offset, payload_length]
      end

      new(fin: fin, opcode: opcode, payload: payload)
    end
  end

  class Connection
    attr_reader :socket, :id

    def initialize(socket)
      @socket = socket
      @id = SecureRandom.uuid
      @open = false
    end

    def handshake
      request = @socket.gets
      headers = {}

      while (line = @socket.gets.chomp) != ''
        key, value = line.split(': ', 2)
        headers[key] = value
      end

      if headers['Upgrade'] == 'websocket'
        perform_handshake(headers['Sec-WebSocket-Key'])
        @open = true
      end
    end

    def send_text(message)
      frame = Frame.new(opcode: :text, payload: message)
      @socket.write(frame.to_bytes)
    end

    def send_binary(data)
      frame = Frame.new(opcode: :binary, payload: data)
      @socket.write(frame.to_bytes)
    end

    def ping
      frame = Frame.new(opcode: :ping, payload: '')
      @socket.write(frame.to_bytes)
    end

    def receive
      data = @socket.read(2)
      return nil unless data

      full_data = data
      needed = calculate_frame_length(data)
      full_data += @socket.read(needed) if needed > 0

      Frame.parse(full_data)
    end

    def close
      frame = Frame.new(opcode: :close, payload: '')
      @socket.write(frame.to_bytes)
      @socket.close
      @open = false
    end

    def open?
      @open
    end

    private

    def perform_handshake(key)
      accept = Digest::SHA1.base64digest(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')

      response = [
        'HTTP/1.1 101 Switching Protocols',
        'Upgrade: websocket',
        'Connection: Upgrade',
        "Sec-WebSocket-Accept: #{accept}",
        '',
        ''
      ].join("\r\n")

      @socket.write(response)
    end

    def calculate_frame_length(data)
      second_byte = data.bytes[1]
      payload_length = second_byte & 0x7F
      masked = (second_byte & 0x80) != 0

      extra = 0
      extra += 2 if payload_length == 126
      extra += 8 if payload_length == 127
      extra += 4 if masked

      extra + payload_length
    end
  end

  class Server
    def initialize(host: 'localhost', port: 8080)
      @host = host
      @port = port
      @connections = []
      @handlers = {}
      @running = false
    end

    def on(event, &block)
      @handlers[event] = block
    end

    def start
      @server = TCPServer.new(@host, @port)
      @running = true

      puts "WebSocket server listening on #{@host}:#{@port}"

      while @running
        Thread.start(@server.accept) do |client|
          handle_client(client)
        end
      end
    end

    def stop
      @running = false
      @connections.each(&:close)
      @server.close
    end

    def broadcast(message)
      @connections.each do |conn|
        conn.send_text(message) if conn.open?
      end
    end

    private

    def handle_client(socket)
      connection = Connection.new(socket)
      connection.handshake

      @connections << connection
      trigger(:connect, connection)

      while connection.open?
        frame = connection.receive
        break unless frame

        case frame.opcode
        when :text
          trigger(:message, connection, frame.payload)
        when :binary
          trigger(:binary, connection, frame.payload)
        when :close
          connection.close
          break
        when :ping
          pong = Frame.new(opcode: :pong, payload: frame.payload)
          socket.write(pong.to_bytes)
        end
      end

      @connections.delete(connection)
      trigger(:disconnect, connection)
    rescue => e
      puts "Error handling client: #{e.message}"
      connection.close if connection
    end

    def trigger(event, *args)
      @handlers[event]&.call(*args)
    end
  end

  class Client
    def initialize(url)
      @url = url
      @socket = nil
      @connected = false
      @handlers = {}
    end

    def on(event, &block)
      @handlers[event] = block
    end

    def connect
      uri = URI.parse(@url)
      @socket = TCPSocket.new(uri.host, uri.port || 80)

      send_handshake(uri)
      @connected = true

      Thread.new { receive_loop }
    end

    def send(message)
      return unless @connected

      frame = Frame.new(opcode: :text, payload: message)
      @socket.write(frame.to_bytes)
    end

    def close
      return unless @connected

      frame = Frame.new(opcode: :close, payload: '')
      @socket.write(frame.to_bytes)
      @socket.close
      @connected = false
    end

    private

    def send_handshake(uri)
      key = Base64.strict_encode64(SecureRandom.random_bytes(16))

      request = [
        "GET #{uri.path.empty? ? '/' : uri.path} HTTP/1.1",
        "Host: #{uri.host}",
        'Upgrade: websocket',
        'Connection: Upgrade',
        "Sec-WebSocket-Key: #{key}",
        'Sec-WebSocket-Version: 13',
        '',
        ''
      ].join("\r\n")

      @socket.write(request)

      while (line = @socket.gets.chomp) != ''
      end
    end

    def receive_loop
      while @connected
        data = @socket.read(2)
        break unless data

        full_data = data
        needed = calculate_frame_length(data)
        full_data += @socket.read(needed) if needed > 0

        frame = Frame.parse(full_data)

        case frame.opcode
        when :text
          trigger(:message, frame.payload)
        when :close
          close
          break
        end
      end
    rescue => e
      puts "Receive error: #{e.message}"
      close
    end

    def trigger(event, *args)
      @handlers[event]&.call(*args)
    end

    def calculate_frame_length(data)
      second_byte = data.bytes[1]
      payload_length = second_byte & 0x7F

      extra = 0
      extra += 2 if payload_length == 126
      extra += 8 if payload_length == 127

      extra + payload_length
    end
  end
end
