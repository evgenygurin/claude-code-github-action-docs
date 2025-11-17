# Security Best Practices for Claude Code GitHub Actions

## Overview

Security is paramount when integrating AI assistants into your development workflow. This guide covers best practices for securing your Claude Code GitHub Actions implementation.

## Core Security Principles

### 1. Never Commit Secrets

**❌ BAD - Hardcoded secrets:**

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: "sk-ant-1234567890"  # NEVER DO THIS!
```

**✅ GOOD - Using GitHub Secrets:**

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### 2. Principle of Least Privilege

Grant only the minimum permissions required:

```yaml
# Minimal permissions
permissions:
  contents: write        # Only if Claude needs to modify files
  pull-requests: write   # Only if Claude creates PRs
  issues: write          # Only if Claude responds to issues

# If Claude only needs to read:
permissions:
  contents: read
  pull-requests: read
  issues: read
```

### 3. Use OIDC Instead of Long-Lived Credentials

For AWS Bedrock and Google Vertex AI, use OpenID Connect (OIDC) for temporary credentials:

**AWS Example:**

```yaml
- name: Configure AWS Credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
    aws-region: us-west-2
    # No long-lived access keys needed!
```

**Google Cloud Example:**

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
    service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
    # No service account keys needed!
```

## GitHub Actions Security

### Pin Actions to Commit SHA

**❌ Less secure - using tags:**

```yaml
uses: anthropics/claude-code-action@v1  # Tag can be moved
```

**✅ More secure - using commit SHA:**

```yaml
uses: anthropics/claude-code-action@a1b2c3d4...  # Immutable commit
```

### Set Workflow Timeouts

Prevent runaway costs and potential abuse:

```yaml
jobs:
  claude:
    runs-on: ubuntu-latest
    timeout-minutes: 30  # Prevents infinite loops

    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          claude_args: |
            --max-turns 10  # Limits API calls
        timeout-minutes: 25  # Step-level timeout
```

### Use Concurrency Controls

Prevent multiple instances from running simultaneously:

```yaml
jobs:
  claude:
    concurrency:
      group: claude-${{ github.event.issue.number }}
      cancel-in-progress: false  # Don't cancel ongoing work
```

### Restrict Workflow Triggers

Only trigger workflows for trusted events:

```yaml
# Good: Specific events only
on:
  issue_comment:
    types: [created]

# Be careful with:
on:
  pull_request_target:  # Runs with repo permissions for fork PRs
    # Only use if you understand the security implications
```

## API Key Management

### GitHub Secrets Best Practices

1. **Use Repository Secrets** for single-repo setups
2. **Use Environment Secrets** for multi-environment deployments
3. **Use Organization Secrets** for shared credentials

**Setting up secrets:**

```bash
# Via GitHub CLI
gh secret set ANTHROPIC_API_KEY --body "your-key-here"

# Via GitHub UI
Settings → Secrets and variables → Actions → New repository secret
```

### API Key Rotation

Regularly rotate API keys to minimize exposure:

```bash
# 1. Generate new key at console.anthropic.com
# 2. Update GitHub secret
gh secret set ANTHROPIC_API_KEY --body "new-key-here"
# 3. Verify workflows still work
# 4. Delete old key from Anthropic console
```

### Secret Scope Limitation

Pass secrets only to steps that need them:

```yaml
# Good: Secret scoped to specific step
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}

# Avoid: Exposing all secrets to step
- run: ./script.sh
  env:
    ALL_SECRETS: ${{ toJSON(secrets) }}  # Don't do this!
```

## Repository Configuration

### Set Default Permissions to Read-Only

In repository settings:

1. Go to Settings → Actions → General
2. Scroll to "Workflow permissions"
3. Select "Read repository contents permission"
4. Uncheck "Allow GitHub Actions to create and approve pull requests"

Then explicitly grant write permissions in workflows that need them.

### Require Approval for First-Time Contributors

