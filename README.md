# HTMX Examples Vector Database

This project downloads HTMX examples from htmx.org, processes them into structured data, and stores them in a PostgreSQL database with vector embeddings for semantic search.

## Project Structure

- `examples/` - Directory containing the downloaded HTMX examples
- `processed_examples/` - Directory containing the processed JSON files
- `download_examples.sh` - Script to download HTMX examples from htmx.org
- `process_htmx_examples.sh` - Script to process the examples using the LLM tool
- `setup_db.sh` - Script to set up the PostgreSQL database with the vector extension
- `import_simple.sh` - Script to import the processed examples into the database
- `generate_embeddings.py` - Script to generate embeddings for the examples
- `search_examples.py` - Script to perform semantic search on the examples

## Setup

1. **Download HTMX Examples**:
   ```bash
   ./download_examples.sh
   ```

2. **Process Examples**:
   ```bash
   ./process_htmx_examples.sh --direct
   ```

3. **Set Up Database**:
   ```bash
   ./setup_db.sh
   ```

4. **Configure Environment Variables**:
   Copy the example environment file and update it with your credentials:
   ```bash
   cp .env.example .env
   ```
   
   Edit the `.env` file to add your database credentials and OpenAI API key:
   ```
   # OpenAI API key
   OPENAI_API_KEY=your_openai_api_key_here
   
   # Database connection parameters
   DB_HOST=your_db_host_here
   DB_PORT=your_db_port_here
   DB_USER=your_db_user_here
   DB_PASS=your_db_password_here
   DB_NAME=your_db_name_here
   
   # PostgREST configuration
   POSTGREST_USER=your_postgrest_user_here
   POSTGREST_PASSWORD=your_postgrest_password_here
   POSTGREST_JWT_SECRET=your_jwt_secret_here
   ```

5. **Import Examples**:
   ```bash
   ./import_simple.sh
   ```

6. **Install Python Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

7. **Generate Embeddings**:
   ```bash
   python generate_embeddings.py
   ```

## Usage

### Semantic Search

Search for HTMX examples using semantic search:

```bash
./search_examples.py "How to implement infinite scrolling"
```

Options:
- `--type`: Type of embedding to search against (title, description, content, key_concepts)
- `--limit`: Maximum number of results to return
- `--category`: Filter by category
- `--complexity`: Filter by complexity level
- `--json`: Output results as JSON

Example:
```bash
./search_examples.py "How to implement infinite scrolling" --type content --limit 3 --complexity beginner
```

### PostgREST API

This project includes a PostgREST API for accessing the HTMX examples database via HTTP:

1. **Generate PostgREST Configuration**:
   ```bash
   ./generate_postgrest_conf.sh
   ```

2. **Start the PostgREST API**:
   ```bash
   docker-compose up -d
   ```

3. **Access the API**:
   The API will be available at http://localhost:3000

4. **Access the Web UI**:
   A simple web UI is available at http://localhost:8080

## Database Schema

### htmx_examples

- `id`: Unique identifier for the example
- `title`: Title of the example
- `category`: Category of the example
- `url`: URL of the example
- `description`: Description of the example
- `html_snippets`: HTML code snippets with descriptions
- `javascript_snippets`: JavaScript code snippets with descriptions
- `key_concepts`: Key HTMX concepts demonstrated in the example
- `htmx_attributes`: HTMX attributes used in the example
- `demo_explanation`: Explanation of how the demo works
- `complexity_level`: Complexity level of the example (beginner, intermediate, advanced)
- `use_cases`: Common use cases for the pattern

### htmx_embeddings

- `id`: Unique identifier for the example (foreign key to htmx_examples)
- `title_embedding`: Vector embedding of the title
- `description_embedding`: Vector embedding of the description
- `content_embedding`: Vector embedding of the content
- `key_concepts_embedding`: Vector embedding of the key concepts

## License

This project is for educational purposes only. The HTMX examples are owned by htmx.org.

## Scrape-Embed

## Environment Setup

This project uses environment variables to protect sensitive information. Follow these steps to set up your environment:

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file and add your actual credentials:
   ```
   DB_URI="your-database-connection-string"
   JWT_SECRET="your-jwt-secret"
   OPENAI_API_KEY="your-openai-api-key"
   ```

3. Generate the PostgREST configuration file:
   ```bash
   python generate_config.py
   ```

4. Make sure you have the required Python packages:
   ```bash
   pip install python-dotenv
   ```

## Important Notes

- Never commit the `.env` file or `postgrest.conf` to version control
- The `.gitignore` file is set up to exclude these files
- Always use the example files as templates for new developers

## Running the Application

[Add instructions for running your application here] 