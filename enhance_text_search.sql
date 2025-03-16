-- Create an enhanced text search function that ranks results by relevance
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

-- Grant execute permission to the postgrest user
GRANT EXECUTE ON FUNCTION api.enhanced_text_search TO postgrest;
GRANT EXECUTE ON FUNCTION api.enhanced_text_search TO web_anon;

-- Create a function to search for examples by multiple keywords
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

-- Grant execute permission to the postgrest user
GRANT EXECUTE ON FUNCTION api.keyword_search TO postgrest;
GRANT EXECUTE ON FUNCTION api.keyword_search TO web_anon; 