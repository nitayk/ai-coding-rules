---
name: e2e
description: >-
  End-to-end development workflow — from raw idea to merged PR in a single
  invocation. Orchestrates specialized subagent roles through 11 phases:
  intake, research, design, planning, worktree setup, parallel execution,
  quality gates, code review, verification, delivery, and memory-driven
  learning.
  Use whenever the user provides a feature idea, ticket, or says "develop
  this", "build this end to end", or invokes /e2e. Also triggers on a
  pasted Jira/GitHub issue expecting the full lifecycle. Use for
  multi-step work spanning multiple files or requiring design decisions.
  Do NOT use for single-file fixes, config changes, or tasks where the
  user names a specific skill.
---

# E2E — End-to-End Development Workflow

Take a raw idea and deliver a merged PR. One command, eleven phases, fully
orchestrated. Specialized subagent roles handle each phase — you stay in
the driver's seat.

**Announce at start:** "Starting E2E development workflow. Let me refine your
idea, plan the work, execute it, and deliver a PR."

## How It Works

```
  YOUR IDEA (rough notes, ticket, screenshot, conversation)
       │
       ▼
  Phase 0: INTAKE ──────── Product Analyst (sonnet)
  Phase 1: RESEARCH ────── Product Analyst (sonnet)
  Phase 2: DESIGN ─────── Architect (opus) + optional /council
  Phase 3: PLANNING ────── Architect (opus)
  Phase 4: SETUP ────────── (mechanical — haiku)
  Phase 5: EXECUTION ───── Engineer subagents (per-task)
  Phase 6: QUALITY GATES ─ Simplifier + Security + Standards (sonnet)
  Phase 7: REVIEW ──────── Code Reviewer (opus)
  Phase 8: VERIFICATION ── QA / Sentinel (sonnet)
  Phase 9: DELIVERY ────── (mechanical — haiku)
  Phase 10: LEARN ──────── (mechanical — haiku)
```

## Roles

Each role maps to a configured `subagent_type` when running on Claude
Code. On Cursor / Copilot fall back to a generic agent with the role's
responsibility brief in the prompt.

| Role | Subagent type | Model | Responsibility |
|------|---------------|-------|----------------|
| **Product Analyst** | `general-purpose` | sonnet | Turn raw idea into spec. Identify gaps. Ask "why" and "for whom" |
| **Architect** | `architect` | opus | System design, API contracts, trade-offs. Challenge assumptions |
| **Code Architect** | `code-architect` | sonnet | Implementation blueprint from architecture decisions |
| **Engineer** | (dispatched by `/subagent-driven-development`) | per-task | Write code, follow TDD, commit. One task, focused context |
| **Security Reviewer** | `security-reviewer` | sonnet | OWASP, secrets, injection, auth. Read-only in this skill (instruct via prompt) |
| **Simplifier** | `code-simplifier` | sonnet | Code clarity, DRY, complexity reduction. Preserves behavior exactly |
| **Code Reviewer** | `code-reviewer` | sonnet → override to opus | Requirements coverage, readability, edge cases. Never writes code |
| **QA / Sentinel** | `verifier` | haiku | Validate acceptance criteria, run tests, evidence-before-claims |
| **Test Runner** | `test-runner` | haiku | Execute test suites, analyze failures (use inside QA when iterating) |
| **Code Explorer** | `code-explorer` | sonnet | Trace execution paths, map dependencies (Phase 1 / Phase 3) |
| **Git Workflow** | `git-workflow-specialist` | sonnet | Phase 4 worktree setup, Phase 9 commit/branch hygiene |
| **Skeptic** | `general-purpose` | opus | Challenge premises, find failure modes. Only when ambiguity detected |

**Key rules:**
- Same agent never writes AND reviews its own code
- Reviewers and QA are read-only in this skill — they report, they don't
  fix. Even if the agent type's tool list includes Write/Edit (e.g.
  `security-reviewer`), instruct it explicitly to report findings only.
- Engineers get focused context per task — not the full session history
- Escalate when stuck, don't guess
- When the role table model differs from the agent type's default
  (e.g. `code-reviewer` defaults to sonnet but this skill prefers opus),
  pass `model: opus` to the Agent tool override

## Classification & Skip-Logic

Auto-classify the task in Phase 0. Present as numbered options and wait for
the user's choice before proceeding.

| Classification | Default skips | Rationale |
|----------------|---------------|-----------|
| **feature** | None | Full pipeline |
| **bugfix** | Research, Design | Jump to planning (codebase scan in Step 0) |
| **refactor** | Research, Design | Structure is known, jump to planning (codebase scan in Step 0) |
| **spike** | Quality Gates, Review. Delivery simplified (keep/discard only) | Exploratory — no PR expected |
| **hotfix** | Research, Design, Quality Gates | Emergency — minimal path to fix. Review skipped during initial fix — flag for follow-up review in Phase 10 (Learn) |
| **docs-only** | Research, Design, Quality Gates, Security | No code — Verification checks docs build/links |

