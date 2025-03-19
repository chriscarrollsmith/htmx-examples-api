# Deploying PostgREST API with Embedding Middleware

This document outlines the process of deploying a PostgREST API with middleware that embeds search queries using Google AI and provides a RESTful interface for searching HTMX examples with vector similarity.

## Overview

The architecture consists of:

1. **PostgreSQL Database** - Stores HTMX examples and their vector embeddings
2. **PostgREST** - Provides a REST API for the PostgreSQL database
3. **Node.js Middleware** - Handles query embedding using Google AI
4. **Nginx** - Acts as a reverse proxy

The middleware sits between clients and PostgREST, intercepting search requests, generating embeddings for queries using Google AI, and passing those embeddings to PostgREST for vector similarity search.

This document provides two approaches to deployment:
1. A step-by-step manual process with detailed explanations
2. Automated deployment using provided scripts for rapid setup

For most deployments, the automated scripts in the `workflow` directory (`setup_middleware.sh`, `deploy_middleware.sh`, and `setup_nginx.sh`) are recommended for their reliability and consistency.

## Prerequisites

- Digital Ocean Droplet (Ubuntu 22.04)
- Digital Ocean PostgreSQL database (set up in previous steps)
- Google AI API key (for generating embeddings)
- Database credentials and environment variables
- SSH access to the droplet (see SSH Key Setup below)

**Note:** All required environment variables (e.g., DB_HOST, DB_PORT, DB_NAME, POSTGREST_PASSWORD, POSTGREST_JWT_SECRET, etc.) must be placed in the project root's `.env` file. The deployment script automatically loads them from that file.

### Verify or Generate Required Credentials

Before deploying PostgREST, you need to check if the required security credentials are already set in your `.env` file:

1. Check if `POSTGREST_PASSWORD` and `POSTGREST_JWT_SECRET` are already set and non-empty:
   ```bash
   source .env
   
   # Check if POSTGREST_PASSWORD is set
   if [ -z "$POSTGREST_PASSWORD" ]; then
     echo "POSTGREST_PASSWORD is not set, generating a new one..."
     POSTGREST_PASSWORD=$(openssl rand -base64 24)
     echo "Generated password: $POSTGREST_PASSWORD"
     echo "POSTGREST_PASSWORD=$POSTGREST_PASSWORD" >> .env
     
     # Since the password is new, we need to update the database
     echo "Updating web_anon role with new password..."
     PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "ALTER ROLE web_anon WITH PASSWORD '$POSTGREST_PASSWORD';"
   else
     echo "POSTGREST_PASSWORD is already set"
   fi
   
   # Check if POSTGREST_JWT_SECRET is set
   if [ -z "$POSTGREST_JWT_SECRET" ]; then
     echo "POSTGREST_JWT_SECRET is not set, generating a new one..."
     POSTGREST_JWT_SECRET=$(openssl rand -base64 32)
     echo "Generated JWT secret: $POSTGREST_JWT_SECRET"
     echo "POSTGREST_JWT_SECRET=$POSTGREST_JWT_SECRET" >> .env
   else
     echo "POSTGREST_JWT_SECRET is already set"
   fi
   ```

2. If you need to manually generate these credentials because they are not set in your `.env` file:
   
   **POSTGREST_JWT_SECRET** - A secure key used for JWT authentication:
   ```bash
   openssl rand -base64 32
   ```
   Example output: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

   **POSTGREST_PASSWORD** - A secure password for the web_anon database role:
   ```bash
   openssl rand -base64 24
   ```
   Example output: `xxxxxxxxxxxxxxxxxxxxxxxx`

After generating these credentials, add them to your `.env` file:
```
POSTGREST_PASSWORD=your_generated_password
POSTGREST_JWT_SECRET=your_generated_jwt_secret
```

Then update the database with the new password for the web_anon role:
```bash
source .env
PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "ALTER ROLE web_anon WITH PASSWORD '$POSTGREST_PASSWORD';"
```

3. After verifying or generating credentials, make sure you can connect to the database as the `web_anon` user:
   ```bash
   source .env
   PGPASSWORD=$POSTGREST_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $POSTGREST_USER -d $DB_NAME -c "SELECT 1;"
   ```

### SSH Key Setup

