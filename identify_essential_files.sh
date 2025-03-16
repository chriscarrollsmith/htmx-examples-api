#!/bin/bash

# Create output directory if it doesn't exist
mkdir -p analysis

# Instructions for Gemini
INSTRUCTIONS="You are analyzing a repository that contains a workflow for scraping HTMX examples, extracting structured data, loading it to PostgreSQL, embedding the data using OpenAI, and creating a PostgREST API endpoint with vector similarity search.

I'm providing you with:
1. A workflow summary that describes the successful steps and key files used in the workflow
2. A repomix-output.txt file that contains the entire codebase

Please analyze these files and create a report that:
1. Identifies which files are ESSENTIAL to reproducing the workflow based on the workflow summary
2. Identifies which files are likely ARTIFACTS from wrong turns or experiments that are not needed
3. For each file, provide a brief explanation of why you think it's essential or an artifact
4. Organize your response as a markdown document with clear sections for essential files and artifacts

Focus on determining which files are actually used in the successful workflow versus those that were created during experimentation but aren't part of the final solution."

# Combine the workflow summary and a portion of repomix-output.txt
echo "Processing files for analysis..."
cat > analysis/combined_input.md << EOF
# Workflow Summary

$(cat summaries/final_workflow_summary.md)

# Repository Contents

$(cat repomix-output.txt)
EOF

# Send to Gemini for analysis
echo "Sending to Gemini for analysis..."
cat analysis/combined_input.md | llm "$INSTRUCTIONS" -m gemini-2.0-flash-001 > analysis/essential_files_report.md

echo "Analysis complete. Report saved to analysis/essential_files_report.md" 