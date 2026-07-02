---
name: pr-workflow
description: "Use when managing the full PR lifecycle autonomously — pre-PR validation, status polling, bot-feedback handling, and merge gating on mergeable_state. Do NOT use for single-file PRs (use /create-pr), responding to specific review comments (use /address-pr-feedback), or general gh-CLI operations like triage/releases (use /github-ops). Requires GitHub."
disable-model-invocation: true
last-reviewed: 2026-05-27
---
# PR Workflow Management

End-to-end PR lifecycle: pre-PR checks, create, monitor, address bot feedback, merge only when `mergeable_state: "clean"`.

**CRITICAL:** `mergeable: true` only means "no git conflicts". Merge gating must use `mergeable_state == "clean"`. See [references/pr-workflow.md](references/pr-workflow.md#mergeable-vs-mergeable_state).

## When to Use

| Use this skill | Use instead |
|----------------|-------------|
| Multi-file PR with CI + bot loop | `/create-pr` for single-file trivial PRs |
| Autonomous monitor-and-fix until clean | `/address-pr-feedback` for one-shot reply to specific review comments |
| Full lifecycle (create through merge) | `/github-ops` for triage, releases, issue ops |
| GitHub | — (skip if not GitHub) |

**Do NOT use when:** PR already merged, you only need to push a commit, or the task is a single targeted comment reply.

## Core Directive

**Pre-PR checks → Create PR → Monitor every 30–60s → Address bot/CI feedback → Merge only when `mergeable_state: "clean"`.**

## Phase 1 — Pre-PR Checks

Run locally before `gh pr create`. All must pass:

1. **Compile / typecheck** — `sbt compile` / `npm run typecheck` / `mypy .` / `go build ./...`
2. **Lint / format** — `sbt scalafmtCheck` / `npm run lint` / `ruff check .` / `golangci-lint run`
3. **Tests** — `sbt test` / `npm test` / `pytest` / `go test ./...`
4. **Secrets scan** — `git secrets --scan` (or trufflehog / `npm audit` / `safety check`)
5. **Branch sanity** — `git branch --show-current` is not `main`/`master`

Full command matrix and template lookup: [references/pr-workflow.md § Pre-PR checks](references/pr-workflow.md#pre-pr-checks-multi-stack).

## Phase 2 — Create PR

```bash
gh pr create \
  --title "feat: <short summary>" \
  --body "$(cat <<'EOF'
## What
<one-line>

## Why
<motivation, links>

## How
<implementation notes>

## Testing
<verification>

Closes #<issue>
EOF
)"
```

Use repo's `.github/pull_request_template.md` if present. Full template: [references/pr-workflow.md § PR description template](references/pr-workflow.md#pr-description-template).

## Phase 3 — Monitor (Autonomous Loop)

Poll every 30–60 seconds:

```bash
# State (the only field that gates merge)
gh pr view <pr> --json mergeableState -q .mergeableState

# Bot comments
gh pr view <pr> --json comments \
  -q '.comments[] | select(.author.type == "Bot")'

# CI checks
gh pr checks <pr>
```

For each iteration:
1. If `mergeable_state == "clean"` → go to Phase 5.
2. If new bot comments → fix → commit → push.
3. If CI failed → diagnose (flaky vs real) → fix or `gh pr checks <pr> --rerun-failed`.
4. Wait 30–60s, repeat.

State-field semantics and bot-signal taxonomy: [references/pr-workflow.md § mergeable vs mergeable_state](references/pr-workflow.md#mergeable-vs-mergeable_state) and [§ Bot feedback handling](references/pr-workflow.md#bot-feedback-handling).

## Phase 4 — Address Feedback

| Source | Action |
|--------|--------|
| **Bot comment** | Fix the flagged issue; push; let CI re-validate. Address every one — they encode org policy. |
| **Review comment** | Reply, fix, mark thread resolved. Use `/address-pr-feedback` if it's a structured review pass. |
| **CI failure (real)** | Reproduce locally, fix, push. |
| **CI failure (flaky)** | `gh pr checks <pr> --rerun-failed` — only after confirming flakiness. |

## Phase 5 — Merge

Merge **only** when all of:

- `mergeable_state: "clean"`
- All required checks green
- Zero unresolved review threads
- Required approvals obtained

```bash
gh pr merge <pr> --squash --delete-branch
```

Strategy table (squash vs merge vs rebase): [references/pr-workflow.md § Merge strategies](references/pr-workflow.md#merge-strategies).

## Workflow Diagram

```
Pre-PR checks  →  gh pr create  →  ┌─ Monitor (30–60s) ─┐
                                   │  mergeable_state?  │
                                   │  bot comments?     │
                                   │  CI checks?        │
                                   └──┬─────────────┬───┘
                                      │ not clean   │ clean
                                      ▼             ▼
                                   Fix + push    gh pr merge
                                      │
                                      └─→ loop
```

## Integration

- `/git-workflow` — clean commit history feeding into the PR
- `/tdd-workflow` — tests written before code (Phase 1 will then pass)
- `/best-practices-enforcement` — language-rule gate before push
- `/create-pr` — single-file trivial PRs (use that, not this)
- `/address-pr-feedback` — focused review-comment reply (use that for that subtask)
- `/github-ops` — issue triage, releases, repo admin (different scope)

## Common Pitfalls

- **Merging on `mergeable: true`** — gates on conflict, not checks. Use `mergeable_state: "clean"`.
- **Ignoring bot comments** — they encode org policy. Fix or post a justified dismissal.
- **No polling** — PR stalls; user has to babysit. Always loop.
- **Skipping Phase 1** — CI catches the same issues slower and more expensively.
- **Auto-rerunning red checks** — only rerun if you've confirmed flakiness; otherwise fix.

Full pitfalls + handling table: [references/pr-workflow.md § Common pitfalls](references/pr-workflow.md#common-pitfalls).

## Success Criteria

- Phase 1 checks pass locally before `gh pr create`
- PR opens with complete description
- Loop drives `mergeable_state` to `clean` without human prodding
- Every bot comment addressed or justified
- PR merged with `--squash --delete-branch` (or repo-policy strategy)

## Remember

> `mergeable_state: "clean"` is the only merge gate. `mergeable: true` is not.

> Bot comments are usually right. Address every one.

> Poll continuously — don't let the PR wait on you.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