User confirms or overrides. Choice saved as default for future runs.

## Phase 0: INTAKE & PROMPT OPTIMIZATION

**Role:** Product Analyst (sonnet)
**Announce:** "Phase 0: Intake — refining your idea."

### Step 1: Load context (silent)

1. Check `{MEMORY_DIR}/e2e/` (resolution in Cross-Phase Rules § Memory paths) for past defaults, feedback, saved answers
2. Read recent git log for active work context
3. Note project language, framework, and conventions from CLAUDE.md

### Step 2: Optimize the prompt

Invoke `/prompt-optimizer` on the raw input.

First run in this project:
> "First time running /e2e here. I'll ask more questions this time —
> your answers get saved so future runs are faster."

Repeat runs — load saved defaults and present as pre-selected:
> "Last time you chose [X]. Same choice, or change?"
If user confirms, skip the question. If they change, update the saved default.

### Step 3: Classify and propose skip-logic

See classification table above.

### Step 4: Create the phase tracker

Create task list with all active phases. Held in memory until Phase 4
persists it to disk (see Phase 4).

Status markers: `[ ] pending | [>] in_progress | [x] complete | [-] skipped`

### Step 5: Name the session

Invoke the Claude Code built-in `/rename` command with format
`e2e-<classification>-<topic-slug>` (e.g. `e2e-feature-rtb-bid-cache`).
Makes the session findable in history. `/rename` is a built-in command,
not a skill — outside Claude Code (Cursor, Copilot) skip this step
silently; do not log as a missing skill in Phase 10.

## Phase 1: RESEARCH

**Role:** Product Analyst (sonnet)
**Announce:** "Phase 1: Research — checking for existing solutions."

Invoke `/search-first` + `/documentation-lookup` (Context7). For
context-heavy research that risks blowing the budget, layer
`/iterative-retrieval` on top — refines the search progressively
instead of dumping all results into the orchestrator.

Output: research brief saved to session memory scratchpad.

**Skip when:** bugfix, refactor, hotfix, docs-only.

## Phase 2: DESIGN

**Role:** Architect — `architect` subagent (opus default)
**Announce:** "Phase 2: Design — exploring requirements and design."

Invoke `/brainstorming` for design exploration — run all checklist
items 1–8 (through user-reviews-written-spec). Stop before item 9 (the
transition to `/writing-plans`); the orchestrator handles planning in
Phase 3. **Blocking gate:** do not advance to Phase 3 until step 8
(user spec review) is complete and approved.

Invoke `/council` when the user expresses uncertainty between approaches,
or when approaches have fundamentally different trade-off profiles with no
dominant option. Council voices: Architect, Skeptic, Pragmatist, Critic.

For non-trivial architectural decisions (library/framework picks, key
patterns, data-model shape), invoke `/architecture-decision-records` to
capture the chosen approach and rejected alternatives as ADRs alongside
the design doc. Skip when there was a single viable approach.

