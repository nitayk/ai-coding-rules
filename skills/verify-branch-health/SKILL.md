---
name: verify-branch-health
description: "Audit git repo hygiene — stale worktrees, branches, stashes, untracked files — locally AND on origin, with per-item dispositions (safe-to-delete-because-merged / rescue-candidate / gitignore-suggestion / commit-candidate). Auto-acts on high-confidence cleanups (squash-merged branches, `[gone]` upstreams, prunable worktrees); asks before touching anything ambiguous; cleans up OLD verified-merged agent worktrees but never removes an actively-worked peer session's checkout (one that is dirty, `locked`, or freshly committed) even if it is merged. Use whenever the user says `/verify-branch-health`, `branch health`, `audit my branches`, `stale branches`, `clean up git`, `stale worktrees`, `repo hygiene`, `what's safe to delete`, `prune branches`, `untracked files audit`, or when starting a fresh week of work and wanting a clean baseline. Do NOT use for one-branch end-of-work flow (use `/finishing-a-development-branch`) or for read-only churn / bus-factor analysis (use `/git-forensics`)."
last-reviewed: 2026-06-06
---

# Verify Branch Health

Audit a git repo's accumulated cruft — worktrees, branches, stashes, untracked files — both local and origin, with a **safety-tiered disposition** per finding. Autonomous on high-confidence cleanups; advisory on anything ambiguous.

**Core principle:** Detect → classify → only auto-delete what's provably already in `main`/`master`. Everything else gets a report row with a recommended action and a one-line "why."

**Overriding invariant — never damage another agent's *in-progress* work.** Cleaning up **OLD, verified-merged** agent worktrees/branches is fine and expected — that's the job. What's off-limits is touching a worktree/branch that a **concurrent peer session is actively working in**. The discriminator is **liveness**, not merge status: VERIFY merged first (§2a squash-merge / 0-ahead / merged-PR), then only auto-clean a worktree that *also* shows **no signs of a live session**. Treat any of these as "actively-worked → do not auto-touch": uncommitted/untracked changes, a `locked` flag, or a commit within the last ~24h. So a clean, merged, idle worktree IS safe to remove; a merged worktree that's dirty / locked / freshly-committed is NOT — a peer may be mid-task in it, and pulling the dir out from under a running session is destructive even when no commits are lost. When a worktree is unverifiable or borderline, report it and ask. See Step 0 and Safety Rule 1.

**Announce at start:** "I'm using the verify-branch-health skill to audit repo hygiene."

## When to Use

**APPLY WHEN:**
- User says `/verify-branch-health`, "audit my branches", "what's safe to delete", "stale stuff in this repo"
- Returning to a long-lived repo after time away — want a clean baseline
- Local branch list has gotten unwieldy (`git branch | wc -l` > ~20)
- After a sprint of stacked PRs that merged — clean up the residue
- Before a large refactor / migration — start from known-clean state
- Workspace-wide periodic hygiene sweep across nested repos (`--workspace`)

**SKIP WHEN:**
- One specific branch just finished and needs merge/PR → `/finishing-a-development-branch`
- Read-only history analysis (churn, bus factor, riskiest files) → `/git-forensics`
- Looking for code dead-paths inside files → `/code-cleanup`
- The repo has < 5 branches and no worktrees — not enough to audit

## Scope Detection (Step 0)

```bash
# Default: cwd repo only
# If --workspace flag or user says "across all repos":
#   For workspace root /Users/nitay.k/Repos (or detected multi-repo parent):
#   Iterate each nested .git/ directory; run audit per-repo, aggregate report
find . -maxdepth 3 -name '.git' -type d -not -path '*/.claude/worktrees/*' \
  | xargs -n1 dirname | sort -u
```

Single-repo audit is the default. `--workspace` mode runs the same checks per nested repo and produces a per-repo + workspace-summary report.

## Workflow

### 1. Refresh remote state + capability detection

