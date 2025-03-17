#!/bin/bash
# Script to set up a PostgreSQL database and droplet on DigitalOcean
# This script creates a project, database, and droplet, and assigns them to the project

set -e  # Exit on error

# Print commands before executing them
set -x

# Configuration
PROJECT_NAME="HTMX-Examples"
DB_NAME="htmx-examples-db"
DB_ENGINE="pg"
DB_VERSION="17"
DB_SIZE="db-s-1vcpu-1gb"
DB_REGION="nyc1"
DROPLET_NAME="htmx-postgrest"
DROPLET_SIZE="s-1vcpu-1gb"
DROPLET_IMAGE="ubuntu-22-04-x64"
DROPLET_REGION="nyc1"
ENV_FILE=".env"

# Function to check if doctl is installed
check_doctl() {
    if ! command -v doctl &> /dev/null; then
        echo "Error: doctl is not installed. Please install it first."
        echo "See https://docs.digitalocean.com/reference/doctl/how-to/install/"
        exit 1
    fi

    # Check if doctl is authenticated
    if ! doctl account get &> /dev/null; then
        echo "Error: doctl is not authenticated. Please run 'doctl auth init' first."
        exit 1
    fi
}

# Function to create a project
create_project() {
    local project_name=$1
    
    # Check if project already exists
    if doctl projects list --format Name | grep -q "^${project_name}$"; then
        echo "Project ${project_name} already exists."
        return 0
    fi
    
    # Create project
    echo "Creating project ${project_name}..."
    doctl projects create --name "${project_name}" --purpose "HTMX Examples with PostgREST"
    
    # Get project ID
    PROJECT_ID=$(doctl projects list --format ID,Name | grep "${project_name}" | awk '{print $1}')
    echo "Project ID: ${PROJECT_ID}"
}

# Function to create a database
create_database() {
    local db_name=$1
    local engine=$2
    local version=$3
    local size=$4
    local region=$5
    
    # Check if database already exists
    if doctl databases list --format Name | grep -q "^${db_name}$"; then
        echo "Database ${db_name} already exists."
        DB_ID=$(doctl databases list --format ID,Name | grep "${db_name}" | awk '{print $1}')
        echo "Database ID: ${DB_ID}"
        return 0
    fi
    
    # Create database
    echo "Creating database ${db_name}..."
    doctl databases create "${db_name}" \
        --engine "${engine}" \
        --version "${version}" \
        --size "${size}" \
        --region "${region}" \
        --num-nodes 1
    
    # Get database ID
    DB_ID=$(doctl databases list --format ID,Name | grep "${db_name}" | awk '{print $1}')
    echo "Database ID: ${DB_ID}"
    
    # Wait for database to be ready
    echo "Waiting for database to be ready..."
    while [[ "$(doctl databases get "${DB_ID}" --format Status)" != "online" ]]; do
        echo "Database status: $(doctl databases get "${DB_ID}" --format Status)"
        sleep 10
    done
    echo "Database is ready."
}

# Function to create a droplet
create_droplet() {
    local droplet_name=$1
    local size=$2
    local image=$3
    local region=$4
    
    # Check if droplet already exists
    if doctl compute droplet list --format Name | grep -q "^${droplet_name}$"; then
        echo "Droplet ${droplet_name} already exists."
        DROPLET_ID=$(doctl compute droplet list --format ID,Name | grep "${droplet_name}" | awk '{print $1}')
        echo "Droplet ID: ${DROPLET_ID}"
        return 0
    fi
    
    # Create droplet
    echo "Creating droplet ${droplet_name}..."
    doctl compute droplet create "${droplet_name}" \
        --size "${size}" \
        --image "${image}" \
        --region "${region}" \
        --wait
    
    # Get droplet ID
    DROPLET_ID=$(doctl compute droplet list --format ID,Name | grep "${droplet_name}" | awk '{print $1}')
    echo "Droplet ID: ${DROPLET_ID}"
}

# Function to assign resources to a project
assign_to_project() {
    local project_id=$1
    local db_id=$2
    local droplet_id=$3
    
    # Assign database to project
    echo "Assigning database to project..."
    doctl projects resources assign "${project_id}" --resource=do:database:"${db_id}"
    
    # Assign droplet to project
    echo "Assigning droplet to project..."
    doctl projects resources assign "${project_id}" --resource=do:droplet:"${droplet_id}"
}

# Function to update .env file with database connection details
update_env_file() {
    local db_id=$1
    local env_file=$2
    
    # Get database connection details
    echo "Getting database connection details..."
    DB_HOST=$(doctl databases get "${db_id}" --format PrivateHost | tail -n 1)
    DB_PORT=$(doctl databases get "${db_id}" --format Port | tail -n 1)
    DB_USER=$(doctl databases user get "${db_id}" doadmin --format Name | tail -n 1)
    DB_PASS=$(doctl databases user get "${db_id}" doadmin --format Password | tail -n 1)
    DB_NAME=$(doctl databases db list "${db_id}" --format Name | tail -n 1)
    
    # Create or update .env file
    echo "Updating ${env_file} file..."
    cat > "${env_file}" << EOF
# Database connection details
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
DB_NAME=${DB_NAME}

# PostgREST configuration
PGRST_DB_URI=postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}
PGRST_DB_SCHEMA=api
PGRST_DB_ANON_ROLE=web_anon
PGRST_SERVER_PORT=3000
EOF
    
    echo "${env_file} file updated."
}

# Main function
main() {
    # Check if doctl is installed
    check_doctl
    
    # Create project
    create_project "${PROJECT_NAME}"
    
    # Create database
    create_database "${DB_NAME}" "${DB_ENGINE}" "${DB_VERSION}" "${DB_SIZE}" "${DB_REGION}"
    
    # Create droplet
    create_droplet "${DROPLET_NAME}" "${DROPLET_SIZE}" "${DROPLET_IMAGE}" "${DROPLET_REGION}"
    
    # Assign resources to project
    assign_to_project "${PROJECT_ID}" "${DB_ID}" "${DROPLET_ID}"
    
    # Update .env file
    update_env_file "${DB_ID}" "${ENV_FILE}"
    
    echo "Setup completed successfully."
    echo "Project: ${PROJECT_NAME}"
    echo "Database: ${DB_NAME}"
    echo "Droplet: ${DROPLET_NAME}"
    echo "Environment file: ${ENV_FILE}"
}

# Run main function
main 