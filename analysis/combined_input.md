# Workflow Summary

# HTMX Examples Scraping and Embedding Workflow

This document provides a concise summary of the workflow used to scrape HTMX examples, extract structured data, load it to PostgreSQL, embed the data using OpenAI, and create a PostgREST API endpoint with vector similarity search.

## Workflow Steps

### 1. Scraping HTMX Examples
- **Key Files**: 
  - `scrape.md` - Instructions for scraping
  - `download_examples.sh` - Script to download examples
- **Commands**:
  ```bash
  chmod +x download_examples.sh
  ./download_examples.sh
  ```
- **Output**: HTML files in `examples/` directory

### 2. Extracting Structured Data
- **Key Files**:
  - `extract_schema.md` - Instructions for extraction
  - `htmx_examples_schema.json` - JSON schema for examples
  - `process_htmx_examples.sh` - Script to process examples
- **Commands**:
  ```bash
  chmod +x process_htmx_examples.sh
  ./process_htmx_examples.sh --direct
  ```
- **Output**: JSON files in `processed_examples/` directory

### 3. Setting Up PostgreSQL Database
- **Key Files**:
  - `setup_db.sh` - Script to set up database
  - `setup_db.sql` - SQL for database setup
- **Commands**:
  ```bash
  chmod +x setup_db.sh
  ./setup_db.sh
  ```
- **Output**: PostgreSQL database with tables for HTMX examples

### 4. Importing Examples to Database
- **Key Files**:
  - `import_all_examples.py` - Script to import examples
- **Commands**:
  ```bash
  uv add psycopg3 python-dotenv
  uv run import_all_examples.py
  ```
- **Output**: Data loaded into PostgreSQL tables

### 5. Generating Embeddings
- **Key Files**:
  - `generate_embeddings.py` - Script to generate embeddings
- **Commands**:
  ```bash
  uv add openai psycopg3 python-dotenv
  uv run generate_embeddings.py
  ```
- **Output**: Vector embeddings stored in PostgreSQL

### 6. Setting Up PostgREST API
- **Key Files**:
  - `setup_postgrest_api.sh` - Script to set up API
  - `setup_postgrest.sql` - SQL for API setup
  - `postgrest.conf` - Configuration for PostgREST
  - `docker-compose.yml` - Docker configuration
- **Commands**:
  ```bash
  chmod +x setup_postgrest_api.sh
  ./setup_postgrest_api.sh
  docker compose up -d
  ```
- **Output**: Running PostgREST API with vector similarity search

### 7. Environment Variable Management
- **Key Files**:
  - `.env.example` - Template for environment variables
  - `.env` - Actual environment variables
  - `generate_config.py` - Script to generate configuration
- **Commands**:
  ```bash
  cp .env.example .env
  # Edit .env with actual values
  python generate_config.py
  ```
- **Output**: Configured environment with protected secrets

## Complete Workflow Execution

To reproduce this workflow:

1. Clone the repository
2. Run `./download_examples.sh` to scrape HTMX examples
3. Run `./process_htmx_examples.sh --direct` to extract structured data
4. Run `./setup_db.sh` to set up the PostgreSQL database
5. Run `uv run import_all_examples.py` to import examples to the database
6. Run `uv run generate_embeddings.py` to generate and store embeddings
7. Configure `.env` file with your credentials
8. Run `./setup_postgrest_api.sh` to set up the PostgREST API
9. Run `docker compose up -d` to start the API server

The API will be available at http://localhost:3000 with vector similarity search capabilities. 

# Repository Contents

This file is a merged representation of the entire codebase, combined into a single document by Repomix.

================================================================
File Summary
================================================================

Purpose:
--------
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

File Format:
------------
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Multiple file entries, each consisting of:
  a. A separator line (================)
  b. The file path (File: path/to/file)
  c. Another separator line
  d. The full contents of the file
  e. A blank line

Usage Guidelines:
-----------------
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

Notes:
------
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded

Additional Info:
----------------

================================================================
Directory Structure
================================================================
summaries/
  env_secrets_summary.md
  final_workflow_summary.md
  htmx_examples_summary.md
  README.md
  workflow_summary.md
.env.example
.gitignore
.python-version
check_db.sh
check_vector.sql
debug_import.sh
direct_insert.sql
docker-compose.yml
download_examples.sh
extract_schema.md
generate_config.py
generate_embeddings.py
generate_postgrest_conf.sh
htmx_examples_multi_schema.json
htmx_examples_schema.json
htmx_extraction_prompt.txt
htmx_multi_schema.json
htmx_schema.json
import_all_examples.py
import_all.sql
import_direct.sh
import_examples.sh
import_examples.sql
import_simple.sh
POSTGREST_README.md
postgrest.conf.example
process_htmx_examples.sh
pyproject.toml
README.md
requirements.txt
scrape.md
setup_db.sh
setup_db.sql
setup_postgrest_api.sh
setup_postgrest.sql
summarize_workflow.sh
update_scripts_to_use_env.sh
update_workflow_summary.sh
uv.lock

================================================================
Files
================================================================

================
File: summaries/env_secrets_summary.md
================
## HTMX Examples Workflow Summary

This document summarizes the steps taken to scrape, process, embed, and serve HTMX examples via a PostgREST API with vector similarity search.

### 1. Scraping and Extracting Data

*   **Files:**
    *   `scraper.py`: Scrapes HTMX examples from the website.
    *   `extract_structured_data.py`: Extracts structured information. Raw html files are needed as input. 
*   **Commands:**
    *  `python scraper.py`

### 2. Data Processing and Loading to PostgreSQL

*   **Files:**
    *   `import_all_examples.py`: Processes examples and loads them into PostgreSQL. It will traverse all of the `/processed_examples/` directory to find files to import.
    * `setup_db.sh`: Sets up the database and tables
*   **Commands:**
    *  `./setup_db.sh`
    *  `python import_all_examples.py`

### 3. Generating Embeddings and Storing in PostgreSQL

*   **Files:**
    *   `generate_embeddings.py`: Generates embeddings using OpenAI and stores them in PostgreSQL. Depends on openai api key.
*   **Commands:**

    *   `python generate_embeddings.py`

### 4. Setting up PostgREST API

*   **Files:**
    *   `postgrest.conf`: Configuration file to define connections to PostgreSQL and HTTP settings.
    *   `setup_postgrest_api.sh`: Creates schema, roles, and functions for the PostgREST API.
    *   `docker-compose.yml`: YAML file for dockerized Postgres, PostgREST api, and a simple web UI interface.
    * `generate_postgrest_conf.sh`: Generates actual `postgrest.conf` from `.env` variables and template.
*   **Commands:**
    *   `./generate_postgrest_conf.sh`
    *   `./setup_postgrest_api.sh`
    *   `docker compose up -d`

### 5. Setting up Environment Variables

*   **Files:**

    *   `.env`: Stores sensitive information like API keys and database credentials.

    *   `.env.example`: Template for creating `.env` file (without exposing credentials).

*   **Workflow:**

    *   Copy `.env.example` file.

    *   Configure `.env` with appropriate database details and API keys.

    *   Execute `./generate_postgrest_conf.sh .` to dynamically generate the `postgrest.conf` file with environment variables setup by docker compose.

### Overall Workflow

1.  Scrape HTMX examples.
2.  Extract structured data for scraping example output.
3.  Set up Postgres DB and import extracted examples.
4.  Generate embeddings using OpenAI and store them in Postgres.
5.  Update configuration files (.env, docker-compose.yml, postgrest.conf).
6.  Update database scripts.
7.  Setup `.env` file and run setup scripts
8.  Start the PostgREST API.

================
File: summaries/final_workflow_summary.md
================
# HTMX Examples Scraping and Embedding Workflow

This document provides a concise summary of the workflow used to scrape HTMX examples, extract structured data, load it to PostgreSQL, embed the data using OpenAI, and create a PostgREST API endpoint with vector similarity search.

## Workflow Steps

### 1. Scraping HTMX Examples
- **Key Files**: 
  - `scrape.md` - Instructions for scraping
  - `download_examples.sh` - Script to download examples
- **Commands**:
  ```bash
  chmod +x download_examples.sh
  ./download_examples.sh
  ```
- **Output**: HTML files in `examples/` directory

### 2. Extracting Structured Data
- **Key Files**:
  - `extract_schema.md` - Instructions for extraction
  - `htmx_examples_schema.json` - JSON schema for examples
  - `process_htmx_examples.sh` - Script to process examples
- **Commands**:
  ```bash
  chmod +x process_htmx_examples.sh
  ./process_htmx_examples.sh --direct
  ```
- **Output**: JSON files in `processed_examples/` directory

### 3. Setting Up PostgreSQL Database
- **Key Files**:
  - `setup_db.sh` - Script to set up database
  - `setup_db.sql` - SQL for database setup
- **Commands**:
  ```bash
  chmod +x setup_db.sh
  ./setup_db.sh
  ```
- **Output**: PostgreSQL database with tables for HTMX examples

### 4. Importing Examples to Database
- **Key Files**:
  - `import_all_examples.py` - Script to import examples
- **Commands**:
  ```bash
  uv add psycopg3 python-dotenv
  uv run import_all_examples.py
  ```
- **Output**: Data loaded into PostgreSQL tables

### 5. Generating Embeddings
- **Key Files**:
  - `generate_embeddings.py` - Script to generate embeddings
- **Commands**:
  ```bash
  uv add openai psycopg3 python-dotenv
  uv run generate_embeddings.py
  ```
- **Output**: Vector embeddings stored in PostgreSQL

### 6. Setting Up PostgREST API
- **Key Files**:
  - `setup_postgrest_api.sh` - Script to set up API
  - `setup_postgrest.sql` - SQL for API setup
  - `postgrest.conf` - Configuration for PostgREST
  - `docker-compose.yml` - Docker configuration
- **Commands**:
  ```bash
  chmod +x setup_postgrest_api.sh
  ./setup_postgrest_api.sh
  docker compose up -d
  ```
- **Output**: Running PostgREST API with vector similarity search

### 7. Environment Variable Management
- **Key Files**:
  - `.env.example` - Template for environment variables
  - `.env` - Actual environment variables
  - `generate_config.py` - Script to generate configuration
- **Commands**:
  ```bash
  cp .env.example .env
  # Edit .env with actual values
  python generate_config.py
  ```
- **Output**: Configured environment with protected secrets

## Complete Workflow Execution

To reproduce this workflow:

1. Clone the repository
2. Run `./download_examples.sh` to scrape HTMX examples
3. Run `./process_htmx_examples.sh --direct` to extract structured data
4. Run `./setup_db.sh` to set up the PostgreSQL database
5. Run `uv run import_all_examples.py` to import examples to the database
6. Run `uv run generate_embeddings.py` to generate and store embeddings
7. Configure `.env` file with your credentials
8. Run `./setup_postgrest_api.sh` to set up the PostgREST API
9. Run `docker compose up -d` to start the API server

The API will be available at http://localhost:3000 with vector similarity search capabilities.

================
File: summaries/htmx_examples_summary.md
================
## HTMX Example Workflow Summary

This document summarizes the steps to scrape, process, embed, and expose HTMX examples via a PostgREST API with vector similarity search.

### 1. Scraping and Data Extraction

- **Goal**: Download HTML examples and convert them into structured JSON.
- **Key File**: `download_examples.sh`
- **Commands**:
  ```bash
  mkdir -p examples
  wget -q -O examples/example.html https://htmx.org/examples/example/ # Example
  ```
  ```bash
  chmod +x download_examples.sh
  ./download_examples.sh
  ```
- **Key File:** `htmx_extraction_prompt.txt` (System prompt).
- **Key File:** `process_htmx_examples.sh`  (Main processing script).
- **Key File:** `htmx_schema.json`  (Single example JSON Schema).
- **Key File:** `htmx_multi_schema.json`  (Multiple example JSON Schema).
- **Command:**
   ```bash
   ./process_htmx_examples.sh --direct  # Processes w/ direct String schema.
   ```
- Goal: Store results in JSON files (with appropriate content extracted).
- **Final result**: JSON files in `processed_examples/`.

### 2. PostgreSQL Database Setup and Import

- **Goal**: Create PostgreSQL schema and load JSON data.
- **Key File**: `setup_db.sh` (Creates tables, indexes, etc.)

  ```bash
  CREATE EXTENSION IF NOT EXISTS vector; # Inside script
  ```
- **Command**:
  ```bash
  chmod +x setup_db.sh
  ./setup_db.sh
  ```
