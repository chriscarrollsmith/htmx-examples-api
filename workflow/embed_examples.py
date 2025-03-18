#!/usr/bin/env python3
"""
A simplified script to generate embeddings for HTMX examples using Google's Generative AI
and store them in PostgreSQL database.
"""

import os
import sys
import json
import time
import logging
import argparse
from typing import List, Dict, Any, Optional, Tuple
from pathlib import Path

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

try:
    # Import required libraries
    from dotenv import load_dotenv
    import psycopg
    from psycopg.rows import dict_row
    from google import genai
    from google.genai.types import EmbedContentConfig
except ImportError as e:
    logger.error(f"Missing required packages. Please run: uv add google-genai psycopg python-dotenv")
    sys.exit(1)

# Load environment variables from .env file
load_dotenv()

# Constants for Google AI
API_KEY = os.getenv("GOOGLE_API_KEY")
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT")
REGION = os.getenv("GOOGLE_CLOUD_REGION", "us-central1")
# IMPORTANT: Must use the format "models/text-embedding-004" even though 
# Google's documentation lists models like "text-embedding-004" or "textembedding-gecko@003"
MODEL = "models/text-embedding-004"
DIMENSION = 768

# Set Google GenAI environment variables
os.environ["GOOGLE_CLOUD_PROJECT"] = PROJECT_ID if PROJECT_ID else ""
os.environ["GOOGLE_CLOUD_LOCATION"] = REGION

# Database connection parameters
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_NAME = os.getenv("DB_NAME")

def connect_to_db() -> psycopg.Connection:
    """Connect to the PostgreSQL database using environment variables."""
    try:
        # Check if all required environment variables are set
        required_env_vars = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASS", "DB_NAME"]
        missing_vars = [var for var in required_env_vars if not os.getenv(var)]
        
        if missing_vars:
            raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")
        
        # Connect to the database
        conn_string = f"host={DB_HOST} port={DB_PORT} dbname={DB_NAME} user={DB_USER} password={DB_PASS}"
        conn = psycopg.connect(conn_string)
        
        logger.info(f"Successfully connected to database: {DB_NAME} on {DB_HOST}")
        return conn
    except Exception as e:
        logger.error(f"Error connecting to database: {e}")
        raise

def create_genai_client() -> genai.Client:
    """Create and configure Google Generative AI client."""
    if not API_KEY:
        raise ValueError("GOOGLE_API_KEY environment variable is not set. Please set it in the .env file.")
    
    # Create a client directly
    client = genai.Client(api_key=API_KEY)
    logger.info("Google Generative AI client created with API key")
    return client

def fetch_examples(
    conn: psycopg.Connection,
    limit: Optional[int] = None,
    filter_condition: Optional[str] = None
) -> List[Dict[str, Any]]:
    """Fetch HTMX examples from the database."""
    try:
        with conn.cursor(row_factory=dict_row) as cur:
            query = "SELECT * FROM htmx_examples"
            
            if filter_condition:
                query += f" WHERE {filter_condition}"
                
            if limit is not None:
                query += f" LIMIT {limit}"
            
            cur.execute(query)
            examples = cur.fetchall()
            
            logger.info(f"Fetched {len(examples)} examples from database")
            return examples
    except Exception as e:
        logger.error(f"Error fetching examples: {e}")
        raise

def check_embeddings_exist(
    conn: psycopg.Connection,
    example_id: str
) -> Dict[str, bool]:
    """Check if embeddings exist for a specific example."""
    try:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute("""
                SELECT 
                    id,
                    (title_embedding IS NOT NULL) AS has_title_embedding,
                    (description_embedding IS NOT NULL) AS has_description_embedding,
                    (content_embedding IS NOT NULL) AS has_content_embedding,
                    (key_concepts_embedding IS NOT NULL) AS has_key_concepts_embedding
                FROM htmx_embeddings
                WHERE id = %s
            """, (example_id,))
            
            result = cur.fetchone()
            
            if result:
                return {
                    "title_embedding": result["has_title_embedding"],
                    "description_embedding": result["has_description_embedding"],
                    "content_embedding": result["has_content_embedding"],
                    "key_concepts_embedding": result["has_key_concepts_embedding"]
                }
            else:
                # No embeddings exist for this example
                return {
                    "title_embedding": False,
                    "description_embedding": False,
                    "content_embedding": False,
                    "key_concepts_embedding": False
                }
    except Exception as e:
        logger.error(f"Error checking embeddings existence: {e}")
        raise

