# Swift Language Patterns Index

**Purpose**: Router for Swift language patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **swift style**, swift formatting, swift naming, style guide | `style-guide.md` |
| **swift concurrency**, swift async await, actors, @MainActor, structured concurrency | `swift-concurrency-patterns.md` |
| **swift 6 migration**, strict concurrency, Sendable, language mode 6, @preconcurrency | `strict-concurrency-migration.md` |
| **approachable concurrency**, main-actor-default, Swift 6.2, defaultIsolation | `approachable-concurrency.md` |
| **swift error**, error handling, Result, throws, do-try-catch | `error-handling-patterns.md` |
| **swift value types**, struct vs class, value semantics | `value-types-patterns.md` |
| **swift protocol**, protocol-oriented, POP, protocol extension | `protocol-oriented-patterns.md` |

---

## Language Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Style Guide](style-guide.md) | Swift naming conventions, formatting, code organization | swift style, swift formatting, swift naming |
| [Swift Concurrency Patterns](swift-concurrency-patterns.md) | Async/await, actors, @MainActor, structured concurrency | swift concurrency, swift async await, actors |
| [Strict-Concurrency Migration](strict-concurrency-migration.md) | Swift 6 language-mode mechanics, Sendable, @preconcurrency | swift 6, strict concurrency, Sendable |
| [Approachable Concurrency](approachable-concurrency.md) | Swift 6.2 main-actor-default and NonisolatedNonsendingByDefault | approachable concurrency, main-actor-default |
| [Error Handling Patterns](error-handling-patterns.md) | Result vs throws, do-try-catch, custom errors | swift error, Result, throws |
| [Value Types Patterns](value-types-patterns.md) | Struct vs class, when to use each | swift value types, struct, class |
| [Protocol-Oriented Patterns](protocol-oriented-patterns.md) | Protocols, extensions, composition | swift protocol, POP |

---

## Quick Reference

| Need | Load |
|------|------|
| Style guide | `style-guide.md` |
| Concurrency | `swift-concurrency-patterns.md` |
| Error handling | `error-handling-patterns.md` |
| Value types | `value-types-patterns.md` |
| Protocols | `protocol-oriented-patterns.md` |

---

## Related Resources

- **iOS**: See `../ios/index.md` for iOS patterns

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
