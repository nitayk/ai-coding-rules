# Go Architecture Patterns Index

**Purpose**: Router for Go architecture patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **project structure**, directory organization, go project layout | `project-structure.md` |

---

## Architecture Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Project Structure](project-structure.md) | Standard Go project layout and organization | project structure, directory organization |

---

## Quick Reference

| Need | Load |
|------|------|
| Project structure | `project-structure.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Generic**: See `references/rules/common/generic/architecture/core-principles.md` for universal architecture principles

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
