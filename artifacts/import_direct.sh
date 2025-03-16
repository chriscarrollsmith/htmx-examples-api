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

# Create a function to extract values from JSON
extract_value() {
    local file=$1
    local key=$2
    local value=$(cat "$file" | grep -o "\"$key\":\"[^\"]*\"" | sed "s/\"$key\":\"//g" | sed "s/\"//g")
    echo "$value"
}

extract_array() {
    local file=$1
    local key=$2
    local array=$(cat "$file" | grep -o "\"$key\":\[[^\]]*\]" | sed "s/\"$key\"://g")
    echo "$array"
}

# Import each example file
COUNT=0
for file in "$EXAMPLES_DIR"/*.json; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        example_id="${filename%.json}"
        
        echo "Importing $example_id..."
        
        # Extract values from JSON
        id=$(jq -r '.id' "$file")
        title=$(jq -r '.title' "$file")
        category=$(jq -r '.category' "$file")
        url=$(jq -r '.url' "$file")
        description=$(jq -r '.description' "$file")
        html_snippets=$(jq -c '.html_snippets' "$file")
        javascript_snippets=$(jq -c '.javascript_snippets' "$file")
        key_concepts=$(jq -c '.key_concepts | join("","")' "$file" | sed 's/\"/\\\"/g')
        htmx_attributes=$(jq -c '.htmx_attributes | join("","")' "$file" | sed 's/\"/\\\"/g')
        demo_explanation=$(jq -r '.demo_explanation' "$file")
        complexity_level=$(jq -r '.complexity_level' "$file")
        use_cases=$(jq -c '.use_cases | join("","")' "$file" | sed 's/\"/\\\"/g')
        
        # Create a SQL file for this import
        cat > "import_${example_id}.sql" << EOF
-- Insert example: $example_id
INSERT INTO htmx_examples (
    id,
    title,
    category,
    url,
    description,
    html_snippets,
    javascript_snippets,
    key_concepts,
    htmx_attributes,
    demo_explanation,
    complexity_level,
    use_cases
) VALUES (
    '$id',
    '$title',
    '$category',
    '$url',
    '$description',
    '$html_snippets',
    '$javascript_snippets',
    ARRAY[$(echo "$key_concepts" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')],
    ARRAY[$(echo "$htmx_attributes" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')],
    '$demo_explanation',
    '$complexity_level',
    ARRAY[$(echo "$use_cases" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')]
)
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    category = EXCLUDED.category,
    url = EXCLUDED.url,
    description = EXCLUDED.description,
    html_snippets = EXCLUDED.html_snippets,
    javascript_snippets = EXCLUDED.javascript_snippets,
    key_concepts = EXCLUDED.key_concepts,
    htmx_attributes = EXCLUDED.htmx_attributes,
    demo_explanation = EXCLUDED.demo_explanation,
    complexity_level = EXCLUDED.complexity_level,
    use_cases = EXCLUDED.use_cases,
    updated_at = CURRENT_TIMESTAMP;
EOF
        
        # Execute the import
        PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "import_${example_id}.sql" > /dev/null 2>&1
        
        # Check if import was successful
        if [ $? -eq 0 ]; then
            COUNT=$((COUNT + 1))
            echo "  Imported successfully."
            # Remove the SQL file
            rm "import_${example_id}.sql"
        else
            echo "  Error importing $example_id."
            echo "  See import_${example_id}.sql for details."
        fi
    fi
done

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
