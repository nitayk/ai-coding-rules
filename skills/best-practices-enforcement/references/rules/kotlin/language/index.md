# Kotlin Language Patterns Index

**Purpose**: Router for Kotlin language patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword -> File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **kotlin style**, kotlin formatting, kotlin naming, style guide | `style-guide.md` |
| **kotlin coroutines**, coroutines, structured concurrency, dispatchers, flow | `coroutines-patterns.md` |
| **kotlin sealed**, sealed classes, sealed interfaces, exhaustive when | `sealed-classes-patterns.md` |
| **scope functions**, let apply run with also | `scope-functions.md` |
| **extension functions**, kotlin extensions | `extension-functions.md` |
| **result type**, runCatching, kotlin error handling | `result-error-handling.md` |
| **kotlin collections**, mutable immutable, sequences | `collections-patterns.md` |
| **kotlin dsl**, type-safe builder, dsl marker, lambda with receiver | `kotlin-dsl-patterns.md` |

---

## Language Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Style Guide](style-guide.md) | Kotlin naming conventions, formatting, code organization | kotlin style, kotlin formatting, kotlin naming |
| [Coroutines Patterns](coroutines-patterns.md) | Structured concurrency, dispatchers, error handling, Flow | kotlin coroutines, coroutines, structured concurrency |
| [Sealed Classes Patterns](sealed-classes-patterns.md) | Closed hierarchies, exhaustive when expressions | kotlin sealed, sealed classes, sealed interfaces |
| [Scope Functions](scope-functions.md) | let, apply, run, with, also - when to use each | scope functions, let apply run |
| [Extension Functions](extension-functions.md) | Extension function best practices | extension functions, kotlin extensions |
| [Result Error Handling](result-error-handling.md) | Result type, runCatching, fold | result type, runCatching |
| [Collections Patterns](collections-patterns.md) | Mutable vs immutable, sequences | kotlin collections, sequences |
| [Kotlin DSL Patterns](kotlin-dsl-patterns.md) | Type-safe builders, @DslMarker | kotlin dsl, type-safe builder |

---

## Quick Reference

| Need | Load |
|------|------|
| Style guide | `style-guide.md` |
| Coroutines | `coroutines-patterns.md` |
| Sealed classes | `sealed-classes-patterns.md` |
| Scope functions | `scope-functions.md` |
| Extension functions | `extension-functions.md` |
| Result/error handling | `result-error-handling.md` |
| Collections | `collections-patterns.md` |
| DSL / type-safe builders | `kotlin-dsl-patterns.md` |

---

## Related Resources

- **Android**: See `../android/index.md` for Android patterns
- **Testing**: See `../testing/index.md` for Kotlin testing patterns
- **Generic Testing**: `references/rules/common/generic/testing/core-principles.md`

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
