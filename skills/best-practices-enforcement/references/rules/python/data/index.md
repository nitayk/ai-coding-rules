# Python Data Handling Patterns Index

**Purpose**: Router for Python data patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **pandas**, pydantic, data handling, data processing | `data-handling.md` |

---

## Data Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Data Handling](data-handling.md) | Pandas optimizations and Pydantic validation patterns | pandas, pydantic, data handling |

---

## Quick Reference

| Need | Load |
|------|------|
| Pandas/Pydantic | `data-handling.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Performance**: See `../performance/index.md` for performance optimization

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
