# Embedding HTMX Examples with Google AI API

This document outlines the process of generating embeddings for HTMX examples using Google AI's text embedding models and storing them in a PostgreSQL database for similarity search.

## Overview

The embedding process involves:

1. **Authentication** with Google AI API using an API key
2. **Generating embeddings** for HTMX examples using Google's text embedding models
3. **Storing embeddings** in a PostgreSQL database with pgvector extension
4. **Preparing for similarity searches** to find related examples

## Prerequisites

- PostgreSQL database with pgvector extension installed
- Google Cloud project with Vertex AI API enabled
- Google AI Studio API key (requires human intervention via browser)
- Python 3.8+ with required packages

## Quick Start

1. Ensure you have Google Cloud authentication:
   ```bash
   gcloud auth login
   ```

2. **[REQUIRES HUMAN INTERVENTION]** Obtain a Google AI API key:
   - Visit https://aistudio.google.com/app/apikey in your browser
   - Create a new API key or use an existing one
   - Copy the API key and add it to your .env file as GOOGLE_API_KEY

3. Install required dependencies:
   ```bash
   uv add google-genai psycopg python-dotenv
   ```

4. Update the database schema (if needed):
   ```bash
   uv run workflow/embed_examples.py --update-schema
   ```

5. Generate embeddings for all examples:
   ```bash
   uv run workflow/embed_examples.py
   ```

## Setup

### 1. Install Required Python Packages

```bash
uv add google-genai psycopg python-dotenv
```

### 2. Configure Environment Variables

Create or update the `.env` file with the following variables:

```
# Database Connection
DB_HOST=your_db_host
DB_PORT=your_db_port
DB_USER=your_db_user
DB_PASS=your_db_password
DB_NAME=your_db_name

# Google Cloud
GOOGLE_CLOUD_PROJECT=your_gcp_project_id
GOOGLE_CLOUD_REGION=us-central1
GOOGLE_API_KEY=your_api_key
```

To obtain a Google AI API key:

**[REQUIRES HUMAN INTERVENTION]**
1. Visit https://aistudio.google.com/app/apikey in your web browser
2. Sign in with your Google account if not already signed in
3. Create a new API key or use an existing one
4. Copy the API key and add it to your .env file

Note: Unlike other Google Cloud services, the Google AI API key cannot be obtained through the CLI and requires browser access to the Google AI Studio website.

### 3. Update Database Schema for Google AI Embeddings

The Google AI embedding models produce 768-dimensional vectors, while the default schema might be configured for OpenAI's 1536-dimensional vectors. Run the script with the `--update-schema` flag to update the table schema:

```bash
uv run workflow/embed_examples.py --update-schema
```

## Solution

We've created a simplified solution that combines all functionality into a single script: `workflow/embed_examples.py`.

This script provides:

1. **Database connectivity** - Connects to PostgreSQL with proper error handling
2. **Google AI configuration** - Sets up the Google AI client with your API key
3. **Content preparation** - Extracts and formats content from examples for embedding
4. **Embedding generation** - Creates embeddings using Google's embedding models
5. **Database storage** - Stores the embeddings efficiently with batch processing

## Usage

### Generating Embeddings for All Examples

```bash
uv run workflow/embed_examples.py
```

This will:
1. Connect to the database
2. Fetch all HTMX examples
3. Generate embeddings for each example (title, description, content, key concepts)
4. Store the embeddings in the database

### Command-Line Options

```
--limit INTEGER        Maximum number of examples to process (default: all)
--filter TEXT          SQL WHERE clause to filter examples (e.g., "category = 'buttons'")
--force-update         Force update existing embeddings
--batch-size INTEGER   Number of examples to process in a single batch (default: 10)
--update-schema        Update database schema for Google AI embeddings
```

Examples:

```bash
# Process only the first 5 examples
uv run workflow/embed_examples.py --limit 5

# Process only examples in the 'events' category
uv run workflow/embed_examples.py --filter "category = 'events'"

# Force update all embeddings, even if they already exist
uv run workflow/embed_examples.py --force-update

# Use a larger batch size for efficiency
uv run workflow/embed_examples.py --batch-size 20
```

## Implementation

We use a single script approach (`embed_examples.py`) that handles:
- Database connectivity
- Google AI authentication
- Content preparation and extraction
- Embedding generation
- Database storage

The script generates embeddings for four different aspects of each example:
1. Title
2. Description
3. Key concepts
4. Combined content (including code snippets)

These embeddings enable powerful semantic search across your HTMX examples collection.

## Validating Embeddings

After running the script, you can validate that the embeddings were successfully created and stored in the database by using the following PostgreSQL queries:

### 1. Count Total Embeddings

```bash
source .env && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) FROM htmx_embeddings;" -t | cat
```

This should match the total number of examples:

