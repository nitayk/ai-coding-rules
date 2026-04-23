---
name: git-forensics
description: Use when asked to understand, explore, or assess an unfamiliar repository, evaluate codebase health before reading code, identify the riskiest files, understand team dynamics, analyze commit history, or assess bus factor. Also use when the user says "what does this repo do", "analyze repo health", "show me riskiest files", "understand this codebase", or /git-forensics.
---

# Git Forensics

## Overview

Surface repo health signals from git history **before reading any code**. Five diagnostic commands reveal churn hotspots, team structure, bug clustering, momentum, and firefighting frequency. An agent can cross-correlate these signals into a compound risk ranking — something no static script can do.

**Core principle:** Git history is a permanent record of where complexity, risk, and pain actually live. Read it first.

## When to Use

- Exploring an unfamiliar or open-source repository
- Evaluating a dependency before adopting it
- Assessing a codebase before a refactor, migration, or service breakdown
- Answering "what does this repo do?" or "where are the riskiest files?"

**Do NOT substitute code reading for this.** Do not read source files until after the report is complete.

## Workflow

### Phase 0 — Learn Commit Conventions (ALWAYS first)

**Step A: Check declared conventions**
```bash
cat CONTRIBUTING.md 2>/dev/null || cat .github/CONTRIBUTING.md 2>/dev/null
# Also scan README for "contributing" or "commit" sections (first 200 lines)
ls .github/ 2>/dev/null
```
Extract the *officially declared* commit strategy (Conventional Commits, Angular, free-form, etc.) and any ticket system references. This is what the team *intended*.

**Step B: Sample actual history**
```bash
git log --oneline -100
```
Scan the output and determine:
- **Actual commit style**: conventional (`feat:`, `fix:`, `chore:`), free-form, Jira-prefixed, emoji-led, or mixed
- **Bug/fix keywords actually in use**: `fix:`, `bugfix`, `🐛`, `FIX`, `fixes #`, `closes #`
- **Hotfix/emergency keywords**: `revert`, `hotfix`, `HOTFIX`, `rollback`, `emergency`
- **Drift**: any shift in convention over time (e.g. free-form before 2024, conventional after)

Store the extracted bug and hotfix terms — you will use them in Phases 3 and 5 instead of hardcoded patterns.

**Fallback**: If no bug/fix keywords are found in the sample (e.g. brand-new or unusually clean repo), fall back to: `fix|bug|broken|error` for bug terms and `revert|hotfix|rollback` for hotfix terms. Note the assumption in your report.

---

### Phase 1 — Churn Hotspots

```bash
git log --format=format: --name-only --no-merges --since="1 year ago" | sort | uniq -c | sort -nr | head -20
```
Files modified most in the last year. High churn combined with high bug density = real danger zone.

### Phase 2 — Team Structure / Bus Factor

```bash
git shortlog -sn --no-merges
git shortlog -sn --no-merges --since="6 months ago"
```
Run both. Compare all-time vs. recent 6-month distributions to detect: single points of failure, recent knowledge drain, and team continuity risk.

**If `git shortlog` returns empty output** (this happens silently on some setups), fall back to:
```bash
git log --format='%an' --no-merges | sort | uniq -c | sort -nr
git log --format='%an' --no-merges --since="6 months ago" | sort | uniq -c | sort -nr
```

### Phase 3 — Bug Clustering

```bash
git log -i -E --grep="<bug-terms-from-phase-0>" --name-only --format='' | sort | uniq -c | sort -nr | head -20
```
Replace `<bug-terms-from-phase-0>` with **only** the terms you actually observed in Phase 0. Do not pad with generic words like `bug`, `broken`, or `error` that weren't in the commit history. If the only bug keyword you saw was `fix:`, the pattern should be exactly `fix:` — precision matters because false positives corrupt the risk ranking.

### Phase 4 — Momentum

```bash
git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
# For repos older than ~3 years, add --since="3 years ago" to avoid slow output on deep histories
```
Monthly commit frequency across history. Look for: steady rhythm (healthy), sudden drops (personnel changes), declining trend (momentum loss), irregular spikes (batched releases).

### Phase 5 — Firefighting Frequency

```bash
git log --oneline --since="1 year ago" | grep -iE '<hotfix-terms-from-phase-0>'
```
Replace with actual keywords found. Frequency > monthly indicates deploy process weakness (missing tests, unreliable staging), not just code quality issues.

### Phase 6 — Bonus Signals (when available)

```bash
git tag --sort=-version:refname | head -10        # release cadence
gh repo view --json stargazerCount,openIssues,forkCount 2>/dev/null  # if gh CLI present
```

---

## Output Format

Produce a **Repo Health Report** with these sections in order:

```
## Repo Health Report: <repo-name>

### Contribution Style
- **Documented in**: CONTRIBUTING.md (declares: Conventional Commits)
  OR: ⚠️ Not documented (no CONTRIBUTING.md, README silent on commits)
- **Declared strategy**: [what docs say]
- **Actual strategy** (last 100 commits): ✅ Followed consistently
  OR: ⚠️ Inconsistent (~40% free-form despite docs)
  OR: ❌ Not followed in practice
- **Ticket system**: JIRA (PROJ-NNN pattern) / GitHub issues (#NNN) / none
- **Examples**: `fix(auth): handle expired tokens`, `feat: add retry logic`
- **Drift note**: [if convention changed over time, note when and how]

### Risk Matrix
| File | Churn (1yr) | Bug Commits | Risk |
|------|-------------|-------------|------|
| src/auth.ts | 87 | 12 | HIGH |
| ...          | ..  | ..  | ...  |

Rank by compound score. Flag files appearing in BOTH top-churn and top-bug lists.

### Bus Factor
- **All-time**: 2 people hold 71%+ of commits (Alice 54%, Bob 17%)
- **Last 6 months**: ⚠️ 1 person (Alice 89%) — single point of failure
- **Note if key authors appear absent** from recent period vs. all-time

### Momentum
[Monthly commit counts — tabular or narrative trend description]
Trend assessment: growing / stable / declining / abandoned

### Firefighting
- N reverts/hotfixes in the past year (~X/month)
- Assessment: [normal / elevated — suggests deploy process concern]

### Recommended Investigation Order
Ranked list of files/areas to review first, with reason (churn + bug density combination).
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using hardcoded `fix\|bug\|broken` grep | Always learn actual keywords from Phase 0 first |
| Padding learned keywords with generic terms | Use ONLY keywords you observed — `fix:` alone is correct if that's all you saw; `fix:\|bug\|broken\|error` poisons the results |
| `git shortlog` returning empty output | Fall back to `git log --format='%an' --no-merges \| sort \| uniq -c \| sort -nr` for both windows |
| Skipping Phase 0 to "save time" | Phase 0 takes 30 seconds and prevents wrong grep results |
| Reading source files before the report | Run all 6 phases first; code reading comes after. README and CONTRIBUTING.md are allowed in Phase 0 — they describe the repo, not implement it |
| Only checking all-time bus factor | Always run the 6-month window — that's where risks hide |
| Reporting raw counts without correlation | Cross-reference churn and bug density to find real danger zones |
| Skipping contribution style when docs exist | CONTRIBUTING.md reveals declared intent; comparing to actual practice is the key insight |

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
