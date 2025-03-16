#!/bin/bash

# This script checks the API capabilities of your Digital Ocean managed database
# You need to have doctl installed and authenticated

# Set your database ID
# You can find this with: doctl databases list
DATABASE_ID="your-database-id"

# List database users
echo "Listing database users:"
doctl databases user list $DATABASE_ID

# List database connection details
echo -e "\nDatabase connection details:"
doctl databases connection $DATABASE_ID

# List database configuration
echo -e "\nDatabase configuration:"
doctl databases config $DATABASE_ID

# Check if there's a way to execute custom SQL
echo -e "\nChecking if there's a way to execute custom SQL:"
doctl databases --help | grep -i sql

echo -e "\nNote: Digital Ocean's managed database API is limited and doesn't provide direct SQL execution capabilities."
echo "You'll need to deploy PostgREST separately to create a RESTful API for your database." 