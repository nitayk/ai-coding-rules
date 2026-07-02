# Go Development Rules

**Go-Specific Rules**: Implementation details for Go code.

**How It Works**:
- Generic rules (SOLID, DRY, KISS, correctness first) load **automatically** when you open Go files
- This index loads **automatically** when you open Go files (via globs)
- Use this to discover Go-specific patterns (error wrapping, goroutines, interfaces)

**Key Principle**: This directory contains ONLY Go-specific patterns. Universal principles are in `generic/` and load automatically - they're referenced from here.

**Graph Structure**: This is a Layer 2 node that routes directly to Layer 0 leaves (rule files) based on keywords. Flattened for efficiency. Sub-indexes (`language/index.md`, `architecture/index.md`, `performance/index.md`, `testing/index.md`, `tooling/index.md`) provide alternative category-based navigation.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **error handling**, errors, error wrapping, custom errors | `language/error-handling-patterns.md` |
| **idiomatic errors**, guard clauses, explicit checks, error wrapping | `language/idiomatic-error-handling.md` |
| **concurrency**, goroutines, channels, worker pools, errgroup | `language/concurrency-patterns.md` |
| **mutex**, locking, sync.Mutex, RWMutex, deadlock | `language/mutex-and-locking.md` |
| **context**, cancellation, deadlines, context propagation, WithoutCancel, AfterFunc | `language/context-patterns.md` |
| **interfaces**, small interfaces, interface design | `language/small-interfaces.md` |
| **slog**, structured logging, log/slog, JSON handler, LogValuer | `language/slog-structured-logging.md` |
| **iter**, iterators, range-over-func, iter.Seq, iter.Pull, slices.Values, maps.Keys | `language/iter-and-range-over-func.md` |
| **architecture**, project structure, directory organization | `architecture/project-structure.md` |
| **performance**, profiling, optimization, escape analysis, PGO, Swiss Tables, Green Tea GC | `performance/profiling-and-optimization.md` |
| **testing**, table-driven tests, go testing | `testing/table-driven-tests.md` |
| **mocking**, integration tests, fuzz testing | `testing/mocking-and-integration.md` |
| **synctest**, fake clock, deterministic time tests, flaky timing | `testing/synctest-for-time-dependent-code.md` |
| **govulncheck**, vulnerabilities, security CI gate, go vuln | `tooling/govulncheck-in-ci.md` |
| **go fix**, modernize, //go:fix inline, idiom rewrite | `tooling/go-fix-modernization.md` |
| **tool directive**, go.mod tool, tools.go migration, go get -tool | `tooling/go-mod-tool-directive.md` |
| **golangci-lint**, v2 migration, linter config | `tooling/golangci-lint-v2-migration.md` |
| **style**, naming, formatting, go style | `meta/naming-and-formatting.md` |
| **production**, production-ready, Uber style, deployment | `meta/go-production-patterns.md` |
| **project layout**, golang-standards, cmd/internal/pkg, cargo-cult layout | `meta/project-layout-pragmatism.md` |

---

## Available Rules (Leaves)

### 🔧 Language Features (`language/`)
- **[Error Handling Patterns](language/error-handling-patterns.md)** - Error creation, wrapping, custom errors, panic/recover
- **[Idiomatic Error Handling](language/idiomatic-error-handling.md)** - Explicit checks, guard clauses, error wrapping patterns
- **[Small Interfaces](language/small-interfaces.md)** - Design small, focused interfaces - prefer single-method interfaces
- **[Context Patterns](language/context-patterns.md)** - Cancellation, deadlines, context propagation, `WithoutCancel`/`AfterFunc` (Go 1.21+)
- **[Concurrency Patterns](language/concurrency-patterns.md)** - Goroutines, channels, worker pools, errgroup, Go 1.22 loopvar
- **[Mutex and Locking](language/mutex-and-locking.md)** - sync.Mutex, RWMutex, deadlock prevention, channels vs mutex
- **[slog Structured Logging](language/slog-structured-logging.md)** - Stdlib `log/slog` for structured logging (Go 1.21+)
- **[iter and Range-over-func](language/iter-and-range-over-func.md)** - `iter.Seq`, range-over-func, stdlib iterator helpers (Go 1.23+)

