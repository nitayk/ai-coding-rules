# Go Language Patterns Index

**Purpose**: Router for Go language patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **error handling**, errors, error wrapping, custom errors | `error-handling-patterns.md` |
| **idiomatic errors**, guard clauses, explicit checks, error wrapping | `idiomatic-error-handling.md` |
| **concurrency**, goroutines, channels, worker pools, errgroup | `concurrency-patterns.md` |
| **mutex**, locking, sync.Mutex, RWMutex, deadlock | `mutex-and-locking.md` |
| **context**, cancellation, deadlines, context propagation | `context-patterns.md` |
| **interfaces**, small interfaces, interface design | `small-interfaces.md` |

---

## Language Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Error Handling Patterns](error-handling-patterns.md) | Error creation, wrapping, custom errors | error handling, errors, error wrapping |
| [Idiomatic Error Handling](idiomatic-error-handling.md) | Explicit checks, guard clauses, error wrapping | idiomatic errors, guard clauses |
| [Concurrency Patterns](concurrency-patterns.md) | Goroutines, channels, worker pools, errgroup | concurrency, goroutines, channels |
| [Mutex and Locking](mutex-and-locking.md) | sync.Mutex, RWMutex, deadlock prevention | mutex, locking, RWMutex |
| [Context Patterns](context-patterns.md) | Cancellation, deadlines, context propagation | context, cancellation, deadlines |
| [Small Interfaces](small-interfaces.md) | Design small, focused interfaces | interfaces, interface design |

---

## Quick Reference

| Need | Load |
|------|------|
| Error handling | `error-handling-patterns.md`, `idiomatic-error-handling.md` |
| Concurrency | `concurrency-patterns.md` |
| Mutex/locking | `mutex-and-locking.md` |
| Context | `context-patterns.md` |
| Interfaces | `small-interfaces.md` |

---

## Related Resources

- **Architecture**: See `../architecture/index.md` for architectural patterns
- **Testing**: See `../testing/index.md` for testing patterns
- **Performance**: See `../performance/index.md` for performance patterns

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
