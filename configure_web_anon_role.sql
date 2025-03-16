-- This script configures the web_anon role for passwordless access
-- Run this on your PostgreSQL database after setting up PostgREST

-- Ensure the web_anon role exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'web_anon') THEN
        CREATE ROLE web_anon NOLOGIN;
    END IF;
END
$$;

-- Configure the web_anon role for passwordless access
ALTER ROLE web_anon WITH LOGIN NOINHERIT;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA api TO web_anon;
GRANT SELECT ON ALL TABLES IN SCHEMA api TO web_anon;

-- Grant execute permissions on search functions
GRANT EXECUTE ON FUNCTION api.search_examples_fixed TO web_anon;
GRANT EXECUTE ON FUNCTION api.text_search_examples TO web_anon;
GRANT EXECUTE ON FUNCTION api.enhanced_text_search TO web_anon;
GRANT EXECUTE ON FUNCTION api.keyword_search TO web_anon;

-- Grant select permission on htmx_embeddings table
GRANT SELECT ON htmx_embeddings TO web_anon;

-- Create a pg_hba.conf entry for passwordless access
-- Note: This needs to be added to your pg_hba.conf file manually
-- or through your database provider's interface
/*
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    defaultdb       web_anon        0.0.0.0/0               trust
*/

-- Output success message
DO $$
BEGIN
    RAISE NOTICE 'web_anon role configured for passwordless access.';
    RAISE NOTICE 'Note: You may need to configure pg_hba.conf on your database server to allow passwordless connections.';
    RAISE NOTICE 'For Digital Ocean managed databases, you may need to contact support to enable this.';
END
$$; 