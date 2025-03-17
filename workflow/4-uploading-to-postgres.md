# Uploading Data to PostgreSQL

This document outlines the steps to initialize the database schema and upload HTMX examples to the PostgreSQL database.

## Prerequisites
- DigitalOcean PostgreSQL database set up (see [Creating a PostgreSQL Database on DigitalOcean](3-creating-postgresql.md))
- Database users and permissions configured (the `web_anon` role should be created and granted appropriate permissions)
- `.env` file with database connection details
- `psql` client installed
- Python 3.6+ installed
- `uv` Python package manager installed

> **Note:** If you followed the steps in [Creating a PostgreSQL Database on DigitalOcean](3-creating-postgresql.md), including Section 5 "Set Up Database Users and Permissions", the database users and permissions should already be set up. The `api` schema should also have been created. This is a prerequisite for the steps in this document.

## 1. Install Required Python Packages

Install the required Python packages using `uv`:

```bash
# Install required packages
uv add psycopg python-dotenv
```

## 2. Initialize the Database Schema

The database schema needs to be initialized before uploading data. The schema includes tables for HTMX examples and embeddings, as well as functions for similarity search.

> **Note:** The `api` schema should already exist from the previous step. The `init_db_schema.sql` script will create tables, views, and functions within this schema.

```bash
# Initialize the database schema using the init_db_schema.sql script
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f workflow/init_db_schema.sql 2>&1 | cat
```

This script will:
1. Enable the vector extension for embeddings
2. Create tables for HTMX examples and embeddings
3. Create indexes for faster searches
4. Set up triggers for automatic timestamp updates
5. Create views and API schema for PostgREST

The schema creates two main tables:
- `htmx_examples`: Stores the HTMX examples with TEXT arrays for key_concepts, htmx_attributes, and use_cases
- `htmx_embeddings`: Stores embeddings for each example with separate embeddings for title, description, content, and key concepts

You can verify that the schema was initialized correctly:

```bash
# Check if the htmx_examples table was created
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'htmx_examples');" | cat

# Check if the htmx_embeddings table was created
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'htmx_embeddings');" | cat

# Check if the api.examples view was created
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT EXISTS (SELECT FROM information_schema.views WHERE table_schema = 'api' AND table_name = 'examples');" | cat
```

## 3. Upload HTMX Examples

The `upload_to_postgres.py` script uploads HTMX examples from JSON files to the PostgreSQL database.

```bash
# Upload HTMX examples using the upload_to_postgres.py script
uv run workflow/upload_to_postgres.py --examples-dir processed_examples --env-file .env --verbose
```

The script accepts the following arguments:
- `--examples-dir`: Directory containing processed examples (default: `processed_examples`)
- `--env-file`: Environment file path (default: `.env`)
- `--verbose` or `-v`: Enable verbose output

The script will:
1. Load environment variables from the `.env` file
2. Connect to the PostgreSQL database
3. Get a list of existing examples in the database
4. Import each example from the JSON files
5. Verify the import with summary statistics

## 4. Verify the Upload

Verify that the examples were uploaded correctly:

```bash
# Count the number of examples
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM htmx_examples;" | cat

# List examples by category
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT category, COUNT(*) FROM htmx_examples GROUP BY category ORDER BY category;" | cat
```

> **Note:** We use the `-t` (tuples only) flag and pipe to `cat` to avoid pager issues with `psql` commands.

## 5. Troubleshooting

### Connection Issues
- Verify that the database is running: `doctl databases list`
- Check the connection details in the `.env` file
- Ensure that the database allows connections from your IP address

### Schema Initialization Issues
- Check the PostgreSQL version: `PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT version();" | cat`
- Ensure that the vector extension is available: `PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';" | cat`

### Upload Issues
- Check that the JSON files are properly formatted
- Ensure that the required fields are present in the JSON files
- Verify that the database schema matches the JSON structure
- If you encounter Python dependency issues, make sure to use `uv add` to install the required packages

### Data Type Issues
- The schema uses TEXT arrays for `key_concepts`, `htmx_attributes`, and `use_cases`
- Make sure your JSON files have these fields as arrays of strings
- The script will handle converting JSONB fields to the appropriate format

## Next Steps

After uploading the data, you'll need to:
1. Generate embeddings for the examples
2. Configure and deploy PostgREST

These steps will be covered in the subsequent documents.
