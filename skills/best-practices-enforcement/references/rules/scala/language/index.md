# Scala Language Patterns Index

**Purpose**: Router for Scala language patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **error handling**, option, either, try, error patterns | `error-handling-patterns.md` |
| **future error**, async errors, future error handling | `future-error-handling-conventions.md` |
| **compiler friendly**, type safety, compiler errors, stop lying to compiler | `compiler-friendly-types.md` |
| **referential transparency**, pure functions, functional programming | `referential-transparency.md` |
| **sealed traits**, illegal states, make illegal states unrepresentable, type safety | `make-illegal-states-unrepresentable.md` |
| **option blindness**, domain types, avoid option | `avoid-option-blindness.md` |
| **method overloading**, avoid overloading, explicit naming | `avoid-overloading.md` |
| **pattern matching**, sealed types, exhaustive when | `pattern-matching-best-practices.md` |
| **functional composition**, HOF, higher-order functions | `functional-composition-and-hof.md` |
| **extension methods**, implicit conversions, implicit extensions | `implicit-extension-methods.md` |
| **validation**, safe operations, safe validation | `validation-and-safe-operations.md` |
| **case classes**, tuples, prefer case classes | `prefer-case-classes-over-tuples.md` |
| **iterators**, iterator safety, side effects | `iterator-safety.md` |
| **lazy evaluation**, lazy val, lazy evaluation patterns | `lazy-evaluation-and-productivity.md` |
| **scala best practices**, scala patterns | `scala-more-best-practices.md` |
| **scala core patterns**, option either, immutability, sealed traits, core patterns | `scala-core-patterns.md` |
| **visibility**, access modifiers, private, scala visibility | `scala-visibility-guidelines.md` |
| **anonymous functions**, SAM types, avoid anonymous | `avoid-anonymous-function-dependencies.md` |
| **cats**, cats effect, zio, io, effect system, ZLayer, Resource | `cats-zio-effect-patterns.md` |

---

## Language Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Compiler-Friendly Types](compiler-friendly-types.md) | Core principle: stop lying to compiler | compiler friendly, type safety, compiler errors |
| [Error Handling Patterns](error-handling-patterns.md) | Option, Either, Try patterns | error handling, option, either, try |
| [Future Error Handling Conventions](future-error-handling-conventions.md) | Async error handling with Future[Either[E, A]] | future error handling, async errors |
| [Referential Transparency](referential-transparency.md) | Pure functional programming principles | referential transparency, pure functions |
| [Make Illegal States Unrepresentable](make-illegal-states-unrepresentable.md) | Type-safe invariants with sealed traits | sealed traits, illegal states, type safety |
| [Avoid Option Blindness](avoid-option-blindness.md) | When Option loses domain semantics | option blindness, domain types |
| [Avoid Overloading](avoid-overloading.md) | Prefer explicit naming over overloading | method overloading, explicit naming |
| [Pattern Matching Best Practices](pattern-matching-best-practices.md) | Pattern matching patterns and exhaustiveness | pattern matching, sealed types |
| [Functional Composition and HOF](functional-composition-and-hof.md) | Higher-order functions and composition | functional composition, HOF, higher-order |
| [Implicit Extension Methods](implicit-extension-methods.md) | Extension methods and implicit conversions | extension methods, implicit conversions |
| [Validation and Safe Operations](validation-and-safe-operations.md) | Safe validation patterns | validation, safe operations |
| [Prefer Case Classes Over Tuples](prefer-case-classes-over-tuples.md) | When to use case classes vs tuples | case classes, tuples |
| [Iterator Safety](iterator-safety.md) | Iterator safety and side effects | iterators, side effects |
| [Lazy Evaluation and Productivity](lazy-evaluation-and-productivity.md) | Lazy evaluation patterns | lazy evaluation, lazy val |
| [Scala More Best Practices](scala-more-best-practices.md) | Additional Scala best practices | scala best practices |
| [Scala Core Patterns](scala-core-patterns.md) | Option/Either, immutability, sealed traits, core patterns | scala core patterns, option either, immutability |
| [Scala Visibility Guidelines](scala-visibility-guidelines.md) | Access modifiers and visibility | visibility, access modifiers, private |
| [Avoid Anonymous Function Dependencies](avoid-anonymous-function-dependencies.md) | Prefer named traits over anonymous functions | anonymous functions, SAM types |
| [Cats and ZIO Effect Patterns](cats-zio-effect-patterns.md) | Cats Effect IO, ZIO, ZLayer, Resource | cats, zio, cats effect, effect system |

---

## Quick Reference

| Need | Load |
|------|------|
| Error handling | `error-handling-patterns.md` |
| Type safety | `compiler-friendly-types.md`, `make-illegal-states-unrepresentable.md` |
| Functional programming | `referential-transparency.md`, `functional-composition-and-hof.md` |
| Pattern matching | `pattern-matching-best-practices.md` |
| Async errors | `future-error-handling-conventions.md` |
| Cats/ZIO effects | `cats-zio-effect-patterns.md` |

---

## Related Resources

- **Architecture**: See `../architecture/index.md` for architectural patterns
- **Data**: See `../data/index.md` for data handling patterns
- **Testing**: See `../testing/index.md` for testing patterns
- **Performance**: See `../performance/index.md` for performance patterns

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
