# Generated Code Excluded from Go Rules

`.pb.go`, `*_grpc.pb.go`, `*.pb.validate.go`, `*.connect.go`, and other proto-generated files are produced by `buf generate` (or `protoc`). They are **read-only artifacts** — every change must be made by editing the `.proto` source and regenerating. Treating them as regular Go code in linters, coverage tools, and security scanners produces a constant stream of noise and tempts the worst possible response: hand-editing the generated file.

Sources: [GitHub `linguist` — generated files](https://github.com/github-linguist/linguist/blob/main/docs/overrides.md), [`golangci-lint` skip configuration](https://golangci-lint.run/).

---

## The exclusion list

| File pattern | Producer |
|---|---|
| `*.pb.go` | `protoc-gen-go` |
| `*_grpc.pb.go` | `protoc-gen-go-grpc` |
| `*.pb.validate.go` | `protoc-gen-validate` (PGV) — being phased out |
| `*.pb.gw.go` | `protoc-gen-grpc-gateway` |
| `*.connect.go` | `protoc-gen-connect-go` |

If you have a custom plugin, add its output pattern here too. Anything under a top-level `gen/` directory (per `../validation/codegen-toolchain.md`) can be excluded by directory rather than by suffix:

```
gen/go/**/*.go
```

---

## `golangci-lint` configuration

```yaml
# .golangci.yml
run:
  skip-dirs:
    - gen
  skip-files:
    - '.*\.pb\.go$'
    - '.*_grpc\.pb\.go$'
    - '.*\.pb\.validate\.go$'
    - '.*\.pb\.gw\.go$'
    - '.*\.connect\.go$'
```

Belt-and-suspenders: `skip-dirs` covers the convention-based layout, `skip-files` catches anything that's escaped into the hand-written tree.

---

## Coverage exclusion

Generated code has no real branches you can write tests for — covering it is meaningless. Exclude it from coverage so the percentage reflects actual hand-written code:

```bash
# ✅ Good: coverage excludes generated paths
go test ./... -coverprofile=cover.out
grep -v '\.pb\.go:' cover.out | grep -v '/gen/' > cover.filtered.out
go tool cover -func=cover.filtered.out
```

If you use `gocov` / `gcov2lcov` / Codecov, configure their ignore lists similarly. Same applies to SonarQube / Codacy.

---

## GitHub: mark as `linguist-generated`

GitHub's language detector picks up generated code as Go and bloats the repo's reported Go LOC. Add a `.gitattributes` entry to mark generated files:

```
# .gitattributes
gen/** linguist-generated=true
*.pb.go linguist-generated=true
*_grpc.pb.go linguist-generated=true
*.pb.validate.go linguist-generated=true
```

After this, generated files:

- Don't count towards language stats on the repo landing page.
- Are collapsed by default in PR diffs (huge productivity win on schema PRs).
- Are excluded from GitHub Code Search.

---

## Security scanners

`gosec`, Snyk, Trivy, Semgrep, and similar tools should also skip generated paths. Most accept the same kinds of exclusion patterns:

```yaml
# semgrep .semgrepignore
gen/
*.pb.go
*_grpc.pb.go
```

A real vulnerability in `protoc-gen-go`'s output is upstream's problem, not ours — bumping the plugin version is the fix, not patching a `.pb.go` by hand.

---

## What "read-only" means in practice

If `buf generate` would change a file, that file is generated and you don't touch it. Concrete consequences:

- Never `git add` a hand-edit to a `.pb.go`. CI's "buf generate + diff" check (see `../validation/codegen-toolchain.md`) will fail anyway, but a clean local discipline prevents wasted PRs.
- Bug in generated code → bug in the plugin or in the source `.proto`. Fix at the source.
- Want a different generated shape (e.g. a custom field tag)? That's a plugin option or a different plugin — not a manual edit.

---

## Rules-engine matchers

This ruleset's globs (`**/*.proto`, `**/buf.*.yaml`) deliberately don't match generated code. The Go ruleset's globs (`**/*.go`) **do** match generated code, which is why the linter exclusions above matter. If you write a new repo-specific rule that targets Go files, exclude `gen/` / `*.pb.go` for the same reason.

---

## When generated code does have a bug

The escape valve: if `protoc-gen-go` produces invalid code, file an upstream issue. If you absolutely cannot wait, the right local fix is one of:

1. Pin to an older plugin version that doesn't have the bug.
2. Apply a `replace` in `go.mod` to a forked plugin.
3. Add a hand-written wrapper in a non-generated file that fixes the consuming side.

None of these involve editing the `.pb.go`. Editing the generated file means your next `buf generate` silently overwrites the fix — usually noticed weeks later as a regression in production.

---

## Related Rules

- [Codegen Toolchain](../validation/codegen-toolchain.md) — what produces the generated files
- [BSR vs Vendored Protos](../governance/bsr-vs-vendored-protos.md) — affects whether generated code is even in your tree

---

## References

- [GitHub Linguist — overrides](https://github.com/github-linguist/linguist/blob/main/docs/overrides.md)
- [`golangci-lint` configuration](https://golangci-lint.run/)
- [google.golang.org/protobuf](https://pkg.go.dev/google.golang.org/protobuf)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
