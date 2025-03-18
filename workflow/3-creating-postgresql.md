# Creating a PostgreSQL Database on DigitalOcean

This document outlines the steps to create the necessary DigitalOcean infrastructure for hosting HTMX examples, including:
1. Creating an HTMX-Examples project
2. Setting up a managed PostgreSQL database
3. Creating a droplet for PostgREST deployment
4. Setting up database users and permissions
5. Storing connection details securely

> **Note:** An end-to-end automation script (`workflow/setup_postgres_db.sh`) has been created to perform all the steps in this document automatically. However, this script has not been fully tested or validated yet. For now, we recommend following the step-by-step manual process outlined below.

## Prerequisites
- DigitalOcean account
- `doctl` CLI tool installed and authenticated
- `psql` client installed

## 1. Verify Authentication

First, verify that `doctl` is installed and authenticated:

```bash
# Check doctl version
doctl version

# Verify authentication
doctl account get
```

If you're not authenticated, run:

```bash
doctl auth init
```

## 2. Create a Project

Create a new project to organize your resources:

```bash
# List existing projects
doctl projects list

# Create a new project
doctl projects create --name "HTMX-Examples" --purpose "Hosting HTMX examples with PostgreSQL and PostgREST" --environment "Production"
```

Take note of the Project ID in the output for later use.

## 3. Set Up a Managed PostgreSQL Database

Explore the available database options:

```bash
# Check available database engines
doctl databases options engines

# Check available PostgreSQL versions
doctl databases options versions pg

# Check available regions
doctl databases options regions pg

# Check available instance sizes
doctl databases options slugs --engine pg
```

Create a PostgreSQL database with the latest version:

```bash
doctl databases create htmx-examples-db --engine pg --version 17 --region nyc3 --size db-s-1vcpu-1gb --num-nodes 1 --wait
```

Retrieve the database connection details:

```bash
# Get the database ID from the output of the create command
DATABASE_ID="your-database-id"

# Get connection details
doctl databases connection $DATABASE_ID --format Host,Port,User,Password,Database
```

Store these details securely in a `.env` file:

```bash
# Database connection parameters
DB_HOST=your-host
DB_PORT=your-port
DB_USER=your-user
DB_PASS=your-password
DB_NAME=your-database

# Database connection URI
DB_URI="postgres://your-user:your-password@your-host:your-port/your-database?sslmode=require"

# Digital Ocean database ID
DO_DATABASE_ID=your-database-id
```

## 4. Create a Droplet for PostgREST

**Important:** Before creating your droplet, verify that you have valid Digital Ocean compute SSH key access:

```bash
# List SSH keys in your Digital Ocean account
doctl compute ssh-key list

# Ensure at least one key from the list has a matching private key on your local machine
# If no matching keys exist, generate and import a new one:
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
doctl compute ssh-key import "droplet-access-key" --public-key-file ~/.ssh/id_rsa.pub

# Verify fingerprints match between your local key and the one in Digital Ocean
ssh-keygen -l -f ~/.ssh/id_rsa  # Compare this output with the fingerprint from doctl ssh-key list
```

Check available droplet sizes:

```bash
doctl compute size list
```

Create a droplet for the PostgREST deployment:

```bash
doctl compute droplet create htmx-postgrest --region nyc3 --size s-1vcpu-1gb --image ubuntu-22-04-x64 --ssh-keys $(doctl compute ssh-key list --format ID --no-header) --wait
```

Assign the droplet to your project:

```bash
# Get the droplet ID from the output of the create command
DROPLET_ID="your-droplet-id"
PROJECT_ID="your-project-id"

doctl projects resources assign $PROJECT_ID --resource="do:droplet:$DROPLET_ID"
```

Add the droplet details to your `.env` file:

```bash
# PostgREST droplet details
DROPLET_ID=your-droplet-id
DROPLET_NAME=htmx-postgrest
DROPLET_IP=your-droplet-ip

# PostgREST configuration
POSTGREST_USER=web_anon
POSTGREST_PASSWORD=your-secure-password
POSTGREST_JWT_SECRET=your-jwt-secret
```

## 5. Set Up Database Users and Permissions

After creating the database and droplet, you need to set up the necessary database users and permissions for PostgREST:

```bash
# Create a temporary SQL file that sets the postgrest.password variable
echo "SET postgrest.password = '$POSTGREST_PASSWORD';" > /tmp/setup_db_users_temp.sql
echo "\i workflow/setup_db_users.sql" >> /tmp/setup_db_users_temp.sql

# Run the script
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f /tmp/setup_db_users_temp.sql
```

This script will:
1. Create the `api` schema if it doesn't exist
2. Create or update the `web_anon` role with login capabilities and the specified password
3. Grant the necessary permissions to the `web_anon` role
4. Create a simple view in the `api` schema for testing
5. Grant permissions on existing tables and views if they exist

You can verify that the `web_anon` role has been set up correctly:

```bash
# Check if the web_anon role exists and has login privileges
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT rolname, rolcanlogin FROM pg_roles WHERE rolname = 'web_anon';"

# Test connecting as the web_anon role
PGPASSWORD=$POSTGREST_PASSWORD psql -h $DB_HOST -p $DB_PORT -U web_anon -d $DB_NAME -c "SELECT * FROM api.test_view;"
```

## 6. Verify Setup

Verify that your database is running:

```bash
doctl databases list
```

Verify that your droplet is running:

```bash
doctl compute droplet list
```

## Next Steps

After completing the steps in this document, you'll have:
1. Created a DigitalOcean project for organizing your resources
2. Set up a managed PostgreSQL database
3. Created a droplet for PostgREST deployment
4. Set up database users and permissions
5. Stored connection details securely in a `.env` file

The next steps in the workflow are:
1. Initialize the database schema
2. Upload the structured JSON data
3. Configure and deploy PostgREST

These steps will be covered in the subsequent documents, starting with [Uploading Data to PostgreSQL](4-uploading-to-postgres.md).

## Appendix: End-to-End Automation Script

An end-to-end automation script (`workflow/setup_postgres_db.sh`) has been created to perform all the steps in this document automatically. The script includes functions for:

- Checking if `doctl` is installed and authenticated
- Creating a project
- Creating a PostgreSQL database
- Creating a droplet
- Assigning resources to a project
- Updating the `.env` file with configuration details
- Setting up database users and permissions

To use the script:

```bash
# Make the script executable
chmod +x workflow/setup_postgres_db.sh

# Run the script
./workflow/setup_postgres_db.sh
```
> **Important:** This script has not been fully tested or validated yet. Use it at your own risk or follow the step-by-step manual process outlined in this document.
