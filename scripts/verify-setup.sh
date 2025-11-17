#!/bin/bash
# Verify Claude Code GitHub Actions Setup
# This script checks all prerequisites and configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Claude Code GitHub Actions Setup Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Track overall status
ERRORS=0
WARNINGS=0

# Function to check command existence
check_command() {
    local cmd=$1
    local name=$2
    local install_url=$3

    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name installed: $(which $cmd)"
        return 0
    else
        echo -e "${RED}✗${NC} $name not found"
        echo -e "  ${CYAN}Install:${NC} $install_url"
        ((ERRORS++))
        return 1
    fi
}

# Function to check file existence
check_file() {
    local file=$1
    local description=$2

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description found: $file"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $description not found: $file"
        ((WARNINGS++))
        return 1
    fi
}

# Function to check directory existence
check_directory() {
    local dir=$1
    local description=$2

    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description found: $dir"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $description not found: $dir"
        ((WARNINGS++))
        return 1
    fi
}

echo -e "${CYAN}[1/5] Checking CLI Tools${NC}"
echo "-----------------------------------"
check_command "git" "Git" "https://git-scm.com/downloads"
check_command "gh" "GitHub CLI" "https://cli.github.com/"
check_command "jq" "jq (JSON processor)" "https://stedolan.github.io/jq/"
check_command "curl" "curl" "https://curl.se/"
echo ""

echo -e "${CYAN}[2/5] Checking Cloud Provider CLIs${NC}"
echo "-----------------------------------"
if check_command "aws" "AWS CLI" "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"; then
    echo "  Version: $(aws --version 2>&1)"

    # Check AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
        echo -e "  ${GREEN}✓${NC} AWS credentials configured (Account: $ACCOUNT)"
    else
        echo -e "  ${YELLOW}⚠${NC} AWS credentials not configured"
        echo "    Run: aws configure"
        ((WARNINGS++))
    fi
fi

if check_command "gcloud" "Google Cloud CLI" "https://cloud.google.com/sdk/docs/install"; then
    echo "  Version: $(gcloud version | head -1)"

    # Check gcloud auth
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1)
        echo -e "  ${GREEN}✓${NC} gcloud authenticated ($ACCOUNT)"
    else
        echo -e "  ${YELLOW}⚠${NC} gcloud not authenticated"
        echo "    Run: gcloud auth login"
        ((WARNINGS++))
    fi
fi
echo ""

echo -e "${CYAN}[3/5] Checking Repository Structure${NC}"
echo "-----------------------------------"
check_directory ".github" "GitHub directory"
check_directory ".github/workflows" "Workflows directory"
check_file ".github/workflows/claude.yml" "Main Claude workflow" || \
check_file ".github/workflows/claude-bedrock-eu.yml" "Bedrock workflow"
check_file "CLAUDE.md" "Project guidelines"
check_file "README.md" "README file"
check_directory "docs" "Documentation directory"
check_directory "examples" "Examples directory"
echo ""

echo -e "${CYAN}[4/5] Checking Documentation${NC}"
echo "-----------------------------------"
check_file "docs/getting-started.md" "Getting Started guide"
check_file "docs/aws-bedrock-oidc-setup.md" "AWS Bedrock OIDC setup"
check_file "docs/security-best-practices.md" "Security best practices"
check_file "docs/troubleshooting-guide.md" "Troubleshooting guide"
echo ""

echo -e "${CYAN}[5/5] Checking GitHub Configuration${NC}"
echo "-----------------------------------"

# Check if gh is authenticated
if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        REPO_INFO=$(gh repo view --json nameWithOwner,owner,name 2>/dev/null || echo "{}")
        if [ "$REPO_INFO" != "{}" ]; then
            REPO_NAME=$(echo $REPO_INFO | jq -r '.nameWithOwner')
            REPO_OWNER=$(echo $REPO_INFO | jq -r '.owner.login')
            echo -e "${GREEN}✓${NC} GitHub repository: $REPO_NAME"
            echo -e "${GREEN}✓${NC} Repository owner: $REPO_OWNER"

            # Check if GitHub Actions is enabled
            ACTIONS_STATUS=$(gh api "repos/$REPO_NAME/actions/permissions" --jq '.enabled' 2>/dev/null || echo "unknown")
            if [ "$ACTIONS_STATUS" = "true" ]; then
                echo -e "${GREEN}✓${NC} GitHub Actions enabled"
            else
                echo -e "${YELLOW}⚠${NC} GitHub Actions status unknown"
                ((WARNINGS++))
            fi
        else
            echo -e "${YELLOW}⚠${NC} Not in a GitHub repository"
            ((WARNINGS++))
        fi
    else
        echo -e "${YELLOW}⚠${NC} GitHub CLI not authenticated"
        echo "  Run: gh auth login"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠${NC} GitHub CLI not installed"
    ((WARNINGS++))
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Verification Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your environment is ready for Claude Code GitHub Actions."
    EXIT_CODE=0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Setup complete with $WARNINGS warning(s)${NC}"
    echo ""
    echo "Your environment is mostly ready, but some optional components are missing."
    EXIT_CODE=0
else
    echo -e "${RED}✗ Setup incomplete: $ERRORS error(s), $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please address the errors above before proceeding."
    EXIT_CODE=1
fi

echo ""
echo "Next steps:"
echo "  1. Install missing tools (if any)"
echo "  2. Configure cloud provider credentials"
echo "  3. Set up GitHub secrets"
echo "  4. Test with: ./scripts/test-bedrock-cli.sh (for AWS)"
echo "  5. Test with: ./scripts/test-vertex-cli.sh (for GCP)"
echo ""

exit $EXIT_CODE
