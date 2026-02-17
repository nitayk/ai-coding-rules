---
paths: "**/*.scala"
---

# Scala Core Patterns

## Triggers

**APPLY WHEN**: Writing or editing Scala code.
**SKIP WHEN**: Reading-only or config files.

## Core Directive

Use Option/Either for errors. Prefer immutability. Use sealed traits for ADTs. Never use null or return.

## Team-Specific Patterns

### Error Handling

**Preferred:** `Option` for potentially missing values. `Either` for business logic errors. Sealed traits for explicit error cases.
**Avoid:** `null`. Exceptions for flow control. `Option` when `None` could mean different things (use domain types).

### Option Blindness

**Avoid:** `def processPayment(amount: Double): Option[Receipt]` (what does None mean?)
**Preferred:** Sealed trait with `PaymentSuccess`, `InsufficientFunds`, `NetworkError`

### Pattern Matching

**Preferred:** Exhaustive match on sealed traits. Guards for complex conditions. Extract values in patterns.
**Avoid:** Non-exhaustive match. `value match { case true => ... case false => ... }` (use if/else for booleans).

### Immutability

**Preferred:** `val`, immutable collections, `copy` for case classes, pass state explicitly.
**Avoid:** `var`, mutable collections, mutating case class fields.

### Pure vs Effectful

**Preferred:** Separate pure calculation from effects. Use for-comprehensions to chain.
**Avoid:** Mixing pure logic inside effect blocks.

### Type Safety

**Preferred:** Sealed traits for ADTs. Value classes to avoid primitive obsession. Enumeratum for enums.
**Avoid:** Stringly-typed enums. Primitive obsession (all String parameters).

## Anti-Patterns

- Do not use `return`; use expression-based control flow
- Do not overuse implicit conversions; prefer explicit or extension methods
- Do not use nested loops; use `flatMap`/`map`/`for`
