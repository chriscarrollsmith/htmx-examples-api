#!/usr/bin/env python3
"""
Utility script to embed a search query and find the most similar HTMX examples
using the same embedding model as used for the examples.
"""

import os
import sys
import json
import argparse
import logging
from typing import List, Dict, Any, Optional

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

# Constants for Google AI - same as in embed_examples.py
API_KEY = os.getenv("GOOGLE_API_KEY")
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT")
REGION = os.getenv("GOOGLE_CLOUD_REGION", "us-central1")
MODEL = "models/text-embedding-004"  # Must use this format
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

def generate_query_embedding(query: str, client: genai.Client) -> List[float]:
    """Generate embedding for a query using Google's Generative AI."""
    try:
        # Create configuration - use RETRIEVAL_QUERY task type for queries
        config = EmbedContentConfig(
            task_type="RETRIEVAL_QUERY",  # Different task type for queries
            output_dimensionality=DIMENSION,
        )
        
        # Truncate query if too long (unlikely for a query, but just in case)
        max_chars = 25000
        if len(query) > max_chars:
            query = query[:max_chars]
        
        # Call the embedding API
        response = client.models.embed_content(
            model=MODEL,
            contents=[query],
            config=config
        )
        
        # Return embedding values
        return response.embeddings[0].values
    except Exception as e:
        logger.error(f"Error generating query embedding: {e}")
        raise

def search_similar_examples(
    conn: psycopg.Connection, 
    query_embedding: List[float],
    embedding_type: str = "content",
    limit: int = 5,
    category_filter: Optional[str] = None,
    complexity_filter: Optional[str] = None
) -> List[Dict[str, Any]]:
    """Find examples similar to the query embedding using the vector_search function."""
    try:
        with conn.cursor(row_factory=dict_row) as cur:
            # Execute the api.vector_search function with the query embedding
            query = """
                SELECT * FROM api.vector_search(
                    %s::vector,  -- query_embedding
                    %s,          -- embedding_type
                    %s,          -- result_limit
                    %s,          -- category_filter
                    %s           -- complexity_filter
                )
            """
            
            # Execute query
            cur.execute(
                query, 
                (query_embedding, embedding_type, limit, category_filter, complexity_filter)
            )
            
            # Fetch and return results
            results = cur.fetchall()
            logger.info(f"Found {len(results)} similar examples")
            return results
    except Exception as e:
        logger.error(f"Error searching for similar examples: {e}")
        raise

def search_using_multi_vector(
    conn: psycopg.Connection, 
    query_embedding: List[float],
    limit: int = 5,
    category_filter: Optional[str] = None,
    complexity_filter: Optional[str] = None
) -> List[Dict[str, Any]]:
    """Find examples similar to the query embedding using the multi_vector_search function."""
    try:
        with conn.cursor(row_factory=dict_row) as cur:
            # Execute the api.multi_vector_search function with the query embedding
            query = """
                SELECT * FROM api.multi_vector_search(
                    %s::vector,  -- query_embedding
                    %s,          -- result_limit
                    %s,          -- category_filter
                    %s           -- complexity_filter
                )
            """
            
            # Execute query
            cur.execute(
                query, 
                (query_embedding, limit, category_filter, complexity_filter)
            )
            
            # Fetch and return results
            results = cur.fetchall()
            logger.info(f"Found {len(results)} similar examples using multi-vector search")
            return results
    except Exception as e:
        logger.error(f"Error searching with multi-vector: {e}")
        raise

def format_results(results: List[Dict[str, Any]], detailed: bool = False) -> str:
    """Format search results for display."""
    if not results:
        return "No matching examples found."
    
    formatted_output = []
    
    for i, example in enumerate(results):
        # Basic information always included
        example_info = [
            f"#{i+1}: {example['title']} (similarity: {example['similarity']:.2f})",
            f"ID: {example['id']}",
            f"Category: {example['category']}",
            f"URL: {example['url']}",
            f"Description: {example['description']}"
        ]
        
        # Add more details if requested
        if detailed:
            if example.get('key_concepts'):
                example_info.append(f"Key Concepts: {', '.join(example['key_concepts'])}")
            
            if example.get('htmx_attributes'):
                example_info.append(f"HTMX Attributes: {', '.join(example['htmx_attributes'])}")
            
            if example.get('complexity_level'):
                example_info.append(f"Complexity: {example['complexity_level']}")
            
            # Add HTML snippets summary
            if example.get('html_snippets'):
                html_count = len(example['html_snippets']) if isinstance(example['html_snippets'], list) else 1
                example_info.append(f"HTML Snippets: {html_count} snippet(s) available")
            
            # Add JavaScript snippets summary
            if example.get('javascript_snippets'):
                js_count = len(example['javascript_snippets']) if isinstance(example['javascript_snippets'], list) else 1
                example_info.append(f"JavaScript Snippets: {js_count} snippet(s) available")
        
        formatted_output.append("\n".join(example_info))
    
    return "\n\n".join(formatted_output)

def main():
    """Main function to run the query embedding and similarity search."""
    parser = argparse.ArgumentParser(description="Embed a search query and find similar HTMX examples")
    
    parser.add_argument(
        "query",
        type=str,
        help="Search query to embed and use for finding similar examples"
    )
    
    parser.add_argument(
        "--embedding-type",
        type=str,
        choices=["content", "title", "description", "key_concepts"],
        default="content",
        help="Type of embedding to search against (default: content)"
    )
    
    parser.add_argument(
        "--limit",
        type=int,
        default=5,
        help="Maximum number of results to return (default: 5)"
    )
    
    parser.add_argument(
        "--category",
        type=str,
        help="Filter results by category"
    )
    
    parser.add_argument(
        "--complexity",
        type=str,
        choices=["beginner", "intermediate", "advanced"],
        help="Filter results by complexity level"
    )
    
    parser.add_argument(
        "--detailed",
        action="store_true",
        help="Show detailed information about each example"
    )
    
    parser.add_argument(
        "--multi-vector",
        action="store_true",
        help="Use multi-vector search (searches across all embedding types)"
    )
    
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results in JSON format"
    )
    
    args = parser.parse_args()
    
    try:
        # Configure Google AI client
        client = create_genai_client()
        
        # Connect to the database
        conn = connect_to_db()
        
        # Generate embedding for the query
        logger.info(f"Generating embedding for query: {args.query}")
        query_embedding = generate_query_embedding(args.query, client)
        
        # Find similar examples
        if args.multi_vector:
            results = search_using_multi_vector(
                conn=conn,
                query_embedding=query_embedding,
                limit=args.limit,
                category_filter=args.category,
                complexity_filter=args.complexity
            )
        else:
            results = search_similar_examples(
                conn=conn,
                query_embedding=query_embedding,
                embedding_type=args.embedding_type,
                limit=args.limit,
                category_filter=args.category,
                complexity_filter=args.complexity
            )
        
        # Output results
        if args.json:
            # Output as JSON
            json_results = []
            for result in results:
                # Convert any non-serializable types
                result_dict = dict(result)
                for key, value in result_dict.items():
                    if isinstance(value, (list, dict)):
                        continue
                    elif isinstance(value, (bytes, memoryview)):
                        result_dict[key] = str(value)
                json_results.append(result_dict)
            
            print(json.dumps(json_results, indent=2))
        else:
            # Output formatted text
            print(format_results(results, detailed=args.detailed))
        
    except Exception as e:
        logger.error(f"Error in main function: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main() 