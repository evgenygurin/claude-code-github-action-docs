# Customization

Claude Code GitHub Actions offers extensive customization options to tailor Claude's behavior to your specific project needs, coding standards, and workflow requirements. This document covers how to customize Claude through `CLAUDE.md`, custom prompts, hooks, plugins, and environment variables.

## 1. `CLAUDE.md` Configuration

The `CLAUDE.md` file is a powerful mechanism to provide Claude with project-specific context and guidelines. Placed at the root of your repository, this Markdown file acts as a living style guide and rulebook for the AI agent.

### Purpose

*   **Define Coding Standards**: Specify preferred formatting, naming conventions, and architectural patterns.
*   **Set Review Criteria**: Outline what constitutes a good (or bad) Pull Request, focusing Claude's review efforts.
*   **Project-Specific Rules**: Inform Claude about unique aspects of your codebase, such as specific libraries, frameworks, or design decisions.
*   **Behavioral Guidance**: Guide Claude on how to approach tasks (e.g., "always prioritize performance," "focus on security first").

### Usage

Claude automatically reads and interprets the `CLAUDE.md` file at the start of its execution. The content of this file influences Claude's understanding and decision-making process throughout its interaction with your codebase.

## 2. Custom Prompts

The `prompt` parameter in your workflow file allows you to provide specific instructions to Claude for a given task. This is particularly useful in Automation Mode or when you want to override the default behavior in Interactive Mode.

### Usage

*   **Direct Instructions**: Provide a natural language description of the task you want Claude to perform.
*   **Slash Commands**: Utilize pre-built slash commands (e.g., `/review`, `/fix`) for common tasks.
*   **GitHub Context Variables**: Embed GitHub context variables (e.g., `${{ github.event.issue.title }}`) within your prompts for dynamic instructions.

```yaml
- uses: anthropics/claude-code-action @v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    prompt: |
      Generate a summary of yesterday's commits and open issues.
      Focus on changes related to the 'feature-x' branch.
    claude_args: "--model claude-opus-4-1-20250805"
```

## 3. Hooks

Hooks allow you to execute custom commands or scripts at specific points during Claude's execution lifecycle, such as before or after a tool is used. This provides fine-grained control and enables integration with external processes.

### Configuration

Hooks are defined within the `settings` parameter in your workflow YAML.

```yaml
- uses: anthropics/claude-code-action @v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    settings: |
      {
        "hooks": {
          "PreToolUse": [
            {
              "matcher": "Bash",
              "hooks": [
                {
                  "type": "command",
                  "command": "echo 'About to run a Bash command: $TOOL_ARGS'"
                }
              ]
            }
          ],
          "PostToolUse": [
            {
              "matcher": "Edit",
              "hooks": [
                {
                  "type": "command",
                  "command": "npm run lint -- --fix $FILE_PATH"
                }
              ]
            }
          ]
        }
      }
```

### Key Properties

*   **`PreToolUse` / `PostToolUse`**: Define hooks to run before or after a tool is executed.
*   **`matcher`**: Specifies which tool the hook applies to (e.g., `"Bash"`, `"Edit"`, `"mcp__my-tool__*"`, or `"*"` for all tools).
*   **`hooks`**: An array of hook definitions.
    *   `type: "command"`: Executes a shell command.
    *   `command`: The shell command to execute. Environment variables like `$TOOL_NAME`, `$TOOL_ARGS`, `$FILE_PATH` (for file-related tools) are available.

## 4. Plugins

Plugins offer a structured way to extend Claude's functionality by bundling custom commands, agents, skills, and hooks. They allow for modular and reusable extensions.

### Structure

A plugin is typically a directory containing a `plugin.json` manifest and subdirectories for its components.

```
plugins/
  my-custom-plugin/
    plugin.json
    commands/
      my-command.md
    agents/
      specialized-agent.md
    skills/
      my-skill.md
    hooks/
      pre-bash-script.sh
```

### `plugin.json` Example

```json
{
  "name": "my-custom-plugin",
  "version": "1.0.0",
  "description": "A plugin for specialized code analysis tasks.",
  "commands": ["commands/my-command.md"],
  "agents": ["agents/specialized-agent.md"],
  "skills": ["skills/my-skill.md"],
  "hooks": {
    "PreToolUse": ["hooks/pre-bash-script.sh"]
  }
}
```

### Usage

Plugins are enabled via the `settings` parameter in your workflow.

```yaml
- uses: anthropics/claude-code-action @v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    settings: |
      {
        "plugins": ["./plugins/my-custom-plugin"]
      }
```

## 5. Environment Variables

You can pass custom environment variables to the Claude Code Action, which can then be accessed by Claude or its tools.

### Configuration

Environment variables can be set using the `claude_env` parameter.

```yaml
- uses: anthropics/claude-code-action @v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    claude_env: |
      NODE_ENV: production
      FEATURE_FLAG_X: true
      DATABASE_URL: ${{ secrets.PROD_DB_URL }}
```

These variables become available to Claude's execution environment and can be referenced within prompts or scripts executed by hooks or custom tools.

## 6. Model Configuration

You can specify which Claude model to use and configure its parameters for optimal performance and cost.

### Model Selection

*   **Via `claude_args`**:
    ```yaml
    claude_args: "--model claude-sonnet-4-5-20250929"
    ```
*   **Via `settings`**:
    ```yaml
    settings: |
      {
        "model": "claude-opus-4-1-20250805"
      }
    ```

### Model Parameters

Advanced model parameters like `maxTokens`, `temperature`, and `topP` can be configured via the `settings` parameter.

```yaml
settings: |
  {
    "model": "claude-opus-4-1-20250805",
    "maxTokens": 4096,
    "temperature": 0.7,
    "topP": 0.9
  }
```

By combining these customization options, you can fine-tune Claude Code GitHub Actions to seamlessly integrate into your existing development practices and achieve highly specific automation goals.
