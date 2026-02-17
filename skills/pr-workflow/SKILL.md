---
name: pr-workflow
description: "Manages complete PR lifecycle from creation through merge with pre-PR validation, autonomous status monitoring, bot feedback handling, and merge coordination. Performs pre-PR checks (tests, linting, build), monitors PR status continuously, addresses bot feedback automatically, and merges only when all checks pass. Use when creating pull requests, monitoring PR status, addressing bot feedback, or merging PRs. More comprehensive than /create-pr command - includes full lifecycle management with automated monitoring and merge coordination."
version: "1.0.0"
last_updated: "2026-01-25"
tags: ["git", "pr", "workflow", "ci-cd", "universal"]
---
# PR Workflow Management

Comprehensive pull request lifecycle management from creation to merge.

**CRITICAL**: Use `mergeable_state: "clean"` (not `mergeable: true`) to determine if PR is ready to merge.

## What is PR Workflow Management?

PR workflow management is a comprehensive process that handles the complete pull request lifecycle from creation through merge. It includes pre-PR validation, continuous status monitoring, automated bot feedback handling, and merge coordination to ensure code quality and CI/CD compliance.

**Core Concept**: A PR should be:
- ✅ **Validated** - Pre-PR checks pass (tests, linting, build)
- ✅ **Monitored** - Status checked continuously
- ✅ **Addressed** - Bot feedback handled automatically
- ✅ **Clean** - All checks pass before merge
- ✅ **Coordinated** - Merged only when ready

## Why This Matters

### The Problem: Manual PR Management

**Without automated workflow:**
- PRs created with failing tests
- CI failures go unnoticed
- Bot feedback ignored
- PRs merged prematurely
- Code quality issues slip through

**Example of problems:**
```
# PR created without checks
gh pr create --title "feat: new feature"
# Tests failing, but PR created anyway
# CI fails, but no one notices
# PR sits for days with failures
# Eventually merged with broken code
```

### The Solution: Automated Lifecycle Management

**With PR workflow:**
- ✅ Pre-PR checks ensure quality
- ✅ Continuous monitoring catches issues
- ✅ Bot feedback addressed automatically
- ✅ Merge only when all checks pass
- ✅ Consistent quality standards

**Example of success:**
```
# Pre-PR checks run first
sbt test && sbt scalafmtCheck
# All checks pass
# PR created
# Status monitored continuously
# Bot feedback addressed automatically
# Merged only when mergeable_state: "clean"
```

## When to Use This Skill

**APPLY WHEN:**
- Creating pull requests
- Monitoring PR status and CI checks
- Addressing bot comments and feedback
- Preparing PR for merge
- Managing PR lifecycle autonomously

**SKIP WHEN:**
- Simple single-file changes (use `/create-pr` command instead)
- Not using GitHub
- PR already merged

## Core Directive

**Pre-PR checks → Create PR → Monitor → Address feedback → Merge when clean.**

## Phase 1: Pre-PR Checks

**Before creating PR, verify:**

### 1. Code Quality Checks

```bash
# Type checking
sbt compile
# or
npm run typecheck
# or
mypy .

# Linting
sbt scalafmtCheck
# or
npm run lint
# or
ruff check .
```

**Required:** All checks must pass

### 2. Run Tests

```bash
# Run full test suite
sbt test
# or
npm test
# or
pytest
```

**Required:** All tests must pass

### 3. Security Scan

**Check for:**
- Hardcoded secrets (API keys, passwords)
- Hardcoded paths (use environment variables)
- Insecure dependencies
- SQL injection risks
- XSS vulnerabilities

**Tools:**
```bash
# GitGuardian, TruffleHog, or similar
git secrets --scan
# or
npm audit
# or
safety check
```

**Required:** No critical security issues

### 4. Find PR Template

**Check for PR template:**

```bash
# Common locations
.github/pull_request_template.md
docs/pull_request_template.md
PULL_REQUEST_TEMPLATE.md
```

**Use template** if available, fill all required sections

### 5. Verify Branch Status

```bash
# Check current branch
git branch --show-current

# Ensure not on main/master
# If on main/master, create feature branch first
```

## Phase 2: Create PR

### Using GitHub CLI

```bash
# Create PR with title and body
gh pr create \
  --title "feat: add price calculator with tax" \
  --body "Implements price calculation with configurable tax rate.

- Added PriceCalculator class
- Added unit tests (100% coverage)
- Updated documentation

Closes #123"
```

### PR Description Template

**Include:**
- **What changed**: Brief summary
- **Why**: Motivation/context
- **How**: Implementation approach
- **Testing**: How tested
- **Checklist**: Pre-PR checks completed

**Example:**
```markdown
## What Changed
Added PriceCalculator class with tax calculation support.

## Why
Needed to standardize price calculations across services.

## How
- Created PriceCalculator class
- Added calculateTotal method
- Implemented tax calculation logic

## Testing
- Unit tests added (100% coverage)
- Integration tests pass
- Manual testing completed

## Checklist
- [x] Code compiles
- [x] Tests pass
- [x] No security issues
- [x] Documentation updated
```

