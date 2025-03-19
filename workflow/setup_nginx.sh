#!/bin/bash
# setup_nginx.sh
#
# This script sets up Nginx as a reverse proxy for the HTMX Examples Semantic Search API.
# It handles deployment on a remote Digital Ocean droplet.
#
# Usage: 
#   ./workflow/setup_nginx.sh --remote DROPLET_ID

set -e

# Parse arguments
if [ "$1" != "--remote" ]; then
    echo "Error: This script is designed to run on a remote droplet only."
    echo "Usage: $0 --remote DROPLET_ID"
    exit 1
fi

DROPLET_ID="$2"
if [ -z "$DROPLET_ID" ]; then
    echo "Error: You must provide a droplet ID."
    echo "Usage: $0 --remote DROPLET_ID"
    exit 1
fi

# Create a temporary script to run on the remote server
TMP_SCRIPT=$(mktemp)

# Create the script content
cat > "$TMP_SCRIPT" << 'EOF'
#!/bin/bash
set -e

echo "Setting up Nginx reverse proxy..."

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx
fi

# Create Nginx configuration
echo "Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/htmx-api << 'EOL'
server {
    listen 80;
    server_name _;

    # Middleware API
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Optional: Direct PostgREST access
    location /direct/ {
        proxy_pass http://localhost:3001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL

# Enable the configuration
echo "Enabling Nginx configuration..."
sudo ln -sf /etc/nginx/sites-available/htmx-api /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

# Restart Nginx
echo "Restarting Nginx..."
sudo systemctl restart nginx
sudo systemctl enable nginx

# Set up firewall (if installed)
if command -v ufw &> /dev/null; then
    echo "Configuring firewall..."
    sudo ufw allow 22
    sudo ufw allow 80
    sudo ufw allow 443
    
    # Enable firewall if not enabled
    if ! sudo ufw status | grep -q "Status: active"; then
        echo "Enabling firewall..."
        echo "y" | sudo ufw enable
    fi
fi

echo "Nginx setup completed!"
echo "API should now be accessible at http://$(curl -s ifconfig.me)"
EOF

# Make the script executable
chmod +x "$TMP_SCRIPT"

# Execute the script on the remote server
echo "Uploading and executing setup script on remote server..."
doctl compute ssh "$DROPLET_ID" --ssh-command "bash -s" < "$TMP_SCRIPT"

# Clean up the temporary script
rm "$TMP_SCRIPT"

# Get the public IP of the droplet
PUBLIC_IP=$(doctl compute droplet get $DROPLET_ID --format PublicIPv4 --no-header)

echo ""
echo "==========================================================="
echo "Nginx Deployment Summary:"
echo "- Nginx installed and configured as a reverse proxy"
echo "- API is now accessible at http://$PUBLIC_IP"
echo "- Endpoints:"
echo "  - Main API: http://$PUBLIC_IP/"
echo "  - Health check: http://$PUBLIC_IP/health"
echo "  - Search: http://$PUBLIC_IP/api/search?q=your+query+here"
echo "  - Multi-search: http://$PUBLIC_IP/api/multi-search?q=your+query+here"
echo "  - Similar examples: http://$PUBLIC_IP/api/similar?id=example-id"
echo "  - Direct PostgREST access: http://$PUBLIC_IP/direct/"
echo "===========================================================" 