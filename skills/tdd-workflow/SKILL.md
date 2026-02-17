---
name: tdd-workflow
description: "Guides Test-Driven Development workflow following Red-Green-Refactor cycle. Write failing tests first (Red), implement minimal code to pass tests (Green), then refactor for quality while maintaining passing tests (Refactor). Ensures test coverage from the start and provides safety net for refactoring. Use when starting new features, adding functionality to existing code, refactoring with safety net, or ensuring test coverage. Produces well-tested code with comprehensive test suite."
version: "1.0.0"
last_updated: "2026-01-25"
tags: ["testing", "tdd", "workflow", "universal"]
---
# Test-Driven Development Workflow

Test-Driven Development (TDD) workflow following the Red-Green-Refactor cycle.

**CRITICAL**: Write tests FIRST, then implement. Tests drive design and ensure correctness.

## What is Test-Driven Development?

Test-Driven Development (TDD) is a software development methodology where you write tests before writing implementation code. It follows a three-phase cycle: Red (write failing test), Green (make test pass with minimal code), Refactor (improve code while keeping tests green).

**Core Concept**: Tests drive design and ensure correctness:
- ✅ **Red** - Write failing test that describes desired behavior
- ✅ **Green** - Write minimal code to make test pass
- ✅ **Refactor** - Improve code quality while keeping tests green

**Benefits:**
- Test coverage from the start
- Tests serve as documentation
- Safety net for refactoring
- Design driven by requirements
- Confidence in code correctness

## Why This Matters

### The Problem: Tests Written After Implementation

**Without TDD:**
- Tests written after code (may miss edge cases)
- Code written without clear requirements
- Refactoring is risky (no safety net)
- Low test coverage
- Tests test implementation, not behavior

**Example of problems:**
```
# Write implementation first
def calculate_total(price, tax_rate):
    return price * (1 + tax_rate)

# Then write test (if remembered)
def test_calculate_total():
    assert calculate_total(100, 0.1) == 110
# Misses edge cases: negative prices, zero tax, etc.
```

### The Solution: Tests Drive Development

**With TDD:**
- ✅ Requirements clarified through tests
- ✅ Edge cases considered upfront
- ✅ Refactoring is safe (tests catch breaks)
- ✅ High test coverage
- ✅ Tests focus on behavior, not implementation

**Example of success:**
```
# Write test first (Red)
def test_calculate_total_with_negative_price():
    with pytest.raises(ValueError):
        calculate_total(-100, 0.1)

# Implement to pass (Green)
def calculate_total(price, tax_rate):
    if price < 0:
        raise ValueError("Price cannot be negative")
    return price * (1 + tax_rate)

# Refactor for clarity (Refactor)
def calculate_total(price: float, tax_rate: float) -> float:
    """Calculate total price with tax."""
    if price < 0:
        raise ValueError("Price cannot be negative")
    return price * (1 + tax_rate)
```

## When to Use This Skill

**APPLY WHEN:**
- Starting new features or functionality
- Adding methods/functions to existing code
- Refactoring with safety net
- Ensuring test coverage
- Learning codebase through tests
- Building confidence in changes

**SKIP WHEN:**
- Quick bug fixes (fix first, test after)
- Purely cosmetic changes (formatting, comments)
- Documentation-only changes
- Configuration changes without logic

## Core Directive

**Red → Green → Refactor**: Write failing test → Make it pass → Improve code.

## The TDD Cycle

### 1. Red: Write Failing Test

**Write a test that describes desired behavior:**

```scala
// Example: Scala/ScalaTest
test("should calculate total price with tax") {
  val calculator = new PriceCalculator(taxRate = 0.1)
  calculator.calculateTotal(100.0) shouldBe 110.0
}
```

**Key principles:**
- Test describes WHAT, not HOW
- Test should fail for the right reason (missing functionality, not syntax error)
- One behavior per test
- Use descriptive test names

### 2. Green: Make Test Pass

**Write minimal code to pass the test:**

```scala
// Minimal implementation
class PriceCalculator(taxRate: Double) {
  def calculateTotal(price: Double): Double = {
    price * (1 + taxRate)  // Just enough to pass
  }
}
```

**Key principles:**
- Write ONLY enough code to pass
- Don't optimize yet
- Don't add features not tested
- Commit when test passes

### 3. Refactor: Improve Code

**Improve code while keeping tests green:**

```scala
// Refactored implementation
class PriceCalculator(taxRate: Double) {
  def calculateTotal(price: Double): Double = {
    require(price >= 0, "Price must be non-negative")
    price + calculateTax(price)
  }
  
  private def calculateTax(price: Double): Double = {
    price * taxRate
  }
}
```

**Key principles:**
- Tests must stay green
- Improve readability, structure, performance
- Remove duplication
- Extract methods/classes as needed

## Workflow Steps

### Step 1: Understand Requirements