def prepare_example_content(example: Dict[str, Any]) -> Dict[str, str]:
    """Prepare different content types from an example for embedding generation."""
    prepared_content = {}
    
    # Title embedding
    if "title" in example and example["title"]:
        prepared_content["title"] = example["title"]
    
    # Description embedding
    if "description" in example and example["description"]:
        prepared_content["description"] = example["description"]
    
    # Key concepts embedding
    if "key_concepts" in example and example["key_concepts"]:
        if isinstance(example["key_concepts"], list):
            prepared_content["key_concepts"] = ", ".join(example["key_concepts"])
        else:
            prepared_content["key_concepts"] = str(example["key_concepts"])
    
    # Combined content embedding (most important for retrieval)
    content_parts = []
    
    if "title" in example and example["title"]:
        content_parts.append(f"Title: {example['title']}")
    
    if "description" in example and example["description"]:
        content_parts.append(f"Description: {example['description']}")
    
    if "key_concepts" in example and example["key_concepts"]:
        if isinstance(example["key_concepts"], list):
            content_parts.append(f"Key Concepts: {', '.join(example['key_concepts'])}")
        else:
            content_parts.append(f"Key Concepts: {example['key_concepts']}")
    
    if "html_snippets" in example and example["html_snippets"]:
        if isinstance(example["html_snippets"], dict):
            html_snippets = example["html_snippets"]
        else:
            try:
                html_snippets = json.loads(example["html_snippets"])
            except (json.JSONDecodeError, TypeError):
                html_snippets = {}
        
        for name, snippet in html_snippets.items():
            content_parts.append(f"HTML Snippet - {name}: {snippet}")
    
    if "javascript_snippets" in example and example["javascript_snippets"]:
        if isinstance(example["javascript_snippets"], dict):
            js_snippets = example["javascript_snippets"]
        else:
            try:
                js_snippets = json.loads(example["javascript_snippets"])
            except (json.JSONDecodeError, TypeError):
                js_snippets = {}
        
        for name, snippet in js_snippets.items():
            content_parts.append(f"JavaScript Snippet - {name}: {snippet}")
    
    if "htmx_attributes" in example and example["htmx_attributes"]:
        if isinstance(example["htmx_attributes"], list):
            content_parts.append(f"HTMX Attributes: {', '.join(example['htmx_attributes'])}")
        else:
            content_parts.append(f"HTMX Attributes: {example['htmx_attributes']}")
    
    if "demo_explanation" in example and example["demo_explanation"]:
        content_parts.append(f"Demo Explanation: {example['demo_explanation']}")
    
    if "use_cases" in example and example["use_cases"]:
        if isinstance(example["use_cases"], list):
            content_parts.append(f"Use Cases: {', '.join(example['use_cases'])}")
        else:
            content_parts.append(f"Use Cases: {example['use_cases']}")
    
    prepared_content["content"] = "\n\n".join(content_parts)
    
    return prepared_content

def generate_embedding(text: str, client: genai.Client, task_type: str = "RETRIEVAL_DOCUMENT") -> List[float]:
    """Generate embedding for text using Google's Generative AI."""
    try:
        # Create configuration
        config = EmbedContentConfig(
            task_type=task_type,
            output_dimensionality=DIMENSION,
        )
        
        # Truncate text if too long (Google AI has token limits)
        max_chars = 25000  # Approximately 7k tokens
        if len(text) > max_chars:
            text = text[:max_chars]
        
        # Call the embedding API
        response = client.models.embed_content(
            model=MODEL,
            contents=[text],
            config=config
        )
        
        # Return embedding values
        return response.embeddings[0].values
    except Exception as e:
        logger.error(f"Error generating embedding: {e}")
        raise

def generate_example_embeddings(example: Dict[str, Any], client: genai.Client, force_update: bool = False) -> Dict[str, List[float]]:
    """Generate embeddings for a single example."""
    # Prepare content for embedding
    prepared_content = prepare_example_content(example)
    result_embeddings = {}
    
    # Generate an embedding for each content type
    for content_type, content in prepared_content.items():
        if not content:
            logger.warning(f"Empty content for {content_type} in example {example['id']}")
            continue
        
        # Generate embedding
        logger.info(f"Generating {content_type} embedding for example {example['id']}")
        
        try:
            embedding = generate_embedding(content, client, task_type="RETRIEVAL_DOCUMENT")
            
            # Map content type to corresponding embedding field name
            embedding_field_name = f"{content_type}_embedding"
            result_embeddings[embedding_field_name] = embedding
            
            # Add a small delay to avoid rate limiting
            time.sleep(0.5)
            
        except Exception as e:
            logger.error(f"Error generating {content_type} embedding for example {example['id']}: {e}")
    
    return result_embeddings

