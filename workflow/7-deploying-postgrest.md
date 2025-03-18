# Deploying PostgREST API with Embedding Middleware

This document outlines the process of deploying a PostgREST API with middleware that embeds search queries using Google AI and provides a RESTful interface for searching HTMX examples with vector similarity.

## Overview

The architecture consists of:

1. **PostgreSQL Database** - Stores HTMX examples and their vector embeddings
2. **PostgREST** - Provides a REST API for the PostgreSQL database
3. **Node.js Middleware** - Handles query embedding using Google AI
4. **Nginx** - Acts as a reverse proxy

The middleware sits between clients and PostgREST, intercepting search requests, generating embeddings for queries using Google AI, and passing those embeddings to PostgREST for vector similarity search.

## Prerequisites

- Digital Ocean Droplet (Ubuntu 22.04)
- Digital Ocean PostgreSQL database (set up in previous steps)
- Google AI API key (for generating embeddings)
- Database credentials and environment variables

**Note:** All required environment variables (e.g., DB_HOST, DB_PORT, DB_NAME, POSTGREST_PASSWORD, POSTGREST_JWT_SECRET, etc.) must be placed in the project root's `.env` file. The deployment script automatically loads them from that file.

## Deployment Process

### 1. Researching the Solution

Before implementation, we thoroughly researched several key aspects:

1. **Existing Workflow**: Reviewed the workflow steps 1-6 to understand the data pipeline, database schema, and embedding process.
2. **Python Implementation**: Analyzed `query_htmx.py` to understand how to embed queries using Google AI.
3. **PostgREST Deployment Files**: Examined legacy deployment files to learn from previous attempts and identify best practices.

Key findings from this research:
- Google AI's text embedding model (`text-embedding-004`) is used for generating 768-dimensional embeddings
- The database contains several vector similarity search functions in the `api` schema
- Previous PostgREST deployment attempts had issues with configuration and permissions
- A middleware approach is preferred over direct database embedding

### 2. Setting Up PostgREST

#### Installing PostgREST

```bash
# Create directory for PostgREST
mkdir -p /opt/postgrest
cd /opt/postgrest

# Download and extract PostgREST
wget https://github.com/PostgREST/postgrest/releases/download/v12.2.8/postgrest-v12.2.8-linux-static-x64.tar.xz
tar -xf postgrest-v12.2.8-linux-static-x64.tar.xz
rm postgrest-v12.2.8-linux-static-x64.tar.xz
```

#### Configuring PostgREST

+ **Note:** If the `POSTGREST_USER` variable is not set in the `.env` file, the deployment script defaults to using `web_anon` as the database role.

Create a configuration file (`postgrest.conf`):

```bash
cat > /opt/postgrest/postgrest.conf << EOF
# PostgreSQL connection string
db-uri = "postgres://web_anon:${POSTGREST_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=require"

# The database schema to expose to REST clients
db-schema = "api"

# The database role to use when executing commands
db-anon-role = "web_anon"

# JWT secret for authentication (if needed)
jwt-secret = "${POSTGREST_JWT_SECRET}"

# Server settings
server-port = 3001
server-host = "127.0.0.1"  # Only listen on localhost, as Nginx will proxy requests

# The maximum number of rows to return from a request
max-rows = 100

# Additional schema paths
db-extra-search-path = "public"
EOF
```

#### Creating a Systemd Service

```bash
cat > /etc/systemd/system/postgrest.service << EOF
[Unit]
Description=PostgREST API Server
After=network.target

[Service]
ExecStart=/opt/postgrest/postgrest /opt/postgrest/postgrest.conf
Restart=always
User=root
Group=root
WorkingDirectory=/opt/postgrest
Environment="PGRST_JWT_SECRET=${POSTGREST_JWT_SECRET}"

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable postgrest
systemctl start postgrest
```

### 3. Implementing the Middleware

#### Setting Up Node.js Environment

```bash
# Install Node.js (newer version)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
npm install -g pm2

# Create directory for middleware
mkdir -p /opt/htmx-middleware
cd /opt/htmx-middleware

# Initialize project and install dependencies
npm init -y
npm install express axios dotenv @google/generative-ai winston
```

#### Creating the Middleware Application

The middleware's `app.js` implements:
1. A function to generate embeddings using Google AI
2. Endpoints for search and multi-search that embed queries and forward to PostgREST
3. A proxy for all other requests to PostgREST
4. Logging and error handling

Key implementation details:

```javascript
// Function to generate embeddings
async function generateEmbedding(text) {
  const model = genAI.getGenerativeModel({ model: "models/text-embedding-004" });
  
  const embeddingResult = await model.embedContent({
    content: text,
    taskType: "RETRIEVAL_QUERY",
    title: "HTMX search query",
  });
  
  return embeddingResult.embedding.values;
}

// Search endpoint
app.get('/api/search', async (req, res) => {
  // Generate embedding for query
  const embedding = await generateEmbedding(req.query.q);
  
  // Call PostgREST with the embedding
  const response = await axios.post(`${POSTGREST_URL}/rpc/vector_search`, {
    query_embedding: embedding,
    embedding_type: embeddingType,
    result_limit: limit,
    category_filter: category,
    complexity_filter: complexity
  });
  
  res.json(response.data);
});
```

#### Setting Up Process Management with PM2

