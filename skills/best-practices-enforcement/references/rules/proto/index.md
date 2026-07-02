# Protocol Buffers / gRPC Development Rules

**Proto-Specific Rules**: Implementation details for `.proto` schemas, gRPC services, and the surrounding Buf governance / validation / codegen toolchain.

**How It Works**:
- Generic rules (SOLID, KISS, correctness first) load **automatically** when you open `.proto` files
- This index loads **automatically** when you open `.proto` or `buf.*.yaml` files (via globs)
- Use this to discover proto/gRPC-specific patterns (Buf style, AIP design rules, FieldMask, protovalidate)

**Key Principle**: This directory contains ONLY proto/gRPC-specific patterns. Universal principles live in `generic/` and load automatically.

**Schema-repo context**: A shared schema repo (referred to as `apis` in these examples) is consumed by every Go backend across the org. Cross-repo blast radius is much larger than the file count. The single highest-leverage rule in this directory is `governance/buf-breaking-against-main.md` — wire it into CI on the schema repo first.

**Graph Structure**: This is a Layer 2 node that routes directly to Layer 0 leaves (rule files) based on keywords. Flattened for efficiency.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **naming**, file layout, message/field/enum casing, package version | `schema/naming-and-layout.md` |
| **optional**, field presence, proto3 presence, hasField | `schema/field-presence-and-optional.md` |
| **editions**, Edition 2024, Edition 2023, proto3 vs editions, Prototiller | `schema/editions-adoption.md` |
| **enum**, UNSPECIFIED, zero value, enum hygiene | `schema/enum-hygiene.md` |
| **Empty**, `google.protobuf.Empty`, RPC request/response design | `schema/avoid-empty-rpc-messages.md` |
| **status codes**, gRPC codes, NOT_FOUND vs INVALID_ARGUMENT, error mapping | `grpc/status-codes-and-errors.md` |
| **deadlines**, timeouts, cancellation, context propagation across gRPC | `grpc/deadlines-and-timeouts.md` |
| **FieldMask**, partial update, PATCH, update_mask | `grpc/update-and-fieldmask.md` |
| **resource naming**, resource path, collection ID, AIP-122 | `grpc/resource-naming-aip.md` |
| **pagination**, page_token, page_size, AIP-158 | `grpc/pagination-aip.md` |
| **long-running**, LRO, Operation, AIP-151 | `grpc/long-running-operations.md` |
| **buf lint**, lint in CI, STANDARD category | `governance/buf-lint-in-ci.md` |
| **buf breaking**, breaking change, against main, WIRE vs FILE | `governance/buf-breaking-against-main.md` |
| **buf format**, formatter, pre-commit | `governance/buf-format-precommit.md` |
| **backward compat**, AIP-180, what you can change | `governance/backward-compatibility-checklist.md` |
| **BSR**, Buf Schema Registry, vendored protos, schema distribution | `governance/bsr-vs-vendored-protos.md` |
| **protovalidate**, PGV, CEL validation, buf.validate | `validation/protovalidate-over-pgv.md` |
| **protoc-gen-go**, codegen, buf.gen.yaml, pinned versions | `validation/codegen-toolchain.md` |
| **contract test**, golden samples, schema contract | `testing/contract-tests.md` |
| **generated code**, `.pb.go`, exclude from lint | `meta/gen-code-excluded-from-go-rules.md` |
| **rule loading**, globs, when rules apply | `meta/rule-loading-conventions.md` |

---

## Available Rules (Leaves)

### Schema Discipline (`schema/`)
- **[Naming and Layout](schema/naming-and-layout.md)** — file/message/field/enum casing, package version suffix
- **[Field Presence and `optional`](schema/field-presence-and-optional.md)** — proto3 `optional` for scalar presence
- **[Editions Adoption](schema/editions-adoption.md)** — Edition 2024 latest, Edition 2023 baseline, Prototiller migration
- **[Enum Hygiene](schema/enum-hygiene.md)** — `UNSPECIFIED = 0`, never renumber, never remove values
- **[Avoid Empty RPC Messages](schema/avoid-empty-rpc-messages.md)** — custom req/resp over `google.protobuf.Empty`

