#!/bin/bash
# Test Google Vertex AI CLI Integration
# This script verifies Vertex AI setup and tests Claude model access

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_LOCATION="${GCP_LOCATION:-us-central1}"
MODEL_ID="${MODEL_ID:-claude-3-5-sonnet@20241022}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Google Vertex AI CLI Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Check gcloud CLI installation
echo -e "${YELLOW}[1/7] Checking gcloud CLI installation...${NC}"
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}✗ gcloud CLI is not installed${NC}"
    echo "  Install: https://cloud.google.com/sdk/docs/install"
    exit 1
fi
echo -e "${GREEN}✓ gcloud CLI installed: $(gcloud version | head -1)${NC}"
echo ""

# Step 2: Check gcloud authentication
echo -e "${YELLOW}[2/7] Checking gcloud authentication...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo -e "${RED}✗ Not authenticated with gcloud${NC}"
    echo "  Authenticate with: gcloud auth login"
    exit 1
fi
ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1)
echo -e "${GREEN}✓ Authenticated as: $ACTIVE_ACCOUNT${NC}"
echo ""

# Step 3: Check/Set project ID
echo -e "${YELLOW}[3/7] Checking GCP project...${NC}"
if [ -z "$GCP_PROJECT_ID" ]; then
    GCP_PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$GCP_PROJECT_ID" ] || [ "$GCP_PROJECT_ID" = "(unset)" ]; then
        echo -e "${RED}✗ No GCP project configured${NC}"
        echo "  Set with: gcloud config set project PROJECT_ID"
        echo "  Or: export GCP_PROJECT_ID=your-project-id"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Using project: $GCP_PROJECT_ID${NC}"
echo ""

# Step 4: Check Vertex AI API enablement
echo -e "${YELLOW}[4/7] Checking Vertex AI API enablement...${NC}"
if ! gcloud services list --enabled --project=$GCP_PROJECT_ID \
    --filter="name:aiplatform.googleapis.com" --format="value(name)" | grep -q "aiplatform"; then
    echo -e "${RED}✗ Vertex AI API is not enabled${NC}"
    echo "  Enable with: gcloud services enable aiplatform.googleapis.com --project=$GCP_PROJECT_ID"
    exit 1
fi
echo -e "${GREEN}✓ Vertex AI API is enabled${NC}"
echo ""

# Step 5: List available models
echo -e "${YELLOW}[5/7] Listing available Claude models in $GCP_LOCATION...${NC}"

# Try to list models (this requires proper permissions)
MODELS_OUTPUT=$(gcloud ai models list \
    --region=$GCP_LOCATION \
    --project=$GCP_PROJECT_ID \
    --filter="displayName:claude" \
    --format="table(displayName,name)" 2>&1 || echo "")

if echo "$MODELS_OUTPUT" | grep -q "ERROR"; then
    echo -e "${YELLOW}⚠ Cannot list models (permission denied or no models)${NC}"
    echo "  This is normal if using Anthropic models via Vertex AI Model Garden"
    echo "  Continue with model ID: $MODEL_ID"
else
    echo -e "${GREEN}✓ Available models:${NC}"
    echo "$MODELS_OUTPUT"
fi
echo ""

# Step 6: Test model invocation (via REST API)
echo -e "${YELLOW}[6/7] Testing model invocation...${NC}"

# Get access token
ACCESS_TOKEN=$(gcloud auth print-access-token)

# Prepare test request
TEST_REQUEST=$(cat <<EOF
{
  "anthropic_version": "vertex-2023-10-16",
  "messages": [
    {
      "role": "user",
      "content": "Say 'Hello from Google Vertex AI!' in exactly those words."
    }
  ],
  "max_tokens": 100
}
EOF
)

# Invoke model via REST API
ENDPOINT="https://${GCP_LOCATION}-aiplatform.googleapis.com/v1/projects/${GCP_PROJECT_ID}/locations/${GCP_LOCATION}/publishers/anthropic/models/${MODEL_ID}:streamRawPredict"

RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$TEST_REQUEST" \
    "$ENDPOINT" | head -1 | jq -r '.content[0].text' 2>/dev/null || echo "")

if [ -z "$RESPONSE" ]; then
    echo -e "${RED}✗ Failed to invoke model${NC}"
    echo "  Check model access and permissions"
    echo "  Model ID: $MODEL_ID"
    echo "  Endpoint: $ENDPOINT"
    echo ""
    echo "  Common issues:"
    echo "  - Model access not granted in Vertex AI Model Garden"
    echo "  - Incorrect model ID format"
    echo "  - Missing IAM permissions (roles/aiplatform.user)"
    exit 1
fi

echo -e "${GREEN}✓ Model invocation successful${NC}"
echo "  Model response: $RESPONSE"
echo ""

# Step 7: Check IAM permissions
echo -e "${YELLOW}[7/7] Checking IAM permissions...${NC}"

REQUIRED_ROLES=(
    "roles/aiplatform.user"
)

echo -e "${GREEN}✓ Required roles:${NC}"
for role in "${REQUIRED_ROLES[@]}"; do
    echo "  - $role"
done
echo ""

# Check if user has the role
USER_BINDINGS=$(gcloud projects get-iam-policy $GCP_PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:user:$ACTIVE_ACCOUNT" \
    --format="value(bindings.role)" 2>/dev/null || echo "")

if echo "$USER_BINDINGS" | grep -q "roles/aiplatform.user\|roles/owner\|roles/editor"; then
    echo -e "${GREEN}✓ User has required permissions${NC}"
else
    echo -e "${YELLOW}⚠ Cannot verify user permissions${NC}"
    echo "  Ensure service account has: roles/aiplatform.user"
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ All tests passed!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Google Vertex AI is properly configured and ready to use."
echo ""
echo "Configuration:"
echo "  Project ID: $GCP_PROJECT_ID"
echo "  Location: $GCP_LOCATION"
echo "  Model: $MODEL_ID"
echo "  Account: $ACTIVE_ACCOUNT"
echo ""
echo "Next steps:"
echo "  1. Create service account for GitHub Actions"
echo "  2. Grant roles/aiplatform.user to service account"
echo "  3. Configure Workload Identity Federation"
echo "  4. Add secrets to GitHub repository"
echo "  5. Use examples/claude-vertex.yml workflow"
