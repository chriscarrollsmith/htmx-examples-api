#!/bin/bash

# This script generates a postgrest.conf file from the template and environment variables

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v "^#" .env | xargs)
else
    echo "Error: .env file not found. Please create one based on .env.example"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ] || \
   [ -z "$POSTGREST_USER" ] || [ -z "$POSTGREST_PASSWORD" ] || [ -z "$POSTGREST_JWT_SECRET" ] || [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: Missing required environment variables in .env file."
    echo "Please make sure all required variables are set."
    exit 1
fi

# Create the postgrest.conf file
cat > postgrest.conf << EOF
# PostgreSQL connection string
db-uri = "postgres://${POSTGREST_USER}:${POSTGREST_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# The database schema to expose to REST clients
db-schema = "api"

# The database role to use when executing commands
db-anon-role = "web_anon"

# The secret used to sign JWT tokens
jwt-secret = "${POSTGREST_JWT_SECRET}"

# The maximum number of rows to return from a request
max-rows = 100

# Server settings
server-port = 3000
server-host = "0.0.0.0"

# Set OpenAI API key as a custom setting
db-extra-search-path = "public, openai"
db-pre-request = "SET app.openai_api_key = '${OPENAI_API_KEY}'"
EOF

echo "Generated postgrest.conf file with environment variables." 