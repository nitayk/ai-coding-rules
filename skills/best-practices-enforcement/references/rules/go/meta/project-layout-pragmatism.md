# Project layout pragmatism

`golang-standards/project-layout` is widely referenced (>50k stars) and often
treated as official. It is not. The repo's own README opens with:

> This is a basic layout for Go application projects. **It's not an official
> standard** defined by the core Go dev team...

Treat it as one community pattern among many. Authoritative guidance on
package layout comes from the Go team's docs and Google's Style Decisions.

Sources: [`golang-standards/project-layout` README](https://github.com/golang-standards/project-layout),
[Google Go Style Decisions](https://google.github.io/styleguide/go/decisions).

---

## Start small. Add structure when you feel pain.

A new Go service rarely needs all of `cmd/`, `internal/`, `pkg/`, `api/`,
`build/`, `scripts/`, `configs/`, `deployments/`, `docs/`, `examples/`,
`githooks/`, `vendor/`, `web/`, `tools/`, `third_party/`. Cargo-culting the
full layout buys you:

- Empty directories that confuse newcomers.
- Premature abstraction (e.g. `pkg/` for code that has zero external callers).
- Refactor churn when reality disagrees with the template.

```
# ✅ Good: a small service
myservice/
├── main.go
├── handler.go
├── repo.go
├── handler_test.go
├── repo_test.go
└── go.mod

# ✅ Good: grown up, still minimal
myservice/
├── cmd/server/main.go
├── internal/
│   ├── api/
│   ├── repo/
│   └── domain/
└── go.mod
```

Add `cmd/` when you have a second binary. Add `internal/` when you actually
need to fence code. Add `pkg/` when something is being imported externally
**right now**, not "in case."

---

## Rules that *are* well-grounded

These come from the Go toolchain and the team's docs, not a community
convention — they're load-bearing:

1. **`internal/` blocks external imports** (toolchain enforced). Use it to
   keep "implementation" packages from leaking into other modules' import
   graphs.
2. **`cmd/<name>/main.go` is `package main`**. One binary per directory.
3. **`testdata/` is ignored by `go build`** (toolchain convention). Stash test
   fixtures there.
4. **`vendor/`**, if present, is consulted by `go build` automatically (with
   `-mod=vendor`). Either commit it fully or not at all — don't half-vendor.

Everything else (`pkg/`, `api/`, `build/`, `deployments/`...) is convention,
not toolchain behavior.

---

## `pkg/` is optional, not required

`pkg/` originated as a way to say "this directory is the public part of the
module." But there's no toolchain meaning to it — `internal/` is what
actually fences imports. If you don't have an `internal/`, **everything else
is already public**; adding `pkg/` is decoration.

```
# ✅ Good when you need it
myservice/
├── internal/    # private
└── pkg/         # explicitly public, importable
    └── client/  # users import myservice/pkg/client

# ❌ Cargo-cult: only one directory of code, but it's under pkg/
myservice/
└── pkg/
    └── all-my-code/
```

Reach for `pkg/` when you have **both** a public surface and a private one,
and you want the boundary visible at the directory level.

---

## Prefer Google Style Decisions for package layout questions

When you hit a real layout question — "where do model types live?", "should
errors be in their own package?", "is one giant `util` package OK?" — the
most actionable canonical source is
[Google Go Style Decisions](https://google.github.io/styleguide/go/decisions),
specifically the **Naming**, **Package names**, and **Imports** sections.

Effective Go and the Go wiki cover the same ground but are older.

---

## Don't reorganize a working repo just to "match the layout"

A PR titled "adopt standard project layout" that moves 300 files is almost
always net-negative:

- Every code search and `git blame` regresses.
- Open PRs against the old paths become conflict storms.
- The team learns "structure churn is normal", which makes the *next*
  reorganization easier than it should be.

If the existing layout works, leave it. Apply this rule going forward, not
retroactively.

---

## Reference, don't normalize

When someone cites `project-layout` in a review, the right response is:

> The community layout has good ideas, but it explicitly disclaims being a
> standard. Our convention is X because Y — let's keep it consistent.

Have an answer for Y. "Because that's what the template says" isn't one.

---

## Related rules

- [Project Structure](../architecture/project-structure.md) — Go-specific layout patterns; read alongside this caveat.
- [Naming and Formatting](naming-and-formatting.md) — naming is more load-bearing than layout.

---

## References

- [`golang-standards/project-layout`](https://github.com/golang-standards/project-layout) — community pattern, **self-declares non-official**.
- [Google Go Style Decisions](https://google.github.io/styleguide/go/decisions) — canonical for package layout decisions.
- [Effective Go](https://go.dev/doc/effective_go) — older, but covers naming and package design.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
