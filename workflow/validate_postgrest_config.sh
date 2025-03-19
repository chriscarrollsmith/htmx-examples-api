#!/bin/bash
# validate_postgrest_config.sh
#
# This script validates that the PostgREST configuration was set up correctly
# by checking for required files and validating their content.
#
# Usage: ./artifacts/validate_postgrest_config.sh [--remote] [droplet_id]
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

# Function for local validation
local_validate() {
    echo "Validating local PostgREST configuration..."
    
    # Check if configuration directory exists
    if [ ! -d "/opt/postgrest" ]; then
        echo "❌ ERROR: PostgREST directory does not exist at /opt/postgrest"
        return 1
    fi
    
    # Check if configuration file exists
    if [ ! -f "/opt/postgrest/postgrest.conf" ]; then
        echo "❌ ERROR: Configuration file does not exist at /opt/postgrest/postgrest.conf"
        return 1
    fi
    
    # Check if systemd service file exists
    if [ ! -f "/etc/systemd/system/postgrest.service" ]; then
        echo "❌ ERROR: Systemd service file does not exist at /etc/systemd/system/postgrest.service"
        return 1
    fi
    
    # Validate configuration file contents
    echo "Validating configuration file content..."
    
    # Load environment variables
    if [ -f .env ]; then
        source .env
    fi
    
    # Check if the connection string is properly formatted
    grep -q "db-uri = \"postgres://" /opt/postgrest/postgrest.conf
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Connection string not found or improperly formatted in configuration file"
        return 1
    fi
    
    # Check for special characters in password and proper URL encoding
    if [ -n "$POSTGREST_PASSWORD" ]; then
        if echo "$POSTGREST_PASSWORD" | grep -q '[/+&=]'; then
            # Password contains special characters, check for URL encoding
            for char in "/" "+" "&" "="; do
                if echo "$POSTGREST_PASSWORD" | grep -q "$char"; then
                    encoded_char=$(echo "$char" | sed 's|/|%2F|g; s|+|%2B|g; s|&|%26|g; s|=|%3D|g')
                    if ! grep -q "$encoded_char" /opt/postgrest/postgrest.conf; then
                        echo "❌ ERROR: Special character '$char' in password should be URL-encoded as '$encoded_char' but encoding not found"
                        return 1
                    fi
                fi
            done
            echo "✅ Password special characters are correctly URL-encoded in the configuration"
        else
            echo "✅ No special characters found in password that require URL encoding"
        fi
    else
        echo "⚠️ WARNING: POSTGREST_PASSWORD not set in environment, skipping URL encoding check"
    fi
    
    # Check if systemd service file references the correct configuration
    grep -q "ExecStart=/opt/postgrest/postgrest /opt/postgrest/postgrest.conf" /etc/systemd/system/postgrest.service
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Systemd service file does not reference the correct PostgREST binary or configuration file"
        return 1
    fi
    
    # Output configuration for inspection
    echo "Current configuration file content (with password masked):"
    cat /opt/postgrest/postgrest.conf | sed 's/\(db-uri = "postgres:\/\/[^:]*:\)[^@]*\(@.*\)/\1******\2/'
    
    echo ""
    echo "✅ All validation checks passed! PostgREST is correctly configured."
    return 0
}

# Function for remote validation
remote_validate() {
    echo "Validating PostgREST configuration on droplet $DROPLET_ID..."
    
    # Create a temporary script to run on the remote server
    TMP_SCRIPT=$(mktemp)
    cat > "$TMP_SCRIPT" << 'EOF'
#!/bin/bash
set -e

# Check if configuration directory exists
if [ ! -d "/opt/postgrest" ]; then
    echo "❌ ERROR: PostgREST directory does not exist at /opt/postgrest"
    exit 1
fi

# Check if configuration file exists
if [ ! -f "/opt/postgrest/postgrest.conf" ]; then
    echo "❌ ERROR: Configuration file does not exist at /opt/postgrest/postgrest.conf"
    exit 1
fi

# Check if systemd service file exists
if [ ! -f "/etc/systemd/system/postgrest.service" ]; then
    echo "❌ ERROR: Systemd service file does not exist at /etc/systemd/system/postgrest.service"
    exit 1
fi

# Validate configuration file contents
echo "Validating configuration file content..."

# Check if the connection string is properly formatted
grep -q "db-uri = \"postgres://" /opt/postgrest/postgrest.conf
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Connection string not found or improperly formatted in configuration file"
    exit 1
fi

# Check if systemd service file references the correct configuration
grep -q "ExecStart=/opt/postgrest/postgrest /opt/postgrest/postgrest.conf" /etc/systemd/system/postgrest.service
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Systemd service file does not reference the correct PostgREST binary or configuration file"
    exit 1
fi

# Check the password part of the connection string for URL encoding
# Extract password from the connection string
password_part=$(grep "db-uri" /opt/postgrest/postgrest.conf | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
if echo "$password_part" | grep -q '%'; then
    echo "✅ Password appears to be URL-encoded (contains % character)"
else
    echo "⚠️ WARNING: Password does not appear to be URL-encoded (no % character found)"
    echo "   This is OK if the password doesn't contain special characters that need encoding"
fi

# Output configuration for inspection (with password masked)
echo "Current configuration file content (with password masked):"
cat /opt/postgrest/postgrest.conf | sed 's/\(db-uri = "postgres:\/\/[^:]*:\)[^@]*\(@.*\)/\1******\2/'

echo ""
echo "✅ All validation checks passed! PostgREST is correctly configured."
exit 0
EOF
    
    # Make the script executable
    chmod +x "$TMP_SCRIPT"
    
    # Execute the script on the remote server
    echo "Uploading and executing validation script on remote server..."
    source .env || echo "Warning: Could not source .env file"
    doctl compute ssh "$DROPLET_ID" --ssh-command "bash -s" < "$TMP_SCRIPT"
    
    # Clean up the temporary script
    rm "$TMP_SCRIPT"
    
    echo "Remote validation completed."
}

# Main execution logic
if [ "$REMOTE_EXECUTION" = true ]; then
    echo "Performing remote validation on droplet $DROPLET_ID..."
    remote_validate
else
    echo "Performing local validation..."
    local_validate
fi

echo ""
echo "==========================================================="
echo "To restart and test the PostgREST service, use:"
if [ "$REMOTE_EXECUTION" = true ]; then
    echo "doctl compute ssh $DROPLET_ID --ssh-command \"systemctl restart postgrest && sleep 2 && systemctl status postgrest\""
    echo "doctl compute ssh $DROPLET_ID --ssh-command \"curl http://localhost:3001/ -v\""
else
    echo "sudo systemctl restart postgrest && sleep 2 && sudo systemctl status postgrest"
    echo "curl http://localhost:3001/ -v"
fi
echo "===========================================================" 