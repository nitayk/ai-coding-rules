# Scala Testing Patterns Index

**Purpose**: Router for Scala testing patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **pure testing**, functional testing, pure test patterns | `pure-testing-patterns.md` |
| **scalatest**, scala testing, testing best practices | `scala-testing-best-practices.md` |
| **scala testing patterns**, team testing patterns, async testing, mocking | `scala-testing-patterns.md` |

---

## Testing Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Pure Testing Patterns](pure-testing-patterns.md) | Functional testing approach | pure testing, functional testing |
| [Scala Testing Best Practices](scala-testing-best-practices.md) | ScalaTest patterns and best practices | scalatest, testing best practices |
| [Scala Testing Patterns](scala-testing-patterns.md) | Team-specific patterns: Matchers, async, mocking | scala testing patterns, async testing, mocking |

---

## Quick Reference

| Need | Load |
|------|------|
| Functional testing | `pure-testing-patterns.md` |
| ScalaTest patterns | `scala-testing-best-practices.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Meta**: See `../meta/correctness-first.md` - testing for correctness
- **Generic**: See `references/rules/common/generic/testing/core-principles.md` for universal testing principles

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