## Phase 3: Autonomous Monitoring

**After PR creation, monitor continuously:**

### Check PR Status

**Use GitHub API (via `gh` CLI or API):**

```bash
# Get PR details
gh pr view <pr-number> --json mergeableState,statusCheckRollup,comments

# Key fields:
# - mergeableState: "clean" | "dirty" | "unstable" | "blocked"
# - statusCheckRollup: Array of CI check results
# - comments: Array of comments (including bot comments)
```

### Critical Insight: mergeable vs mergeableState

**These are DIFFERENT:**

- `mergeable: true` → Only means "no git conflicts"
- `mergeable_state: "clean"` → Means "all checks passed, ready to merge"

**Only merge when `mergeable_state: "clean"`**

### Monitoring Loop

**Poll every 30-60 seconds:**

1. **Check mergeable_state:**
   ```bash
   gh pr view <pr-number> --json mergeableState -q .mergeableState
   ```

2. **Read all comments:**
   ```bash
   gh pr view <pr-number> --json comments -q '.comments[] | select(.author.type == "Bot")'
   ```

3. **Check CI status:**
   ```bash
   gh pr checks <pr-number>
   ```

4. **Address feedback:**
   - Fix issues mentioned in bot comments
   - Respond to review comments
   - Rerun failed checks if flaky

5. **Push fixes:**
   ```bash
   git add .
   git commit -m "fix: address PR feedback"
   git push
   ```

6. **Wait for re-validation:**
   - Wait 30-60 seconds
   - Check status again
   - Repeat until `mergeable_state: "clean"`

## Phase 4: Addressing Feedback

### Bot Comments

**Common bot feedback:**
- Code coverage too low
- Linting errors
- Security vulnerabilities
- Missing tests
- Documentation issues

**Action:** Fix issues, push, wait for re-check

### Review Comments

**Human reviewer feedback:**
- Code style suggestions
- Logic questions
- Performance concerns
- Architecture suggestions

**Action:** 
- Address each comment
- Reply to reviewer
- Push changes
- Mark threads as resolved

### CI Failures

**If CI fails:**

1. **Check failure reason:**
   ```bash
   gh pr checks <pr-number> --watch
   ```

2. **Fix issues:**
   - Update code
   - Fix tests
   - Update configuration

3. **Rerun flaky tests:**
   ```bash
   gh pr checks <pr-number> --rerun-failed
   ```

4. **Push and wait:**
   - Push fixes
   - Wait for CI to complete
   - Verify all checks pass

## Phase 5: Merge (Only When Clean)

**Merge ONLY when:**

- `mergeable_state: "clean"` (not just `mergeable: true`)
- All CI checks passed
- Zero unaddressed comments
- All review threads resolved
- Required approvals obtained

### Merge Command

```bash
# Merge PR
gh pr merge <pr-number> --squash --delete-branch

# Or merge via GitHub UI if preferred
gh pr view <pr-number> --web
```

### Merge Strategies

**Choose based on project:**
- **Squash**: Single commit (clean history)
- **Merge**: Preserve commit history
- **Rebase**: Linear history (if allowed)

## Workflow Summary

```
1. Pre-PR Checks
   ├─ Type check ✓
   ├─ Tests pass ✓
   ├─ Security scan ✓
   └─ PR template filled ✓

2. Create PR
   └─ gh pr create

3. Monitor Loop (every 30-60s)
   ├─ Check mergeable_state
   ├─ Read bot comments
   ├─ Check CI status
   ├─ Address feedback
   ├─ Push fixes
   └─ Wait for re-validation

4. Merge (when mergeable_state: "clean")
   └─ gh pr merge
```

## Integration with Other Skills

**Use with:**
- `/git-workflow` - Clean commit history
- `/tdd-workflow` - Tests written first
- `/best-practices-enforcement` - Code quality

## Common Pitfalls

### Merging Too Early

**Problem:** Merging when `mergeable: true` but checks still running

**Solution:** Wait for `mergeable_state: "clean"`

### Ignoring Bot Comments

**Problem:** Not addressing automated feedback

**Solution:** Read all comments, fix issues, push

### Not Monitoring Continuously

**Problem:** PR stuck waiting for fixes

**Solution:** Poll every 30-60 seconds, address immediately

### Skipping Pre-PR Checks

**Problem:** PR fails CI immediately

**Solution:** Run all checks locally before creating PR

## Success Criteria

- **All pre-PR checks pass** before creating PR
- **PR created** with complete description
- **All bot comments addressed** and resolved
- **All CI checks pass** (mergeable_state: "clean")
- **All review comments** addressed
- **PR merged** successfully

## Output

**This skill produces:**
- PR created with proper description
- All feedback addressed
- PR merged when ready
- Clean git history

## Remember

> "mergeable_state: 'clean' means ready to merge, not mergeable: true"

> "Address every bot comment - they're usually right"

> "Monitor continuously - don't let PRs sit waiting"
