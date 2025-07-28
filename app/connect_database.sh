#!/bin/bash
# connect_database.sh - Simple database connection

set -e

echo "Setting up database connection..."

# Use direct RDS connection
echo "Using direct RDS connection"
export DB_HOST=${RDS_ENDPOINT:-"neotomaprivate.cxkwxkjpj8zi.us-east-2.rds.amazonaws.com"}
export DB_PORT=${RDS_PORT:-"5432"}

echo "Database connection configured: ${DB_HOST}:${DB_PORT}"