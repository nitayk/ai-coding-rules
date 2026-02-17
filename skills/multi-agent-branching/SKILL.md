---
name: multi-agent-branching
description: "Prevents concurrent AI agents from overwriting each other's work by enforcing feature branch isolation. Checks current git branch before any file edits, creates unique timestamped feature branches if on main/master, and ensures all commits go to feature branches. Use when multiple agents work simultaneously, during autonomous agent workflows, or when preventing merge conflicts. Agents detect from description and apply branch verification pattern at session start - check branch before first edit, create feature branch if needed, commit only to feature branches."
version: "1.0.0"
last_updated: "2026-01-25"
tags: ["git", "workflow", "agents", "branching", "universal"]
---
# Multi-Agent Branching

Prevent concurrent AI agents from overwriting each other's work by enforcing feature branch isolation.

**CRITICAL**: This skill is `alwaysApply: true` - automatically active for every session. All agents MUST work in feature branches, never on main/master.

## What is Multi-Agent Branching?

Multi-agent branching is a workflow pattern that prevents conflicts when multiple AI agents work simultaneously on the same codebase. Instead of all agents committing directly to `main` or `master`, each agent works in an isolated feature branch.

**Core Concept**: Every agent session operates in its own feature branch, ensuring that:
- Work from different agents doesn't interfere with each other
- Each agent has a stable base to work from
- Changes can be reviewed and merged via pull requests
- No work is lost due to concurrent modifications

## Why This Matters

### The Problem: Concurrent Agent Conflicts

When multiple Cursor agents work simultaneously without branch isolation:

**Scenario: Lost Work**
```
10:00 AM - Agent A starts working on feature X
10:05 AM - Agent A commits changes to main
10:10 AM - Agent B starts working on feature Y (unaware of A's changes)
10:15 AM - Agent B commits different changes to main
Result: Agent A's work is overwritten or lost
```

**Scenario: Confusion and Merge Conflicts**
```
Agent A: Modifies UserService.scala → commits to main
Agent B: Also modifies UserService.scala → commits to main
Result: Merge conflicts, broken code, both agents confused
```

**Scenario: Unstable Base**
```
Agent A: Adds new dependency → commits to main
Agent B: Starts work assuming old dependencies → code breaks
Result: Agent B's work fails due to unexpected changes
```

### The Solution: Feature Branch Isolation

By forcing each agent to work in a feature branch:
- ✅ Each agent has an isolated workspace
- ✅ Changes don't interfere with each other
- ✅ All work is preserved
- ✅ Changes can be reviewed before merging
- ✅ Stable base for each agent's work

## When This Skill Applies

**ALWAYS ACTIVE** - This skill applies to every Cursor session automatically.

**Prevents:**
- Agent A commits to main
- Agent B (unaware) commits different changes to main
- Agent B overwrites Agent A's work
- Both agents get confused by unexpected state

## Core Directive

**Check branch BEFORE any file edit. Create feature branch if on main/master. Never commit directly to main/master.**

## The Problem

**When multiple Cursor agents work simultaneously:**

```
Agent A: Working on feature X → commits to main
Agent B: Working on feature Y → commits to main (overwrites A's work)
Result: Lost work, confusion, merge conflicts
```

**Solution:** Force all agents to work in isolated feature branches

## Core Principles

### 1. Branch-First Workflow

**Never edit files before checking the branch.** The first action in every session must be branch verification.

**Why**: If you're on `main` and start editing, you risk committing to the wrong branch. Check first, then work.

### 2. Unique Branch Names

Use timestamps in branch names to prevent collisions between agents working simultaneously.

**Pattern**: `{type}/agent-{timestamp}`
- `feat/agent-20260125-143022` - Feature work
- `fix/agent-20260125-143022` - Bug fixes  
- `refactor/agent-20260125-143022` - Refactoring

**Why timestamps**: Two agents creating branches at the same time won't collide.

### 3. Isolation Before Integration

Work in isolation, integrate via pull requests. Never force-push to main.

**Why**: PRs provide:
- Review point for changes
- CI/CD validation
- Merge conflict resolution
- Audit trail

## Workflow

### Step 1: Check Current Branch

**Before ANY file edit, check branch:**

```bash
git branch --show-current
```

**Expected output:**
- Feature branch name (e.g., `feat/add-calculator`) → ✅ Safe to proceed
- Or `main`/`master` → ⚠️ Must create branch first

