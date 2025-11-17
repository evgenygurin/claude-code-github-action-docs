# Getting Started with Claude Code GitHub Actions

This guide will walk you through setting up Claude Code GitHub Actions in your repository, from installation to your first successful automation.

## Prerequisites

Before you begin, ensure you have:

- [ ] A GitHub repository (public or private)
- [ ] Admin access to the repository
- [ ] An Anthropic API key ([Get one here](https://console.anthropic.com))
- [ ] Basic familiarity with GitHub Actions

## Quick Start (5 Minutes)

### Option 1: Automated Setup (Recommended)

The fastest way to get started is using Claude Code's terminal command:

1. **Install and open Claude Code**

2. **Run the installer**:
   ```bash
   /install-github-app
   ```

3. **Follow the prompts**:
   - Select your repository
   - Authorize the Claude GitHub App
   - Add your API key as a secret

4. **Test it**:
   - Create an issue in your repo
   - Comment: `@claude hello!`
   - Watch Claude respond!

### Option 2: Manual Setup

If the automated setup doesn't work, follow these steps:

#### Step 1: Install the Claude GitHub App

1. Visit: [https://github.com/apps/claude](https://github.com/apps/claude)
2. Click "Install"
3. Select your repository
4. Authorize the required permissions:
   - **Contents**: Read & Write
   - **Issues**: Read & Write
   - **Pull requests**: Read & Write

#### Step 2: Add Your API Key

1. Go to your repository on GitHub
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Name: `ANTHROPIC_API_KEY`
5. Value: Your API key from [console.anthropic.com](https://console.anthropic.com)
6. Click **"Add secret"**

#### Step 3: Create the Workflow File

1. In your repository, create: `.github/workflows/claude.yml`
2. Add this content:

```yaml
name: Claude Code Action

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
  claude-code:
    if: |
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude'))

    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v4

      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          claude_args: |
            --max-turns 10
            --model claude-sonnet-4-5-20250929
```

3. Commit and push the file

#### Step 4: Test the Integration

1. Create a new issue in your repository
2. Add a comment: `@claude can you help me?`
3. Wait a few seconds - Claude should respond!

## Understanding the Workflow

Let's break down what we just created:

### Triggers

```yaml
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
```

This tells GitHub Actions to run Claude when:
- Someone comments on an issue
- Someone comments on a pull request

### Conditions

```yaml
if: contains(github.event.comment.body, '@claude')
```

Claude only responds when explicitly mentioned with `@claude`.

### Permissions

```yaml
permissions:
  contents: write        # Allows Claude to modify files
  pull-requests: write   # Allows Claude to create PRs
  issues: write          # Allows Claude to comment on issues
```

These are the minimum permissions Claude needs to function effectively.

### Configuration

```yaml
claude_args: |
  --max-turns 10                        # Max conversation rounds
  --model claude-sonnet-4-5-20250929    # Model selection
```

Customize Claude's behavior with these arguments.

## Common Use Cases

### 1. Code Review

**In a Pull Request:**
```bash
@claude please review this PR for:
- Code quality
- Security issues
- Performance concerns
- Best practices
```

**Claude will:**
- Analyze the code changes
- Provide detailed feedback
- Suggest improvements
- Identify potential issues

### 2. Feature Implementation

**In an Issue:**
```text
@claude implement user authentication with JWT tokens.

Requirements:
- Login endpoint
- Token generation
- Token validation middleware
- Logout functionality
```

**Claude will:**
- Create a new branch
- Implement the feature
- Add tests
- Create a pull request

### 3. Bug Fixes

**In an Issue:**
```text
@claude fix the bug where users can't upload images larger than 1MB.

Error message: "Request entity too large"
Location: src/api/upload.ts:45
```

**Claude will:**
- Analyze the issue
- Find the root cause
- Implement a fix
- Test the solution
- Create a PR with the fix

### 4. Documentation

**In a Comment:**
```sql
@claude update the README with:
- Installation instructions
- API documentation
- Usage examples
```

**Claude will:**
- Generate comprehensive documentation
- Follow existing documentation style
- Add code examples
- Update relevant files

## Customizing Claude's Behavior

### Create a CLAUDE.md File

Add a `CLAUDE.md` file to your repository root to guide Claude:

```markdown
# Project Guidelines for Claude

## Project Overview
This is a Node.js API using Express and MongoDB.

## Coding Standards
- Use TypeScript for all new files
- Follow Airbnb style guide
- Maximum line length: 100 characters
- Use async/await over promises

## Testing Requirements
- Write tests for all new features
- Minimum 80% code coverage
- Use Jest for testing

## Code Review Focus
- Security vulnerabilities
- Performance optimization
- Error handling
- Code documentation

## Important Files
- `src/index.ts` - Main entry point
- `src/routes/` - API routes
- `src/models/` - Database models
- `tests/` - Test files
```

Claude will automatically follow these guidelines!

## Advanced Configuration

### Use Slash Commands

Instead of writing full prompts, use built-in commands:

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    prompt: "/review"  # Use the built-in review command
```

Available commands:
- `/review` - Code review
- `/fix` - Auto-fix issues
- `/test` - Generate tests
- `/optimize` - Optimize code
- `/security-audit` - Security check

### Multiple Workflows

Create separate workflows for different purposes:

```text
.github/workflows/
├── claude.yml                 # Interactive mode
├── claude-pr-review.yml       # Auto-review PRs
├── claude-security.yml        # Weekly security audits
└── claude-documentation.yml   # Auto-update docs
```

### Cost Optimization

Control Claude's resource usage:

```yaml
jobs:
  claude-code:
    timeout-minutes: 20  # Prevent long-running jobs

    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          claude_args: |
            --max-turns 5  # Limit iterations
            --model claude-sonnet-4-5-20250929  # Use efficient model
```

## Troubleshooting

### Claude Isn't Responding

**Check:**
1. ✅ Is the GitHub App installed?
2. ✅ Is `ANTHROPIC_API_KEY` in secrets?
3. ✅ Does the comment contain `@claude`?
4. ✅ Are workflows enabled?

**Fix:**
```bash
# Check workflow status
gh workflow list

# Enable workflows if disabled
gh workflow enable claude.yml
```

### Authentication Errors

**Symptom:** `401 Unauthorized` or `403 Forbidden`

**Fix:**
1. Verify API key is correct:
   ```bash
   gh secret list
   ```
2. Regenerate API key if needed:
   - Go to [console.anthropic.com](https://console.anthropic.com)
   - Generate new key
   - Update secret:
     ```bash
     gh secret set ANTHROPIC_API_KEY
     ```

### Workflow Not Triggering

**Check:**
```yaml
# Ensure correct event configuration
on:
  issue_comment:
    types: [created]  # Not 'edited' or other types
```

**Debug:**
1. Check the Actions tab in your repository
2. Look for workflow runs
3. Review logs for errors

## Next Steps

Now that you're set up, explore:

1. **[Examples Directory](../examples/)** - More workflow templates
2. **[MCP Configuration](./mcp-configuration.md)** - Extend Claude's capabilities
3. **[Security Best Practices](./security-best-practices.md)** - Secure your setup
4. **[Advanced Configuration](./advanced-configuration.md)** - Fine-tune behavior

## Need Help?

- 📚 [Official Documentation](https://code.claude.com/docs)
- 💬 [Community Discussions](https://github.com/anthropics/claude-code-action/discussions)
- 🐛 [Report Issues](https://github.com/anthropics/claude-code-action/issues)
- 📧 Support: support@anthropic.com

## Success Tips

1. **Start Small**: Begin with simple tasks like code reviews
2. **Iterate**: Refine your `CLAUDE.md` based on results
3. **Monitor Costs**: Track API usage regularly
4. **Review Changes**: Always review Claude's PRs before merging
5. **Provide Context**: The more context you give Claude, the better results

**Congratulations!** You're now ready to leverage Claude Code in your development workflow! 🎉
