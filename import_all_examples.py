#!/usr/bin/env python3
"""
Import all HTMX examples from the processed_examples directory into PostgreSQL.
"""

import os
import json
import psycopg
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
required_env_vars = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASS", "DB_NAME"]
missing_vars = [var for var in required_env_vars if not os.getenv(var)]
if missing_vars:
    raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")

# Directory containing processed examples
EXAMPLES_DIR = "processed_examples"

def connect_to_db():
    """Connect to the PostgreSQL database."""
    try:
        conn_string = f"host={DB_HOST} port={DB_PORT} dbname={DB_NAME} user={DB_USER} password={DB_PASS}"
        conn = psycopg.connect(conn_string)
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        raise

def get_existing_examples(conn):
    """Get a list of example IDs already in the database."""
    with conn.cursor() as cur:
        cur.execute("SELECT id FROM htmx_examples")
        return [row[0] for row in cur.fetchall()]

def import_example(conn, file_path):
    """Import a single example from a JSON file."""
    try:
        with open(file_path, 'r') as f:
            example = json.load(f)
        
        # Check if the example has all required fields
        required_fields = ['id', 'title', 'category', 'url', 'description', 
                          'html_snippets', 'javascript_snippets', 'key_concepts', 
                          'htmx_attributes', 'demo_explanation', 'complexity_level', 'use_cases']
        
        for field in required_fields:
            if field not in example:
                print(f"  Warning: Missing required field '{field}'")
                if field in ['html_snippets', 'javascript_snippets']:
                    example[field] = []
                elif field in ['key_concepts', 'htmx_attributes', 'use_cases']:
                    example[field] = []
                else:
                    example[field] = ""
        
        # Ensure html_snippets and javascript_snippets are properly formatted as JSON strings
        if isinstance(example['html_snippets'], list):
            html_snippets_json = json.dumps(example['html_snippets'])
        else:
            html_snippets_json = example['html_snippets']
            
        if isinstance(example['javascript_snippets'], list):
            js_snippets_json = json.dumps(example['javascript_snippets'])
        else:
            js_snippets_json = example['javascript_snippets']
        
        # Insert the example into the database
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO htmx_examples (
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
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                    title = EXCLUDED.title,
                    category = EXCLUDED.category,
                    url = EXCLUDED.url,
                    description = EXCLUDED.description,
                    html_snippets = EXCLUDED.html_snippets,
                    javascript_snippets = EXCLUDED.javascript_snippets,
                    key_concepts = EXCLUDED.key_concepts,
                    htmx_attributes = EXCLUDED.htmx_attributes,
                    demo_explanation = EXCLUDED.demo_explanation,
                    complexity_level = EXCLUDED.complexity_level,
                    use_cases = EXCLUDED.use_cases,
                    updated_at = CURRENT_TIMESTAMP
            """, (
                example['id'],
                example['title'],
                example['category'],
                example['url'],
                example['description'],
                html_snippets_json,
                js_snippets_json,
                example['key_concepts'],
                example['htmx_attributes'],
                example['demo_explanation'],
                example['complexity_level'],
                example['use_cases']
            ))
            
        conn.commit()
        return True
    except Exception as e:
        print(f"  Error importing example: {e}")
        conn.rollback()
        return False

def main():
    """Main function to import all examples."""
    print("Connecting to database...")
    conn = connect_to_db()
    
    print("Getting existing examples...")
    existing_examples = get_existing_examples(conn)
    print(f"Found {len(existing_examples)} existing examples in the database.")
    
    # Get all JSON files in the examples directory
    example_files = [f for f in os.listdir(EXAMPLES_DIR) if f.endswith('.json')]
    print(f"Found {len(example_files)} example files to import.")
    
    # Import each example
    success_count = 0
    for file_name in example_files:
        example_id = file_name.replace('.json', '')
        file_path = os.path.join(EXAMPLES_DIR, file_name)
        
        print(f"Importing {example_id}...")
        if example_id in existing_examples:
            print(f"  Example {example_id} already exists, updating...")
        
        if import_example(conn, file_path):
            success_count += 1
            print(f"  Imported successfully.")
        else:
            print(f"  Failed to import {example_id}.")
    
    print(f"Import completed. {success_count} out of {len(example_files)} examples imported successfully.")
    
    # Verify the import
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM htmx_examples")
        count = cur.fetchone()[0]
        print(f"Database now contains {count} examples.")
        
        # List all examples
        print("Listing all examples:")
        cur.execute("SELECT id, title, category, complexity_level FROM htmx_examples ORDER BY category, id")
        examples = cur.fetchall()
        for example in examples:
            print(f"  {example[0]}: {example[1]} ({example[2]}, {example[3]})")
    
    conn.close()

if __name__ == "__main__":
    main() 