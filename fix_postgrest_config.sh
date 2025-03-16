#!/bin/bash

# This script fixes the PostgREST configuration with the correct password

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Error: .env file not found."
    exit 1
fi

# Check if required environment variables are set
if [ -z "$DROPLET_IP" ] || [ -z "$DROPLET_USER" ] || [ -z "$DROPLET_PASSWORD" ]; then
    echo "Error: DROPLET_IP, DROPLET_USER, and DROPLET_PASSWORD must be set in the .env file."
    exit 1
fi

# Use the password we set in the database
WEB_ANON_PASSWORD="htmx_examples_api"

# Create the updated configuration file
cat > postgrest.conf.fixed << EOF
# PostgreSQL connection string
db-uri = "postgres://web_anon:${WEB_ANON_PASSWORD}@db-postgresql-nyc3-20256-do-user-18794323-0.k.db.ondigitalocean.com:25060/defaultdb"

# The database schema to expose to REST clients
db-schema = "api"

# The database role to use when executing commands
db-anon-role = "web_anon"

# Server settings
server-port = 3000
server-host = "0.0.0.0"

# The maximum number of rows to return from a request
max-rows = 100

# Additional schema paths
db-extra-search-path = "public, openai"

# Enable CORS
server-cors-allowed-origins = "*"
EOF

# Copy the updated configuration to the Droplet
echo "Copying fixed PostgREST configuration to the Droplet..."
scp -o StrictHostKeyChecking=no postgrest.conf.fixed $DROPLET_USER@$DROPLET_IP:/opt/postgrest/postgrest.conf

# Restart the PostgREST service
echo "Restarting PostgREST service..."
ssh -o StrictHostKeyChecking=no $DROPLET_USER@$DROPLET_IP "systemctl restart postgrest && sleep 5 && systemctl status postgrest"

# Clean up
rm postgrest.conf.fixed

echo "PostgREST configuration fixed!"
echo "Your API should now be accessible at: http://$DROPLET_IP/"
echo ""
echo "To test your API, run:"
echo "curl http://$DROPLET_IP/examples?limit=5" 