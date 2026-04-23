---
name: scala-testing
description: "Use when writing Scala tests (*Test.scala, *Spec.scala), reviewing test code, user asks about testing patterns, or code review involves test files. Do NOT use when non-Scala tests, quick syntax fixes, or when user explicitly requests different testing approach."
---

# Scala Testing

## Core Principles

### Pure Testing

Tests must be pure functions: no side effects in setup, no mutable shared state, deterministic outcomes.

### Mock Setup

Avoid mutable mock state. Use pure mock factories that accept behavior functions.

### Property-Based Testing

Use ScalaCheck `forAll` for property testing instead of example-based tests only.

## Patterns

**Structure**: Pure test data → Fresh SUT factory per test → Isolated tests with behavior-focused names.

**Async**: Use `AsyncFlatSpec` with `map` for Future results, not blocking.

## Tools Required

- Read: For existing test files
- Grep: For finding test patterns

## Success Criteria

Before completing, verify:
- Tests are pure (no side effects)
- No mutable shared state
- Clear test names (behavior-focused)
- Proper use of matchers
- Async tests handled correctly

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
