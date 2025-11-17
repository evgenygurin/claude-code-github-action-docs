# AWS Bedrock + OIDC Setup Guide for Claude Code GitHub Actions

## 📋 Overview

This guide will help you set up secure integration of Claude Code GitHub Actions with AWS Bedrock using OIDC (OpenID Connect) for the **eu-north-1** (Stockholm) region.

### Why OIDC?

- ✅ **Security**: Temporary tokens instead of long-lived keys
- ✅ **Automation**: Automatic credential rotation
- ✅ **Granular Control**: Access restriction by repository and branch
- ✅ **Best Practices Compliance**: Recommended by AWS and GitHub

## 🎯 What Will Be Configured

1. OIDC Identity Provider in AWS IAM
2. IAM Role with Bedrock access permissions
3. Trust Policy for your GitHub repository
4. GitHub Workflow with OIDC authentication
5. Minimal necessary permissions (Principle of Least Privilege)

## 📝 Prerequisites

- [ ] AWS account with IAM administrator privileges
- [ ] Amazon Bedrock access enabled
- [ ] Access to Claude models in `eu-north-1` region requested
- [ ] GitHub repository with admin privileges
- [ ] GitHub App installed (or using GITHUB_TOKEN)

## 🔧 Step 1: Enable Amazon Bedrock

### 1.1 Verify Bedrock Access

1. Open AWS Console
2. Navigate to **Amazon Bedrock**
3. Ensure the service is available in **EU (Stockholm) eu-north-1** region

### 1.2 Request Access to Claude Models

1. In Bedrock Console, select **Model access** in the sidebar
2. Click **Manage model access**
3. Find and select Anthropic Claude models:
   - Claude 3.5 Sonnet
   - Claude 3 Opus (optional)
   - Claude 3 Haiku (optional)
4. Click **Request model access**
5. Fill out the form and submit request
6. Wait for confirmation (usually instant or within a few minutes)

### Available Models in eu-north-1

```text
eu.anthropic.claude-3-5-sonnet-20241022-v2:0
eu.anthropic.claude-3-5-haiku-20241022-v1:0
eu.anthropic.claude-3-opus-20240229-v1:0
```

> **Note**: Model IDs include the `eu.` region prefix for European regions.

## 🔐 Step 2: Configure OIDC Identity Provider

### 2.1 Create OIDC Provider in AWS

1. Open **IAM Console**: https://console.aws.amazon.com/iam/
2. In the left menu, select **Identity providers**
3. Click **Add provider**

### 2.2 Provider Configuration

Fill out the form:

**Provider type**: `OpenID Connect`

**Provider URL**:
```text
https://token.actions.githubusercontent.com
```

**Audience**:
```text
sts.amazonaws.com
```

4. Click **Get thumbprint** (loads automatically)
5. Click **Add provider**

### 2.3 Confirm Creation

After creation, you will see:
```text
ARN: arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
```

Save this ARN - you'll need it later.

## 👤 Step 3: Create IAM Role

### 3.1 Start Role Creation

1. In IAM Console, select **Roles** in the left menu
2. Click **Create role**

### 3.2 Select Trusted Entity Type

**Trusted entity type**: `Web identity`

**Identity provider**: Select the created OIDC provider
```text
token.actions.githubusercontent.com
```

**Audience**:
```text
sts.amazonaws.com
```

### 3.3 Configure Access Conditions (IMPORTANT!)

Click **Add condition** to restrict access:

**Condition 1 - Restrict by organization/user:**
- Condition key: `token.actions.githubusercontent.com:sub`
- Operator: `StringLike`
- Value: `repo:YOUR_USERNAME/*:*`
  (this allows all your repositories)

**OR for a specific repository:**
- Value: `repo:YOUR_USERNAME/YOUR_REPO:ref:refs/heads/main`
  (only this repository and main branch)

**Condition 2 - Restrict by audience:**
- Condition key: `token.actions.githubusercontent.com:aud`
- Operator: `StringEquals`
- Value: `sts.amazonaws.com`

Click **Next**

### 3.4 Assign Permissions

**Option A: Use Managed Policy (Easier)**

1. Search for: `AmazonBedrockFullAccess`
2. Select this policy
3. Click **Next**

**Option B: Create Minimal Custom Policy (More Secure)**

