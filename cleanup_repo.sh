#!/bin/bash

# Create artifacts directory if it doesn't exist
mkdir -p artifacts

# List of artifact files identified by Gemini
ARTIFACT_FILES=(
  "check_db.sh"
  "check_vector.sql"
  "debug_import.sh"
  "direct_insert.sql"
  "htmx_examples_multi_schema.json"
  "htmx_multi_schema.json"
  "htmx_schema.json"
  "import_all.sql"
  "import_direct.sh"
  "import_examples.sh"
  "import_examples.sql"
  "import_simple.sh"
  "update_scripts_to_use_env.sh"
  "search_ui.html"
)

# Move each artifact file to the artifacts directory
for file in "${ARTIFACT_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Moving $file to artifacts/"
    mv "$file" artifacts/
  else
    echo "File $file not found, skipping"
  fi
done

# Create a README in the artifacts directory
cat > artifacts/README.md << EOF
# Artifacts

This directory contains files that were created during the development of the HTMX Examples Vector Database project but are not essential for reproducing the workflow.

These files are likely remnants of experiments, alternative approaches that were abandoned, or support/debugging scripts that aren't part of the core execution.

They are kept here for reference purposes but can be safely ignored when following the main workflow.

## Files

$(for file in "${ARTIFACT_FILES[@]}"; do echo "- \`$file\`"; done)

For a detailed explanation of why these files are considered artifacts, see \`analysis/essential_files_report.md\`.
EOF

echo "Cleanup complete. Artifact files moved to artifacts/ directory." 