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

# Process the conversation logs
echo "Processing conversation logs..."
for log_file in .specstory/history/*.md; do
  filename=$(basename "$log_file" .md)
  echo "Processing $filename..."
  cat "$log_file" | llm "$INSTRUCTIONS" -m gemini-2.0-flash-001 > "summaries/${filename}_summary.md"
done

# Combine the summaries
echo "Combining summaries..."
cat > summaries/workflow_summary.md << EOF
# HTMX Examples Scraping and Embedding Workflow Summary

This document provides a concise summary of the workflow used to scrape HTMX examples, 
extract structured data, load it to PostgreSQL, embed the data using OpenAI, 
and create a PostgREST API endpoint with vector similarity search.

## Workflow Overview

EOF

for summary_file in summaries/*_summary.md; do
  cat "$summary_file" >> summaries/workflow_summary.md
  echo -e "\n\n" >> summaries/workflow_summary.md
done

# Create a final, more concise summary
echo "Creating final summary..."
cat summaries/workflow_summary.md | llm "Create a concise, well-structured summary of this workflow with clear steps, key files, commands, and outputs for each step. Format as markdown with sections for each step and a final section with the complete workflow execution steps. Keep it under 100 lines total." -m gemini-2.0-flash-001 > summaries/final_workflow_summary.md

echo "Summary created at summaries/final_workflow_summary.md" 