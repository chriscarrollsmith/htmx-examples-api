-- Enable the vector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create a table for HTMX examples
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

-- Create a table for embeddings
CREATE TABLE IF NOT EXISTS htmx_embeddings (
    id TEXT PRIMARY KEY REFERENCES htmx_examples(id),
    title_embedding VECTOR(1536),
    description_embedding VECTOR(1536),
    content_embedding VECTOR(1536),
    key_concepts_embedding VECTOR(1536),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster similarity search
CREATE INDEX IF NOT EXISTS htmx_examples_category_idx ON htmx_examples(category);
CREATE INDEX IF NOT EXISTS htmx_examples_complexity_idx ON htmx_examples(complexity_level);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically update the updated_at column
CREATE TRIGGER update_htmx_examples_updated_at
BEFORE UPDATE ON htmx_examples
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_htmx_embeddings_updated_at
BEFORE UPDATE ON htmx_embeddings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create a view that combines examples and embeddings
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
