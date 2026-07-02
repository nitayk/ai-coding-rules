# `tool` directive in `go.mod` (Go 1.24+)

Go 1.24 added a first-class `tool` directive to `go.mod`. It replaces the
long-standing `tools.go` workaround — a file with `// +build tools` and blank
imports of binaries you wanted pinned. The directive does the same job in one
line per tool, with no fake source file.

Sources: [Go 1.24 release notes](https://go.dev/doc/go1.24),
[Managing dependencies](https://go.dev/doc/modules/managing-dependencies).

---

## Use `go get -tool` to pin a tool

```bash
# ✅ Good: pin a build tool in go.mod
go get -tool golang.org/x/tools/cmd/stringer@latest
go get -tool github.com/golangci/golangci-lint/cmd/golangci-lint@v2.12.2
```

Result in `go.mod`:

```
tool (
    golang.org/x/tools/cmd/stringer
    github.com/golangci/golangci-lint/cmd/golangci-lint
)
```

Run with:

```bash
go tool stringer -type=Color
go tool golangci-lint run
```

The version is reproducible (locked in `go.sum`); no global install required.

---

## Migrate the `tools.go` pattern

If your repo still has the legacy file:

```go
// ❌ Old: tools.go
//go:build tools

package tools

import (
    _ "golang.org/x/tools/cmd/stringer"
    _ "github.com/golangci/golangci-lint/cmd/golangci-lint"
)
```

Replace it (Go 1.24+):

```bash
# ✅ New: one command per tool, then delete tools.go
go get -tool golang.org/x/tools/cmd/stringer
go get -tool github.com/golangci/golangci-lint/cmd/golangci-lint
rm tools.go
```

Update your `Makefile`/CI scripts:

```diff
- go install golang.org/x/tools/cmd/stringer
- stringer -type=Color
+ go tool stringer -type=Color
```

---

## When to keep `tools.go` (transitional)

If the module **still has to build on Go ≤ 1.23**, keep `tools.go` and don't
add `tool` directives — older toolchains don't understand the directive and
will refuse the module. Drop `tools.go` only after the `go` line in `go.mod`
is bumped to `1.24+`.

```
// go.mod
go 1.24            // safe to use `tool` directive
```

---

## Don't mix the two mechanisms

Pick one per module. Running both means:
- Tool versions live in two places (`tools.go` blank imports vs `tool` block).
- Devs and CI may install different copies depending on which they invoke.
- A migration PR that "added the directive but kept tools.go" leaves the next
  contributor unsure which is authoritative.

If you're mid-migration, do it in one commit.

---

## Don't use `tool` for production runtime dependencies

`tool` is for **build / test / codegen** binaries — things you run *during
development*, not things your service imports at runtime. Runtime dependencies
go in `require` like normal; the `tool` block is read by `go tool`, not by
your binary.

```go
// ✅ Good
tool (
    golang.org/x/tools/cmd/stringer       // codegen
    github.com/google/wire/cmd/wire       // codegen
    github.com/golangci/golangci-lint/cmd/golangci-lint  // lint
)

// ❌ Bad: this is a runtime lib, not a tool
tool (
    google.golang.org/grpc  // wrong place
)
```

---

## CI: one less install step

A typical CI block before:

```yaml
- run: go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.55.0
- run: golangci-lint run
```

After:

```yaml
- run: go tool golangci-lint run   # version comes from go.mod
```

No `go install`, no `$GOBIN` in `PATH`, no version drift between dev and CI.

---

## Related rules

- [golangci-lint v2 migration](golangci-lint-v2-migration.md) — golangci-lint is a typical `tool` entry.
- [go fix modernization](go-fix-modernization.md) — `go fix` is also installable as a `tool` if you pin a specific build.

---

## References

- [Go 1.24 release notes](https://go.dev/doc/go1.24)
- [Managing dependencies](https://go.dev/doc/modules/managing-dependencies)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
