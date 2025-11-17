# Workflow Modes

Claude Code GitHub Actions operates in two primary modes: **Interactive Mode** and **Automation Mode**. The action intelligently detects which mode to use based on your workflow configuration and the GitHub event that triggers it. Understanding these modes is crucial for effectively leveraging Claude's capabilities.

## 1. Interactive Mode

Interactive Mode is designed for direct, conversational interaction with Claude within GitHub comments.

### Activation

Interactive Mode is automatically activated when:

*   The GitHub event is an `issue_comment` or `pull_request_review_comment` (i.e., a comment is created on an issue or a pull request).
*   The comment body contains the `trigger_phrase` (by default, `@claude`).
*   The `prompt` parameter in the workflow is *not* explicitly set.

### Behavior

In Interactive Mode, Claude:

*   **Responds to Mentions**: Actively listens for mentions of its `trigger_phrase` in comments.
*   **Contextual Understanding**: Automatically loads the context of the associated Pull Request or Issue.
*   **Progress Updates**: Creates a "progress comment" on GitHub to provide real-time updates on its activity.
*   **Direct Response**: Publishes its responses and any generated code or feedback directly as a reply to the triggering comment.

### Conceptual Flow

```mermaid
graph TD
    A[User Comments on PR/Issue] --> B{Comment Contains "@claude"?}
    B -- Yes --> C[Claude Code Action Triggered]
    C --> D{Prompt Parameter Set?}
    D -- No --> E[Interactive Mode Activated]
    E --> F[Claude Reads PR/Issue Context]
    E --> G[Claude Posts "Thinking..." Comment]
    F & G --> H[Claude Processes Request]
    H --> I[Claude Posts Response/Changes]
```

### Example Workflow Configuration

```yaml
name: Claude Interactive Mode

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
    # Condition to ensure Claude only runs when mentioned
    if: contains(github.event.comment.body, ' @claude')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout @v4

      - uses: anthropics/claude-code-action @v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          # No 'prompt' parameter means it will listen for @claude mentions
```

## 2. Automation Mode

Automation Mode is designed for programmatic, non-interactive execution of Claude's capabilities, typically triggered by events other than comments or when a specific `prompt` is provided.

### Activation

Automation Mode is activated when:

*   The `prompt` parameter is explicitly set in the workflow configuration.
*   The workflow is triggered by any GitHub event (e.g., `pull_request`, `push`, `schedule`, `workflow_dispatch`).

### Behavior

In Automation Mode, Claude:

*   **Immediate Execution**: Runs immediately upon workflow trigger, without waiting for a comment mention.
*   **Uses Defined Prompt**: Executes tasks based on the instructions provided in the `prompt` parameter.
*   **GitHub Context Variables**: Can leverage GitHub context variables (e.g., `github.event.pull_request.title`) within the `prompt` for dynamic instructions.
*   **Automated Actions**: Can perform actions like creating new Pull Requests, committing changes, or updating issues automatically.
*   **Workflow Output**: Results and logs are typically outputted to the GitHub Actions workflow run logs.

### Conceptual Flow

```mermaid
graph TD
    A[GitHub Event Trigger] --> B[Claude Code Action Triggered]
    B --> C{Prompt Parameter Set?}
    C -- Yes --> D[Automation Mode Activated]
    D --> E[Claude Processes Defined Prompt]
    E --> F[Claude Executes Task]
    F --> G[Claude Commits Changes/Creates PR (if applicable)]
    G --> H[Results in Workflow Logs]
```

### Example Workflow Configurations

#### Automatic Code Review on PR Open/Update

```yaml
name: Automatic Code Review

on:
  pull_request:
    types: [opened, synchronize] # Triggers on new PRs or updates to existing ones

permissions:
  contents: read
  pull-requests: write # Required for Claude to post review comments

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout @v4

      - uses: anthropics/claude-code-action @v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            Review this pull request for code quality, potential bugs, and adherence to project standards.
            Provide feedback as review comments.
          claude_args: "--max-turns 5" # Limit conversation turns for efficiency
```

#### Scheduled Daily Report

```yaml
name: Daily Project Report

on:
  schedule:
    - cron: "0 9 * * *" # Runs every day at 9:00 UTC

permissions:
  contents: read
  issues: write # Required if Claude needs to create/update issues

jobs:
  report:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout @v4

      - uses: anthropics/claude-code-action @v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: "Generate a summary of yesterday's commits and open issues across the repository. Highlight any critical items."
          claude_args: "--model claude-opus-4-1-20250805" # Use a more powerful model for complex summaries
```

## 3. Automatic Mode Detection

The Claude Code Action v1 automatically detects the appropriate mode based on the presence of the `prompt` parameter and the GitHub event type. This simplifies configuration, as you no longer need to explicitly set a `mode` input.

*   If `prompt` is provided, it defaults to **Automation Mode**.
*   If `prompt` is omitted and the event is a comment creation, it defaults to **Interactive Mode**.

This intelligent detection allows for flexible and powerful automation workflows.
