# HTMX Examples Vector Database

This project used Cursor Agent powered by Claude Sonnet 3.7 to download HTMX examples from htmx.org, process them into structured data, and store them in a PostgreSQL database with vector embeddings. The database is set up to support vector similarity search through PostgREST.

## 🚧 API Status: Successfully Deployed! 🎉

The HTMX Examples API has been successfully deployed and is now publicly accessible at:

- **API Endpoint**: `http://167.172.232.115/`
- **Host**: `db-postgresql-nyc3-20256-do-user-18794323-0.k.db.ondigitalocean.com`
- **Port**: `25060`
- **Database**: `defaultdb`

### API Usage Examples

#### Browse All Examples
```bash
curl http://167.172.232.115/examples?limit=5
```

#### Keyword Search
```bash
curl -X POST "http://167.172.232.115/rpc/keyword_search" \
  -H "Content-Type: application/json" \
  -d '{"keywords": ["form", "validation"], "limit_results": 3}'
```

#### Vector Similarity Search
```bash
curl -X POST "http://167.172.232.115/rpc/search_examples_fixed" \
  -H "Content-Type: application/json" \
  -d '{"example_id": "inline-validation", "embedding_type": "content", "limit_results": 3}'
```

### Deploying the API on Digital Ocean

To deploy the API on a Digital Ocean Droplet and make it publicly accessible:

1. **Create a Droplet in the HTMX-Examples project**:
   ```bash
   ./create_htmx_api_droplet.sh
   ```
   This script creates a small Droplet in the HTMX-Examples project and sets up PostgREST to serve the API.

2. **Configure the `web_anon` role for passwordless access**:
   ```bash
   PGPASSWORD='your_password' psql -h db-postgresql-nyc3-20256-do-user-18794323-0.k.db.ondigitalocean.com -p 25060 -U doadmin -d defaultdb -f configure_web_anon_role.sql
   ```
   This script configures the `web_anon` role to allow passwordless connections from the PostgREST server.

3. **Update the PostgREST configuration**:
   ```bash
   ./update_postgrest_conf.sh <droplet-ip>
   ```
   This script updates the PostgREST configuration on the Droplet to use the passwordless `web_anon` role.

4. **Test the API**:
   ```bash
   curl http://<droplet-ip>/examples?limit=5
   ```

5. **Set up a domain name (optional)**:
   If you want to use a custom domain name for your API, you can set up DNS records to point to your Droplet's IP address and configure HTTPS:
   ```bash
   ssh root@<droplet-ip> 'certbot --nginx -d your-domain.com'
   ```

### Next Steps to Complete the API

✅ The API has been successfully deployed and is now publicly accessible. The following steps have been completed:

1. ✅ **Database Configuration**: The `web_anon` role has been configured with a password for authentication.
2. ✅ **PostgREST Deployment**: A PostgREST instance has been deployed on a Digital Ocean Droplet.
3. ✅ **CORS Configuration**: CORS has been configured to allow requests from any origin.
4. ✅ **Public Deployment**: The API is now publicly accessible at `http://167.172.232.115/`.

The API is now ready for use by AI agents and developers.

## 🤖 For AI Agents: How to Use This API

This API is designed to be used by AI agents like me (Claude) to retrieve relevant HTMX examples when helping users with web development tasks. Here's how I would use it:

### Example: AI Agent Workflow

When a user asks me about implementing a specific UI pattern with HTMX, I can:

1. Formulate a semantic search query based on the user's request
2. Send a request to the API endpoint
3. Analyze the results and provide relevant examples to the user

### Sample AI Agent Query and Response

**User Question:** "How can I implement form validation with HTMX?"

**AI Agent Process:**
```
1. Identify the key concept: "form validation with HTMX"
2. Formulate API request with this search query
3. Send request to the vector search endpoint
4. Receive and analyze relevant examples
5. Present the most relevant examples to the user
```

**API Request:**
```json
{
  "search_query": "form validation with HTMX",
  "embedding_type": "content",
  "limit": 3
}
```

**API Response:**
```json
[
  {
    "id": 7,
    "title": "Inline Validation",
    "url": "https://htmx.org/examples/inline-validation/",
    "description": "This example shows how to implement inline form validation with htmx",
    "category": "UI Patterns",
    "complexity_level": "intermediate",
    "similarity": 0.92
  },
  {
    "id": 15,
    "title": "Reset User Input",
    "url": "https://htmx.org/examples/reset-user-input/",
    "description": "This example shows how to reset form fields after submission",
    "category": "UI Patterns",
    "complexity_level": "beginner",
    "similarity": 0.78
  },
  {
    "id": 14,
    "title": "Preserving File Inputs after Form Errors",
    "url": "https://htmx.org/examples/file-upload-input/",
    "description": "This example shows how to preserve file inputs after form validation errors",
    "category": "UI Patterns",
    "complexity_level": "intermediate",
    "similarity": 0.76
  }
]
```