- **Key File:** `import_all_examples.py` (imports from JSON).
  ```bash
  uv add psycopg3 python-dotenv
  uv run import_all_examples.py
  ````

### 3. Embedding Generation
- **Goal**: Create vectors for the important text data. Store these alongside the original data.
- **Key File**: `generate_embeddings.py`
- **Goal:** add the openai and vector deps. Use explicit "uv" commands for installing python dep.
  ```bash
  uv add openai psycopg3 python-dotenv
  uv run generate_embeddings.py   # Make sure python deps are correctly added before run
  ```


### 4. PostgREST API Setup with Vector Similarity

- **Goal**: Create a PostgREST API to expose the database.
- **Key Files**:
  - `setup_postgrest.sql` (Creates roles, functions, views).
  ```sql
  CREATE ROLE web_anon NOLOGIN; # anon access user in API
  CREATE SCHEMA IF NOT EXISTS api; # api schema
  CREATE FUNCTION api.search_htmx_examples()...; # simalarity search function
  CREATE VIEW api.htmx_examples AS SELECT ...;  # view for the HTMX examples table
  ```
  - `postgrest.conf` (Configures PostgREST).
  ```properties
  db-uri = "postgres://postgrest:postgrest_password@db..." # Connection URL
  db-schema = "api" # schema
  db-anon-role = "web_anon" # role for anon access
  jwt-secret = "some-secret-key" #  JWT secret (dummy)
  ```
  - `docker-compose.yml` (Runs PostgREST and web UI).
  ```yml
  version: '3'
  services:
    postgrest: # service definition
    environment: # the PostgREST DB configuration params
       ...
  ```
  - `search_ui.html` (Simple HTMX driven front-end for access)
- **Commands**:
   ```bash
  PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f setup_postgrest.sql
   chmod +x setup_postgrest_api.sh   # Needed?
   ./setup_postgrest_api.sh   # run the setup
  docker compose up -d # start docker-compose environment
  # Also some restarts along the way:
  docker restart scrape-embed-postgrest-1  # helpful too at various points, try it before restarting compose env.
   ```
---

================
File: summaries/README.md
================
# Workflow Summaries

This directory contains summaries of the workflow used to create the HTMX Examples Vector Database project.

## Files

- `final_workflow_summary.md` - The main, concise summary of the entire workflow
- `workflow_summary.md` - A more detailed summary combining all individual summaries
- `*_summary.md` - Individual summaries of specific conversation logs

## Updating Summaries

To update the summaries based on the latest conversation logs, run:

```bash
./update_workflow_summary.sh
```

This script will:
1. Process all conversation logs in `.specstory/history/`
2. Generate individual summaries for each log
3. Combine them into a comprehensive summary
4. Create a final, concise summary

## Using the Summaries

The `final_workflow_summary.md` file provides a step-by-step guide to reproduce the entire workflow, from scraping HTMX examples to setting up the PostgREST API with vector similarity search. It includes:

- Key files used at each step
- Commands to execute
- Expected outputs
- Complete workflow execution steps

This documentation is designed to make it easy to understand and reproduce the workflow in the future.

================
File: summaries/workflow_summary.md
================
# HTMX Examples Scraping and Embedding Workflow Summary

This document provides a concise summary of the workflow used to scrape HTMX examples, 
extract structured data, load it to PostgreSQL, embed the data using OpenAI, 
and create a PostgREST API endpoint with vector similarity search.

## Workflow Overview

## HTMX Example Workflow Summary

This document summarizes the steps to scrape, process, embed, and expose HTMX examples via a PostgREST API with vector similarity search.

### 1. Scraping and Data Extraction

- **Goal**: Download HTML examples and convert them into structured JSON.
- **Key File**: `download_examples.sh`
- **Commands**:
  ```bash
  mkdir -p examples
  wget -q -O examples/example.html https://htmx.org/examples/example/ # Example
  ```
  ```bash
  chmod +x download_examples.sh
  ./download_examples.sh
  ```
- **Key File:** `htmx_extraction_prompt.txt` (System prompt).
- **Key File:** `process_htmx_examples.sh`  (Main processing script).
- **Key File:** `htmx_schema.json`  (Single example JSON Schema).
- **Key File:** `htmx_multi_schema.json`  (Multiple example JSON Schema).
- **Command:**
   ```bash
   ./process_htmx_examples.sh --direct  # Processes w/ direct String schema.
   ```
- Goal: Store results in JSON files (with appropriate content extracted).
- **Final result**: JSON files in `processed_examples/`.

### 2. PostgreSQL Database Setup and Import

- **Goal**: Create PostgreSQL schema and load JSON data.
- **Key File**: `setup_db.sh` (Creates tables, indexes, etc.)

  ```bash
  CREATE EXTENSION IF NOT EXISTS vector; # Inside script
  ```
- **Command**:
  ```bash
  chmod +x setup_db.sh
  ./setup_db.sh
  ```
- **Key File:** `import_all_examples.py` (imports from JSON).
  ```bash
  uv add psycopg3 python-dotenv
  uv run import_all_examples.py
  ````

### 3. Embedding Generation
- **Goal**: Create vectors for the important text data. Store these alongside the original data.
- **Key File**: `generate_embeddings.py`
- **Goal:** add the openai and vector deps. Use explicit "uv" commands for installing python dep.
  ```bash
  uv add openai psycopg3 python-dotenv
  uv run generate_embeddings.py   # Make sure python deps are correctly added before run
  ```


### 4. PostgREST API Setup with Vector Similarity

- **Goal**: Create a PostgREST API to expose the database.
- **Key Files**:
  - `setup_postgrest.sql` (Creates roles, functions, views).
  ```sql
  CREATE ROLE web_anon NOLOGIN; # anon access user in API
  CREATE SCHEMA IF NOT EXISTS api; # api schema
  CREATE FUNCTION api.search_htmx_examples()...; # simalarity search function
  CREATE VIEW api.htmx_examples AS SELECT ...;  # view for the HTMX examples table
  ```
  - `postgrest.conf` (Configures PostgREST).
  ```properties
  db-uri = "postgres://postgrest:postgrest_password@db..." # Connection URL
  db-schema = "api" # schema
  db-anon-role = "web_anon" # role for anon access
  jwt-secret = "some-secret-key" #  JWT secret (dummy)
  ```
  - `docker-compose.yml` (Runs PostgREST and web UI).
  ```yml
  version: '3'
  services:
    postgrest: # service definition
    environment: # the PostgREST DB configuration params
       ...
  ```
  - `search_ui.html` (Simple HTMX driven front-end for access)
- **Commands**:
   ```bash
  PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f setup_postgrest.sql
   chmod +x setup_postgrest_api.sh   # Needed?
   ./setup_postgrest_api.sh   # run the setup
  docker compose up -d # start docker-compose environment
  # Also some restarts along the way:
  docker restart scrape-embed-postgrest-1  # helpful too at various points, try it before restarting compose env.
   ```
---




## HTMX Examples Workflow Summary

This document summarizes the steps taken to scrape, process, embed, and serve HTMX examples via a PostgREST API with vector similarity search.

### 1. Scraping and Extracting Data

*   **Files:**
    *   `scraper.py`: Scrapes HTMX examples from the website.
    *   `extract_structured_data.py`: Extracts structured information. Raw html files are needed as input. 
*   **Commands:**
    *  `python scraper.py`

### 2. Data Processing and Loading to PostgreSQL

*   **Files:**
    *   `import_all_examples.py`: Processes examples and loads them into PostgreSQL. It will traverse all of the `/processed_examples/` directory to find files to import.
    * `setup_db.sh`: Sets up the database and tables
*   **Commands:**
    *  `./setup_db.sh`
    *  `python import_all_examples.py`

### 3. Generating Embeddings and Storing in PostgreSQL

*   **Files:**
    *   `generate_embeddings.py`: Generates embeddings using OpenAI and stores them in PostgreSQL. Depends on openai api key.
*   **Commands:**

    *   `python generate_embeddings.py`

### 4. Setting up PostgREST API

*   **Files:**
    *   `postgrest.conf`: Configuration file to define connections to PostgreSQL and HTTP settings.
    *   `setup_postgrest_api.sh`: Creates schema, roles, and functions for the PostgREST API.
    *   `docker-compose.yml`: YAML file for dockerized Postgres, PostgREST api, and a simple web UI interface.
    * `generate_postgrest_conf.sh`: Generates actual `postgrest.conf` from `.env` variables and template.
*   **Commands:**
    *   `./generate_postgrest_conf.sh`
    *   `./setup_postgrest_api.sh`
    *   `docker compose up -d`

### 5. Setting up Environment Variables

*   **Files:**

    *   `.env`: Stores sensitive information like API keys and database credentials.

    *   `.env.example`: Template for creating `.env` file (without exposing credentials).

*   **Workflow:**

    *   Copy `.env.example` file.

    *   Configure `.env` with appropriate database details and API keys.

    *   Execute `./generate_postgrest_conf.sh .` to dynamically generate the `postgrest.conf` file with environment variables setup by docker compose.

### Overall Workflow

1.  Scrape HTMX examples.
2.  Extract structured data for scraping example output.
3.  Set up Postgres DB and import extracted examples.
4.  Generate embeddings using OpenAI and store them in Postgres.
5.  Update configuration files (.env, docker-compose.yml, postgrest.conf).
6.  Update database scripts.
7.  Setup `.env` file and run setup scripts
8.  Start the PostgREST API.

================
File: .env.example
================
# Database connection parameters
DB_HOST=your_db_host_here
DB_PORT=your_db_port_here
DB_USER=your_db_user_here
DB_PASS=your_db_password_here
DB_NAME=your_db_name_here

# PostgREST configuration
POSTGREST_USER=your_postgrest_user_here
POSTGREST_PASSWORD=your_postgrest_password_here
POSTGREST_JWT_SECRET=your_jwt_secret_here 

# Add any additional configuration variables here 
# Database connection
DB_URI="postgres://username:password@hostname:port/database"

# JWT secret
JWT_SECRET="your-jwt-secret-here"

# OpenAI API key
OPENAI_API_KEY="your-openai-api-key-here"

================
File: .gitignore
================
# Environment variables
.env
.env.*
!.env.example

# PostgreSQL configuration with secrets
postgrest.conf
!postgrest.conf.example

# Node modules
node_modules/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# OS specific
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Virtual environments
.venv
.specstory
repomix-output.txt
examples/
processed_examples/
*.crt

================
File: .python-version
================
3.13

================
File: check_db.sh
================
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

================
File: check_vector.sql
================
SELECT * FROM pg_available_extensions WHERE name = 'vector';

================
File: debug_import.sh
================
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

================
File: direct_insert.sql
================
-- Insert directly without using the function
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
    'click-to-edit',
    'Click to Edit',
    'UI Patterns',
    'https://htmx.org/examples/click-to-edit/',
    'The click to edit pattern provides a way to offer inline editing of all or part of a record without a page refresh.',
    '[{"code":"<div hx-target=\"this\" hx-swap=\"outerHTML\">\n    <div><label>First Name</label>: Joe</div>\n    <div><label>Last Name</label>: Blow</div>\n    <div><label>Email</label>: joe@blow.com</div>\n    <button hx-get=\"/contact/1/edit\" class=\"btn primary\">\n    Click To Edit\n    </button>\n</div>","description":"This snippet displays the contact details (first name, last name, and email) and includes a button that, when clicked, will fetch the editing UI for the contact."},{"code":"<form hx-put=\"/contact/1\" hx-target=\"this\" hx-swap=\"outerHTML\">\n  <div>\n    <label>First Name</label>\n    <input type=\"text\" name=\"firstName\" value=\"Joe\">\n  </div>\n  <div class=\"form-group\">\n    <label>Last Name</label>\n    <input type=\"text\" name=\"lastName\" value=\"Blow\">\n  </div>\n  <div class=\"form-group\">\n    <label>Email Address</label>\n    <input type=\"email\" name=\"email\" value=\"joe@blow.com\">\n  </div>\n  <button class=\"btn\">Submit</button>\n  <button class=\"btn\" hx-get=\"/contact/1\">Cancel</button>\n</form>","description":"This snippet represents the editing form that appears when the ''Click To Edit'' button is pressed. It allows users to update contact information and submit via a PUT request."}]',
    '[]',
    ARRAY['AJAX requests', 'Dynamic content loading', 'Inline editing', 'Form submission without page refresh'],
    ARRAY['hx-get', 'hx-put', 'hx-target', 'hx-swap'],
    'The demo allows users to click on a button to edit contact information directly on the page without needing to refresh. It uses HTMX attributes to fetch the edit form and update the content dynamically.',
    'beginner',
    ARRAY['Inline editing of user profiles', 'Dynamic form generation', 'Content management systems', 'Real-time data updates without page refreshes']
);

================
File: docker-compose.yml
================
version: '3'

services:
  postgrest:
    image: postgrest/postgrest:latest
    ports:
      - "3000:3000"
    environment:
      PGHOST: ${DB_HOST}
      PGPORT: ${DB_PORT}
      PGDATABASE: ${DB_NAME}
      PGUSER: ${POSTGREST_USER}
      PGPASSWORD: ${POSTGREST_PASSWORD}
      PGRST_DB_SCHEMA: api
      PGRST_DB_ANON_ROLE: web_anon
      PGRST_JWT_SECRET: ${POSTGREST_JWT_SECRET}
      PGRST_MAX_ROWS: 100
      PGRST_DB_EXTRA_SEARCH_PATH: public,openai
    restart: unless-stopped
    env_file:
      - .env

  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./search_ui.html:/usr/share/nginx/html/index.html
    restart: unless-stopped
    depends_on:
      - postgrest

================
File: download_examples.sh
================
#!/bin/bash

# Create examples directory if it doesn't exist
mkdir -p examples

# Download all examples
echo "Downloading HTMX examples..."

# UI Patterns
wget -q -O examples/click-to-edit.html https://htmx.org/examples/click-to-edit/
wget -q -O examples/bulk-update.html https://htmx.org/examples/bulk-update/
wget -q -O examples/click-to-load.html https://htmx.org/examples/click-to-load/
wget -q -O examples/delete-row.html https://htmx.org/examples/delete-row/
wget -q -O examples/edit-row.html https://htmx.org/examples/edit-row/
wget -q -O examples/lazy-load.html https://htmx.org/examples/lazy-load/
wget -q -O examples/inline-validation.html https://htmx.org/examples/inline-validation/
wget -q -O examples/infinite-scroll.html https://htmx.org/examples/infinite-scroll/
wget -q -O examples/active-search.html https://htmx.org/examples/active-search/
wget -q -O examples/progress-bar.html https://htmx.org/examples/progress-bar/
wget -q -O examples/value-select.html https://htmx.org/examples/value-select/
wget -q -O examples/animations.html https://htmx.org/examples/animations/
wget -q -O examples/file-upload.html https://htmx.org/examples/file-upload/
wget -q -O examples/file-upload-input.html https://htmx.org/examples/file-upload-input/
wget -q -O examples/reset-user-input.html https://htmx.org/examples/reset-user-input/

# Dialog Examples
wget -q -O examples/dialogs.html https://htmx.org/examples/dialogs/
wget -q -O examples/modal-uikit.html https://htmx.org/examples/modal-uikit/
wget -q -O examples/modal-bootstrap.html https://htmx.org/examples/modal-bootstrap/
wget -q -O examples/modal-custom.html https://htmx.org/examples/modal-custom/

# Advanced Examples
wget -q -O examples/tabs-hateoas.html https://htmx.org/examples/tabs-hateoas/
wget -q -O examples/tabs-javascript.html https://htmx.org/examples/tabs-javascript/
wget -q -O examples/keyboard-shortcuts.html https://htmx.org/examples/keyboard-shortcuts/
wget -q -O examples/sortable.html https://htmx.org/examples/sortable/
wget -q -O examples/update-other-content.html https://htmx.org/examples/update-other-content/
wget -q -O examples/confirm.html https://htmx.org/examples/confirm/
wget -q -O examples/async-auth.html https://htmx.org/examples/async-auth/
wget -q -O examples/web-components.html https://htmx.org/examples/web-components/
wget -q -O examples/move-before.html https://htmx.org/examples/move-before/

