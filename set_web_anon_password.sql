-- This script sets a password for the web_anon role
-- Run this on your PostgreSQL database

-- Set a password for the web_anon role
ALTER ROLE web_anon WITH PASSWORD 'htmx_examples_api';

-- Output success message
DO $$
BEGIN
    RAISE NOTICE 'Password set for web_anon role.';
    RAISE NOTICE 'Use this password in the PostgREST configuration.';
END
$$; 