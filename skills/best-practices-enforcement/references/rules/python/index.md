# Python Development Rules

**Python-Specific Rules**: Implementation details for Python code.

**How It Works**:
- Generic rules (SOLID, DRY, KISS, correctness first) load **automatically** when you open Python files
- This index loads **automatically** when you open Python files (via globs)
- Use this to discover Python-specific patterns (async/await, type hints, PEP 8)

**Key Principle**: This directory contains ONLY Python-specific patterns. Universal principles are in `generic/` and load automatically - they're referenced from here.

**Graph Structure**: This is a Layer 2 node that routes to Layer 1 nodes (subcategory indexes) based on keywords.

---

## Keyword → Subcategory Index Routing

| Keywords/Intent | Load Subcategory Index |
|----------------|----------------------|
| **language**, python language, type hints, async, pythonic, error handling | `references/rules/python/language/index.md` |
| **testing**, pytest, python testing, mocking, property-based testing | `references/rules/python/testing/index.md` |
| **performance**, profiling, optimization, concurrency, memory management | `references/rules/python/performance/index.md` |
| **architecture**, design patterns, project structure, dependency injection | `references/rules/python/architecture/index.md` |
| **data**, pandas, pydantic, data handling, data processing | `references/rules/python/data/index.md` |
| **style**, pep8, python style, formatting, naming | `references/rules/python/meta/pep8-style-guide.md` |
| **security**, secrets, sql injection, input validation | `references/rules/python/meta/python-security-patterns.md` |
| **production**, deployment, pyproject, poetry, pre-commit | `references/rules/python/meta/python-production-patterns.md` |

---

## Available Rules

### Meta & Style (`meta/`)
- **[PEP 8 Style Guide](meta/pep8-style-guide.md)** - Naming, formatting, imports, and code organization
- **[Python Security Patterns](meta/python-security-patterns.md)** - Secrets, SQL injection prevention, input validation, safe subprocess
- **[Python Production Patterns](meta/python-production-patterns.md)** - uv + ruff + pyproject.toml stack, env config, modular design

### Tooling (`tooling/`)
- **[uv Package Manager](tooling/uv-package-manager.md)** - Standardize on uv (replaces pip/poetry/pyenv/virtualenv)
- **[Ruff: Lint and Format](tooling/ruff-lint-and-format.md)** - Single Ruff config replaces flake8/black/isort/pyupgrade
- **[Type Checker Selection](tooling/type-checker-selection.md)** - mypy vs pyright vs basedpyright decision guide

### Packaging (`packaging/`)
- **[pyproject.toml (PEP 621)](packaging/pyproject-toml-pep621.md)** - Single metadata source; ban setup.py/setup.cfg in new code

### Language Features (`language/`)
**Load**: `references/rules/python/language/index.md` - Points to specific language pattern files
- **[Error Handling Patterns](language/error-handling-patterns.md)** - Exceptions, try/except, context managers, custom errors
- **[Type Annotations Everywhere](language/type-annotations-everywhere.md)** - Type annotations for static type checking (Python 3.12+ syntax)
- **[Modern Type Syntax (3.12+)](language/modern-type-syntax-3-12.md)** - PEP 695 native generics: `class Foo[T]`, `type Alias = ...`
- **[Pythonic Patterns](language/pythonic-patterns.md)** - Idiomatic Python: comprehensions, dataclasses, EAFP, generators
- **[Async Patterns](language/async-patterns.md)** - Async/await best practices, structured concurrency, avoiding blocking
- **[Advanced Features](language/advanced-features.md)** - Decorators, context managers, modern type syntax

### Architecture (`architecture/`)
**Load**: `references/rules/python/architecture/index.md` - Points to specific architecture pattern files
- **[Design Patterns](architecture/design-patterns.md)** - Project structure, dependency injection, API design

### Web (`web/`)
- **[FastAPI + Pydantic v2](web/fastapi-pydantic-v2.md)** - Annotated deps, lifespan handlers, response models, v2-native patterns