echo "All examples downloaded successfully to the 'examples' directory."

================
File: extract_schema.md
================
Take a look at a couple of the example files. I am interested in embedding the examples in a vector database in the way that would make them most useful for an LLM agent with a semantic search tool. Suggest a JSON schema to use in a data cleaning pipeline for transforming the examples into clean, embeddable text with useful, filterable metadata. Save the schema as a JSON file named `htmx_examples_schema.json`.

================
File: generate_config.py
================
#!/usr/bin/env python3
"""
Generate postgrest.conf from environment variables.
This script reads values from .env and creates a postgrest.conf file.
"""

import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get environment variables
db_uri = os.getenv('DB_URI')
jwt_secret = os.getenv('JWT_SECRET')
openai_api_key = os.getenv('OPENAI_API_KEY')

# Create postgrest.conf content
config_content = f"""# PostgreSQL connection string
db-uri = "{db_uri}"

# The database schema to expose to REST clients
db-schema = "api"

# The database role to use when executing commands
db-anon-role = "web_anon"

# The secret used to sign JWT tokens
jwt-secret = "{jwt_secret}"

# The maximum number of rows to return from a request
max-rows = 100

# Server settings
server-port = 3000
server-host = "0.0.0.0"

# Set OpenAI API key as a custom setting
db-extra-search-path = "public, openai"
db-pre-request = "SET app.openai_api_key = '{openai_api_key}'"
"""

# Write to postgrest.conf
with open('postgrest.conf', 'w') as f:
    f.write(config_content)

print("postgrest.conf has been generated successfully.")

================
File: generate_embeddings.py
================
#!/usr/bin/env python3
"""
Generate embeddings for HTMX examples and store them in PostgreSQL.
"""

import os
import json
import psycopg
import openai
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database connection parameters from environment variables
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_NAME = os.getenv("DB_NAME")

# Check if all required environment variables are set
required_env_vars = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASS", "DB_NAME", "OPENAI_API_KEY"]
missing_vars = [var for var in required_env_vars if not os.getenv(var)]
if missing_vars:
    raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")

# OpenAI API key
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# Initialize OpenAI client
client = openai.OpenAI(api_key=OPENAI_API_KEY)

def connect_to_db():
    """Connect to the PostgreSQL database."""
    try:
        conn_string = f"host={DB_HOST} port={DB_PORT} dbname={DB_NAME} user={DB_USER} password={DB_PASS}"
        conn = psycopg.connect(conn_string)
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        raise

def get_examples(conn):
    """Get all examples from the database."""
    with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
        cur.execute("SELECT * FROM htmx_examples")
        return cur.fetchall()

def generate_embedding(text):
    """Generate an embedding for the given text using OpenAI's API."""
    try:
        response = client.embeddings.create(
            model="text-embedding-3-small",
            input=text,
            dimensions=1536
        )
        return response.data[0].embedding
    except Exception as e:
        print(f"Error generating embedding: {e}")
        raise

def prepare_text_for_embedding(example):
    """Prepare text from an example for embedding."""
    # Title embedding
    title_text = example["title"]
    
    # Description embedding
    description_text = example["description"]
    
    # Content embedding (combine HTML snippets, key concepts, and demo explanation)
    # Check if html_snippets is already a list/dict or needs to be parsed from JSON string
    html_snippets = example["html_snippets"]
    if isinstance(html_snippets, str):
        html_snippets = json.loads(html_snippets)
    
    # Handle HTML snippets safely
    html_code_parts = []
    html_description_parts = []
    
    for snippet in html_snippets:
        if isinstance(snippet, dict):
            if "code" in snippet:
                html_code_parts.append(snippet["code"])
            if "description" in snippet or "explanation" in snippet:
                desc = snippet.get("description", snippet.get("explanation", ""))
                html_description_parts.append(desc)
    
    html_code = "\n".join(html_code_parts)
    html_descriptions = "\n".join(html_description_parts)
    
    # Handle JavaScript snippets safely
    js_snippets = example["javascript_snippets"]
    if isinstance(js_snippets, str):
        js_snippets = json.loads(js_snippets)
    
    js_code_parts = []
    js_description_parts = []
    
    for snippet in js_snippets:
        if isinstance(snippet, dict):
            if "code" in snippet:
                js_code_parts.append(snippet["code"])
            if "description" in snippet or "explanation" in snippet:
                desc = snippet.get("description", snippet.get("explanation", ""))
                js_description_parts.append(desc)
    
    js_code = "\n".join(js_code_parts)
    js_descriptions = "\n".join(js_description_parts)
    
    # Combine all text elements
    key_concepts = ", ".join(example["key_concepts"]) if example["key_concepts"] else ""
    htmx_attributes = ", ".join(example["htmx_attributes"]) if example["htmx_attributes"] else ""
    demo_explanation = example["demo_explanation"] if example["demo_explanation"] else ""
    
    content_text = f"""
    HTML Code:
    {html_code}
    
    HTML Descriptions:
    {html_descriptions}
    
    JavaScript Code:
    {js_code}
    
    JavaScript Descriptions:
    {js_descriptions}
    
    Key Concepts:
    {key_concepts}
    
    HTMX Attributes:
    {htmx_attributes}
    
    Demo Explanation:
    {demo_explanation}
    """
    
    # Key concepts embedding
    key_concepts_text = key_concepts
    
    return {
        "title": title_text,
        "description": description_text,
        "content": content_text,
        "key_concepts": key_concepts_text
    }

def store_embeddings(conn, example_id, embeddings):
    """Store embeddings in the database."""
    with conn.cursor() as cur:
        # Check if embeddings already exist for this example
        cur.execute("SELECT id FROM htmx_embeddings WHERE id = %s", (example_id,))
        exists = cur.fetchone()
        
        if exists:
            # Update existing embeddings
            cur.execute("""
                UPDATE htmx_embeddings
                SET 
                    title_embedding = %s,
                    description_embedding = %s,
                    content_embedding = %s,
                    key_concepts_embedding = %s,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
            """, (
                embeddings["title"],
                embeddings["description"],
                embeddings["content"],
                embeddings["key_concepts"],
                example_id
            ))
        else:
            # Insert new embeddings
            cur.execute("""
                INSERT INTO htmx_embeddings (
                    id,
                    title_embedding,
                    description_embedding,
                    content_embedding,
                    key_concepts_embedding
                ) VALUES (%s, %s, %s, %s, %s)
            """, (
                example_id,
                embeddings["title"],
                embeddings["description"],
                embeddings["content"],
                embeddings["key_concepts"]
            ))
        
        conn.commit()

def main():
    """Main function to generate and store embeddings."""
    print("Connecting to database...")
    conn = connect_to_db()
    
    print("Getting examples from database...")
    examples = get_examples(conn)
    print(f"Found {len(examples)} examples.")
    
    for i, example in enumerate(examples):
        example_id = example["id"]
        print(f"Processing example {i+1}/{len(examples)}: {example_id}")
        
        try:
            # Prepare text for embedding
            texts = prepare_text_for_embedding(example)
            
            # Generate embeddings
            print(f"  Generating embeddings...")
            embeddings = {
                "title": generate_embedding(texts["title"]),
                "description": generate_embedding(texts["description"]),
                "content": generate_embedding(texts["content"]),
                "key_concepts": generate_embedding(texts["key_concepts"])
            }
            
            # Store embeddings
            print(f"  Storing embeddings...")
            store_embeddings(conn, example_id, embeddings)
            
            print(f"  Done with {example_id}")
        except Exception as e:
            print(f"  Error processing example {example_id}: {e}")
            continue
    
    print("All embeddings generated and stored successfully.")
    conn.close()

if __name__ == "__main__":
    main()

================
File: generate_postgrest_conf.sh
================
#!/bin/bash

# This script generates a postgrest.conf file from the template and environment variables

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v "^#" .env | xargs)
else
    echo "Error: .env file not found. Please create one based on .env.example"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ] || \
   [ -z "$POSTGREST_USER" ] || [ -z "$POSTGREST_PASSWORD" ] || [ -z "$POSTGREST_JWT_SECRET" ] || [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: Missing required environment variables in .env file."
    echo "Please make sure all required variables are set."
    exit 1
fi

# Create the postgrest.conf file
cat > postgrest.conf << EOF
# PostgreSQL connection string
db-uri = "postgres://${POSTGREST_USER}:${POSTGREST_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# The database schema to expose to REST clients
db-schema = "api"

# The database role to use when executing commands
db-anon-role = "web_anon"

# The secret used to sign JWT tokens
jwt-secret = "${POSTGREST_JWT_SECRET}"

# The maximum number of rows to return from a request
max-rows = 100

# Server settings
server-port = 3000
server-host = "0.0.0.0"

# Set OpenAI API key as a custom setting
db-extra-search-path = "public, openai"
db-pre-request = "SET app.openai_api_key = '${OPENAI_API_KEY}'"
EOF

echo "Generated postgrest.conf file with environment variables."

================
File: htmx_examples_multi_schema.json
================
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "HTMX Examples Multi Schema",
  "description": "Schema for extracting multiple HTMX examples at once",
  "type": "object",
  "properties": {
    "items": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {
            "type": "string",
            "description": "Unique identifier for the example (e.g., 'click-to-edit', 'active-search')"
          },
          "title": {
            "type": "string",
            "description": "Title of the example as shown on the page"
          },
          "category": {
            "type": "string",
            "description": "Category of the example (e.g., 'UI Patterns', 'Dialog Examples', 'Advanced Examples')"
          },
          "url": {
            "type": "string",
            "description": "Original URL of the example"
          },
          "description": {
            "type": "string",
            "description": "Short description of what the example demonstrates"
          },
          "html_snippets": {
            "type": "array",
            "description": "Array of HTML code snippets shown in the example",
            "items": {
              "type": "object",
              "properties": {
                "code": {
                  "type": "string",
                  "description": "The HTML code snippet"
                },
                "description": {
                  "type": "string",
                  "description": "Description or explanation of the code snippet"
                }
              },
              "required": ["code"]
            }
          },
          "javascript_snippets": {
            "type": "array",
            "description": "Array of JavaScript code snippets shown in the example",
            "items": {
              "type": "object",
              "properties": {
                "code": {
                  "type": "string",
                  "description": "The JavaScript code snippet"
                },
                "description": {
                  "type": "string",
                  "description": "Description or explanation of the code snippet"
                }
              },
              "required": ["code"]
            }
          },
          "key_concepts": {
            "type": "array",
            "description": "Key HTMX concepts demonstrated in this example",
            "items": {
              "type": "string"
            }
          },
          "htmx_attributes": {
            "type": "array",
            "description": "HTMX attributes used in this example (e.g., 'hx-get', 'hx-trigger', 'hx-swap')",
            "items": {
              "type": "string"
            }
          },
          "full_content": {
            "type": "string",
            "description": "The full textual content of the example page with HTML tags removed"
          },
          "demo_explanation": {
            "type": "string",
            "description": "Explanation of how the demo works, extracted from the page"
          },
          "complexity_level": {
            "type": "string",
            "enum": ["beginner", "intermediate", "advanced"],
            "description": "Subjective assessment of the example's complexity"
          }
        },
        "required": ["id", "title", "category", "url", "description", "html_snippets", "key_concepts", "htmx_attributes"]
      }
    }
  },
  "required": ["items"]
}

================
File: htmx_examples_schema.json
================
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "HTMX Example Schema",
  "description": "Schema for storing HTMX examples in a vector database for semantic search",
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "description": "Unique identifier for the example (e.g., 'click-to-edit', 'active-search')"
    },
    "title": {
      "type": "string",
      "description": "Title of the example as shown on the page"
    },
    "category": {
      "type": "string",
      "description": "Category of the example (e.g., 'UI Patterns', 'Dialog Examples', 'Advanced Examples')"
    },
    "url": {
      "type": "string",
      "description": "Original URL of the example"
    },
    "description": {
      "type": "string",
      "description": "Short description of what the example demonstrates"
    },
    "html_snippets": {
      "type": "array",
      "description": "Array of HTML code snippets shown in the example",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string",
            "description": "The HTML code snippet"
          },
          "description": {
            "type": "string",
            "description": "Description or explanation of the code snippet"
          }
        },
        "required": ["code"]
      }
    },
    "javascript_snippets": {
      "type": "array",
      "description": "Array of JavaScript code snippets shown in the example",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string",
            "description": "The JavaScript code snippet"
          },
          "description": {
            "type": "string",
            "description": "Description or explanation of the code snippet"
          }
        },
        "required": ["code"]
      }
    },
    "key_concepts": {
      "type": "array",
      "description": "Key HTMX concepts demonstrated in this example",
      "items": {
        "type": "string"
      }
    },
    "htmx_attributes": {
      "type": "array",
      "description": "HTMX attributes used in this example (e.g., 'hx-get', 'hx-trigger', 'hx-swap')",
      "items": {
        "type": "string"
      }
    },
    "full_content": {
      "type": "string",
      "description": "The full textual content of the example page with HTML tags removed"
    },
    "demo_explanation": {
      "type": "string",
      "description": "Explanation of how the demo works, extracted from the page"
    },
    "complexity_level": {
      "type": "string",
      "enum": ["beginner", "intermediate", "advanced"],
      "description": "Subjective assessment of the example's complexity"
    },
    "related_examples": {
      "type": "array",
      "description": "IDs of related examples",
      "items": {
        "type": "string"
      }
    },
    "use_cases": {
      "type": "array",
      "description": "Common use cases where this pattern would be useful",
      "items": {
        "type": "string"
      }
    }
  },
  "required": ["id", "title", "category", "url", "description", "html_snippets", "key_concepts", "htmx_attributes", "full_content"]
}

================
File: htmx_extraction_prompt.txt
================
You are an expert in HTMX, a JavaScript library that allows you to access AJAX, CSS Transitions, WebSockets and Server Sent Events directly in HTML, using attributes.

Analyze the provided HTMX example and extract structured information according to the schema. Focus on:

1. Identifying the key concepts demonstrated in the example
2. Extracting all HTML and JavaScript code snippets along with explanations of what they do
3. Identifying all HTMX attributes used and their purpose
4. Determining the complexity level based on the concepts used
5. Suggesting practical use cases for this pattern