### gRPC Service Design (`grpc/`)
- **[Status Codes and Errors](grpc/status-codes-and-errors.md)** — canonical 17 codes, never invent app codes
- **[Deadlines and Timeouts](grpc/deadlines-and-timeouts.md)** — always set client-side, propagate server-side
- **[Update Methods and FieldMask](grpc/update-and-fieldmask.md)** — AIP-134 PATCH pattern
- **[Resource Naming](grpc/resource-naming-aip.md)** — AIP-122 resource path conventions
- **[Pagination](grpc/pagination-aip.md)** — AIP-158 `page_token` / `page_size`
- **[Long-Running Operations](grpc/long-running-operations.md)** — AIP-151 `Operation` pattern

### Governance (`governance/`) — highest-leverage subdir
- **[buf lint in CI](governance/buf-lint-in-ci.md)** — STANDARD category on every PR
- **[buf breaking against main](governance/buf-breaking-against-main.md)** — FILE tier default; prevents accidental wire breakage
- **[buf format pre-commit](governance/buf-format-precommit.md)** — canonical formatter
- **[Backward Compatibility Checklist](governance/backward-compatibility-checklist.md)** — AIP-180 what-you-can-change
- **[BSR vs Vendored Protos](governance/bsr-vs-vendored-protos.md)** — schema distribution tradeoffs

### Validation and Codegen (`validation/`)
- **[protovalidate over PGV](validation/protovalidate-over-pgv.md)** — CEL-based validation, the explicit PGV successor
- **[Codegen Toolchain](validation/codegen-toolchain.md)** — `protoc-gen-go` + `protoc-gen-go-grpc`, pinned

### Testing (`testing/`)
- **[Contract Tests](testing/contract-tests.md)** — `buf breaking` IS the contract test; supplement with golden samples

### Meta (`meta/`)
- **[Generated Code Excluded from Go Rules](meta/gen-code-excluded-from-go-rules.md)** — `.pb.go` is read-only
- **[Rule Loading Conventions](meta/rule-loading-conventions.md)** — globs, when each rule applies

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../generic/code-quality/core-principles.md) — SOLID, DRY, KISS, correctness first
- [Generic Architecture Principles](../../generic/architecture/core-principles.md) — boundaries, contracts
- [Generic Testing Principles](../../generic/testing/core-principles.md) — universal testing principles

**Adjacent stacks:**
- [Go Rules](../go/index.md) — generated `.pb.go` lives in Go services; lint rules there must exclude generated paths

---

## References

- [Protocol Buffers Style Guide](https://protobuf.dev/programming-guides/style/) — official naming/layout conventions
- [Protobuf Editions Overview](https://protobuf.dev/editions/overview/) — replaces proto2/proto3; Edition 2024 is latest, Edition 2023 is the migration baseline
- [Proto3 Language Guide](https://protobuf.dev/programming-guides/proto3/) — current syntax reference; explains `optional` for field presence
- [Buf Docs](https://buf.build/docs/) — `buf lint`, `buf breaking`, `buf format`, `buf generate`, BSR
- [Buf Style Guide](https://buf.build/docs/best-practices/style-guide/) — enforceable counterpart to Google's guide; what `buf lint STANDARD` checks
- [Buf Breaking Change Rules](https://buf.build/docs/breaking/rules/) — FILE / PACKAGE / WIRE / WIRE_JSON tiers
- [Google API Improvement Proposals (AIP)](https://google.aip.dev/) — canonical API design rules
- [AIP-180 — Backwards Compatibility](https://google.aip.dev/180) — what you can and cannot change
- [AIP-134 — Update (FieldMask)](https://google.aip.dev/134) — partial updates via `google.protobuf.FieldMask`
- [gRPC Official Documentation](https://grpc.io/docs/) — concepts, language guides, feature guides
- [gRPC Deadlines Guide](https://grpc.io/docs/guides/deadlines/) — deadline propagation across services
- [protovalidate](https://github.com/bufbuild/protovalidate) — explicit successor to `protoc-gen-validate`; CEL-based validation

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
