#!/bin/bash
# setup_postgrest_config.sh
#
# This script sets up PostgREST with proper configuration handling special characters
# in passwords by URL-encoding them to prevent connection string parsing issues.
#
# Usage: ./setup_postgrest_config.sh [--remote] [droplet_id]
#        If --remote flag is provided, the script will attempt to update a remote server
#        via doctl ssh using the droplet_id.

set -e

# Function to URL encode special characters in a string
# Particularly focuses on characters that cause issues in connection strings
url_encode_password() {
    local string="$1"
    # URL encode / and + which are common special chars in base64 that cause issues
    echo "$string" | sed 's|/|%2F|g; s|+|%2B|g; s|&|%26|g; s|=|%3D|g'
}

# Function to create the PostgREST configuration with URL-encoded password
create_postgrest_conf() {
    local postgrest_dir="$1"
    local db_user="$2"
    local raw_password="$3"
    local encoded_password="$4"
    local db_host="$5"
    local db_port="$6"
    local db_name="$7"
    local jwt_secret="$8"

    # Create configuration file
    cat > "${postgrest_dir}/postgrest.conf" << EOF
# PostgreSQL connection string
db-uri = "postgres://${db_user}:${encoded_password}@${db_host}:${db_port}/${db_name}?sslmode=require"

# The database schema to expose to REST clients
db-schema = "api"

# The database role to use when executing commands
db-anon-role = "${db_user}"

# JWT secret for authentication
jwt-secret = "${jwt_secret}"

# Server settings
server-port = 3001
server-host = "127.0.0.1"  # Only listen on localhost, as Nginx will proxy requests

# The maximum number of rows to return from a request
max-rows = 100

# Additional schema paths
db-extra-search-path = "public"
EOF

    echo "Created PostgREST configuration at ${postgrest_dir}/postgrest.conf"
    # Don't print the actual password, only indicate if it needed encoding
    if [[ "$raw_password" != "$encoded_password" ]]; then
        echo "Password required URL encoding: Yes (special characters detected)"
    else
        echo "Password required URL encoding: No (no special characters detected)"
    fi
}

# Function to create a systemd service file for PostgREST
create_systemd_service() {
    local postgrest_dir="$1"
    local jwt_secret="$2"

    cat > "${postgrest_dir}/postgrest.service" << EOF
[Unit]
Description=PostgREST API Server
After=network.target

[Service]
ExecStart=${postgrest_dir}/postgrest ${postgrest_dir}/postgrest.conf
Restart=always
User=root
Group=root
WorkingDirectory=${postgrest_dir}
Environment="PGRST_JWT_SECRET=${jwt_secret}"

[Install]
WantedBy=multi-user.target
EOF

    echo "Created systemd service file at ${postgrest_dir}/postgrest.service"
}

# Main script logic
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

# Load environment variables if .env file exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    source .env
else
    echo "Warning: No .env file found. Using environment variables if they exist."
fi

# Check if required variables are set
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$POSTGREST_PASSWORD" ] || [ -z "$POSTGREST_JWT_SECRET" ]; then
    echo "Error: Required environment variables are not set."
    echo "Please ensure the following are set in your .env file or environment:"
    echo "- DB_HOST"
    echo "- DB_PORT"
    echo "- DB_NAME"
    echo "- POSTGREST_PASSWORD"
    echo "- POSTGREST_JWT_SECRET"
    exit 1
fi

# Set default value for POSTGREST_USER if not provided
POSTGREST_USER=${POSTGREST_USER:-web_anon}

# URL encode the password
ENCODED_PASSWORD=$(url_encode_password "$POSTGREST_PASSWORD")

echo "PostgREST Configuration Setup"
echo "----------------------------"
echo "Database Host: $DB_HOST"
echo "Database Port: $DB_PORT"
echo "Database Name: $DB_NAME"
echo "PostgREST User: $POSTGREST_USER"
echo "Password contains special characters that need URL encoding: $(echo "$POSTGREST_PASSWORD" | grep -q '[/+&=]' && echo "Yes" || echo "No")"

