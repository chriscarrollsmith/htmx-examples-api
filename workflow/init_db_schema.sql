-- Initialize database schema for HTMX examples and embeddings
-- This script creates tables, indexes, functions, and views for storing and querying HTMX examples

-- Enable vector extension for embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Create table for HTMX examples
CREATE TABLE IF NOT EXISTS htmx_examples (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    url TEXT NOT NULL,
    description TEXT NOT NULL,
    html_snippets JSONB NOT NULL,
    javascript_snippets JSONB NOT NULL,
    key_concepts TEXT[] NOT NULL,
    htmx_attributes TEXT[] NOT NULL,
    demo_explanation TEXT,
    complexity_level TEXT CHECK (complexity_level IN ('beginner', 'intermediate', 'advanced')),
    use_cases TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster searches
CREATE INDEX IF NOT EXISTS htmx_examples_category_idx ON htmx_examples(category);
CREATE INDEX IF NOT EXISTS htmx_examples_complexity_idx ON htmx_examples(complexity_level);

-- Create table for embeddings
CREATE TABLE IF NOT EXISTS htmx_embeddings (
    id TEXT PRIMARY KEY REFERENCES htmx_examples(id),
    title_embedding VECTOR(1536),
    description_embedding VECTOR(1536),
    content_embedding VECTOR(1536),
    key_concepts_embedding VECTOR(1536),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to update updated_at timestamp
CREATE TRIGGER update_htmx_examples_updated_at
BEFORE UPDATE ON htmx_examples
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_htmx_embeddings_updated_at
BEFORE UPDATE ON htmx_embeddings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create view for examples with embeddings
CREATE OR REPLACE VIEW htmx_examples_with_embeddings AS
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
    emb.title_embedding,
    emb.description_embedding,
    emb.content_embedding,
    emb.key_concepts_embedding,
    e.created_at,
    e.updated_at
FROM
    htmx_examples e
LEFT JOIN
    htmx_embeddings emb ON e.id = emb.id;

-- Create API schema for PostgREST
CREATE SCHEMA IF NOT EXISTS api;

-- Create view for examples in API schema
CREATE OR REPLACE VIEW api.examples AS
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
    use_cases,
    created_at,
    updated_at
FROM
    htmx_examples;

-- Grant permissions to web_anon role (for PostgREST)
-- Create web_anon role if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'web_anon') THEN
        CREATE ROLE web_anon NOLOGIN;
    END IF;
END
$$;

-- Grant usage on schemas
GRANT USAGE ON SCHEMA public TO web_anon;
GRANT USAGE ON SCHEMA api TO web_anon;

-- Grant select on views
GRANT SELECT ON api.examples TO web_anon;
GRANT SELECT ON htmx_examples_with_embeddings TO web_anon;

-- Grant select on tables
GRANT SELECT ON htmx_examples TO web_anon;
GRANT SELECT ON htmx_embeddings TO web_anon; 