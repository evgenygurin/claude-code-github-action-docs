# Claude Code GitHub Actions

## AI-Powered Automation for Your GitHub Workflow

Claude Code GitHub Actions integrates advanced AI capabilities directly into your GitHub development process. By simply mentioning `@claude` in a Pull Request or Issue, Claude can automate various code-related tasks, ensuring adherence to your project's standards. This action is built upon the Claude Code SDK, offering a powerful and extensible platform for custom automation.

## Why Use Claude Code GitHub Actions?

*   **Instant Pull Request Creation**: Describe your requirements, and Claude can generate a complete Pull Request with all necessary modifications.
*   **Automated Code Implementation**: Transform issues into functional code with a single command, streamlining your development cycle.
*   **Standard Adherence**: Claude respects your project's `CLAUDE.md` guidelines and existing code patterns, ensuring consistency.
*   **Simplified Setup**: Get started quickly with an easy installation process and API key configuration.
*   **Secure by Design**: Your code remains within GitHub's secure runner environment, with API calls directed to your chosen provider.

## What Can Claude Do?

Claude Code enhances your workflow by providing capabilities such as:

*   **Code Review**: Analyze code for quality, potential bugs, performance, and security.
*   **Feature Implementation**: Develop new features based on issue descriptions.
*   **Bug Fixing**: Identify and resolve bugs, including adding tests for regression prevention.
*   **Documentation Generation**: Create comprehensive documentation for various scopes.
*   **Code Refactoring**: Improve code readability, optimize performance, and ensure design pattern compliance.
*   **Test Generation**: Write unit and integration tests for new or existing code.
*   **Custom Automation**: Build tailored workflows using prompts and CLI arguments.

## Quick Start

The fastest way to integrate Claude Code GitHub Actions is through the Claude Code CLI.

1.  **Install Claude Code CLI**:
    ```bash
    curl -fsSL https://claude.ai/install.sh | bash
    ```
2.  **Initialize in your project**:
    Navigate to your project directory and run `claude`. Follow the prompts for initial setup and authorization.
3.  **Install GitHub App**:
    From the Claude Code CLI, execute `/install-github-app`. This command automates the installation of the Claude GitHub App, configures necessary secrets, and creates a basic workflow file (`.github/workflows/claude.yml`).

    *   **Note**: This quick setup requires repository admin privileges and is primarily for direct Claude API users. For AWS Bedrock or Google Vertex AI, refer to the detailed setup documentation.

## Manual Setup

If the quick setup is not suitable, follow these steps:

1.  **Install the Claude GitHub App**: Visit [https://github.com/apps/claude](https://github.com/apps/claude) and install the app to your repository, granting the required `Contents`, `Issues`, and `Pull requests` read/write permissions.
2.  **Add `ANTHROPIC_API_KEY`**: Obtain your API key from [console.anthropic.com](https://console.anthropic.com/) and add it as a repository secret named `ANTHROPIC_API_KEY` in your GitHub repository settings.
3.  **Create Workflow File**: Copy the example workflow from the action's repository into `.github/workflows/claude.yml` in your project.

## AWS Bedrock Integration (EU Region)

For enterprise environments and EU data residency requirements, Claude Code can integrate with AWS Bedrock in the **eu-north-1 (Stockholm)** region using secure OIDC authentication.

### Why AWS Bedrock + OIDC?

*   **Data Residency**: Keep data within EU boundaries (GDPR compliance)
*   **Security**: Temporary credentials with automatic rotation
*   **Cost Control**: Use your own AWS account for billing and monitoring
*   **No Long-Lived Keys**: OIDC eliminates the need for permanent AWS access keys

### Quick Start with Bedrock

1.  **Enable Bedrock**: Access Amazon Bedrock in eu-north-1 and request Claude model access
2.  **Setup OIDC**: Configure OpenID Connect authentication in AWS IAM
3.  **Create IAM Role**: Grant minimal Bedrock permissions to GitHub Actions
4.  **Add Secret**: Store only the Role ARN in GitHub Secrets (no AWS keys!)
5.  **Use Workflow**: Deploy `.github/workflows/claude-bedrock-eu.yml`

**📚 Detailed Guide**: [AWS Bedrock OIDC Setup](docs/aws-bedrock-oidc-setup.md)

**⚠️ Security Note**: If you have existing AWS access keys, please review the [Urgent Key Rotation Guide](docs/URGENT-KEY-ROTATION.md) for secure credential management.

### Available Models in eu-north-1

*   `eu.anthropic.claude-3-5-sonnet-20241022-v2:0` (Recommended)
*   `eu.anthropic.claude-3-5-haiku-20241022-v1:0`
*   `eu.anthropic.claude-3-opus-20240229-v1:0`

### Example Workflow

See `examples/claude-bedrock-eu-oidc.yml` for a complete, production-ready example.

## Best Practices

*   **`CLAUDE.md` Configuration**: Create a `CLAUDE.md` file in your repository root to define coding standards, review criteria, and project-specific guidelines. This file acts as a guide for Claude's behavior.
*   **Security Considerations**: Always use GitHub Secrets for API keys and other sensitive information. Never hardcode credentials directly in workflow files. Limit action permissions to the minimum necessary. **For AWS**: Use OIDC instead of long-lived access keys.
*   **Optimizing Performance**: Provide clear context using issue templates, keep your `CLAUDE.md` concise, and configure appropriate timeouts for workflows to manage resource consumption.
*   **Cost Management**: Be mindful of GitHub Actions minutes and Claude API token usage. Utilize specific `@claude` commands, configure `--max-turns`, and set workflow-level timeouts to optimize costs.

## Troubleshooting

*   **Claude Not Responding**: Verify GitHub App installation, workflow enablement, correct API key secret, and ensure `@claude` is used in comments.
*   **CI Not Running on Claude's Commits**: Confirm the use of the GitHub App or a custom app (not an Actions user), check workflow triggers, and verify app permissions.
*   **Authentication Errors**: Validate API key, permissions, and correct secret naming for Bedrock/Vertex configurations.

## Further Reading

For detailed information on architecture, advanced configuration, security, and cloud provider integrations, please refer to the `docs/` directory.

### Getting Started

*   [Getting Started Guide](docs/getting-started.md) - Step-by-step setup for beginners
*   [Setup and Configuration](docs/setup-and-configuration.md) - Detailed configuration options
*   [Workflow Modes](docs/workflow-modes.md) - Understanding different modes

### AWS Bedrock Integration

*   [AWS Bedrock OIDC Setup](docs/aws-bedrock-oidc-setup.md) - Complete OIDC setup for EU region
*   [Urgent Key Rotation Guide](docs/URGENT-KEY-ROTATION.md) - Security incident response

### Advanced Topics

*   [Architecture Overview](docs/architecture.md) - System architecture and design
*   [Advanced Tool Management](docs/advanced-tool-management.md) - Tool configuration
*   [MCP Configuration](docs/mcp-configuration.md) - Model Context Protocol setup
*   [Customization](docs/customization.md) - Custom workflows and commands

### Security & Best Practices

*   [Security Best Practices](docs/security-best-practices.md) - Comprehensive security guide
*   [Security and Authentication](docs/security-and-authentication.md) - Authentication methods
*   [Cost Optimization](docs/cost-optimization.md) - Managing costs effectively

### Troubleshooting

*   [Troubleshooting Guide](docs/troubleshooting-guide.md) - Common issues and solutions
*   [Implementation Pseudocode](claude_code_action_pseudocode.txt) - Technical reference
