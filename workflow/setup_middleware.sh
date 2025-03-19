#!/bin/bash
# setup_middleware.sh
#
# This script sets up the Node.js middleware for the HTMX Examples Semantic Search API.
# It handles deployment both locally and on a remote Digital Ocean droplet.
#
# Usage: 
#   ./workflow/setup_middleware.sh             # For local deployment
#   ./workflow/setup_middleware.sh --remote DROPLET_ID  # For remote deployment

set -e

# Parse arguments
REMOTE_EXECUTION=false
if [ "$1" == "--remote" ]; then
    REMOTE_EXECUTION=true
    DROPLET_ID="$2"
    if [ -z "$DROPLET_ID" ]; then
        echo "Error: When using --remote, you must provide a droplet ID."
        echo "Usage: $0 --remote DROPLET_ID"
        exit 1
    fi
fi

# Function for local deployment
local_deploy() {
    echo "Setting up middleware locally..."
    
    # Create directory for middleware
    sudo mkdir -p /opt/htmx-middleware
    sudo chown $USER:$USER /opt/htmx-middleware
    
    # Copy middleware files
    cp workflow/middleware_app.js /opt/htmx-middleware/app.js
    cp workflow/package.json /opt/htmx-middleware/
    cp workflow/ecosystem.config.js /opt/htmx-middleware/
    
    # Install Node.js and dependencies
    if ! command -v node &> /dev/null; then
        echo "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Install PM2 globally if not installed
    if ! command -v pm2 &> /dev/null; then
        echo "Installing PM2..."
        sudo npm install -g pm2
    fi
    
    # Install dependencies
    echo "Installing middleware dependencies..."
    cd /opt/htmx-middleware
    npm install --production
    
    # Create .env file
    echo "Creating .env file..."
    if [ -f .env ]; then
        source .env
    fi
    
    cat > /opt/htmx-middleware/.env << EOF
GOOGLE_API_KEY=${GOOGLE_API_KEY}
MIDDLEWARE_PORT=3000
POSTGREST_URL=http://localhost:3001
EOF
    
    # Set permissions
    chmod 600 /opt/htmx-middleware/.env
    
    # Start the middleware with PM2
    echo "Starting middleware with PM2..."
    cd /opt/htmx-middleware
    pm2 start ecosystem.config.js
    pm2 save
    pm2 startup
    
    echo "Middleware setup completed locally."
}

# Function for remote deployment
remote_deploy() {
    echo "Setting up middleware on droplet $DROPLET_ID..."
    
    # Create a temporary script to run on the remote server
    TMP_SCRIPT=$(mktemp)
    
    # Load environment variables
    source .env || echo "Warning: Could not source .env file"
    
    # Create the script content
    cat > "$TMP_SCRIPT" << EOF
#!/bin/bash
set -e

echo "Setting up Node.js middleware on the remote server..."

# Install Node.js if not installed
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install PM2 globally if not installed
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    sudo npm install -g pm2
fi

# Create directory for middleware
sudo mkdir -p /opt/htmx-middleware
sudo chown \$(whoami):\$(whoami) /opt/htmx-middleware

# Create app.js
cat > /opt/htmx-middleware/app.js << 'EOL'
$(cat workflow/middleware_app.js)
EOL

# Create package.json
cat > /opt/htmx-middleware/package.json << 'EOL'
$(cat workflow/package.json)
EOL

# Create ecosystem.config.js
cat > /opt/htmx-middleware/ecosystem.config.js << 'EOL'
$(cat workflow/ecosystem.config.js)
EOL

# Create .env file
cat > /opt/htmx-middleware/.env << EOL
GOOGLE_API_KEY=${GOOGLE_API_KEY}
MIDDLEWARE_PORT=3000
POSTGREST_URL=http://localhost:3001
EOL

# Set permissions
chmod 600 /opt/htmx-middleware/.env

# Install dependencies
echo "Installing middleware dependencies..."
cd /opt/htmx-middleware
npm install --production

# Start the middleware with PM2
echo "Starting middleware with PM2..."
cd /opt/htmx-middleware
pm2 start ecosystem.config.js
pm2 save
sudo env PATH=\$PATH:/usr/bin pm2 startup systemd -u \$(whoami) --hp /home/\$(whoami)
sudo systemctl enable pm2-\$(whoami)

echo "Middleware setup completed on remote server."
EOF
    
    # Make the script executable
    chmod +x "$TMP_SCRIPT"
    
    # Execute the script on the remote server
    echo "Uploading and executing setup script on remote server..."
    doctl compute ssh "$DROPLET_ID" --ssh-command "bash -s" < "$TMP_SCRIPT"
    
    # Clean up the temporary script
    rm "$TMP_SCRIPT"
    
    echo "Remote middleware deployment completed."
}

# Check for required environment variables
if [ -z "$GOOGLE_API_KEY" ]; then
    echo "Warning: GOOGLE_API_KEY is not set in environment variables."
    echo "Please make sure to set this in your .env file before running the middleware."
fi

# Main execution
if [ "$REMOTE_EXECUTION" = true ]; then
    remote_deploy
else
    local_deploy
fi

echo ""
echo "==========================================================="
echo "Middleware Deployment Summary:"
echo "- Middleware installed and configured"
if [ "$REMOTE_EXECUTION" = true ]; then
    echo "- Running on droplet $DROPLET_ID at port 3000"
    echo "- Connect to PostgREST at http://localhost:3001"
else
    echo "- Running locally at http://localhost:3000"
    echo "- Connect to PostgREST at http://localhost:3001"
fi
echo "==========================================================="
echo ""
echo "To test the middleware, run:"
if [ "$REMOTE_EXECUTION" = true ]; then
    echo "doctl compute ssh $DROPLET_ID --ssh-command \"curl http://localhost:3000/health\""
    echo "doctl compute ssh $DROPLET_ID --ssh-command \"curl 'http://localhost:3000/api/search?q=How%20to%20implement%20tabs'\""
else
    echo "curl http://localhost:3000/health"
    echo "curl 'http://localhost:3000/api/search?q=How%20to%20implement%20tabs'"
fi
echo "===========================================================" 