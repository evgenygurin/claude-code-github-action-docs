# Testing and Verification Scripts

This directory contains CLI testing scripts to verify AWS Bedrock and Google Vertex AI integration for Claude Code GitHub Actions.

## Available Scripts

### 1. Setup Verification (`verify-setup.sh`)

Comprehensive check of your local environment and repository configuration.

**Usage:**

```bash
./scripts/verify-setup.sh
```

**What it checks:**

- CLI tools (git, gh, jq, curl)
- Cloud provider CLIs (aws, gcloud)
- Cloud credentials configuration
- Repository structure
- Documentation completeness
- GitHub Actions enablement

**Output:**

- ✓ Green checkmarks for successful checks
- ⚠ Yellow warnings for optional components
- ✗ Red errors for required missing components

### 2. AWS Bedrock CLI Test (`test-bedrock-cli.sh`)

Tests AWS Bedrock integration with Claude models.

**Prerequisites:**

- AWS CLI installed
- AWS credentials configured (or OIDC for GitHub Actions)
- Amazon Bedrock enabled in target region
- Access to Claude models granted

**Usage:**

```bash
# Use default settings (eu-north-1, Claude 3.5 Sonnet)
./scripts/test-bedrock-cli.sh

# Override region
AWS_REGION=us-east-1 ./scripts/test-bedrock-cli.sh

# Override model
MODEL_ID=eu.anthropic.claude-3-5-haiku-20241022-v1:0 ./scripts/test-bedrock-cli.sh
```

**Environment Variables:**

- `AWS_REGION` - AWS region (default: `eu-north-1`)
- `MODEL_ID` - Claude model ID (default: `eu.anthropic.claude-3-5-sonnet-20241022-v2:0`)

**What it tests:**

1. AWS CLI installation
2. AWS credentials validity
3. Bedrock API accessibility
4. Available Claude models
5. Model invocation
6. IAM permissions

### 3. Google Vertex AI CLI Test (`test-vertex-cli.sh`)

Tests Google Vertex AI integration with Claude models.

**Prerequisites:**

- Google Cloud CLI installed
- gcloud authenticated
- GCP project configured
- Vertex AI API enabled
- Access to Claude models granted

**Usage:**

```bash
# Use default settings (us-central1, Claude 3.5 Sonnet)
./scripts/test-vertex-cli.sh

# Override project
GCP_PROJECT_ID=my-project ./scripts/test-vertex-cli.sh

# Override location
GCP_LOCATION=europe-west4 ./scripts/test-vertex-cli.sh

# Override model
MODEL_ID=claude-3-5-haiku@20241022 ./scripts/test-vertex-cli.sh
```

**Environment Variables:**

- `GCP_PROJECT_ID` - Google Cloud project ID (auto-detected from gcloud config)
- `GCP_LOCATION` - Vertex AI location (default: `us-central1`)
- `MODEL_ID` - Claude model ID (default: `claude-3-5-sonnet@20241022`)

**What it tests:**

1. gcloud CLI installation
2. gcloud authentication
3. GCP project configuration
4. Vertex AI API enablement
5. Available Claude models
6. Model invocation via REST API
7. IAM permissions

## Quick Start

### 1. Verify Your Setup

Start here to check if your environment is ready:

```bash
./scripts/verify-setup.sh
```

### 2. Test AWS Bedrock (if using)

```bash
# Configure AWS credentials first
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_REGION=eu-north-1

# Run test
./scripts/test-bedrock-cli.sh
```

### 3. Test Google Vertex AI (if using)

```bash
# Authenticate with gcloud first
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable Vertex AI API
gcloud services enable aiplatform.googleapis.com

# Run test
./scripts/test-vertex-cli.sh
```

## Troubleshooting

### AWS Bedrock

**Error: "AWS credentials not configured"**

- Run: `aws configure`
- Or set environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- For GitHub Actions: Use OIDC (see `docs/aws-bedrock-oidc-setup.md`)

**Error: "Cannot access Bedrock in region"**

- Ensure Bedrock is available in your region
- Check IAM permissions: `bedrock:ListFoundationModels`

**Error: "No Claude models available"**

- Request model access in Bedrock console
- Navigate to: Bedrock → Model access → Manage model access

**Error: "Failed to invoke model"**

- Verify model ID matches region (use `eu.` prefix for eu-north-1)
- Check IAM permissions: `bedrock:InvokeModel`

### Google Vertex AI

**Error: "gcloud not authenticated"**

- Run: `gcloud auth login`
- Or: `gcloud auth activate-service-account --key-file=key.json`

**Error: "Vertex AI API is not enabled"**

- Enable with: `gcloud services enable aiplatform.googleapis.com`

**Error: "Cannot list models"**

- This is normal for Anthropic models
- Models are accessed via Model Garden, not listed in your project

**Error: "Failed to invoke model"**

- Check model access in Vertex AI Model Garden
- Verify IAM role: `roles/aiplatform.user`
- Ensure correct model ID format (use `@` not `:`)

## Required Tools

### Core Tools

- `bash` - Shell script interpreter
- `curl` - HTTP client
- `jq` - JSON processor
- `git` - Version control

### Cloud Provider CLIs

**For AWS Bedrock:**

- `aws` - AWS CLI v2
- Install: <https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>

**For Google Vertex AI:**

- `gcloud` - Google Cloud CLI
- Install: <https://cloud.google.com/sdk/docs/install>

### Optional Tools

- `gh` - GitHub CLI (for repository checks)
- Install: <https://cli.github.com/>

## CI/CD Integration

These scripts can be used in CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Verify Setup
  run: ./scripts/verify-setup.sh

- name: Test Bedrock Integration
  run: ./scripts/test-bedrock-cli.sh
  env:
    AWS_REGION: eu-north-1
```

## Security Best Practices

1. **Never commit credentials** to repository
2. **Use OIDC for GitHub Actions** instead of long-lived keys
3. **Use environment variables** for sensitive configuration
4. **Test in non-production environment** first
5. **Monitor CloudTrail/Cloud Logging** for API calls

## Additional Resources

- [AWS Bedrock OIDC Setup](../docs/aws-bedrock-oidc-setup.md)
- [Security Best Practices](../docs/security-best-practices.md)
- [Troubleshooting Guide](../docs/troubleshooting-guide.md)
- [Getting Started Guide](../docs/getting-started.md)

## Support

If you encounter issues:

1. Check script output for specific error messages
2. Review documentation links provided in errors
3. Ensure all prerequisites are met
4. Verify cloud provider service enablement
5. Check IAM/permissions configuration

For AWS Bedrock support: <https://docs.aws.amazon.com/bedrock/>
For Google Vertex AI support: <https://cloud.google.com/vertex-ai/docs>
