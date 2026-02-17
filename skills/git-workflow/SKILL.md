---
name: git-workflow
description: "Guides git workflow for migrations, refactorings, and complex multi-step tasks by enforcing stable state commits. Ensures every commit compiles, passes tests, and completes a logical task before committing. Produces clean git commit history with descriptive messages following conventional commit format. Use when managing complex migrations, large refactorings, multi-day development tasks, or ensuring commit hygiene. Works with service-migration and service-refactoring skills for code changes."
version: "2.0.0"
last_updated: "2026-01-25"
tags: ["git", "workflow", "commits", "best-practices"]
---
# Git Workflow for Complex Tasks

Git workflow guidelines for migrations, refactorings, and complex multi-step tasks.

**CRITICAL**: This skill guides git workflow - use with `/service-migration` or `/service-refactoring` for code changes.

## What is Clean Git Workflow?

Clean git workflow is a commit strategy that ensures every commit represents a **stable, working state** of the codebase. Instead of committing "work in progress" or large batches of changes, you commit small, logical units that compile, pass tests, and complete a single task.

**Core Concept**: Each commit should be:
- ✅ **Compilable** - Code builds without errors
- ✅ **Testable** - All tests pass
- ✅ **Complete** - A logical task is finished
- ✅ **Reviewable** - Easy to understand what changed and why

## Why This Matters

### The Problem: Messy Commit History

