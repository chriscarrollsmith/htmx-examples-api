# Creating PostgreSQL Functions for Vector Similarity Search

This document outlines the process of implementing PL/pgSQL functions for vector similarity search using pre-embedded query vectors. This approach allows for more efficient and flexible searches compared to the previous implementation that relied on example IDs.

## Overview

The solution consists of three main functions:

1. `api.vector_search` - Searches for examples similar to a provided query vector
2. `api.multi_vector_search` - Performs searches across all embedding types and combines the results
3. `api.find_similar_examples` - Finds examples similar to an existing example (backward compatibility)

These functions rely on the pgvector extension to perform vector similarity calculations using cosine distance.

## Prerequisites

- PostgreSQL database with pgvector extension installed
- HTMX examples data loaded in the database
- Embeddings generated for the examples (see [5-embedding.md](5-embedding.md))
- `.env` file with database connection credentials

## Understanding the Database Schema

The database contains two main tables:

1. `htmx_examples` - Stores the examples with their metadata
2. `htmx_embeddings` - Stores embedding vectors for different aspects of each example:
   - `title_embedding` - Embedding for the example title
   - `description_embedding` - Embedding for the example description
   - `content_embedding` - Embedding for the combined content
   - `key_concepts_embedding` - Embedding for the key concepts

