#!/bin/bash

# This script updates the curl_example.sh script to use your Droplet's IP address
# Run this after deploying PostgREST on a Digital Ocean Droplet

# Set variables
DROPLET_IP="$1"

if [ -z "$DROPLET_IP" ]; then
    echo "Error: Droplet IP address not provided."
    echo "Usage: $0 <droplet-ip>"
    exit 1
fi

# Create the updated curl examples script
cat > curl_example_updated.sh << EOF
#!/bin/bash

# Example curl commands for the HTMX Examples API
# These commands use your deployed PostgREST API at http://$DROPLET_IP

echo "Example 1: Vector Similarity Search"
echo "--------------------------------"
curl -X POST "http://$DROPLET_IP/rpc/search_examples_fixed" \\
  -H "Content-Type: application/json" \\
  -d '{"example_id": "inline-validation", "embedding_type": "content", "limit_results": 5}'

echo -e "\\n\\nExample 2: Basic Text Search"
echo "--------------------------------"
curl -X POST "http://$DROPLET_IP/rpc/text_search_examples" \\
  -H "Content-Type: application/json" \\
  -d '{"search_text": "validation", "limit_results": 5}'

echo -e "\\n\\nExample 3: Enhanced Text Search with Relevance Ranking"
echo "--------------------------------"
curl -X POST "http://$DROPLET_IP/rpc/enhanced_text_search" \\
  -H "Content-Type: application/json" \\
  -d '{"search_text": "validation", "limit_results": 5}'

echo -e "\\n\\nExample 4: Multi-Keyword Search"
echo "--------------------------------"
curl -X POST "http://$DROPLET_IP/rpc/keyword_search" \\
  -H "Content-Type: application/json" \\
  -d '{"keywords": ["form", "validation"], "limit_results": 5}'

echo -e "\\n\\nExample 5: Browse All Examples"
echo "--------------------------------"
curl "http://$DROPLET_IP/examples?limit=5"

echo -e "\\n\\nExample 6: Filter Examples by Category"
echo "--------------------------------"
curl "http://$DROPLET_IP/examples?category=eq.UI%20Patterns&limit=5"

echo -e "\\n\\nExample 7: Filter Examples by Complexity Level"
echo "--------------------------------"
curl "http://$DROPLET_IP/examples?complexity_level=eq.beginner&limit=5"

echo -e "\\n\\nExample 8: Get a Specific Example by ID"
echo "--------------------------------"
curl "http://$DROPLET_IP/examples?id=eq.inline-validation"
EOF

# Make the script executable
chmod +x curl_example_updated.sh

echo "Updated curl examples script created: curl_example_updated.sh"
echo "You can run this script to test your deployed API." 