#!/bin/bash
set -e

# by: Simon Goring
# Documentation for pg_dump is available at https://www.postgresql.org/docs/current/app-pgdump.html
# This script uses pg_dump to duplicate the whole database to a local version.

# We're logging out to a proper log file here.
exec > >(tee -a /var/log/db-sanitize.log)
exec 2>&1

echo "💡 Starting database sanitization at $(date)"
DATESTAMP=$(date +"%Y-%m-%d")

echo "🔌 Connecting to the primary Neotoma database..."
source /home/app/connect_database.sh

echo "⛁ Dumping the primary database from ${DB_HOST}:${DB_PORT}:"
export PGPASSWORD=$REMOTE_PASSWORD
pg_dump -v -O -C -c --no-owner -x -U $REMOTE_USER -h ${DB_HOST} -p ${DB_PORT} \
    --no-subscriptions -T ap.globalmammals -T ap.icesheets -N cron -Fp -d neotoma > /home/archives/tempdump.dump

echo "Checking to ensure the dump is stable:"
pg_restore --list /home/archives/tempdump.dump | head -20

echo "🛠 Restoring the database locally"
export PGPASSWORD=$POSTGRES_PASSWORD
psql -U postgres -h localhost -d postgres -c "DROP DATABASE IF EXISTS neotoma;"
psql -U postgres -h localhost -d postgres -c "CREATE DATABASE neotoma;"
psql -U postgres -h localhost -d postgres -c "CREATE EXTENSION IF NOT EXISTS postgis;"
psql -U postgres -h localhost -d postgres -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
psql -U postgres -h localhost -d postgres -c "CREATE EXTENSION IF NOT EXISTS intarray;"
psql -U postgres -h localhost -d postgres -c "CREATE EXTENSION IF NOT EXISTS unaccent;"

echo "Restoring database in container. Checking for errors."

psql -U postgres -h localhost -d neotoma < /home/archives/tempdump.dump


echo "🧹 Cleaning up all sensitive data from the database."
psql -U postgres -h localhost -d neotoma -c "UPDATE ti.stewards SET username=SUBSTRING(md5(random()::text) from 1 for 10), pwd=SUBSTRING(md5(random()::text) from 1 for 10);"
psql -U postgres -h localhost -d neotoma -c "UPDATE ndb.contacts SET address=SUBSTRING(md5(random()::text) from 1 for 10), phone=SUBSTRING(md5(random()::text) from 1 for 10), fax=SUBSTRING(md5(random()::text) from 1 for 10), email=SUBSTRING(md5(random()::text) from 1 for 10);"

echo "✍🏼 Creating the final cleaned dump."
PGPASSWORD=postgres pg_dump -C -v -O --no-owner -x  -Fc -p 5432 -h localhost -d neotoma -U postgres > /home/archives/neotoma_clean_${DATESTAMP}.dump

echo "📦 Compressing the dumped database."
tar -zcvf /home/archives/neotoma_clean_${DATESTAMP}.tar.gz -C /home/archives/ .

echo "💾 Uploading the archive to S3."
aws s3 cp /home/archives/neotoma_clean_${DATESTAMP}.tar.gz s3://neotoma-remote-store/ --content-encoding "application/x-compressed-tar"
aws s3 cp s3://neotoma-remote-store/neotoma_clean_${DATESTAMP}.tar.gz s3://neotoma-remote-store/neotoma_clean_latest.tar.gz --content-encoding "application/x-compressed-tar"

echo "🗑️ Removing temporary files..."
rm /home/archives/tempdump.dump
rm /home/archives/neotoma_clean_${DATESTAMP}.dump
rm /home/archives/neotoma_clean_${DATESTAMP}.tar.gz

echo "✔ Database sanitization completed successfully at $(date)"
