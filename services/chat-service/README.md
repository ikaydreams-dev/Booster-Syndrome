# Chat Service

Elixir/Phoenix service for real-time chat with PubSub.

## Features

- Real-time messaging
- Phoenix PubSub
- Room-based chat
- Message history
- WebSocket support

## Tech Stack

- Elixir
- Phoenix
- Phoenix PubSub

## Running

```bash
# Install dependencies
mix deps.get

# Start server
mix run --no-halt
```

## API Endpoints

- POST `/api/v1/messages` - Send message
- GET `/api/v1/rooms/:room_id/messages` - Get room messages

## Configuration

Configure in `config/config.exs`.