```bash
git fetch --all --prune --dry-run 2>&1 | tee /tmp/vbh-fetch-dry.log
git fetch --all --prune --tags             # actually prune ghost refs

# Capability: does origin live on a GitHub host? Drives whether `gh` cross-refs run.
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
case "$ORIGIN_URL" in
  *github.com[/:]*) HAS_GH_REMOTE=1 ;;
  *)                HAS_GH_REMOTE=0 ;;   # GitLab, Bitbucket, self-hosted, bare-repo, no remote
esac
```

The dry-run captures what would change. The real fetch + prune is safe (only updates `refs/remotes/`, never touches local branches). If origin isn't a GitHub host (GitLab, Bitbucket, self-hosted git, a local bare repo for testing, or no remote at all), **silently skip every `gh`-based cross-reference below** — note the skip in the report's "Skipped / Not applicable" section, don't surface noisy errors.

### 2. Branch audit — one efficient pass

```bash
# Single-pass: name, upstream-track ([gone] / [ahead N] / [behind N]), age, author
git for-each-ref refs/heads/ \
  --format='%(refname:short)|%(upstream:track)|%(committerdate:relative)|%(committerdate:unix)|%(authorname)' \
  --sort=-committerdate
```

**Then classify each branch:**

| Signal | Disposition | Action |
|---|---|---|
| Upstream `[gone]` AND no uncommitted children | **safe-auto-delete** | `git branch -D <b>` (force — remote already gone proves it landed or was abandoned upstream) |
| Squash-merged into `main` (see §2a) | **safe-auto-delete** | `git branch -D <b>` |
| `git branch --merged main` lists it AND age > 7d | **safe-auto-delete** | `git branch -d <b>` (non-force; will refuse if unmerged tip exists) |
| Behind main by > 50 commits AND ahead by ≥ 1 | **revival-hazard** | Ask: rebase-and-rescue, cherry-pick salvageable commits, or delete |
| Has unique commits, no upstream, age > 30d | **abandoned-rescue-candidate** | Show last commit + 3-line diff stat; ask whether to push as PR or delete |
| Active (committed within 14d) | **leave-alone** | Skip |

