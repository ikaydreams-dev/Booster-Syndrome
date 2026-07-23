# Analytics Service

Python FastAPI service for event tracking and analytics.

## Features

- Event tracking
- Statistical analysis
- Data aggregation
- Pandas integration
- PostgreSQL storage

## Tech Stack

- Python
- FastAPI
- PostgreSQL with SQLAlchemy
- Pandas for data processing
- NumPy

## Running

```bash
# Install dependencies
pip install -r requirements.txt

# Start server
uvicorn main:app --reload

# Production
uvicorn main:app --host 0.0.0.0 --port 8003
```

## API Endpoints

- POST `/api/v1/analytics/events` - Track event
- GET `/api/v1/stats/summary` - Get summary stats
- GET `/api/v1/stats/daily` - Get daily stats
- GET `/api/v1/reports/top-events` - Top events

## Testing

```bash
pytest
```
