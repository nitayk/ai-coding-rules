---
name: test-until-pass
description: "Use when tests are failing and user wants them fixed. Run tests, analyze failures, fix, repeat until pass. Make sure to use when user says: fix the tests, test until pass, /test-until-pass, or tests are failing and need fixing."
disable-model-invocation: true
---
# Test Until Pass

Run tests, fix failures, and repeat until all tests pass.

## When to Use This Skill

**APPLY WHEN:**
- Tests are failing and user wants them fixed
- User says "fix the tests", "test until pass", "/test-until-pass"

**SKIP WHEN:**
- User wants to run tests once (no fix loop)
- Flaky tests (fix flakiness first)

## Core Directive

**Run tests → If fail, analyze and fix → Repeat until pass or max iterations.** Default max: 5 iterations.

## Usage

```
/test-until-pass [test-pattern]
```

## Process

1. Runs the test suite (or specific test pattern)
2. If tests fail:
   - Analyzes the failure output
   - Identifies the root cause
   - Implements a fix
   - Runs tests again
3. Repeats until all tests pass or max iterations reached
4. Reports final status and any remaining issues

## Examples

```
/test-until-pass
```

Run all tests and fix until they pass.

```
/test-until-pass auth
```

Run only authentication-related tests and fix until they pass.

## Configuration

Set max iterations to prevent infinite loops:
- Default: 5 iterations
- Override: Set `TEST_MAX_ITERATIONS` environment variable

## Best Practices

- Use with TDD workflow (write tests first)
- Set reasonable iteration limits
- Review all changes after completion
- Don't use for flaky tests (fix flakiness first)
