# Codegen Toolchain

A proto schema is worthless without code generation. The two core Go plugins are `protoc-gen-go` (messages) and `protoc-gen-go-grpc` (service stubs); validation and other concerns add more. Pin every plugin version explicitly — never rely on whatever's on a contributor's `$PATH`. Drive everything through `buf generate`, not raw `protoc` invocations.

Sources: [Buf Docs — Generate](https://buf.build/docs/), [gRPC Go Quickstart](https://grpc.io/docs/languages/go/quickstart/).

---

## The canonical setup

Three files do all the work: `buf.gen.yaml` declares plugins, `tools.go` pins plugin versions to `go.mod`, and a `make generate` target wires it all together.

```yaml
# buf.gen.yaml
version: v2
managed:
  enabled: true
  override:
    - file_option: go_package_prefix
      value: github.com/example-org/apis/gen/go
plugins:
  - local: protoc-gen-go
    out: gen/go
    opt:
      - paths=source_relative
  - local: protoc-gen-go-grpc
    out: gen/go
    opt:
      - paths=source_relative
  - local: protoc-gen-validate-go   # if using protovalidate-go alongside, name accordingly
    out: gen/go
    opt:
      - paths=source_relative
```

```go
//go:build tools
// +build tools

// Package tools pins codegen plugins to go.mod so versions are tracked.
package tools

import (
    _ "google.golang.org/protobuf/cmd/protoc-gen-go"
    _ "google.golang.org/grpc/cmd/protoc-gen-go-grpc"
)
```

```makefile
# Makefile
.PHONY: tools
tools:
	go install google.golang.org/protobuf/cmd/protoc-gen-go
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc

.PHONY: generate
generate: tools
	buf generate
```

`go.mod` now records the exact plugin versions; every developer running `make generate` gets byte-identical output.

---

## Why never run `protoc` directly

```bash
# ❌ Bad: depends on system protoc, system plugins, system include paths
protoc \
  --go_out=. --go_opt=paths=source_relative \
  --go-grpc_out=. --go-grpc_opt=paths=source_relative \
  -I. example/ads/sdk/v1/ad_request.proto
```

Every flag is a place to drift. `protoc` versions differ across machines; `--go_opt=paths=source_relative` is a thing one developer remembers and another forgets; the `-I` flag has to be reconstructed for every multi-module setup. `buf generate` reads `buf.gen.yaml`, runs the plugins with the same options every time, and resolves dependencies automatically.

```bash
# ✅ Good
buf generate
```

---

## Pin every plugin

`go install` without a version installs `@latest` — which means every developer's machine ends up at a slightly different version. Pin in the install step **and** in `tools.go`/`go.mod`:

```bash
# ✅ Good: pinned in CI / install scripts too
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.34.2
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1
```

```bash
# ❌ Bad: @latest drift
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
```

When a plugin's generated output changes (occasionally for performance or new features), it shows up as a diff in the generated code on PR. Easier to review one intentional bump than a creeping series of mystery diffs.

---

## Generated code lives under `gen/`

Standard convention: all generated code goes under a top-level `gen/` directory, keyed by language. This makes it trivial to:

- Add `gen/` to `.gitattributes` as `linguist-generated=true` (GitHub stops showing it in diffs / search by default).
- Exempt it from Go linters and tests (see `../meta/gen-code-excluded-from-go-rules.md`).
- Distinguish it from hand-written code at a glance.

```
apis/
├── proto/
│   └── example/ads/sdk/v1/*.proto    ← hand-written
├── gen/
│   └── go/
│       └── example/ads/sdk/v1/
│           ├── ad_request.pb.go         ← generated
│           └── ad_service_grpc.pb.go    ← generated
└── buf.gen.yaml
```

---

## Commit generated code? Yes (for vendored distribution)

For the vendored distribution model (see `../governance/bsr-vs-vendored-protos.md`), commit the generated `.pb.go` files. Consumers import the generated package directly; they don't run codegen.

If you ever switch to BSR Remote Plugins or per-consumer codegen, the generated files become an artefact and `gen/` moves to `.gitignore`. That's a deliberate decision, not an accident — make it explicitly when you adopt it.

---

## CI: regenerate and diff

The CI gate is "running `buf generate` produces zero diff." If a contributor edits a `.proto` but forgets to regenerate, this fails.

```yaml
# .github/workflows/proto.yml
jobs:
  buf-generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.23' }
      - uses: bufbuild/buf-setup-action@v1
      - run: make tools
      - run: buf generate
      - name: Check no diff
        run: |
          if [[ -n "$(git status --porcelain)" ]]; then
            echo "Generated code is out of date. Run 'make generate'."
            git diff
            exit 1
          fi
```

---

## Managed-mode is your friend

`managed: enabled: true` in `buf.gen.yaml` lets `buf generate` inject options like `go_package` automatically based on a single repo-wide prefix. Without it, every `.proto` has to declare its own `option go_package = "..."`, and the prefixes drift over time.

```yaml
managed:
  enabled: true
  override:
    - file_option: go_package_prefix
      value: github.com/example-org/apis/gen/go
```

Now every generated file gets `option go_package = "github.com/example-org/apis/gen/go/<package-path>"` derived from the proto package — no per-file maintenance.

---

## Plugin catalog: add deliberately, not casually

Plugins beyond `protoc-gen-go` / `protoc-gen-go-grpc` to consider:

| Plugin | Use case |
|---|---|
| `protoc-gen-validate-go` / protovalidate codegen | Validation code (paired with `../validation/protovalidate-over-pgv.md`) |
| `protoc-gen-openapiv2` | OpenAPI/Swagger spec generation (for gRPC-gateway HTTP exposure) |
| `protoc-gen-grpc-gateway` | Generates a JSON/HTTP reverse-proxy for gRPC services |
| `protoc-gen-connect-go` | ConnectRPC codegen (only relevant if adopting Connect) |
| `protoc-gen-doc` | Markdown/HTML documentation generation |

Each new plugin adds toolchain weight (install step, CI step, version-pin maintenance). Only add when there's a clear consumer.

---

## Related Rules

- [protovalidate over PGV](protovalidate-over-pgv.md) — needs its own plugin entry
- [Generated Code Excluded from Go Rules](../meta/gen-code-excluded-from-go-rules.md) — `gen/` is read-only
- [BSR vs Vendored Protos](../governance/bsr-vs-vendored-protos.md) — affects whether you commit `gen/`

---

## References

- [Buf Docs — Generate](https://buf.build/docs/)
- [gRPC Go Quickstart](https://grpc.io/docs/languages/go/quickstart/)
- [google.golang.org/protobuf](https://pkg.go.dev/google.golang.org/protobuf)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
