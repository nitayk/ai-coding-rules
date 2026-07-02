# Proto Schema Discipline Index

**Purpose**: Routes to file/message/field/enum rules — the foundation everything else (governance, validation, gRPC design) builds on.

**Chaining**: Router → `rules/proto/index.md` → This Index → Files

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **naming**, file basename, package version, casing | `naming-and-layout.md` |
| **optional**, field presence, hasField, proto3 presence | `field-presence-and-optional.md` |
| **editions**, Edition 2024/2023, proto3 vs editions, Prototiller | `editions-adoption.md` |
| **enum**, UNSPECIFIED, zero value, enum value lifecycle | `enum-hygiene.md` |
| **Empty**, `google.protobuf.Empty`, RPC request/response design | `avoid-empty-rpc-messages.md` |

---

## Schema Rule Files (Leaves)

| File | Purpose |
|------|---------|
| [Naming and Layout](naming-and-layout.md) | Buf-enforceable file/message/field/enum/package conventions |
| [Field Presence and `optional`](field-presence-and-optional.md) | Use `optional` for scalar presence in proto3 |
| [Editions Adoption](editions-adoption.md) | Edition 2024 latest, Edition 2023 baseline, Prototiller migration |
| [Enum Hygiene](enum-hygiene.md) | `UNSPECIFIED = 0`, never renumber, never remove values |
| [Avoid Empty RPC Messages](avoid-empty-rpc-messages.md) | Custom req/resp over `google.protobuf.Empty` |

---

## Related Resources

- **gRPC service design**: `../grpc/index.md` — Status codes, deadlines, FieldMask, AIP patterns
- **Governance**: `../governance/index.md` — `buf lint`, `buf breaking`, `buf format`
- **Validation**: `../validation/index.md` — protovalidate (CEL constraints)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
