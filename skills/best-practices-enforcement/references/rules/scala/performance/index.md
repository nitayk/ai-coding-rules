# Scala Performance Patterns Index

**Purpose**: Router for Scala performance patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **collections**, memory, collection performance, memory optimization | `collections-and-memory.md` |
| **FP performance**, functional optimization, performance-conscious FP | `performance-conscious-fp.md` |
| **future optimization**, async performance, scala future management | `scala-efficient-future-management.md` |
| **akka**, actor, akka actor, tell ask, actor patterns | `akka-actor-patterns.md` |

---

## Performance Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Collections and Memory](collections-and-memory.md) | Collection performance and memory management | collections, memory, performance |
| [Performance-Conscious FP](performance-conscious-fp.md) | Functional programming optimization patterns | FP performance, functional optimization |
| [Scala Efficient Future Management](scala-efficient-future-management.md) | Async optimization with Future | future optimization, async performance |
| [Akka Actor Patterns](akka-actor-patterns.md) | Actor best practices, tell vs ask, Future integration | akka, actor |

---

## Quick Reference

| Need | Load |
|------|------|
| Collection performance | `collections-and-memory.md` |
| FP optimization | `performance-conscious-fp.md` |
| Future optimization | `scala-efficient-future-management.md` |
| Akka actors | `akka-actor-patterns.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Meta**: See `../meta/correctness-first.md` - optimize only after correctness
- **Generic**: See `references/rules/common/generic/performance/core-principles.md` for universal performance principles

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
