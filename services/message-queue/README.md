# Message Queue Service

Go service for managing RabbitMQ message queues.

## Features

- RabbitMQ integration
- Publisher/Consumer pattern
- Queue management
- Event-driven architecture

## Tech Stack

- Go
- RabbitMQ
- AMQP protocol

## Running

```bash
# Install dependencies
go mod download

# Run
go run main.go
```

## Queues

- `events` - Event processing
- `notifications` - Notification delivery
- `analytics` - Analytics events

## Configuration

Set RabbitMQ URL in `.env` file.
