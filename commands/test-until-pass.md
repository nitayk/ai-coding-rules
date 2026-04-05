# Test Until Pass

Run tests, fix failures, and repeat until all tests pass.

## Usage

```
/test-until-pass [test-pattern]
```

## What it does

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
