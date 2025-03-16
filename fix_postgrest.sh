#!/bin/bash

# This script fixes the PostgREST service on the Droplet

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

echo "Fixing PostgREST service on $DROPLET_IP..."
echo "Please enter the password when prompted: $DROPLET_PASSWORD"
echo ""

# Create a temporary script to run on the Droplet
cat > fix_postgrest_remote.sh << 'EOF'
#!/bin/bash

# Install necessary tools
apt-get update
apt-get install -y net-tools

# Check if PostgREST binary exists and is executable
if [ ! -x /opt/postgrest/postgrest ]; then
    echo "PostgREST binary is missing or not executable."
    ls -la /opt/postgrest/
    exit 1
fi

# Check the PostgREST configuration
echo "Current PostgREST configuration:"
cat /opt/postgrest/postgrest.conf

# Test the database connection
echo "Testing database connection..."
apt-get install -y postgresql-client
PGPASSWORD='' psql -h db-postgresql-nyc3-20256-do-user-18794323-0.k.db.ondigitalocean.com -p 25060 -U web_anon -d defaultdb -c "SELECT 1" || echo "Database connection failed"

# Check for errors in the journal
echo "Checking for errors in the journal..."
journalctl -u postgrest --no-pager -n 100

# Restart the PostgREST service
echo "Restarting PostgREST service..."
systemctl restart postgrest
sleep 5
systemctl status postgrest

# Check if PostgREST is now listening on port 3000
echo "Checking if PostgREST is listening on port 3000..."
netstat -tulpn | grep 3000 || echo "PostgREST is still not listening on port 3000"

# Try running PostgREST manually to see any errors
echo "Trying to run PostgREST manually..."
cd /opt/postgrest
./postgrest postgrest.conf &
PID=$!
sleep 5
kill $PID || true

# Check Nginx error logs
echo "Checking Nginx error logs..."
cat /var/log/nginx/error.log
EOF

# Copy the script to the Droplet
echo "Copying fix script to the Droplet..."
scp fix_postgrest_remote.sh $DROPLET_USER@$DROPLET_IP:~/

# Execute the script on the Droplet
echo "Executing fix script on the Droplet..."
ssh $DROPLET_USER@$DROPLET_IP "chmod +x fix_postgrest_remote.sh && ./fix_postgrest_remote.sh"

# Clean up
rm fix_postgrest_remote.sh 