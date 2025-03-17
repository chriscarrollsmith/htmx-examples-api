#!/usr/bin/env python3
"""
Upload HTMX examples to PostgreSQL database.

This script reads HTMX examples from JSON files and uploads them to a PostgreSQL database.
It uses environment variables from a .env file for database connection details.
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Any, Optional

import psycopg
from dotenv import load_dotenv


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Upload HTMX examples to PostgreSQL database")
    parser.add_argument(
        "--examples-dir",
        type=str,
        default="processed_examples",
        help="Directory containing processed examples (default: processed_examples)",
    )
    parser.add_argument(
        "--env-file",
        type=str,
        default=".env",
        help="Environment file path (default: .env)",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output",
    )
    return parser.parse_args()


def load_env_vars(env_file: str) -> Dict[str, str]:
    """Load environment variables from .env file."""
    if not os.path.exists(env_file):
        print(f"Error: Environment file {env_file} not found")
        sys.exit(1)
    
    load_dotenv(env_file)
    
    required_vars = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASS", "DB_NAME"]
    env_vars = {}
    
    for var in required_vars:
        value = os.getenv(var)
        if not value:
            print(f"Error: Required environment variable {var} not found in {env_file}")
            sys.exit(1)
        env_vars[var] = value
    
    return env_vars


def connect_to_db(env_vars: Dict[str, str]) -> psycopg.Connection:
    """Connect to PostgreSQL database."""
    try:
        conn = psycopg.connect(
            host=env_vars["DB_HOST"],
            port=env_vars["DB_PORT"],
            user=env_vars["DB_USER"],
            password=env_vars["DB_PASS"],
            dbname=env_vars["DB_NAME"],
        )
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        sys.exit(1)


def get_existing_examples(conn: psycopg.Connection) -> List[str]:
    """Get list of existing examples in the database."""
    with conn.cursor() as cur:
        cur.execute("SELECT id FROM htmx_examples")
        return [row[0] for row in cur.fetchall()]


def get_example_files(examples_dir: str) -> List[Path]:
    """Get list of example JSON files."""
    examples_path = Path(examples_dir)
    if not examples_path.exists() or not examples_path.is_dir():
        print(f"Error: Examples directory {examples_dir} not found or is not a directory")
        sys.exit(1)
    
    return list(examples_path.glob("*.json"))


def load_example(file_path: Path) -> Dict[str, Any]:
    """Load example from JSON file."""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            example = json.load(f)
            # Add the file stem as the ID if not present
            if "id" not in example:
                example["id"] = file_path.stem
            return example
    except Exception as e:
        print(f"Error loading example from {file_path}: {e}")
        return None


def import_example(conn: psycopg.Connection, example: Dict[str, Any], verbose: bool) -> Optional[str]:
    """Import example into database."""
    # Extract fields from example
    example_id = example.get("id", "")
    title = example.get("title", "")
    category = example.get("category", "")
    url = example.get("url", "")
    description = example.get("description", "")
    html_snippets = json.dumps(example.get("html_snippets", []))
    javascript_snippets = json.dumps(example.get("javascript_snippets", []))
    key_concepts = example.get("key_concepts", [])
    htmx_attributes = example.get("htmx_attributes", [])
    demo_explanation = example.get("demo_explanation", "")
    complexity_level = example.get("complexity_level", "beginner")
    use_cases = example.get("use_cases", [])
    
    # Insert example into database
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO htmx_examples (
                    id, title, category, url, description, html_snippets, javascript_snippets,
                    key_concepts, htmx_attributes, demo_explanation, complexity_level, use_cases
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
                """,
                (
                    example_id, title, category, url, description, html_snippets, javascript_snippets,
                    key_concepts, htmx_attributes, demo_explanation, complexity_level, use_cases
                ),
            )
            conn.commit()
            
            if verbose:
                print(f"Imported example: {title}")
            
            return example_id
    except Exception as e:
        conn.rollback()
        print(f"Error importing example {title}: {e}")
        return None


def main():
    """Main function."""
    args = parse_args()
    
    # Load environment variables
    print(f"Loading environment variables from {args.env_file}")
    env_vars = load_env_vars(args.env_file)
    
    # Connect to database
    print("Connecting to database")
    conn = connect_to_db(env_vars)
    
    # Get existing examples
    existing_examples = get_existing_examples(conn)
    print(f"Found {len(existing_examples)} existing examples in database")
    
    # Get example files
    example_files = get_example_files(args.examples_dir)
    print(f"Found {len(example_files)} example files to import")
    
    # Import examples
    imported_count = 0
    skipped_count = 0
    error_count = 0
    
    for file_path in example_files:
        example_id = file_path.stem
        
        # Skip if example already exists
        if example_id in existing_examples:
            if args.verbose:
                print(f"Skipping existing example: {example_id}")
            skipped_count += 1
            continue
        
        # Load example
        example = load_example(file_path)
        if not example:
            error_count += 1
            continue
        
        # Import example
        result_id = import_example(conn, example, args.verbose)
        if result_id:
            imported_count += 1
        else:
            error_count += 1
    
    # Print summary
    print("\nImport summary:")
    print(f"  - Imported: {imported_count}")
    print(f"  - Skipped: {skipped_count}")
    print(f"  - Errors: {error_count}")
    print(f"  - Total examples in database: {len(existing_examples) + imported_count}")
    
    # List all examples in database
    with conn.cursor() as cur:
        cur.execute("""
            SELECT id, title, category, complexity_level 
            FROM htmx_examples 
            ORDER BY category, complexity_level, title
        """)
        print("\nExamples in database:")
        for row in cur.fetchall():
            id, title, category, complexity = row
            print(f"  - {id}: {title} ({category}, {complexity})")
    
    # Close connection
    conn.close()


if __name__ == "__main__":
    main() 