**§2a — Squash-merge detection** (handles GitHub's default merge mode; `git branch --merged` misses these):

```bash
for branch in $(git for-each-ref refs/heads/ --format='%(refname:short)' | grep -vE '^(main|master)$'); do
  mb=$(git merge-base main "$branch" 2>/dev/null) || continue
  synthetic=$(git commit-tree "$(git rev-parse "$branch^{tree}")" -p "$mb" -m _)
  if [[ $(git cherry main "$synthetic" 2>/dev/null) == "-"* ]]; then
    echo "squash-merged: $branch"
  fi
done
```

Source: [not-an-aardvark/git-delete-squashed](https://github.com/not-an-aardvark/git-delete-squashed). This is the #1 reason naive audits miss obvious cleanups.

### 3. Worktree audit

```bash
git worktree list --porcelain
```

**Step 0 — classify each worktree as OLD (cleanable) vs ACTIVE (protected), BEFORE any disposition.** This matters most when worktrees are parked under a harness/agent-session dir (`.claude/worktrees/` or `.worktrees/`, names like `agent-<hash>`, `e2e-*`, `worktree-agent-*`) — i.e. parallel agent sessions. For each worktree gather two independent facts:

```bash
# (a) VERIFY merged — is the work already delivered? (§2a squash-merge, 0-ahead, or merged PR)
git rev-list --count main..<branch>                       # 0 = nothing unique left
#   + run the §2a synthetic-tree squash-merge check (plain merge-base misses squash merges)
# (b) LIVENESS — is a peer session actively in it RIGHT NOW? ANY hit ⇒ ACTIVE:
git -C <path> status --porcelain | head -1                # dirty / untracked ⇒ ACTIVE
git worktree list --porcelain | grep -A3 <path> | grep -q '^locked' && echo locked   # ACTIVE
git -C <path> log -1 --format=%ct                         # commit within ~24h ⇒ ACTIVE (likely live)
```

Disposition from the two facts:
- **OLD = verified-merged AND no liveness signal** → **safe-auto-remove** (clean, merged, idle — delivered work; removing it disturbs no one). This is the cleanup you SHOULD do.
- **ACTIVE = any liveness signal** (dirty, untracked, `locked`, or commit < ~24h) → **leave / report-only**, even if merged. A peer may be mid-task; pulling the dir is destructive regardless of merge status.
- **Unmerged + recent activity** → active work → **leave**.
- **Unmerged + stale (no activity > 30d), no worktree pinning it** → **rescue-candidate → ask** (don't silently delete unmerged commits).
- **Borderline / can't verify** → report and ask.

Same gate applies to branch deletion: delete a branch only once you've confirmed it's merged (or 0-ahead) AND it isn't backing an ACTIVE worktree.

Parse the porcelain output (stable contract). Per worktree, classify:

| Signal | Disposition | Action |
|---|---|---|
| **ACTIVE** — dirty/untracked, `locked`, or commit < ~24h (Step 0) | **leave / report-only** | Never auto-remove, even if merged. Report as `active-peer-session?`; confirm with owner before touching. |
| `prunable <reason>` | **safe-auto-prune** | `git worktree prune` (whole-repo, idempotent) — prunable means the dir is already gone, so no live session to disturb |
| **OLD** — verified-merged (§2a / 0-ahead / merged PR via `gh pr list --state merged --head <b>` when `HAS_GH_REMOTE=1`) AND no liveness signal | **safe-auto-remove** | `git worktree remove <path>` then branch delete |
| Path exists, has uncommitted changes OR untracked files | **ask** | Show `git -C <path> status -s` excerpt; ask: stash, commit-WIP, or force-remove |
| Unmerged, stale > 30d, not pinning active work | **rescue-candidate → ask** | Don't delete unmerged commits without confirmation |

### 4. Stash audit

```bash
git stash list --format='%gd|%cr|%s|%H'
```

| Signal | Disposition | Action |
|---|---|---|
| Stash refers to deleted branch (parse `WIP on <branch>:`, check `git branch`) | **rescue-candidate** | Ask: pop into new branch, drop, or leave |
| Age > 60d AND content is `diff` of files already in `main` | **safe-suggest-drop** | Ask before dropping (stashes can't be recovered) |
| Age < 14d | **leave-alone** | Skip |
| Otherwise | **needs-review** | Show 1-line summary + `git stash show -p <ref> \| head -20` |

**Stashes are never auto-dropped.** Even high-confidence stash matches need confirmation — the cost of losing real WIP is asymmetric.

### 5. Untracked file audit

```bash
git status --porcelain=v1 | awk '/^\?\? /{print substr($0,4)}'
git ls-files --others --exclude-standard --directory  # collapses dirs
```

**Then run a secret-pattern scan first** (leak-risk dominates hygiene):

```bash
# Flag and HALT auto-action if any match:
git ls-files --others --exclude-standard | grep -iE \
  '(\.env(\..*)?$|\.pem$|^id_rsa|\.key$|credentials|service-account.*\.json|\.p12$|\.pfx$)'
```

If matches found: report as **secret-leak-risk**, recommend `git-secrets` / TruffleHog scan, do NOT suggest `.gitignore` (they shouldn't exist on disk in a shared workspace either).

**Then classify remaining untracked:**

| Signal | Disposition | Action |
|---|---|---|
| Matches well-known build/IDE pattern (`.idea/`, `node_modules/`, `dist/`, `build/`, `target/`, `__pycache__/`, `.DS_Store`, `*.log`, coverage dirs) | **gitignore-suggestion** | Show proposed `.gitignore` block; ask before writing |
| Matches secret pattern | **secret-leak-risk** | See above |
| Source file (`.go`, `.py`, `.ts`, `.scala`, `.rs`, `.md`, etc.) — looks like real work | **commit-candidate** | Show `wc -l` + first 5 lines; ask: commit (with suggested message), stash, or ignore |
| Size > 50MB | **lfs-or-ignore** | Flag — large file should be in LFS or gitignored |
| Otherwise | **needs-review** | Show path + size; let user decide |

### 6. Also-tracked-but-ignored check (very common, often missed)

```bash
git ls-files -i -c --exclude-standard
```

Finds files in the index that **now** match `.gitignore` (added to ignore after they were committed — they keep being tracked silently). Recommend `git rm --cached <file>` per match.

### 7. Tag drift (local vs origin)

```bash
comm -23 <(git tag | sort) <(git ls-remote --tags origin | awk -F/ '{print $NF}' | sed 's/\^{}$//' | sort -u)
# Local-only tags = at risk if machine dies
comm -13 <(git tag | sort) <(git ls-remote --tags origin | awk -F/ '{print $NF}' | sed 's/\^{}$//' | sort -u)
# Origin-only tags = need `git fetch --tags`
```

Tags get silently dropped — no UI warns you.

### 8. Origin-side branch audit (read-only)

```bash
# Branches on origin not present locally — possibly forgotten PRs
git ls-remote --heads origin | awk '{print $2}' | sed 's|refs/heads/||' \
  | sort > /tmp/vbh-remote.txt
git for-each-ref refs/heads/ --format='%(refname:short)' | sort > /tmp/vbh-local.txt
comm -23 /tmp/vbh-remote.txt /tmp/vbh-local.txt   # remote-only
```

For remote-only branches, **if `HAS_GH_REMOTE=1`**, cross-ref `gh pr list --head <b>` to find:
- Open PRs by user (active work)
- Merged PRs where remote branch was never deleted (auto-delete-branches-on-merge wasn't enabled — see [K9095])
- Branches with no PR (true orphans — usually safe to delete via `gh api -X DELETE`)

If `HAS_GH_REMOTE=0`, leave remote-only branches in **needs-review** — list them in the report with last-commit date and author, and let the user decide. Don't try `glab`/`bb` substitutes silently; just defer.

**Never auto-delete remote branches.** Always ask. Remote deletion is high-blast-radius and irreversible without admin access.

## Output Report

Produce a single structured report. Example:

```
# Branch Health Audit — <repo-name> — 2026-05-27

## Summary
- 8 branches → 3 auto-deleted (squash-merged), 2 need-review, 3 active
- 2 worktrees → 1 auto-pruned, 1 has uncommitted changes (ask)
- 4 stashes → 2 rescue-candidates, 2 needs-review
- 17 untracked → 12 gitignore-suggestions, 3 commit-candidates, 0 secret-leaks
- 1 ignored-but-tracked: build/output.log

## Auto-Actions Taken
- DELETED branch `feat/old-thing` (squash-merged into main 2w ago)
- DELETED branch `chore/cleanup` ([gone] upstream)
- PRUNED worktree `.claude/worktrees/abandoned-2026-04-12` (path deleted)

## Needs Your Decision
1. Branch `wip/big-experiment` — 47 ahead, 312 behind. Revival hazard.
   → Rebase / cherry-pick / delete?
2. Worktree `.claude/worktrees/active-feature` — uncommitted: 3 files
   → Show diff / stash-WIP / leave alone?
3. Stash@{2} — "WIP on deleted-branch-foo: …" — branch gone
   → Pop into new branch / drop / leave?
4. Untracked `notes/design-v2.md` (340 lines, modified yesterday)
   → Commit / stash / .gitignore?

## Recommended .gitignore additions
build/
*.log
.idea/workspace.xml
```

## Safety Rules

1. **Never damage another agent's *in-progress* work (highest priority).** Cleaning up OLD, verified-merged agent worktrees/branches is fine and expected. The guard is **liveness, not merge status**: never remove a worktree (or delete its branch) that shows a live-session signal — uncommitted/untracked changes, a `locked` flag, or a commit within the last ~24h — *even when it's squash-merged into `main`*, because a peer may be mid-task in that checkout. Verify merged AND idle before auto-removing; when borderline, report and ask. This rule overrides the "auto-act on high-confidence cleanups" default.
2. **Never `git push --delete` without explicit confirmation.** Origin-side deletes are high-blast-radius.
3. **Never auto-drop stashes.** Even confident matches need confirmation. Stash loss is unrecoverable.
4. **Never touch locked worktrees.** Even if they look stale — `locked` is an intentional signal.
5. **Never auto-add files matching secret patterns to `.gitignore`.** Flag them as leak-risk; the right answer is removal + secret scan, not silencing.
6. **Never operate on the currently-checked-out branch.** Skip with explanation.
7. **In `--workspace` mode, never recurse into vendored snapshots** — skip any directory containing `.subtree-source` (those are upstream-managed; their hygiene is upstream's problem).
8. **Match the user's "explicit-push-approval" pattern.** Even after this skill finishes, do not push anything to origin without a fresh `AskUserQuestion`.

## Workspace Mode (`--workspace`)

When sweeping multiple nested repos:

```bash
# From workspace root, iterate nested git repos
for repo in $(find . -maxdepth 3 -name '.git' -type d \
              -not -path '*/.claude/worktrees/*' \
              -not -path '*/node_modules/*' \
              | xargs -n1 dirname); do
  echo "=== $repo ==="
  # Skip vendored snapshots
  [[ -f "$repo/.subtree-source" ]] && { echo "skipped (vendored)"; continue; }
  # Run §1–§7 per repo
done
```

Aggregate the per-repo reports into a workspace summary. Cap autonomous actions at — say — 20 deletions total per workspace run; above that, switch to ask-mode for each.

## Tier 2 Checks (run on request, not by default)

- **Submodule drift** — `git submodule status` prefix flags (`-` uninit, `+` commit differs, `U` conflict).
- **Repo bloat** — `git count-objects -vH`; flag `size-pack > 1G` or `size-garbage > 100M`. Suggest `git gc` (not `--aggressive` — rarely worth it).
- **Disabled hooks** — repo has `.pre-commit-config.yaml` or `.husky/` but `core.hooksPath` is set elsewhere or `.git/hooks/` is sample-only.
- **Worktrees that match a merged PR** — `gh pr list --state merged --head <branch>` cross-reference; common "forgot to clean up after PR landed."

These are gated behind `--deep` because they're slower and more likely to produce noise.

## What This Skill Does NOT Do

- **No `git fsck` dangling-blob audit.** Auto-cleaned by `git gc` after 90 days; surfacing SHAs is noise unless chasing corruption.
- **No reflog cleanup suggestions.** Auto-expires; manual cleanup risks losing recovery options.
- **No history rewriting / BFG.** Out of scope. Refer user to `BFG repo-cleaner` if individual blobs >50MB are the problem.
- **No secret remediation.** This skill flags leak-risk untracked files but does not scan history or remove from past commits. Use `git-secrets` / TruffleHog / dedicated tools.

## Companions

| Need | Skill |
|---|---|
| Finish one specific branch (merge / PR / cleanup) | `/finishing-a-development-branch` |
| Read-only history analysis (churn, bus factor) | `/git-forensics` |
| Set up worktree for new work | `/using-git-worktrees` |
| Multi-step migration / refactor workflow | `/git-workflow` |
| Repo-level folder restructure / deduplication | `/repository-organization` |
| Dead-code cleanup inside source files | `/code-cleanup` |

## Sources

- [not-an-aardvark/git-delete-squashed](https://github.com/not-an-aardvark/git-delete-squashed) — squash-merge detection
- [seachicken/gh-poi](https://github.com/seachicken/gh-poi) — safer alternative to `gh-clean-branches`; reference for disposition logic
- [foriequal0/git-trim](https://github.com/foriequal0/git-trim) — Rust impl of similar audit; useful prior art
- [Adam Johnson: cleaning up squash-merged branches](https://adamj.eu/tech/2022/10/30/git-how-to-clean-up-squash-merged-branches/)
- [git-worktree porcelain output](https://git-scm.com/docs/git-worktree)
- [git-ls-files exclude-standard](https://git-scm.com/docs/git-ls-files)
- [cli/cli#8515 — ghost remote refs after `gh pr merge -d`](https://github.com/cli/cli/issues/8515)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
