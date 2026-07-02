# Ruff: One Tool for Lint + Format

[Ruff](https://docs.astral.sh/ruff/) is Astral's Rust-based linter and formatter. It is "10-100x faster than existing tools" and replaces Flake8, Black, isort, pydocstyle, pyupgrade, and autoflake with a single binary and a single config block in `pyproject.toml`. Prefer Ruff for new projects and migrate existing ones — there is no remaining reason to chain multiple Python linters.

---

## What Ruff replaces

| Old tool | Replaced by | Ruff rule prefix |
|---|---|---|
| flake8 + plugins | `ruff check` | `E`, `W`, `F` (pyflakes/pycodestyle) |
| Black | `ruff format` | — (formatter) |
| isort | `ruff check --fix` | `I` |
| pyupgrade | `ruff check --fix` | `UP` |
| pydocstyle | `ruff check` | `D` |
| autoflake | `ruff check --fix` | `F401`, `F841` |
| bandit (partial) | `ruff check` | `S` |

One install, one config, one CI step.

---

## Minimal pyproject.toml block

```toml
# Good: starter Ruff config — extend rule selection as the codebase tolerates it
[tool.ruff]
line-length = 100
target-version = "py312"
extend-exclude = ["migrations", "generated"]

[tool.ruff.lint]
# Start with a strict, opinionated default set.
select = [
    "E", "W",   # pycodestyle
    "F",        # pyflakes
    "I",        # isort
    "B",        # flake8-bugbear
    "UP",       # pyupgrade
    "SIM",      # flake8-simplify
    "RUF",      # Ruff-native rules
]
ignore = [
    "E501",   # line too long — handled by the formatter
]

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101"]   # asserts are fine in tests

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

`target-version` should match (or be the floor of) `requires-python` in `[project]`. This is what enables the `UP` rules to know which `from __future__` imports and modern syntax are safe.

---

## Daily commands

```bash
# Check + autofix in one pass
uv run ruff check --fix .

# Format (Black-compatible)
uv run ruff format .

# Verify nothing needs changing (CI)
uv run ruff check .
uv run ruff format --check .
```

`ruff check --fix` is safe to run repeatedly; unsafe fixes require `--unsafe-fixes` and are opt-in.

---

## Pre-commit integration

```yaml
# Good: .pre-commit-config.yaml — single Ruff repo replaces black/isort/flake8 hooks
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

❌ Don't keep black/isort/flake8 hooks alongside Ruff — duplicate formatting passes and conflicting rules.

---

## CI integration

```yaml
# Good: GitHub Actions
- run: uv run ruff check .
- run: uv run ruff format --check .
```

Both commands exit non-zero on violations. Keep them as two steps so the log line clearly identifies which gate failed.

---

## Choosing rule sets

Start narrow and widen as the codebase tolerates it:

1. **Day-1 baseline:** `E`, `W`, `F`, `I` — pycodestyle, pyflakes, isort. Catches bugs and import ordering with near-zero false positives.
2. **Add when stable:** `B` (bugbear), `UP` (pyupgrade), `SIM` (simplify).
3. **Add for security-sensitive code:** `S` (bandit subset).
4. **Add for libraries / public APIs:** `D` (pydocstyle) with a docstring convention (`google`, `numpy`, or `pep257`).

Use `# noqa: <RULE>` sparingly and always with a rule code — never bare `# noqa`.

---

## Formatter notes

`ruff format` is intentionally Black-compatible — same line-splitting, same string-quote handling. Migrating from Black requires no source changes beyond removing `[tool.black]` from `pyproject.toml`. The formatter and linter share the same parser, so there's no second AST walk and no risk of one tool fighting the other.

---

## Common pitfalls

❌ Don't combine Ruff with Black or isort. Pick one — Ruff. Two formatters guarantees a war.

❌ Don't set `line-length` differently for `[tool.ruff]` and `[tool.ruff.format]`. The single top-level `line-length` covers both.

❌ Don't use `# type: ignore` to silence Ruff. That's for the type checker. Use `# noqa: <CODE>`.

✅ Pin Ruff in your lockfile or pre-commit `rev:`. Ruff rules and autofixes evolve quickly; floating versions cause CI churn.

---

## Related rules

- [uv package manager](uv-package-manager.md) — paired Astral tool; install via `uv add --dev ruff`
- [Type checker selection](type-checker-selection.md) — Ruff is not a type checker; pair with mypy/pyright
- [PEP 8 Style Guide](../meta/pep8-style-guide.md) — Ruff is the enforcer for PEP 8

---

## References

- [Ruff documentation](https://docs.astral.sh/ruff/) — official Astral docs
- [Ruff rules](https://docs.astral.sh/ruff/rules/) — full rule catalog with replacement mapping
- [Ruff formatter](https://docs.astral.sh/ruff/formatter/) — Black-compatibility details

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
