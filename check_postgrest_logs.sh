#!/bin/bash

# This script checks the PostgREST logs on the Droplet

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

echo "Checking PostgREST logs on $DROPLET_IP..."
echo "Please enter the password when prompted: $DROPLET_PASSWORD"
echo ""

# Create a temporary script to run on the Droplet
cat > check_logs_remote.sh << 'EOF'
#!/bin/bash

# Check the PostgREST service status
echo "PostgREST service status:"
systemctl status postgrest

# Check the journal logs
echo -e "\nPostgREST journal logs:"
journalctl -u postgrest --no-pager -n 50

# Try running PostgREST manually to see any errors
echo -e "\nTrying to run PostgREST manually:"
cd /opt/postgrest
./postgrest postgrest.conf 2>&1 | head -n 20

# Check the configuration file
echo -e "\nPostgREST configuration:"
cat /opt/postgrest/postgrest.conf | grep -v "password"

# Test the database connection
echo -e "\nTesting database connection:"
PGPASSWORD=$(grep -oP 'db-uri = "postgres://web_anon:\K[^@]+' /opt/postgrest/postgrest.conf) psql -h db-postgresql-nyc3-20256-do-user-18794323-0.k.db.ondigitalocean.com -p 25060 -U web_anon -d defaultdb -c "SELECT 1" || echo "Database connection failed"
EOF

# Copy the script to the Droplet
echo "Copying check logs script to the Droplet..."
scp check_logs_remote.sh $DROPLET_USER@$DROPLET_IP:~/

# Execute the script on the Droplet
echo "Executing check logs script on the Droplet..."
ssh $DROPLET_USER@$DROPLET_IP "chmod +x check_logs_remote.sh && ./check_logs_remote.sh"

# Clean up
rm check_logs_remote.sh 