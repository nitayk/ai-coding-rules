# Python Production Patterns

Patterns for production-ready Python projects. Modern 2025-2026 default toolchain: **`uv`** (project + package manager, replaces pip / pip-tools / pipx / poetry / pyenv / virtualenv) + **`ruff`** (lint + format, replaces flake8 / black / isort / pyupgrade / pydocstyle) + **PEP 621 `pyproject.toml`** as the single metadata source. Poetry and pre-commit still work but are no longer the recommended path for new projects.

For the deep dives, see `tooling/uv-package-manager.md`, `tooling/ruff-lint-and-format.md`, and `packaging/pyproject-toml-pep621.md`.

---

## Triggers

**APPLY WHEN**: Setting up new projects, configuring deployment, managing dependencies, or ensuring production readiness.
**SKIP WHEN**: One-off scripts or exploratory code.

---

## Core Directive

**Write modules, not scripts.** Use virtual environments, managed dependencies, and environment-based configuration. Python 3.12+ is the standard baseline.

---

## Virtual Environments Are Mandatory

```python
# Good: Always use venv
python -m venv .venv
source .venv/bin/activate  # or .venv\Scripts\activate on Windows

# Bad: System Python for project work
pip install -r requirements.txt  # Pollutes system
```

---

## Dependency Management

### Prefer pyproject.toml and Modern Tools

```toml
# Good: pyproject.toml (PEP 621)
[project]
name = "myapp"
version = "1.0.0"
requires-python = ">=3.12"
dependencies = [
    "pydantic>=2.0",
    "httpx>=0.25",
]

[project.optional-dependencies]
dev = ["pytest", "ruff", "mypy"]
```

### Use uv (preferred) — or Poetry for legacy projects

```bash
# Good: uv — single tool, ~10-100x faster than pip/poetry
uv init my-service
uv add fastapi 'pydantic>=2' httpx
uv add --dev pytest ruff mypy
uv sync --frozen          # CI: reproducible install from uv.lock

# Acceptable for existing Poetry projects:
poetry add pydantic httpx
poetry add --group dev pytest ruff mypy
```

For new projects in this org, default to `uv`. See `tooling/uv-package-manager.md` for the full pattern (dependency groups, PEP 723 inline scripts, CI setup).

### Avoid Deprecated Tools

- **pipenv**: Deprecated for new projects.
- **setup.py-only / setup.cfg**: Use `pyproject.toml` (PEP 621) as the single metadata source. See `packaging/pyproject-toml-pep621.md`.
- **pyenv**: `uv python install 3.13` / `uv python pin` replace it.
- **pip-tools**: `uv.lock` replaces `pip-compile`.
- **flake8 + black + isort + pyupgrade**: `ruff` replaces all four. See `tooling/ruff-lint-and-format.md`.

---

## Environment Configuration

### Never Hardcode Config

```python
# Good: Environment variables
import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    db_url: str
    log_level: str = "INFO"
    model_config = {"env_file": ".env", "extra": "ignore"}

settings = Settings()

# Bad: Hardcoded
DB_URL = "postgresql://localhost/mydb"
```

### Use .env for Local Development Only

- Add `.env` to `.gitignore`
- Provide `.env.example` with placeholder values
- Production: inject via orchestration (K8s secrets, etc.)

---

## Pre-commit Hooks

```yaml
# .pre-commit-config.yaml — single Ruff repo replaces black/isort/flake8 hooks
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.13.0
    hooks:
      - id: mypy
```

```bash
pre-commit install
pre-commit run --all-files
```

---

## Code Quality in CI

```yaml
# Example: GitHub Actions with uv + ruff
- uses: astral-sh/setup-uv@v3
  with:
    enable-cache: true
- run: uv sync --frozen
- run: uv run ruff check .
- run: uv run ruff format --check .
- run: uv run mypy src/
- run: uv run pytest
```

---

## Modular Design

### src Layout

```
project_root/
├── src/
│   └── mypackage/
│       ├── __init__.py
│       ├── api.py
│       └── services/
├── tests/
├── pyproject.toml
└── README.md
```

### Public API via __all__

```python
# src/mypackage/__init__.py
from .api import PublicClass, public_function

__all__ = ["PublicClass", "public_function"]
```

---

## Exit Only from main

```python
# Good: main handles exit
def main() -> int:
    try:
        run_app()
        return 0
    except ConfigError as e:
        print(f"Config error: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())

# Bad: Library calls sys.exit
def load_config(path: str) -> Config:
    if not os.path.exists(path):
        sys.exit(1)  # Caller cannot handle
```

---

## Logging Over print for Production

```python
# Good: Structured logging
import logging
logger = logging.getLogger(__name__)
logger.info("Processing %d items", count)

# Bad: print for operational messages
print(f"Processing {count} items")
```

---

## Related Rules

- [Architecture Design Patterns](../architecture/design-patterns.md) - src layout, DI
- [Security Patterns](python-security-patterns.md) - Secrets, env config
- [PEP 8 Style Guide](pep8-style-guide.md) - Formatting

---

## References

- [PEP 621 – pyproject.toml](https://peps.python.org/pep-0621/)
- [uv documentation](https://docs.astral.sh/uv/) — official Astral docs (replaces pip/poetry/pyenv/virtualenv)
- [Ruff documentation](https://docs.astral.sh/ruff/) — official Astral docs (replaces flake8/black/isort/pyupgrade)
- [Poetry Documentation](https://python-poetry.org/docs/) — still maintained for existing projects

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