**Bad commit history makes:**
- Code review difficult (hard to see incremental changes)
- Debugging harder (can't bisect to find bugs)
- Rollbacks risky (can't safely revert partial work)
- Understanding changes impossible (giant commits with mixed changes)

**Example of bad history:**
```
a1b2c3d WIP: migrating service
d4e5f6g more changes
g7h8i9j fix compilation errors
i0j1k2l update tests
```

**Problems:**
- Can't review incrementally
- Don't know what each commit does
- Can't safely revert individual changes
- Tests might fail in intermediate commits

### The Solution: Stable State Commits

**Good commit history:**
```
a1b2c3d migrate(iab-gateway): copy handlers from source
d4e5f6g migrate(iab-gateway): wire Kafka producers
g7h8i9j migrate(iab-gateway): update configuration
i0j1k2l migrate(iab-gateway): add integration tests
```

**Benefits:**
- ✅ Easy to review (one logical change per commit)
- ✅ Safe to revert (each commit is complete)
- ✅ Easy to debug (can bisect to find issues)
- ✅ Clear history (understand what changed and why)

## When to Use This Skill

**APPLY WHEN:**
- Managing complex migrations
- Large refactorings with many changes
- Multi-day development tasks
- Ensuring commit hygiene during complex work
- Need clean commit history

**SKIP WHEN:**
- Simple single-file changes
- Quick fixes (standard commit is fine)
- Not making code changes

## Core Directive

**Every commit = Compiles + Tests Pass + Logical Task Complete. Commit stable states, not work in progress.**

## The Golden Rule

```
Every commit = Compiles + Tests Pass + Logical Task Complete
```

**A commit represents a STABLE state, not "work in progress."**

### Understanding Stable States

A **stable state** means:
- Code compiles without errors
- All tests pass (unit, integration, etc.)
- A logical task is complete (not half-done)
- The codebase is in a working condition

**Why stable states matter:**
- Any commit can be checked out and the code will work
- Easy to bisect bugs (test each commit)
- Safe to revert individual commits
- Clear progression of changes

## Core Principles

### Single Branch, Many Commits

**Use one branch with many small commits:**

```bash
# Create working branch
git checkout -b migrate/service-name

# Work, committing stable states
# Each commit = compiles + tests pass + task done
```

### Valid Commit Criteria

| Criterion | Required? |
|-----------|-----------|
| Code compiles | YES |
| Tests pass | YES |
| Logical task COMPLETE | YES |
| No WIP or half-done work | YES |

**Invalid commits:**
- Code doesn't compile
- Tests failing
- "WIP: still working on X"
- Half-migrated module

## Commit Message Format

```
type(scope): short description

Longer explanation if needed.

- Bullet points for details
- What was changed and why
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring
- `migrate`: Migration work
- `test`: Test additions/changes
- `docs`: Documentation

**Examples:**
```
migrate(iab-gateway): copy handlers from source

- Copied RequestHandler, ResponseBuilder
- Updated package declarations
- All tests passing

refactor(kafka): consolidate producers into KafkaService

- Moved 5 producer classes to single service
- Updated all call sites
- Dead code removed
```

## Workflow Steps

### 1. Start Branch

```bash
git checkout -b type/description
```

### 2. Work on Task

```bash
# Make changes
# Compile and test
sbt compile && sbt test

# Commit stable state
git add .
git commit -m "type(scope): what was accomplished"
```

### 3. Continue Working

```bash
# Repeat: change → compile → test → commit
# Each commit = stable state
```

### 4. Push Regularly

```bash
# Push to backup your work
git push origin your-branch
```

### 5. Create PR

```bash
# When all tasks complete
gh pr create --title "Description" --body "Details"
```

## Common Patterns

### Pattern 1: Incremental Migration

**For migrating a service module by module:**

```bash
# Commit 1: Copy code
git add src/main/scala/com/service/ModuleA.scala
git commit -m "migrate(service): copy ModuleA from source"

# Commit 2: Update dependencies
git add build.sbt
git commit -m "migrate(service): add ModuleA dependencies"

# Commit 3: Wire integration
git add src/main/scala/com/service/Service.scala
git commit -m "migrate(service): wire ModuleA into Service"

# Each commit is stable and reviewable
```

**When to use**: Migrating large services piece by piece.

### Pattern 2: Refactoring in Steps

**For refactoring with clear steps:**

```bash
# Step 1: Extract method
git add src/main/scala/com/service/Utils.scala
git commit -m "refactor(utils): extract validation logic"

# Step 2: Consolidate
git add src/main/scala/com/service/Utils.scala
git commit -m "refactor(utils): consolidate duplicate validation"

# Step 3: Remove dead code
git add src/main/scala/com/service/Utils.scala
git commit -m "refactor(utils): remove unused validation methods"
```

**When to use**: Large refactorings that can be broken into logical steps.

### Pattern 3: Test-Driven Development

**For TDD workflow:**

```bash
# Commit 1: Add failing test
git add src/test/scala/com/service/FeatureTest.scala
git commit -m "test(service): add failing test for feature"

# Commit 2: Implement feature
git add src/main/scala/com/service/Feature.scala
git commit -m "feat(service): implement feature to pass test"

# Commit 3: Refactor
git add src/main/scala/com/service/Feature.scala
git commit -m "refactor(service): improve feature implementation"
```

**When to use**: Following TDD methodology.

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: WIP Commits

**Bad:**
```bash
git commit -m "WIP: migrating service"
git commit -m "WIP: still working on handlers"
git commit -m "WIP: need to fix tests"
```

**Problems:**
- Can't review incomplete work
- Don't know what's done vs. what's not
- Can't safely revert
- Pollutes history

**Good:**
```bash
git commit -m "migrate(service): copy handlers from source"
git commit -m "migrate(service): wire handlers into routes"
git commit -m "migrate(service): add handler tests"
```

### ❌ Anti-Pattern 2: Giant Commits

**Bad:**
```bash
git commit -m "refactor: all changes"
# Includes: 50 files, multiple features, test updates, config changes
```

**Problems:**
- Hard to review (too many changes)
- Can't understand what changed
- Risky to revert (might break other things)
- Hard to debug (can't bisect)

**Good:**
```bash
git commit -m "refactor(module): extract validation logic"
git commit -m "refactor(module): consolidate utils"
git commit -m "refactor(module): update tests"
```

### ❌ Anti-Pattern 3: Committing Broken Code

**Bad:**
```bash
# Code doesn't compile
git commit -m "feat: add new feature"
# Tests failing
git commit -m "fix: update tests"
```

**Problems:**
- Can't checkout and run code
- Can't bisect bugs
- Breaks CI/CD pipeline
- Other developers can't work

**Good:**
```bash
# Fix compilation errors first
sbt compile
# Fix tests
sbt test
# Then commit
git commit -m "feat: add new feature with tests"
```

### ❌ Anti-Pattern 4: Vague Commit Messages

**Bad:**
```bash
git commit -m "fix stuff"
git commit -m "updates"
git commit -m "changes"
```

**Problems:**
- Can't understand what changed
- Can't find commits later
- No context for reviewers
- Useless git history

**Good:**
```bash
git commit -m "fix(auth): correct token validation logic

Fixed issue where expired tokens were accepted.
Added expiration check before validation.
All tests passing."
```

## Best Practices

### Commit Often

**Many small commits are better than few large commits:**

```bash
# Good: Many small commits
git log --oneline
a1b2c3d refactor(module): extract validation logic
d4e5f6g refactor(module): consolidate utils
g7h8i9j refactor(module): remove dead code

# Bad: One giant commit
a1b2c3d refactor(module): all changes
```

**Why**: Small commits are easier to review, understand, and revert.

### Test Before Commit

**Always verify before committing:**

```bash
# ALWAYS before committing
sbt compile && sbt test
git commit -m "..."
```

**Why**: Ensures every commit is stable and working.

### Descriptive Messages

**Clear messages help reviewers and future you:**

```bash
# Good
migrate(iab-gateway): wire Kafka producers

Replaced embedded Kafka with KafkaService.
Updated 3 producer call sites.
All integration tests passing.

# Bad
fix stuff
wip
updates
```

**Why**: Good messages make git history useful for debugging and understanding changes.

## Complex Task Strategy

For multi-day tasks:

### Day 1-2: Analysis
- Complete service breakdown
- NO code changes yet
- Commit: docs/analysis files

### Day 3-N: Implementation
- One module at a time
- Commit after each stable module
- Push daily for backup

### Final: Review
- Squash WIP commits if any
- Clean commit history
- Create PR

## Troubleshooting

### Commit doesn't compile

```bash
# Undo last commit, keep changes
git reset --soft HEAD~1

# Fix issues
sbt compile

# Commit again
git add .
git commit -m "..."
```

### Tests failing

```bash
# Undo and fix
git reset --soft HEAD~1

# Fix tests
sbt test

# Commit when passing
git commit -m "..."
```

### Need to split large commit

```bash
# Reset to before commit
git reset HEAD~1

# Stage and commit in parts
git add file1.scala file2.scala
git commit -m "part 1"

git add file3.scala
git commit -m "part 2"
```

## Output

**This skill produces clean git commit history with stable states.**

### Git History Output

- **Multiple commits** - One per stable state (compiles + tests pass + logical task complete)
- **Clean commit history** - Logical progression, descriptive messages
- **Stable states** - Each commit represents working code
- **No WIP commits** - All commits are complete logical tasks

### What This Output Enables

- **For Service Migration**: Clean migration history for code review
- **For Service Refactoring**: Track refactoring progression safely
- **For Complex Tasks**: Break down large changes into reviewable commits
- **For Code Review**: Easy to review incremental changes

**Note**: This skill produces **git commit history**, not files. The output is the git history itself.

## Success Criteria

- **Every commit compiles**
- **Every commit passes tests**
- **Commit messages are descriptive**
- **Logical progression in history**
- **No WIP commits in final PR**
- **Branch pushed regularly**

## Related Skills

- Service Migration - Applies this workflow
- Service Refactoring - Applies this workflow
- Service Breakdown - Analysis phase commits

## Remember

> "Commit stable states, not work in progress."

> "Each commit should compile and pass tests."

> "Descriptive commit messages help code review."
