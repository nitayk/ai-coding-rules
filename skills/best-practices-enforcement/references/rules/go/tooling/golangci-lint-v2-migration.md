# Migrating to `golangci-lint` v2

`golangci-lint` v2 is the current major (v2.12.2, May 2026). v1 still works
but is no longer the line that receives new features or analyzer updates.
Repos still pinning v1 should plan a migration; the config schema changed.

Sources: [golangci-lint releases](https://github.com/golangci/golangci-lint/releases),
[golangci-lint docs](https://golangci-lint.run/).

---

## Pin v2 explicitly

```bash
# ✅ Good: explicit v2 pin, via the Go 1.24 tool directive
go get -tool github.com/golangci/golangci-lint/cmd/golangci-lint@v2.12.2

# Run
go tool golangci-lint run

# Or, for older toolchains
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v2.12.2
```

Don't pin `@latest` in CI — it makes the build non-reproducible and a new
release can flip rule sets on you overnight.

---

## Config schema: the top-level layout changed

v1 used a flat layout. v2 splits enable/disable + per-linter settings cleanly.
Snippet (consult the docs for the full schema for your version):

```yaml
# ✅ Good: v2 shape (.golangci.yml)
version: "2"

linters:
  default: standard
  enable:
    - errcheck
    - govet
    - staticcheck
    - revive
  disable:
    - exhaustruct

linters-settings:
  revive:
    rules:
      - name: unused-parameter
        disabled: true

issues:
  exclude-rules:
    - path: _test\.go
      linters: [errcheck]
```

```yaml
# ❌ Old: v1 shape — will be rejected or quietly ignored on v2
linters:
  enable-all: true
  disable:
    - exhaustruct
```

Run `golangci-lint config verify` after the rewrite to confirm the schema
parses cleanly.

---

## Use `linters.default: standard` instead of `enable-all`

`enable-all` opts you into every linter, including experimental and noisy
ones. The `standard` preset matches the recommended baseline; add what you
want on top.

```yaml
# ✅ Good
linters:
  default: standard
  enable: [gosec, prealloc, perfsprint]

# ❌ Bad — high noise, churns every release
linters:
  enable-all: true
```

---

## Use `--fix` for safe rewrites

Many linters (`gofmt`, `goimports`, `gofumpt`, `gci`, parts of `staticcheck`)
ship safe auto-fixes.

```bash
# ✅ Good: apply mechanical fixes, then review the diff
go tool golangci-lint run --fix
git diff
```

Don't enable `--fix` in CI on the main branch — fixes belong in a dedicated
commit, like `go fix`. CI should *check*, not *write*.

---

## Match the Go version

v2 builds against a specific Go minor. If your `go.mod` says `go 1.24` but you
pin a `golangci-lint` built for `go 1.21`, some analyzers won't understand
newer language features (generics aliases, `range`-over-func, `iter`).

```yaml
# ✅ Good: keep them aligned
go: "1.24"           # in .golangci.yml
```

```
// in go.mod
go 1.24
```

Bump both together.

---

## Don't run two installs in one repo

If you have both `go install golangci-lint@vX` in CI and a `tool` directive in
`go.mod`, you have two pins. Pick one. The `tool` directive is preferred on
Go 1.24+ — version lives next to the code.

---

## Triage: a wall of new findings after the upgrade

v2 enables some analyzers v1 didn't. Expected workflow:

1. Run `go tool golangci-lint run --new-from-rev=HEAD~50` to see only
   regressions introduced recently — easier first pass.
2. For each genuinely new rule that fires across the codebase, decide:
   *enable + fix all* (commit-bot-style), *enable + per-path exclude*, or
   *disable*. Document the choice in `.golangci.yml`.
3. Don't suppress with file-level `//nolint:all` — name the linter and add a
   reason: `//nolint:errcheck // intentional: log-only path`.

---

## Related rules

- [`tool` directive](go-mod-tool-directive.md) — pin golangci-lint via `go.mod`.
- [`go fix` modernization](go-fix-modernization.md) — `go fix` and the `modernize` linter overlap; pick one as the source of truth.

---

## References

- [golangci-lint](https://golangci-lint.run/)
- [golangci-lint releases](https://github.com/golangci/golangci-lint/releases)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
