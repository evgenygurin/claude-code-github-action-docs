# Setup and Configuration

This document details the various methods for setting up Claude Code GitHub Actions, from quick installation to advanced configurations for cloud providers.

## 1. Quick Setup via Claude Code CLI

The most straightforward way to get started is by using the Claude Code Command Line Interface (CLI).

### Prerequisites

*   **Python 3.x** installed.
*   **Poetry** (recommended for Python dependency management) or `pip`.
*   **Repository Admin Privileges**: Required to install the GitHub App and configure secrets.

### Steps

1.  **Install Claude Code CLI**:
    Open your terminal and run the following command to install the Claude Code CLI:
    ```bash
    curl -fsSL https://claude.ai/install.sh | bash
    ```
    Alternatively, if you prefer `npm`:
    ```bash
    npm install -g @anthropic-ai/claude-code
    ```
2.  **Initialize in Your Project**:
    Navigate to your project's root directory and execute:
    ```bash
    claude
    ```
    This command will guide you through an initial setup process, including authorization with Claude.ai.
3.  **Install GitHub App**:
    Within the Claude Code CLI, run:
    ```bash
    /install-github-app
    ```
    This command automates several critical steps:
    *   Installs the official Claude GitHub App into your chosen repository.
    *   Configures necessary GitHub secrets, including `ANTHROPIC_API_KEY`.
    *   Creates a foundational workflow file (`.github/workflows/claude.yml`) in your repository.

    **Note**: The GitHub App will request read and write permissions for `Contents`, `Issues`, and `Pull requests`. This quick setup method is primarily for users leveraging the direct Claude API. For AWS Bedrock or Google Vertex AI integrations, refer to the dedicated sections below.

## 2. Manual Setup

If the quick setup is not feasible or if you require more granular control, follow these manual steps.

### Steps

