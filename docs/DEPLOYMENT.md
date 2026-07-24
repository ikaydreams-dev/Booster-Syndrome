# Deployment Guide

## Prerequisites

- Docker and Docker Compose installed
- PostgreSQL 15+
- Redis 7+
- MongoDB 7+
- Node.js 18+
- Ruby 3.2+
- Python 3.11+
- Go 1.21+
- Rust 1.70+
- Java 17+

## Local Development

1. Clone the repository
```bash
git clone https://github.com/ikaydreams-dev/Booster-Syndrome.git
cd Booster-Syndrome
```

2. Run setup script
```bash
./scripts/setup.sh
```

3. Start infrastructure services
```bash
docker-compose -f docker-compose.dev.yml up -d
```

4. Run migrations
```bash
export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/booster_dev
./scripts/db_migrate.sh
```

5. Seed database (optional)
```bash
./scripts/db_seed.sh
```

6. Run tests
```bash
./scripts/test.sh
```

## Production Deployment

1. Set environment variables
```bash
cp .env.production .env
# Edit .env with production values
```

2. Build Docker images
```bash
docker-compose build
```

3. Deploy services
```bash
docker-compose up -d
```

4. Run migrations
```bash
./scripts/db_migrate.sh
```

## CI/CD

GitHub Actions workflows automatically:
- Run tests on pull requests
- Lint code
- Build Docker images
- Deploy to staging/production

See `.github/workflows/` for details.
