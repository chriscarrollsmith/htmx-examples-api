-- =========================================================
-- HTMX Examples Vector Similarity Search Functions
-- =========================================================
-- This file contains PL/pgSQL functions for performing vector 
-- similarity search on HTMX examples using pre-computed embeddings.

-- Function to search using an existing embedding vector 
-- (for direct querying with pre-embedded vectors)
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
    similarity FLOAT                     -- Cosine similarity score (0-1)
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

-- Multi-embedding search function that performs searches across multiple embedding types
-- and combines the results with a ranking algorithm
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

-- Function to find similar examples to an existing example
-- This doesn't regenerate embeddings on every call, making it more efficient
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

-- Grant execute permissions to the web_anon role
GRANT EXECUTE ON FUNCTION api.vector_search TO web_anon;
GRANT EXECUTE ON FUNCTION api.multi_vector_search TO web_anon;
GRANT EXECUTE ON FUNCTION api.find_similar_examples TO web_anon; 