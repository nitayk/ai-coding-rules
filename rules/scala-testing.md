---
paths:
  - "**/test/**/*.scala"
  - "**/*Test.scala"
  - "**/*Spec.scala"
---

# Scala Testing Patterns

## Triggers

**APPLY WHEN**: Writing or editing Scala tests.
**SKIP WHEN**: Production code only.

## Core Directive

Test behavior, not implementation. Use descriptive names. Keep tests independent. Prefer test doubles over mocks when simple.

## Team-Specific Patterns

### Test Structure

**Preferred:** ScalaTest Matchers DSL. Behavior-focused names: "calculateDiscount should apply 10% discount for silver members"
**Avoid:** "test1", "testCalculateDiscount" (implementation-focused)

### Async Testing

**Preferred:** ScalaTest AsyncFlatSpec or ZIO Test. Use `eventually` for timing.
**Avoid:** `Thread.sleep` in tests.

### Mocking

**Preferred:** Stub/fake when simple. Mockito when needed. Verify behavior, not internal calls.
**Avoid:** Mocking everything. Testing private methods via reflection. Testing implementation details (e.g., verify internal method calls).

### Test Independence

**Preferred:** Each test sets up its own data. No shared mutable state.
**Avoid:** Tests depending on execution order. Shared `var` across tests.

### Error Handling in Tests

**Preferred:** `assertThrows[ArithmeticException] { divide(10, 0) }`
**Avoid:** try/catch that swallows exceptions.

### Table-Driven Tests

Use `TableDrivenPropertyChecks` for multiple similar cases. Use ScalaCheck for property-based tests.

## Coverage Guidelines

- 80%+ for business logic. 100% for critical paths (payments, security, data loss)
- Focus on meaningful tests, not coverage numbers
- Test edge cases and error conditions
