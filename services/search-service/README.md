# Search Service

Elixir service for full-text search with Elasticsearch.

## Features

- Full-text search
- Document indexing
- Elasticsearch integration
- Multi-field queries

## Tech Stack

- Elixir
- Plug/Cowboy
- Elasticsearch

## Running

```bash
# Install dependencies
mix deps.get

# Start server
mix run --no-halt

# Or with IEx
iex -S mix
```

## API Endpoints

- POST `/api/v1/search` - Search documents
- POST `/api/v1/index` - Index document

## Configuration

Set Elasticsearch URL in `config/config.exs`.
