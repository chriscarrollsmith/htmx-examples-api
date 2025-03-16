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