```yaml
# Settings → Actions → General → Fork pull request workflows
# Set to "Require approval for first-time contributors"
```

### Enable Branch Protection

Protect important branches:

1. Settings → Branches → Add rule
2. Branch name pattern: `main` or `master`
3. Enable:
   - Require pull request reviews
   - Require status checks
   - Require conversation resolution
   - Restrict who can push

## Cloud Provider Security

### AWS Bedrock

1. **Use IAM Roles with Minimal Permissions**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "arn:aws:bedrock:*::foundation-model/anthropic.claude-*"
    }
  ]
}
```

2. **Configure Trust Policy for Specific Repository**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

3. **Enable CloudTrail Logging**

Monitor all Bedrock API calls for security auditing.

### Google Vertex AI

1. **Use Workload Identity Federation**

```yaml
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
    service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
```

2. **Grant Minimal IAM Roles**

```bash
# Only grant Vertex AI User role
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SERVICE_ACCOUNT" \
  --role="roles/aiplatform.user"
```

3. **Configure Attribute Conditions**

Restrict identity pool to specific repository:

```yaml
google.subject == "repo:OWNER/REPO:ref:refs/heads/main"
```

## Monitoring and Auditing

### Enable GitHub Actions Logs

Always keep workflow logs enabled for security auditing:

1. Settings → Actions → General
2. Keep "Allow GitHub Actions to..." enabled
3. Regularly review workflow run logs

### Monitor API Usage

Track Claude API usage to detect anomalies:

```bash
# Check recent API usage at:
# https://console.anthropic.com/settings/usage
```

### Set Up Cost Alerts

1. Configure spending limits in Anthropic Console
2. Set up budget alerts for GitHub Actions
3. Monitor for unexpected usage spikes

### Audit GitHub App Permissions

Regularly review installed apps:

1. Settings → Applications
2. Review installed apps
3. Revoke access for unused apps
4. Update permissions as needed

## Code Review Security

### Review Claude's Suggestions

Always review Claude's code before merging:

1. **Security vulnerabilities**: SQL injection, XSS, etc.
2. **Credentials exposure**: No hardcoded secrets
3. **Permission escalation**: Appropriate access controls
4. **Input validation**: Proper sanitization
5. **Error handling**: No sensitive data in errors

### Use Status Checks

Require security checks before merging:

```yaml
name: Security Checks
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run security scan
        uses: securego/gosec@master  # Example scanner

      - name: Check for secrets
        uses: trufflesecurity/trufflehog@main
```

## Incident Response

### If API Key is Compromised

1. **Immediately revoke the key** in Anthropic Console
2. **Generate new key** and update GitHub secrets
3. **Review recent API usage** for unauthorized access
4. **Check workflow logs** for suspicious activity
5. **Audit affected repositories**

### If GitHub Token is Compromised

1. **Revoke the token** immediately
2. **Review recent repository access**
3. **Rotate all related secrets**
4. **Enable 2FA** if not already enabled
5. **Review audit logs**

## Security Checklist

Before deploying Claude Code GitHub Actions:

- [ ] API keys stored in GitHub Secrets
- [ ] Minimal permissions configured
- [ ] Workflow timeouts set
- [ ] Concurrency controls enabled
- [ ] Branch protection rules active
- [ ] OIDC configured (if using cloud providers)
- [ ] Security scanning enabled
- [ ] Code review process in place
- [ ] Monitoring and alerting configured
- [ ] Incident response plan documented

## Additional Resources

- [GitHub Actions Security Hardening](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Anthropic Security Best Practices](https://www.anthropic.com/security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [Google Cloud Security Best Practices](https://cloud.google.com/security/best-practices)

## Need Help?

If you discover a security issue:

1. **Don't** open a public issue
2. Email security concerns to relevant security teams
3. Follow responsible disclosure practices
4. Document and preserve evidence

Security is an ongoing process - stay vigilant!
