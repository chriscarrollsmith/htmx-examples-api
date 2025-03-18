# Query Embedding and Vector Search Utility

This document outlines the implementation of a command-line utility for embedding search queries and finding similar HTMX examples using vector similarity search.

## Overview

We've created two key components:

1. **PostgreSQL Vector Search Functions** - SQL functions for performing similarity searches using pre-embedded vectors
2. **Query Embedding Utility** - A Python script that embeds a user's query and uses the SQL functions to find similar examples

This approach allows for efficient similarity searches without embedding examples on the fly during each query.

## Prerequisites

- PostgreSQL database with pgvector extension installed
- HTMX examples data with embeddings already loaded in the database
- `.env` file with database connection credentials and Google API key
- Python 3.7+

## Implementation Steps

### 1. Create PostgreSQL Vector Search Functions

First, we implemented three PostgreSQL functions for vector similarity search:

- `api.vector_search` - Searches a specific embedding type with a query vector
- `api.multi_vector_search` - Searches across all embedding types with weighted scoring
- `api.find_similar_examples` - For backward compatibility, finds examples similar to an existing one

These functions are defined in `workflow/similarity_search.sql` and can be applied using the `workflow/apply_search_functions.sh` script.

Key features of these functions:
- Support for different embedding types (content, title, description, key_concepts)
- Optional filtering by category and complexity level
- Comprehensive result data including similarity scores
- Proper permissions for the web_anon role

### 2. Implement the Query Embedding Utility

Next, we implemented a Python utility (`workflow/query_htmx.py`) that:

1. Takes a natural language query from the user
2. Embeds it using Google's Generative AI with the RETRIEVAL_QUERY task type
3. Passes the embedding vector to one of the PostgreSQL functions
4. Returns and formats the results

The utility has several command-line options:
```
usage: query_htmx.py [-h] [--embedding-type {content,title,description,key_concepts}] [--limit LIMIT] [--category CATEGORY]
                     [--complexity {beginner,intermediate,advanced}] [--detailed] [--multi-vector] [--json]
                     query
```

### Testing the Solution

1. Apply the SQL functions:
```bash
./workflow/apply_search_functions.sh
```

2. Run the query utility:
```bash
uv run workflow/query_htmx.py "dynamically load content when a button is clicked" --limit 3
```

3. Try the multi-vector search option:
```bash
uv run workflow/query_htmx.py "form validation without page refresh" --multi-vector --detailed
```

4. Output as JSON for programmatic use:
```bash
uv run workflow/query_htmx.py "lazy loading images" --json > results.json
```

## Query Embedding vs. Document Embedding

One important technical detail is that we use different task types for embedding:

- `RETRIEVAL_DOCUMENT` - Used for embedding the HTMX examples (documents)
- `RETRIEVAL_QUERY` - Used for embedding search queries

This follows best practices for retrieval systems, as queries and documents often have different characteristics and the embedding model can optimize for each use case.

## Key Technical Considerations

### 1. Vector Similarity Metric

We use cosine similarity for measuring the distance between embeddings, which is computed in PostgreSQL using the `<=>` operator from the pgvector extension. The similarity score is normalized to a 0-1 range where 1 means identical.

### 2. Multi-vector Search Weighting

For multi-vector searches, we use a weighted combination:
- 40% weight for content embedding
- 20% weight for title embedding
- 20% weight for description embedding
- 20% weight for key concepts embedding

This balances the importance of the full content with more specialized aspects of each example.

### 3. Error Handling

The utility includes comprehensive error handling for:
- Missing dependencies
- Missing environment variables
- Database connection issues
- API errors
- Non-serializable types in JSON output

## Usage Examples

### Basic Search
```bash
uv run workflow/query_htmx.py "load data without refreshing the page"
```

### Filtered Search with Category
```bash
uv run workflow/query_htmx.py "form submission" --category "Form Handling" --limit 10
```

### Detailed Output with Multi-vector Search
```bash
uv run workflow/query_htmx.py "client-side validation" --multi-vector --detailed
```

### JSON Output for Integration
```bash
uv run workflow/query_htmx.py "lazy loading" --json > results.json
```

## Conclusion

This implementation provides a flexible and efficient way to search for HTMX examples using natural language queries. The vector similarity approach allows for semantic understanding beyond simple keyword matching, helping users find relevant examples even when their query doesn't contain exact matches for titles or descriptions. 