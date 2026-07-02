# Type Checker Selection

Pick exactly one static type checker per repository and pin it in `pyproject.toml`. Running two checkers in CI doubles the noise and creates conflicts when they disagree (and they will). The three serious choices in 2025-2026 are **mypy**, **pyright**, and **basedpyright**.

---

## Decision matrix

| Criterion | mypy | pyright | basedpyright |
|---|---|---|---|
| Authority | Reference impl from Python typing team | Microsoft (powers Pylance/VSCode) | Community fork of pyright |
| Install | `pip install mypy` (pure Python) | `pip install pyright` (downloads Node binary) | `pip install basedpyright` (PyPI binary, no Node) |
| Speed | Slower, single-threaded | Fast, incremental | Fast (tracks pyright ~1 day) |
| Editor UX | Plugin support, slower feedback | Pylance (VSCode only) | Pylance features unlocked in any editor |
| Default strictness | Permissive (must opt in) | Permissive | Strict by default + baseline support |
| Plugin ecosystem | Mature (SQLAlchemy, Pydantic, Django) | Limited | Same as pyright |
| Best when | Long-lived codebase with framework plugins | Editor-integrated workflow on VSCode | Greenfield strict project; non-VSCode editor; want Pylance features |

---

## Pick by repo profile

- **Existing service using SQLAlchemy/Pydantic/Django** → `mypy`. Plugins close gaps the other two can't.
- **New service, team uses VSCode, want fast editor feedback** → `pyright` (Pylance covers editor; CI runs `pyright` for parity).
- **New service, want maximum strictness + baseline + cross-editor** → `basedpyright`.
- **Library you publish** → `mypy` for compatibility; users expect it.

Don't run both. If you must validate one against the other during migration, do it once and pick the winner.

---

## mypy config

```toml
# Good: mypy in pyproject.toml
[tool.mypy]
python_version = "3.13"
strict = true                       # turns on the full strict bundle
warn_unreachable = true
warn_redundant_casts = true
exclude = ["migrations/", "generated/"]

# Per-module overrides for legacy code
[[tool.mypy.overrides]]
module = ["legacy.*"]
disallow_untyped_defs = false
```

```bash
uv run mypy src/
```

`strict = true` is the modern default for new code. For incremental adoption, leave it off and ratchet individual flags up over time (`disallow_untyped_defs`, `disallow_any_generics`, `warn_return_any`).

---

## pyright config

```toml
# Good: pyright in pyproject.toml
[tool.pyright]
include = ["src", "tests"]
exclude = ["**/__pycache__", "**/migrations"]
pythonVersion = "3.13"
typeCheckingMode = "strict"        # off | basic | standard | strict | all
reportMissingTypeStubs = "warning"
```

```bash
uv run pyright
```

`typeCheckingMode = "strict"` is the analogue of mypy's `strict = true`. Pyright also supports `# pyright: strict` per-file pragmas for gradual migration.

---

## basedpyright config

```toml
# Good: basedpyright — same schema as pyright, stricter defaults
[tool.basedpyright]
include = ["src", "tests"]
pythonVersion = "3.13"
typeCheckingMode = "strict"
reportImplicitOverride = "error"   # basedpyright-only stricter check
```

```bash
uv run basedpyright
uv run basedpyright --baselinefile pyright-baseline.json    # baseline drift
```

basedpyright's killer feature is the **baseline file**: snapshot existing errors, fail CI only on new ones. This is the cleanest path to adopting types on a legacy codebase without a flag day.

---

## CI patterns

```yaml
# Good: single checker in CI
- run: uv run mypy src/        # or: pyright / basedpyright
```

❌ Don't run two type checkers in CI — disagreement is normal (e.g. mypy and pyright handle `Self` and protocol variance differently) and produces unfixable noise.

---

## Editor parity

If devs use Pylance (VSCode) but CI runs mypy, expect periodic disagreements. Two mitigations:

1. **Match versions and config:** ensure Pylance's `python.analysis.typeCheckingMode` matches the CI tool's strictness.
2. **CI is the source of truth:** the editor squiggle is advisory; the green check is the gate. Document this in the repo's `CONTRIBUTING.md`.

For mixed-editor teams, `basedpyright` removes the Pylance-vs-CI split entirely — same engine in both places.

---

## Stubs and third-party types

All three checkers honor:

- Inline annotations in installed packages with `py.typed` marker (PEP 561)
- Stub-only packages: `pip install types-requests`, `types-PyYAML`, etc.
- Local stubs under a `stubs/` dir referenced via `mypy_path` / `stubPath`

When a third-party library has no stubs and no inline types, add a `[[tool.mypy.overrides]]` block (or `reportMissingTypeStubs = "none"` in pyright) for that module only — don't disable the rule globally.

---

## Common pitfalls

❌ Running `mypy --strict` on day 1 of a legacy codebase. Use basedpyright's baseline, or ratchet mypy flags incrementally.

❌ Mixing `# type: ignore` (mypy) and `# pyright: ignore` (pyright) — settle on one syntax matching your chosen tool.

❌ Pinning the type checker outside the lockfile. Type checkers gate CI; their version must move with the lockfile, not float.

✅ Treat the type checker as a unit test. Failures block merge, same as pytest.

---

## Related rules

- [Type Annotations Everywhere](../language/type-annotations-everywhere.md) — what to annotate; the checker enforces it
- [Modern Type Syntax (3.12+)](../language/modern-type-syntax-3-12.md) — PEP 695 generics; all three checkers support
- [uv package manager](uv-package-manager.md) — install the checker via `uv add --dev`

---

## References

- [mypy documentation](https://mypy.readthedocs.io/en/stable/) — reference checker
- [pyright documentation](https://microsoft.github.io/pyright/) — Microsoft's checker
- [basedpyright documentation](https://docs.basedpyright.com/latest/) — community fork with stricter defaults + baseline
- [PEP 561 — distributing type information](https://peps.python.org/pep-0561/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
