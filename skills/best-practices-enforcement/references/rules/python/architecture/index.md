# Python Architecture Patterns Index

**Purpose**: Router for Python architecture patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **architecture**, design patterns, project structure, dependency injection | `design-patterns.md` |

---

## Architecture Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Design Patterns](design-patterns.md) | Project structure, dependency injection, API design | architecture, design patterns, dependency injection |

---

## Quick Reference

| Need | Load |
|------|------|
| Architecture patterns | `design-patterns.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Generic**: See `references/rules/common/generic/architecture/core-principles.md` for universal architecture principles

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
