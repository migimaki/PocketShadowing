#!/bin/bash

# Test script for content generation
# Usage: ./scripts/test-generation.sh [series-id or batch-number]

set -e

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

# Check if API_SECRET is set
if [ -z "$API_SECRET" ]; then
  echo "Error: API_SECRET not found in .env file"
  exit 1
fi

# Determine if testing locally or production
if [ "$1" == "local" ]; then
  BASE_URL="http://localhost:3000"
  shift
else
  # Get production URL from Vercel
  BASE_URL=$(vercel ls 2>/dev/null | grep "walking-talking-content" | head -1 | awk '{print "https://"$2}')
  if [ -z "$BASE_URL" ]; then
    echo "Error: Could not determine production URL. Run 'vercel ls' to check deployments."
    exit 1
  fi
fi

echo "Testing endpoint: $BASE_URL/api/generate-content"
echo ""

# Test with series ID or batch number
if [ -n "$1" ]; then
  # Check if input looks like a UUID (series ID)
  if [[ $1 =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
    echo "Testing with series ID: $1"
    curl -X POST "$BASE_URL/api/generate-content" \
      -H "x-api-secret: $API_SECRET" \
      -H "Content-Type: application/json" \
      -d "{\"series_ids\": [\"$1\"]}" \
      | jq '.'
  else
    # Assume it's a batch number
    echo "Testing with batch: $1"
    curl -X POST "$BASE_URL/api/generate-content" \
      -H "x-api-secret: $API_SECRET" \
      -H "Content-Type: application/json" \
      -d "{\"batch\": $1}" \
      | jq '.'
  fi
else
  echo "Usage: $0 [local] [series-id or batch-number]"
  echo ""
  echo "Examples:"
  echo "  $0 local 1                              # Test locally with batch 1"
  echo "  $0 550e8400-e29b-41d4-a716-446655440000  # Test production with series ID"
  echo "  $0 1                                     # Test production with batch 1"
  exit 1
fi
