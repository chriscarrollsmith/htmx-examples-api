#!/bin/bash

# This script checks the status of the PostgREST service on the Droplet

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

echo "Checking PostgREST service status on $DROPLET_IP..."
echo "Please enter the password when prompted: $DROPLET_PASSWORD"
echo ""

echo "1. Checking if PostgREST service is running:"
ssh $DROPLET_USER@$DROPLET_IP "systemctl status postgrest"

echo ""
echo "2. Checking PostgREST logs:"
ssh $DROPLET_USER@$DROPLET_IP "journalctl -u postgrest --no-pager -n 50"

echo ""
echo "3. Checking Nginx configuration:"
ssh $DROPLET_USER@$DROPLET_IP "cat /etc/nginx/sites-enabled/postgrest"

echo ""
echo "4. Checking if PostgREST is listening on port 3000:"
ssh $DROPLET_USER@$DROPLET_IP "netstat -tulpn | grep 3000 || echo 'PostgREST is not listening on port 3000'"

echo ""
echo "5. Testing connection to the database:"
ssh $DROPLET_USER@$DROPLET_IP "curl -s http://localhost:3000/ || echo 'Cannot connect to PostgREST locally'" 