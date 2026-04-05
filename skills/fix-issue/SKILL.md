---
name: fix-issue
description: "Use when implementing a fix for a GitHub issue. Fetch issue by number, analyze, implement fix with tests. Make sure to use when user says: fix issue #123, implement fix for #456, /fix-issue, or provides a GitHub issue number to fix."
disable-model-invocation: true
---
# Fix GitHub Issue

Fetch a GitHub issue, analyze it, and implement the fix.

## When to Use This Skill

**APPLY WHEN:**
- User provides a GitHub issue number to fix
- User says "fix issue #123", "implement fix for #456", "/fix-issue"

**SKIP WHEN:**
- No issue number provided
- User wants to create a new feature (not fix issue)
- GitHub CLI (`gh`) not installed or authenticated

## Core Directive

**Fetch → Analyze → Branch → Plan → Implement (with tests) → Verify → Commit.** Always create a feature branch and write tests for the fix.

## Usage

`/fix-issue <number>` or `/fix-github-issue <number>` — where `<number>` is the GitHub issue number.

## Process

1. **Fetch issue**: Run `gh issue view <number>` to get title, body, labels, and comments
2. **Analyze**: Understand the problem described. Identify:
   - Is this a bug, feature request, or improvement?
   - What files are likely involved?
   - Are there reproduction steps?
3. **Search codebase**: Find the relevant code using the issue description as context
4. **Create branch**: `git checkout -b fix/<number>-<short-description>`
5. **Plan the fix**: Describe what you'll change and why before writing code
6. **Implement**:
   - For bugs: Write a failing test first (reproduces the bug), then fix the code
   - For features: Follow TDD — test first, then implement
7. **Verify**: Run the test suite to ensure nothing is broken
8. **Commit**: Use conventional commit format referencing the issue: `fix: description (#<number>)`
9. **Offer next steps**: Ask if the user wants to create a PR

## Rules
- Always create a feature branch — never commit directly to main
- Always write or update tests for the fix
- Reference the issue number in commit messages
- If the issue is unclear, ask for clarification before implementing
- If the fix is complex, present a plan before coding

## Best Practices
- The issue should have clear reproduction steps
- For complex issues, consider using Plan Mode first
- Always verify the fix with tests
- Link the PR back to the issue with "Fixes #123"

## Requirements

- GitHub CLI (`gh`) installed and authenticated

## Related Skills

- `/create-pr` - Create PR after fix is complete
- `/tdd-workflow` - Test-driven development patterns
