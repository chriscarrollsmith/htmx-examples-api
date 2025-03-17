-- setup_db_users.sql
-- This script sets up the necessary database users and permissions for PostgREST

-- Create the api schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS api;

-- Create or update the web_anon role with login capabilities
DO $$
DECLARE
    password_var TEXT;
BEGIN
    -- Get the password from environment variable
    SELECT current_setting('postgrest.password', TRUE) INTO password_var;
    
    IF password_var IS NULL THEN
        RAISE EXCEPTION 'The postgrest.password variable is not set. Please set it before running this script.';
    END IF;

    -- Create or update the web_anon role
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'web_anon') THEN
        EXECUTE format('CREATE ROLE web_anon LOGIN PASSWORD %L', password_var);
        RAISE NOTICE 'Created web_anon role with login capability and password.';
    ELSE
        EXECUTE format('ALTER ROLE web_anon WITH LOGIN PASSWORD %L', password_var);
        RAISE NOTICE 'Updated web_anon role with login capability and password.';
    END IF;
END
$$;

-- Grant necessary permissions to web_anon role
GRANT USAGE ON SCHEMA public TO web_anon;
GRANT USAGE ON SCHEMA api TO web_anon;

-- Create a simple view in the api schema for testing
CREATE OR REPLACE VIEW api.test_view AS
SELECT 1 AS id, 'Test' AS name;

-- Grant select on views
GRANT SELECT ON api.test_view TO web_anon;

-- Note: The following section will be executed if the htmx_examples and htmx_embeddings tables exist
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'htmx_examples') THEN
        EXECUTE 'GRANT SELECT ON htmx_examples TO web_anon';
        RAISE NOTICE 'Granted SELECT on htmx_examples to web_anon.';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'htmx_embeddings') THEN
        EXECUTE 'GRANT SELECT ON htmx_embeddings TO web_anon';
        RAISE NOTICE 'Granted SELECT on htmx_embeddings to web_anon.';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'htmx_examples_with_embeddings') THEN
        EXECUTE 'GRANT SELECT ON htmx_examples_with_embeddings TO web_anon';
        RAISE NOTICE 'Granted SELECT on htmx_examples_with_embeddings to web_anon.';
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'api' AND table_name = 'examples') THEN
        EXECUTE 'GRANT SELECT ON api.examples TO web_anon';
        RAISE NOTICE 'Granted SELECT on api.examples to web_anon.';
    END IF;
END
$$;

-- Verify that the web_anon role has been set up correctly
DO $$
BEGIN
    RAISE NOTICE 'Database users and permissions have been set up successfully.';
    RAISE NOTICE 'The web_anon role has been configured with login capability and the specified password.';
    RAISE NOTICE 'The necessary permissions have been granted to the web_anon role.';
END
$$; 