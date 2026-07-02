# gRPC Service Design Index

**Purpose**: Routes to RPC-shape, error-model, timeout, and AIP-pattern rules. Schema concerns (naming, enums, field presence) live in `../schema/`.

**Chaining**: Router → `rules/proto/index.md` → This Index → Files

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **status codes**, gRPC codes, NOT_FOUND vs INVALID_ARGUMENT, error mapping | `status-codes-and-errors.md` |
| **deadlines**, timeouts, cancellation, context propagation across gRPC | `deadlines-and-timeouts.md` |
| **FieldMask**, partial update, PATCH, update_mask | `update-and-fieldmask.md` |
| **resource naming**, resource path, collection ID, AIP-122 | `resource-naming-aip.md` |
| **pagination**, page_token, page_size, AIP-158 | `pagination-aip.md` |
| **long-running**, LRO, Operation, AIP-151 | `long-running-operations.md` |

---

## gRPC Rule Files (Leaves)

| File | Purpose |
|------|---------|
| [Status Codes and Errors](status-codes-and-errors.md) | Canonical 17 codes, NOT_FOUND vs FAILED_PRECONDITION vs ABORTED |
| [Deadlines and Timeouts](deadlines-and-timeouts.md) | Always set client-side; honor and propagate server-side |
| [Update Methods and FieldMask](update-and-fieldmask.md) | AIP-134 PATCH + `update_mask` + etag |
| [Resource Naming](resource-naming-aip.md) | AIP-122 resource path conventions |
| [Pagination](pagination-aip.md) | AIP-158 `page_token` / `page_size` |
| [Long-Running Operations](long-running-operations.md) | AIP-151 `Operation` pattern |

---

## Related Resources

- **Schema discipline**: `../schema/index.md` — naming, optional, enums, Empty
- **Governance**: `../governance/index.md` — `buf lint` / `buf breaking` enforce many of these rules in CI
- **AIP general index**: [google.aip.dev/general](https://google.aip.dev/general) — full AIP catalog

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
