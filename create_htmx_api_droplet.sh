#!/bin/bash

# This script creates a Digital Ocean Droplet for the HTMX-Examples project
# and sets up PostgREST to serve the API

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

echo "Using Droplet at IP: $DROPLET_IP"

# Create instructions for manual steps
echo ""
echo "Please follow these steps to deploy PostgREST on your Droplet:"
echo ""
echo "1. Copy the deployment script to the Droplet:"
echo "   scp deploy_postgrest_to_droplet.sh $DROPLET_USER@$DROPLET_IP:~/"
echo "   (When prompted, enter your password: $DROPLET_PASSWORD)"
echo ""
echo "2. SSH into the Droplet:"
echo "   ssh $DROPLET_USER@$DROPLET_IP"
echo "   (When prompted, enter your password: $DROPLET_PASSWORD)"
echo ""
echo "3. Run the deployment script on the Droplet:"
echo "   chmod +x deploy_postgrest_to_droplet.sh && ./deploy_postgrest_to_droplet.sh"
echo ""
echo "4. After the deployment is complete, configure your PostgreSQL database:"
echo "   PGPASSWORD='your_password' psql -h db-postgresql-nyc3-20256-do-user-18794323-0.k.db.ondigitalocean.com -p 25060 -U doadmin -d defaultdb -f configure_web_anon_role.sql"
echo ""
echo "5. Update the PostgREST configuration on the Droplet:"
echo "   ./update_postgrest_conf.sh $DROPLET_IP"
echo ""
echo "6. Test your API:"
echo "   curl http://$DROPLET_IP/examples?limit=5"
echo "" 