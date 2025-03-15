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