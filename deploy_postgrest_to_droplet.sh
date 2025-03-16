#!/bin/bash

# This script sets up PostgREST on a Digital Ocean Droplet
# Run this script on your new Droplet after creating it

# Install dependencies
apt-get update
apt-get install -y wget unzip

# Create a directory for PostgREST
mkdir -p /opt/postgrest
cd /opt/postgrest

# Download the latest version of PostgREST
wget https://github.com/PostgREST/postgrest/releases/download/v10.2.0/postgrest-v10.2.0-linux-static-x64.tar.xz
tar -xf postgrest-v10.2.0-linux-static-x64.tar.xz
rm postgrest-v10.2.0-linux-static-x64.tar.xz

# Create a configuration file
cat > /opt/postgrest/postgrest.conf << EOF
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
EOF

# Create a systemd service file
cat > /etc/systemd/system/postgrest.service << EOF
[Unit]
Description=PostgREST API Server
After=network.target

[Service]
ExecStart=/opt/postgrest/postgrest /opt/postgrest/postgrest.conf
Restart=always
User=root
Group=root
WorkingDirectory=/opt/postgrest

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable postgrest
systemctl start postgrest

# Install Nginx as a reverse proxy
apt-get install -y nginx

# Configure Nginx
cat > /etc/nginx/sites-available/postgrest << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the Nginx configuration
ln -s /etc/nginx/sites-available/postgrest /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
systemctl restart nginx

# Install certbot for HTTPS
apt-get install -y certbot python3-certbot-nginx

echo "PostgREST has been installed and configured."
echo "To enable HTTPS, run: certbot --nginx -d your-domain.com"
echo "Remember to update the PostgreSQL database to allow the web_anon role to connect without a password." 