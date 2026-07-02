# Proto Testing Index

**Purpose**: Routes to the rules covering how `.proto` schemas themselves get tested — not how the gRPC services that implement them are tested (that lives in `../../go/testing/` etc.).

**Chaining**: Router → `rules/proto/index.md` → This Index → Files

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **contract test**, golden samples, schema contract, consumer-driven contract | `contract-tests.md` |

---

## Testing Rule Files (Leaves)

| File | Purpose |
|------|---------|
| [Contract Tests](contract-tests.md) | `buf breaking` IS the schema contract test; supplement with golden samples for behaviour |

---

## Related Resources

- **Governance**: `../governance/buf-breaking-against-main.md` — the foundational contract gate
- **Go testing**: `../../go/testing/` — service-level test patterns

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
