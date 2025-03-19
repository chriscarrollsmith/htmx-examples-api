 #!/bin/bash
# teardown_postgrest.sh
#
# This script stops the PostgREST service and cleans up configuration files
# to prepare for testing the setup_postgrest_config.sh script.
#
# Usage: ./workflow/teardown_postgrest.sh [--remote] [droplet_id]
#        If --remote flag is provided, the script will run on the specified remote droplet.

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

# Function for local cleanup
local_cleanup() {
    echo "Performing local PostgREST cleanup..."
    
    # Stop and disable the service if it exists
    if systemctl list-unit-files | grep -q postgrest.service; then
        echo "Stopping PostgREST service..."
        sudo systemctl stop postgrest || echo "Service was not running"
        sudo systemctl disable postgrest || echo "Could not disable service"
    fi
    
    # Backup and remove config files
    if [ -d "/opt/postgrest" ]; then
        echo "Backing up PostgREST configuration files..."
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        sudo mkdir -p /opt/postgrest_backups
        
        if [ -f "/opt/postgrest/postgrest.conf" ]; then
            sudo cp /opt/postgrest/postgrest.conf /opt/postgrest_backups/postgrest.conf.$TIMESTAMP
            echo "Configuration backed up to /opt/postgrest_backups/postgrest.conf.$TIMESTAMP"
            sudo rm /opt/postgrest/postgrest.conf
            echo "Removed /opt/postgrest/postgrest.conf"
        fi
        
        if [ -f "/etc/systemd/system/postgrest.service" ]; then
            sudo cp /etc/systemd/system/postgrest.service /opt/postgrest_backups/postgrest.service.$TIMESTAMP
            echo "Service file backed up to /opt/postgrest_backups/postgrest.service.$TIMESTAMP"
            sudo rm /etc/systemd/system/postgrest.service
            echo "Removed /etc/systemd/system/postgrest.service"
        fi
        
        # Reload systemd to recognize the changes
        sudo systemctl daemon-reload
    else
        echo "No PostgREST directory found at /opt/postgrest"
    fi
    
    echo "Cleanup completed successfully."
    echo "Ready to test setup_postgrest_config.sh"
}

# Function for remote cleanup
remote_cleanup() {
    echo "Performing remote PostgREST cleanup on droplet $DROPLET_ID..."
    
    # Create a temporary script to run on the remote server
    TMP_SCRIPT=$(mktemp)
    cat > "$TMP_SCRIPT" << 'EOF'
#!/bin/bash
set -e

echo "Stopping PostgREST service..."
systemctl stop postgrest 2>/dev/null || echo "Service was not running"
systemctl disable postgrest 2>/dev/null || echo "Could not disable service"

# Backup and remove config files
if [ -d "/opt/postgrest" ]; then
    echo "Backing up PostgREST configuration files..."
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mkdir -p /opt/postgrest_backups
    
    if [ -f "/opt/postgrest/postgrest.conf" ]; then
        cp /opt/postgrest/postgrest.conf /opt/postgrest_backups/postgrest.conf.$TIMESTAMP
        echo "Configuration backed up to /opt/postgrest_backups/postgrest.conf.$TIMESTAMP"
        rm /opt/postgrest/postgrest.conf
        echo "Removed /opt/postgrest/postgrest.conf"
    fi
    
    if [ -f "/etc/systemd/system/postgrest.service" ]; then
        cp /etc/systemd/system/postgrest.service /opt/postgrest_backups/postgrest.service.$TIMESTAMP
        echo "Service file backed up to /opt/postgrest_backups/postgrest.service.$TIMESTAMP"
        rm /etc/systemd/system/postgrest.service
        echo "Removed /etc/systemd/system/postgrest.service"
    fi
    
    # Reload systemd to recognize the changes
    systemctl daemon-reload
else
    echo "No PostgREST directory found at /opt/postgrest"
fi

echo "Cleanup completed successfully on remote server."
echo "Ready to test setup_postgrest_config.sh"
EOF
    
    # Make the script executable
    chmod +x "$TMP_SCRIPT"
    
    # Execute the script on the remote server
    echo "Uploading and executing cleanup script on remote server..."
    source .env || echo "Warning: Could not source .env file"
    doctl compute ssh "$DROPLET_ID" --ssh-command "bash -s" < "$TMP_SCRIPT"
    
    # Clean up the temporary script
    rm "$TMP_SCRIPT"
    
    echo "Remote cleanup completed."
}

# Verify environment variables before proceeding
check_env_vars() {
    if [ -f .env ]; then
        source .env
        
        local missing_vars=0
        if [ -z "$DB_HOST" ]; then echo "Warning: DB_HOST is not set"; missing_vars=1; fi
        if [ -z "$DB_PORT" ]; then echo "Warning: DB_PORT is not set"; missing_vars=1; fi
        if [ -z "$DB_NAME" ]; then echo "Warning: DB_NAME is not set"; missing_vars=1; fi
        if [ -z "$POSTGREST_PASSWORD" ]; then echo "Warning: POSTGREST_PASSWORD is not set"; missing_vars=1; fi
        if [ -z "$POSTGREST_JWT_SECRET" ]; then echo "Warning: POSTGREST_JWT_SECRET is not set"; missing_vars=1; fi
        
        if [ $missing_vars -eq 1 ]; then
            echo ""
            echo "One or more required environment variables are missing."
            echo "Please set them in your .env file before running setup_postgrest_config.sh"
            echo ""
        else
            echo "All required environment variables are set."
        fi
    else
        echo "Warning: No .env file found. Make sure to set required environment variables before running setup_postgrest_config.sh"
    fi
}

# Main execution logic
if [ "$REMOTE_EXECUTION" = true ]; then
    echo "Performing remote cleanup operations on droplet $DROPLET_ID..."
    remote_cleanup
else
    echo "Performing local cleanup operations..."
    local_cleanup
fi

# Check environment variables
check_env_vars

echo ""
echo "==========================================================="
echo "Teardown complete! You can now test setup_postgrest_config.sh with:"
if [ "$REMOTE_EXECUTION" = true ]; then
    echo "./workflow/setup_postgrest_config.sh --remote $DROPLET_ID"
else
    echo "./workflow/setup_postgrest_config.sh"
fi
echo "==========================================================="