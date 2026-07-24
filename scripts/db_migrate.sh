#!/bin/bash
set -e

echo "Running database migrations..."

MIGRATIONS_DIR="db/migrations"

if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "Migrations directory not found!"
    exit 1
fi

for migration in $(ls -1 $MIGRATIONS_DIR/*.sql | sort); do
    echo "Applying migration: $(basename $migration)"
    psql $DATABASE_URL -f $migration || echo "Failed to apply $migration"
done

echo "All migrations complete!"
