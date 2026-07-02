# Pre-commit Hooks

CI catches mistakes after the push. Pre-commit catches them before the commit even lands. For Terraform, the de-facto bundle is **`pre-commit-terraform`** (maintained by Anton Babenko), which wires the standard toolchain into the `pre-commit` framework.

Source: [antonbabenko/pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform), [pre-commit](https://pre-commit.com/).

---

## What to Run Before Every Commit

| Hook | What it does | Cost |
|---|---|---|
| `terraform_fmt` | Reformats `.tf` and `.tfvars` to canonical style | < 1s |
| `terraform_validate` | Syntactic + reference validity (per module) | ~1-3s per module |
| `terraform_tflint` | Provider-aware linter (see `security/scanner-stack.md`) | ~2-5s |
| `terraform_docs` | Regenerates `README.md` from `variables.tf` / `outputs.tf` | < 1s |
| `terraform_checkov` | Security scanner (heavier; consider PR-only, not pre-commit) | ~10-30s |

Run the cheap ones (`fmt`, `validate`, `docs`) on every commit. Run the slower ones (`tflint`, `checkov`) on push or in CI to keep the commit loop snappy.

---

## ✅ Good: `.pre-commit-config.yaml`

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.94.0  # pin; bump deliberately
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
        args:
          - --hook-config=--retry-once-with-cleanup=true
      - id: terraform_tflint
        args:
          - --args=--config=.tflint.hcl
      - id: terraform_docs
        args:
          - --hook-config=--path-to-file=README.md
          - --hook-config=--add-to-existing-file=true
          - --hook-config=--create-file-if-not-exist=true

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-merge-conflict
      - id: detect-private-key
```

Install once per clone:

```bash
pre-commit install        # runs on every git commit
pre-commit run --all-files  # one-shot run across the whole repo
```

The first run downloads the hooks and caches them; subsequent commits cost only the per-file diff.

---

## `terraform-docs` Discipline

`terraform-docs` generates a README section from `variables.tf` and `outputs.tf`. To make it idempotent, add markers to your `README.md`:

```markdown
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
```

`terraform-docs` (and the pre-commit hook) regenerates the content between those markers from the live HCL. The rest of the README — usage examples, prose explanation — is preserved.

```bash
# Run manually if you've turned off the hook
terraform-docs markdown table --output-file README.md --output-mode inject .
```

Without auto-regeneration, the README drifts from reality within days. PR reviewers shouldn't have to check that you remembered to update it.

---

## Hook Ordering

`pre-commit` runs hooks in declaration order. The standard order:

1. `terraform_fmt` — rewrites whitespace first so downstream tools see canonical input.
2. `terraform_validate` — fails fast on syntactic errors before the slower tools start.
3. `terraform_tflint` — provider-aware lint.
4. `terraform_docs` — last, because it only reads (doesn't modify HCL).

If `fmt` reformats a file, the commit is aborted with the changes staged — you re-stage and commit again. This two-step is mildly annoying once, then becomes muscle memory.

---

## ❌ Bad: Skip the Hooks "Just This Once"

```bash
# ❌ Bad: bypass for a "quick fix"
git commit --no-verify -m "quick fix"
```

The fastest way to a repo where the hook is effectively dead. After three `--no-verify` commits the formatting drifts, the docs lie, and the next contributor doesn't trust the hooks at all.

Better: if the hook is genuinely broken (network down, version-skew bug), fix the hook config in the same PR. If you're rushing a hotfix, run `pre-commit run --all-files` from another worktree to confirm at least it passes before merging.

---

## CI: Same Hooks, Belt-and-Braces

Even with pre-commit configured, run the same checks in CI for contributors who don't use the hook locally:

```yaml
# .github/workflows/pre-commit.yml
on: [pull_request]
jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }
      - uses: hashicorp/setup-terraform@v3
      - uses: terraform-linters/setup-tflint@v4
      - uses: terraform-docs/gh-actions@v1
      - uses: pre-commit/action@v3.0.1
```

This makes the hook output authoritative: if it fails in CI, the PR is blocked regardless of whether the author had it installed.

---

## Custom Hooks for Org Policy

`pre-commit` supports inline `system` hooks for org-specific rules without writing a plugin:

```yaml
  - repo: local
    hooks:
      - id: no-public-buckets
        name: No public GCS buckets without an exemption tag
        entry: bash scripts/check-public-buckets.sh
        language: system
        files: \.tf$
        pass_filenames: false
```

Keep the script in the repo so reviewers can read it.

---

## Pinning the Hook Version

`rev:` in `.pre-commit-config.yaml` pins to a specific tag. Bump it explicitly:

```bash
pre-commit autoupdate            # rewrites .pre-commit-config.yaml with latest tags
git diff .pre-commit-config.yaml # the PR-visible upgrade
pre-commit run --all-files       # confirm nothing new breaks
```

Treat hook upgrades like any other dependency bump — its own PR, reviewed, with a clean test run.

---

## Related Rules

- [Scanner Stack](scanner-stack.md) — same tools, but explicitly the CI-side stack.
- [File Layout and Naming](../language/file-layout-and-naming.md) — `terraform fmt` enforces it; this rule wires it into the workflow.

---

## References

- [antonbabenko/pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)
- [pre-commit framework](https://pre-commit.com/)
- [terraform-docs](https://github.com/terraform-docs/terraform-docs)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
