# pyproject.toml is the Single Source of Truth (PEP 621)

[PEP 621](https://peps.python.org/pep-0621/) is Final. Project metadata lives in `pyproject.toml` under `[project]` — not in `setup.py`, not in `setup.cfg`, not in `[tool.poetry]`. Every modern build backend (hatch, setuptools, flit, pdm, uv) reads PEP 621 metadata; tool configs (Ruff, mypy, pytest, coverage) live in the same file under `[tool.*]` sections.

---

## Minimum viable pyproject.toml

```toml
# Good: PEP 621 metadata + a build backend
[project]
name = "my-service"
version = "0.1.0"
description = "Short, one-line description"
readme = "README.md"
requires-python = ">=3.12"
license = { text = "MIT" }
authors = [{ name = "Team Name", email = "team@example.com" }]
dependencies = [
    "fastapi>=0.110",
    "pydantic>=2.0",
    "httpx>=0.27",
]

[project.optional-dependencies]
# For deps you DO want to ship to consumers as an extra:
# install with `pip install my-service[postgres]`
postgres = ["asyncpg>=0.29"]

[dependency-groups]
# PEP 735 — for deps that should NEVER ship (dev/test/lint).
dev = ["pytest>=8", "ruff", "mypy"]

[project.scripts]
my-cli = "my_service.cli:main"

[project.urls]
Homepage = "https://example.com/my-service"
Repository = "https://github.com/org/my-service"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

Three required sections: `[project]`, `[build-system]`, and at least one `[tool.*]` block to consolidate tool config.

---

## Optional-dependencies vs dependency-groups

These are different things — pick correctly:

| Use case | Section |
|---|---|
| Optional features users opt into (`pip install pkg[postgres]`) | `[project.optional-dependencies]` |
| Dev / test / lint / docs deps that never ship to consumers | `[dependency-groups]` (PEP 735) |

❌ Don't put `pytest` and `ruff` under `[project.optional-dependencies.dev]` — they leak into the package's installable extras and confuse downstream users.

✅ Put them under `[dependency-groups.dev]`. `uv sync` installs them by default; `uv sync --no-dev` excludes them.

---

## Banned in new code

```python
# ❌ Bad: setup.py with imperative metadata
from setuptools import setup
setup(name="my-service", version="0.1.0", install_requires=["fastapi"])
```

```ini
# ❌ Bad: setup.cfg metadata
[metadata]
name = my-service
version = 0.1.0
```

The setuptools build backend itself is fine — it reads PEP 621 metadata from `pyproject.toml`. What's banned is **duplicating metadata in setup.py/setup.cfg**. If you're using setuptools as your backend, the only contents of `setup.py` should be either absent entirely or a one-line shim — and even that's only needed for editable installs on older setuptools.

---

## Centralize tool config

All tool config goes in `pyproject.toml` under `[tool.<name>]`:

```toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "UP"]

[tool.mypy]
python_version = "3.12"
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-ra -q --strict-markers"
asyncio_mode = "auto"

[tool.coverage.run]
source = ["src"]
branch = true

[tool.coverage.report]
exclude_lines = ["pragma: no cover", "raise NotImplementedError"]
```

Delete the following on adoption:

- `.flake8` / `setup.cfg` `[flake8]` section
- `pytest.ini` / `tox.ini` `[pytest]` section
- `mypy.ini`
- `.coveragerc`
- `pyrightconfig.json` (move to `[tool.pyright]`)

Single file, single grep target, single place to update versions.

---

## Build backend selection

| Backend | Pick when |
|---|---|
| `hatchling` | Default — modern, fast, dependency-free, no setuptools cruft |
| `setuptools` | Existing project; C-extensions; ecosystem tooling assumes it |
| `flit-core` | Pure-Python single-file/module library |
| `pdm-backend` | Already on PDM |
| `poetry-core` | Already on Poetry (but consider migrating to uv + hatchling) |

For new Python projects in this org, prefer `hatchling`. It has zero runtime deps, supports PEP 621 natively, and works with `uv`, `pip`, and `build` out of the box.

---

## Versioning

Pick one source of truth:

```toml
# Good (static): hardcoded version, updated by release tooling
[project]
version = "1.2.3"
```

```toml
# Good (dynamic): version from __init__.py or VCS tag
[project]
dynamic = ["version"]

[tool.hatch.version]
path = "src/my_service/__init__.py"     # e.g. __version__ = "1.2.3"
```

Don't have both static `version =` and `dynamic = ["version"]` — build backends will reject it.

---

## requires-python

Set `requires-python` to the lowest version you actually test against. This:

- Drives `target-version` in Ruff's `UP` rules (modernization)
- Drives `python_version` in mypy/pyright
- Prevents installs on too-old interpreters (pip respects it)

```toml
requires-python = ">=3.12"   # not >=3.8 unless you really test on 3.8
```

---

## Common pitfalls

❌ Keeping `setup.py` "for editable installs" — modern pip + PEP 660 handles editable installs from PEP 621 alone.

❌ Duplicating dep lists across `pyproject.toml` and `requirements.txt`. Pick one (lockfile + pyproject.toml).

❌ Setting `requires-python = ">=3.8"` reflexively. Be honest about what you test.

✅ Validate the file: `uv lock` (or `python -m build`) will surface metadata errors immediately.

---

## Related rules

- [uv package manager](../tooling/uv-package-manager.md) — reads PEP 621 metadata
- [Ruff lint and format](../tooling/ruff-lint-and-format.md) — `[tool.ruff]` config block
- [Type checker selection](../tooling/type-checker-selection.md) — `[tool.mypy]` / `[tool.pyright]` config

---

## References

- [PEP 621 — Storing project metadata in pyproject.toml](https://peps.python.org/pep-0621/) — Final
- [PEP 735 — Dependency Groups](https://peps.python.org/pep-0735/) — dev/test/docs deps
- [PEP 660 — Editable installs](https://peps.python.org/pep-0660/) — replaces `setup.py develop`
- [uv project structure](https://docs.astral.sh/uv/concepts/projects/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
