# Auth Service

Rust-based authentication service using Axum and PostgreSQL.

## Features

- User registration and login
- JWT token generation and validation
- Refresh token support
- Session management
- Password hashing with bcrypt

## Tech Stack

- Rust
- Axum web framework
- SQLx for database access
- PostgreSQL
- JWT for authentication

## Running

```bash
# Install dependencies
cargo build

# Run migrations
sqlx migrate run

# Start server
cargo run
```

## API Endpoints

- POST `/api/v1/auth/register` - Register new user
- POST `/api/v1/auth/login` - Login user
- POST `/api/v1/auth/refresh` - Refresh access token
- POST `/api/v1/auth/logout` - Logout user
- GET `/api/v1/auth/verify` - Verify token

## Environment Variables

See `.env.example` for required configuration.