If you followed the steps in the previous workflow, you should already have an SSH key pair set up for connecting to the Digital Ocean droplet. If not, you will need to follow the fixup steps below to generate and import a new SSH key pair.

1. **Generate an SSH key pair on your local machine**:
   ```bash
   # Option A: Generate key in default location
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -N ""
   
   # Option B: Generate key in custom location
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f ~/.ssh/id_rsa_do -N ""
   ```
   Copy the public key content from your console, as you will need it to add your key to an existing droplet.

2. To add your key to an existing droplet, you must:

   a. Log into your droplet via the Digital Ocean web console (in the Digital Ocean dashboard, select your droplet and click "Console")
   
   b. Once logged in, create the SSH directory (if it doesn't exist) and add your public key to the authorized_keys file:
   ```bash
   mkdir -p ~/.ssh
   echo "YOUR_PUBLIC_KEY_CONTENT" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys

   # Verify by checking the contents
   cat ~/.ssh/authorized_keys
   ```
   Replace `YOUR_PUBLIC_KEY_CONTENT` with the content you copied in step 1.

4. **Test your SSH connection**:
   ```bash
   # If using Option A (default location)
   doctl compute ssh $DROPLET_ID --ssh-command "echo 'SSH Access Successful'"

   # If using Option B (custom location)
   doctl compute ssh $DROPLET_ID --ssh-key-path ~/.ssh/id_rsa_do --ssh-command "echo 'SSH Access Successful'"
   ```

**Note:** For new droplets, you can select the SSH key during the creation process, and it will be automatically added to the droplet's authorized_keys file.

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
# Note: Make sure to use the correct URL for the latest version
wget https://github.com/PostgREST/postgrest/releases/download/v12.2.8/postgrest-v12.2.8-linux-static-x86-64.tar.xz
tar -xf postgrest-v12.2.8-linux-static-x86-64.tar.xz
chmod +x postgrest
rm postgrest-v12.2.8-linux-static-x86-64.tar.xz
```

#### Configuring PostgREST

+ **Note:** If the `POSTGREST_USER` variable is not set in the `.env` file, the deployment script defaults to using `web_anon` as the database role.

Create a configuration file (`postgrest.conf`):

```bash
# Create the configuration file
cat > /opt/postgrest/postgrest.conf << EOF
# PostgreSQL connection string
db-uri = "postgres://${POSTGREST_USER}:${POSTGREST_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=require"

# The database schema to expose to REST clients
db-schema = "api"

# The database role to use when executing commands
db-anon-role = "${POSTGREST_USER}"

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

If you're having issues with heredocs on the remote server, you can create the configuration file in multiple steps:

```bash
# Step 1: Create the basic file structure
cd /opt/postgrest
echo "# PostgreSQL connection string" > postgrest.conf
echo "db-uri = \"postgres://$POSTGREST_USER:$POSTGREST_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=require\"" >> postgrest.conf

# Step 2: Add schema and role settings
echo -e "\n# The database schema to expose to REST clients\ndb-schema = \"api\"\n\n# The database role to use when executing commands\ndb-anon-role = \"$POSTGREST_USER\"" >> postgrest.conf

# Step 3: Add JWT secret
echo -e "\n# JWT secret for authentication\njwt-secret = \"$POSTGREST_JWT_SECRET\"" >> postgrest.conf

# Step 4: Add server settings and other configuration
echo -e "\n# Server settings\nserver-port = 3001\nserver-host = \"127.0.0.1\"  # Only listen on localhost, as Nginx will proxy requests\n\n# The maximum number of rows to return from a request\nmax-rows = 100\n\n# Additional schema paths\ndb-extra-search-path = \"public\"" >> postgrest.conf
```

#### Simplified Configuration with URL Encoding

If your PostgreSQL password contains special characters (like `+`, `/`, `&`, etc.), it's recommended to use the provided utility script that automatically handles URL encoding:

```bash
# Run the script locally to configure PostgREST
./workflow/setup_postgrest_config.sh

# Or run it to configure PostgREST on a remote Digital Ocean droplet
./workflow/setup_postgrest_config.sh --remote YOUR_DROPLET_ID
```

This script:
1. Automatically URL-encodes special characters in your password
2. Creates a properly formatted PostgREST configuration file
3. Sets up a systemd service for PostgREST
4. Handles both local and remote (Digital Ocean droplet) configurations
5. Provides detailed output for debugging

Example output:
```
PostgREST Configuration Setup
----------------------------
Database Host: htmx-examples-db-do-user-12345.db.ondigitalocean.com
Database Port: 25060
Database Name: defaultdb
PostgREST User: web_anon
Password contains special characters that need URL encoding: Yes

Creating configuration locally...
Created PostgREST configuration at /opt/postgrest/postgrest.conf
URL-encoded password: Yes (special characters were properly encoded)
Created systemd service file at /opt/postgrest/postgrest.service

Configuration Summary:
---------------------
PostgREST User: web_anon
Database Connection: postgres://web_anon:***@htmx-examples-db-do-user-12345.db.ondigitalocean.com:25060/defaultdb
Password URL-Encoded: Yes (special characters were properly encoded)
```

### Testing and Maintenance Scripts

The deployment workflow includes additional scripts to help with testing, validation, and maintenance of your PostgREST setup:

#### Teardown Script

The `teardown_postgrest.sh` script helps clean up existing PostgREST configurations, either for testing purposes or when you need to reinstall. It:

1. Stops and disables the PostgREST service
2. Backs up existing configuration files before removing them
3. Provides detailed output of the teardown process
4. Works in both local and remote (Digital Ocean droplet) environments

```bash
# For local teardown
./workflow/teardown_postgrest.sh

# For remote teardown (on a Digital Ocean droplet)
./workflow/teardown_postgrest.sh --remote YOUR_DROPLET_ID
```

Example output:
```
Performing remote cleanup operations on droplet YOUR_DROPLET_ID...
Uploading and executing cleanup script on remote server...
Stopping PostgREST service...
Backing up PostgREST configuration files...
Configuration backed up to /opt/postgrest_backups/postgrest.conf.20250318_202835
Removed /opt/postgrest/postgrest.conf
Service file backed up to /opt/postgrest_backups/postgrest.service.20250318_202835
Removed /etc/systemd/system/postgrest.service
Cleanup completed successfully on remote server.
Ready to test setup_postgrest_config.sh
```

#### Validation Script

The `validate_postgrest_config.sh` script helps verify that your PostgREST configuration is correct. It:

1. Checks for the existence of required configuration files and directories
2. Validates that the configuration files contain the correct settings
3. Verifies URL encoding of special characters in the database password
4. Displays the current configuration (with passwords masked)
5. Works in both local and remote environments

```bash
# For local validation
./workflow/validate_postgrest_config.sh

# For remote validation (on a Digital Ocean droplet)
./workflow/validate_postgrest_config.sh --remote YOUR_DROPLET_ID
```

Example output:
```
Validating PostgREST configuration on droplet YOUR_DROPLET_ID...
Validating configuration file content...
✅ Password appears to be URL-encoded (contains % character)
Current configuration file content (with password masked):
# PostgreSQL connection string
db-uri = "postgres://web_anon:******@htmx-examples-db-do-user-12345.db.ondigitalocean.com:25060/defaultdb?sslmode=require"

# The database schema to expose to REST clients
db-schema = "api"
...

✅ All validation checks passed! PostgREST is correctly configured.
```

#### Typical Workflow for Testing and Deployment

A common workflow for testing and deployment might look like this:

1. **Clean up existing configuration** (if necessary):
   ```bash
   ./workflow/teardown_postgrest.sh --remote YOUR_DROPLET_ID
   ```

2. **Set up a new configuration**:
   ```bash
   ./workflow/setup_postgrest_config.sh --remote YOUR_DROPLET_ID
   ```

3. **Start the PostgREST service**:
   ```bash
   doctl compute ssh YOUR_DROPLET_ID --ssh-command "systemctl enable postgrest && systemctl start postgrest"
   ```

4. **Validate the configuration**:
   ```bash
   ./workflow/validate_postgrest_config.sh --remote YOUR_DROPLET_ID
   ```

5. **Test the API**:
   ```bash
   doctl compute ssh YOUR_DROPLET_ID --ssh-command "curl http://localhost:3001/ -v"
   ```

Using these scripts together allows for easy deployment, testing, and troubleshooting of your PostgREST setup.

#### Creating a Systemd Service

Create a systemd service file for PostgREST:

```bash
# Create the service file
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
```

If you're having issues with heredocs on the remote server, you can create the service file in multiple steps:

```bash
# Step 1: Create the base service file
cd /opt/postgrest
echo "[Unit]" > postgrest.service
echo -e "Description=PostgREST API Server\nAfter=network.target\n\n[Service]" >> postgrest.service

# Step 2: Add the service configuration
echo -e "ExecStart=/opt/postgrest/postgrest /opt/postgrest/postgrest.conf\nRestart=always\nUser=root\nGroup=root\nWorkingDirectory=/opt/postgrest\nEnvironment=\"PGRST_JWT_SECRET=$POSTGREST_JWT_SECRET\"\n\n[Install]\nWantedBy=multi-user.target" >> postgrest.service

# Step 3: Copy the service file to the systemd directory
sudo cp postgrest.service /etc/systemd/system/
```

Enable and start the PostgREST service:

```bash
# Enable and start the service
systemctl daemon-reload
systemctl enable postgrest
systemctl start postgrest

# Check the status to ensure it's running
systemctl status postgrest
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

Create the `app.js` file with the following content:

```javascript
const express = require('express');
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const winston = require('winston');
const http = require('http');  // Required for IPv4 configuration
const https = require('https'); // Required for IPv4 configuration
require('dotenv').config();

// Initialize logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'htmx-middleware' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ],
});

