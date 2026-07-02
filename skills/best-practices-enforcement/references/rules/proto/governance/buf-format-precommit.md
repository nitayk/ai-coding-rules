# `buf format` Pre-Commit

`buf format` is the canonical `.proto` formatter, maintained by the Buf team alongside the lint and breaking-change tooling. It has no configuration — there's exactly one way to format a `.proto`, and that's it. Adopt it everywhere; never let two formatters fight over the same file.

Source: [Buf Docs](https://buf.build/docs/).

---

## What it does

`buf format` rewrites every `.proto` file in place:

- 2-space indentation.
- Consistent whitespace around `=`, `;`, `{`, `}`.
- Options sorted into a stable order.
- Trailing newlines / comment alignment normalised.
- Long imports / option lines wrapped to a sensible width.

You don't configure any of these — that's the point. Every contributor's diff stays small because everyone's editor produces byte-identical output.

---

## Replace clang-format-for-proto

Old proto formatting workflows used `clang-format` with a custom `.clang-format` for proto support. That worked but:

1. Clang-format's proto support is a side project, frequently lagging the latest syntax (Editions, etc.).
2. Different teams configured it differently — diffs blow up when files cross team boundaries.
3. No alignment with `buf lint` / `buf breaking` (different tooling, different opinions).

Switch to `buf format`. Delete the `.clang-format` proto section. Reformat everything in a single dedicated commit so future blame stays useful:

```bash
# One-shot migration commit
buf format -w
git add -A
git commit -m "chore(proto): adopt buf format as canonical formatter"
```

Mark this commit's SHA in `.git-blame-ignore-revs` so `git blame` skips it:

```
# .git-blame-ignore-revs
abc123def4567890   # one-shot buf format migration
```

---

## Pre-commit hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/bufbuild/buf
    rev: v1.50.0   # pin a real version
    hooks:
      - id: buf-format     # runs `buf format -w` on changed files
      - id: buf-lint       # see governance/buf-lint-in-ci.md
```

Install once per checkout:

```bash
pre-commit install
```

The pre-commit hook makes the CI check redundant in practice, but keep both — contributors sometimes commit without running hooks, and CI is the final gate.

---

## CI check

Run formatting as a `--diff` check in CI so an un-formatted file fails the build instead of being silently rewritten:

```yaml
# .github/workflows/proto.yml
jobs:
  buf-format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: bufbuild/buf-setup-action@v1
      - name: Check formatting
        run: buf format --diff --exit-code
```

`--exit-code` returns non-zero if any file is unformatted; `--diff` prints the suggested edits.

---

## Editor integration

VS Code and GoLand both support `buf` via LSP:

```jsonc
// .vscode/settings.json
{
  "[proto3]": {
    "editor.defaultFormatter": "bufbuild.vscode-buf",
    "editor.formatOnSave": true
  }
}
```

Once every contributor's editor formats-on-save, the pre-commit hook becomes a safety net rather than the primary mechanism.

---

## What `buf format` does NOT do

- **Reorder fields** — field order is wire-irrelevant but semantically meaningful (it's the canonical authoring order). `buf format` leaves it alone.
- **Renumber fields** — field numbers are part of the wire contract; never touched.
- **Add/remove comments** — comments are preserved verbatim, including doc comments above each declaration.
- **Resolve imports** — that's `buf build` / `buf dep`'s job.
- **Enforce style** — that's `buf lint`'s job. A poorly-named field that's correctly indented still fails lint.

`buf format` and `buf lint` are different layers. Both belong in CI.

---

## Style overrides aren't supported (deliberately)

Buf does not expose options for tab width, max line length, brace placement, etc. The team's position is that formatter knobs are themselves a source of inter-team friction; removing them is a feature. If your team has strong opinions, the answer is to absorb the Buf style — not to fork the formatter.

The one practical consequence: comment alignment and long-option wrapping might shift between Buf versions. Pin the version in pre-commit and bump deliberately to avoid a "the formatter changed on me" churn.

---

## Related Rules

- [buf lint in CI](buf-lint-in-ci.md) — style enforcement (different layer)
- [buf breaking against main](buf-breaking-against-main.md) — wire-compat enforcement (different layer)

---

## References

- [Buf Docs](https://buf.build/docs/)
- [Buf Style Guide](https://buf.build/docs/best-practices/style-guide/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
