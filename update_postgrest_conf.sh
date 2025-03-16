#!/bin/bash

# This script updates the PostgREST configuration on your Droplet
# Run this after configuring the web_anon role for passwordless access

# Set variables
DROPLET_IP="$1"

if [ -z "$DROPLET_IP" ]; then
    echo "Error: Droplet IP address not provided."
    echo "Usage: $0 <droplet-ip>"
    exit 1
fi

# Create the updated configuration file
cat > postgrest.conf.updated << EOF
# PostgreSQL connection string
db-uri = "postgres://web_anon@db-postgresql-nyc3-20256-do-user-18794323-0.k.db.ondigitalocean.com:25060/defaultdb"

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
echo "Copying updated PostgREST configuration to the Droplet..."
scp -o StrictHostKeyChecking=no postgrest.conf.updated root@$DROPLET_IP:/opt/postgrest/postgrest.conf

# Restart the PostgREST service
echo "Restarting PostgREST service..."
ssh -o StrictHostKeyChecking=no root@$DROPLET_IP "systemctl restart postgrest"

# Clean up
rm postgrest.conf.updated

echo "PostgREST configuration updated successfully!"
echo "Your API should now be accessible at: http://$DROPLET_IP/"
echo ""
echo "To test your API, run:"
echo "curl http://$DROPLET_IP/examples?limit=5" 