### Step 2: Create Branch If Needed

**If on main/master, create feature branch:**

```bash
# Generate unique branch name with timestamp
BRANCH_NAME="feat/agent-$(date +%Y%m%d-%H%M%S)"

# Create and switch to branch
git checkout -b "$BRANCH_NAME"

# Verify branch created
git branch --show-current
```

**Branch naming:**
- `feat/agent-YYYYMMDD-HHMMSS` - Feature work
- `fix/agent-YYYYMMDD-HHMMSS` - Bug fixes
- `refactor/agent-YYYYMMDD-HHMMSS` - Refactoring

**Why timestamps:** Prevents branch name collisions between agents

### Step 3: Work on Feature Branch

**Make changes, commit to feature branch:**

```bash
# Make changes
# ... edit files ...

# Commit to feature branch (NOT main)
git add .
git commit -m "feat: implement calculator"

# Push feature branch
git push -u origin HEAD
```

### Step 4: Create PR When Done

**Merge via PR (controlled merge point):**

```bash
# Create PR from feature branch
gh pr create --title "feat: add calculator" --body "..."

# Or use /pr-workflow skill for comprehensive PR management
```

## Common Patterns

### Pattern 1: Session Initialization

**Every session starts with branch verification:**

```bash
# Check branch
CURRENT_BRANCH=$(git branch --show-current)

# Create branch if needed
if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
  BRANCH_NAME="feat/agent-$(date +%Y%m%d-%H%M%S)"
  git checkout -b "$BRANCH_NAME"
fi
```

**When to use**: Start of every agent session, before any file edits.

### Pattern 2: Regular Pushes

**Push feature branch regularly to preserve work:**

```bash
# After each logical commit
git push -u origin HEAD
```

**When to use**: After completing a logical unit of work (not after every single file change).

### Pattern 3: PR Creation

**Always merge via pull request:**

```bash
# When work is complete
gh pr create --title "feat: description" --body "Details..."
```

**When to use**: When feature is complete and ready for review.

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Edit First, Branch Later

**Bad:**
```bash
# Edit files
vim src/main.py
# Then realize you're on main
git checkout -b feat/new-feature  # Too late!
```

**Good:**
```bash
# Check branch first
git branch --show-current
# Create branch if needed
git checkout -b feat/new-feature
# Then edit files
vim src/main.py
```

### ❌ Anti-Pattern 2: Generic Branch Names

**Bad:**
```bash
git checkout -b feat/feature  # Collision risk!
```

**Good:**
```bash
git checkout -b feat/agent-$(date +%Y%m%d-%H%M%S)  # Unique!
```

### ❌ Anti-Pattern 3: Assuming Single Agent

**Bad:**
```bash
# "I'm the only one working, I'll commit to main"
git commit -m "..."  # Dangerous!
```

**Good:**
```bash
# Always assume other agents exist
git checkout -b feat/agent-$(date +%Y%m%d-%H%M%S)
git commit -m "..."
```

### ❌ Anti-Pattern 4: Force Pushing to Main

**Bad:**
```bash
git push --force origin main  # Never!
```

**Good:**
```bash
gh pr create  # Use PR workflow
```

## Key Rules

### MUST DO

- **Check branch before first edit** in each session
- **Create feature branch** if on main/master
- **Use unique branch names** (timestamps prevent collisions)
- **Commit to feature branch** only
- **Push feature branch** regularly
- **Merge via PR** (never force push to main)

### NEVER DO

- **Commit directly to main/master**
- **Assume you're the only agent** working
- **Force push** without explicit user permission
- **Skip branch check** before editing files
- **Use generic branch names** (e.g., `feat/feature`)

## Branch Verification Pattern

**Every session, before first edit:**

```bash
# 1. Check current branch
CURRENT_BRANCH=$(git branch --show-current)

# 2. If on main/master, create branch
if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
  echo "WARNING: On main/master - creating feature branch"
  BRANCH_NAME="feat/agent-$(date +%Y%m%d-%H%M%S)"
  git checkout -b "$BRANCH_NAME"
  echo "SUCCESS: Created branch: $BRANCH_NAME"
else
  echo "SUCCESS: Already on feature branch: $CURRENT_BRANCH"
fi

# 3. Verify branch
git branch --show-current
```

## Integration with Other Skills

**Works with:**
- `/git-workflow` - Clean commit history on feature branch
- `/pr-workflow` - Merge feature branch via PR
- `/service-migration` - Migration work on feature branch
- `/service-refactoring` - Refactoring on feature branch

