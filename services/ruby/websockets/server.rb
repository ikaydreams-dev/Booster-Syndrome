require 'websocket'
require 'json'

module WebSockets
  class Server
    def initialize(host: 'localhost', port: 8080)
      @host = host
      @port = port
      @clients = []
      @rooms = Hash.new { |h, k| h[k] = [] }
    end

    def start
      puts "WebSocket server starting on #{@host}:#{@port}"
      # Server implementation would go here
    end

    def broadcast(message, room: nil)
      payload = JSON.generate(message)
      
      if room
        @rooms[room].each { |client| send_to_client(client, payload) }
      else
        @clients.each { |client| send_to_client(client, payload) }
      end
    end

    def handle_message(client, message)
      data = JSON.parse(message)
      
      case data['type']
      when 'join'
        join_room(client, data['room'])
      when 'leave'
        leave_room(client, data['room'])
      when 'message'
        broadcast_message(data['room'], data['content'], client)
      end
    rescue JSON::ParserError => e
      send_error(client, 'Invalid JSON')
    end

    private

    def join_room(client, room)
      @rooms[room] << client unless @rooms[room].include?(client)
      broadcast({ type: 'user_joined', room: room }, room: room)
    end

    def leave_room(client, room)
      @rooms[room].delete(client)
      broadcast({ type: 'user_left', room: room }, room: room)
    end

    def broadcast_message(room, content, sender)
      message = {
        type: 'message',
        room: room,
        content: content,
        timestamp: Time.now.iso8601
      }
      
      @rooms[room].each do |client|
        next if client == sender
        send_to_client(client, JSON.generate(message))
      end
    end

    def send_to_client(client, payload)
      # WebSocket send implementation
      client.send(payload)
    rescue => e
      puts "Error sending to client: #{e.message}"
      @clients.delete(client)
    end

    def send_error(client, error_message)
      payload = JSON.generate({ type: 'error', message: error_message })
      send_to_client(client, payload)
    end
  end
end
