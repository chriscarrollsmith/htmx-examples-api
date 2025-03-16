#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v "^#" .env | xargs)
else
    echo "Error: .env file not found. Please create one based on .env.example"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ]; then
    echo "Error: Missing required environment variables in .env file."
    echo "Please make sure DB_HOST, DB_PORT, DB_USER, DB_PASS, and DB_NAME are set."
    exit 1
fi

# Directory containing processed examples
EXAMPLES_DIR="processed_examples"

# Check if the directory exists
if [ ! -d "$EXAMPLES_DIR" ]; then
    echo "Error: Directory $EXAMPLES_DIR does not exist."
    exit 1
fi

# Count the number of example files
NUM_FILES=$(find "$EXAMPLES_DIR" -name "*.json" | wc -l)
echo "Found $NUM_FILES example files to import."

# Import each example file
COUNT=0
for file in "$EXAMPLES_DIR"/*.json; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        example_id="${filename%.json}"
        
        echo "Importing $example_id..."
        
        # Create a temporary SQL file for this import
        cat > temp_import.sql << EOF
SELECT import_htmx_example('$(cat "$file" | sed "s/'/''/g")');
EOF
        
        # Execute the import
        PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f temp_import.sql > /dev/null 2>&1
        
        # Check if import was successful
        if [ $? -eq 0 ]; then
            COUNT=$((COUNT + 1))
            echo "  Imported successfully."
        else
            echo "  Error importing $example_id."
        fi
    fi
done

# Remove temporary file
rm -f temp_import.sql

echo "Import completed. $COUNT out of $NUM_FILES examples imported successfully."

# Verify the import by counting records in the database
echo "Verifying import..."
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) FROM htmx_examples;" -t > count.txt
DB_COUNT=$(cat count.txt | tr -d ' ')

echo "Database contains $DB_COUNT examples."

# List the imported examples
echo "Listing imported examples..."
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT id, title, category, complexity_level FROM htmx_examples ORDER BY category, id;" > imported_examples.txt

echo "Import process completed. See imported_examples.txt for a list of imported examples." 