const app = express();
app.use(express.json());

const PORT = process.env.MIDDLEWARE_PORT || 3000;
const POSTGREST_URL = process.env.POSTGREST_URL || 'http://127.0.0.1:3001'; // Use 127.0.0.1 instead of localhost
const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;

if (!GOOGLE_API_KEY) {
  logger.error('GOOGLE_API_KEY is not set in environment variables');
  process.exit(1);
}

// Configure axios to use IPv4 (important for PostgREST connectivity)
const httpAgent = new http.Agent({ family: 4 });
const httpsAgent = new https.Agent({ family: 4 });

// Create an axios instance with IPv4 configuration
const axiosIPv4 = axios.create({
  httpAgent,
  httpsAgent,
  timeout: 10000 // 10 second timeout
});

// Helper function to ensure URLs use IPv4
function ensureIPv4Url(url) {
  return url.replace(/localhost/g, '127.0.0.1');
}

// Initialize Google AI
const genAI = new GoogleGenerativeAI(GOOGLE_API_KEY);

// Function to generate embeddings
async function generateEmbedding(text) {
  try {
    // Create embedding model
    const model = genAI.getGenerativeModel({ model: "models/text-embedding-004" });
    
    // Generate embedding
    const embeddingResult = await model.embedContent({
      content: {
        parts: [
          { text }
        ],
      },
      taskType: "RETRIEVAL_QUERY"
    });
    
    return embeddingResult.embedding.values;
  } catch (error) {
    logger.error('Error generating embedding:', error);
    throw new Error('Embedding generation failed: ' + error.message);
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Basic search endpoint
app.get('/api/search', async (req, res) => {
  try {
    const query = req.query.q;
    if (!query) {
      return res.status(400).json({ error: 'Query parameter "q" is required' });
    }
    
    const limit = parseInt(req.query.limit || '5');
    const embeddingType = req.query.embedding_type || 'content';
    const category = req.query.category || null;
    const complexity = req.query.complexity || null;
    
    logger.info('Processing search query:', { query, embeddingType, limit });
    
    // Generate embedding
    const embedding = await generateEmbedding(query);
    
    // Call PostgREST with the embedding using IPv4
    const postUrl = `${ensureIPv4Url(POSTGREST_URL)}/rpc/vector_search`;
    logger.info(`Making request to: ${postUrl}`);
    
    const response = await axiosIPv4.post(postUrl, {
      query_embedding: embedding,
      embedding_type: embeddingType,
      result_limit: limit,
      category_filter: category,
      complexity_filter: complexity
    });
    
    res.json(response.data);
  } catch (error) {
    logger.error('Search error:', error);
    res.status(500).json({ 
      error: 'Search failed', 
      details: error.message 
    });
  }
});

// Multi-search endpoint
app.get('/api/multi-search', async (req, res) => {
  try {
    const query = req.query.q;
    if (!query) {
      return res.status(400).json({ error: 'Query parameter "q" is required' });
    }
    
    const limit = parseInt(req.query.limit || '5');
    const category = req.query.category || null;
    const complexity = req.query.complexity || null;
    
    logger.info('Processing multi-search query:', { query, limit });
    
    // Generate embedding
    const embedding = await generateEmbedding(query);
    
    // Call PostgREST with the embedding using IPv4
    const postUrl = `${ensureIPv4Url(POSTGREST_URL)}/rpc/multi_vector_search`;
    logger.info(`Making request to: ${postUrl}`);
    
    const response = await axiosIPv4.post(postUrl, {
      query_embedding: embedding,
      result_limit: limit,
      category_filter: category,
      complexity_filter: complexity
    });
    
    res.json(response.data);
  } catch (error) {
    logger.error('Multi-search error:', error);
    res.status(500).json({ 
      error: 'Multi-search failed', 
      details: error.message 
    });
  }
});

// Forward all other requests to PostgREST
app.all('/direct/*', async (req, res) => {
  try {
    // Prepare headers but remove host
    const headers = { ...req.headers };
    delete headers.host;
    
    // Forward to PostgREST, removing the /direct prefix and ensuring IPv4
    const targetUrl = `${ensureIPv4Url(POSTGREST_URL)}${req.url.replace(/^\/direct/, '')}`;
    logger.info(`Proxying request to: ${targetUrl}`);
    
    const response = await axiosIPv4({
      method: req.method,
      url: targetUrl,
      data: req.body,
      headers: headers,
      responseType: 'stream',
    });
    
    // Forward response headers
    Object.entries(response.headers).forEach(([key, value]) => {
      res.set(key, value);
    });
    
    // Stream response data
    response.data.pipe(res);
  } catch (error) {
    logger.error('PostgREST proxy error:', error);
    res.status(error.response?.status || 500).json(
      error.response?.data || { error: 'Proxy request failed' }
    );
  }
});

app.listen(PORT, () => {
  logger.info(`Middleware listening on port ${PORT}`);
  logger.info(`Connected to PostgREST at ${ensureIPv4Url(POSTGREST_URL)}`);
});
```

**Important Note**: This middleware implementation includes proper IPv4 configuration to ensure reliable connectivity with PostgREST. Node.js applications may prefer IPv6 by default, causing connection issues with services that only listen on IPv4 loopback addresses (like our PostgREST configuration which listens on 127.0.0.1).

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

### Automated Middleware Deployment with Scripts

For a more streamlined deployment process, use the provided scripts in the `workflow` directory. These scripts handle all the steps described above, including environment setup, file creation, dependencies installation, and service configuration.

#### Ready-to-use Middleware Implementation

The `workflow/middleware_app.js` file contains a production-ready implementation of the middleware with the following features:

- **IPv4 Compatibility**: Configured to explicitly use IPv4 for all network requests
- **Error Handling**: Robust error handling and detailed logging
- **Full API Implementation**: Includes all endpoints (`/health`, `/api/search`, `/api/multi-search`, `/api/similar`, `/direct/*`)
- **Streaming Response Handling**: Properly streams responses from PostgREST
- **Environment Variable Support**: Configurable through environment variables

This implementation is designed to work reliably in production environments and avoids common issues like IPv6/IPv4 address resolution problems.

#### Initial Middleware Setup

To set up the middleware for the first time on a remote server:

```bash
# Ensure you have the droplet ID from Digital Ocean
DROPLET_ID="your_droplet_id_here"

# Set up the middleware with proper IPv4 configuration
./workflow/setup_middleware.sh --remote $DROPLET_ID
```

This script:
1. Installs Node.js and PM2 on the remote server
2. Creates the middleware directory structure
3. Copies the application files (`app.js`, `package.json`, `ecosystem.config.js`)
4. Sets up the environment variables
5. Installs all dependencies
6. Starts the middleware with PM2 and enables it to run on startup

The middleware implementation in these scripts includes proper IPv4 configuration to ensure reliable connectivity with PostgREST.

#### Updating Existing Middleware

If you need to update an existing middleware installation (e.g., to fix issues or add features):

```bash
# Deploy updates to an existing middleware installation
./workflow/deploy_middleware.sh $DROPLET_ID
```

This script:
1. Backs up the current middleware application
2. Deploys the new version from `workflow/middleware_app.js`
3. Sets appropriate permissions
4. Restarts the middleware service

#### Testing the Deployed Middleware

After deployment, verify the middleware is functioning correctly:

```bash
# Test the health endpoint
doctl compute ssh $DROPLET_ID --ssh-command "curl http://localhost:3000/health"

# Test the search functionality
doctl compute ssh $DROPLET_ID --ssh-command "curl 'http://localhost:3000/api/search?q=How%20to%20implement%20tabs'"
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

### Automated Nginx Setup with Script

For a more streamlined Nginx setup, use the provided script:

```bash
# Set up Nginx as a reverse proxy
./workflow/setup_nginx.sh --remote $DROPLET_ID
```

This script:
1. Installs Nginx if not already installed
2. Creates and enables the appropriate configuration
3. Sets up proxy rules for the middleware and optionally for direct PostgREST access
4. Configures the firewall (if available)
5. Restarts Nginx to apply changes

The script also provides a summary of available endpoints and their usage.

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

## Recommended Deployment Workflow

For a complete deployment from scratch, the following sequence is recommended:

1. **Prerequisites**:
   - Create a Digital Ocean droplet
   - Set up a PostgreSQL database
   - Obtain a Google AI API key
   - Configure SSH keys for server access
   - Add all required environment variables to `.env` file
   - Ensure `doctl` is properly configured on your local machine with appropriate access tokens

2. **Deploy PostgREST**:
   ```bash
   ./workflow/setup_postgrest_config.sh --remote $DROPLET_ID
   ```

3. **Deploy the Middleware**:
   ```bash
   ./workflow/setup_middleware.sh --remote $DROPLET_ID
   ```

4. **Set Up Nginx as Reverse Proxy**:
   ```bash
   # Important: This script must be run from your local machine,
   # NOT from inside the droplet via SSH.
   ./workflow/setup_nginx.sh --remote $DROPLET_ID
   ```

5. **Verify Deployment**:
   ```bash
   # Get the droplet's public IP
   PUBLIC_IP=$(doctl compute droplet get $DROPLET_ID --format PublicIPv4 --no-header)
   
   # Test the API through Nginx
   curl "http://$PUBLIC_IP/health"
   curl "http://$PUBLIC_IP/api/search?q=How%20to%20implement%20tabs"
   ```

**Note on `doctl`**: If you encounter errors related to the `doctl` command when running the setup scripts, ensure that:
- The Digital Ocean CLI tool (`doctl`) is installed on your local machine
- You've authenticated with `doctl auth init` and provided a valid API token
- Your API token has sufficient permissions to manage the droplet

This workflow ensures all components are properly installed, configured, and integrated with each other.

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

2. **Special Characters in Passwords**:
   - If your PostgreSQL password contains special characters (like `+`, `/`, `&`, etc.), they must be URL-encoded in the connection string.
   - Characters like `+` should be encoded as `%2B` and `/` as `%2F`.
   - Example fixing a connection string with special characters:
     ```bash
     # Original password with special characters: PasswordWithSpecialChars/+&
     # URL-encoded password: PasswordWithSpecialChars%2F%2B%26
     
     # Edit the connection string in postgrest.conf:
     db-uri = "postgres://web_anon:PasswordWithSpecialChars%2F%2B%26@hostname:port/dbname?sslmode=require"
     ```
   - Failure to encode special characters can result in errors like `"invalid integer value \"PasswordWith\" for connection option \"port\""`.
   - Alternatively, consider using separate connection parameters instead of a URI:
     ```bash
     # Instead of db-uri, use these parameters:
     db-host = "hostname"
     db-port = port
     db-name = "dbname"
     db-user = "web_anon"
     db-pass = "PasswordWithSpecialChars/+&"  # No need to URL-encode here
     ```

3. **Middleware Embedding Issues**:
   - Check Google AI API key: `curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $GOOGLE_API_KEY" "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent"`
   - Check middleware logs: `cat /opt/htmx-middleware/error.log`

4. **PostgREST Configuration Issues**:
   - Check systemd logs: `journalctl -u postgrest -n 50`
   - Verify that the functions exist in the `api` schema: `PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT proname FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'api';" | cat`

5. **PostgREST Binary Download Issues**:
   - If the PostgREST binary URL in the documentation doesn't work, check the latest release URL at: https://github.com/PostgREST/postgrest/releases
   - The correct URL format for version 12.2.8 is: `https://github.com/PostgREST/postgrest/releases/download/v12.2.8/postgrest-v12.2.8-linux-static-x86-64.tar.xz`. Always check the latest release page for the correct URL format.

6. **Public Accessibility Issues**:
   - If your API isn't publicly accessible after completing all setup steps, check:
     - Nginx status: `systemctl status nginx`
     - Nginx configuration: `nginx -t`
     - Firewall settings: `ufw status`
   - Common mistakes:
     - Running the `setup_nginx.sh` script via SSH inside the droplet (it must be run from local machine)
     - Missing `doctl` configuration on local machine
     - Digital Ocean firewall rules blocking ports 80/443
   - Verify local services:
     ```bash
     # Check if services are running locally
     curl http://localhost:3000/health  # Middleware
     curl http://localhost:3001/        # PostgREST
     ```
   - For complete debugging, check:
     ```bash
     # Nginx logs
     tail -f /var/log/nginx/error.log
     
     # PostgREST logs
     journalctl -u postgrest -n 50
     
     # Middleware logs
     pm2 logs htmx-middleware
     ```

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

4. **Public Access Configuration**:
   - Ensure your Digital Ocean droplet doesn't have a firewall blocking ports 80/443
   - Confirm that Nginx is properly configured to listen on the server's public interface
   - Verify that both the PostgREST service and middleware are running correctly
   - Test accessibility using the public IP address: `curl http://$PUBLIC_IP/health`

5. **Network Architecture**:
   ```
   ┌─────────┐    ┌─────────┐    ┌────────────┐    ┌────────────┐
   │ Client  │───>│  Nginx  │───>│ Middleware │───>│ PostgREST  │
   └─────────┘    └─────────┘    └────────────┘    └────────────┘
                  Port 80/443    Port 3000         Port 3001
                  Public         Internal          Internal
   ```
   - Only Nginx should be exposed publicly on ports 80/443
   - The middleware and PostgREST should only listen on localhost (127.0.0.1)

## Challenges and Solutions

### IPv6/IPv4 Connectivity Issues

When deploying the Node.js middleware, ensure proper network connectivity with PostgREST. Node.js DNS resolution may prefer IPv6 addresses over IPv4, but PostgREST typically listens only on IPv4 loopback addresses.

**Solution**: The middleware in `workflow/middleware_app.js` includes code to explicitly use IPv4:

```javascript
// Force IPv4 for all axios requests
const httpAgent = new http.Agent({ family: 4 });
const httpsAgent = new https.Agent({ family: 4 });

// Create an axios instance with IPv4 configuration
const axiosIPv4 = axios.create({
  httpAgent,
  httpsAgent
});

// Replace 'localhost' with explicit IPv4 address
function ensureIPv4Url(url) {
  return url.replace(/localhost/g, '127.0.0.1');
}
```

### Google AI API Integration

When integrating with Google AI for generating embeddings:

**Challenge**: The embedding API requires specific parameters for proper operation.

**Solution**: Use the following configuration:
- Model: `models/text-embedding-004`
- Task type: `RETRIEVAL_QUERY`
- Content structure: Wrap text in the expected format with `parts` array

```javascript
const embeddingResult = await model.embedContent({
  content: {
    parts: [{ text: queryText }]
  },
  taskType: "RETRIEVAL_QUERY"
});
```

### PostgREST Configuration

**Challenge**: Database connection strings with special characters can cause issues.

**Solution**: URL-encode special characters in passwords and ensure the correct PostgreSQL connection parameters:
- Add `sslmode=require` for secure connections
- Use the `setup_postgrest_config.sh` script which handles encoding automatically

### Middleware Security

**Challenge**: Protecting the Google API key and other sensitive credentials.

**Solution**:
- Store credentials in the `.env` file
- Restrict file permissions with `chmod 600 /opt/htmx-middleware/.env`
- Ensure the application validates required environment variables at startup

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

The automated deployment scripts in the `workflow` directory (`setup_middleware.sh`, `deploy_middleware.sh`, and `setup_nginx.sh`) provide a reliable and repeatable deployment process that handles common issues like IPv4/IPv6 connectivity. While the manual deployment steps are documented for reference and educational purposes, using the scripts is highly recommended for production deployments.

The resulting API allows applications to search for HTMX examples semantically, finding the most relevant examples regardless of exact keyword matches.