### 🏗️ Architecture (`architecture/`)
- **[Project Structure](architecture/project-structure.md)** - Layout patterns; toolchain-enforced vs convention

### 🚀 Performance (`performance/`)
- **[Profiling and Optimization](performance/profiling-and-optimization.md)** - Profiling, escape analysis, memory allocation, PGO, Go 1.24/1.25 runtime wins

### 🧪 Testing (`testing/`)
- **[Table-Driven Tests](testing/table-driven-tests.md)** - Idiomatic Go testing pattern for multiple test cases
- **[Mocking and Integration](testing/mocking-and-integration.md)** - Mocking, integration tests, fuzz testing
- **[synctest for Time-Dependent Code](testing/synctest-for-time-dependent-code.md)** - Deterministic timing tests via fake clock (Go 1.24+, experimental)

### 🛠️ Tooling (`tooling/`)
- **[govulncheck in CI](tooling/govulncheck-in-ci.md)** - Required security gate alongside `go vet`/`-race`/fuzz
- **[go fix Modernization](tooling/go-fix-modernization.md)** - Mechanical idiom rewrites (Go 1.26+); `//go:fix inline` for own helpers
- **[tool Directive in go.mod](tooling/go-mod-tool-directive.md)** - Replace `tools.go` with `go get -tool` (Go 1.24+)
- **[golangci-lint v2 Migration](tooling/golangci-lint-v2-migration.md)** - Schema migration off v1; pinning, `--fix`, triage

### 📝 Meta (`meta/`)
- **[Naming and Formatting](meta/naming-and-formatting.md)** - Naming conventions, code organization
- **[Go Production Patterns](meta/go-production-patterns.md)** - Uber/Google style, production readiness, slog default
- **[Project Layout Pragmatism](meta/project-layout-pragmatism.md)** - `golang-standards/project-layout` is community, not normative

## Planned Categories

### 🔧 Language Features (Coming Soon)
- Defer, panic, and recover
- Package design patterns

### 📊 Data Handling (Coming Soon)
- JSON serialization
- Database patterns
- Validation

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../generic/code-quality/core-principles.md) - Universal principles (SOLID, DRY, KISS, YAGNI, correctness first, pure functions)
- [Generic Architecture Principles](../../generic/architecture/core-principles.md) - Universal architecture principles
- [Generic Testing Principles](../../generic/testing/core-principles.md) - Universal testing principles
- [Generic Error Handling Principles](../../generic/error-handling/universal-patterns.md) - Universal error handling patterns
- [Generic Performance Principles](../../generic/performance/core-principles.md) - Universal performance principles

**Go-Specific:**
- This directory contains Go-specific implementations and examples

---

## References

**Canonical (Go team)**
- [Effective Go](https://go.dev/doc/effective_go) — Core idioms. *Note: page banner declares "not actively updated" — pair with sources below for generics/modules/slog/iter.*
- [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments) — Canonical wiki (moved from github.com/golang/go/wiki)
- [Go Security Best Practices](https://go.dev/doc/security/best-practices) — govulncheck, fuzzing, `-race`, `go vet`
- [Managing dependencies](https://go.dev/doc/modules/managing-dependencies) — Modules + Go 1.24 `tool` directive
- [Structured Logging with slog](https://go.dev/blog/slog) — Stdlib structured logging (Go 1.21+)
- [Go 1.23 release notes](https://go.dev/doc/go1.23) — `iter` package and range-over-func
- [The Go Blog](https://go.dev/blog/) — Ongoing canonical updates (go fix, GC, runtime)

**Authoritative external style guides**
- [Google Go Style Guide](https://google.github.io/styleguide/go/guide) — Normative (top of 3-doc hierarchy)
- [Google Go Style Decisions](https://google.github.io/styleguide/go/decisions) — Verbose, most actionable
- [Google Go Best Practices](https://google.github.io/styleguide/go/best-practices) — Patterns above the Style Guide level
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md) — Strong industry guide (concurrency, mutex, functional options)

**Tooling**
- [golangci-lint](https://golangci-lint.run/) — De-facto Go meta-linter (**v2.x current**; migrate off v1)

**Community (use with caution)**
- [Standard Go Project Layout](https://github.com/golang-standards/project-layout) — Widely referenced but **self-declares non-official**; prefer Google Style Decisions for package layout

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
