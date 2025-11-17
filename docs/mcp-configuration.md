# Model Context Protocol (MCP) Configuration

## Overview

The Model Context Protocol (MCP) is a standardized protocol that allows AI systems like Claude to interact with external tools and resources. MCP extends Claude's capabilities beyond its base functionality, enabling integration with various services and tools.

## What is MCP?

MCP is a universal protocol that connects AI assistants to external data sources and tools. Think of it as a plugin system for Claude that allows it to:

- Access external APIs and services
- Read and manipulate files in specific ways
- Interact with databases and data sources
- Execute specialized operations
- Use domain-specific tools

## Popular MCP Servers

### Core MCP Servers

| Server | Purpose | Use Cases |
|--------|---------|-----------|
| **GitHub** | Manage PRs, issues, repositories | Repository operations, issue tracking |
| **Filesystem** | Safe file operations | File reading, writing, directory management |
| **Git** | Repository manipulation | Git history, branching, commits |
| **Perplexity** | Research capabilities | Web research, fact-checking |
| **Sequential Thinking** | Complex task breakdown | Multi-step problem solving |
| **Context7** | Up-to-date documentation | Library docs, API references |

### MCP Server Repository

Browse all available MCP servers:
- **Official Repository**: [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers)
- **MCP Catalog**: [mcpcat.io](https://mcpcat.io)

## Installing MCP Servers

### Via Claude CLI

The easiest way to add MCP servers is through the Claude CLI:

```bash
# Add a server for your user (global)
claude mcp add github --scope user

# Add a server for current project only
claude mcp add perplexity --scope project

# List installed servers
claude mcp list

# Remove a server
claude mcp remove github --scope user
```

### Manual Configuration

You can also manually edit the MCP configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
**Linux**: `~/.config/Claude/claude_desktop_config.json`

Example configuration:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token-here"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/directory"]
    }
  }
}
```

## Using MCP in GitHub Actions

### Basic MCP Configuration

To use MCP servers in your GitHub Actions workflows:

```yaml
- name: Run Claude with MCP
  uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    claude_args: |
      --mcp-config /path/to/mcp-config.json
      --max-turns 10
```

### Creating MCP Configuration for CI

Create a minimal MCP configuration file in your repository:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${{ secrets.GITHUB_TOKEN }}"
      }
    }
  }
}
```

### Advanced Workflow Example

```yaml
name: Claude with MCP Tools

on:
  issue_comment:
    types: [created]

jobs:
  claude-mcp:
    if: contains(github.event.comment.body, '@claude')
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js (for MCP servers)
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Create MCP config
        run: |
          cat > mcp-config.json << 'EOF'
          {
            "mcpServers": {
              "github": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-github"],
                "env": {
                  "GITHUB_PERSONAL_ACCESS_TOKEN": "${{ secrets.GITHUB_TOKEN }}"
                }
              },
              "filesystem": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-filesystem", "${{ github.workspace }}"]
              }
            }
          }
          EOF

      - name: Run Claude with MCP
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          claude_args: |
            --mcp-config ./mcp-config.json
            --max-turns 15
```

## Security Best Practices for MCP

### 1. Trust Only Official Servers

- Install servers from trusted sources only
- Review server code before installation
- MCP servers run with full system access

### 2. Use Scoped Installation

```bash
# Project scope - limits to current directory
claude mcp add github --scope project

# User scope - global access
claude mcp add github --scope user
```

### 3. API Key Management

- Never commit API keys to configuration files
- Use environment variables for secrets
- Rotate keys regularly

```bash
# Good: Use environment variables
export GITHUB_TOKEN="your-token"
claude mcp add github --scope user

# Bad: Hardcoded in config (DON'T DO THIS!)
{
  "env": {
    "GITHUB_TOKEN": "ghp_hardcodedtoken"
  }
}
```

### 4. Audit Server Permissions

Before installing an MCP server:

1. Review what permissions it requests
2. Check what data it can access
3. Verify it only asks for necessary permissions
4. Monitor its behavior after installation

### 5. Regular Security Audits

```bash
# List all installed servers
claude mcp list

# Review server configurations
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json

# Remove unused servers
claude mcp remove unused-server --scope user
```

## Common MCP Use Cases

### 1. GitHub Integration

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Capabilities**:
- Create and manage issues
- Review pull requests
- Search repositories
- Manage branches and commits

### 2. File System Operations

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/project"
      ]
    }
  }
}
```

**Capabilities**:
- Safe file reading and writing
- Directory operations
- File search and manipulation

### 3. Research and Documentation

```json
{
  "mcpServers": {
    "perplexity": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-perplexity"],
      "env": {
        "PERPLEXITY_API_KEY": "${PERPLEXITY_KEY}"
      }
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-context7"]
    }
  }
}
```

**Capabilities**:
- Web research
- Up-to-date library documentation
- API reference lookup

## Troubleshooting MCP

### Server Not Starting

```bash
# Check server status
claude mcp list

# Try reinstalling
claude mcp remove problematic-server --scope user
claude mcp add problematic-server --scope user

# Check logs
tail -f ~/.claude/mcp.log
```

### Permission Issues

```bash
# Ensure Node.js is installed (required for most MCP servers)
node --version
npm --version

# Update npx cache
npx clear-cache
```

### Authentication Errors

```bash
# Verify environment variables
echo $GITHUB_TOKEN

# Regenerate tokens if expired
# GitHub: Settings → Developer settings → Personal access tokens
```

## Advanced MCP Configuration

### Custom MCP Server

You can create custom MCP servers for your specific needs:

```json
{
  "mcpServers": {
    "custom-tool": {
      "command": "python",
      "args": ["/path/to/your/mcp_server.py"],
      "env": {
        "CUSTOM_API_KEY": "${YOUR_API_KEY}"
      }
    }
  }
}
```

### Multiple Servers

Combine multiple MCP servers for enhanced capabilities:

```json
{
  "mcpServers": {
    "github": { ... },
    "filesystem": { ... },
    "perplexity": { ... },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

## Resources

- **MCP Specification**: [Model Context Protocol](https://modelcontextprotocol.io)
- **Official Servers**: [GitHub Repository](https://github.com/modelcontextprotocol/servers)
- **MCP Catalog**: [mcpcat.io](https://mcpcat.io)
- **Documentation**: [Claude MCP Guide](https://docs.anthropic.com/claude/docs/model-context-protocol)

## Next Steps

1. Install your first MCP server: `claude mcp add github --scope user`
2. Test it in Claude: Ask Claude to use GitHub operations
3. Review MCP security best practices
4. Explore additional servers from the MCP catalog
5. Consider creating custom servers for your specific needs

MCP significantly extends Claude's capabilities - use it to build powerful, integrated workflows!
