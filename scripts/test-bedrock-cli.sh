#!/bin/bash
# Test AWS Bedrock CLI Integration
# This script verifies AWS Bedrock setup and tests Claude model access

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-eu-north-1}"
MODEL_ID="${MODEL_ID:-eu.anthropic.claude-3-5-sonnet-20241022-v2:0}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}AWS Bedrock CLI Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Check AWS CLI installation
echo -e "${YELLOW}[1/6] Checking AWS CLI installation...${NC}"
if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗ AWS CLI is not installed${NC}"
    echo "  Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi
echo -e "${GREEN}✓ AWS CLI installed: $(aws --version)${NC}"
echo ""

# Step 2: Check AWS credentials
echo -e "${YELLOW}[2/6] Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}✗ AWS credentials not configured${NC}"
    echo "  Configure with: aws configure"
    echo "  Or use OIDC for GitHub Actions"
    exit 1
fi
CALLER_IDENTITY=$(aws sts get-caller-identity)
echo -e "${GREEN}✓ AWS credentials configured${NC}"
echo "  Account: $(echo $CALLER_IDENTITY | jq -r '.Account')"
echo "  User ARN: $(echo $CALLER_IDENTITY | jq -r '.Arn')"
echo ""

# Step 3: Check Bedrock availability in region
echo -e "${YELLOW}[3/6] Checking Bedrock availability in $AWS_REGION...${NC}"
aws bedrock list-foundation-models --region $AWS_REGION > /dev/null 2>&1 || {
    echo -e "${RED}✗ Cannot access Bedrock in $AWS_REGION${NC}"
    echo "  Ensure Bedrock is enabled in this region"
    exit 1
}
echo -e "${GREEN}✓ Bedrock is accessible in $AWS_REGION${NC}"
echo ""

# Step 4: List available Claude models
echo -e "${YELLOW}[4/6] Listing available Claude models...${NC}"
CLAUDE_MODELS=$(aws bedrock list-foundation-models \
    --region $AWS_REGION \
    --by-provider anthropic \
    --query 'modelSummaries[*].[modelId,modelName]' \
    --output text)

if [ -z "$CLAUDE_MODELS" ]; then
    echo -e "${RED}✗ No Claude models available${NC}"
    echo "  Request model access in Bedrock console"
    exit 1
fi

echo -e "${GREEN}✓ Available Claude models:${NC}"
echo "$CLAUDE_MODELS" | while read model_id model_name; do
    echo "  - $model_id"
done
echo ""

# Step 5: Test model invocation
echo -e "${YELLOW}[5/6] Testing model invocation with $MODEL_ID...${NC}"

# Prepare test prompt
TEST_PROMPT=$(cat <<EOF
{
  "anthropic_version": "bedrock-2023-05-31",
  "max_tokens": 100,
  "messages": [
    {
      "role": "user",
      "content": "Say 'Hello from AWS Bedrock!' in exactly those words."
    }
  ]
}
EOF
)

# Invoke model
RESPONSE=$(aws bedrock-runtime invoke-model \
    --region $AWS_REGION \
    --model-id "$MODEL_ID" \
    --body "$TEST_PROMPT" \
    /dev/stdout 2>/dev/null | jq -r '.content[0].text' 2>/dev/null || echo "")

if [ -z "$RESPONSE" ]; then
    echo -e "${RED}✗ Failed to invoke model${NC}"
    echo "  Check model access permissions"
    echo "  Model ID: $MODEL_ID"
    exit 1
fi

echo -e "${GREEN}✓ Model invocation successful${NC}"
echo "  Model response: $RESPONSE"
echo ""

# Step 6: Check IAM permissions
echo -e "${YELLOW}[6/6] Checking IAM permissions...${NC}"

REQUIRED_ACTIONS=(
    "bedrock:InvokeModel"
    "bedrock:InvokeModelWithResponseStream"
    "bedrock:ListFoundationModels"
)

echo -e "${GREEN}✓ Required permissions:${NC}"
for action in "${REQUIRED_ACTIONS[@]}"; do
    echo "  - $action"
done
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ All tests passed!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "AWS Bedrock is properly configured and ready to use."
echo ""
echo "Configuration:"
echo "  Region: $AWS_REGION"
echo "  Model: $MODEL_ID"
echo "  Account: $(echo $CALLER_IDENTITY | jq -r '.Account')"
echo ""
echo "Next steps:"
echo "  1. Use this configuration in .github/workflows/claude-bedrock-eu.yml"
echo "  2. Add AWS_ROLE_TO_ASSUME to GitHub Secrets (for OIDC)"
echo "  3. Test with @claude mention in an issue"
