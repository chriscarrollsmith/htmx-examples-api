#!/usr/bin/env python3
"""
Generate postgrest.conf from environment variables.
This script reads values from .env and creates a postgrest.conf file.
"""

import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get environment variables
db_uri = os.getenv('DB_URI')
jwt_secret = os.getenv('JWT_SECRET')
openai_api_key = os.getenv('OPENAI_API_KEY')

# Create postgrest.conf content
config_content = f"""# PostgreSQL connection string
db-uri = "{db_uri}"

# The database schema to expose to REST clients
db-schema = "api"

# The database role to use when executing commands
db-anon-role = "web_anon"

# The secret used to sign JWT tokens
jwt-secret = "{jwt_secret}"

# The maximum number of rows to return from a request
max-rows = 100

# Server settings
server-port = 3000
server-host = "0.0.0.0"

# Set OpenAI API key as a custom setting
db-extra-search-path = "public, openai"
db-pre-request = "SET app.openai_api_key = '{openai_api_key}'"
"""

# Write to postgrest.conf
with open('postgrest.conf', 'w') as f:
    f.write(config_content)

print("postgrest.conf has been generated successfully.") 