For HTML and JavaScript snippets, make sure to extract both the code and a clear explanation of what the code does. For the complexity level, use your judgment to classify as beginner, intermediate, or advanced based on the concepts involved.

The ID should be derived from the filename or title (lowercase, hyphenated). The URL should be constructed as "https://htmx.org/examples/[id]/".

Be thorough in your analysis, as this information will be used for semantic search in a vector database to help developers find relevant HTMX patterns.

================
File: htmx_multi_schema.json
================
{
  "type": "object",
  "properties": {
    "items": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {
            "type": "string",
            "description": "unique identifier for the example (e.g., 'click-to-edit', 'active-search')"
          },
          "title": {
            "type": "string",
            "description": "title of the example as shown on the page"
          },
          "category": {
            "type": "string",
            "description": "category of the example (e.g., 'UI Patterns', 'Dialog Examples', 'Advanced Examples')"
          },
          "url": {
            "type": "string",
            "description": "original URL of the example"
          },
          "description": {
            "type": "string",
            "description": "short description of what the example demonstrates"
          },
          "html_snippets": {
            "type": "array",
            "description": "array of HTML code snippets with their descriptions",
            "items": {
              "type": "object",
              "properties": {
                "code": {
                  "type": "string",
                  "description": "the HTML snippet"
                },
                "description": {
                  "type": "string",
                  "description": "explanation of what the snippet does"
                }
              },
              "required": ["code"]
            }
          },
          "javascript_snippets": {
            "type": "array",
            "description": "array of JavaScript code snippets with their descriptions",
            "items": {
              "type": "object",
              "properties": {
                "code": {
                  "type": "string",
                  "description": "the JavaScript snippet"
                },
                "description": {
                  "type": "string",
                  "description": "explanation of what the snippet does"
                }
              },
              "required": ["code"]
            }
          },
          "key_concepts": {
            "type": "array",
            "description": "array of key HTMX concepts demonstrated in this example (e.g., 'AJAX requests', 'DOM swapping')",
            "items": {
              "type": "string"
            }
          },
          "htmx_attributes": {
            "type": "array",
            "description": "array of HTMX attributes used in this example (e.g., 'hx-get', 'hx-trigger', 'hx-swap')",
            "items": {
              "type": "string"
            }
          },
          "demo_explanation": {
            "type": "string",
            "description": "explanation of how the demo works, extracted from the page"
          },
          "complexity_level": {
            "type": "string",
            "enum": ["beginner", "intermediate", "advanced"],
            "description": "subjective assessment of the example's complexity"
          },
          "use_cases": {
            "type": "array",
            "description": "array of common scenarios where this pattern would be useful",
            "items": {
              "type": "string"
            }
          }
        },
        "required": ["id", "title", "category", "url", "description", "html_snippets", "key_concepts", "htmx_attributes"]
      }
    }
  },
  "required": ["items"]
}

================
File: htmx_schema.json
================
{
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "description": "unique identifier for the example (e.g., 'click-to-edit', 'active-search')"
    },
    "title": {
      "type": "string",
      "description": "title of the example as shown on the page"
    },
    "category": {
      "type": "string",
      "description": "category of the example (e.g., 'UI Patterns', 'Dialog Examples', 'Advanced Examples')"
    },
    "url": {
      "type": "string",
      "description": "original URL of the example"
    },
    "description": {
      "type": "string",
      "description": "short description of what the example demonstrates"
    },
    "html_snippets": {
      "type": "array",
      "description": "array of HTML code snippets with their descriptions",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string",
            "description": "the HTML snippet"
          },
          "description": {
            "type": "string",
            "description": "explanation of what the snippet does"
          }
        },
        "required": ["code"]
      }
    },
    "javascript_snippets": {
      "type": "array",
      "description": "array of JavaScript code snippets with their descriptions",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string",
            "description": "the JavaScript snippet"
          },
          "description": {
            "type": "string",
            "description": "explanation of what the snippet does"
          }
        },
        "required": ["code"]
      }
    },
    "key_concepts": {
      "type": "array",
      "description": "array of key HTMX concepts demonstrated in this example (e.g., 'AJAX requests', 'DOM swapping')",
      "items": {
        "type": "string"
      }
    },
    "htmx_attributes": {
      "type": "array",
      "description": "array of HTMX attributes used in this example (e.g., 'hx-get', 'hx-trigger', 'hx-swap')",
      "items": {
        "type": "string"
      }
    },
    "demo_explanation": {
      "type": "string",
      "description": "explanation of how the demo works, extracted from the page"
    },
    "complexity_level": {
      "type": "string",
      "enum": ["beginner", "intermediate", "advanced"],
      "description": "subjective assessment of the example's complexity"
    },
    "use_cases": {
      "type": "array",
      "description": "array of common scenarios where this pattern would be useful",
      "items": {
        "type": "string"
      }
    }
  },
  "required": ["id", "title", "category", "url", "description", "html_snippets", "key_concepts", "htmx_attributes"]
}

================
File: import_all_examples.py
================
#!/usr/bin/env python3
"""
Import all HTMX examples from the processed_examples directory into PostgreSQL.
"""

import os
import json
import psycopg
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database connection parameters from environment variables
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_NAME = os.getenv("DB_NAME")

# Check if all required environment variables are set
required_env_vars = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASS", "DB_NAME"]
missing_vars = [var for var in required_env_vars if not os.getenv(var)]
if missing_vars:
    raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")

# Directory containing processed examples
EXAMPLES_DIR = "processed_examples"

def connect_to_db():
    """Connect to the PostgreSQL database."""
    try:
        conn_string = f"host={DB_HOST} port={DB_PORT} dbname={DB_NAME} user={DB_USER} password={DB_PASS}"
        conn = psycopg.connect(conn_string)
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        raise

def get_existing_examples(conn):
    """Get a list of example IDs already in the database."""
    with conn.cursor() as cur:
        cur.execute("SELECT id FROM htmx_examples")
        return [row[0] for row in cur.fetchall()]

def import_example(conn, file_path):
    """Import a single example from a JSON file."""
    try:
        with open(file_path, 'r') as f:
            example = json.load(f)
        
        # Check if the example has all required fields
        required_fields = ['id', 'title', 'category', 'url', 'description', 
                          'html_snippets', 'javascript_snippets', 'key_concepts', 
                          'htmx_attributes', 'demo_explanation', 'complexity_level', 'use_cases']
        
        for field in required_fields:
            if field not in example:
                print(f"  Warning: Missing required field '{field}'")
                if field in ['html_snippets', 'javascript_snippets']:
                    example[field] = []
                elif field in ['key_concepts', 'htmx_attributes', 'use_cases']:
                    example[field] = []
                else:
                    example[field] = ""
        
        # Ensure html_snippets and javascript_snippets are properly formatted as JSON strings
        if isinstance(example['html_snippets'], list):
            html_snippets_json = json.dumps(example['html_snippets'])
        else:
            html_snippets_json = example['html_snippets']
            
        if isinstance(example['javascript_snippets'], list):
            js_snippets_json = json.dumps(example['javascript_snippets'])
        else:
            js_snippets_json = example['javascript_snippets']
        
        # Insert the example into the database
        with conn.cursor() as cur:
            cur.execute("""
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
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
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
                    updated_at = CURRENT_TIMESTAMP
            """, (
                example['id'],
                example['title'],
                example['category'],
                example['url'],
                example['description'],
                html_snippets_json,
                js_snippets_json,
                example['key_concepts'],
                example['htmx_attributes'],
                example['demo_explanation'],
                example['complexity_level'],
                example['use_cases']
            ))
            
        conn.commit()
        return True
    except Exception as e:
        print(f"  Error importing example: {e}")
        conn.rollback()
        return False

def main():
    """Main function to import all examples."""
    print("Connecting to database...")
    conn = connect_to_db()
    
    print("Getting existing examples...")
    existing_examples = get_existing_examples(conn)
    print(f"Found {len(existing_examples)} existing examples in the database.")
    
    # Get all JSON files in the examples directory
    example_files = [f for f in os.listdir(EXAMPLES_DIR) if f.endswith('.json')]
    print(f"Found {len(example_files)} example files to import.")
    
    # Import each example
    success_count = 0
    for file_name in example_files:
        example_id = file_name.replace('.json', '')
        file_path = os.path.join(EXAMPLES_DIR, file_name)
        
        print(f"Importing {example_id}...")
        if example_id in existing_examples:
            print(f"  Example {example_id} already exists, updating...")
        
        if import_example(conn, file_path):
            success_count += 1
            print(f"  Imported successfully.")
        else:
            print(f"  Failed to import {example_id}.")
    
    print(f"Import completed. {success_count} out of {len(example_files)} examples imported successfully.")
    
    # Verify the import
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM htmx_examples")
        count = cur.fetchone()[0]
        print(f"Database now contains {count} examples.")
        
        # List all examples
        print("Listing all examples:")
        cur.execute("SELECT id, title, category, complexity_level FROM htmx_examples ORDER BY category, id")
        examples = cur.fetchall()
        for example in examples:
            print(f"  {example[0]}: {example[1]} ({example[2]}, {example[3]})")
    
    conn.close()

if __name__ == "__main__":
    main()

================
File: import_all.sql
================
-- Import click-to-edit example
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
    'active-search',
    'Active Search',
    'Search',
    'https://htmx.org/examples/active-search/',
    'This example actively searches a contacts database as the user enters text.',
    '[{"code":"<h3>\n  Search Contacts\n  <span class=\"htmx-indicator\">\n    <img src=\"/img/bars.svg\"/> Searching...\n   </span>\n</h3>\n<input class=\"form-control\" type=\"search\"\n       name=\"search\" placeholder=\"Begin Typing To Search Users...\"\n       hx-post=\"/search\"\n       hx-trigger=\"input changed delay:500ms, keyup[key==''Enter''], load\"\n       hx-target=\"#search-results\"\n       hx-indicator=\".htmx-indicator\">\n\n<table class=\"table\">\n    <thead>\n    <tr>\n      <th>First Name</th>\n      <th>Last Name</th>\n      <th>Email</th>\n    </tr>\n    </thead>\n    <tbody id=\"search-results\">\n    </tbody>\n</table>","description":"This snippet creates the UI for the search functionality, including a header, an input field for searching, and a table to display search results."}]',
    '[]',
    ARRAY['AJAX', 'Dynamic Content Loading', 'Input Handling', 'Event Triggers', 'Debouncing Input'],
    ARRAY['hx-post', 'hx-trigger', 'hx-target', 'hx-indicator'],
    'The active search example listens to user input in a search box, and triggers a POST request to the /search endpoint. Search results are displayed in a table as the user types, providing real-time feedback. The ht indicator shows a loading icon when the search is in progress, enhancing user experience.',
    'intermediate',
    ARRAY['Real-time search suggestions', 'Autocomplete features', 'Dynamic filtering of lists or tables', 'Improving user experience with instant feedback on searches']
);

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
    'infinite-scroll',
    'Infinite Scroll',
    'Scrolling Patterns',
    'https://htmx.org/examples/infinite-scroll/',
    'The infinite scroll pattern provides a way to load content dynamically on user scrolling action.',
    '[{"code":"<tr hx-get=\"/contacts/?page=2\"\nhx-trigger=\"revealed\"\nhx-swap=\"afterend\">\n  <td>Agent Smith</td>\n  <td>void29@null.org</td>\n  <td>55F49448C0</td>\n</tr>","explanation":"This table row element is set up to make an HTMX request to fetch the next page of contacts when it is revealed in the viewport. The new content will be appended right after this element when the request is resolved."}]',
    '[]',
    ARRAY['Dynamic content loading', 'User interaction with scroll events', 'Lazy loading of content'],
    ARRAY['hx-get', 'hx-trigger', 'hx-swap'],
    'The demo implements an infinite scroll functionality where the last element of the loaded content listens for the scroll event. When this element is brought into view, it triggers an HTMX request to fetch more data, appending the results to the DOM seamlessly.',
    'intermediate',
    ARRAY['Loading additional content in a feed (e.g., social media posts)', 'Displaying images in a gallery without pagination', 'Fetching more data in search results triggered by scrolling']
);

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
    'lazy-load',
    'Lazy Loading',
    'UI Patterns',
    'https://htmx.org/examples/lazy-load/',
    'The lazy loading pattern allows you to defer loading content until it is needed.',
    '[{"code":"<div hx-get=\"/graph\" hx-trigger=\"revealed\">
  <img class=\"htmx-indicator\" width=\"150\" src=\"/img/bars.svg\"/>
</div>","explanation":"This div element will trigger a GET request to /graph when it becomes visible in the viewport (revealed). While loading, it displays a loading indicator."}]',
    '[]',
    ARRAY['Lazy Loading', 'Performance Optimization', 'Progressive Enhancement'],
    ARRAY['hx-get', 'hx-trigger'],
    'The demo shows how content can be loaded only when it becomes visible to the user, improving initial page load performance. The revealed trigger fires when the element enters the viewport.',
    'beginner',
    ARRAY['Loading images only when they come into view', 'Deferring loading of below-the-fold content', 'Optimizing page load times for content-heavy pages']
);

================
File: import_direct.sh
================
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

================
File: import_examples.sh
================
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

================
File: import_examples.sql
================
-- Function to import examples from JSON
CREATE OR REPLACE FUNCTION import_htmx_example(example_json JSONB)
RETURNS VOID AS $$
BEGIN
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
        example_json->>'id',
        example_json->>'title',
        example_json->>'category',
        example_json->>'url',
        example_json->>'description',
        example_json->'html_snippets',
        example_json->'javascript_snippets',
        (SELECT array_agg(jsonb_array_elements_text(example_json->'key_concepts'))),
        (SELECT array_agg(jsonb_array_elements_text(example_json->'htmx_attributes'))),
        example_json->>'demo_explanation',
        example_json->>'complexity_level',
        (SELECT array_agg(jsonb_array_elements_text(example_json->'use_cases')))
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
END;
$$ LANGUAGE plpgsql;

================
File: import_simple.sh
================
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

================
File: POSTGREST_README.md
================
# HTMX Examples Search API with PostgREST

This project provides a REST API for searching HTMX examples using vector similarity search. It uses PostgREST to expose the PostgreSQL database as a RESTful API.

