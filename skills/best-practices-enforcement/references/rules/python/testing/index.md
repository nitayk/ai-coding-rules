# Python Testing Patterns Index

**Purpose**: Router for Python testing patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **pytest**, python testing, testing best practices, pytest patterns | `python-testing-best-practices.md` |
| **advanced testing**, mocking, property-based testing | `advanced-testing.md` |

---

## Testing Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Python Testing Best Practices](python-testing-best-practices.md) | Pytest patterns, testing behavior vs structure | pytest, testing best practices |
| [Advanced Testing](advanced-testing.md) | Mocking strategies and property-based testing | mocking, property-based testing |

---

## Quick Reference

| Need | Load |
|------|------|
| Pytest patterns | `python-testing-best-practices.md` |
| Advanced testing | `advanced-testing.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Generic**: See `references/rules/common/generic/testing/core-principles.md` for universal testing principles

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
