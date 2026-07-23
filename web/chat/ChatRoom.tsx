import React, { useEffect, useState, useRef } from 'react';

interface Message {
  id: string;
  userId: string;
  username: string;
  content: string;
  timestamp: Date;
}

interface ChatRoomProps {
  roomId: string;
  userId: string;
  username: string;
}

export const ChatRoom: React.FC<ChatRoomProps> = ({ roomId, userId, username }) => {
  const [ws, setWs] = useState<WebSocket | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isConnected, setIsConnected] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const websocket = new WebSocket(`ws://localhost:8080/ws/chat`);

    websocket.onopen = () => {
      console.log('Chat WebSocket connected');
      setIsConnected(true);

      websocket.send(
        JSON.stringify({
          type: 'join',
          room_id: roomId,
          user_id: userId,
        })
      );
    };

    websocket.onmessage = (event) => {
      const data = JSON.parse(event.data);

      if (data.type === 'message') {
        const newMessage: Message = {
          id: Date.now().toString(),
          userId: data.user_id,
          username: data.username || 'Unknown',
          content: data.content,
          timestamp: new Date(data.timestamp),
        };

        setMessages((prev) => [...prev, newMessage]);
      } else if (data.type === 'user_joined') {
        console.log(`User ${data.user_id} joined the room`);
      } else if (data.type === 'user_left') {
        console.log(`User ${data.user_id} left the room`);
      }
    };

    websocket.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    websocket.onclose = () => {
      console.log('Chat WebSocket disconnected');
      setIsConnected(false);
    };

    setWs(websocket);

    return () => {
      if (websocket.readyState === WebSocket.OPEN) {
        websocket.send(JSON.stringify({ type: 'leave' }));
      }
      websocket.close();
    };
  }, [roomId, userId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const sendMessage = () => {
    if (!ws || !inputValue.trim()) {
      return;
    }

    ws.send(
      JSON.stringify({
        type: 'message',
        content: inputValue,
      })
    );

    setInputValue('');
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="chat-room">
      <div className="chat-header">
        <h3>Chat Room: {roomId}</h3>
        <div className={`connection-status ${isConnected ? 'connected' : 'disconnected'}`}>
          {isConnected ? 'Connected' : 'Disconnected'}
        </div>
      </div>

      <div className="messages-container">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`message ${message.userId === userId ? 'own-message' : 'other-message'}`}
          >
            <div className="message-header">
              <span className="username">{message.username}</span>
              <span className="timestamp">
                {message.timestamp.toLocaleTimeString()}
              </span>
            </div>
            <div className="message-content">{message.content}</div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      <div className="message-input">
        <textarea
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder="Type a message..."
          disabled={!isConnected}
        />
        <button onClick={sendMessage} disabled={!isConnected || !inputValue.trim()}>
          Send
        </button>
      </div>
    </div>
  );
};

export default ChatRoom;
