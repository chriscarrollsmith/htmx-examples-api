#!/bin/bash

# Example curl commands for the HTMX Examples API
# Note: These commands assume PostgREST is running at localhost:3000
# Replace with your actual PostgREST endpoint when deployed

echo "Example 1: Vector Similarity Search"
echo "--------------------------------"
curl -X POST "http://localhost:3000/rpc/search_examples_fixed" \
  -H "Content-Type: application/json" \
  -d '{"example_id": "inline-validation", "embedding_type": "content", "limit_results": 5}'

echo -e "\n\nExample 2: Basic Text Search"
echo "--------------------------------"
curl -X POST "http://localhost:3000/rpc/text_search_examples" \
  -H "Content-Type: application/json" \
  -d '{"search_text": "validation", "limit_results": 5}'

echo -e "\n\nExample 3: Enhanced Text Search with Relevance Ranking"
echo "--------------------------------"
curl -X POST "http://localhost:3000/rpc/enhanced_text_search" \
  -H "Content-Type: application/json" \
  -d '{"search_text": "validation", "limit_results": 5}'

echo -e "\n\nExample 4: Multi-Keyword Search"
echo "--------------------------------"
curl -X POST "http://localhost:3000/rpc/keyword_search" \
  -H "Content-Type: application/json" \
  -d '{"keywords": ["form", "validation"], "limit_results": 5}'

echo -e "\n\nExample 5: Browse All Examples"
echo "--------------------------------"
curl "http://localhost:3000/examples?limit=5"

echo -e "\n\nExample 6: Filter Examples by Category"
echo "--------------------------------"
curl "http://localhost:3000/examples?category=eq.UI%20Patterns&limit=5"

echo -e "\n\nExample 7: Filter Examples by Complexity Level"
echo "--------------------------------"
curl "http://localhost:3000/examples?complexity_level=eq.beginner&limit=5"

echo -e "\n\nExample 8: Get a Specific Example by ID"
echo "--------------------------------"
curl "http://localhost:3000/examples?id=eq.inline-validation" 