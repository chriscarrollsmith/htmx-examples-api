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


