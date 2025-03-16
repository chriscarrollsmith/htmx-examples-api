#!/bin/bash

# Create output directory if it doesn't exist
mkdir -p summaries

# Instructions for Gemini
INSTRUCTIONS="You are analyzing logs from an LLM agent that created a workflow for scraping HTMX examples, extracting structured data, loading it to PostgreSQL, embedding the data, and creating a PostgREST API endpoint with vector similarity search. 

Please create a very concise summary of the successful steps taken in this workflow, focusing on:
1. The key files created/used at each step
2. The commands executed for each successful step
3. The overall workflow from start to finish

Format your response as a markdown document with clear sections for each major step in the process. Include code snippets where relevant, but keep them brief. This summary should serve as documentation for repeating this process in the future."

# Process the first conversation log
echo "Processing fetching-htmx-examples.md..."
cat .specstory/history/fetching-htmx-examples.md | llm "$INSTRUCTIONS" -m gemini-2.0-flash-001 > summaries/htmx_examples_summary.md

# Process the second conversation log
echo "Processing protecting-secrets-with-env-file.md..."
cat .specstory/history/protecting-secrets-with-env-file.md | llm "$INSTRUCTIONS" -m gemini-2.0-flash-001 > summaries/env_secrets_summary.md

# Combine the summaries
echo "Combining summaries..."
cat > summaries/workflow_summary.md << EOF
# HTMX Examples Scraping and Embedding Workflow Summary

This document provides a concise summary of the workflow used to scrape HTMX examples, 
extract structured data, load it to PostgreSQL, embed the data using OpenAI, 
and create a PostgREST API endpoint with vector similarity search.

## Workflow Overview

EOF

cat summaries/htmx_examples_summary.md >> summaries/workflow_summary.md
echo -e "\n\n" >> summaries/workflow_summary.md
cat summaries/env_secrets_summary.md >> summaries/workflow_summary.md

echo "Summary created at summaries/workflow_summary.md" 