#!/bin/bash

# Database Backup Script
# Author: ikaydreams108@gmail.com

set -e

BACKUP_DIR="/var/backups/booster-syndrome"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
S3_BUCKET="s3://booster-backups"

# PostgreSQL
POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_DB=${POSTGRES_DB:-booster}

# MongoDB
MONGO_HOST=${MONGO_HOST:-localhost}
MONGO_DB=${MONGO_DB:-booster}

echo "🔐 Starting backup at $TIMESTAMP"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL
echo "Backing up PostgreSQL..."
pg_dump -h "$POSTGRES_HOST" -U "$POSTGRES_USER" "$POSTGRES_DB" \
    | gzip > "$BACKUP_DIR/postgres_$TIMESTAMP.sql.gz"

if [ $? -eq 0 ]; then
    echo "✓ PostgreSQL backup successful"
else
    echo "✗ PostgreSQL backup failed"
    exit 1
fi

# Backup MongoDB
echo "Backing up MongoDB..."
mongodump --host "$MONGO_HOST" --db "$MONGO_DB" \
    --archive="$BACKUP_DIR/mongo_$TIMESTAMP.archive" --gzip

if [ $? -eq 0 ]; then
    echo "✓ MongoDB backup successful"
else
    echo "✗ MongoDB backup failed"
    exit 1
fi

# Backup Redis (RDB snapshot)
echo "Backing up Redis..."
redis-cli --rdb "$BACKUP_DIR/redis_$TIMESTAMP.rdb"

# Upload to S3
if command -v aws &> /dev/null; then
    echo "Uploading backups to S3..."
    aws s3 sync "$BACKUP_DIR" "$S3_BUCKET/$(date +%Y/%m/%d)/"

    if [ $? -eq 0 ]; then
        echo "✓ S3 upload successful"
    else
        echo "✗ S3 upload failed"
    fi
fi

# Cleanup old backups (keep last 30 days)
find "$BACKUP_DIR" -type f -mtime +30 -delete

echo "✅ Backup complete at $TIMESTAMP"
echo "Backup location: $BACKUP_DIR"
