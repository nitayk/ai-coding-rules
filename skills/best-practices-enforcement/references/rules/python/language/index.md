# Python Language Patterns Index

**Purpose**: Router for Python language patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **type hints**, type annotations, mypy, pyright, static type checking | `type-annotations-everywhere.md` |
| **python core patterns**, mutable defaults, bare except, core patterns | `python-core-patterns.md` |
| **error handling**, exceptions, try except, error patterns | `error-handling-patterns.md` |
| **pythonic**, comprehensions, dataclasses, EAFP, idiomatic python | `pythonic-patterns.md` |
| **async**, await, asyncio, async patterns, async await | `async-patterns.md` |
| **advanced python**, decorators, context managers, advanced features | `advanced-features.md` |

---

## Language Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Type Annotations Everywhere](type-annotations-everywhere.md) | Use type annotations for static type checking | type hints, type annotations, mypy, pyright |
| [Python Core Patterns](python-core-patterns.md) | Type hints, mutable defaults, bare except, core patterns | python core patterns, mutable defaults, bare except |
| [Error Handling Patterns](error-handling-patterns.md) | Exceptions, try/except, context managers | error handling, exceptions, try except |
| [Pythonic Patterns](pythonic-patterns.md) | Idiomatic Python: comprehensions, dataclasses, EAFP | pythonic, comprehensions, dataclasses |
| [Async Patterns](async-patterns.md) | Async/await best practices, structured concurrency | async, await, asyncio, async patterns |
| [Advanced Features](advanced-features.md) | Type hints, decorators, context managers | advanced python, decorators, context managers |

---

## Quick Reference

| Need | Load |
|------|------|
| Type hints | `type-annotations-everywhere.md` |
| Error handling | `error-handling-patterns.md` |
| Pythonic code | `pythonic-patterns.md` |
| Async/await | `async-patterns.md` |
| Advanced features | `advanced-features.md` |

---

## Related Resources

- **Testing**: See `../testing/index.md` for testing patterns
- **Performance**: See `../performance/index.md` for performance patterns
- **Meta**: See `../meta/pep8-style-guide.md` for PEP 8 style guide
- **Security**: See `../meta/python-security-patterns.md` for secrets, injection prevention
- **Production**: See `../meta/python-production-patterns.md` for deployment, tooling

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
