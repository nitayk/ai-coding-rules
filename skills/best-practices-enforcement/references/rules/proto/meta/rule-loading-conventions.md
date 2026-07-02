# Rule Loading Conventions

`rules/proto/` follows the standard Layer 2 → Layer 0 model: the directory's `index.md` is the auto-loaded entry point, and each leaf rule loads on demand based on keyword routing or explicit reference. This file documents the loading mechanics so contributors can add new rules without breaking the model.

---

## What auto-loads, what doesn't

| File | When it loads | How |
|---|---|---|
| `rules/proto/index.md` | When proto/buf work is in scope (`.proto`, `buf.yaml`, `buf.gen.yaml`, `buf.work.yaml`, `buf.lock`) | Agent loads it as the entry point |
| `rules/proto/<subdir>/index.md` | On demand, via the top-level index's routing | Manual load by the agent |
| `rules/proto/<subdir>/<rule>.md` | On demand, when a keyword in `index.md`'s routing table matches | Manual load by the agent |

The top-level index is the entry point for this directory. Every leaf rule is loaded when the agent decides it's relevant — either via the keyword router or because another rule referenced it. (Nothing auto-attaches: these are skill `references/`, read on demand — not Cursor globs.)

---

## Glob patterns

The top-level `rules/proto/index.md` declares:

```yaml
globs:
  - "**/*.proto"
  - "**/buf.yaml"
  - "**/buf.gen.yaml"
  - "**/buf.work.yaml"
  - "**/buf.lock"
```

That's the entirety of the auto-load surface. Generated files (`*.pb.go`, etc.) are not in scope — those belong to the Go ruleset (which must exclude them per `gen-code-excluded-from-go-rules.md`).

Sub-indexes and leaf rules have `globs: []` and `alwaysApply: false` — they never auto-load.

---

## Adding a new rule

1. **Pick the subdir** that matches the rule's concern (`schema/`, `grpc/`, `governance/`, `validation/`, `testing/`, `meta/`). Don't add a new subdir without a clear gap.
2. **Slugify the filename**: `lower-kebab-case.md`, descriptive of the rule's content. Match neighbouring filenames where possible.
3. **Write the frontmatter** per the writer brief style contract:
   ```yaml
   ---
   description: "<one-sentence purpose + 'Use when: (1) ..., (2) ..., (3) ...'>"
   globs: []
   alwaysApply: false
   ---
   ```
4. **Add a keyword-router row** to `rules/proto/index.md`'s routing table.
5. **Add a leaf entry** to the same subdir's `index.md` (the sub-index).
6. **Cross-link** to adjacent rules at the bottom under a `## Related Rules` section.

The order matters: without the router row in the top-level index, the rule is invisible to the loading mechanism.

---

## Why leaf rules have `globs: []`

If every leaf rule auto-loaded on `.proto` files, the agent would slurp the entire `rules/proto/` tree into context every time someone opens a schema. Keeping leaves on-demand keeps the loaded context small — the top-level index loads, the keyword router picks the relevant leaves, and the irrelevant ones stay on disk.

This is the same model `rules/go/`, `rules/python/`, etc. use. Don't break it by sprinkling globs on leaves.

---

## Subdir indexes are optional but recommended

`rules/proto/<subdir>/index.md` provides an alternative navigation path — load the sub-index when you want to browse "all governance rules" rather than search by keyword. For sub-areas with 2+ rules, having a sub-index pays for itself; for a sub-area with one rule, the sub-index is just a redirect to that single file (still fine, but not load-bearing).

---

## Interaction with `rules/go/`

A `.proto` file change usually accompanies a `.go` change — either in `unityapis`'s generated output or in a consumer regenerating its stubs. Both rulesets auto-load when both file types are in scope. The `meta/` rules in this directory specifically address that interaction (notably the generated-code exclusion).

If you find yourself needing a rule that spans both directories, write it in the directory that owns the **source**, and reference it from the other. Example: "exclude generated `.pb.go` from Go linters" is a `proto/meta/` rule because the convention is driven by proto codegen, even though the configuration lives in `golangci-lint`.

---

## Always-loaded? Never for leaves

Resist the urge to mark a rule `alwaysApply: true`. The only thing in `rules/proto/` that even comes close to "always" is the top-level index — and it's loaded by glob match, not by `alwaysApply`. The reason: an always-applied rule consumes context tokens on every interaction, regardless of whether `.proto` is involved. That's a high cost; reserve it for truly universal guidance (which lives in `rules/common/`, not in language-specific directories).

---

## Related Rules

- [Generated Code Excluded from Go Rules](gen-code-excluded-from-go-rules.md) — sibling meta rule
- `../index.md` — the auto-loaded top-level index this file describes

---

## References

- [`rules/go/index.md`](../../go/index.md) — the structural template this directory mirrors
- Repository `index.md` style guide (top-level `rules/common/meta/`)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
