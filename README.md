# HTMX Examples Semantic Search API

This repository contains a PostgREST API for semantic search over HTMX code examples. The API leverages vector embeddings to find examples based on semantic similarity rather than just keyword matching, allowing for more intuitive and relevant search results.

## Overview

The API provides endpoints for:

1. **Vector Search** - Search using a specific embedding type (content, title, description, key_concepts)
2. **Multi-Vector Search** - Search across all embedding types at once, combining the results
3. **Similar Examples Search** - Find examples similar to an existing example by ID

All search endpoints use [Google's Generative AI](https://ai.google.dev/) to generate embeddings from natural language queries, enabling semantic search without needing to understand vector embeddings.

## API Base URL

The API is hosted at:
```
http://157.245.4.248
```

## API Usage

The API is accessible through a middleware that handles the embedding generation process. This means you can use natural language queries without having to manually generate vector embeddings.

### Basic Search

```bash
curl -X GET "http://157.245.4.248/api/search?q=How%20to%20implement%20infinite%20scroll"
```

This endpoint:
1. Takes your natural language query
2. Converts it to an embedding vector using Google AI
3. Finds the most semantically similar HTMX examples
4. Returns the results ordered by similarity

#### Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| q | Your search query (required) | - | `q=Form validation without page refresh` |
| limit | Maximum number of results | 5 | `limit=10` |
| embedding_type | Type of embedding to search against | 'content' | `embedding_type=title` |
| category | Filter by example category | null | `category=UI%20Patterns` |
| complexity | Filter by complexity level | null | `complexity=intermediate` |

#### Example Response

```json
[
  {
    "id": "animated-tabs",
    "title": "Animated Tabs",
    "category": "UI Patterns",
    "url": "https://htmx.org/examples/animated-tabs/",
    "description": "This example shows how to implement animated tabs with HTMX",
    "html_snippets": [...],
    "javascript_snippets": [...],
    "key_concepts": ["tabs", "animation", "css transitions"],
    "htmx_attributes": ["hx-get", "hx-target", "hx-swap"],
    "demo_explanation": "When a tab is clicked, it makes an AJAX request for the new content...",
    "complexity_level": "intermediate",
    "use_cases": ["Navigation", "Content organization"],
    "similarity": 0.92
  },
  {
    "id": "tabs-example",
    "title": "Basic Tabs",
    "category": "UI Patterns",
    "url": "https://htmx.org/examples/tabs/",
    "description": "A simple tabs implementation with HTMX",
    "html_snippets": [...],
    "javascript_snippets": [...],
    "key_concepts": ["tabs", "content switching"],
    "htmx_attributes": ["hx-get", "hx-target"],
    "demo_explanation": "This example shows a minimal tab implementation...",
    "complexity_level": "beginner",
    "use_cases": ["Navigation", "Content organization"],
    "similarity": 0.89
  }
]
```

### Multi-Vector Search

```bash
curl -X GET "http://157.245.4.248/api/multi-search?q=Form%20validation%20with%20htmx"
```

This advanced search method checks your query against multiple embedding types (content, title, description, key_concepts) and combines the results with a weighted algorithm for better overall results.

#### Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| q | Your search query (required) | - | `q=Lazy loading with htmx` |
| limit | Maximum number of results | 5 | `limit=10` |
| category | Filter by example category | null | `category=Performance` |
| complexity | Filter by complexity level | null | `complexity=advanced` |

#### Example Response

The response follows the same format as the basic search, but includes additional similarity scores for each embedding type:

```json
[
  {
    "id": "form-validation",
    "title": "Client-Side Form Validation",
    "category": "Forms",
    "url": "https://htmx.org/examples/form-validation/",
    "description": "How to implement client-side form validation with HTMX",
    "html_snippets": [...],
    "javascript_snippets": [...],
    "key_concepts": ["validation", "forms", "client-side"],
    "htmx_attributes": ["hx-post", "hx-validate"],
    "demo_explanation": "This example demonstrates how to validate forms...",
    "complexity_level": "intermediate",
    "use_cases": ["Data entry", "User input"],
    "similarity": 0.94,
    "content_similarity": 0.95,
    "title_similarity": 0.85,
    "description_similarity": 0.91,
    "key_concepts_similarity": 0.96
  }
]
```

### Finding Similar Examples

```bash
curl -X GET "http://157.245.4.248/api/similar?id=form-validation&limit=3"
```

This endpoint finds examples similar to an existing example by ID.

#### Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| id | ID of the example to find similar examples for (required) | - | `id=infinite-scroll` |
| embedding_type | Type of embedding to use for comparison | 'content' | `embedding_type=key_concepts` |
| limit | Maximum number of results | 5 | `limit=10` |
| category | Filter by example category | null | `category=Animation` |
| complexity | Filter by complexity level | null | `complexity=beginner` |

The response format is the same as the basic search.

## Usage Examples

### Find Examples About Lazy Loading

```bash
curl -X GET "http://157.245.4.248/api/search?q=Implement%20lazy%20loading%20for%20images&limit=3"
```

### Search for Animation Examples

```bash
curl -X GET "http://157.245.4.248/api/multi-search?q=Smooth%20animations%20with%20CSS%20transitions&category=Animation&limit=5"
```

### Find Similar Examples to Infinite Scroll

```bash
curl -X GET "http://157.245.4.248/api/similar?id=infinite-scroll&limit=3"
```

### Filter by Complexity Level

```bash
curl -X GET "http://157.245.4.248/api/search?q=Simple%20modal%20dialog&complexity=beginner"
```

## Health Check

To check if the API is functioning correctly:

```bash
curl -X GET "http://157.245.4.248/health"
```

Expected response:
```json
{"status": "healthy"}
```

## API Schema

To view the complete API schema and available functions:

```bash
curl -X GET "http://157.245.4.248/direct/"
```

This will return the OpenAPI schema with detailed information about all available endpoints and data structures.

## Technical Details

### API Architecture

The API consists of two key components:

1. **Node.js Middleware** - Handles query embedding using Google AI and provides user-friendly endpoints
2. **PostgREST Backend** - Provides direct database access and performs vector similarity search

While you can access the PostgREST API directly, this requires working with 768-dimensional vectors. We recommend using the middleware endpoints that handle embedding generation for you.

### Embedding Model

The API uses Google's `text-embedding-004` model to generate 768-dimensional vector embeddings. These embeddings capture the semantic meaning of text, allowing for matching based on concepts rather than just keywords.

### Vector Similarity

The API uses cosine similarity for measuring the distance between embeddings. The similarity score ranges from 0 to 1, where 1 represents identical vectors.

### Multi-Vector Search Weighting

For multi-vector searches, the API uses a weighted combination:
- 40% weight for content embedding
- 20% weight for title embedding  
- 20% weight for description embedding
- 20% weight for key concepts embedding

This balances the importance of full content with more specialized aspects of each example.

## Advanced Usage: Direct PostgREST Access

For advanced users who want to work directly with vector embeddings, you can access the PostgREST API directly under the `/direct/` path. This requires:

1. Creating your own 768-dimensional embedding vectors
2. Sending them directly to the vector search functions

Example:
```
POST http://157.245.4.248/direct/rpc/vector_search
Content-Type: application/json

{
  "query_embedding": [0.1, 0.2, ...768 values...],  
  "embedding_type": "content",
  "result_limit": 5,
  "category_filter": null,
  "complexity_filter": null
}
```

## Code Examples for Querying the API

Below are examples of how to query the API using different programming languages and tools:

## Rate Limiting and Usage Considerations

When using this API, please be aware of the following considerations:

1. **Rate Limiting**: There is a limit of 100 requests per minute per IP address. Exceeding this limit will result in HTTP 429 (Too Many Requests) responses.

2. **Response Time**: Embedding generation may take 1-2 seconds, so expect some latency for each request.

3. **Query Complexity**: More complex queries generate better embeddings for semantic search, so use natural language queries rather than just keywords.

4. **Error Handling**: Always handle potential errors in your code, especially for network issues or rate limiting.

5. **Caching**: Consider caching results for common queries to improve performance and reduce API usage.

## Workflow Documentation

This repository includes detailed documentation of the process used to create this API, designed for repeatability by future AI agents with minimal human intervention. The workflow was executed by a Claude 3.7 Sonnet-powered Cursor Agent, with the documentation and scripts stored in the `workflow` directory.

### Documentation Files

1. **Data Collection and Processing**
   - [`1-scraping.md`](workflow/1-scraping.md) - Web scraping HTMX examples
   - [`2-extracting-to-json.md`](workflow/2-extracting-to-json.md) - Converting scraped data to structured JSON
   
2. **Database Setup and Data Loading**
   - [`3-creating-postgresql.md`](workflow/3-creating-postgresql.md) - Setting up PostgreSQL on Digital Ocean
   - [`4-uploading-to-postgres.md`](workflow/4-uploading-to-postgres.md) - Loading examples into the database
   
3. **Vector Embeddings and Search**
   - [`5-embedding.md`](workflow/5-embedding.md) - Generating vector embeddings
   - [`6-creating-pgsql-functions.md`](workflow/6-creating-pgsql-functions.md) - Implementing vector similarity search
   
4. **API Deployment**
   - [`7-deploying-postgrest.md`](workflow/7-deploying-postgrest.md) - Setting up and deploying the PostgREST API

### Supporting Scripts and Files

1. **Data Collection**
   - `scrape_htmx.sh` - Script for scraping HTMX examples
   - `extract_to_json.sh` - Script for JSON conversion
   - `htmx_extraction_prompt.txt` - LLM prompt for data extraction
   - `htmx_examples_schema.json` - JSON schema for examples

2. **Database Setup**
   - `setup_postgres_db.sh` - Database initialization script
   - `setup_db_users.sql` - User and role configuration
   - `init_db_schema.sql` - Database schema creation

3. **Vector Search Implementation**
   - `embed_examples.py` - Python script for generating embeddings
   - `similarity_search.sql` - Vector similarity search functions
   - `apply_search_functions.sh` - Script to apply search functions

4. **API Configuration and Deployment**
   - `setup_postgrest_config.sh` - PostgREST configuration
   - `deploy_postgrest.sh` - API deployment script
   - `setup_nginx.sh` - Nginx reverse proxy setup
   - `middleware_app.js` - Node.js middleware implementation
   - `setup_middleware.sh` - Middleware setup script
   - `deploy_middleware.sh` - Middleware deployment script

The workflow is supported by Cursor Rules in the `.cursor/rules` directory that provide additional context and guidelines for AI agents working with the codebase.

## Contributing

If you'd like to contribute to this project, please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [HTMX](https://htmx.org/) for providing the amazing examples this API indexes
- [Google AI](https://ai.google.dev/) for the embedding model
- [PostgREST](https://postgrest.org/) for the API framework
- [pgvector](https://github.com/pgvector/pgvector) for vector similarity search in PostgreSQL

