# Proto Governance Index

**Purpose**: Routes to the CI-enforceable proto rules. Schema and gRPC rules tell you what good schemas look like; governance rules tell you how to keep them that way.

**Note**: `governance/buf-breaking-against-main.md` is the single highest-leverage rule in this entire directory. When `apis` is consumed by every Go backend in the org, one accidental field-number reuse has cross-repo blast radius. Wire it in first.

**Chaining**: Router → `rules/proto/index.md` → This Index → Files

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **buf lint**, lint in CI, STANDARD category | `buf-lint-in-ci.md` |
| **buf breaking**, breaking change, against main, FILE vs WIRE | `buf-breaking-against-main.md` |
| **buf format**, formatter, pre-commit | `buf-format-precommit.md` |
| **backward compat**, AIP-180, what you can change | `backward-compatibility-checklist.md` |
| **BSR**, Buf Schema Registry, vendored protos, schema distribution | `bsr-vs-vendored-protos.md` |

---

## Governance Rule Files (Leaves)

| File | Purpose |
|------|---------|
| [buf lint in CI](buf-lint-in-ci.md) | STANDARD category enforcement on every PR |
| [buf breaking against main](buf-breaking-against-main.md) | **Highest-leverage rule**. FILE tier default; gate every `.proto` PR |
| [buf format pre-commit](buf-format-precommit.md) | Canonical formatter, replaces ad-hoc clang-format-for-proto |
| [Backward Compatibility Checklist](backward-compatibility-checklist.md) | AIP-180 what-you-can-and-cannot-change reference |
| [BSR vs Vendored Protos](bsr-vs-vendored-protos.md) | Schema distribution decision criteria |

---

## Related Resources

- **Schema**: `../schema/index.md` — what `buf lint` and `buf breaking` actually enforce
- **gRPC**: `../grpc/index.md` — service design rules; many show up as Buf lint checks
- **Validation**: `../validation/index.md` — protovalidate annotations also need `buf lint` coverage

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
