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