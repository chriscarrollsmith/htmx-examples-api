## Direct Database Search Functions

The database includes several specialized search functions that provide different ways to find relevant HTMX examples. These functions are available in the `api` schema and can be called directly using psql.

### 1. Vector Similarity Search

This function performs vector similarity search using an existing example as a reference point. It doesn't regenerate embeddings on every call, making it more efficient.

```sql
-- Find examples similar to 'inline-validation' using content embeddings
SELECT id, title, url, description, complexity_level 
FROM api.search_examples_fixed('inline-validation', 'content', 5);
```

Parameters:
- `example_id`: ID of an existing example to use as a reference point
- `embedding_type`: Type of embedding to use ('content', 'title', 'description', 'key_concepts')
- `limit_results`: Maximum number of results to return
- `category`: Filter by category (optional)
- `complexity_level`: Filter by complexity level (optional)

### 2. Basic Text Search

This function performs a simple text search on examples.

```sql
-- Find examples containing the word 'validation'
SELECT id, title, url, description, complexity_level 
FROM api.text_search_examples('validation', 5);
```

Parameters:
- `search_text`: Text to search for
- `limit_results`: Maximum number of results to return
- `category`: Filter by category (optional)
- `complexity_level`: Filter by complexity level (optional)

### 3. Enhanced Text Search with Relevance Ranking

This function performs text search and ranks results by relevance based on where the search term appears.

```sql
-- Find examples containing the word 'validation' and rank by relevance
SELECT id, title, url, description, complexity_level, relevance 
FROM api.enhanced_text_search('validation', 5);
```

Parameters:
- `search_text`: Text to search for
- `limit_results`: Maximum number of results to return
- `category_filter`: Filter by category (optional)
- `complexity_filter`: Filter by complexity level (optional)

### 4. Multi-Keyword Search

This function searches for examples containing multiple keywords and ranks them by how many keywords they match.

```sql
-- Find examples containing the words 'form' or 'validation'
SELECT id, title, url, description, complexity_level, match_count 
FROM api.keyword_search(ARRAY['form', 'validation'], 5);
```

Parameters:
- `keywords`: Array of keywords to search for
- `limit_results`: Maximum number of results to return
- `category_filter`: Filter by category (optional)
- `complexity_filter`: Filter by complexity level (optional)

### Using Search Functions in PostgREST API

These functions can also be exposed through the PostgREST API, allowing you to use them in HTTP requests:

```bash
# Vector similarity search
curl -X POST "https://your-postgrest-api-endpoint/rpc/search_examples_fixed" \
  -H "Content-Type: application/json" \
  -d '{"example_id": "inline-validation", "embedding_type": "content", "limit_results": 5}'

# Multi-keyword search
curl -X POST "https://your-postgrest-api-endpoint/rpc/keyword_search" \
  -H "Content-Type: application/json" \
  -d '{"keywords": ["form", "validation"], "limit_results": 5}'
``` 