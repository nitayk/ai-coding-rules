---
name: git-workflow
description: "Use when managing complex migrations, large refactorings, multi-day development tasks, or ensuring commit hygiene. Do NOT use for simple single-file changes or quick fixes."
last-reviewed: 2026-06-02
---
# Git Workflow for Complex Tasks

Every commit = Compiles + Tests Pass + Logical Task Complete. Commit stable states, not work in progress.

## When to Use This Skill

**APPLY WHEN:**
- Managing complex migrations
- Large refactorings with many changes
- Multi-day development tasks
- Ensuring commit hygiene during complex work

**DO NOT USE WHEN:**
- Simple single-file changes
- Quick fixes (standard commit is fine)
- Not making code changes

## Core Directive

Every commit = Compiles + Tests Pass + Logical Task Complete. A commit represents a STABLE state.

## Commit Message Format

```
type(scope): short description

Longer explanation if needed.

- Bullet points for details
```

**Types**: feat, fix, refactor, migrate, test, docs

## Workflow Steps

### 1. Start Branch

```bash
git checkout -b type/description
```

### 2. Work on Task

```bash
# Make changes
# Build and test using the repo's command:
#   sbt test (Scala), go test ./... (Go), pytest (Python), etc.
<build-and-test-command>

# Commit stable state
git add .
git commit -m "type(scope): what was accomplished"
```

### 3. Continue Working

Repeat: change, compile, test, commit. Each commit = stable state.

### 4. Push Regularly

```bash
git push origin your-branch
```

### 5. Create PR

```bash
gh pr create --title "Description" --body "Details"
```

## Common Patterns

**Incremental Migration**: One commit per module (copy, dependencies, wire integration)

**Refactoring in Steps**: Extract method, consolidate, remove dead code - one commit each

**TDD**: Add failing test, implement feature, refactor - one commit each

## Anti-Patterns

- **WIP commits**: Use descriptive messages, not "WIP"
- **Giant commits**: Split into logical units
- **Committing broken code**: Always compile and test first
- **Vague messages**: "fix stuff" - use specific descriptions

## Troubleshooting

**Commit does not compile**: `git reset --soft HEAD~1`, fix, commit again

**Tests failing**: `git reset --soft HEAD~1`, fix tests, commit when passing

**Split large commit**: `git reset HEAD~1`, stage and commit in parts

## Output

- Multiple commits, one per stable state
- Clean history with logical progression
- No WIP commits in final PR

## Related Skills

- Service Migration - Applies this workflow
- Service Refactoring - Applies this workflow
- **Same change across many repos** (bulk PRs, `progress.md`, orchestration repo) → `/mass-repo-orchestration`

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
