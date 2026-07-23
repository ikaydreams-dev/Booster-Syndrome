# File Service

Rust service for file storage and management with S3.

## Features

- File upload/download
- S3 integration
- Multipart support
- File validation
- Metadata tracking

## Tech Stack

- Rust
- Axum
- AWS S3
- PostgreSQL

## Running

```bash
# Build
cargo build

# Run
cargo run

# Tests
cargo test
```

## API Endpoints

- POST `/api/v1/files/upload` - Upload file
- GET `/api/v1/files/:id` - Get file
- DELETE `/api/v1/files/:id` - Delete file
- GET `/api/v1/files` - List files

## Configuration

Set S3 credentials in `.env` file.