# Local execution (for testing or local setup)
if [ "$REMOTE_EXECUTION" = false ]; then
    POSTGREST_DIR="/opt/postgrest"
    
    # Create directory if it doesn't exist
    if [ ! -d "$POSTGREST_DIR" ]; then
        echo "Creating PostgREST directory..."
        sudo mkdir -p "$POSTGREST_DIR"
    fi
    
    echo "Creating configuration locally..."
    create_postgrest_conf "$POSTGREST_DIR" "$POSTGREST_USER" "$POSTGREST_PASSWORD" "$ENCODED_PASSWORD" "$DB_HOST" "$DB_PORT" "$DB_NAME" "$POSTGREST_JWT_SECRET"
    create_systemd_service "$POSTGREST_DIR" "$POSTGREST_JWT_SECRET"
    
    # Move the systemd service file to the right location and reload systemd
    echo "Installing systemd service..."
    sudo mv "${POSTGREST_DIR}/postgrest.service" /etc/systemd/system/
    sudo systemctl daemon-reload
    
    echo "Configuration complete. You can now enable and start the PostgREST service with:"
    echo "sudo systemctl enable postgrest"
    echo "sudo systemctl start postgrest"
else
    # Remote execution on a Digital Ocean droplet
    echo "Setting up PostgREST configuration on remote droplet $DROPLET_ID..."
    
    # Create a temporary script to run on the remote server
    TMP_SCRIPT=$(mktemp)
    cat > "$TMP_SCRIPT" << EOF
#!/bin/bash
set -e

# Create PostgREST directory if it doesn't exist
mkdir -p /opt/postgrest

# Create configuration file with URL-encoded password
cat > /opt/postgrest/postgrest.conf << EOL
# PostgreSQL connection string
db-uri = "postgres://${POSTGREST_USER}:${ENCODED_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=require"

# The database schema to expose to REST clients
db-schema = "api"

# The database role to use when executing commands
db-anon-role = "${POSTGREST_USER}"

# JWT secret for authentication
jwt-secret = "${POSTGREST_JWT_SECRET}"

# Server settings
server-port = 3001
server-host = "127.0.0.1"  # Only listen on localhost, as Nginx will proxy requests

# The maximum number of rows to return from a request
max-rows = 100

# Additional schema paths
db-extra-search-path = "public"
EOL

# Create systemd service file
cat > /etc/systemd/system/postgrest.service << EOL
[Unit]
Description=PostgREST API Server
After=network.target

[Service]
ExecStart=/opt/postgrest/postgrest /opt/postgrest/postgrest.conf
Restart=always
User=root
Group=root
WorkingDirectory=/opt/postgrest
Environment="PGRST_JWT_SECRET=${POSTGREST_JWT_SECRET}"

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd configuration
systemctl daemon-reload

echo "PostgREST configuration complete on remote server."
if [[ "$POSTGREST_PASSWORD" != "$ENCODED_PASSWORD" ]]; then
    echo "Password required URL encoding: Yes (special characters detected)"
else
    echo "Password required URL encoding: No (no special characters detected)"
fi
echo "You can now enable and start the PostgREST service with:"
echo "systemctl enable postgrest"
echo "systemctl start postgrest"
EOF
    
    # Make the script executable
    chmod +x "$TMP_SCRIPT"
    
    # Execute the script on the remote server
    echo "Uploading and executing configuration script on remote server..."
    doctl compute ssh "$DROPLET_ID" --ssh-command "bash -s" < "$TMP_SCRIPT"
    
    # Clean up the temporary script
    rm "$TMP_SCRIPT"
    
    echo "Remote configuration complete."
fi

echo ""
echo "Configuration Summary:"
echo "---------------------"
echo "PostgREST User: $POSTGREST_USER"
echo "Database Connection: postgres://${POSTGREST_USER}:***@${DB_HOST}:${DB_PORT}/${DB_NAME}"
if [[ "$POSTGREST_PASSWORD" != "$ENCODED_PASSWORD" ]]; then
    echo "Password URL-Encoded: Yes (special characters were properly encoded)"
else
    echo "Password URL-Encoded: No (no special characters detected)"
fi
echo ""
echo "Note: If you have special characters in your password, they have been URL-encoded"
echo "to prevent connection string parsing issues with PostgREST." 