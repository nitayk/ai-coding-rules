# Proto Meta Index

**Purpose**: Cross-cutting rules about how the proto ruleset itself loads and how it interacts with adjacent language rulesets (mainly Go, since `.pb.go` is the dominant generated artifact).

**Chaining**: Router → `rules/proto/index.md` → This Index → Files

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **generated code**, `.pb.go`, exclude from lint, linguist-generated | `gen-code-excluded-from-go-rules.md` |
| **rule loading**, globs, when rules apply, alwaysApply | `rule-loading-conventions.md` |

---

## Meta Rule Files (Leaves)

| File | Purpose |
|------|---------|
| [Generated Code Excluded from Go Rules](gen-code-excluded-from-go-rules.md) | `.pb.go` is read-only; lint/test rules must skip it |
| [Rule Loading Conventions](rule-loading-conventions.md) | Which globs / events load which rules in this directory |

---

## Related Resources

- **Adjacent: Go**: `../../go/index.md` — must exclude generated paths from its linters
- **Validation**: `../validation/codegen-toolchain.md` — where generated code comes from

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