## Understanding the Concepts

### Git Branches as Isolation Mechanism

Git branches create isolated workspaces where changes don't affect other branches until merged. This is perfect for multi-agent workflows:

- **Isolation**: Each branch is independent
- **Safety**: Changes in one branch don't break another
- **Review**: Changes can be reviewed before merging
- **Rollback**: Easy to discard a branch if needed

### Timestamp-Based Naming

Using timestamps in branch names ensures uniqueness:

**Why it works:**
- Two agents creating branches at the same moment get different timestamps
- Even if they use the same prefix, timestamps differ
- No coordination needed between agents

**Format**: `YYYYMMDD-HHMMSS` provides second-level precision, sufficient for agent workflows.

### Pull Request as Integration Point

Pull requests provide a controlled merge point:

- **Review**: Human can review changes before merging
- **CI/CD**: Automated tests run before merge
- **Conflict Resolution**: Merge conflicts visible and resolvable
- **History**: Clear record of what changed and why

## Common Scenarios

### Scenario 1: Starting Fresh Session

**Context**: Agent starts a new session to work on a feature.

**Workflow:**
```bash
# 1. Check branch
git branch --show-current
# Output: main

# 2. Create feature branch
BRANCH_NAME="feat/agent-$(date +%Y%m%d-%H%M%S)"
git checkout -b "$BRANCH_NAME"
# Output: Switched to new branch 'feat/agent-20260125-143022'

# 3. Work on feature branch
# ... make changes ...

# 4. Commit to feature branch
git add .
git commit -m "feat: implement calculator"

# 5. Push and create PR
git push -u origin HEAD
gh pr create --title "feat: add calculator" --body "..."
```

**Key Point**: Branch created before any file edits.

### Scenario 2: Continuing Existing Branch

**Context**: Agent continues work from a previous session.

**Workflow:**
```bash
# 1. Check branch
git branch --show-current
# Output: feat/agent-20260125-140000

# 2. Already on feature branch ✓
# No branch creation needed

# 3. Continue work
# ... make changes ...

# 4. Commit to feature branch
git add .
git commit -m "feat: add error handling"

# 5. Push updates
git push
```

**Key Point**: Verify you're on the right branch, then continue.

### Scenario 3: Multiple Agents Working Simultaneously

**Context**: Two agents working on different features at the same time.

**Timeline:**
```
10:00 AM - Agent A: Checks branch → main
10:00 AM - Agent A: Creates feat/agent-20260125-100000
10:05 AM - Agent B: Checks branch → main  
10:05 AM - Agent B: Creates feat/agent-20260125-100500
10:10 AM - Agent A: Commits to feat/agent-20260125-100000
10:15 AM - Agent B: Commits to feat/agent-20260125-100500
10:20 AM - Both push to different branches
10:25 AM - Both create PRs independently
```

**Result**: 
- ✅ No conflicts (different branches)
- ✅ No overwrites (isolated work)
- ✅ Both PRs can be reviewed independently
- ✅ Both can be merged when ready

**Key Point**: Timestamps ensure unique branch names even when agents work simultaneously.

## Troubleshooting

### Already Committed to Main

**If accidentally committed to main:**

```bash
# 1. Create feature branch from current state
git checkout -b feat/agent-$(date +%Y%m%d-%H%M%S)

# 2. Reset main to previous state
git checkout main
git reset --hard origin/main

# 3. Switch back to feature branch
git checkout feat/agent-...
```

### Branch Name Collision

**If branch name already exists:**

```bash
# Add more precision to timestamp
BRANCH_NAME="feat/agent-$(date +%Y%m%d-%H%M%S-%N)"
```

### Need to Update Main

**To update feature branch with latest main:**

```bash
# On feature branch
git fetch origin
git merge origin/main
# Resolve conflicts if any
git push
```

## Success Criteria

- **Branch checked** before first edit
- **Feature branch created** if on main/master
- **All commits** go to feature branch
- **Branch pushed** regularly
- **PR created** for merge
- **No direct commits** to main/master

## Output

**This skill produces:**
- Feature branch created (if needed)
- All work isolated to feature branch
- Clean merge via PR
- No agent conflicts

## Remember

> "Check branch before editing - always"

> "Feature branches prevent conflicts"

> "Timestamps make branch names unique"

> "Merge via PR, never force push to main"
