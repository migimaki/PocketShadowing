#!/bin/bash

# Test script for local development
# Make sure you have npm run dev running in another terminal

echo "Testing WalkingTalking Content Generator locally..."
echo ""

# Load API_SECRET from .env file
if [ -f .env ]; then
  export $(cat .env | grep API_SECRET | xargs)
else
  echo "Error: .env file not found!"
  exit 1
fi

if [ -z "$API_SECRET" ]; then
  echo "Error: API_SECRET not found in .env file!"
  exit 1
fi

echo "Making request to http://localhost:3000/api/generate-content"
echo "This may take 1-2 minutes to complete..."
echo ""

curl -X POST http://localhost:3000/api/generate-content \
  -H "x-api-secret: $API_SECRET" \
  -H "Content-Type: application/json" \
  -v

echo ""
echo "Test complete!"