### Data Handling (`data/`)
**Load**: `references/rules/python/data/index.md` - Points to specific data pattern files
- **[Data Handling](data/data-handling.md)** - pandas + Polars + Pydantic v2 patterns
- **[Polars vs pandas](data/polars-vs-pandas.md)** - When to pick Polars (lazy, multi-threaded, > memory) vs pandas (ecosystem)
- **[Pydantic v2 Migration](data/pydantic-v2-migration.md)** - v1 → v2 method/config/settings rename cheatsheet
- **[Airflow 3 Task SDK](data/airflow-3-task-sdk.md)** - `@task` decorator + TaskFlow as the default DAG authoring style
- **[dbt Fusion Engine](data/dbt-fusion-engine.md)** - Rust-based Fusion for new dbt work; Core remains supported

### Observability (`observability/`)
- **[Structured Logging (structlog)](observability/structured-logging-structlog.md)** - Key-value structured output, contextvars binding, stdlib interop

### Performance (`performance/`)
**Load**: `references/rules/python/performance/index.md` - Points to specific performance pattern files
- **[Profiling and Optimization](performance/profiling-and-optimization.md)** - Profiling tools, memory management, vectorization
- **[Concurrency and Optimization](performance/concurrency-and-optimization.md)** - Multiprocessing, threading, asyncio

### Testing (`testing/`)
**Load**: `references/rules/python/testing/index.md` - Points to specific testing pattern files
- **[Python Testing Best Practices](testing/python-testing-best-practices.md)** - pytest patterns, testing behavior vs structure
- **[Advanced Testing](testing/advanced-testing.md)** - Mocking strategies, property-based testing (hypothesis)

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../generic/code-quality/core-principles.md) - Universal principles (SOLID, DRY, KISS, YAGNI, correctness first, pure functions)
- [Generic Architecture Principles](../../generic/architecture/core-principles.md) - Universal architecture principles
- [Generic Testing Principles](../../generic/testing/core-principles.md) - Universal testing principles
- [Generic Error Handling Principles](../../generic/error-handling/universal-patterns.md) - Universal error handling patterns
- [Generic Performance Principles](../../generic/performance/core-principles.md) - Universal performance principles

**Python-Specific:**
- This directory contains Python-specific implementations and examples

---

## References

### Canonical (language + typing)
- [PEP 8 – Style Guide for Python Code](https://peps.python.org/pep-0008/) — official style guide (Active, last updated 2025-04-04)
- [Python 3 Documentation](https://docs.python.org/3/) — stdlib + language reference (Python 3.14 stable)
- [Static Typing with Python](https://typing.python.org/en/latest/) — official type-system spec and guides
- [PEP 621 — Project metadata in pyproject.toml](https://peps.python.org/pep-0621/) — modern packaging metadata standard

### Modern toolchain (Astral — 2024/2025 shift)
- [uv](https://docs.astral.sh/uv/) — package + project manager; replaces pip, pip-tools, pipx, poetry, pyenv, twine, virtualenv
- [Ruff](https://docs.astral.sh/ruff/) — linter + formatter; replaces Flake8, Black, isort, pydocstyle, pyupgrade, autoflake

### Type checking
- [mypy](https://mypy.readthedocs.io/en/stable/) — reference static type checker (mypy 2.x)
- [pyright](https://microsoft.github.io/pyright/) — Microsoft's type checker (powers Pylance)
- [basedpyright](https://docs.basedpyright.com/latest/) — pyright fork with Pylance features unlocked, PyPI install, stricter defaults

### Testing
- [pytest](https://docs.pytest.org/en/stable/) — de facto test framework (pytest 9.x)

### Commonly used frameworks
- [Pydantic v2](https://pydantic.dev/docs/validation/latest/get-started/) — current v2.13.x; [v1→v2 migration guide](https://pydantic.dev/docs/validation/latest/get-started/migration/)
- [FastAPI](https://fastapi.tiangolo.com/) — async web framework, Pydantic v2 native
- [Polars](https://docs.pola.rs/) — Rust-core dataframe library; pandas alternative for large workloads

### Supplemental
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html) — useful supplement; no visible last-revised date

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
