#!/usr/bin/env bash
# Script to apply PostgreSQL vector search functions to the database

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

# Load environment variables from .env file
if [ -f .env ]; then
    echo "Loading environment variables from .env file"
    source .env
else
    echo "Error: .env file not found. Please create it with the required environment variables."
    exit 1
fi

# Check if required environment variables are set
required_vars=("DB_HOST" "DB_PORT" "DB_USER" "DB_PASS" "DB_NAME")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "Error: The following required environment variables are missing: ${missing_vars[*]}"
    echo "Please make sure they are set in the .env file."
    exit 1
fi

echo "Applying SQL functions to database: $DB_NAME on $DB_HOST"
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f workflow/similarity_search.sql

echo "Verifying functions were created successfully..."
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
"SELECT proname, pronamespace::regnamespace as schema FROM pg_proc WHERE proname IN ('vector_search', 'multi_vector_search', 'find_similar_examples') AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'api');" -t | cat

echo "Verifying permissions..."
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
"SELECT proname, proacl FROM pg_proc WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'api') AND proname IN ('vector_search', 'multi_vector_search', 'find_similar_examples');" -t | cat

echo "Testing backward compatibility function with an example ID..."
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
"SELECT id, title, similarity FROM api.find_similar_examples('active-search', 'content', 3);" -t | cat

echo "SQL functions applied and verified successfully!" 