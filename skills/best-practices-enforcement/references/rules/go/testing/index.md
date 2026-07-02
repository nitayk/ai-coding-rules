# Go Testing Patterns Index

**Purpose**: Router for Go testing patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **table-driven tests**, go testing, testing patterns | `table-driven-tests.md` |
| **mocking**, integration tests, fuzz testing | `mocking-and-integration.md` |

---

## Testing Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Table-Driven Tests](table-driven-tests.md) | Idiomatic Go testing pattern for multiple test cases | table-driven tests, testing patterns |
| [Mocking and Integration](mocking-and-integration.md) | Mocking, integration tests, fuzz testing | mocking, integration, fuzz |

---

## Quick Reference

| Need | Load |
|------|------|
| Table-driven tests | `table-driven-tests.md` |
| Mocking, integration, fuzz | `mocking-and-integration.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Generic**: See `references/rules/common/generic/testing/core-principles.md` for universal testing principles

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
