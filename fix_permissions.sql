-- This script needs to be run by a database superuser (e.g., doadmin)

-- Grant SELECT permission on htmx_embeddings to postgrest user
GRANT SELECT ON htmx_embeddings TO postgrest;

-- Grant SELECT permission on htmx_embeddings to web_anon role
GRANT SELECT ON htmx_embeddings TO web_anon;

-- Verify permissions
SELECT grantee, table_name, privilege_type 
FROM information_schema.table_privileges 
WHERE table_name = 'htmx_embeddings'; 