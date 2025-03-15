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