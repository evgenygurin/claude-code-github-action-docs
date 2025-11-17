# Project Overview

This project, "claude-integration", is a Python application designed to integrate with the Claude AI for various code-related tasks. It leverages a layered architecture (Presentation, Application, Domain, Infrastructure) and follows SOLID principles, GoF patterns (Factory, Strategy, Repository), and emphasizes testability and scalability.

The core functionality revolves around executing different types of tasks (review, implement, fix, docs, refactor, tests) using the Claude AI. It supports different Claude providers (Direct API, Bedrock, Vertex) and integrates with GitHub workflows.

## Technologies Used

*   **Python**: Primary programming language.
*   **Poetry**: Dependency management.
*   **Jinja2**: Templating for GitHub workflows.
*   **PyYAML**: For loading prompt configurations.
*   **Anthropic**: Claude AI client library.
*   **Black, Pylint, MyPy, Ruff**: Code quality and linting tools.
*   **Pytest**: Testing framework.
*   **Docker**: For containerization.

## Project Structure

```
claude-integration/
├── src/
│   ├── __init__.py
│   ├── main.py
│   ├── config/             # Configuration settings and logger setup
│   │   ├── __init__.py
│   │   ├── settings.py
│   │   └── logger.py
│   ├── domain/             # Core business logic, entities, and exceptions
│   │   ├── __init__.py
│   │   ├── entities.py
│   │   └── exceptions.py
│   ├── application/        # Application services, DTOs, and use cases
│   │   ├── __init__.py
│   │   ├── service.py
│   │   ├── dto.py
│   │   └── use_cases/      # Specific use cases for Claude tasks
│   │       ├── __init__.py
│   │       ├── base.py
│   │       ├── review.py
│   │       ├── implement.py
│   │       ├── fix.py
│   │       ├── docs.py
│   │       ├── refactor.py
│   │       └── tests.py
│   ├── infrastructure/     # External integrations (Claude, GitHub, Shell)
│   │   ├── __init__.py
│   │   ├── claude/
│   │   │   ├── __init__.py
│   │   │   ├── client.py
│   │   │   ├── factory.py
│   │   │   └── providers.py
│   │   ├── github/
│   │   │   ├── __init__.py
│   │   │   └── workflows.py
│   │   └── shell/
│   │       ├── __init__.py
│   │       └── executor.py
│   ├── presentation/       # CLI interface, argument parsing, and output formatting
│   │   ├── __init__.py
│   │   ├── cli.py
│   │   ├── formatter.py
│   │   └── parser.py
│   └── utils/              # Utility functions (e.g., Result monad)
│       ├── __init__.py
│       └── result.py
├── prompts/                # YAML files defining prompts for different Claude tasks
│   ├── review.yml
│   ├── implement.yml
│   ├── fix.yml
│   ├── docs.yml
│   ├── refactor.yml
│   └── tests.yml
├── scripts/                # Bash scripts for setup and analysis
│   ├── claude-cli.sh
│   ├── analyze.sh
│   └── setup.sh
├── .github/workflows/      # GitHub Actions workflow definitions
│   ├── claude-pr.yml
│   ├── claude-api.yml
│   ├── claude-vertex.yml
│   ├── claude-review.yml
│   └── claude-daily-report.yml
├── tests/                  # Unit and integration tests
│   ├── __init__.py
│   ├── test_service.py
│   ├── test_use_cases.py
│   └── fixtures/
├── Dockerfile              # Docker build instructions
├── Makefile                # Build automation
├── pyproject.toml          # Poetry project configuration
├── requirements.txt        # Pip requirements
└── README.md               # Project README
```

## Building and Running

### Setup

To set up the project and install dependencies, use the provided `setup.sh` script or `Makefile`:

```bash
./scripts/setup.sh
# or
make setup
```

This will install Python dependencies using Poetry and the Claude CLI tool.

### Installing Claude CLI

The Claude CLI is a core dependency. It can be installed manually:

```bash
curl -fsSL https://claude.ai/install.sh | bash
# or via make
make install
```

### Running Tasks via CLI

The project provides a command-line interface (`src/main.py`) to execute various Claude AI tasks.

Example commands:

*   **Review a Pull Request:**
    ```bash
    python -m src.main review --pr 123
    ```
*   **Implement a Feature:**
    ```bash
    python -m src.main implement --issue 456
    ```
*   **Fix a Bug:**
    ```bash
    python -m src.main fix --bug "Database connection error"
    ```
*   **Generate Documentation:**
    ```bash
    python -m src.main docs --scope src/application
    ```
*   **Refactor a Module:**
    ```bash
    python -m src.main refactor --module src/domain/entities.py
    ```
*   **Write Tests for a Module:**
    ```bash
    python -m src.main tests --module src/application/service.py
    ```
*   **Run a custom prompt:**
    ```bash
    python -m src.main run --prompt "Explain the concept of dependency injection."
    ```

### Docker

To build a Docker image for the application:

```bash
make docker-build
```

### Testing

To run tests and generate a coverage report:

```bash
make test
```

### Linting and Formatting

To check code quality:

```bash
make lint
```

To automatically format code:

```bash
make format
```

## Configuration

The application's configuration is managed through environment variables and defined in `src/config/settings.py`. Key configurations include:

*   `CLAUDE_API_KEY`: API key for Claude (required for `api` provider).
*   `CLAUDE_MODEL`: The Claude model to use (default: `claude-sonnet-4-5-20250929`).
*   `CLAUDE_MAX_TURNS`: Maximum turns for Claude conversations (default: 10).
*   `CLAUDE_PROVIDER`: Cloud provider for Claude (e.g., `api`, `bedrock`, `vertex`).
*   `AWS_REGION`: AWS region for Bedrock (default: `us-west-2`).
*   `GCP_PROJECT_ID`: GCP project ID for Vertex (required for `vertex` provider).
*   `CLAUDE_TIMEOUT`: Timeout for Claude execution (default: 300 seconds).
*   `LOG_LEVEL`: Logging level (e.g., `INFO`, `DEBUG`).

These settings can be overridden via a `.env` file or directly as environment variables.

## Development Conventions

*   **Code Style**: Enforced by `black` (line length 120) and `ruff`.
*   **Linting**: `pylint` and `mypy` are used for static analysis and type checking.
*   **Testing**: `pytest` is used for unit and integration tests, with `pytest-cov` for coverage reporting.
*   **Prompts**: AI prompts are defined in YAML files within the `prompts/` directory, allowing for easy modification and management.
*   **Architecture**: Adherence to a clean, layered architecture (Presentation, Application, Domain, Infrastructure) to ensure separation of concerns and maintainability.

## GitHub Workflows

The project includes several GitHub Actions workflows (`.github/workflows/`) for continuous integration and automation:

*   `claude-pr.yml`: Likely for pull request reviews.
*   `claude-api.yml`: Integration with Claude API.
*   `claude-vertex.yml`: Integration with Claude via Google Cloud Vertex AI.
*   `claude-review.yml`: Specific workflow for code reviews.
*   `claude-daily-report.yml`: For daily reports or automated tasks.

These workflows are generated using Jinja2 templates, as seen in `src/infrastructure/github/workflows.py`.
