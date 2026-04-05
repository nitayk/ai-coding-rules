---
name: mass-repo-orchestration
description: "Use when applying the same mechanical change across many repositories (dozens+), tracking bulk PRs, or resuming migration work across sessions—e.g. config/tooling updates, explicit hooks replacing implicit platform behavior, org-wide renovate patterns. Use with /writing-plans, /executing-plans, /git-workflow, /agent-token-optimization. Do NOT use for moving one service between two repos (/service-migration, /code-migration) or a single-repo feature build."
disable-model-invocation: true
---

# Mass repository orchestration

Orchestrate **one playbook** across **many client repositories**: version-controlled plans, resumable progress, human gates before publish, and fallbacks when you lack write access.

*Credits: Inspired by the excellent talk and learnings from Théo Penavaire, Miro Brodlova, Justinas, and Harald at Unity. ([Watch the Zoom recording](https://unity3d.zoom.us/rec/play/6cvv-txtZzflo4uPWHWBVxAk6AjtYhkNwhA0m00R05XiyMjnTOk_Q0Zx3Q7K3sRYks0LaN4wHQQopdS1.AstNS71M0zSL2onE))*

## When to use

**APPLY WHEN:**

- The same change must land in many repos (bulk PRs, shared config, org-wide tooling).
- Work spans **multiple agent sessions** and must be **resumed** without redoing discovery.
- You need a **single source of truth** for “what good looks like” and a **checklist of targets**.

**DO NOT USE WHEN:**

- **One service**, repo A → repo B, with graph-driven analysis → `/service-migration` + `/service-breakdown` (and `/code-migration` where that skill applies).
- **Single-repo** implementation from a spec → `/writing-plans` + `/executing-plans` only.

## Principles (field-tested patterns)

1. **Dedicated orchestration repo** — Track prompts, plans, progress, and owner comms in git. The migration itself is a product; treat it like one.
2. **Plan-only first session** — In Plan mode (or equivalent), produce **artifacts only**: orchestrator prompt, full plan, migration “golden” doc — **do not** start touching target repos until those exist and are committed.
3. **Prefer skills over a pile of ad-hoc docs** — One skill (or a small set) plus `progress.md` beats many one-off markdown files that compete for attention.
4. **Human checkpoint before publish** — Pause before `git commit` / `git push` / opening PRs on each target until a human reviews the high-level diff and anything unusual vs prior repos.
5. **Resumable state** — After each completed (or attempted) repo, update a **single progress file** (e.g. `progress.md`): repo, status, blockers, links to PRs or diffs.

## Recommended artifact layout (orchestration repo)

| Artifact | Role |
|----------|------|
| `orchestrator-prompt.md` | Short prompt you paste each session; points at plan + progress + SoT. |
| `orchestrator-plan.md` (or under `docs/plans/`) | Full ordered checklist and edge cases. |
| `migration.md` (or `docs/migration.md`) | **Source of truth** for exact config/script shapes (examples, diffs). |
| `repos.md` / `prs.md` | Inventory: org/repo list, PR links, access notes. |
| `progress.md` | Append-only or dated sections: per-repo outcome, resumed across sessions. |
| Harness settings | e.g. allowed/blocked commands; document what you intentionally allow. |

Adjust paths to your org; **names matter less than having these roles covered**.

## Execution loop (per target repo)

1. Clone / worktree; apply playbook from `migration.md`.
2. Run local verification (tests, lint) as appropriate.
3. **Stop at review checkpoint** — Summarize changes vs previous repos; flag surprises.
4. After human approval: commit, push, open PR (or hand off — see below).

### Agent Execution Directives
When an agent is executing this playbook, it MUST follow these rules to reduce human approval fatigue:
- **NO chained commands**: Execute one shell command per tool call (do NOT chain with `&&`, `;`, `||`). Granular commands allow humans to safely whitelist read-only commands (like `ls`, `find`) without accidentally greenlighting destructive chained commands.
- **Explicit Checkpoints**: At the review checkpoint, explicitly list the high-level changes made to the current repo. Call out any deviations or unusual findings compared to prior migrations.
- **Fail Gracefully**: If a push or PR creation fails due to missing permissions, do not loop endlessly. Dump the diff, record the blocker in `progress.md`, and move on to the next repo.

## Feedback and process improvement

After each repo (or every N repos):

- **Retrospective**: bottlenecks, repeated permission friction, clumsy commands — feed back into `orchestrator-plan.md`.
- **Permissions (Claude Code / similar)**: optionally ask the agent to list commands it had to ask about and whether each belongs on an allowlist; **you** decide (chained commands often bypass per-command allowances—prefer **single, explicit commands** when documenting patterns).

## Anti-fragile: no write access or blocked remote

- Capture **`git diff` / patch** to a file; link or send to the repo owner with the migration SoT.
- Record in `progress.md` and `repos.md` — don’t lose the work in chat history.
- Update the plan when a new failure mode appears (access denied, missing template, etc.).

## Cost and model choice

- Strongest model / extended reasoning for **planning** and the **first few pilot repos** (reduce systematic mistakes).
- After the playbook stabilizes, **step down** model tier for repetitive applications → see **`/agent-token-optimization`**.
- Operational work (permissions, reviewers, access requests) still sits with humans; agents shift effort from typing to **orchestration and babysitting** — plan for that time.

## Related skills

| Need | Skill |
|------|--------|
| Plan shape, bite-sized tasks | `/writing-plans` |
| Execute a written plan with checkpoints | `/executing-plans` |
| Branch hygiene on long efforts | `/git-workflow` |
| Model tiering and context cost | `/agent-token-optimization` |
| Parallel isolated clones | `/using-git-worktrees`, `/dispatching-parallel-agents` |
| Session scratchpad (optional) | `/session-memory` |
| Ship gate — run checks before “done” | `/verification-before-completion` |

## Further reading (external)

- [Anthropic: Claude Code auto mode](https://www.anthropic.com/engineering/claude-code-auto-mode) — may reduce approval fatigue for safe read-only exploration; still gate destructive actions manually.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
