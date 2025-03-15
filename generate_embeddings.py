#!/usr/bin/env python3
"""
Generate embeddings for HTMX examples and store them in PostgreSQL.
"""

import os
import json
import psycopg
import openai
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database connection parameters from environment variables
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_NAME = os.getenv("DB_NAME")

# Check if all required environment variables are set
required_env_vars = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASS", "DB_NAME", "OPENAI_API_KEY"]
missing_vars = [var for var in required_env_vars if not os.getenv(var)]
if missing_vars:
    raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")

# OpenAI API key
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# Initialize OpenAI client
client = openai.OpenAI(api_key=OPENAI_API_KEY)

def connect_to_db():
    """Connect to the PostgreSQL database."""
    try:
        conn_string = f"host={DB_HOST} port={DB_PORT} dbname={DB_NAME} user={DB_USER} password={DB_PASS}"
        conn = psycopg.connect(conn_string)
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        raise

def get_examples(conn):
    """Get all examples from the database."""
    with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
        cur.execute("SELECT * FROM htmx_examples")
        return cur.fetchall()

def generate_embedding(text):
    """Generate an embedding for the given text using OpenAI's API."""
    try:
        response = client.embeddings.create(
            model="text-embedding-3-small",
            input=text,
            dimensions=1536
        )
        return response.data[0].embedding
    except Exception as e:
        print(f"Error generating embedding: {e}")
        raise

def prepare_text_for_embedding(example):
    """Prepare text from an example for embedding."""
    # Title embedding
    title_text = example["title"]
    
    # Description embedding
    description_text = example["description"]
    
    # Content embedding (combine HTML snippets, key concepts, and demo explanation)
    # Check if html_snippets is already a list/dict or needs to be parsed from JSON string
    html_snippets = example["html_snippets"]
    if isinstance(html_snippets, str):
        html_snippets = json.loads(html_snippets)
    
    # Handle HTML snippets safely
    html_code_parts = []
    html_description_parts = []
    
    for snippet in html_snippets:
        if isinstance(snippet, dict):
            if "code" in snippet:
                html_code_parts.append(snippet["code"])
            if "description" in snippet or "explanation" in snippet:
                desc = snippet.get("description", snippet.get("explanation", ""))
                html_description_parts.append(desc)
    
    html_code = "\n".join(html_code_parts)
    html_descriptions = "\n".join(html_description_parts)
    
    # Handle JavaScript snippets safely
    js_snippets = example["javascript_snippets"]
    if isinstance(js_snippets, str):
        js_snippets = json.loads(js_snippets)
    
    js_code_parts = []
    js_description_parts = []
    
    for snippet in js_snippets:
        if isinstance(snippet, dict):
            if "code" in snippet:
                js_code_parts.append(snippet["code"])
            if "description" in snippet or "explanation" in snippet:
                desc = snippet.get("description", snippet.get("explanation", ""))
                js_description_parts.append(desc)
    
    js_code = "\n".join(js_code_parts)
    js_descriptions = "\n".join(js_description_parts)
    
    # Combine all text elements
    key_concepts = ", ".join(example["key_concepts"]) if example["key_concepts"] else ""
    htmx_attributes = ", ".join(example["htmx_attributes"]) if example["htmx_attributes"] else ""
    demo_explanation = example["demo_explanation"] if example["demo_explanation"] else ""
    
    content_text = f"""
    HTML Code:
    {html_code}
    
    HTML Descriptions:
    {html_descriptions}
    
    JavaScript Code:
    {js_code}
    
    JavaScript Descriptions:
    {js_descriptions}
    
    Key Concepts:
    {key_concepts}
    
    HTMX Attributes:
    {htmx_attributes}
    
    Demo Explanation:
    {demo_explanation}
    """
    
    # Key concepts embedding
    key_concepts_text = key_concepts
    
    return {
        "title": title_text,
        "description": description_text,
        "content": content_text,
        "key_concepts": key_concepts_text
    }

def store_embeddings(conn, example_id, embeddings):
    """Store embeddings in the database."""
    with conn.cursor() as cur:
        # Check if embeddings already exist for this example
        cur.execute("SELECT id FROM htmx_embeddings WHERE id = %s", (example_id,))
        exists = cur.fetchone()
        
        if exists:
            # Update existing embeddings
            cur.execute("""
                UPDATE htmx_embeddings
                SET 
                    title_embedding = %s,
                    description_embedding = %s,
                    content_embedding = %s,
                    key_concepts_embedding = %s,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
            """, (
                embeddings["title"],
                embeddings["description"],
                embeddings["content"],
                embeddings["key_concepts"],
                example_id
            ))
        else:
            # Insert new embeddings
            cur.execute("""
                INSERT INTO htmx_embeddings (
                    id,
                    title_embedding,
                    description_embedding,
                    content_embedding,
                    key_concepts_embedding
                ) VALUES (%s, %s, %s, %s, %s)
            """, (
                example_id,
                embeddings["title"],
                embeddings["description"],
                embeddings["content"],
                embeddings["key_concepts"]
            ))
        
        conn.commit()

def main():
    """Main function to generate and store embeddings."""
    print("Connecting to database...")
    conn = connect_to_db()
    
    print("Getting examples from database...")
    examples = get_examples(conn)
    print(f"Found {len(examples)} examples.")
    
    for i, example in enumerate(examples):
        example_id = example["id"]
        print(f"Processing example {i+1}/{len(examples)}: {example_id}")
        
        try:
            # Prepare text for embedding
            texts = prepare_text_for_embedding(example)
            
            # Generate embeddings
            print(f"  Generating embeddings...")
            embeddings = {
                "title": generate_embedding(texts["title"]),
                "description": generate_embedding(texts["description"]),
                "content": generate_embedding(texts["content"]),
                "key_concepts": generate_embedding(texts["key_concepts"])
            }
            
            # Store embeddings
            print(f"  Storing embeddings...")
            store_embeddings(conn, example_id, embeddings)
            
            print(f"  Done with {example_id}")
        except Exception as e:
            print(f"  Error processing example {example_id}: {e}")
            continue
    
    print("All embeddings generated and stored successfully.")
    conn.close()

if __name__ == "__main__":
    main() 