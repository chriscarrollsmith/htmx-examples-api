# Extracting HTMX Examples to Structured JSON

This document outlines the process followed by the Cursor Agent to extract structured information from HTMX examples using the `llm` tool. The goal is to transform HTML examples into a structured JSON format that can be embedded in a vector database for semantic search.

## Prerequisites

- Downloaded HTMX examples in the `examples/` directory (from step 1)
- The `llm` CLI tool installed
- The `uvx strip-tags` tool installed
- The `jq` tool installed (optional, for JSON validation)

## Step 1: Create the JSON Schema

First, we need to define a schema that specifies the structure of the data we want to extract from each HTMX example.

Create a file named `htmx_examples_schema.json` in the workflow directory with the following content:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "HTMX Example Schema",
  "description": "Schema for storing HTMX examples in a vector database for semantic search",
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "description": "Unique identifier for the example (e.g., 'click-to-edit', 'active-search')"
    },
    "title": {
      "type": "string",
      "description": "Title of the example as shown on the page"
    },
    "category": {
      "type": "string",
      "description": "Category of the example (e.g., 'UI Patterns', 'Dialog Examples', 'Advanced Examples')"
    },
    "url": {
      "type": "string",
      "description": "Original URL of the example"
    },
    "description": {
      "type": "string",
      "description": "Short description of what the example demonstrates"
    },
    "html_snippets": {
      "type": "array",
      "description": "Array of HTML code snippets shown in the example",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string",
            "description": "The HTML code snippet"
          },
          "description": {
            "type": "string",
            "description": "Description or explanation of the code snippet"
          }
        },
        "required": ["code"]
      }
    },
    "javascript_snippets": {
      "type": "array",
      "description": "Array of JavaScript code snippets shown in the example",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string",
            "description": "The JavaScript code snippet"
          },
          "description": {
            "type": "string",
            "description": "Description or explanation of the code snippet"
          }
        },
        "required": ["code"]
      }
    },
    "key_concepts": {
      "type": "array",
      "description": "Key HTMX concepts demonstrated in this example",
      "items": {
        "type": "string"
      }
    },
    "htmx_attributes": {
      "type": "array",
      "description": "HTMX attributes used in this example (e.g., 'hx-get', 'hx-trigger', 'hx-swap')",
      "items": {
        "type": "string"
      }
    },
    "demo_explanation": {
      "type": "string",
      "description": "Explanation of how the demo works, extracted from the page"
    },
    "complexity_level": {
      "type": "string",
      "enum": ["beginner", "intermediate", "advanced"],
      "description": "Subjective assessment of the example's complexity"
    },
    "use_cases": {
      "type": "array",
      "description": "Common use cases where this pattern would be useful",
      "items": {
        "type": "string"
      }
    }
  },
  "required": ["id", "title", "category", "url", "description", "html_snippets", "key_concepts", "htmx_attributes"]
}
```

## Step 2: Create the Extraction Prompt

Next, create a system prompt that will guide the LLM in extracting the information according to our schema.

Create a file named `htmx_extraction_prompt.txt` in the workflow directory with the following content:

```
You are an expert in HTMX, a JavaScript library that allows you to access AJAX, CSS Transitions, WebSockets and Server Sent Events directly in HTML, using attributes.

Analyze the provided HTMX example and extract structured information according to the schema. Focus on:

1. Identifying the key concepts demonstrated in the example
2. Extracting all HTML and JavaScript code snippets along with explanations of what they do
3. Identifying all HTMX attributes used and their purpose
4. Determining the complexity level based on the concepts used
5. Suggesting practical use cases for this pattern

For HTML and JavaScript snippets, make sure to extract both the code and a clear explanation of what the code does. For the complexity level, use your judgment to classify as beginner, intermediate, or advanced based on the concepts involved.

The ID should be derived from the filename or title (lowercase, hyphenated). The URL should be constructed as "https://htmx.org/examples/[id]/".

Be thorough in your analysis, as this information will be used for semantic search in a vector database to help developers find relevant HTMX patterns.
```

## Step 3: Create the Processing Script

Create a shell script named `extract_to_json.sh` in the workflow directory that will process the HTML examples and extract structured information using the `llm` tool.

The script provides several options:
- Process all examples (default or with `--all` flag)
- Process a single example (`--single` flag)
- Verify the extraction results (`--verify` flag)
- Display help information (`--help` flag)

The script will create a `processed_examples` directory in the project root (not in the workflow directory) to store the extracted JSON files.

```bash
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
```

## Step 4: Run the Extraction Process

Make the script executable and run it from the workflow directory:

```bash
cd workflow
chmod +x extract_to_json.sh
./extract_to_json.sh --all
```

This will process each HTML file in the `examples/` directory, strip the HTML tags, and use the `llm` tool to extract structured information according to our schema. The results will be saved as JSON files in the `processed_examples/` directory at the project root.

Alternatively, you can process a single example:

```bash
./extract_to_json.sh --single ../examples/click-to-edit.html
```

## Step 5: Verify the Extraction

Check the extracted JSON files to ensure they contain the expected information:

```bash
./extract_to_json.sh --verify
```

Each JSON file should contain structured information about the corresponding HTMX example, including:
- Basic metadata (id, title, category, URL)
- Description of what the example demonstrates
- HTML and JavaScript code snippets with explanations
- Key HTMX concepts and attributes used
- Complexity level assessment
- Suggested use cases

## Troubleshooting

If you encounter issues with the extraction process, try these solutions:

1. **JSON Schema Issues**: If the `llm` tool has trouble with the JSON schema file, try using the concise schema syntax directly in the command as shown in the script.

2. **Missing Fields**: If some fields are missing in the extracted JSON, check the extraction prompt and make sure it explicitly instructs the LLM to extract all required fields.

3. **Batch Processing**: For a large number of examples, you can modify the script to process examples in batches using the `--schema-multi` option.

4. **jq Not Installed**: If you see a warning about `jq` not being installed, you can install it using your package manager (e.g., `apt-get install jq` on Ubuntu). The script will still work without `jq`, but some verification features will be limited.

## Next Steps

After successfully extracting structured information from all HTMX examples, you can proceed to the next step: generating embeddings for the examples to enable semantic search. 