## Overview

The system consists of:

1. A PostgreSQL database with HTMX examples and their vector embeddings
2. PostgREST to expose the database as a REST API
3. A simple web interface for searching examples

## Setup Instructions

### 1. Set Up the Database

Run the SQL script to create the necessary database objects:

```bash
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f setup_postgrest.sql
```

This script will:
- Create a role for anonymous access
- Create a function for vector similarity search
- Create views for the API
- Set up permissions

### 2. Run PostgREST with Docker Compose

Start the PostgREST server and web interface:

```bash
docker-compose up -d
```

This will start:
- PostgREST on port 3000
- A web server on port 8080 serving the search interface

### 3. Access the Search Interface

Open your browser and navigate to:

```
http://localhost:8080
```

## API Endpoints

### Search HTMX Examples

```
POST /rpc/search_htmx_examples
```

Parameters:
- `query_text` (required): The search query
- `embedding_type` (optional): Type of embedding to search against (title, description, content, key_concepts)
- `category_filter` (optional): Filter by category
- `complexity_filter` (optional): Filter by complexity level
- `result_limit` (optional): Maximum number of results to return

Example request:

```bash
curl -X POST http://localhost:3000/rpc/search_htmx_examples \
  -H "Content-Type: application/json" \
  -d '{"query_text": "How to implement infinite scrolling", "embedding_type": "content", "result_limit": 3}'
```

### Get All Examples

```
GET /htmx_examples
```

Example request:

```bash
curl http://localhost:3000/htmx_examples
```

### Get Categories

```
GET /htmx_categories
```

Example request:

```bash
curl http://localhost:3000/htmx_categories
```

### Get Complexity Levels

```
GET /htmx_complexity_levels
```

Example request:

```bash
curl http://localhost:3000/htmx_complexity_levels
```

## Implementation Notes

### OpenAI Embeddings

The current implementation includes a placeholder function for generating embeddings in the database. In a production environment, you would need to:

1. Implement a proper HTTP client in the `openai.embed` function to call the OpenAI API
2. Securely store and retrieve the OpenAI API key

### Security Considerations

For a production deployment:

1. Use HTTPS for all API endpoints
2. Store sensitive information like API keys in a secure vault
3. Consider implementing rate limiting
4. Set up proper authentication if needed

## Customization

### Changing the API URL

If you deploy the API to a different URL, update the following in `search_ui.html`:

1. The form's `hx-post` attribute
2. The fetch URL for categories

### Styling

The web interface uses Bootstrap 5 for styling. You can customize the appearance by modifying the CSS in `search_ui.html`.

================
File: postgrest.conf.example
================
# PostgreSQL connection string
db-uri = "postgres://username:password@hostname:port/database"

# The database schema to expose to REST clients
db-schema = "api"

# The database role to use when executing commands
db-anon-role = "web_anon"

# The secret used to sign JWT tokens
jwt-secret = "your-jwt-secret-here"

# The maximum number of rows to return from a request
max-rows = 100

# Server settings
server-port = 3000
server-host = "0.0.0.0"

# Set OpenAI API key as a custom setting
db-extra-search-path = "public, openai"
db-pre-request = "SET app.openai_api_key = 'your-openai-api-key-here'"

================
File: process_htmx_examples.sh
================
#!/bin/bash

# This script processes HTMX examples using the LLM tool
# It extracts structured information according to our schema
# and saves the results to a JSON file

# Create output directory
mkdir -p processed_examples

# Process a single example
process_single_example() {
  local file=$1
  local basename=$(basename "$file" .html)
  echo "Processing $basename..."
  
  # Extract structured information using LLM
  cat "$file" | \
    uvx strip-tags | \
    llm --schema htmx_schema.json \
        --system "$(cat htmx_extraction_prompt.txt)" \
        > "processed_examples/${basename}.json"
  
  echo "Saved to processed_examples/${basename}.json"
}

