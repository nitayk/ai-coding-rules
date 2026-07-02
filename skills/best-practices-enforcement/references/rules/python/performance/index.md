# Python Performance Patterns Index

**Purpose**: Router for Python performance patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **profiling**, optimization, memory management, vectorization | `profiling-and-optimization.md` |
| **concurrency**, async performance, concurrency optimization | `concurrency-and-optimization.md` |

---

## Performance Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Profiling and Optimization](profiling-and-optimization.md) | Profiling tools, memory management, vectorization | profiling, optimization, memory management |
| [Concurrency and Optimization](concurrency-and-optimization.md) | Concurrency patterns and performance optimization | concurrency, async performance |

---

## Quick Reference

| Need | Load |
|------|------|
| Profiling | `profiling-and-optimization.md` |
| Concurrency | `concurrency-and-optimization.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for async patterns
- **Generic**: See `references/rules/common/generic/performance/core-principles.md` for universal performance principles

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
