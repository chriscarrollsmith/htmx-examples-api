#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v "^#" .env | xargs)
else
    echo "Error: .env file not found. Please create one based on .env.example"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ] || \
   [ -z "$POSTGREST_USER" ] || [ -z "$POSTGREST_PASSWORD" ] || [ -z "$POSTGREST_JWT_SECRET" ] || [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: Missing required environment variables in .env file."
    echo "Please make sure all required variables are set."
    exit 1
fi

# Generate the PostgREST configuration file
echo "Generating PostgREST configuration file..."
./generate_postgrest_conf.sh

# Set up the database schema and roles for PostgREST
echo "Setting up database schema and roles for PostgREST..."

# Create the API schema
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
CREATE SCHEMA IF NOT EXISTS api;
"

# Create the web_anon role
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'web_anon') THEN
        CREATE ROLE web_anon NOLOGIN;
    END IF;
END
\$\$;
"

# Create the postgrest role
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'postgrest') THEN
        CREATE ROLE postgrest LOGIN PASSWORD '$POSTGREST_PASSWORD';
    ELSE
        ALTER ROLE postgrest WITH PASSWORD '$POSTGREST_PASSWORD';
    END IF;
END
\$\$;
"

# Grant permissions
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
GRANT USAGE ON SCHEMA api TO web_anon;
GRANT USAGE ON SCHEMA api TO postgrest;
GRANT ALL ON SCHEMA api TO postgrest;
GRANT web_anon TO postgrest;
"

# Create views in the API schema
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
CREATE OR REPLACE VIEW api.examples AS
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
    e.use_cases
FROM 
    htmx_examples e;

GRANT SELECT ON api.examples TO web_anon;
"

# Create search function in the API schema
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
CREATE OR REPLACE FUNCTION api.search_examples(
    query text,
    embedding_type text DEFAULT 'content',
    limit_results int DEFAULT 5,
    category text DEFAULT NULL,
    complexity_level text DEFAULT NULL
) RETURNS SETOF api.examples AS \$\$
DECLARE
    query_embedding vector;
    embedding_column text;
BEGIN
    -- Generate embedding for the query using OpenAI
    SELECT openai.generate_embedding(query) INTO query_embedding;
    
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
    USING query_embedding, limit_results, category, complexity_level;
END;
\$\$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION api.search_examples TO web_anon;
"

echo "PostgREST API setup completed successfully."
echo "You can now start the PostgREST API using: docker-compose up -d"