# Process all examples
process_all_examples() {
  echo "Processing all examples..."
  
  # First, create a template for reuse
  llm --schema htmx_schema.json \
      --system "$(cat htmx_extraction_prompt.txt)" \
      --save htmx-extractor
  
  # Process each example file
  for file in examples/*.html; do
    local basename=$(basename "$file" .html)
    echo "Processing $basename..."
    
    cat "$file" | \
      uvx strip-tags | \
      llm -t htmx-extractor \
      > "processed_examples/${basename}.json"
  done
  
  echo "All examples processed and saved to processed_examples/"
}

# Process examples in batch mode
process_batch_examples() {
  echo "Processing examples in batch mode..."
  
  # Create a multi-schema template
  llm --schema htmx_multi_schema.json \
      --system "$(cat htmx_extraction_prompt.txt)" \
      --save htmx-batch-extractor
  
  # Process examples in batches of 5
  find examples -name "*.html" | \
    xargs -n 5 | \
    while read -r batch; do
      echo "Processing batch: $batch"
      cat $batch | \
        uvx strip-tags | \
        llm -t htmx-batch-extractor \
        > "processed_examples/batch_$(date +%s).json"
    done
  
  echo "Batch processing complete"
}

# Alternative approach using direct schema string
process_with_direct_schema() {
  echo "Processing examples with direct schema..."
  
  # Define the concise schema directly
  local schema='id: unique identifier for the example, title: title of the example as shown on the page, category: category of the example, url: original URL of the example, description: short description of what the example demonstrates, html_snippets: array of objects with code and description, javascript_snippets: array of objects with code and description, key_concepts: array of key HTMX concepts demonstrated, htmx_attributes: array of HTMX attributes used, demo_explanation: explanation of how the demo works, complexity_level: subjective assessment of complexity, use_cases: array of common scenarios where this pattern would be useful'
  
  # Process each example file
  for file in examples/*.html; do
    local basename=$(basename "$file" .html)
    echo "Processing $basename..."
    
    cat "$file" | \
      uvx strip-tags | \
      llm --schema "$schema" \
          --system "$(cat htmx_extraction_prompt.txt)" \
          > "processed_examples/${basename}.json"
  done
  
  echo "All examples processed and saved to processed_examples/"
}

# Create a vector database from processed examples
create_vector_database() {
  echo "Creating vector database from processed examples..."
  
  # This is a placeholder - you would use your vector DB tool here
  # For example, with sqlite-utils and an embedding plugin:
  
  # Combine all JSON files
  jq -s 'add' processed_examples/*.json > all_examples.json
  
  # Create SQLite database with embeddings
  # sqlite-utils insert htmx_examples.db examples all_examples.json --pk=id
  # sqlite-utils enable-fts htmx_examples.db examples description key_concepts
  
  echo "Vector database created"
}

# Display usage information
usage() {
  echo "Usage: $0 [OPTION]"
  echo "Process HTMX examples and extract structured information."
  echo ""
  echo "Options:"
  echo "  -s, --single FILE   Process a single example file"
  echo "  -a, --all           Process all examples"
  echo "  -b, --batch         Process examples in batch mode"
  echo "  -d, --direct        Process examples with direct schema string"
  echo "  -v, --vector        Create vector database from processed examples"
  echo "  -h, --help          Display this help message"
}

# Parse command line arguments
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--single)
      process_single_example "$2"
      shift 2
      ;;
    -a|--all)
      process_all_examples
      shift
      ;;
    -b|--batch)
      process_batch_examples
      shift
      ;;
    -d|--direct)
      process_with_direct_schema
      shift
      ;;
    -v|--vector)
      create_vector_database
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

echo "Processing complete!"

================
File: pyproject.toml
================
[project]
name = "scrape-embed"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.13"
dependencies = [
    "openai>=1.66.3",
    "psycopg>=3.2.6",
    "psycopg2>=2.9.10",
    "python-dotenv>=1.0.1",
]

================
File: README.md
================
# HTMX Examples Vector Database

This project downloads HTMX examples from htmx.org, processes them into structured data, and stores them in a PostgreSQL database with vector embeddings for semantic search.

## Project Structure

- `examples/` - Directory containing the downloaded HTMX examples
- `processed_examples/` - Directory containing the processed JSON files
- `download_examples.sh` - Script to download HTMX examples from htmx.org
- `process_htmx_examples.sh` - Script to process the examples using the LLM tool
- `setup_db.sh` - Script to set up the PostgreSQL database with the vector extension
- `import_simple.sh` - Script to import the processed examples into the database
- `generate_embeddings.py` - Script to generate embeddings for the examples
- `search_examples.py` - Script to perform semantic search on the examples

## Workflow Summary

For a concise summary of the workflow used to create this project, see [summaries/final_workflow_summary.md](summaries/final_workflow_summary.md). This document provides step-by-step instructions for reproducing the entire workflow, from scraping HTMX examples to setting up the PostgREST API with vector similarity search.

## Setup

1. **Download HTMX Examples**:
   ```bash
   ./download_examples.sh
   ```

2. **Process Examples**:
   ```bash
   ./process_htmx_examples.sh --direct
   ```

3. **Set Up Database**:
   ```bash
   ./setup_db.sh
   ```

4. **Configure Environment Variables**:
   Copy the example environment file and update it with your credentials:
   ```bash
   cp .env.example .env
   ```
   
   Edit the `.env` file to add your database credentials and OpenAI API key:
   ```
   # OpenAI API key
   OPENAI_API_KEY=your_openai_api_key_here
   
   # Database connection parameters
   DB_HOST=your_db_host_here
   DB_PORT=your_db_port_here
   DB_USER=your_db_user_here
   DB_PASS=your_db_password_here
   DB_NAME=your_db_name_here
   
   # PostgREST configuration
   POSTGREST_USER=your_postgrest_user_here
   POSTGREST_PASSWORD=your_postgrest_password_here
   POSTGREST_JWT_SECRET=your_jwt_secret_here
   ```

5. **Import Examples**:
   ```bash
   ./import_simple.sh
   ```

6. **Install Python Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

7. **Generate Embeddings**:
   ```bash
   python generate_embeddings.py
   ```

## Usage

### Semantic Search

Search for HTMX examples using semantic search:

```bash
./search_examples.py "How to implement infinite scrolling"
```

Options:
- `--type`: Type of embedding to search against (title, description, content, key_concepts)
- `--limit`: Maximum number of results to return
- `--category`: Filter by category
- `--complexity`: Filter by complexity level
- `--json`: Output results as JSON

Example:
```bash
./search_examples.py "How to implement infinite scrolling" --type content --limit 3 --complexity beginner
```

### PostgREST API

This project includes a PostgREST API for accessing the HTMX examples database via HTTP:

1. **Generate PostgREST Configuration**:
   ```bash
   ./generate_postgrest_conf.sh
   ```

2. **Start the PostgREST API**:
   ```bash
   docker-compose up -d
   ```

3. **Access the API**:
   The API will be available at http://localhost:3000

4. **Access the Web UI**:
   A simple web UI is available at http://localhost:8080

## Database Schema

### htmx_examples

- `id`: Unique identifier for the example
- `title`: Title of the example
- `category`: Category of the example
- `url`: URL of the example
- `description`: Description of the example
- `html_snippets`: HTML code snippets with descriptions
- `javascript_snippets`: JavaScript code snippets with descriptions
- `key_concepts`: Key HTMX concepts demonstrated in the example
- `htmx_attributes`: HTMX attributes used in the example
- `demo_explanation`: Explanation of how the demo works
- `complexity_level`: Complexity level of the example (beginner, intermediate, advanced)
- `use_cases`: Common use cases for the pattern

### htmx_embeddings

- `id`: Unique identifier for the example (foreign key to htmx_examples)
- `title_embedding`: Vector embedding of the title
- `description_embedding`: Vector embedding of the description
- `content_embedding`: Vector embedding of the content
- `key_concepts_embedding`: Vector embedding of the key concepts

## License

This project is for educational purposes only. The HTMX examples are owned by htmx.org.

## Scrape-Embed

## Environment Setup

This project uses environment variables to protect sensitive information. Follow these steps to set up your environment:

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file and add your actual credentials:
   ```
   DB_URI="your-database-connection-string"
   JWT_SECRET="your-jwt-secret"
   OPENAI_API_KEY="your-openai-api-key"
   ```

3. Generate the PostgREST configuration file:
   ```bash
   python generate_config.py
   ```

4. Make sure you have the required Python packages:
   ```bash
   pip install python-dotenv
   ```

## Important Notes

- Never commit the `.env` file or `postgrest.conf` to version control
- The `.gitignore` file is set up to exclude these files
- Always use the example files as templates for new developers

## Running the Application

[Add instructions for running your application here]

================
File: requirements.txt
================
psycopg==3.1.12
openai==1.12.0
python-dotenv==1.0.0

================
File: scrape.md
================
# HTMX Examples Fetching Instructions

You are tasked with fetching and analyzing htmx examples from htmx.org. These examples demonstrate various UI patterns implemented with htmx. Use the `wget` command-line tool to fetch all examples and save them to the `examples` directory:

## Example Fetching Command:

```bash
# To fetch a specific example:
wget -q -O examples/example.html https://htmx.org/examples/EXAMPLE_NAME/
```

## Available Examples:

UI Patterns:
1. Click To Edit: https://htmx.org/examples/click-to-edit/
2. Bulk Update: https://htmx.org/examples/bulk-update/
3. Click To Load: https://htmx.org/examples/click-to-load/
4. Delete Row: https://htmx.org/examples/delete-row/
5. Edit Row: https://htmx.org/examples/edit-row/
6. Lazy Loading: https://htmx.org/examples/lazy-load/
7. Inline Validation: https://htmx.org/examples/inline-validation/
8. Infinite Scroll: https://htmx.org/examples/infinite-scroll/
9. Active Search: https://htmx.org/examples/active-search/
10. Progress Bar: https://htmx.org/examples/progress-bar/
11. Value Select: https://htmx.org/examples/value-select/
12. Animations: https://htmx.org/examples/animations/
13. File Upload: https://htmx.org/examples/file-upload/
14. Preserving File Inputs after Form Errors: https://htmx.org/examples/file-upload-input/
15. Reset User Input: https://htmx.org/examples/reset-user-input/

Dialog Examples:
16. Dialogs - Browser: https://htmx.org/examples/dialogs/
17. Dialogs - UIKit: https://htmx.org/examples/modal-uikit/
18. Dialogs - Bootstrap: https://htmx.org/examples/modal-bootstrap/
19. Dialogs - Custom: https://htmx.org/examples/modal-custom/

Advanced Examples:
20. Tabs (Using HATEOAS): https://htmx.org/examples/tabs-hateoas/
21. Tabs (Using JavaScript): https://htmx.org/examples/tabs-javascript/
22. Keyboard Shortcuts: https://htmx.org/examples/keyboard-shortcuts/
23. Drag & Drop / Sortable: https://htmx.org/examples/sortable/
24. Updating Other Content: https://htmx.org/examples/update-other-content/
25. Confirm: https://htmx.org/examples/confirm/
26. Async Authentication: https://htmx.org/examples/async-auth/
27. Web Components: https://htmx.org/examples/web-components/
28. (Experimental) moveBefore()-powered hx-preserve: https://htmx.org/examples/move-before/

================
File: setup_db.sh
================
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

================
File: setup_db.sql
================
-- Enable the vector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create a table for HTMX examples
CREATE TABLE IF NOT EXISTS htmx_examples (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    url TEXT NOT NULL,
    description TEXT NOT NULL,
    html_snippets JSONB NOT NULL,
    javascript_snippets JSONB NOT NULL,
    key_concepts TEXT[] NOT NULL,
    htmx_attributes TEXT[] NOT NULL,
    demo_explanation TEXT,
    complexity_level TEXT CHECK (complexity_level IN ('beginner', 'intermediate', 'advanced')),
    use_cases TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create a table for embeddings
CREATE TABLE IF NOT EXISTS htmx_embeddings (
    id TEXT PRIMARY KEY REFERENCES htmx_examples(id),
    title_embedding VECTOR(1536),
    description_embedding VECTOR(1536),
    content_embedding VECTOR(1536),
    key_concepts_embedding VECTOR(1536),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster similarity search
CREATE INDEX IF NOT EXISTS htmx_examples_category_idx ON htmx_examples(category);
CREATE INDEX IF NOT EXISTS htmx_examples_complexity_idx ON htmx_examples(complexity_level);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically update the updated_at column
CREATE TRIGGER update_htmx_examples_updated_at
BEFORE UPDATE ON htmx_examples
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_htmx_embeddings_updated_at
BEFORE UPDATE ON htmx_embeddings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create a view that combines examples and embeddings
CREATE OR REPLACE VIEW htmx_examples_with_embeddings AS
SELECT
    e.id,
    e.title,
    e.category,
    e.url,
    e.description,
    e.html_snippets,
    e.javascript_snippets,
    e.key_concepts,
    e.htmx_attributes,
    e.demo_explanation,
    e.complexity_level,
    e.use_cases,
    emb.title_embedding,
    emb.description_embedding,
    emb.content_embedding,
    emb.key_concepts_embedding,
    e.created_at,
    e.updated_at
FROM
    htmx_examples e
LEFT JOIN
    htmx_embeddings emb ON e.id = emb.id;

================
File: setup_postgrest_api.sh
================
#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v "^#" .env | xargs)
else
    echo "Error: .env file not found. Please create one based on .env.example"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ] || \
   [ -z "$POSTGREST_USER" ] || [ -z "$POSTGREST_PASSWORD" ] || [ -z "$POSTGREST_JWT_SECRET" ] || [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: Missing required environment variables in .env file."
    echo "Please make sure all required variables are set."
    exit 1
fi

# Generate the PostgREST configuration file
echo "Generating PostgREST configuration file..."
./generate_postgrest_conf.sh

# Set up the database schema and roles for PostgREST
echo "Setting up database schema and roles for PostgREST..."

# Create the API schema
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
CREATE SCHEMA IF NOT EXISTS api;
"

# Create the web_anon role
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'web_anon') THEN
        CREATE ROLE web_anon NOLOGIN;
    END IF;
END
\$\$;
"

# Create the postgrest role
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'postgrest') THEN
        CREATE ROLE postgrest LOGIN PASSWORD '$POSTGREST_PASSWORD';
    ELSE
        ALTER ROLE postgrest WITH PASSWORD '$POSTGREST_PASSWORD';
    END IF;
END
\$\$;
"

# Grant permissions
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
GRANT USAGE ON SCHEMA api TO web_anon;
GRANT USAGE ON SCHEMA api TO postgrest;
GRANT ALL ON SCHEMA api TO postgrest;
GRANT web_anon TO postgrest;
"

# Create views in the API schema
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
CREATE OR REPLACE VIEW api.examples AS
SELECT 
    e.id,
    e.title,
    e.category,
    e.url,
    e.description,
    e.html_snippets,
    e.javascript_snippets,
    e.key_concepts,
    e.htmx_attributes,
    e.demo_explanation,
    e.complexity_level,
    e.use_cases
FROM 
    htmx_examples e;

GRANT SELECT ON api.examples TO web_anon;
"

# Create search function in the API schema
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
CREATE OR REPLACE FUNCTION api.search_examples(
    query text,
    embedding_type text DEFAULT 'content',
    limit_results int DEFAULT 5,
    category text DEFAULT NULL,
    complexity_level text DEFAULT NULL
) RETURNS SETOF api.examples AS \$\$
DECLARE
    query_embedding vector;
    embedding_column text;
BEGIN
    -- Generate embedding for the query using OpenAI
    SELECT openai.generate_embedding(query) INTO query_embedding;
    
    -- Determine which embedding column to use
    IF embedding_type = 'title' THEN
        embedding_column := 'title_embedding';
    ELSIF embedding_type = 'description' THEN
        embedding_column := 'description_embedding';
    ELSIF embedding_type = 'key_concepts' THEN
        embedding_column := 'key_concepts_embedding';
    ELSE
        embedding_column := 'content_embedding';
    END IF;
    
    -- Return the results
    RETURN QUERY EXECUTE format('
        SELECT 
            e.*
        FROM 
            api.examples e
        JOIN 
            htmx_embeddings emb ON e.id = emb.id
        WHERE 
            1=1
            %s
            %s
        ORDER BY 
            emb.%I <=> $1
        LIMIT $2
    ',
    CASE WHEN category IS NOT NULL THEN 'AND e.category = $3' ELSE '' END,
    CASE WHEN complexity_level IS NOT NULL THEN 
        CASE WHEN category IS NOT NULL THEN 'AND e.complexity_level = $4' ELSE 'AND e.complexity_level = $3' END
    ELSE '' END,
    embedding_column)
    USING query_embedding, limit_results, category, complexity_level;
END;
\$\$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION api.search_examples TO web_anon;
"

echo "PostgREST API setup completed successfully."
echo "You can now start the PostgREST API using: docker-compose up -d"

================
File: setup_postgrest.sql
================
-- Create a role for anonymous access
CREATE ROLE web_anon NOLOGIN;

-- Create a schema for the API
CREATE SCHEMA IF NOT EXISTS api;

-- Grant usage on schemas
GRANT USAGE ON SCHEMA public TO web_anon;
GRANT USAGE ON SCHEMA api TO web_anon;

-- Create a role for PostgREST to use
CREATE ROLE postgrest LOGIN PASSWORD 'postgrest_password';
GRANT web_anon TO postgrest;

-- Create a schema for OpenAI functions
CREATE SCHEMA IF NOT EXISTS openai;
GRANT USAGE ON SCHEMA openai TO web_anon;

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS api.search_htmx_examples(text, text, text, text, integer);

-- Create a function for vector similarity search in the api schema
CREATE OR REPLACE FUNCTION api.search_htmx_examples(
    query_text TEXT,
    embedding_type TEXT DEFAULT 'content',
    category_filter TEXT DEFAULT NULL,
    complexity_filter TEXT DEFAULT NULL,
    result_limit INTEGER DEFAULT 5
) RETURNS TABLE (
    id TEXT,
    title TEXT,
    category TEXT,
    url TEXT,
    description TEXT,
    html_snippets JSONB,
    javascript_snippets JSONB,
    key_concepts TEXT[],
    htmx_attributes TEXT[],
    demo_explanation TEXT,
    complexity_level TEXT,
    use_cases TEXT[],
    similarity FLOAT
) AS $$
DECLARE
    embedding_column TEXT;
    example_id TEXT;
    example_embedding VECTOR(1536);
BEGIN
    -- Determine which embedding column to use
    CASE embedding_type
        WHEN 'title' THEN embedding_column := 'title_embedding';
        WHEN 'description' THEN embedding_column := 'description_embedding';
        WHEN 'key_concepts' THEN embedding_column := 'key_concepts_embedding';
        ELSE embedding_column := 'content_embedding';
    END CASE;
    
    -- First, try to find an exact match for the query in the examples
    -- This allows us to use the embedding of an existing example for similarity search
    SELECT e.id INTO example_id
    FROM htmx_examples e
    WHERE lower(e.title) LIKE '%' || lower(query_text) || '%'
       OR lower(e.description) LIKE '%' || lower(query_text) || '%'
    LIMIT 1;
    
    -- If we found a matching example, use its embedding for vector similarity search
    IF example_id IS NOT NULL THEN
        -- Get the embedding for the matching example
        EXECUTE format('
            SELECT emb.%I 
            FROM htmx_embeddings emb 
            WHERE emb.id = $1
        ', embedding_column)
        INTO example_embedding
        USING example_id;
        
        -- Use vector similarity search with the example's embedding
        RETURN QUERY EXECUTE format('
            SELECT 
                e.id,
                e.title,
                e.category,
                e.url,
                e.description,
                e.html_snippets,
                e.javascript_snippets,
                e.key_concepts,
                e.htmx_attributes,
                e.demo_explanation,
                e.complexity_level,
                e.use_cases,
                (1 - (emb.%I <=> $1))::FLOAT AS similarity
            FROM 
                htmx_examples e
            JOIN 
                htmx_embeddings emb ON e.id = emb.id
            WHERE 
                ($2 IS NULL OR e.category = $2)
            AND
                ($3 IS NULL OR e.complexity_level = $3)
            ORDER BY 
                emb.%I <=> $1
            LIMIT $4
        ', embedding_column, embedding_column)
        USING example_embedding, category_filter, complexity_filter, result_limit;
    ELSE
        -- Fallback to text search if no matching example is found
        RETURN QUERY EXECUTE format('
            WITH ranked_examples AS (
                SELECT 
                    e.id,
                    e.title,
                    e.category,
                    e.url,
                    e.description,
                    e.html_snippets,
                    e.javascript_snippets,
                    e.key_concepts,
                    e.htmx_attributes,
                    e.demo_explanation,
                    e.complexity_level,
                    e.use_cases,
                    CASE 
                        WHEN lower(e.title) LIKE ''%%'' || lower($1) || ''%%'' THEN 0.9
                        WHEN lower(e.description) LIKE ''%%'' || lower($1) || ''%%'' THEN 0.8
                        WHEN array_to_string(e.key_concepts, '' '') LIKE ''%%'' || lower($1) || ''%%'' THEN 0.7
                        ELSE 0.5
                    END::FLOAT AS similarity
                FROM 
                    htmx_examples e
                WHERE 
                    ($2 IS NULL OR e.category = $2)
                AND
                    ($3 IS NULL OR e.complexity_level = $3)
                AND
                    (
                        lower(e.title) LIKE ''%%'' || lower($1) || ''%%'' OR
                        lower(e.description) LIKE ''%%'' || lower($1) || ''%%'' OR
                        array_to_string(e.key_concepts, '' '') LIKE ''%%'' || lower($1) || ''%%'' OR
                        array_to_string(e.htmx_attributes, '' '') LIKE ''%%'' || lower($1) || ''%%''
                    )
            )
            SELECT * FROM ranked_examples
            ORDER BY similarity DESC
            LIMIT $4
        ')
        USING query_text, category_filter, complexity_filter, result_limit;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a view for PostgREST to expose
CREATE OR REPLACE VIEW api.htmx_examples AS
SELECT 
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
FROM htmx_examples;

-- Grant permissions to the web_anon role
GRANT SELECT ON api.htmx_examples TO web_anon;
GRANT EXECUTE ON FUNCTION api.search_htmx_examples TO web_anon;

-- Create a view for categories
CREATE OR REPLACE VIEW api.htmx_categories AS
SELECT DISTINCT category FROM htmx_examples ORDER BY category;

-- Create a view for complexity levels
CREATE OR REPLACE VIEW api.htmx_complexity_levels AS
SELECT DISTINCT complexity_level FROM htmx_examples ORDER BY complexity_level;

-- Grant permissions on the views
GRANT SELECT ON api.htmx_categories TO web_anon;
GRANT SELECT ON api.htmx_complexity_levels TO web_anon;

================
File: summarize_workflow.sh
================
#!/bin/bash

# Create output directory if it doesn't exist
mkdir -p summaries

# Instructions for Gemini
INSTRUCTIONS="You are analyzing logs from an LLM agent that created a workflow for scraping HTMX examples, extracting structured data, loading it to PostgreSQL, embedding the data, and creating a PostgREST API endpoint with vector similarity search. 

Please create a very concise summary of the successful steps taken in this workflow, focusing on:
1. The key files created/used at each step
2. The commands executed for each successful step
3. The overall workflow from start to finish

Format your response as a markdown document with clear sections for each major step in the process. Include code snippets where relevant, but keep them brief. This summary should serve as documentation for repeating this process in the future."

# Process the first conversation log
echo "Processing fetching-htmx-examples.md..."
cat .specstory/history/fetching-htmx-examples.md | llm "$INSTRUCTIONS" -m gemini-2.0-flash-001 > summaries/htmx_examples_summary.md

# Process the second conversation log
echo "Processing protecting-secrets-with-env-file.md..."
cat .specstory/history/protecting-secrets-with-env-file.md | llm "$INSTRUCTIONS" -m gemini-2.0-flash-001 > summaries/env_secrets_summary.md

# Combine the summaries
echo "Combining summaries..."
cat > summaries/workflow_summary.md << EOF
# HTMX Examples Scraping and Embedding Workflow Summary

This document provides a concise summary of the workflow used to scrape HTMX examples, 
extract structured data, load it to PostgreSQL, embed the data using OpenAI, 
and create a PostgREST API endpoint with vector similarity search.

## Workflow Overview

EOF

cat summaries/htmx_examples_summary.md >> summaries/workflow_summary.md
echo -e "\n\n" >> summaries/workflow_summary.md
cat summaries/env_secrets_summary.md >> summaries/workflow_summary.md

echo "Summary created at summaries/workflow_summary.md"

================
File: update_scripts_to_use_env.sh
================
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

================
File: update_workflow_summary.sh
================
#!/bin/bash

# Create output directory if it doesn't exist
mkdir -p summaries

# Instructions for Gemini
INSTRUCTIONS="You are analyzing logs from an LLM agent that created a workflow for scraping HTMX examples, extracting structured data, loading it to PostgreSQL, embedding the data, and creating a PostgREST API endpoint with vector similarity search. 

Please create a very concise summary of the successful steps taken in this workflow, focusing on:
1. The key files created/used at each step
2. The commands executed for each successful step
3. The overall workflow from start to finish

Format your response as a markdown document with clear sections for each major step in the process. Include code snippets where relevant, but keep them brief. This summary should serve as documentation for repeating this process in the future."

# Process the conversation logs
echo "Processing conversation logs..."
for log_file in .specstory/history/*.md; do
  filename=$(basename "$log_file" .md)
  echo "Processing $filename..."
  cat "$log_file" | llm "$INSTRUCTIONS" -m gemini-2.0-flash-001 > "summaries/${filename}_summary.md"
done

# Combine the summaries
echo "Combining summaries..."
cat > summaries/workflow_summary.md << EOF
# HTMX Examples Scraping and Embedding Workflow Summary

This document provides a concise summary of the workflow used to scrape HTMX examples, 
extract structured data, load it to PostgreSQL, embed the data using OpenAI, 
and create a PostgREST API endpoint with vector similarity search.

## Workflow Overview

EOF

for summary_file in summaries/*_summary.md; do
  cat "$summary_file" >> summaries/workflow_summary.md
  echo -e "\n\n" >> summaries/workflow_summary.md
done

# Create a final, more concise summary
echo "Creating final summary..."
cat summaries/workflow_summary.md | llm "Create a concise, well-structured summary of this workflow with clear steps, key files, commands, and outputs for each step. Format as markdown with sections for each step and a final section with the complete workflow execution steps. Keep it under 100 lines total." -m gemini-2.0-flash-001 > summaries/final_workflow_summary.md

echo "Summary created at summaries/final_workflow_summary.md"

================
File: uv.lock
================
version = 1
requires-python = ">=3.13"

[[package]]
name = "annotated-types"
version = "0.7.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/ee/67/531ea369ba64dcff5ec9c3402f9f51bf748cec26dde048a2f973a4eea7f5/annotated_types-0.7.0.tar.gz", hash = "sha256:aff07c09a53a08bc8cfccb9c85b05f1aa9a2a6f23728d790723543408344ce89", size = 16081 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/78/b6/6307fbef88d9b5ee7421e68d78a9f162e0da4900bc5f5793f6d3d0e34fb8/annotated_types-0.7.0-py3-none-any.whl", hash = "sha256:1f02e8b43a8fbbc3f3e0d4f0f4bfc8131bcb4eebe8849b8e5c773f3a1c582a53", size = 13643 },
]

[[package]]
name = "anyio"
version = "4.8.0"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "idna" },
    { name = "sniffio" },
]
sdist = { url = "https://files.pythonhosted.org/packages/a3/73/199a98fc2dae33535d6b8e8e6ec01f8c1d76c9adb096c6b7d64823038cde/anyio-4.8.0.tar.gz", hash = "sha256:1d9fe889df5212298c0c0723fa20479d1b94883a2df44bd3897aa91083316f7a", size = 181126 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/46/eb/e7f063ad1fec6b3178a3cd82d1a3c4de82cccf283fc42746168188e1cdd5/anyio-4.8.0-py3-none-any.whl", hash = "sha256:b5011f270ab5eb0abf13385f851315585cc37ef330dd88e27ec3d34d651fd47a", size = 96041 },
]

[[package]]
name = "certifi"
version = "2025.1.31"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/1c/ab/c9f1e32b7b1bf505bf26f0ef697775960db7932abeb7b516de930ba2705f/certifi-2025.1.31.tar.gz", hash = "sha256:3d5da6925056f6f18f119200434a4780a94263f10d1c21d032a6f6b2baa20651", size = 167577 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/38/fc/bce832fd4fd99766c04d1ee0eead6b0ec6486fb100ae5e74c1d91292b982/certifi-2025.1.31-py3-none-any.whl", hash = "sha256:ca78db4565a652026a4db2bcdf68f2fb589ea80d0be70e03929ed730746b84fe", size = 166393 },
]

[[package]]
name = "colorama"
version = "0.4.6"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/d8/53/6f443c9a4a8358a93a6792e2acffb9d9d5cb0a5cfd8802644b7b1c9a02e4/colorama-0.4.6.tar.gz", hash = "sha256:08695f5cb7ed6e0531a20572697297273c47b8cae5a63ffc6d6ed5c201be6e44", size = 27697 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/d1/d6/3965ed04c63042e047cb6a3e6ed1a63a35087b6a609aa3a15ed8ac56c221/colorama-0.4.6-py2.py3-none-any.whl", hash = "sha256:4f1d9991f5acc0ca119f9d443620b77f9d6b33703e51011c16baf57afb285fc6", size = 25335 },
]

[[package]]
name = "distro"
version = "1.9.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/fc/f8/98eea607f65de6527f8a2e8885fc8015d3e6f5775df186e443e0964a11c3/distro-1.9.0.tar.gz", hash = "sha256:2fa77c6fd8940f116ee1d6b94a2f90b13b5ea8d019b98bc8bafdcabcdd9bdbed", size = 60722 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/12/b3/231ffd4ab1fc9d679809f356cebee130ac7daa00d6d6f3206dd4fd137e9e/distro-1.9.0-py3-none-any.whl", hash = "sha256:7bffd925d65168f85027d8da9af6bddab658135b840670a223589bc0c8ef02b2", size = 20277 },
]

[[package]]
name = "h11"
version = "0.14.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/f5/38/3af3d3633a34a3316095b39c8e8fb4853a28a536e55d347bd8d8e9a14b03/h11-0.14.0.tar.gz", hash = "sha256:8f19fbbe99e72420ff35c00b27a34cb9937e902a8b810e2c88300c6f0a3b699d", size = 100418 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/95/04/ff642e65ad6b90db43e668d70ffb6736436c7ce41fcc549f4e9472234127/h11-0.14.0-py3-none-any.whl", hash = "sha256:e3fe4ac4b851c468cc8363d500db52c2ead036020723024a109d37346efaa761", size = 58259 },
]

[[package]]
name = "httpcore"
version = "1.0.7"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "certifi" },
    { name = "h11" },
]
sdist = { url = "https://files.pythonhosted.org/packages/6a/41/d7d0a89eb493922c37d343b607bc1b5da7f5be7e383740b4753ad8943e90/httpcore-1.0.7.tar.gz", hash = "sha256:8551cb62a169ec7162ac7be8d4817d561f60e08eaa485234898414bb5a8a0b4c", size = 85196 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/87/f5/72347bc88306acb359581ac4d52f23c0ef445b57157adedb9aee0cd689d2/httpcore-1.0.7-py3-none-any.whl", hash = "sha256:a3fff8f43dc260d5bd363d9f9cf1830fa3a458b332856f34282de498ed420edd", size = 78551 },
]

[[package]]
name = "httpx"
version = "0.28.1"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "anyio" },
    { name = "certifi" },
    { name = "httpcore" },
    { name = "idna" },
]
sdist = { url = "https://files.pythonhosted.org/packages/b1/df/48c586a5fe32a0f01324ee087459e112ebb7224f646c0b5023f5e79e9956/httpx-0.28.1.tar.gz", hash = "sha256:75e98c5f16b0f35b567856f597f06ff2270a374470a5c2392242528e3e3e42fc", size = 141406 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/2a/39/e50c7c3a983047577ee07d2a9e53faf5a69493943ec3f6a384bdc792deb2/httpx-0.28.1-py3-none-any.whl", hash = "sha256:d909fcccc110f8c7faf814ca82a9a4d816bc5a6dbfea25d6591d6985b8ba59ad", size = 73517 },
]

[[package]]
name = "idna"
version = "3.10"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/f1/70/7703c29685631f5a7590aa73f1f1d3fa9a380e654b86af429e0934a32f7d/idna-3.10.tar.gz", hash = "sha256:12f65c9b470abda6dc35cf8e63cc574b1c52b11df2c86030af0ac09b01b13ea9", size = 190490 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/76/c6/c88e154df9c4e1a2a66ccf0005a88dfb2650c1dffb6f5ce603dfbd452ce3/idna-3.10-py3-none-any.whl", hash = "sha256:946d195a0d259cbba61165e88e65941f16e9b36ea6ddb97f00452bae8b1287d3", size = 70442 },
]

[[package]]
name = "jiter"
version = "0.9.0"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/1e/c2/e4562507f52f0af7036da125bb699602ead37a2332af0788f8e0a3417f36/jiter-0.9.0.tar.gz", hash = "sha256:aadba0964deb424daa24492abc3d229c60c4a31bfee205aedbf1acc7639d7893", size = 162604 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/e7/1b/4cd165c362e8f2f520fdb43245e2b414f42a255921248b4f8b9c8d871ff1/jiter-0.9.0-cp313-cp313-macosx_10_12_x86_64.whl", hash = "sha256:2764891d3f3e8b18dce2cff24949153ee30c9239da7c00f032511091ba688ff7", size = 308197 },
    { url = "https://files.pythonhosted.org/packages/13/aa/7a890dfe29c84c9a82064a9fe36079c7c0309c91b70c380dc138f9bea44a/jiter-0.9.0-cp313-cp313-macosx_11_0_arm64.whl", hash = "sha256:387b22fbfd7a62418d5212b4638026d01723761c75c1c8232a8b8c37c2f1003b", size = 318160 },
    { url = "https://files.pythonhosted.org/packages/6a/38/5888b43fc01102f733f085673c4f0be5a298f69808ec63de55051754e390/jiter-0.9.0-cp313-cp313-manylinux_2_17_aarch64.manylinux2014_aarch64.whl", hash = "sha256:40d8da8629ccae3606c61d9184970423655fb4e33d03330bcdfe52d234d32f69", size = 341259 },
    { url = "https://files.pythonhosted.org/packages/3d/5e/bbdbb63305bcc01006de683b6228cd061458b9b7bb9b8d9bc348a58e5dc2/jiter-0.9.0-cp313-cp313-manylinux_2_17_armv7l.manylinux2014_armv7l.whl", hash = "sha256:a1be73d8982bdc278b7b9377426a4b44ceb5c7952073dd7488e4ae96b88e1103", size = 363730 },
    { url = "https://files.pythonhosted.org/packages/75/85/53a3edc616992fe4af6814c25f91ee3b1e22f7678e979b6ea82d3bc0667e/jiter-0.9.0-cp313-cp313-manylinux_2_17_ppc64le.manylinux2014_ppc64le.whl", hash = "sha256:2228eaaaa111ec54b9e89f7481bffb3972e9059301a878d085b2b449fbbde635", size = 405126 },
    { url = "https://files.pythonhosted.org/packages/ae/b3/1ee26b12b2693bd3f0b71d3188e4e5d817b12e3c630a09e099e0a89e28fa/jiter-0.9.0-cp313-cp313-manylinux_2_17_s390x.manylinux2014_s390x.whl", hash = "sha256:11509bfecbc319459647d4ac3fd391d26fdf530dad00c13c4dadabf5b81f01a4", size = 393668 },
    { url = "https://files.pythonhosted.org/packages/11/87/e084ce261950c1861773ab534d49127d1517b629478304d328493f980791/jiter-0.9.0-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl", hash = "sha256:3f22238da568be8bbd8e0650e12feeb2cfea15eda4f9fc271d3b362a4fa0604d", size = 352350 },
    { url = "https://files.pythonhosted.org/packages/f0/06/7dca84b04987e9df563610aa0bc154ea176e50358af532ab40ffb87434df/jiter-0.9.0-cp313-cp313-manylinux_2_5_i686.manylinux1_i686.whl", hash = "sha256:17f5d55eb856597607562257c8e36c42bc87f16bef52ef7129b7da11afc779f3", size = 384204 },
    { url = "https://files.pythonhosted.org/packages/16/2f/82e1c6020db72f397dd070eec0c85ebc4df7c88967bc86d3ce9864148f28/jiter-0.9.0-cp313-cp313-musllinux_1_1_aarch64.whl", hash = "sha256:6a99bed9fbb02f5bed416d137944419a69aa4c423e44189bc49718859ea83bc5", size = 520322 },
    { url = "https://files.pythonhosted.org/packages/36/fd/4f0cd3abe83ce208991ca61e7e5df915aa35b67f1c0633eb7cf2f2e88ec7/jiter-0.9.0-cp313-cp313-musllinux_1_1_x86_64.whl", hash = "sha256:e057adb0cd1bd39606100be0eafe742de2de88c79df632955b9ab53a086b3c8d", size = 512184 },
    { url = "https://files.pythonhosted.org/packages/a0/3c/8a56f6d547731a0b4410a2d9d16bf39c861046f91f57c98f7cab3d2aa9ce/jiter-0.9.0-cp313-cp313-win32.whl", hash = "sha256:f7e6850991f3940f62d387ccfa54d1a92bd4bb9f89690b53aea36b4364bcab53", size = 206504 },
    { url = "https://files.pythonhosted.org/packages/f4/1c/0c996fd90639acda75ed7fa698ee5fd7d80243057185dc2f63d4c1c9f6b9/jiter-0.9.0-cp313-cp313-win_amd64.whl", hash = "sha256:c8ae3bf27cd1ac5e6e8b7a27487bf3ab5f82318211ec2e1346a5b058756361f7", size = 204943 },
    { url = "https://files.pythonhosted.org/packages/78/0f/77a63ca7aa5fed9a1b9135af57e190d905bcd3702b36aca46a01090d39ad/jiter-0.9.0-cp313-cp313t-macosx_11_0_arm64.whl", hash = "sha256:f0b2827fb88dda2cbecbbc3e596ef08d69bda06c6f57930aec8e79505dc17001", size = 317281 },
    { url = "https://files.pythonhosted.org/packages/f9/39/a3a1571712c2bf6ec4c657f0d66da114a63a2e32b7e4eb8e0b83295ee034/jiter-0.9.0-cp313-cp313t-manylinux_2_17_x86_64.manylinux2014_x86_64.whl", hash = "sha256:062b756ceb1d40b0b28f326cba26cfd575a4918415b036464a52f08632731e5a", size = 350273 },
    { url = "https://files.pythonhosted.org/packages/ee/47/3729f00f35a696e68da15d64eb9283c330e776f3b5789bac7f2c0c4df209/jiter-0.9.0-cp313-cp313t-win_amd64.whl", hash = "sha256:6f7838bc467ab7e8ef9f387bd6de195c43bad82a569c1699cb822f6609dd4cdf", size = 206867 },
]

[[package]]
name = "openai"
version = "1.66.3"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "anyio" },
    { name = "distro" },
    { name = "httpx" },
    { name = "jiter" },
    { name = "pydantic" },
    { name = "sniffio" },
    { name = "tqdm" },
    { name = "typing-extensions" },
]
sdist = { url = "https://files.pythonhosted.org/packages/a3/77/5172104ca1df35ed2ed8fb26dbc787f721c39498fc51d666c4db07756a0c/openai-1.66.3.tar.gz", hash = "sha256:8dde3aebe2d081258d4159c4cb27bdc13b5bb3f7ea2201d9bd940b9a89faf0c9", size = 397244 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/78/5a/e20182f7b6171642d759c548daa0ba20a1d3ac10d2bd0a13fd75704a9ac3/openai-1.66.3-py3-none-any.whl", hash = "sha256:a427c920f727711877ab17c11b95f1230b27767ba7a01e5b66102945141ceca9", size = 567400 },
]

[[package]]
name = "psycopg"
version = "3.2.6"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "tzdata", marker = "sys_platform == 'win32'" },
]
sdist = { url = "https://files.pythonhosted.org/packages/67/97/eea08f74f1c6dd2a02ee81b4ebfe5b558beb468ebbd11031adbf58d31be0/psycopg-3.2.6.tar.gz", hash = "sha256:16fa094efa2698f260f2af74f3710f781e4a6f226efe9d1fd0c37f384639ed8a", size = 156322 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/d7/7d/0ba52deff71f65df8ec8038adad86ba09368c945424a9bd8145d679a2c6a/psycopg-3.2.6-py3-none-any.whl", hash = "sha256:f3ff5488525890abb0566c429146add66b329e20d6d4835662b920cbbf90ac58", size = 199077 },
]

[[package]]
name = "psycopg2"
version = "2.9.10"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/62/51/2007ea29e605957a17ac6357115d0c1a1b60c8c984951c19419b3474cdfd/psycopg2-2.9.10.tar.gz", hash = "sha256:12ec0b40b0273f95296233e8750441339298e6a572f7039da5b260e3c8b60e11", size = 385672 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/ae/49/a6cfc94a9c483b1fa401fbcb23aca7892f60c7269c5ffa2ac408364f80dc/psycopg2-2.9.10-cp313-cp313-win_amd64.whl", hash = "sha256:91fd603a2155da8d0cfcdbf8ab24a2d54bca72795b90d2a3ed2b6da8d979dee2", size = 2569060 },
]

[[package]]
name = "pydantic"
version = "2.10.6"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "annotated-types" },
    { name = "pydantic-core" },
    { name = "typing-extensions" },
]
sdist = { url = "https://files.pythonhosted.org/packages/b7/ae/d5220c5c52b158b1de7ca89fc5edb72f304a70a4c540c84c8844bf4008de/pydantic-2.10.6.tar.gz", hash = "sha256:ca5daa827cce33de7a42be142548b0096bf05a7e7b365aebfa5f8eeec7128236", size = 761681 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/f4/3c/8cc1cc84deffa6e25d2d0c688ebb80635dfdbf1dbea3e30c541c8cf4d860/pydantic-2.10.6-py3-none-any.whl", hash = "sha256:427d664bf0b8a2b34ff5dd0f5a18df00591adcee7198fbd71981054cef37b584", size = 431696 },
]

[[package]]
name = "pydantic-core"
version = "2.27.2"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "typing-extensions" },
]
sdist = { url = "https://files.pythonhosted.org/packages/fc/01/f3e5ac5e7c25833db5eb555f7b7ab24cd6f8c322d3a3ad2d67a952dc0abc/pydantic_core-2.27.2.tar.gz", hash = "sha256:eb026e5a4c1fee05726072337ff51d1efb6f59090b7da90d30ea58625b1ffb39", size = 413443 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/41/b1/9bc383f48f8002f99104e3acff6cba1231b29ef76cfa45d1506a5cad1f84/pydantic_core-2.27.2-cp313-cp313-macosx_10_12_x86_64.whl", hash = "sha256:7d14bd329640e63852364c306f4d23eb744e0f8193148d4044dd3dacdaacbd8b", size = 1892709 },
    { url = "https://files.pythonhosted.org/packages/10/6c/e62b8657b834f3eb2961b49ec8e301eb99946245e70bf42c8817350cbefc/pydantic_core-2.27.2-cp313-cp313-macosx_11_0_arm64.whl", hash = "sha256:82f91663004eb8ed30ff478d77c4d1179b3563df6cdb15c0817cd1cdaf34d154", size = 1811273 },
    { url = "https://files.pythonhosted.org/packages/ba/15/52cfe49c8c986e081b863b102d6b859d9defc63446b642ccbbb3742bf371/pydantic_core-2.27.2-cp313-cp313-manylinux_2_17_aarch64.manylinux2014_aarch64.whl", hash = "sha256:71b24c7d61131bb83df10cc7e687433609963a944ccf45190cfc21e0887b08c9", size = 1823027 },
    { url = "https://files.pythonhosted.org/packages/b1/1c/b6f402cfc18ec0024120602bdbcebc7bdd5b856528c013bd4d13865ca473/pydantic_core-2.27.2-cp313-cp313-manylinux_2_17_armv7l.manylinux2014_armv7l.whl", hash = "sha256:fa8e459d4954f608fa26116118bb67f56b93b209c39b008277ace29937453dc9", size = 1868888 },
    { url = "https://files.pythonhosted.org/packages/bd/7b/8cb75b66ac37bc2975a3b7de99f3c6f355fcc4d89820b61dffa8f1e81677/pydantic_core-2.27.2-cp313-cp313-manylinux_2_17_ppc64le.manylinux2014_ppc64le.whl", hash = "sha256:ce8918cbebc8da707ba805b7fd0b382816858728ae7fe19a942080c24e5b7cd1", size = 2037738 },
    { url = "https://files.pythonhosted.org/packages/c8/f1/786d8fe78970a06f61df22cba58e365ce304bf9b9f46cc71c8c424e0c334/pydantic_core-2.27.2-cp313-cp313-manylinux_2_17_s390x.manylinux2014_s390x.whl", hash = "sha256:eda3f5c2a021bbc5d976107bb302e0131351c2ba54343f8a496dc8783d3d3a6a", size = 2685138 },
    { url = "https://files.pythonhosted.org/packages/a6/74/d12b2cd841d8724dc8ffb13fc5cef86566a53ed358103150209ecd5d1999/pydantic_core-2.27.2-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl", hash = "sha256:bd8086fa684c4775c27f03f062cbb9eaa6e17f064307e86b21b9e0abc9c0f02e", size = 1997025 },
    { url = "https://files.pythonhosted.org/packages/a0/6e/940bcd631bc4d9a06c9539b51f070b66e8f370ed0933f392db6ff350d873/pydantic_core-2.27.2-cp313-cp313-manylinux_2_5_i686.manylinux1_i686.whl", hash = "sha256:8d9b3388db186ba0c099a6d20f0604a44eabdeef1777ddd94786cdae158729e4", size = 2004633 },
    { url = "https://files.pythonhosted.org/packages/50/cc/a46b34f1708d82498c227d5d80ce615b2dd502ddcfd8376fc14a36655af1/pydantic_core-2.27.2-cp313-cp313-musllinux_1_1_aarch64.whl", hash = "sha256:7a66efda2387de898c8f38c0cf7f14fca0b51a8ef0b24bfea5849f1b3c95af27", size = 1999404 },
    { url = "https://files.pythonhosted.org/packages/ca/2d/c365cfa930ed23bc58c41463bae347d1005537dc8db79e998af8ba28d35e/pydantic_core-2.27.2-cp313-cp313-musllinux_1_1_armv7l.whl", hash = "sha256:18a101c168e4e092ab40dbc2503bdc0f62010e95d292b27827871dc85450d7ee", size = 2130130 },
    { url = "https://files.pythonhosted.org/packages/f4/d7/eb64d015c350b7cdb371145b54d96c919d4db516817f31cd1c650cae3b21/pydantic_core-2.27.2-cp313-cp313-musllinux_1_1_x86_64.whl", hash = "sha256:ba5dd002f88b78a4215ed2f8ddbdf85e8513382820ba15ad5ad8955ce0ca19a1", size = 2157946 },
    { url = "https://files.pythonhosted.org/packages/a4/99/bddde3ddde76c03b65dfd5a66ab436c4e58ffc42927d4ff1198ffbf96f5f/pydantic_core-2.27.2-cp313-cp313-win32.whl", hash = "sha256:1ebaf1d0481914d004a573394f4be3a7616334be70261007e47c2a6fe7e50130", size = 1834387 },
    { url = "https://files.pythonhosted.org/packages/71/47/82b5e846e01b26ac6f1893d3c5f9f3a2eb6ba79be26eef0b759b4fe72946/pydantic_core-2.27.2-cp313-cp313-win_amd64.whl", hash = "sha256:953101387ecf2f5652883208769a79e48db18c6df442568a0b5ccd8c2723abee", size = 1990453 },
    { url = "https://files.pythonhosted.org/packages/51/b2/b2b50d5ecf21acf870190ae5d093602d95f66c9c31f9d5de6062eb329ad1/pydantic_core-2.27.2-cp313-cp313-win_arm64.whl", hash = "sha256:ac4dbfd1691affb8f48c2c13241a2e3b60ff23247cbcf981759c768b6633cf8b", size = 1885186 },
]

[[package]]
name = "python-dotenv"
version = "1.0.1"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/bc/57/e84d88dfe0aec03b7a2d4327012c1627ab5f03652216c63d49846d7a6c58/python-dotenv-1.0.1.tar.gz", hash = "sha256:e324ee90a023d808f1959c46bcbc04446a10ced277783dc6ee09987c37ec10ca", size = 39115 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/6a/3e/b68c118422ec867fa7ab88444e1274aa40681c606d59ac27de5a5588f082/python_dotenv-1.0.1-py3-none-any.whl", hash = "sha256:f7b63ef50f1b690dddf550d03497b66d609393b40b564ed0d674909a68ebf16a", size = 19863 },
]

[[package]]
name = "scrape-embed"
version = "0.1.0"
source = { virtual = "." }
dependencies = [
    { name = "openai" },
    { name = "psycopg" },
    { name = "psycopg2" },
    { name = "python-dotenv" },
]

[package.metadata]
requires-dist = [
    { name = "openai", specifier = ">=1.66.3" },
    { name = "psycopg", specifier = ">=3.2.6" },
    { name = "psycopg2", specifier = ">=2.9.10" },
    { name = "python-dotenv", specifier = ">=1.0.1" },
]

[[package]]
name = "sniffio"
version = "1.3.1"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/a2/87/a6771e1546d97e7e041b6ae58d80074f81b7d5121207425c964ddf5cfdbd/sniffio-1.3.1.tar.gz", hash = "sha256:f4324edc670a0f49750a81b895f35c3adb843cca46f0530f79fc1babb23789dc", size = 20372 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/e9/44/75a9c9421471a6c4805dbf2356f7c181a29c1879239abab1ea2cc8f38b40/sniffio-1.3.1-py3-none-any.whl", hash = "sha256:2f6da418d1f1e0fddd844478f41680e794e6051915791a034ff65e5f100525a2", size = 10235 },
]

[[package]]
name = "tqdm"
version = "4.67.1"
source = { registry = "https://pypi.org/simple" }
dependencies = [
    { name = "colorama", marker = "platform_system == 'Windows'" },
]
sdist = { url = "https://files.pythonhosted.org/packages/a8/4b/29b4ef32e036bb34e4ab51796dd745cdba7ed47ad142a9f4a1eb8e0c744d/tqdm-4.67.1.tar.gz", hash = "sha256:f8aef9c52c08c13a65f30ea34f4e5aac3fd1a34959879d7e59e63027286627f2", size = 169737 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/d0/30/dc54f88dd4a2b5dc8a0279bdd7270e735851848b762aeb1c1184ed1f6b14/tqdm-4.67.1-py3-none-any.whl", hash = "sha256:26445eca388f82e72884e0d580d5464cd801a3ea01e63e5601bdff9ba6a48de2", size = 78540 },
]

[[package]]
name = "typing-extensions"
version = "4.12.2"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/df/db/f35a00659bc03fec321ba8bce9420de607a1d37f8342eee1863174c69557/typing_extensions-4.12.2.tar.gz", hash = "sha256:1a7ead55c7e559dd4dee8856e3a88b41225abfe1ce8df57b7c13915fe121ffb8", size = 85321 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/26/9f/ad63fc0248c5379346306f8668cda6e2e2e9c95e01216d2b8ffd9ff037d0/typing_extensions-4.12.2-py3-none-any.whl", hash = "sha256:04e5ca0351e0f3f85c6853954072df659d0d13fac324d0072316b67d7794700d", size = 37438 },
]

[[package]]
name = "tzdata"
version = "2025.1"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/packages/43/0f/fa4723f22942480be4ca9527bbde8d43f6c3f2fe8412f00e7f5f6746bc8b/tzdata-2025.1.tar.gz", hash = "sha256:24894909e88cdb28bd1636c6887801df64cb485bd593f2fd83ef29075a81d694", size = 194950 }
wheels = [
    { url = "https://files.pythonhosted.org/packages/0f/dd/84f10e23edd882c6f968c21c2434fe67bd4a528967067515feca9e611e5e/tzdata-2025.1-py2.py3-none-any.whl", hash = "sha256:7e127113816800496f027041c570f50bcd464a020098a3b6b199517772303639", size = 346762 },
]



================================================================
End of Codebase
================================================================