1. Click **Create policy**
2. Go to **JSON** tab
3. Paste the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BedrockInvokeModel",
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "arn:aws:bedrock:eu-north-1::foundation-model/anthropic.claude-*"
    }
  ]
}
```

4. Click **Next**
5. Policy name: `GitHubActionsBedrockMinimal`
6. Click **Create policy**
7. Return to role creation and select this policy

### 3.5 Role Name and Description

**Role name**:
```text
GitHubActionsBedrockRole
```

**Description**:
```text
OIDC role for GitHub Actions to access AWS Bedrock in eu-north-1
```

### 3.6 Verify Trust Policy

Before creating, verify the Trust policy (automatically generated):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_USERNAME/YOUR_REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

### 3.7 Create Role

Click **Create role**

### 3.8 Save Role ARN

After creation, copy the Role ARN:
```text
arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsBedrockRole
```

**You'll need this ARN for GitHub Secrets!**

## 🔑 Step 4: Configure GitHub Secrets

### 4.1 Add Secrets

1. Open your repository on GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

### 4.2 Role ARN Secret

**Name**:
```text
AWS_ROLE_TO_ASSUME
```

**Secret**:
```text
arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsBedrockRole
```

(paste your actual ARN from the previous step)

Click **Add secret**

### 4.3 Region Secret (Optional)

**Name**:
```text
AWS_REGION
```

**Secret**:
```text
eu-north-1
```

Click **Add secret**

### 4.4 GitHub App Credentials (If Using)

If using a custom GitHub App:

**Name**: `APP_ID`
**Secret**: Your application ID

**Name**: `APP_PRIVATE_KEY`
**Secret**: Contents of the .pem file

## 📄 Step 5: Create GitHub Workflow

See the ready-made workflow in: `.github/workflows/claude-bedrock-eu.yml`

Or use the example: `examples/claude-bedrock-eu-oidc.yml`

## ✅ Step 6: Testing

### 6.1 Create Test Issue

1. In your repository, create a new issue
2. Write in the description:
```text
@claude hello! Can you help me set up AWS Bedrock?
```

### 6.2 Check Workflow

1. Go to the **Actions** tab
2. Find the running workflow `Claude Code Action (Bedrock EU)`
3. Open the workflow run
4. Check the logs:
   - OIDC authentication successful
   - Claude responds to the issue

### 6.3 Expected Result

Claude should:
- Successfully authenticate via OIDC
- Connect to Bedrock in eu-north-1 region
- Respond in the issue comments

## 🔍 Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Cause**: Trust policy doesn't match repository/branch

**Solution**:
1. Verify the role's Trust policy
2. Ensure `token.actions.githubusercontent.com:sub` is correct
3. Format should be: `repo:OWNER/REPO:ref:refs/heads/BRANCH`

### Error: "Access Denied" when calling Bedrock

**Cause**: Insufficient role permissions

**Solution**:
1. Verify that `AmazonBedrockFullAccess` or custom policy is attached to the role
2. Ensure you have access to Claude models in Bedrock
3. Check the region in workflow (should be `eu-north-1`)

### Error: "Model not found"

**Cause**: Incorrect model ID for region

**Solution**:
- Use model ID with region prefix: `eu.anthropic.claude-...`
- Don't use: `us.anthropic.claude-...` or without prefix

### Error: "Workflow doesn't trigger"

**Cause**: Incorrect trigger configuration

**Solution**:
1. Verify workflow file is in `.github/workflows/`
2. Check YAML syntax
3. Ensure `@claude` is used in comments
4. Verify GitHub Actions are enabled in the repository

## 📊 Monitoring and Logs

### CloudTrail

All Bedrock calls are logged in CloudTrail:

1. AWS Console → CloudTrail → Event history
2. Filters:
   - Event source: `bedrock.amazonaws.com`
   - User name: Your GitHub role
   - Region: eu-north-1

### Cost Monitoring

1. AWS Console → Cost Explorer
2. Filters:
   - Service: Amazon Bedrock
   - Region: EU (Stockholm)
3. Set up budget alerts

## 🔒 Security Best Practices

### 1. Minimal Permissions

✅ Use custom policy instead of `AmazonBedrockFullAccess`
✅ Limit access to only necessary models
✅ Limit access to only necessary regions

### 2. Repository Restrictions

✅ Specify exact repository in Trust policy
✅ Use branch restriction (e.g., only main)
❌ Don't use wildcard `*:*` for all repositories

### 3. Monitoring

✅ Enable CloudTrail for all regions
✅ Set up alerts for unusual activity
✅ Regularly review access logs

### 4. Rotation

✅ OIDC tokens rotate automatically (nothing to do!)
✅ Regularly review and update policies
✅ Remove unused roles

## 📚 Additional Resources

- [AWS OIDC for GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Amazon Bedrock User Guide](https://docs.aws.amazon.com/bedrock/)
- [Claude Models in Bedrock](https://docs.anthropic.com/en/api/claude-on-amazon-bedrock)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

## ✅ Setup Checklist

Ensure everything is complete:

- [ ] Amazon Bedrock enabled in eu-north-1
- [ ] Access to Claude models requested and approved
- [ ] OIDC Identity Provider created
- [ ] IAM Role with correct Trust Policy created
- [ ] Minimal necessary permissions assigned to role
- [ ] Role ARN added to GitHub Secrets
- [ ] GitHub Workflow created and configured
- [ ] Test issue created and Claude responded successfully
- [ ] CloudTrail logs verified
- [ ] Cost monitoring configured

**Congratulations! Secure AWS Bedrock integration with OIDC is set up!** 🎉