**AI Response to User:**
"For implementing form validation with HTMX, I found several relevant examples:

1. **Inline Validation** (92% match): This example demonstrates how to validate form fields as the user types, providing immediate feedback without a full page reload. [View example](https://htmx.org/examples/inline-validation/)

2. **Reset User Input** (78% match): Shows how to reset form fields after submission, which is often part of the validation workflow. [View example](https://htmx.org/examples/reset-user-input/)

3. **Preserving File Inputs after Form Errors** (76% match): Demonstrates how to maintain file input values when validation fails, improving user experience. [View example](https://htmx.org/examples/file-upload-input/)

The Inline Validation example is most relevant to your question. It uses the `hx-post` attribute to send form data to the server for validation as the user types, and then updates the UI with validation messages."

### Implementation in AI Agent Code

```python
import requests
import json

def search_htmx_examples(query, embedding_type="content", limit=3, complexity=None):
    """
    Search for HTMX examples using the vector search API.
    
    Args:
        query (str): The search query
        embedding_type (str): Type of embedding to search against
        limit (int): Maximum number of results to return
        complexity (str, optional): Filter by complexity level
        
    Returns:
        list: Relevant HTMX examples
    """
    # Connect to the HTMX Examples API
    url = "http://167.172.232.115/rpc/search_examples_fixed"
    
    payload = {
        "example_id": "inline-validation",  # Use a reference example
        "embedding_type": embedding_type,
        "limit_results": limit
    }
    
    if complexity:
        payload["complexity_level"] = complexity
    
    response = requests.post(url, json=payload)
    
    if response.status_code == 200:
        return response.json()
    else:
        return f"Error: {response.status_code} - {response.text}"

# Example usage in an AI agent
def answer_htmx_question(user_question):
    # Extract key concepts from the user's question
    search_query = extract_search_query(user_question)
    
    # Search for relevant examples
    examples = search_htmx_examples(search_query)
    
    # Format and return the response
    return format_response(user_question, examples)
```

## 🛠️ Setting Up This API as an AI Agent Tool

If you're developing an AI agent system, you can integrate this API as a tool to enhance your agent's capabilities with HTMX knowledge.

### OpenAI Function Calling Format

Here's how to define this API as a tool for OpenAI function calling:

```json
{
  "type": "function",
  "function": {
    "name": "search_htmx_examples",
    "description": "Search for HTMX examples using semantic vector search to find relevant code examples and patterns",
    "parameters": {
      "type": "object",
      "properties": {
        "example_id": {
          "type": "string",
          "description": "The ID of an existing example to use as a reference (e.g., 'inline-validation')"
        },
        "embedding_type": {
          "type": "string",
          "enum": ["content", "title", "description", "key_concepts"],
          "description": "The type of embedding to search against",
          "default": "content"
        },
        "limit_results": {
          "type": "integer",
          "description": "Maximum number of results to return",
          "default": 3
        },
        "complexity_level": {
          "type": "string",
          "enum": ["beginner", "intermediate", "advanced", null],
          "description": "Filter by complexity level",
          "default": null
        },
        "category": {
          "type": "string",
          "description": "Filter by category (e.g., 'UI Patterns', 'Dialog Examples')",
          "default": null
        }
      },
      "required": ["example_id"]
    }
  }
}
```

### LangChain Tool Definition

If you're using LangChain, here's how to define the tool:

```python
from langchain.tools import Tool
import requests

def search_htmx_examples(example_id, embedding_type="content", limit_results=3, complexity=None, category=None):
    """
    Search for HTMX examples using semantic vector search.
    
    Args:
        example_id (str): The ID of an existing example to use as a reference
        embedding_type (str): Type of embedding to search against
        limit_results (int): Maximum number of results to return
        complexity (str, optional): Filter by complexity level
        category (str, optional): Filter by category
        
    Returns:
        list: Relevant HTMX examples
    """
    # Connect to the HTMX Examples API
    url = "http://167.172.232.115/rpc/search_examples_fixed"
    
    payload = {
        "example_id": example_id,
        "embedding_type": embedding_type,
        "limit_results": limit_results
    }
    
    if complexity:
        payload["complexity_level"] = complexity
    
    if category:
        payload["category"] = category
    
    response = requests.post(url, json=payload)
    
    if response.status_code == 200:
        return response.json()
    else:
        return f"Error: {response.status_code} - {response.text}"

htmx_search_tool = Tool(
    name="search_htmx_examples",
    func=search_htmx_examples,
    description="Search for HTMX examples using semantic vector search to find relevant code examples and patterns"
)
```

### Cursor AI Tool Definition

For Cursor AI, you can define the tool like this:

```json
{
  "name": "search_htmx_examples",
  "description": "Search for HTMX examples using semantic vector search to find relevant code examples and patterns",
  "parameters": {
    "properties": {
      "search_query": {
        "description": "The natural language query to search for (e.g., 'how to implement infinite scrolling')",
        "type": "string"
      },
      "embedding_type": {
        "description": "The type of embedding to search against (content, title, description, key_concepts)",
        "type": "string"
      },
      "limit": {
        "description": "Maximum number of results to return",
        "type": "integer"
      },
      "complexity_level": {
        "description": "Filter by complexity level (beginner, intermediate, advanced)",
        "type": "string"
      }
    },
    "required": ["search_query"]
  }
}
```

## 🔍 Vector Search API (Implementation Plan)

When completed, the API will provide the following capabilities:

### Database Configuration

- **Host**: `db-postgresql-nyc3-20256-do-user-18794323-0.k.db.ondigitalocean.com`
- **Port**: `25060`
- **Database**: `defaultdb`
- **Role**: `web_anon` (will be configured for passwordless access)
- **Schema**: `api` (exposed through PostgREST)

### Required Configuration

To set up the PostgREST API, you'll need to:

1. Create a `postgrest.conf` file with the following content:
   ```
   db-uri = "postgres://web_anon@db-postgresql-nyc3-20256-do-user-18794323-0.k.db.ondigitalocean.com:25060/defaultdb"
   db-schema = "api"
   db-anon-role = "web_anon"
   server-port = 3000
   ```

2. Configure PostgreSQL to allow the `web_anon` role to connect without a password:
   ```sql
   ALTER ROLE web_anon WITH LOGIN NOINHERIT;
   GRANT USAGE ON SCHEMA api TO web_anon;
   GRANT SELECT ON ALL TABLES IN SCHEMA api TO web_anon;
   GRANT EXECUTE ON FUNCTION api.search_htmx_examples TO web_anon;
   ```

3. Start the PostgREST server:
   ```bash
   postgrest postgrest.conf
   ```

### API Endpoints

Once configured, the API will provide the following endpoints:

#### Vector Similarity Search

**Endpoint:** `/rpc/search_htmx_examples`  
**Method:** POST  
**Content-Type:** application/json

**Request Body:**
```json
{
  "search_query": "Your search query here",
  "embedding_type": "content",  // Options: "title", "description", "content", "key_concepts"
  "limit": 5,                   // Number of results to return
  "category": null,             // Optional: Filter by category
  "complexity_level": null      // Optional: Filter by complexity level (beginner, intermediate, advanced)
}
```

#### Browse All Examples

**Endpoint:** `/htmx_examples`  
**Method:** GET

### Example Usage

#### JavaScript Fetch

```javascript
// Search for examples about lazy loading
fetch('https://your-postgrest-api-endpoint/rpc/search_htmx_examples', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    search_query: 'lazy loading images',
    embedding_type: 'content',
    limit: 5
  }),
})
.then(response => response.json())
.then(data => console.log(data));
```

#### Python Requests

```python
import requests

# Search for examples about form validation
response = requests.post(
    'https://your-postgrest-api-endpoint/rpc/search_htmx_examples',
    json={
        'search_query': 'form validation',
        'embedding_type': 'content',
        'limit': 3,
        'complexity_level': 'beginner'
    }
)

results = response.json()
print(results)
```

### How It Works

The API uses PostgreSQL's vector extension with PostgREST to provide semantic search capabilities:

1. Your search query is converted to a vector embedding on the server
2. The database performs a vector similarity search against the stored embeddings
3. Results are ranked by similarity and returned as JSON
4. The `web_anon` role provides read-only access to the API schema

## 🔎 How the Vector Search Works

The vector search functionality is powered by PostgreSQL's `pgvector` extension and exposed through a custom SQL function. Here's how it works:

### Database Schema

The database contains the following key components:

1. **Schemas**:
   - `api` - Contains views and functions exposed through PostgREST
   - `openai` - Contains functions for generating embeddings
   - `public` - Contains the base tables

2. **Tables**:
   - `public.htmx_examples` - Base table storing example data
   - `public.htmx_embeddings` - Table storing vector embeddings

3. **Views**:
   - `api.examples` - View for accessing examples
   - `api.htmx_categories` - View for categories
   - `api.htmx_complexity_levels` - View for complexity levels
   - `api.htmx_examples` - View for examples

4. **Functions**:
   - `api.search_examples` - Function for vector similarity search
   - `api.search_htmx_examples` - Another function for vector similarity search
   - `openai.embed` - Function to create embeddings
   - `openai.generate_embedding` - Function to generate embeddings

#### htmx_examples

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

#### htmx_embeddings

- `id`: Unique identifier for the example (foreign key to htmx_examples)
- `title_embedding`: Vector embedding of the title
- `description_embedding`: Vector embedding of the description
- `content_embedding`: Vector embedding of the content
- `key_concepts_embedding`: Vector embedding of the key concepts

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

## Important Notes

- Never commit the `.env` file or `postgrest.conf` to version control
- The `.gitignore` file is set up to exclude these files
- Always use the example files as templates for new developers

## License

This project is for educational purposes only. The HTMX examples are owned by htmx.org. 