def update_db_schema_for_google_ai(conn: psycopg.Connection) -> bool:
    """Update the database schema to support Google AI embeddings (768 dimensions)."""
    try:
        with conn.cursor() as cur:
            # Begin transaction
            cur.execute("BEGIN")
            
            # Check current vector dimensions
            cur.execute("""
                SELECT typelem::regtype::text 
                FROM pg_type 
                WHERE typname = 'vector'
            """)
            
            vector_type = cur.fetchone()
            if not vector_type:
                logger.error("Vector extension not enabled in the database")
                conn.rollback()
                return False
            
            # First check if we need to drop and recreate any views using these columns
            logger.info("Checking for views that depend on the embeddings table...")
            
            try:
                # Save the view definition to recreate it later
                cur.execute("""
                    SELECT definition 
                    FROM pg_views 
                    WHERE viewname = 'htmx_examples_with_embeddings'
                """)
                view_def = cur.fetchone()
                
                if view_def:
                    logger.info("Found dependent view htmx_examples_with_embeddings, dropping it temporarily...")
                    cur.execute("DROP VIEW htmx_examples_with_embeddings")
                    logger.info("View dropped successfully")
            except Exception as e:
                logger.error(f"Error checking or dropping views: {e}")
                conn.rollback()
                return False
            
            # Update the vector dimensions for each column
            alter_statements = [
                "ALTER TABLE htmx_embeddings ALTER COLUMN title_embedding TYPE VECTOR(768)",
                "ALTER TABLE htmx_embeddings ALTER COLUMN description_embedding TYPE VECTOR(768)",
                "ALTER TABLE htmx_embeddings ALTER COLUMN content_embedding TYPE VECTOR(768)",
                "ALTER TABLE htmx_embeddings ALTER COLUMN key_concepts_embedding TYPE VECTOR(768)"
            ]
            
            for statement in alter_statements:
                try:
                    cur.execute(statement)
                    logger.info(f"Executed: {statement}")
                except Exception as e:
                    logger.error(f"Error executing {statement}: {e}")
                    conn.rollback()
                    return False
            
            # Recreate the view if it existed
            if view_def:
                try:
                    logger.info("Recreating the view...")
                    cur.execute(view_def[0])
                    logger.info("View recreated successfully")
                except Exception as e:
                    logger.error(f"Error recreating view: {e}")
                    conn.rollback()
                    return False
            
            # Commit transaction
            conn.commit()
            logger.info("Successfully updated database schema for Google AI embeddings")
            
            return True
    except Exception as e:
        logger.error(f"Error updating database schema: {e}")
        return False

def batch_update_embeddings(
    conn: psycopg.Connection,
    embedding_data: List[Tuple[str, Dict[str, List[float]]]]
) -> bool:
    """Update embeddings for multiple examples in a single transaction."""
    try:
        with conn.cursor() as cur:
            # Begin transaction
            cur.execute("BEGIN")
            
            for example_id, embeddings in embedding_data:
                # Check if a row exists for this example in htmx_embeddings
                cur.execute("SELECT 1 FROM htmx_embeddings WHERE id = %s", (example_id,))
                row_exists = cur.fetchone() is not None
                
                # Prepare SQL command and values based on whether the row exists
                set_clauses = []
                values = []
                
                for embedding_type, embedding_vector in embeddings.items():
                    if embedding_type not in ["title_embedding", "description_embedding", "content_embedding", "key_concepts_embedding"]:
                        logger.warning(f"Ignoring invalid embedding type: {embedding_type}")
                        continue
                    
                    set_clauses.append(f"{embedding_type} = %s")
                    values.append(embedding_vector)
                
                if not set_clauses:
                    logger.warning(f"No valid embedding types to update for example: {example_id}")
                    continue
                
                # Build the SQL query
                if row_exists:
                    # Update existing row
                    sql = f"""
                        UPDATE htmx_embeddings
                        SET {', '.join(set_clauses)}
                        WHERE id = %s
                    """
                    values.append(example_id)
                else:
                    # Insert new row
                    sql = f"""
                        INSERT INTO htmx_embeddings
                        (id, {', '.join(embedding_type for embedding_type in embeddings.keys() if embedding_type in ["title_embedding", "description_embedding", "content_embedding", "key_concepts_embedding"])})
                        VALUES (%s, {', '.join(['%s'] * len(set_clauses))})
                    """
                    values = [example_id] + values
                
                # Execute the query
                cur.execute(sql, values)
            
            # Commit transaction
            conn.commit()
            
            logger.info(f"Successfully updated embeddings for {len(embedding_data)} examples in batch")
            return True
    except Exception as e:
        conn.rollback()
        logger.error(f"Error updating embeddings in batch: {e}")
        return False

