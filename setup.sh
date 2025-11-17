#!/bin/bash

# Claude Code GitHub Actions Setup Script
# This script helps you quickly set up Claude Code in your GitHub repository

set -e

echo "🤖 Claude Code GitHub Actions Setup"
echo "===================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# Check if we're in a git repository
if [ ! -d .git ]; then
    print_error "This script must be run from the root of a git repository"
    exit 1
fi

echo "Step 1: Checking prerequisites..."
echo ""

# Check if GitHub CLI is installed (optional but helpful)
if command -v gh &> /dev/null; then
    print_status "GitHub CLI is installed"
    GH_AVAILABLE=true
else
    print_warning "GitHub CLI not found. You'll need to manually set up secrets."
    GH_AVAILABLE=false
fi

echo ""
echo "Step 2: Creating workflow directory..."
mkdir -p .github/workflows
print_status "Created .github/workflows directory"

echo ""
echo "Step 3: Copying workflow files..."

# Check if workflow files already exist
if [ -f .github/workflows/claude.yml ]; then
    print_warning "claude.yml already exists. Backing up to claude.yml.bak"
    cp .github/workflows/claude.yml .github/workflows/claude.yml.bak
fi

# Copy the main workflow
if [ -f .github/workflows/claude.yml ]; then
    print_status "Main Claude workflow already exists"
else
    print_error "Main Claude workflow not found. Please ensure workflows are properly set up."
fi

echo ""
echo "Step 4: Setting up CLAUDE.md..."

if [ -f CLAUDE.md ]; then
    print_status "CLAUDE.md file exists"
else
    print_warning "CLAUDE.md not found. This file helps Claude understand your project."
    echo "Would you like to create a basic CLAUDE.md? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cat > CLAUDE.md << 'EOF'
# Project Guidelines for Claude

## Project Overview
[Describe your project here]

## Coding Standards
[Define your coding standards]

## Review Criteria
[What should Claude focus on during reviews?]

## Important Files
[List key files Claude should know about]
EOF
        print_status "Created basic CLAUDE.md template"
    fi
fi

echo ""
echo "Step 5: GitHub App Installation"
echo ""

if [ "$GH_AVAILABLE" = true ]; then
    echo "Would you like to open the Claude GitHub App installation page? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        open "https://github.com/apps/claude" 2>/dev/null || xdg-open "https://github.com/apps/claude" 2>/dev/null || echo "Please visit: https://github.com/apps/claude"
    fi
else
    echo "Please install the Claude GitHub App:"
    echo "https://github.com/apps/claude"
fi

echo ""
echo "Step 6: API Key Configuration"
echo ""

if [ "$GH_AVAILABLE" = true ]; then
    echo "Would you like to set up the ANTHROPIC_API_KEY secret using GitHub CLI? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Please enter your Anthropic API key:"
        read -s api_key
        echo ""

        if [ -n "$api_key" ]; then
            gh secret set ANTHROPIC_API_KEY --body="$api_key"
            print_status "API key secret has been set"
        else
            print_error "No API key provided"
        fi
    else
        echo "Please add your API key manually:"
        echo "1. Go to your repository settings on GitHub"
        echo "2. Navigate to Settings > Secrets and variables > Actions"
        echo "3. Click 'New repository secret'"
        echo "4. Name: ANTHROPIC_API_KEY"
        echo "5. Value: Your Anthropic API key"
    fi
else
    echo "Please add your API key manually:"
    echo "1. Go to your repository settings on GitHub"
    echo "2. Navigate to Settings > Secrets and variables > Actions"
    echo "3. Click 'New repository secret'"
    echo "4. Name: ANTHROPIC_API_KEY"
    echo "5. Value: Your Anthropic API key from https://console.anthropic.com"
fi

echo ""
echo "Step 7: Testing the setup"
echo ""

echo "To test your setup:"
echo "1. Create an issue or PR in your repository"
echo "2. Comment with: @claude hello"
echo "3. Claude should respond within a few seconds"
echo ""

print_status "Setup complete!"
echo ""
echo "📚 Next steps:"
echo "- Review the workflow files in .github/workflows/"
echo "- Customize CLAUDE.md for your project"
echo "- Check examples/ directory for more workflow templates"
echo "- Read the documentation in docs/ for advanced configuration"
echo ""
echo "Need help? Check docs/troubleshooting-guide.md or create an issue!"