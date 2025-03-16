-- Fix permissions for the postgrest user
GRANT SELECT ON htmx_embeddings TO postgrest;

-- Create a new version of the search_examples function that doesn't regenerate embeddings
CREATE OR REPLACE FUNCTION api.search_examples_fixed(
    example_id text,  -- Use an existing example ID as the reference point
    embedding_type text DEFAULT 'content',
    limit_results int DEFAULT 5,
    category text DEFAULT NULL,
    complexity_level text DEFAULT NULL
) RETURNS SETOF api.examples AS $$
DECLARE
    reference_embedding vector;
    embedding_column text;
BEGIN
    -- Get the embedding from an existing example instead of generating a new one
    EXECUTE format('SELECT %I FROM htmx_embeddings WHERE id = $1', 
                  CASE 
                      WHEN embedding_type = 'title' THEN 'title_embedding'
                      WHEN embedding_type = 'description' THEN 'description_embedding'
                      WHEN embedding_type = 'key_concepts' THEN 'key_concepts_embedding'
                      ELSE 'content_embedding'
                  END)
    INTO reference_embedding
    USING example_id;
    
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
    USING reference_embedding, limit_results, category, complexity_level;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to the postgrest user
GRANT EXECUTE ON FUNCTION api.search_examples_fixed TO postgrest;
GRANT EXECUTE ON FUNCTION api.search_examples_fixed TO web_anon;

-- Create a text search function as a fallback
CREATE OR REPLACE FUNCTION api.text_search_examples(
    search_text text,
    limit_results int DEFAULT 5,
    category text DEFAULT NULL,
    complexity_level text DEFAULT NULL
) RETURNS SETOF api.examples AS $$
BEGIN
    RETURN QUERY EXECUTE format('
        SELECT 
            e.*
        FROM 
            api.examples e
        WHERE 
            (e.title ILIKE $1 OR 
             e.description ILIKE $1 OR 
             e.key_concepts::text ILIKE $1 OR
             e.demo_explanation ILIKE $1)
            %s
            %s
        LIMIT $2
    ',
    CASE WHEN category IS NOT NULL THEN 'AND e.category = $3' ELSE '' END,
    CASE WHEN complexity_level IS NOT NULL THEN 
        CASE WHEN category IS NOT NULL THEN 'AND e.complexity_level = $4' ELSE 'AND e.complexity_level = $3' END
    ELSE '' END)
    USING '%' || search_text || '%', limit_results, category, complexity_level;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to the postgrest user
GRANT EXECUTE ON FUNCTION api.text_search_examples TO postgrest;
GRANT EXECUTE ON FUNCTION api.text_search_examples TO web_anon; 