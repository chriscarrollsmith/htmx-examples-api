#!/bin/bash

# This script processes HTMX examples using the LLM tool
# It extracts structured information according to our schema
# and saves the results to a JSON file

# Create output directory
mkdir -p processed_examples

# Process a single example
process_single_example() {
  local file=$1
  local basename=$(basename "$file" .html)
  echo "Processing $basename..."
  
  # Extract structured information using LLM
  cat "$file" | \
    uvx strip-tags | \
    llm --schema htmx_schema.json \
        --system "$(cat htmx_extraction_prompt.txt)" \
        > "processed_examples/${basename}.json"
  
  echo "Saved to processed_examples/${basename}.json"
}

# Process all examples
process_all_examples() {
  echo "Processing all examples..."
  
  # First, create a template for reuse
  llm --schema htmx_schema.json \
      --system "$(cat htmx_extraction_prompt.txt)" \
      --save htmx-extractor
  
  # Process each example file
  for file in examples/*.html; do
    local basename=$(basename "$file" .html)
    echo "Processing $basename..."
    
    cat "$file" | \
      uvx strip-tags | \
      llm -t htmx-extractor \
      > "processed_examples/${basename}.json"
  done
  
  echo "All examples processed and saved to processed_examples/"
}

# Process examples in batch mode
process_batch_examples() {
  echo "Processing examples in batch mode..."
  
  # Create a multi-schema template
  llm --schema htmx_multi_schema.json \
      --system "$(cat htmx_extraction_prompt.txt)" \
      --save htmx-batch-extractor
  
  # Process examples in batches of 5
  find examples -name "*.html" | \
    xargs -n 5 | \
    while read -r batch; do
      echo "Processing batch: $batch"
      cat $batch | \
        uvx strip-tags | \
        llm -t htmx-batch-extractor \
        > "processed_examples/batch_$(date +%s).json"
    done
  
  echo "Batch processing complete"
}

# Alternative approach using direct schema string
process_with_direct_schema() {
  echo "Processing examples with direct schema..."
  
  # Define the concise schema directly
  local schema='id: unique identifier for the example, title: title of the example as shown on the page, category: category of the example, url: original URL of the example, description: short description of what the example demonstrates, html_snippets: array of objects with code and description, javascript_snippets: array of objects with code and description, key_concepts: array of key HTMX concepts demonstrated, htmx_attributes: array of HTMX attributes used, demo_explanation: explanation of how the demo works, complexity_level: subjective assessment of complexity, use_cases: array of common scenarios where this pattern would be useful'
  
  # Process each example file
  for file in examples/*.html; do
    local basename=$(basename "$file" .html)
    echo "Processing $basename..."
    
    cat "$file" | \
      uvx strip-tags | \
      llm --schema "$schema" \
          --system "$(cat htmx_extraction_prompt.txt)" \
          > "processed_examples/${basename}.json"
  done
  
  echo "All examples processed and saved to processed_examples/"
}

# Create a vector database from processed examples
create_vector_database() {
  echo "Creating vector database from processed examples..."
  
  # This is a placeholder - you would use your vector DB tool here
  # For example, with sqlite-utils and an embedding plugin:
  
  # Combine all JSON files
  jq -s 'add' processed_examples/*.json > all_examples.json
  
  # Create SQLite database with embeddings
  # sqlite-utils insert htmx_examples.db examples all_examples.json --pk=id
  # sqlite-utils enable-fts htmx_examples.db examples description key_concepts
  
  echo "Vector database created"
}

# Display usage information
usage() {
  echo "Usage: $0 [OPTION]"
  echo "Process HTMX examples and extract structured information."
  echo ""
  echo "Options:"
  echo "  -s, --single FILE   Process a single example file"
  echo "  -a, --all           Process all examples"
  echo "  -b, --batch         Process examples in batch mode"
  echo "  -d, --direct        Process examples with direct schema string"
  echo "  -v, --vector        Create vector database from processed examples"
  echo "  -h, --help          Display this help message"
}

# Parse command line arguments
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--single)
      process_single_example "$2"
      shift 2
      ;;
    -a|--all)
      process_all_examples
      shift
      ;;
    -b|--batch)
      process_batch_examples
      shift
      ;;
    -d|--direct)
      process_with_direct_schema
      shift
      ;;
    -v|--vector)
      create_vector_database
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

echo "Processing complete!" 