```bash
source .env && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) FROM htmx_examples;" -t | cat
```

### 2. Verify Complete Embeddings

Check that all examples have all four embedding types:

```bash
source .env && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) FROM htmx_embeddings WHERE title_embedding IS NOT NULL AND description_embedding IS NOT NULL AND content_embedding IS NOT NULL AND key_concepts_embedding IS NOT NULL;" -t | cat
```

### 3. Examine Embedding Format

You can inspect the actual embedding vectors to confirm they're in the expected format (arrays of floating-point numbers):

```bash
source .env && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT id, title_embedding::text FROM htmx_embeddings LIMIT 1;" -t | cat
```

This will display the embedding as a 768-dimensional vector of floating-point values.

> **Note**: Always use the `| cat` pipe at the end of your psql commands to avoid pagination issues with large result sets.

## How It Works

### 1. Content Preparation

The script prepares different types of content from each example:

- **Title**: The example's title
- **Description**: The example's description
- **Key Concepts**: Important concepts from the example
- **Combined Content**: A comprehensive text that includes title, description, HTML snippets, JavaScript snippets, HTMX attributes, and other metadata

### 2. Embedding Generation

For each content type, the script generates an embedding using Google's embedding model with the RETRIEVAL_DOCUMENT task type. This task type is optimized for content that will be searched over.

```python
from google import genai
from google.genai.types import EmbedContentConfig

# Initialize the client
client = genai.Client(api_key="YOUR_API_KEY")

# Create configuration
config = EmbedContentConfig(
    task_type="RETRIEVAL_DOCUMENT",
    output_dimensionality=768
)

# Generate embedding
response = client.models.embed_content(
    model="models/text-embedding-004",  # IMPORTANT: Use this exact format
    contents=[text],
    config=config
)

# Access the embedding values
embedding = response.embeddings[0].values
```

> **Important Note**: Despite Google's official documentation listing model names like `text-embedding-004` or `textembedding-gecko@003`, the API currently requires using the format `models/text-embedding-004`. If you encounter errors like `404 NOT_FOUND` or `INVALID_ARGUMENT`, make sure you're using the correct model name format.

### 3. Database Storage

The script stores the embeddings in the PostgreSQL database, using batch operations for efficiency:

- Check if embeddings already exist for each example
- Skip examples with existing embeddings (unless --force-update is used)
- Process examples in batches to minimize database transactions
- Use proper error handling and transaction management

## PostgreSQL Schema

The database uses the pgvector extension to store and query embedding vectors:

```sql
CREATE TABLE htmx_embeddings (
    id TEXT PRIMARY KEY REFERENCES htmx_examples(id),
    title_embedding VECTOR(768),
    description_embedding VECTOR(768),
    content_embedding VECTOR(768),
    key_concepts_embedding VECTOR(768),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## Error Handling

The implementation includes robust error handling:

- Validation of environment variables and inputs
- Detailed logging of errors and warnings
- Transaction management for database operations
- Content truncation to prevent exceeding token limits

## Security Considerations

- Never hardcode credentials in scripts
- Store sensitive information in environment variables or .env file
- Use the principle of least privilege for service accounts
- Validate and sanitize inputs for database queries

## Next Steps

After generating embeddings, you can:

1. Create similarity search functions in PostgreSQL
2. Build a search API using the similarity functions
3. Create a UI for searching HTMX examples

## Troubleshooting

### Common Issues

1. **Authentication Errors**:
   - Check that your API key is valid and properly copied from https://aistudio.google.com/app/apikey
   - Ensure you have access to Google AI Studio services with your Google account
   - Verify the API key is correctly set in the .env file as GOOGLE_API_KEY
   - Note that access tokens from `gcloud auth print-access-token` do NOT work for Google AI Studio - you must use an API key

2. **Model Name Format Errors**:
   - Use the format `models/text-embedding-004` for the model name
   - Do NOT use the format listed in Google's documentation like `text-embedding-004` or `textembedding-gecko@003`
   - If you see errors about "unexpected model name format" or "model not found", this is likely the issue

3. **Database Connection Errors**:
   - Confirm database credentials are correct
   - Check that the database is accessible from your network
   - Verify the pgvector extension is installed

4. **API Errors**:
   - Verify the model name is in the correct format
   - Ensure your content doesn't exceed token limits
   - Check for rate limiting issues

### Logging

The script includes comprehensive logging. To see more detailed output, you can adjust the logging level:

```python
logging.basicConfig(
    level=logging.DEBUG,  # Change from INFO to DEBUG
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
```

## References

- [Google AI Embeddings Documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/embeddings/get-text-embeddings)
- [PostgreSQL pgvector Extension](https://github.com/pgvector/pgvector)
- [Google Cloud Authentication Documentation](https://cloud.google.com/docs/authentication)
