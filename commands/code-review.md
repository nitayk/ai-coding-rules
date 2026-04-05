---
name: code-review
description: Run a comprehensive code review of recent changes or a specific file. Use /code-review or /review.
---

# Code Review

Review code changes for quality, correctness, and best practices.

## Usage

```
/code-review
```
or
```
/review
```

## Behavior

When invoked, determine what to review:

1. **If uncommitted changes exist**: Review the current diff (`git diff` + `git diff --staged`)
2. **If on a feature branch**: Review all changes since diverging from main (`git diff main...HEAD`)
3. **If a file is specified**: Review that specific file

## What it does

1. Runs all configured linters (eslint, prettier, etc.) when available
2. Checks for common issues:
   - Unused variables/imports
   - Security vulnerabilities
   - Performance anti-patterns
   - Accessibility issues
3. Reviews test coverage
4. Checks documentation completeness
5. Summarizes what needs attention before PR

## Review Checklist

For each file changed, evaluate:

### Correctness
- Logic errors, off-by-one, null safety
- Edge cases not handled
- Race conditions or concurrency issues

### Code Quality
- SOLID principles adherence
- DRY violations (copy-paste code)
- Naming clarity and consistency
- Function length and complexity
- Style, naming, structure

### Security
- Input validation
- Secret/credential exposure
- SQL injection, XSS, CSRF risks
- Hardcoded values that should be config

### Testing
- Are changes covered by tests?
- Are edge cases tested?
- Are tests testing behavior (not implementation)?

### Architecture
- Does this fit the existing patterns?
- Are dependencies appropriate?
- Is the abstraction level right?

### Documentation
- Comments, README updates, API docs

### Accessibility (when applicable)
- ARIA labels, keyboard navigation, screen readers

## Output Format

Categorize findings as:
- **Critical**: Must fix before merge (bugs, security issues)
- **Important**: Should fix (design issues, missing tests)
- **Suggestion**: Nice to have (style, naming, minor improvements)

Present as a clear, actionable list with file:line references.