**Before writing tests:**
1. Read existing code to understand patterns
2. Check similar features for test structure
3. Identify edge cases and boundaries
4. Plan test cases (happy path, edge cases, errors)

### Step 2: Write First Test

**Create test file (if needed) or add to existing:**

```bash
# Example: Scala project structure
src/test/scala/com/example/PriceCalculatorTest.scala
```

**Write failing test:**
- Use existing test framework conventions
- Follow naming patterns (`should_do_something` or `test_does_something`)
- Test one behavior
- Use descriptive assertions

### Step 3: Run Test (Verify Red)

**Run test to confirm it fails:**

```bash
sbt test
# or
npm test
# or
pytest
```

**Expected:** Test fails with clear error (missing method, wrong return value, etc.)

### Step 4: Implement Minimal Code

**Write just enough to pass:**

- Don't over-engineer
- Don't add features not tested
- Focus on making test green

### Step 5: Run Test (Verify Green)

**Run test again:**

```bash
sbt test
```

**Expected:** Test passes

**Commit when green:**
```bash
git add .
git commit -m "test: add price calculation with tax"
```

### Step 6: Refactor (Keep Green)

**Improve code quality:**
- Extract methods
- Rename for clarity
- Remove duplication
- Add error handling (with tests)

**After each refactor:**
- Run tests (must stay green)
- Commit if significant improvement

### Step 7: Repeat Cycle

**For next behavior:**
1. Write next failing test
2. Make it pass
3. Refactor
4. Continue until feature complete

## Test Structure

### Test Organization

**Group related tests:**

```scala
class PriceCalculatorTest extends AnyFlatSpec {
  
  "calculateTotal" should "add tax to base price" in {
    // test
  }
  
  it should "handle zero price" in {
    // test
  }
  
  it should "reject negative prices" in {
    // test
  }
}
```

### Test Categories

**Write tests for:**
- **Happy path**: Normal operation
- **Edge cases**: Boundaries, empty inputs, nulls
- **Error cases**: Invalid inputs, exceptions
- **Integration**: Multiple components together

## Best Practices

### Test Quality

**Good tests:**
- **Fast**: Run in milliseconds
- **Independent**: No test depends on another
- **Repeatable**: Same result every time
- **Self-validating**: Clear pass/fail
- **Timely**: Written before implementation

**Bad tests:**
- Slow (database, network calls)
- Dependent on execution order
- Non-deterministic (random, time-dependent)
- Unclear what they test
- Written after implementation

### Test Naming

**Use descriptive names:**

```scala
// Good
test("should calculate total with 10% tax rate")

// Bad
test("test1")
test("calculate")
```

### Test Size

**Keep tests focused:**
- One behavior per test
- 3-10 lines of test code
- Clear setup → act → assert

### Test Coverage

**Aim for:**
- 80%+ code coverage
- 100% critical path coverage
- All public APIs tested
- Edge cases covered

## Language-Specific Patterns

### Scala (ScalaTest)

```scala
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class CalculatorSpec extends AnyFlatSpec with Matchers {
  "Calculator" should "add two numbers" in {
    Calculator.add(2, 3) shouldBe 5
  }
}
```

### Python (pytest)

```python
import pytest

def test_calculate_total():
    calculator = PriceCalculator(tax_rate=0.1)
    assert calculator.calculate_total(100.0) == 110.0
```

### JavaScript/TypeScript (Jest/Vitest)

```typescript
describe('PriceCalculator', () => {
  it('should calculate total with tax', () => {
    const calculator = new PriceCalculator(0.1);
    expect(calculator.calculateTotal(100)).toBe(110);
  });
});
```

## Integration with Other Skills

**Use with:**
- `/git-workflow` - Commit after each green test
- `/best-practices-enforcement` - Ensure test quality
- `/service-refactoring` - Refactor with test safety net

## Common Pitfalls

### Writing Too Much Code

**Problem:** Implementing full feature before tests pass

**Solution:** One test → minimal code → refactor → next test

### Skipping Refactor Phase

**Problem:** Code works but messy

**Solution:** Always refactor after green, commit clean code

### Testing Implementation Details

**Problem:** Tests break when refactoring

**Solution:** Test behavior, not implementation

### Not Running Tests Often

**Problem:** Many failures at once

**Solution:** Run tests after each small change

## Success Criteria

- **Tests written first** (before implementation)
- **Red-Green-Refactor cycle followed**
- **All tests pass** before moving on
- **Code refactored** after tests pass
- **Test coverage** meets standards
- **Tests are fast and independent**

## Output

**This skill produces:**
- Test files written before implementation
- Implementation code that passes tests
- Refactored, clean code
- High test coverage
- Confidence in changes

## Remember

> "Red, Green, Refactor - the heartbeat of TDD"

> "Tests are specifications written in code"

> "If it's not tested, it's broken"