```bash
cat > /opt/htmx-middleware/ecosystem.config.js << EOF
module.exports = {
  apps : [{
    name: "htmx-middleware",
    script: "app.js",
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: "200M",
    env: {
      NODE_ENV: "production"
    }
  }]
};
EOF

# Start the middleware
cd /opt/htmx-middleware
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### 4. Configuring Nginx as Reverse Proxy

```bash
cat > /etc/nginx/sites-available/htmx-api << EOF
server {
    listen 80;
    server_name _;

    # Middleware API
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Optional: Direct PostgREST access (if needed)
    location /direct/ {
        proxy_pass http://localhost:3001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the configuration
ln -s /etc/nginx/sites-available/htmx-api /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
```

### 5. Setting Up Monitoring and Maintenance

```bash
# Create monitoring script
cat > /opt/htmx-middleware/check_services.sh << EOF
#!/bin/bash

# Check PostgREST
if ! systemctl is-active --quiet postgrest; then
    echo "PostgREST is down, restarting..."
    systemctl restart postgrest
fi

# Check Middleware
if ! pm2 show htmx-middleware | grep -q "online"; then
    echo "Middleware is down, restarting..."
    cd /opt/htmx-middleware && pm2 restart htmx-middleware
fi

# Check Nginx
if ! systemctl is-active --quiet nginx; then
    echo "Nginx is down, restarting..."
    systemctl restart nginx
fi
EOF

chmod +x /opt/htmx-middleware/check_services.sh

# Set up cron job for monitoring
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/htmx-middleware/check_services.sh >> /var/log/service_checks.log 2>&1") | crontab -
```

## Testing the API

### Testing Basic Functionality

```bash
# Test PostgREST directly
curl http://localhost:3001/

# Test middleware health
curl http://localhost:3000/health

# Test search endpoint
curl "http://localhost:3000/api/search?q=How%20to%20implement%20tabs"

# Test multi-search endpoint
curl "http://localhost:3000/api/multi-search?q=How%20to%20implement%20tabs"

# Test through Nginx
curl "http://$DROPLET_IP/api/search?q=How%20to%20implement%20tabs"
```

### Example API Requests

#### Basic Search

```
GET /api/search?q=How to implement infinite scroll&limit=3&embedding_type=content
```

This request:
1. Receives the query "How to implement infinite scroll"
2. Generates an embedding using Google AI
3. Calls the `api.vector_search` function with the embedding
4. Returns the top 3 most similar examples

#### Multi-Vector Search

```
GET /api/multi-search?q=Form validation with htmx&limit=5&category=UI%20Patterns
```

This request:
1. Generates an embedding for "Form validation with htmx"
2. Searches across all embedding types (title, description, content, key_concepts)
3. Returns the top 5 most similar examples from the "UI Patterns" category

## Debugging and Troubleshooting

### Common Issues

1. **Database Connection Problems**:
   - Check connection string in the PostgREST configuration
   - Verify that the `web_anon` role exists and has the correct permissions
   - Test direct database connection: `PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" | cat`

2. **Middleware Embedding Issues**:
   - Check Google AI API key: `curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $GOOGLE_API_KEY" "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent"`
   - Check middleware logs: `cat /opt/htmx-middleware/error.log`

3. **PostgREST Configuration Issues**:
   - Check systemd logs: `journalctl -u postgrest -n 50`
   - Verify that the functions exist in the `api` schema: `PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT proname FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'api';" | cat`

## Security Considerations

1. **API Key Protection**:
   - Store the Google AI API key in the `.env` file
   - Restrict file permissions: `chmod 600 /opt/htmx-middleware/.env`

2. **Firewall Configuration**:
   ```bash
   ufw allow 22
   ufw allow 80
   ufw allow 443
   ufw enable
   ```

3. **SSL/TLS Setup** (if you have a domain):
   ```bash
   certbot --nginx -d your-domain.com
   ```

## Challenges and Solutions

### Challenge 1: Google AI API Integration

The original `query_htmx.py` used the Google AI Python SDK, but for the Node.js middleware, we had to adapt the embedding generation to use the Google AI Node.js library. The key challenge was understanding the correct parameters:

- **Solution**: Used the `@google/generative-ai` package with the correct model name format (`models/text-embedding-004`) and task type (`RETRIEVAL_QUERY`).

### Challenge 2: PostgREST Configuration

Previous deployment attempts showed issues with database connection strings, especially with special characters in passwords.

- **Solution**: Used environment variables and proper escaping in the connection string, making sure to include `sslmode=require` for secure connections to the DigitalOcean database.

### Challenge 3: Middleware Error Handling

Embedding API calls could fail due to rate limits, network issues, or invalid input.

- **Solution**: Implemented robust error handling and logging in the middleware to gracefully handle and report all types of errors.

## Performance Optimization

1. **Connection Pooling**: The middleware maintains persistent connections to PostgREST for better performance.

2. **Embedding Optimization**: Requests are processed asynchronously to handle multiple concurrent embedding requests.

3. **Caching Opportunities**: For frequently used queries, implementing a caching mechanism could further improve performance.

## Conclusion

This deployment provides a robust API for embedding search queries and performing vector similarity searches against the HTMX examples database. The architecture follows best practices with clear separation of concerns:

- **PostgreSQL** handles data storage and vector similarity search
- **PostgREST** exposes database functions as a RESTful API
- **Node.js Middleware** handles embedding generation
- **Nginx** manages routing and acts as a reverse proxy

The resulting API allows applications to search for HTMX examples semantically, finding the most relevant examples regardless of exact keyword matches.
