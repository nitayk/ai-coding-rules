# Go Performance Patterns Index

**Purpose**: Router for Go performance patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **profiling**, optimization, escape analysis, memory allocation, PGO | `profiling-and-optimization.md` |

---

## Performance Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Profiling and Optimization](profiling-and-optimization.md) | Profiling, escape analysis, memory allocation, PGO | profiling, optimization, escape analysis, PGO |

---

## Quick Reference

| Need | Load |
|------|------|
| Performance | `profiling-and-optimization.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Generic**: See `references/rules/common/generic/performance/core-principles.md` for universal performance principles

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
