#!/bin/bash
# deploy_middleware.sh
#
# This script deploys the middleware to the remote server.
# Usage: ./workflow/deploy_middleware.sh DROPLET_ID

set -e

# Check for required parameter
if [ -z "$1" ]; then
  echo "Error: DROPLET_ID parameter is required."
  echo "Usage: $0 DROPLET_ID"
  exit 1
fi

DROPLET_ID="$1"

echo "Deploying middleware to droplet $DROPLET_ID..."

# Copy the middleware app.js to the remote server
echo "Copying middleware app.js to remote server..."
doctl compute ssh $DROPLET_ID --ssh-command "sudo mkdir -p /tmp/middleware"
cat workflow/middleware_app.js | doctl compute ssh $DROPLET_ID --ssh-command "cat > /tmp/middleware/app.js"

# Deploy the middleware
echo "Deploying the middleware..."
doctl compute ssh $DROPLET_ID --ssh-command "
  # Backup the original app.js
  sudo cp /opt/htmx-middleware/app.js /opt/htmx-middleware/app.js.bak
  
  # Copy the app.js
  sudo cp /tmp/middleware/app.js /opt/htmx-middleware/app.js
  
  # Set permissions
  sudo chown root:root /opt/htmx-middleware/app.js
  sudo chmod 644 /opt/htmx-middleware/app.js
  
  # Restart the middleware
  sudo pm2 restart htmx-middleware
"

echo "Middleware deployed successfully."
echo "To test the middleware, run:"
echo "doctl compute ssh $DROPLET_ID --ssh-command \"curl http://localhost:3000/health\""
echo "doctl compute ssh $DROPLET_ID --ssh-command \"curl 'http://localhost:3000/api/search?q=How%20to%20implement%20tabs'\"" 