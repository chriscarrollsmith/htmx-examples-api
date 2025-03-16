-- HTMX Examples Search Functions
-- This file contains SQL functions for searching HTMX examples in the database.

-- =============================================
-- 1. Vector Similarity Search
-- =============================================

-- This function performs vector similarity search using an existing example as a reference point.
-- It doesn't regenerate embeddings on every call, making it more efficient.
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

-- Example usage:
-- SELECT * FROM api.search_examples_fixed('inline-validation', 'content', 5);
-- This will find examples similar to 'inline-validation' using content embeddings.

-- =============================================
-- 2. Basic Text Search
-- =============================================

-- This function performs a simple text search on examples.
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

-- Example usage:
-- SELECT * FROM api.text_search_examples('validation', 5);
-- This will find examples containing the word 'validation'.

-- =============================================
-- 3. Enhanced Text Search with Relevance Ranking
-- =============================================

-- This function performs text search and ranks results by relevance.
CREATE OR REPLACE FUNCTION api.enhanced_text_search(
    search_text text,
    limit_results int DEFAULT 5,
    category_filter text DEFAULT NULL,
    complexity_filter text DEFAULT NULL
) RETURNS TABLE(
    id text,
    title text,
    url text,
    description text,
    category text,
    complexity_level text,
    relevance numeric
) AS $$
BEGIN
    RETURN QUERY EXECUTE format('
        SELECT 
            e.id,
            e.title,
            e.url,
            e.description,
            e.category,
            e.complexity_level,
            (CASE 
                WHEN e.title ILIKE $1 THEN 1.0
                WHEN e.description ILIKE $1 THEN 0.8
                WHEN e.key_concepts::text ILIKE $1 THEN 0.6
                WHEN e.demo_explanation ILIKE $1 THEN 0.4
                ELSE 0.2
            END) AS relevance
        FROM 
            api.examples e
        WHERE 
            (e.title ILIKE $1 OR 
             e.description ILIKE $1 OR 
             e.key_concepts::text ILIKE $1 OR
             e.demo_explanation ILIKE $1)
            %s
            %s
        ORDER BY
            relevance DESC,
            CASE WHEN e.title ILIKE $1 THEN 0 ELSE 1 END,
            CASE WHEN e.description ILIKE $1 THEN 0 ELSE 1 END
        LIMIT $2
    ',
    CASE WHEN category_filter IS NOT NULL THEN 'AND e.category = $3' ELSE '' END,
    CASE WHEN complexity_filter IS NOT NULL THEN 
        CASE WHEN category_filter IS NOT NULL THEN 'AND e.complexity_level = $4' ELSE 'AND e.complexity_level = $3' END
    ELSE '' END)
    USING '%' || search_text || '%', limit_results, category_filter, complexity_filter;
END;
$$ LANGUAGE plpgsql;

-- Example usage:
-- SELECT * FROM api.enhanced_text_search('validation', 5);
-- This will find examples containing the word 'validation' and rank them by relevance.

-- =============================================
-- 4. Multi-Keyword Search
-- =============================================

-- This function searches for examples containing multiple keywords.
CREATE OR REPLACE FUNCTION api.keyword_search(
    keywords text[],
    limit_results int DEFAULT 5,
    category_filter text DEFAULT NULL,
    complexity_filter text DEFAULT NULL
) RETURNS TABLE(
    id text,
    title text,
    url text,
    description text,
    category text,
    complexity_level text,
    match_count int
) AS $$
DECLARE
    keyword text;
    query_parts text[] := '{}';
BEGIN
    -- Build query parts for each keyword
    FOREACH keyword IN ARRAY keywords LOOP
        query_parts := array_append(query_parts, 
            format('(e.title ILIKE ''%%%s%%'' OR e.description ILIKE ''%%%s%%'' OR e.key_concepts::text ILIKE ''%%%s%%'' OR e.demo_explanation ILIKE ''%%%s%%'')', 
                keyword, keyword, keyword, keyword));
    END LOOP;
    
    -- Execute the query with all keywords
    RETURN QUERY EXECUTE format('
        SELECT 
            e.id,
            e.title,
            e.url,
            e.description,
            e.category,
            e.complexity_level,
            (%s) AS match_count
        FROM 
            api.examples e
        WHERE 
            %s
            %s
            %s
        ORDER BY
            match_count DESC,
            e.title
        LIMIT $1
    ',
    array_to_string(ARRAY(SELECT format('CASE WHEN %s THEN 1 ELSE 0 END', part) FROM unnest(query_parts) AS part), ' + '),
    array_to_string(query_parts, ' OR '),
    CASE WHEN category_filter IS NOT NULL THEN 'AND e.category = $2' ELSE '' END,
    CASE WHEN complexity_filter IS NOT NULL THEN 
        CASE WHEN category_filter IS NOT NULL THEN 'AND e.complexity_level = $3' ELSE 'AND e.complexity_level = $2' END
    ELSE '' END)
    USING limit_results, category_filter, complexity_filter;
END;
$$ LANGUAGE plpgsql;

-- Example usage:
-- SELECT * FROM api.keyword_search(ARRAY['form', 'validation'], 5);
-- This will find examples containing the words 'form' or 'validation' and rank them by how many keywords they match.

-- =============================================
-- Grant Permissions
-- =============================================

-- Grant execute permissions to the postgrest user and web_anon role
GRANT EXECUTE ON FUNCTION api.search_examples_fixed TO postgrest;
GRANT EXECUTE ON FUNCTION api.search_examples_fixed TO web_anon;

GRANT EXECUTE ON FUNCTION api.text_search_examples TO postgrest;
GRANT EXECUTE ON FUNCTION api.text_search_examples TO web_anon;

GRANT EXECUTE ON FUNCTION api.enhanced_text_search TO postgrest;
GRANT EXECUTE ON FUNCTION api.enhanced_text_search TO web_anon;

GRANT EXECUTE ON FUNCTION api.keyword_search TO postgrest;
GRANT EXECUTE ON FUNCTION api.keyword_search TO web_anon;

-- =============================================
-- Required Permissions
-- =============================================

-- Note: The following permissions are required for these functions to work.
-- They should be granted by a database superuser if not already granted.

-- GRANT SELECT ON htmx_embeddings TO postgrest;
-- GRANT SELECT ON htmx_embeddings TO web_anon; 