Each embedding is stored as a VECTOR type with 768 dimensions (Google AI's embedding model dimension).

## Implementation Steps

### 1. Create the SQL Function Files

Create the `similarity_search.sql` file in the workflow directory:

```bash
touch workflow/similarity_search.sql
```

This file will contain all the PostgreSQL functions needed for vector similarity search.

### 2. Implement the Vector Search Functions

The `similarity_search.sql` file contains three main functions:

#### 2.1 `api.vector_search` Function

This function takes a pre-embedded query vector and finds the most similar examples:

```sql
CREATE OR REPLACE FUNCTION api.vector_search(
    query_embedding VECTOR,              -- Pre-embedded query vector
    embedding_type TEXT DEFAULT 'content', -- Type of embedding to search against
    result_limit INTEGER DEFAULT 5,      -- Maximum number of results to return
    category_filter TEXT DEFAULT NULL,   -- Optional filter by category
    complexity_filter TEXT DEFAULT NULL  -- Optional filter by complexity level
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
    similarity FLOAT                     -- Similarity score (0-1)
) AS $$
DECLARE
    embedding_column TEXT;
BEGIN
    -- Determine which embedding column to use
    CASE embedding_type
        WHEN 'title' THEN embedding_column := 'title_embedding';
        WHEN 'description' THEN embedding_column := 'description_embedding';
        WHEN 'key_concepts' THEN embedding_column := 'key_concepts_embedding';
        ELSE embedding_column := 'content_embedding';
    END CASE;
    
    -- Return the most similar examples
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
            emb.%I <=> $1  -- Cosine distance (lower is more similar)
        LIMIT $4
    ', embedding_column, embedding_column)
    USING query_embedding, category_filter, complexity_filter, result_limit;
END;
$$ LANGUAGE plpgsql;
```

Key features:
- Takes a pre-embedded query vector as input
- Allows selection of which embedding type to search against
- Provides optional filtering by category and complexity level
- Returns full example data along with similarity scores

#### 2.2 `api.multi_vector_search` Function

This function performs searches across all embedding types and combines the results:

```sql
CREATE OR REPLACE FUNCTION api.multi_vector_search(
    query_embedding VECTOR,             -- Pre-embedded query vector
    result_limit INTEGER DEFAULT 5,     -- Maximum number of results to return
    category_filter TEXT DEFAULT NULL,  -- Optional filter by category
    complexity_filter TEXT DEFAULT NULL -- Optional filter by complexity level
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
    similarity FLOAT,                 -- Combined similarity score
    content_similarity FLOAT,         -- Individual similarity scores for transparency
    title_similarity FLOAT,
    description_similarity FLOAT,
    key_concepts_similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY EXECUTE format('
        WITH content_results AS (
            SELECT 
                e.id,
                (1 - (emb.content_embedding <=> $1))::FLOAT AS similarity
            FROM 
                htmx_examples e
            JOIN 
                htmx_embeddings emb ON e.id = emb.id
            WHERE 
                ($2 IS NULL OR e.category = $2)
            AND
                ($3 IS NULL OR e.complexity_level = $3)
        ),
        title_results AS (
            SELECT 
                e.id,
                (1 - (emb.title_embedding <=> $1))::FLOAT AS similarity
            FROM 
                htmx_examples e
            JOIN 
                htmx_embeddings emb ON e.id = emb.id
            WHERE 
                ($2 IS NULL OR e.category = $2)
            AND
                ($3 IS NULL OR e.complexity_level = $3)
        ),
        description_results AS (
            SELECT 
                e.id,
                (1 - (emb.description_embedding <=> $1))::FLOAT AS similarity
            FROM 
                htmx_examples e
            JOIN 
                htmx_embeddings emb ON e.id = emb.id
            WHERE 
                ($2 IS NULL OR e.category = $2)
            AND
                ($3 IS NULL OR e.complexity_level = $3)
        ),
        key_concepts_results AS (
            SELECT 
                e.id,
                (1 - (emb.key_concepts_embedding <=> $1))::FLOAT AS similarity
            FROM 
                htmx_examples e
            JOIN 
                htmx_embeddings emb ON e.id = emb.id
            WHERE 
                ($2 IS NULL OR e.category = $2)
            AND
                ($3 IS NULL OR e.complexity_level = $3)
        ),
        combined_results AS (
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
                COALESCE(cr.similarity * 0.4, 0) + 
                COALESCE(tr.similarity * 0.2, 0) + 
                COALESCE(dr.similarity * 0.2, 0) + 
                COALESCE(kr.similarity * 0.2, 0) AS combined_similarity,
                cr.similarity AS content_similarity,
                tr.similarity AS title_similarity,
                dr.similarity AS description_similarity,
                kr.similarity AS key_concepts_similarity
            FROM 
                htmx_examples e
            LEFT JOIN content_results cr ON e.id = cr.id
            LEFT JOIN title_results tr ON e.id = tr.id
            LEFT JOIN description_results dr ON e.id = dr.id
            LEFT JOIN key_concepts_results kr ON e.id = kr.id
            WHERE
                ($2 IS NULL OR e.category = $2)
            AND
                ($3 IS NULL OR e.complexity_level = $3)
        )
        SELECT *
        FROM combined_results
        ORDER BY combined_similarity DESC
        LIMIT $4
    ')
    USING query_embedding, category_filter, complexity_filter, result_limit;
END;
$$ LANGUAGE plpgsql;
```

Key features:
- Searches across all embedding types in a single query
- Uses weighted combination of scores (40% content, 20% title, 20% description, 20% key concepts)
- Returns individual similarity scores for each embedding type for transparency
- Provides optional filtering by category and complexity level

#### 2.3 Backward Compatibility with `api.find_similar_examples`

To maintain backward compatibility, we also implement a function that finds examples similar to an existing example:

```sql
CREATE OR REPLACE FUNCTION api.find_similar_examples(
    example_id TEXT,                    -- Example ID to find similar examples to
    embedding_type TEXT DEFAULT 'content', -- Type of embedding to use
    result_limit INTEGER DEFAULT 5,     -- Maximum number of results to return
    category_filter TEXT DEFAULT NULL,  -- Optional filter by category
    complexity_filter TEXT DEFAULT NULL -- Optional filter by complexity level
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
    similarity FLOAT                    -- Similarity score (0-1)
) AS $$
DECLARE
    reference_embedding VECTOR;
    embedding_column TEXT;
BEGIN
    -- Determine which embedding column to use
    CASE embedding_type
        WHEN 'title' THEN embedding_column := 'title_embedding';
        WHEN 'description' THEN embedding_column := 'description_embedding';
        WHEN 'key_concepts' THEN embedding_column := 'key_concepts_embedding';
        ELSE embedding_column := 'content_embedding';
    END CASE;
    
    -- Get the embedding from the example
    EXECUTE format('
        SELECT emb.%I 
        FROM htmx_embeddings emb 
        WHERE emb.id = $1
    ', embedding_column)
    INTO reference_embedding
    USING example_id;
    
    -- If we couldn't find an embedding, return an empty result
    IF reference_embedding IS NULL THEN
        RAISE NOTICE 'No embedding found for example ID: %', example_id;
        RETURN;
    END IF;
    
    -- Return similar examples, excluding the reference example itself
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
            e.id != $2
        AND
            ($3 IS NULL OR e.category = $3)
        AND
            ($4 IS NULL OR e.complexity_level = $4)
        ORDER BY 
            emb.%I <=> $1
        LIMIT $5
    ', embedding_column, embedding_column)
    USING reference_embedding, example_id, category_filter, complexity_filter, result_limit;
END;
$$ LANGUAGE plpgsql;
```

### 3. Grant Permissions

To ensure that the web_anon role can execute the functions, we add the following grants:

```sql
-- Grant execute permissions to the web_anon role
GRANT EXECUTE ON FUNCTION api.vector_search TO web_anon;
GRANT EXECUTE ON FUNCTION api.multi_vector_search TO web_anon;
GRANT EXECUTE ON FUNCTION api.find_similar_examples TO web_anon;
```

### 4. Create Deployment Script

To facilitate easy deployment of the functions, we create a bash script `apply_search_functions.sh` that:

1. Loads database credentials from the `.env` file
2. Executes the SQL file
3. Tests the functions to ensure they're working correctly

## Testing the Functions

To test the functions, we can use the following commands:

```bash
# Find examples similar to an existing example
source .env && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
"SELECT id, title, similarity FROM api.find_similar_examples('active-search', 'content', 3);" -t | cat

# Verify the vector_search function exists
source .env && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
"SELECT COUNT(*) FROM pg_proc WHERE proname = 'vector_search' AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'api');" -t | cat

# Verify permissions
source .env && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
"SELECT proname, proacl FROM pg_proc WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'api') AND proname IN ('vector_search', 'multi_vector_search', 'find_similar_examples');" -t | cat
```

## Challenges and Solutions

### Challenge 1: Working with Pre-embedded Vectors

**Problem:** Unlike the previous implementation that required generating embeddings on the fly or using example IDs, our new approach needed to work with pre-embedded query vectors.

**Solution:** Created a dedicated function `api.vector_search` that takes a vector parameter directly, allowing clients to pass pre-embedded queries.

### Challenge 2: Supporting Multiple Embedding Types

**Problem:** Different types of searches might benefit from different embedding types (title, description, content, key concepts).

**Solution:** 
1. Added an `embedding_type` parameter to select which embedding column to use
2. Created a more sophisticated `api.multi_vector_search` function that searches across all embedding types and combines the results using weighted scoring

### Challenge 3: Ensuring Backward Compatibility

**Problem:** Existing code might rely on the ability to find examples similar to a specific example ID.

**Solution:** Implemented `api.find_similar_examples` to maintain backward compatibility while allowing migration to the more flexible approach using pre-embedded vectors.

### Challenge 4: Testing Vector Search Functions

**Problem:** It's difficult to test functions that require vector inputs directly from the command line.

**Solution:** Created a testing script that:
1. Verifies function existence using PostgreSQL system catalogs
2. Tests the backward-compatible function with an existing example ID
3. Verifies permissions to ensure the web_anon role can execute the functions

## Usage Examples

### 1. Basic Vector Search

```sql
-- Assuming you have a query embedding vector
SELECT * FROM api.vector_search(
    query_embedding, -- Pre-embedded query vector
    'content',       -- Type of embedding to search against
    5,               -- Maximum number of results
    NULL,            -- Optional category filter
    NULL             -- Optional complexity filter
);
```

### 2. Multi-embedding Search

```sql
-- Search across all embedding types
SELECT * FROM api.multi_vector_search(
    query_embedding, -- Pre-embedded query vector
    5,               -- Maximum number of results
    NULL,            -- Optional category filter
    NULL             -- Optional complexity filter
);
```

### 3. Finding Similar Examples

```sql
-- Find examples similar to an existing example
SELECT * FROM api.find_similar_examples(
    'inline-validation', -- Example ID to find similar examples to
    'content',           -- Type of embedding to use
    5,                   -- Maximum number of results
    NULL,                -- Optional category filter
    NULL                 -- Optional complexity filter
);
```

## Next Steps

1. **Create a web service API endpoint** that generates embeddings for user queries and calls these functions
2. **Implement caching** for frequently used query embeddings to reduce embedding API calls
3. **Add filtering options** for more advanced search capabilities
4. **Create indexes** on the embedding columns for better performance on large datasets

## Deploying the Solution

To deploy the similarity search functions:

```bash
# Make the script executable
chmod +x workflow/apply_search_functions.sh

# Run the script to deploy and test the functions
./workflow/apply_search_functions.sh
```

This will:
1. Apply the SQL functions to the database
2. Test them to ensure they're working correctly
3. Display the results of the tests

## Query Embedding and Vector Search Utility

To test the PostgreSQL vector search functions, we've created a **Query Embedding Utility** - a Python utility (`workflow/query_htmx.py`) that:

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

1. Run the query utility:
```bash
uv run workflow/query_htmx.py "dynamically load content when a button is clicked" --limit 3
```

2. Try the multi-vector search option:
```bash
uv run workflow/query_htmx.py "form validation without page refresh" --multi-vector --detailed
```

3. Output as JSON for programmatic use:
```bash
uv run workflow/query_htmx.py "lazy loading images" --json > results.json
```

## Query Embedding vs. Document Embedding

One important technical detail is that we use different task types for embedding:

- `RETRIEVAL_DOCUMENT` - Used for embedding the HTMX examples (documents)
- `RETRIEVAL_QUERY` - Used for embedding search queries

This follows best practices for retrieval systems, as queries and documents often have different characteristics and the embedding model can optimize for each use case. Note, however, that Google also has a `CODE_RETRIEVAL_QUERY` task type that can be used for embedding queries for code-specific retrieval tasks. We haven't implemented this yet, but it would be a good addition for searching the actual HTMX code examples.

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