#!/bin/bash

# This script updates all shell scripts to use environment variables from .env file
# instead of hardcoded database credentials

echo "Updating shell scripts to use environment variables from .env file..."

# List of shell scripts to update
SCRIPTS=(
    "check_db.sh"
    "debug_import.sh"
    "import_direct.sh"
    "import_examples.sh"
    "import_simple.sh"
    "setup_db.sh"
    "setup_postgrest_api.sh"
)

# Environment variable block to add at the beginning of each script
ENV_BLOCK='# Load environment variables from .env file
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
fi'

# Update each script
for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "Updating $script..."
        
        # Create a temporary file
        TMP_FILE=$(mktemp)
        
        # Add shebang line if it exists in the original file
        if grep -q "^#!/bin/bash" "$script"; then
            echo "#!/bin/bash" > "$TMP_FILE"
            echo "" >> "$TMP_FILE"
        fi
        
        # Add environment variable block
        echo "$ENV_BLOCK" >> "$TMP_FILE"
        echo "" >> "$TMP_FILE"
        
        # Add the rest of the file, skipping the hardcoded database credentials
        sed -n '/^# Directory/,$p' "$script" | grep -v "^DB_HOST=" | grep -v "^DB_PORT=" | grep -v "^DB_USER=" | grep -v "^DB_PASS=" | grep -v "^DB_NAME=" >> "$TMP_FILE"
        
        # Replace the original file
        mv "$TMP_FILE" "$script"
        
        # Make the script executable
        chmod +x "$script"
        
        echo "  Done."
    else
        echo "Warning: $script not found, skipping."
    fi
done

echo "All scripts updated successfully."
echo "Please make sure to create a .env file based on .env.example with your database credentials." 