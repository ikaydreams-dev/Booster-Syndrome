# Notification Service

Ruby Sinatra service for multi-channel notifications.

## Features

- Email notifications
- SMS via Twilio
- Push notifications
- Template management
- Redis queuing

## Tech Stack

- Ruby
- Sinatra
- PostgreSQL
- Redis
- Twilio

## Running

```bash
# Install dependencies
bundle install

# Start server
rackup config.ru

# Or with rerun
rerun rackup config.ru
```

## API Endpoints

- POST `/api/v1/notifications/email` - Send email
- POST `/api/v1/notifications/push` - Queue push notification
- GET `/api/v1/notifications/:user_id` - Get user notifications

## Environment

See `.env.example` for configuration.
