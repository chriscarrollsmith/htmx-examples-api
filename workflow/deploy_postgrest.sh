#!/bin/bash
#
# PostgREST Deployment Script
# This script installs and configures PostgREST on a Digital Ocean Droplet
#
# Usage: ./deploy_postgrest.sh [--version <version>] [--port <port>] [--config-only]
#
# Author: AI Assistant

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

# Get the absolute path to the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
POSTGREST_VERSION="v12.2.8"
POSTGREST_PORT="3001"
POSTGREST_DIR="/opt/postgrest"
CONFIG_ONLY=false
LOG_FILE="postgrest_deploy.log"

# ANSI color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} ${timestamp} - $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} ${timestamp} - $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $message"
            ;;
        *)
            echo -e "${timestamp} - $message"
            ;;
    esac
    
    # Also log to file
    echo "${timestamp} [$level] - $message" >> $LOG_FILE
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to load environment variables from .env file
load_env() {
    # Try to load from the project root .env file
    ENV_FILE="${PROJECT_ROOT}/.env"
    
    if [ -f "$ENV_FILE" ]; then
        log "INFO" "Loading environment variables from ${ENV_FILE}"
        set -a
        source "$ENV_FILE"
        set +a
    else
        log "ERROR" "${ENV_FILE} not found. Please create one with the required variables."
        exit 1
    fi
    
    # Check for required environment variables
    local required_vars=("DB_HOST" "DB_PORT" "DB_NAME" "POSTGREST_PASSWORD" "POSTGREST_JWT_SECRET")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    # Set a default value for POSTGREST_USER if not defined
    if [ -z "${POSTGREST_USER:-}" ]; then
        log "INFO" "POSTGREST_USER not defined, using 'web_anon' as default"
        POSTGREST_USER="web_anon"
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log "ERROR" "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
}

# Function to print usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --version VERSION     Specify PostgREST version (default: $POSTGREST_VERSION)"
    echo "  --port PORT           Specify PostgREST port (default: $POSTGREST_PORT)"
    echo "  --config-only         Only update configuration, don't reinstall PostgREST"
    echo "  --help                Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            POSTGREST_VERSION="$2"
            shift 2
            ;;
        --port)
            POSTGREST_PORT="$2"
            shift 2
            ;;
        --config-only)
            CONFIG_ONLY=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            usage
            ;;
    esac
done

# Start the deployment process
log "INFO" "Starting PostgREST deployment process"
log "INFO" "PostgREST version: $POSTGREST_VERSION"
log "INFO" "PostgREST port: $POSTGREST_PORT"

# Load environment variables
load_env

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    log "ERROR" "This script must be run as root"
    exit 1
fi

# Create PostgREST directory
if [ ! -d "$POSTGREST_DIR" ]; then
    log "INFO" "Creating PostgREST directory: $POSTGREST_DIR"
    mkdir -p $POSTGREST_DIR
fi

# Install PostgREST if not config-only mode
if [ "$CONFIG_ONLY" = false ]; then
    log "INFO" "Installing PostgREST version $POSTGREST_VERSION"
    
    # Check if wget is installed
    if ! command_exists wget; then
        log "INFO" "Installing wget..."
        apt-get update && apt-get install -y wget
    fi
    
    # Download and extract PostgREST
    cd $POSTGREST_DIR
    log "INFO" "Downloading PostgREST binary"
    wget -q https://github.com/PostgREST/postgrest/releases/download/$POSTGREST_VERSION/postgrest-$POSTGREST_VERSION-linux-static-x64.tar.xz -O postgrest.tar.xz
    
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to download PostgREST binary"
        exit 1
    fi
    
    log "INFO" "Extracting PostgREST binary"
    tar -xf postgrest.tar.xz
    rm postgrest.tar.xz
    
    # Make the binary executable
    chmod +x postgrest
    
    log "SUCCESS" "PostgREST binary installed successfully"
fi

# Create PostgREST configuration file
log "INFO" "Creating PostgREST configuration file"
log "INFO" "Using database role: $POSTGREST_USER"

cat > $POSTGREST_DIR/postgrest.conf << EOF
# PostgreSQL connection string
db-uri = "postgres://${POSTGREST_USER}:${POSTGREST_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=require"

# The database schema to expose to REST clients
db-schema = "api"

# The database role to use when executing commands
db-anon-role = "${POSTGREST_USER}"

# JWT secret for authentication (if needed)
jwt-secret = "${POSTGREST_JWT_SECRET}"

# Server settings
server-port = ${POSTGREST_PORT}
server-host = "127.0.0.1"  # Only listen on localhost, as Nginx will proxy requests

# The maximum number of rows to return from a request
max-rows = 100

# Additional schema paths
db-extra-search-path = "public"
EOF

log "SUCCESS" "PostgREST configuration file created successfully"

# Create systemd service file
log "INFO" "Creating systemd service file"

cat > /etc/systemd/system/postgrest.service << EOF
[Unit]
Description=PostgREST API Server
After=network.target

[Service]
ExecStart=${POSTGREST_DIR}/postgrest ${POSTGREST_DIR}/postgrest.conf
Restart=always
User=root
Group=root
WorkingDirectory=${POSTGREST_DIR}
Environment="PGRST_JWT_SECRET=${POSTGREST_JWT_SECRET}"

[Install]
WantedBy=multi-user.target
EOF

log "SUCCESS" "Systemd service file created successfully"

# Reload systemd daemon
log "INFO" "Reloading systemd daemon"
systemctl daemon-reload

# Enable and start/restart PostgREST service
log "INFO" "Enabling PostgREST service"
systemctl enable postgrest

log "INFO" "Starting/restarting PostgREST service"
systemctl restart postgrest

# Check service status
sleep 2  # Give it a moment to start
if systemctl is-active --quiet postgrest; then
    log "SUCCESS" "PostgREST service is running"
else
    log "ERROR" "PostgREST service failed to start. Check logs with: journalctl -u postgrest"
    exit 1
fi

# Test the connection to the service
log "INFO" "Testing connection to PostgREST"
if command_exists curl; then
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$POSTGREST_PORT/ || echo "Failed")
    
    if [ "$response" = "200" ] || [ "$response" = "204" ]; then
        log "SUCCESS" "Successfully connected to PostgREST"
    else
        log "WARNING" "Could not connect to PostgREST. Got response code: $response"
        log "INFO" "This might be expected if the API schema is empty or if there are permission issues"
    fi
else
    log "WARNING" "curl is not installed. Skipping connection test."
fi

# Verify database connection
log "INFO" "Verifying database connection"
if command_exists psql; then
    if PGPASSWORD="$POSTGREST_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$POSTGREST_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null; then
        log "SUCCESS" "Database connection verified"
    else
        log "WARNING" "Could not connect to database as $POSTGREST_USER"
        log "INFO" "Please verify database credentials and permissions"
    fi
else
    log "WARNING" "psql is not installed. Skipping database connection verification."
fi

log "SUCCESS" "PostgREST deployment completed successfully"
log "INFO" "You can now access the API at: http://localhost:$POSTGREST_PORT/"
log "INFO" "Service status: systemctl status postgrest"
log "INFO" "Service logs: journalctl -u postgrest"

exit 0 