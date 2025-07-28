#!/bin/bash
set -e

echo "Starting as user: $(whoami)"
echo "PGDATA location: $PGDATA"

echo "Starting PostgreSQL initialization and job as postgres user..."

# Set PGDATA if not set
export PGDATA=${PGDATA:-/var/lib/postgresql/data}

# Initialize PostgreSQL if needed
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initializing PostgreSQL database..."
    initdb --auth-host=trust --auth-local=trust
fi

echo "Starting PostgreSQL in background..."
# Start PostgreSQL in background
pg_ctl -D "$PGDATA" -o "-c listen_addresses='localhost' -c port=5432" -w start

echo "PostgreSQL started. Waiting for it to be ready..."
until pg_isready -h localhost -p 5432; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "PostgreSQL is ready. Starting database sanitization..."

# Run your sanitization script
cd /home/app
bash /home/app/scrubbed_database.sh

echo "Sanitization complete. Shutting down PostgreSQL..."
pg_ctl -D "$PGDATA" -m fast -w stop

echo "Container job finished successfully."