# Proto Validation and Codegen Index

**Purpose**: Routes to runtime-validation and codegen-toolchain rules. These sit between the schema (`../schema/`) and the runtime services that consume them.

**Chaining**: Router → `rules/proto/index.md` → This Index → Files

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **protovalidate**, PGV, CEL validation, buf.validate, field constraints | `protovalidate-over-pgv.md` |
| **protoc-gen-go**, codegen, buf.gen.yaml, pinned versions, tools.go | `codegen-toolchain.md` |

---

## Validation Rule Files (Leaves)

| File | Purpose |
|------|---------|
| [protovalidate over PGV](protovalidate-over-pgv.md) | Use protovalidate (CEL-based) instead of legacy protoc-gen-validate |
| [Codegen Toolchain](codegen-toolchain.md) | `protoc-gen-go` + `protoc-gen-go-grpc`, version pinning, `buf.gen.yaml` |

---

## Related Resources

- **Schema**: `../schema/index.md` — what the constraints attach to
- **Governance**: `../governance/index.md` — `buf lint` covers protovalidate annotations too
- **gRPC**: `../grpc/status-codes-and-errors.md` — failed validation should return `INVALID_ARGUMENT`

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