Output: design document with acceptance criteria saved to
`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.

**Skip when:** bugfix, refactor, hotfix, docs-only.

## Phase 3: PLANNING

**Role:** Architect — `architect` (opus) for the plan structure;
`code-architect` (sonnet) for the implementation blueprint when ready
**Announce:** "Phase 3: Planning — creating implementation plan."

### Step 0: Codebase scan (always runs)

Dispatch a `code-explorer` subagent to scan the codebase for existing
patterns related to the task:

- grep/glob for existing patterns, conventions, similar implementations
- Read the target file(s) that will be modified
- Use `/git-forensics` to surface ownership, churn, and recent
  incidents on the affected files — knowing the file's history avoids
  re-breaking something that was just fixed
- Use `/iterative-retrieval` when the codebase is large enough that a
  one-shot scan would dump too much into context

When Research ran, this confirms known patterns. When Research was skipped,
this provides essential codebase context.

Invoke `/writing-plans`. Plan includes:
- Ordered tasks with dependencies
- Which tasks are independent (parallelizable)
- Verification steps per task
- Estimated complexity per task

Output: plan saved to `docs/superpowers/plans/YYYY-MM-DD-<topic>-plan.md`.

## Phase 4: SETUP

**Role:** `git-workflow-specialist` subagent (sonnet)
**Announce:** "Phase 4: Setup — creating isolated workspace."

Invoke `/using-git-worktrees`. Non-skippable — even spikes get a worktree.

Once the worktree exists, persist the phase tracker (created in Phase 0
Step 4) to `docs/superpowers/e2e-tracker.md` inside the worktree so
re-entry can resume from the last incomplete phase.

## Phase 5: EXECUTION

**Role:** Engineer subagents (model per-task complexity)
**Announce:** "Phase 5: Execution — implementing the plan."

**Pick one executor:**
- `/subagent-driven-development` (default) — dispatches one Engineer
  subagent per task with two-stage review (spec compliance, then code
  quality). Best when the plan has multiple independent tasks that can
  parallelize.
- `/executing-plans` — single-executor mode with review checkpoints.
  Best for tightly sequential plans where each task feeds the next, or
  when the plan is short enough that subagent dispatch overhead isn't
  worth it.

Default to `/subagent-driven-development` unless the plan is fully
sequential or has only 1–2 tasks.

**TDD discipline by classification:**
- `feature` — Engineers follow `/tdd-workflow` (red → green → refactor)
  unless the task is config-only or a one-line change.
- `bugfix` — Write the failing test that reproduces the bug *first*.
- `refactor` — Run the existing test suite before starting and after
  each change; behavior must be preserved.
- `hotfix`, `spike` — Skip TDD (speed and exploration first).

**Parallel execution:** Whenever the plan has 2+ independent tasks
running concurrently, follow `/dispatching-parallel-agents` (covers fan-
out patterns, result aggregation, and failure isolation). Before any
parallel dispatch, invoke `/multi-agent-branching` to verify branch
hygiene — each worktree on its own branch, no commits leaking to base.
Parallel engineers run with `isolation: worktree`.

**When an Engineer gets stuck:** dispatch a subagent with
`/systematic-debugging` instead of letting it flail.

**Context:** Use `/session-memory` to persist decisions between tasks,
especially when work spans multiple chats.

## Phase 6: QUALITY GATES — HARD GATE

**Announce:** "Phase 6: Quality gates — cleanup, security, best practices."

HARD GATE — see Cross-Phase Rules § Hard Gate Contract.

Run all three checks in **parallel** as subagents with clean context (no
pollution from execution phase). All are read-only except Simplifier.

1. **Simplifier** — `code-simplifier` subagent:
   On Claude Code, invoke `/simplify` (built-in command, always
   available; broader than the skill — reuse + quality + efficiency +
   fixes via three parallel review subagents). On Cursor / Copilot / other
   tools, fall back to the `/code-simplification` skill in this repo.
   If neither is available, note in Phase 10 and skip this single gate
   (the other two still run).

2. **Security Reviewer** — `security-reviewer` subagent (instruct
   read-only despite its Write/Edit tools):
   Invoke `/security-review`. Scan changed files for vulnerabilities.

3. **Best Practices** — `code-reviewer` subagent (sonnet default,
   read-only):
   Invoke `/best-practices-enforcement`. Validate coding standards.

If any gate finds **critical or high-severity** issues → fix before
proceeding to Phase 7. Medium and lower findings → noted for Phase 7
reviewer or for follow-up tracked explicitly in the PR description.

**Skip when:** spike, hotfix, docs-only — only these classifications.

## Phase 7: REVIEW — HARD GATE

**Role:** Code Reviewer — `code-reviewer` subagent with `model: opus`
override (the agent type defaults to sonnet; this skill prefers opus
for review depth)
**Announce:** "Phase 7: Review — dispatching code reviewer."

HARD GATE — see Cross-Phase Rules § Hard Gate Contract. The author of
code is the worst reviewer of it; an independent reviewer subagent is
non-optional except for the explicitly-skipped classifications.

Invoke `/requesting-code-review` to package the review request (diff +
quality gate findings — not the full execution history). The reviewer
subagent itself follows `/code-review-excellence` for review
methodology: prioritize bugs and design issues over style nits, give
constructive concrete feedback, separate must-fix from nice-to-have.

If reviewer finds issues → fix them in the same PR before merge → reviewer
re-reviews. Do not skip re-review. If the reviewer's findings are
non-actionable (out-of-scope nitpicks, disagreement on style), explicitly
acknowledge and document the decision in the PR description rather than
silently ignoring.

**Skip when:** spike, hotfix — only these classifications.

## Phase 8: VERIFICATION

**Role:** QA / Sentinel — `verifier` subagent (haiku, skeptical
validator). For test execution and failure analysis specifically,
dispatch `test-runner` (haiku) inside the verifier's flow.
**Announce:** "Phase 8: Verification — running evidence checks."

Invoke `/verification-before-completion`. Hard gate — no success claims
without evidence:

- Run test suite — all must pass (skip if classification is `docs-only`
  and no tests apply)
- Run build — must succeed
- Run linters/formatters if configured
- For `docs-only`: verify docs build and links resolve
- Present evidence (actual output) before proceeding

If anything fails → fix and re-verify.

## Phase 9: DELIVERY

**Role:** `git-workflow-specialist` subagent (sonnet)
**Announce:** "Phase 9: Delivery — finalizing the work."

Invoke `/finishing-a-development-branch`. Present delivery options as a
numbered list and wait for the user's choice:

- **Create PR** — invoke `/create-pr` to open the PR with summary,
  test plan, link to design doc and any captured ADRs
- **Merge to main** — if merge rights and CI passes
- **Keep branch** — for continued work later
- **Discard** — only for `spike` classification when the exploration
  didn't pan out

For **spike** classification: only show "Keep branch" and "Discard"
options. For **hotfix** that fails to deliver a working fix, use the
Error handling path in Cross-Phase Rules — not Discard.

## Phase 10: LEARN

**Announce:** "Phase 10: Learn — saving what I learned."

Save to `{MEMORY_DIR}/e2e/` (resolution in Cross-Phase Rules § Memory paths):

1. **Feedback** — What the user corrected. Phase overrides, approach
   corrections. Prefix with `e2e:feedback:`.

2. **Defaults** — User responses to structured questions from this run.
   Overwrite existing defaults on the same topic. Prefix with `e2e:default:`.

3. **Decisions** — Architecture choices, library selections, patterns.
   Prefix with `e2e:decision:`.

4. **Skip-logic** — If user changed proposed skips, save their preference
   for this classification type. Prefix with `e2e:skip:`.

5. **Hotfix follow-up review** — If classification was `hotfix` (Phase 7
   review was skipped during the emergency fix), record a follow-up
   review obligation: file path, brief description, target branch.
   Surface it the next time the user runs `/e2e` in this repo, or in
   the PR description if the hotfix is still under review. Prefix with
   `e2e:followup:review:`.

Format: one memory file per concept, Markdown with frontmatter.
Deduplicate: overwrite existing memories on the same topic, don't append.

Tell the user: "Saved learnings from this run. Future /e2e invocations
will be faster."

## Cross-Phase Rules

### Hard Gate Contract

A phase marked **HARD GATE** cannot be silently skipped, even in auto
mode. Skip is allowed only when:
- The classification table lists this phase under "Default skips" for
  the current classification, OR
- The user states an explicit override in the conversation
  (e.g. "skip the gates", "this is small enough, push it").

"The diff looks small," "the tests pass," "we're in auto mode" are NOT
valid skip reasons. Past sessions have skipped hard gates under these
rationalizations and shipped fixable bugs that the gates would have
caught.

### Memory paths

`{MEMORY_DIR}/e2e/` resolves via `/session-memory`:
`.claude/memory/e2e/` on Claude Code, `.cursor/memory/e2e/` on Cursor.
Phases 0 and 10 reference this location.

### Structured questions everywhere

All clarification uses structured numbered options — never dump multiple
questions as plain text. Present one question at a time, wait for answer
before next question.

### Phase announcements

One line: `"Phase N: NAME — [role] using /skill-name"`
Keep announcements short. Substance over ceremony.

### Error handling

If any phase fails:
1. Announce which phase failed and why
2. Present numbered options and wait for choice:
   - [1] Retry with additional context
   - [2] Skip this phase, continue workflow
   - [3] Abort workflow
   - [4] Drop to manual mode (continue without e2e orchestration)
3. Save failure context to memory for future avoidance

### Missing sub-skills

If a sub-skill referenced by a phase is not installed:
1. Announce: "Skill /X not available. Running Phase N inline."
2. Execute the phase's intent directly without the skill's workflow
3. Note the missing skill in Phase 10 so user can install it

### Re-entry

Phase tracker persists to `docs/superpowers/e2e-tracker.md`. On next
`/e2e` invocation in the same worktree, check for this file and offer
to resume from the last incomplete phase. For Phase 5, check completed
tasks in the tracker and resume from the first incomplete task, not from
the beginning of the phase.

### Context budget — conditional compaction trigger

Between phases, invoke `/strategic-compact` when remaining context drops
below ~20% of the window — concretely, **< 200K remaining on a 1M
session** or **< 40K remaining on a 200K session**. The next phase needs
room for a subagent dispatch + your synthesis + the user-facing summary;
running tighter risks truncated tool results and degraded reasoning.

Natural compaction checkpoints (large outputs land here):
- After Phase 1 (Research) and Phase 5 (Execution)
- **Before Phase 6 and Phase 7** — both dispatch subagents whose findings
  you must reason over with clear context
- After any unplanned deep-dive (many file reads, large bash dumps)

If you can't measure context precisely, compact preemptively past Phase
5 or after reading >5 large files in a row. Don't wait for response
quality to degrade — by then the summary you save will already be lossy.

### Cost awareness

A full e2e run dispatches 10+ subagents. For cost-sensitive environments,
consider running individual phases manually.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
