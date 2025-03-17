#!/bin/bash

# This script processes HTMX examples using the LLM tool
# It extracts structured information according to our schema
# and saves the results to JSON files

# Create output directory in the project root (one level up from workflow)
mkdir -p "../processed_examples"

# Process all examples using direct schema
process_examples() {
  echo "Processing HTMX examples..."
  
  # Use the examples folder in the project root
  local examples_dir="../examples"
  
  # Check if the examples directory exists and contains HTML files
  if [ ! -d "$examples_dir" ] || [ "$(ls -1 $examples_dir/*.html 2>/dev/null | wc -l)" -eq 0 ]; then
    echo "Error: No HTML examples found in the $examples_dir directory."
    echo "Please run the download_examples.sh script first."
    exit 1
  fi
  
  echo "Using examples from $examples_dir directory."
  
  # Define the concise schema directly for better compatibility
  local schema='id: unique identifier for the example, title: title of the example as shown on the page, category: category of the example, url: original URL of the example, description: short description of what the example demonstrates, html_snippets: array of objects with code and description, javascript_snippets: array of objects with code and description, key_concepts: array of key HTMX concepts demonstrated, htmx_attributes: array of HTMX attributes used, demo_explanation: explanation of how the demo works, complexity_level: subjective assessment of complexity, use_cases: array of common scenarios where this pattern would be useful'
  
  # Count the number of examples
  local example_count=$(ls -1 $examples_dir/*.html 2>/dev/null | wc -l)
  echo "Found $example_count examples to process."
  
  # Process each example file
  local count=0
  for file in $examples_dir/*.html; do
    local basename=$(basename "$file" .html)
    count=$((count + 1))
    echo "[$count/$example_count] Processing $basename..."
    
    cat "$file" | \
      uvx strip-tags | \
      llm --schema "$schema" \
          --system "$(cat htmx_extraction_prompt.txt)" \
          > "../processed_examples/${basename}.json"
    
    echo "  Saved to ../processed_examples/${basename}.json"
  done
  
  echo "All examples processed and saved to ../processed_examples/"
  echo "Processed $count out of $example_count examples."
}

# Process a single example
process_single_example() {
  local file=$1
  
  if [ ! -f "$file" ]; then
    echo "Error: File $file does not exist."
    exit 1
  fi
  
  local basename=$(basename "$file" .html)
  echo "Processing $basename..."
  
  # Define the concise schema directly for better compatibility
  local schema='id: unique identifier for the example, title: title of the example as shown on the page, category: category of the example, url: original URL of the example, description: short description of what the example demonstrates, html_snippets: array of objects with code and description, javascript_snippets: array of objects with code and description, key_concepts: array of key HTMX concepts demonstrated, htmx_attributes: array of HTMX attributes used, demo_explanation: explanation of how the demo works, complexity_level: subjective assessment of complexity, use_cases: array of common scenarios where this pattern would be useful'
  
  # Extract structured information using LLM
  cat "$file" | \
    uvx strip-tags | \
    llm --schema "$schema" \
        --system "$(cat htmx_extraction_prompt.txt)" \
        > "../processed_examples/${basename}.json"
  
  echo "  Saved to ../processed_examples/${basename}.json"
  echo "  Contents of the extracted JSON:"
  cat "../processed_examples/${basename}.json" | head -c 300
  echo "..."
}

# Verify the extraction results
verify_extraction() {
  echo "Verifying extraction results..."
  
  local json_count=$(ls -1 ../processed_examples/*.json 2>/dev/null | wc -l)
  if [ "$json_count" -eq 0 ]; then
    echo "Error: No JSON files found in the processed_examples directory."
    exit 1
  fi
  
  echo "Found $json_count JSON files."
  
  # Check if all JSON files are valid
  local invalid_count=0
  for file in ../processed_examples/*.json; do
    if ! jq empty "$file" 2>/dev/null; then
      echo "  Error: $file is not valid JSON."
      invalid_count=$((invalid_count + 1))
    fi
  done
  
  if [ "$invalid_count" -eq 0 ]; then
    echo "All JSON files are valid."
  else
    echo "Found $invalid_count invalid JSON files."
  fi
  
  # List all examples with their categories and complexity levels
  echo "Listing all examples with their categories and complexity levels:"
  for file in ../processed_examples/*.json; do
    local basename=$(basename "$file" .json)
    local category=$(jq -r '.category // "Unknown"' "$file")
    local complexity=$(jq -r '.complexity_level // "Unknown"' "$file")
    echo "  $basename: $category ($complexity)"
  done
}

# Display usage information
usage() {
  echo "Usage: $0 [OPTION]"
  echo "Process HTMX examples and extract structured information."
  echo ""
  echo "Options:"
  echo "  -s, --single FILE   Process a single example file"
  echo "  -a, --all           Process all examples (default)"
  echo "  -v, --verify        Verify the extraction results"
  echo "  -h, --help          Display this help message"
}

# Parse command line arguments
if [ $# -eq 0 ]; then
  process_examples
  exit 0
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--single)
      if [ -z "$2" ]; then
        echo "Error: No file specified for --single option."
        usage
        exit 1
      fi
      process_single_example "$2"
      shift 2
      ;;
    -a|--all)
      process_examples
      shift
      ;;
    -v|--verify)
      verify_extraction
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