1.  **Install the Claude GitHub App**:
    Go to [https://github.com/apps/claude](https://github.com/apps/claude) and click "Install". Select the repositories where you want to enable Claude Code and grant the requested permissions:
    *   `Contents`: Read & write (to modify repository files)
    *   `Issues`: Read & write (to respond to issues)
    *   `Pull requests`: Read & write (to create PRs and push changes)
2.  **Add `ANTHROPIC_API_KEY` to Repository Secrets**:
    *   Obtain your Claude API key from the [Anthropic Console](https://console.anthropic.com/).
    *   In your GitHub repository, navigate to `Settings` > `Secrets and variables` > `Actions`.
    *   Click `New repository secret` and create a secret with:
        *   **Name**: `ANTHROPIC_API_KEY`
        *   **Value**: Your Claude API key.
3.  **Create Workflow File**:
    Create a new file at `.github/workflows/claude.yml` with the following basic configuration:
    ```yaml
    name: Claude Code

    on:
      issue_comment:
        types: [created]
      pull_request_review_comment:
        types: [created]

    permissions:
      contents: write
      pull-requests: write
      issues: write

    jobs:
      claude:
        runs-on: ubuntu-latest
        steps:
          - uses: anthropics/claude-code-action @v1
            with:
              anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    ```

## 3. Upgrading from Beta to v1.0

Claude Code GitHub Actions v1.0 introduces significant changes from its beta version. If you are upgrading, ensure you apply the following modifications to your workflow files.

### Essential Changes

1.  **Update Action Version**: Change `@beta` to `@v1` in your `uses` statement.
2.  **Remove Mode Configuration**: The `mode: "tag"` or `mode: "agent"` parameters are now auto-detected and should be removed.
3.  **Update Prompt Inputs**: Replace `direct_prompt` with `prompt`.
4.  **Consolidate CLI Options**: Convert individual CLI options like `max_turns`, `model`, `custom_instructions` into the `claude_args` parameter.

### Breaking Changes Reference

| Old Beta Input        | New v1.0 Input                   |
| :-------------------- | :------------------------------- |
| `mode`                | *(Removed - auto-detected)*      |
| `direct_prompt`       | `prompt`                         |
| `override_prompt`     | `prompt` with GitHub variables   |
| `custom_instructions` | `claude_args: --system-prompt`   |
| `max_turns`           | `claude_args: --max-turns`       |
| `model`               | `claude_args: --model`           |
| `allowed_tools`       | `claude_args: --allowedTools`    |
| `disallowed_tools`    | `claude_args: --disallowedTools` |
| `claude_env`          | `settings` JSON format           |

## 4. Cloud Provider Integrations (AWS Bedrock & Google Vertex AI)

For enterprise environments, Claude Code GitHub Actions supports integration with AWS Bedrock and Google Vertex AI, offering enhanced control over data residency, billing, and security.

### 4.1 Prerequisites for Cloud Providers

Before configuring with a cloud provider, you generally need:

*   A **Google Cloud Project** with Vertex AI enabled OR an **AWS account** with Amazon Bedrock enabled.
*   **Workload Identity Federation** (GCP) or **GitHub OIDC Identity Provider** (AWS) configured for secure authentication.
*   A **Service Account** (GCP) or **IAM Role** (AWS) with the necessary permissions for Vertex AI or Bedrock.
*   A **Custom GitHub App** (recommended for enhanced control and security) or the default `GITHUB_TOKEN`.

### 4.2 Custom GitHub App (Recommended for 3rd Party Providers)

Creating your own GitHub App provides the best control and security when integrating with third-party cloud providers.

#### Steps to Create a Custom GitHub App

1.  **Navigate to GitHub App Creation**: Go to [https://github.com/settings/apps/new](https://github.com/settings/apps/new).
2.  **Basic Information**:
    *   **GitHub App name**: Choose a unique and descriptive name (e.g., "YourOrg Claude Assistant").
    *   **Homepage URL**: Provide your organization's website or the repository URL.
3.  **Configure App Settings**:
    *   **Webhooks**: Uncheck "Active" as webhooks are not typically required for this integration.
4.  **Set Required Permissions**:
    *   **Repository permissions**:
        *   `Contents`: Read & Write
        *   `Issues`: Read & Write
        *   `Pull requests`: Read & Write
5.  **Create App**: Click "Create GitHub App".
6.  **Generate Private Key**: After creation, click "Generate a private key" and securely save the downloaded `.pem` file.
7.  **Note App ID**: Record your App ID from the app settings page.
8.  **Install App to Repository**:
    *   From your app's settings page, click "Install App" in the left sidebar.
    *   Select your account or organization.
    *   Choose "Only select repositories" and select the specific repository.
    *   Click "Install".
9.  **Add Private Key as Secret**:
    *   In your GitHub repository, go to `Settings` > `Secrets and variables` > `Actions`.
    *   Create a new secret named `APP_PRIVATE_KEY` and paste the entire content of your `.pem` file.
10. **Add App ID as Secret**:
    *   Create another new secret named `APP_ID` with your GitHub App's ID.

This custom app will be used with the `actions/create-github-app-token` action in your workflows to generate authentication tokens.

### 4.3 AWS Bedrock Configuration

This section outlines the setup for integrating Claude Code GitHub Actions with AWS Bedrock.

#### Prerequisites

*   Amazon Bedrock enabled in your AWS account.
*   Access to Claude models requested within Amazon Bedrock.
*   GitHub configured as an OIDC Identity Provider in AWS.
*   An IAM role with Bedrock permissions that trusts GitHub Actions.

#### AWS IAM Setup (Conceptual)

1.  **Create OIDC Provider**: Establish GitHub as an OpenID Connect (OIDC) provider in AWS IAM.
2.  **Create IAM Role**: Create an IAM role that GitHub Actions can assume. This role's trust policy must allow `sts:AssumeRoleWithWebIdentity` from the GitHub OIDC provider, with conditions to restrict access to your specific repository.
3.  **Attach Bedrock Policy**: Attach the `AmazonBedrockFullAccess` (or a more granular) policy to the IAM role.

#### Required GitHub Secrets

*   `AWS_ROLE_TO_ASSUME`: The Amazon Resource Name (ARN) of the IAM role created for Bedrock access.
*   `APP_ID`: Your custom GitHub App ID.
*   `APP_PRIVATE_KEY`: The private key content of your custom GitHub App.

#### Workflow Example (Conceptual)

A workflow for AWS Bedrock would involve steps to:
1.  Checkout the repository.
2.  Generate a GitHub App token using `actions/create-github-app-token`.
3.  Configure AWS credentials using `aws-actions/configure-aws-credentials` with the `role-to-assume` and `aws-region`.
4.  Execute the `anthropics/claude-code-action @v1` with `use_bedrock: "true"` and appropriate `claude_args` for the Bedrock model ID.

### 4.4 Google Vertex AI Configuration

This section outlines the setup for integrating Claude Code GitHub Actions with Google Vertex AI.

#### Prerequisites

*   Vertex AI API enabled in your Google Cloud project.
*   Workload Identity Federation configured for GitHub.
*   A service account with Vertex AI permissions.

#### Google Cloud Setup (Conceptual)

1.  **Enable APIs**: Enable `iamcredentials.googleapis.com`, `sts.googleapis.com`, and `aiplatform.googleapis.com` in your GCP project.
2.  **Create Workload Identity Pool**: Create a Workload Identity Pool in GCP.
3.  **Add GitHub OIDC Provider**: Add a GitHub OIDC provider to the Workload Identity Pool, mapping GitHub attributes (like repository and owner) to Google Cloud attributes.
4.  **Create Service Account**: Create a dedicated service account and grant it the `Vertex AI User` role.
5.  **Configure IAM Binding**: Allow the Workload Identity Pool to impersonate the service account, restricting access to your specific GitHub repository.

#### Required GitHub Secrets

*   `GCP_WORKLOAD_IDENTITY_PROVIDER`: The full resource name of your Workload Identity Provider.
*   `GCP_SERVICE_ACCOUNT`: The email address of the service account created for Vertex AI access.
*   `APP_ID`: Your custom GitHub App ID.
*   `APP_PRIVATE_KEY`: The private key content of your custom GitHub App.

#### Workflow Example (Conceptual)

A workflow for Google Vertex AI would involve steps to:
1.  Checkout the repository.
2.  Generate a GitHub App token using `actions/create-github-app-token`.
3.  Authenticate to Google Cloud using `google-github-actions/auth` with the `workload_identity_provider` and `service_account`.
4.  Execute the `anthropics/claude-code-action @v1` with `use_vertex: "true"` and appropriate `claude_args` for the Vertex AI model ID, along with environment variables for `ANTHROPIC_VERTEX_PROJECT_ID`, `CLOUD_ML_REGION`, and `VERTEX_REGION_CLAUDE_3_7_SONNET`.
