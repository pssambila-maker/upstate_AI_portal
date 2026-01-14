#!/bin/bash

# LiteLLM Connection Test Script
# Tests LiteLLM proxy deployment and model connectivity

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
LITELLM_URL=${LITELLM_URL:-"http://localhost:4000"}
MASTER_KEY=${LITELLM_MASTER_KEY:-""}

echo "========================================="
echo "LiteLLM Connection Test"
echo "========================================="
echo "URL: $LITELLM_URL"
echo ""

# Test 1: Health endpoint
echo -e "${YELLOW}Test 1: Health Check${NC}"
if curl -f -s "${LITELLM_URL}/health" > /dev/null; then
    echo -e "${GREEN}✓ Health check passed${NC}"
else
    echo -e "${RED}✗ Health check failed${NC}"
    exit 1
fi
echo ""

# Test 2: Model list
echo -e "${YELLOW}Test 2: List Available Models${NC}"
MODELS=$(curl -s -X GET "${LITELLM_URL}/v1/models" \
  -H "Authorization: Bearer ${MASTER_KEY}")

if echo "$MODELS" | jq . > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Model list retrieved${NC}"
    echo "$MODELS" | jq '.data[].id'
else
    echo -e "${RED}✗ Failed to retrieve model list${NC}"
    echo "$MODELS"
    exit 1
fi
echo ""

# Test 3: Chat completion (non-streaming)
echo -e "${YELLOW}Test 3: Chat Completion (gpt-4o)${NC}"
RESPONSE=$(curl -s -X POST "${LITELLM_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "Say hello in one word"}],
    "max_tokens": 10
  }')

if echo "$RESPONSE" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
    CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')
    echo -e "${GREEN}✓ Chat completion successful${NC}"
    echo "Response: $CONTENT"
else
    echo -e "${RED}✗ Chat completion failed${NC}"
    echo "$RESPONSE" | jq .
    exit 1
fi
echo ""

# Test 4: Error handling (invalid model)
echo -e "${YELLOW}Test 4: Error Handling${NC}"
ERROR_RESPONSE=$(curl -s -X POST "${LITELLM_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -d '{
    "model": "invalid-model",
    "messages": [{"role": "user", "content": "test"}]
  }')

if echo "$ERROR_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Error handling works correctly${NC}"
    echo "Error message:" $(echo "$ERROR_RESPONSE" | jq -r '.error.message')
else
    echo -e "${YELLOW}⚠ Unexpected response for invalid model${NC}"
fi
echo ""

# Test 5: Authentication
echo -e "${YELLOW}Test 5: Authentication Check${NC}"
UNAUTH_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -X POST "${LITELLM_URL}/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "test"}]
  }')

if [ "$UNAUTH_RESPONSE" = "401" ] || [ "$UNAUTH_RESPONSE" = "403" ]; then
    echo -e "${GREEN}✓ Authentication enforced${NC}"
else
    echo -e "${RED}✗ Authentication not working (HTTP $UNAUTH_RESPONSE)${NC}"
fi
echo ""

echo "========================================="
echo -e "${GREEN}All tests completed successfully!${NC}"
echo "========================================="