def process_examples(
    conn: psycopg.Connection,
    client: genai.Client,
    limit: Optional[int] = None,
    filter_condition: Optional[str] = None,
    force_update: bool = False,
    batch_size: int = 10
) -> bool:
    """Process examples and generate embeddings."""
    try:
        # Fetch examples from the database
        examples = fetch_examples(conn, limit=limit, filter_condition=filter_condition)
        
        if not examples:
            logger.warning("No examples found in the database")
            return True
        
        logger.info(f"Processing {len(examples)} examples")
        
        # Process examples in batches for efficient database updates
        batch_data = []
        success_count = 0
        error_count = 0
        
        for index, example in enumerate(examples):
            example_id = example['id']
            logger.info(f"Processing example {index + 1}/{len(examples)}: {example_id}")
            
            try:
                # Check if embeddings already exist for this example
                existing_embeddings = check_embeddings_exist(conn, example_id)
                
                # Skip if all embeddings exist and force_update is False
                if all(existing_embeddings.values()) and not force_update:
                    logger.info(f"Skipping example {example_id} - embeddings already exist")
                    success_count += 1
                    continue
                
                # Generate embeddings
                embeddings = generate_example_embeddings(example, client, force_update=force_update)
                
                if not embeddings:
                    logger.warning(f"No embeddings generated for example {example_id}")
                    error_count += 1
                    continue
                
                # Add to batch data
                batch_data.append((example_id, embeddings))
                
                # Update database when batch is full or this is the last example
                if len(batch_data) >= batch_size or index == len(examples) - 1:
                    if batch_update_embeddings(conn, batch_data):
                        success_count += len(batch_data)
                    else:
                        error_count += len(batch_data)
                    
                    # Clear batch data
                    batch_data = []
                
            except Exception as e:
                logger.error(f"Error processing example {example_id}: {e}")
                error_count += 1
        
        logger.info(f"Processing completed. Success: {success_count}, Errors: {error_count}")
        return error_count == 0
    except Exception as e:
        logger.error(f"Error processing examples: {e}")
        return False

def main():
    """Main function to run the embedding generation process."""
    parser = argparse.ArgumentParser(description="Generate embeddings for HTMX examples using Google AI API")
    
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Maximum number of examples to process (default: all)"
    )
    
    parser.add_argument(
        "--filter",
        type=str,
        default=None,
        help="SQL WHERE clause to filter examples (e.g., \"category = 'buttons'\")"
    )
    
    parser.add_argument(
        "--force-update",
        action="store_true",
        help="Force update existing embeddings"
    )
    
    parser.add_argument(
        "--batch-size",
        type=int,
        default=10,
        help="Number of examples to process in a single batch update (default: 10)"
    )
    
    parser.add_argument(
        "--update-schema",
        action="store_true",
        help="Update database schema for Google AI embeddings (changes vector dimensions to 768)"
    )
    
    args = parser.parse_args()
    
    try:
        # Configure Google AI client
        client = create_genai_client()
        
        # Connect to the database
        conn = connect_to_db()
        
        # Update database schema if requested
        if args.update_schema:
            if update_db_schema_for_google_ai(conn):
                logger.info("Database schema updated successfully")
            else:
                logger.error("Failed to update database schema")
                return
        
        # Process examples
        if process_examples(
            conn=conn,
            client=client,
            limit=args.limit,
            filter_condition=args.filter,
            force_update=args.force_update,
            batch_size=args.batch_size
        ):
            logger.info("Embedding generation completed successfully")
        else:
            logger.error("Embedding generation completed with errors")
        
    except Exception as e:
        logger.error(f"Error in main function: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main() 