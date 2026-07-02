# `go fix` for modernization

As of Go 1.26 (Feb 2026), `go fix` has graduated from "rewrite import paths"
into a real modernization tool: it rewrites old idioms into modern stdlib
equivalents — manual `for`-loops into `slices.Contains`, ternary helpers into
`min`/`max`, etc. The `//go:fix inline` directive lets you mark your own
deprecated helpers so callers can be migrated mechanically.

Sources: [Using go fix to modernize Go code (Go Blog, Feb 2026)](https://go.dev/blog/),
[The Go Blog index](https://go.dev/blog/).

---

## Run it before the lint gate, not after a release

`go fix` is a mechanical rewrite. It shouldn't be a code-review topic — apply
it, commit the diff alone, then start the feature work.

```bash
# ✅ Good: dedicated modernization commit
go fix -fix=modernize ./...
git add -A
git commit -m "chore: go fix modernize"
```

This keeps the diff reviewable. Bundled into a feature commit, the noise hides
the actual change.

---

## What it rewrites (representative)

| Before                                                  | After                          |
|---------------------------------------------------------|--------------------------------|
| `for _, x := range s { if x == v { return true } }`     | `slices.Contains(s, v)`        |
| Manual `if a > b { ... } else { ... }` for max          | `max(a, b)`                    |
| Hand-rolled `sort.Slice` with a comparator              | `slices.SortFunc`              |
| `bytes.Buffer{}` + `WriteString` chains for small joins | `strings.Builder` / `strings.Join` |

The full set evolves. Treat the tool as the source of truth, not the table.

---

## Use `//go:fix inline` for your own deprecated helpers

If your codebase exported `mypkg.Contains` and you want to redirect callers to
`slices.Contains`, annotate the old helper so `go fix` inlines the rewrite
across the module.

```go
// ✅ Good: marked for mechanical rewrite
// Deprecated: use slices.Contains.
//
//go:fix inline
func Contains[T comparable](s []T, v T) bool {
    return slices.Contains(s, v)
}
```

After running `go fix`, the deprecated wrapper has zero callers and can be
deleted in the next minor version.

```go
// ❌ Bad: deprecate-only, no migration path
// Deprecated: use slices.Contains.
func Contains[T comparable](s []T, v T) bool { ... }
// (callers never migrate; the deprecation lives forever)
```

---

## Don't rewrite during a release branch

`go fix` touches many files. Don't run it on a release/maintenance branch —
the noise blocks cherry-picks and bisects.

- **OK**: `main`, feature branches, dependency-bump branches.
- **Not OK**: `release/*`, hotfix branches, anything you'll cherry-pick from.

---

## Pair with `gofmt` and `goimports`, not in place of them

`go fix` is a complement, not a substitute:

```bash
go fix ./...        # idiom modernization
gofmt -s -w .       # formatting + simplify
goimports -w .      # import management
```

Run them in that order in your repo's `make fmt` target. `go fix` first means
imports/formatting catch any new imports the rewrites added.

---

## Pre-PR policy

A reasonable team policy:

- Run `go fix ./...` whenever you bump the Go toolchain version.
- Don't require it on every PR — too noisy for one-line changes.
- Do require that PR authors don't *undo* modernizations applied earlier.

---

## Related rules

- [golangci-lint v2 migration](golangci-lint-v2-migration.md) — the `modernize` analyzer covers similar ground when run as a linter.
- [Naming and Formatting](../meta/naming-and-formatting.md) — `gofmt` pairs with `go fix`.

---

## References

- [Using go fix to modernize Go code (Go Blog, Feb 2026)](https://go.dev/blog/)
- [The Go Blog](https://go.dev/blog/)
- [`go fix` documentation](https://pkg.go.dev/cmd/go#hdr-Update_packages_to_use_new_APIs)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
