---
paths:
  - ".git/**"
  - "**/.gitignore"
  - "**/.gitattributes"
  - "**/.gitmodules"
---

# Git Workflow Guidelines

## Triggers

**APPLY WHEN**: Staging, committing, branching, creating PRs, resolving conflicts.
**SKIP WHEN**: Only reading git history or blame.

## Core Directive

Stage logically related changes. Use conventional commits. Keep PRs focused. Never force push to main.

## Patterns

### Staging

**Preferred:** Review with `git diff`, stage with `git add -p`. Group related files per commit.
**Avoid:** `git add .` without review. One giant commit with unrelated changes.

### Commit Messages

**Preferred:**
```
feat(auth): add JWT token generation
fix(api): handle null response from user service
```
With body explaining why when non-obvious.

**Avoid:** "changes", "fix", "wip", "asdf"

### Branch Names

**Preferred:** `feature/user-authentication`, `fix/payment-timeout`, `refactor/database-layer`
**Avoid:** `dev`, `test`, `temp`

### PR Descriptions

Include: Summary, Changes (files and purpose), Testing checklist, Breaking changes, Related issues.

**Preferred:** Focused PR (~200-500 lines), single feature or fix.
**Avoid:** Massive PR (2000+ lines) mixing features, refactors, fixes.

### Merge and Force Push

**Preferred:** Squash and merge for feature branches. `git push --force-with-lease` only on feature branches.
**Avoid:** Force push to main/master. Rewriting public history.

### Conflict Resolution

After rebase: resolve conflicts, stage resolved files, `git rebase --continue`. Always run tests before pushing.

## Common Mistakes

- Do not commit: `.env`, `config/production.yml`, `target/`, `node_modules/`, `.idea/`, `.vscode/`
- Do not commit build artifacts, IDE files, or large files (use Git LFS)
- Do not rewrite commits others have pulled
