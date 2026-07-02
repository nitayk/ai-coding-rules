# Scala Meta Patterns Index

**Purpose**: Router for Scala meta patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **correctness first**, optimization, make it correct | `correctness-first.md` |
| **functional programming**, FP principles, functional principles | `functional-programming-principles.md` |
| **scala style**, code style, scala code style | `scala-code-style.md` |
| **code smells**, anti-patterns, scala code smells | `scala-code-smells.md` |
| **comments**, meaningful comments, documentation | `meaningful-comments-only.md` |
| **monitoring**, observability, logging, scala observability | `monitoring-and-observability-patterns.md` |
| **production**, production readiness, deployment, reliability | `scala-production-patterns.md` |
| **rules format**, documentation format, scala rules format | `scala-rules-format-guide.md` |

---

## Meta Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Correctness First](correctness-first.md) | Make it correct, then optimize | correctness first, optimization |
| [Functional Programming Principles](functional-programming-principles.md) | Core FP principles for Scala | functional programming, FP principles |
| [Scala Code Style](scala-code-style.md) | Scala coding style guidelines | scala style, code style |
| [Scala Code Smells](scala-code-smells.md) | Common Scala code smells and anti-patterns | code smells, anti-patterns |
| [Meaningful Comments Only](meaningful-comments-only.md) | When and how to write comments | comments, documentation |
| [Monitoring and Observability Patterns](monitoring-and-observability-patterns.md) | Observability patterns for Scala services | monitoring, observability, logging |
| [Scala Production Patterns](scala-production-patterns.md) | Production readiness, deployment, reliability | production, deployment, reliability |
| [Scala Rules Format Guide](scala-rules-format-guide.md) | Format guide for Scala rule files | rules format, documentation |

---

## Quick Reference

| Need | Load |
|------|------|
| Code style | `scala-code-style.md` |
| Correctness principles | `correctness-first.md` |
| Functional programming | `functional-programming-principles.md` |
| Code smells | `scala-code-smells.md` |
| Observability | `monitoring-and-observability-patterns.md` |
| Production readiness | `scala-production-patterns.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Architecture**: See `../architecture/index.md` for architectural patterns
- **Generic**: See `references/rules/common/generic/code-quality/core-principles.md` for universal principles

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
