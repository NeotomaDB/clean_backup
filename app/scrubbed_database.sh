#!/bin/bash

set -e

# by: Simon Goring
# Documentation for pg_dump is available at https://www.postgresql.org/docs/current/app-pgdump.html
# This script uses pg_dump to duplicate the whole database to a local version.

bash /home/app/connect_cloud.sh

echo Dumping:
export PGPASSWORD=$REMOTE_PASSWORD

pg_dump -C -v -O --no-owner -x -U $REMOTE_USER -h localhost -p 5454 -T ap.globalmammals -N cron -Fc -d neotoma > /home/archives/tempdump.dump

export PGPASSWORD=$POSTGRES_PASSWORD
psql -U postgres -h pgneotoma -d postgres -c "DROP DATABASE IF EXISTS neotoma;"
psql -U postgres -h pgneotoma -d postgres -c "CREATE DATABASE neotoma;"
psql -U postgres -h pgneotoma -d postgres -c "CREATE EXTENSION IF NOT EXISTS postgis;"
psql -U postgres -h pgneotoma -d postgres -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
psql -U postgres -h pgneotoma -d postgres -c "CREATE EXTENSION IF NOT EXISTS vector;"
psql -U postgres -h pgneotoma -d postgres -c "CREATE EXTENSION IF NOT EXISTS intarray;"
psql -U postgres -h pgneotoma -d postgres -c "CREATE EXTENSION IF NOT EXISTS unaccent;"
pg_restore -U postgres -h pgneotoma -c --no-owner --no-privileges -d neotoma /home/archives/tempdump.dump
psql -U postgres -h pgneotoma -d neotoma -c "UPDATE ti.stewards SET username=SUBSTRING(md5(random()::text) from 1 for 10), pwd=SUBSTRING(md5(random()::text) from 1 for 10);"
psql -U postgres -h pgneotoma -d neotoma -c "UPDATE ndb.contacts SET address=SUBSTRING(md5(random()::text) from 1 for 10), phone=SUBSTRING(md5(random()::text) from 1 for 10), fax=SUBSTRING(md5(random()::text) from 1 for 10), email=SUBSTRING(md5(random()::text) from 1 for 10);"
PGPASSWORD=postgres pg_dump -C -v -O --no-owner -x  -Fc -p 5432 -h pgneotoma -d neotoma -U postgres > /home/archives/neotoma_clean.dump
rm /home/archives/tempdump.dump
tar -zcvf /home/archives/clean_dump.tar.gz /home/archives/

aws s3 cp --content-encoding "application/x-compressed-tar" /home/archives/clean_dump.tar.gz s3://neotomaprimarybackup
