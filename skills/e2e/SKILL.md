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
last-reviewed: 2026-06-02
---

# E2E — End-to-End Development Workflow

Take a raw idea and deliver a merged PR. One command, eleven phases, fully
orchestrated. Specialized subagent roles handle each phase — you stay in
the driver's seat.

**Announce at start:** "Starting E2E development workflow. Let me refine your
idea, plan the work, execute it, and deliver a PR."

> Scoped to delivering **one change** (idea→PR). For a whole-repo tech-debt /
> codebase-health audit — ranked, file-cited, standalone `TECH_DEBT_AUDIT.md` —
> use `/tech-debt-audit` instead. It's a separate user-invoked mode, not an e2e
> phase (Phase 6 gates the *diff*; the audit assesses the *whole repo*).

## How It Works

```
  IDEA → 0 INTAKE → 1 RESEARCH → 2 DESIGN → 3 PLANNING → 4 SETUP →
         5 EXECUTION → 6 QUALITY GATES → 7 REVIEW → 8 VERIFICATION →
         9 DELIVERY → 10 LEARN → MERGED PR
```

Roles + model per phase: see Roles table below.

## Roles

Each role maps to a configured `subagent_type` on Claude Code. On
harnesses without typed subagents, fall back to a generic agent with the
role's responsibility brief in the prompt.

| Role | Subagent type | Model | Responsibility |
|------|---------------|-------|----------------|
| **Product Analyst** | `general-purpose` | sonnet | Turn raw idea into spec. Identify gaps. Ask "why" and "for whom" |
| **Architect** | `architect` | opus | System design, API contracts, trade-offs. Challenge assumptions |
| **Code Architect** | `code-architect` | sonnet | Implementation blueprint from architecture decisions |
| **Engineer** | (dispatched by `/subagent-driven-development`) | per-task | Write code, follow TDD, commit. One task, focused context |
| **Security Reviewer** | `security-reviewer` | sonnet → opus on auth/crypto/payment/allowlist diffs | OWASP, secrets, injection, auth. Read-only in this skill (instruct via prompt). Tier up when Phase 8 empirical-check categories appear in changed files. |
| **Code Cleanup** | `code-cleanup` (or `general-purpose` fallback) | haiku | Mechanical removal of debug artifacts, dead imports, AI noise (Phase 6 gate 1) |
| **Simplifier** | `code-simplifier` | sonnet | Code clarity, DRY, complexity reduction. Preserves behavior exactly |
| **Code Reviewer** | `code-reviewer` | sonnet → override to opus | Requirements coverage, readability, edge cases. Never writes code |
| **QA / Sentinel** | `verifier` | sonnet (haiku-only for nested test-runner) | Skeptical validator: acceptance criteria, empirical-not-static checks, restore-semantics, smoke-test substitution decisions. Sonnet because every Phase 8 rule requires judgment haiku will fumble (PR #106 burned the team on exactly this). |
| **Test Runner** | `test-runner` | haiku | Execute test suites, parse failures. Pure mechanical — dispatched *inside* QA/Sentinel's flow when iterating |
| **Code Explorer** | `code-explorer` | sonnet → opus on cross-service stack | Trace execution paths, map dependencies (Phase 1 / Phase 3). Tier up when the scan spans a cross-service call graph — sonnet routinely misses transitive call paths there. |
| **Git Workflow** | `git-workflow-specialist` | haiku for Phase 4 (mechanical setup); sonnet for Phase 9 (delivery decisions) | Phase 4 = `git worktree add` + file moves + tracker write (zero design judgment). Phase 9 = commit-message hard rule + delivery-hook decisions (judgment work — haiku will write `Co-Authored-By` lines) |
| **Skeptic** | `general-purpose` | opus | Challenge premises, find failure modes. Only when ambiguity detected |

**Key rules:**
- Same agent never writes AND reviews its own code
- Reviewers and QA are read-only in this skill — they report, they don't
  fix. Even if the agent type's tool list includes Write/Edit (e.g.
  `security-reviewer`), instruct it explicitly to report findings only.
- Engineers get focused context per task — not the full session history
- Escalate when stuck, don't guess
- **Never invent a `subagent_type` from a skill name.** Skills (e.g.
  `/deep-research`, `/security-review`, `/tech-debt-audit`) are
  invoked with the Skill tool / slash command in the current session —
  they are NOT sub-agents. Do not construct a namespaced agent type like
  `<plugin>:some-skill` (plugin name + skill name) and dispatch
  it via the Task (Agent) tool: no agent is registered under that name, so
  it fails with `Agent type '<plugin>:some-skill' not found`.
  When a phase needs a skill's capability inside an isolated sub-agent,
  dispatch a generic agent (`general-purpose`) and instruct it to invoke
  the skill.

## Classification & Skip-Logic

Auto-classify the task in Phase 0. Present as numbered options and wait for
the user's choice before proceeding.

| Classification | Default skips | Rationale |
|----------------|---------------|-----------|
| **feature** | None | Full pipeline |
| **bugfix** | Research, Design | Jump to planning (codebase scan in Step 0) |
| **refactor** | Research, Design | Structure is known, jump to planning (codebase scan in Step 0) |
| **spike** | Research, Design, Quality Gates, Review. Delivery simplified (keep/discard only) | Exploratory — no PR expected, code is throwaway |
| **hotfix** | Research, Design | Emergency — minimal pre-work, but quality gates + review still run (hotfix code SHIPS to prod under pressure — the gates matter MORE not less). Use the Hard Gate Contract override only for true seconds-count emergencies. |
| **docs-only** | Research, Design, Quality Gates, Security | No code — Verification checks docs build/links |
| **migration** | Research (use `/codebase-onboarding` instead), Design (replaced by a codebase-onboarding + migration-planning pass) | Repo-to-repo or service-to-service moves where preserving behavior + minimal diff matter more than design exploration |

User confirms or overrides. Choice saved as default for future runs.

> **Hotfix HIGH-escalation (one-line rule):** if any P6 gate returns a
> HIGH-severity finding on a hotfix branch, P7 review is non-negotiable
> regardless of time pressure. Shipping a HIGH-severity vulnerability
> through an unreviewed hotfix is worse than the original bug staying
> unfixed for one more review cycle.
> <!-- Maintainer note: this one-liner replaces the Stage E per-gate skip matrix (PR #51), reverted in the spirit of "all gates run by default; user explicitly overrides via Hard Gate Contract when seconds count". The matrix paid real cognitive complexity to save 5–10 min on hotfix runs that rarely need that speed. -->

## Phase 0: INTAKE & PROMPT OPTIMIZATION

**Role:** Product Analyst (sonnet)
**Announce:** "Phase 0: Intake — refining your idea."

### Step 1: Load context (silent)

1. Check `{MEMORY_DIR}/e2e/` (resolution in Cross-Phase Rules § Memory paths) for past defaults, feedback, saved answers
2. Read recent git log for active work context
3. Note project language, framework, and conventions from CLAUDE.md
4. Invoke `/using-superpowers` silently to refresh which skills are
   available in the active environment — avoids missing-skill
   surprises in later phases
5. **Issue-number entry path:** if the input matches `#\d+` or
   `<repo>#\d+`, invoke `/fix-issue` first to fetch the GitHub issue
   body + comments and use that as the task description

### Step 1.5: Pre-flight workspace check

Run `git status`. If the workspace has uncommitted changes unrelated to
the new task, surface a structured question with **"Ship pending
changes as a separate PR first (Recommended)"** as the default option.
Don't bundle unrelated work — reviewers shouldn't have to mentally
separate scopes. Skip the question only if the pending changes are
clearly part of the task being started.
<!-- Maintainer note: rule originated from operator memory `e2e/default_pending_changes.md`. -->

### Step 2: Optimize the prompt

Invoke `/prompt-optimizer` on the raw input.

First run in this project:
> "First time running /e2e here. I'll ask more questions this time —
> your answers get saved so future runs are faster."

Repeat runs — load saved defaults and present as pre-selected:
> "Last time you chose [X]. Same choice, or change?"
If user confirms, skip the question. If they change, update the saved default.

### Step 2.5: Generate PRD (raw-idea inputs only)

If the input is a raw idea (no ticket / spec link / acceptance
criteria), invoke `/prd-generation` and save the PRD into
`docs/superpowers/prds/` so it travels with the design doc.

### Step 3: Classify and propose skip-logic

See classification table above.

**Skip-Research+Design heuristic (refines `feature` classification):**
The default for `feature` is the FULL pipeline. Only propose skipping
Phase 1 (Research) and Phase 2 (Design) when ALL of:

- The prompt has explicit section headers like `Out of scope:`, `Design
  decisions:`, `Acceptance criteria:`, or `Open questions resolved:`,
  AND
- The change extends an existing codebase whose constraints are known.

A detailed *conversational* paragraph (no formal section headers) is
NOT enough to skip — the formality is the signal that design has
already happened out-of-band. Greenfield standalone products always get
the full pipeline regardless of how detailed the prompt is, because the
cost of bad architecture compounds and Phase 1 research often surfaces
critical pivots (e.g. competing-tool launches that reframe the work).
<!-- Maintainer note: rule originated from operator memories `e2e/default_classification.md`, `e2e/default_skip_research_design_when_context_provided.md`, `e2e/feedback_full_pipeline_on_raw_idea.md`. -->

**Stack sub-classification:** After picking the primary
classification (feature / bugfix / etc.), pick a stack tag that gates
the conditional skills downstream:

| Stack | Triggers / file patterns | Conditional skills enabled |
|-------|--------------------------|----------------------------|
| `langchain` | `langchain` import, `LangChain` in plan | `/framework-selection`, `/langchain-fundamentals`, `/langchain-middleware`, `/langchain-rag`, `/langchain-dependencies` |
| `langgraph` | `langgraph` import, `StateGraph`/`Send`/`interrupt()` in plan | `/framework-selection`, `/langgraph-fundamentals`, `/langgraph-persistence`, `/langgraph-human-in-the-loop` |
| `deep-agents` | `deepagents` import, `create_deep_agent()` in plan | `/framework-selection`, `/deep-agents-core`, `/deep-agents-memory`, `/deep-agents-orchestration` |
| `web-frontend` | `*.tsx`, `package.json` with React/Vite, `chat-ui/` path | `/frontend-design`, `/web-artifacts-builder`, `/webapp-testing` |
| `infra` | `Dockerfile`, K8s manifests, CI pipelines | `/docker-patterns` |
| `backend-go` | `go.mod`, `*.go` files | `/golang-testing` |
| `backend-scala` | `build.sbt`, `*.scala` files | `/scala-testing`, `/scala-dependency-hell`, `/scala-upgrade-agent` |
| `claude-api` | `import anthropic`, `@anthropic-ai/sdk`, Claude Messages API patterns | `/claude-api` |
| `rest-api` | new HTTP endpoints, `*Controller.scala`, `routes.go`, OpenAPI specs | `/api-design` |
| `generic` | None of the above | (no extra skills enabled) |

> **Skill availability footnote:** Stack-conditional skills are invoked
> *when available*. Some (e.g. `framework-selection`, `langchain-*`,
> `langgraph-*`, `deep-agents-*`) may live in **consumer project repos**
> (`.claude/skills/`) rather than this submodule. If
> the stack tag matches but the skill isn't installed in the active
> environment, follow the existing **Missing sub-skills** rule
> (announce, run intent inline, log in Phase 10) — do NOT block.

The stack tag is recorded in the phase tracker and re-used by Phase 2
(stack-gated `/framework-selection`) and informs Phase 5/6 subagent
scoping. Phase 3 `/task-breakdown` is gated on task count, NOT stack.

### Step 4: Create the phase tracker

Create task list with all active phases. Held in memory until Phase 4
persists it to disk (see Phase 4).

Status markers: `[ ] pending | [>] in_progress | [x] complete | [-] skipped`

### Step 5: Name the session

Invoke the Claude Code built-in `/rename` command with format
`e2e-<classification>-<topic-slug>` (e.g. `e2e-feature-rtb-bid-cache`).
Makes the session findable in history. `/rename` is a built-in Claude
Code command, not a skill — on harnesses without it, skip this step
silently; do not log as a missing skill in Phase 10.

## Phase 1: RESEARCH

**Role:** Product Analyst (sonnet)
**Announce:** "Phase 1: Research — checking for existing solutions."

Invoke `/search-first` + `/documentation-lookup` (Context7). For
context-heavy research that risks blowing the budget, layer
`/iterative-retrieval` on top — refines the search progressively
instead of dumping all results into the orchestrator.

For broader multi-source synthesis (firecrawl + exa MCPs), invoke
`/deep-research` — appropriate for novel domains, library surveys, or
industry pattern scans. Skip for narrow tasks where docs lookup
suffices.

> Name collision: Claude Code now also ships a built-in `/deep-research`
> workflow alongside this toolkit's `/deep-research` skill. They are
> different surfaces — confirm which one resolves on your harness before
> relying on a specific behavior (the built-in may shadow the skill). On a
> large research fan-out, the built-in workflow gets the same
> context-budget benefit described for Dynamic Workflows in Phase 5.

Before writing custom code, invoke `/gh-search` to check for prior
PRs/issues on the same problem (this repo + across the org) — catches
"we already solved this" or "someone is mid-flight on this" before
duplicating work.

Output: research brief saved to session memory scratchpad. (For
unfamiliar codebases, `/codebase-onboarding` runs in Phase 3 Step 0
— don't duplicate here.)

**Skip when:** bugfix, refactor, hotfix, docs-only.

## Phase 2: DESIGN

**Role:** Architect — `architect` subagent (opus default)
**Announce:** "Phase 2: Design — exploring requirements and design."

Invoke `/brainstorming` for design exploration — run all checklist
items 1–8 (through user-reviews-written-spec). Stop before item 9 (the
transition to `/writing-plans`); the orchestrator handles planning in
Phase 3. **Blocking gate:** do not advance to Phase 3 until step 8
(user spec review) is complete and approved.

Run brainstorming's clarifying-questions step (item 3) with the
`/grilling` discipline: walk the design tree in **dependency order**
(resolve the decision other decisions hinge on first, not an arbitrary
list), give your **recommended answer with every question**, and when a
question can be answered by reading the code or a code-graph tool, **explore
instead of asking** (use the Phase 1 `code-explorer` findings and your
code-search / code-graph tools — spend the user's
attention only on genuine unknowns). This is what makes the gate catch
under-specification rather than just collect preferences.

Invoke `/council` when the user expresses uncertainty between approaches,
or when approaches have fundamentally different trade-off profiles with no
dominant option. Council voices: Architect, Skeptic, Pragmatist, Critic.

For non-trivial architectural decisions (library/framework picks, key
patterns, data-model shape), invoke `/architecture-decision-records` to
capture the chosen approach and rejected alternatives as ADRs alongside
the design doc. Skip when there was a single viable approach.

**Stack-gated skills:** If the Phase 0 stack tag is `langchain` /
`langgraph` / `deep-agents`, invoke `/framework-selection` BEFORE
brainstorming to confirm the right framework layer. Skipping this often
leads to wrong-layer choices (e.g. raw LangChain agents when LangGraph
is better, or LangGraph when Deep Agents handles the use case more
cleanly). If the stack tag is `rest-api`, invoke `/api-design` to lock
the resource model, status codes, pagination, error envelope, and
versioning before brainstorming alternatives. For other stacks the
gating is via Phase 5 conditional skills, not Phase 2.

Output: design document with acceptance criteria saved to
`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.

When ≥2 approaches compete across ≥3 trade-off dimensions, you may offer
an ephemeral HTML compare-grid (Cross-Phase Rules § Optional HTML
decision surfaces) — the Markdown design doc above remains the committed
artifact.

**Divergent visual exploration (opt-in — UI-surface work where the visual
*direction* is load-bearing, not just its logic).** Before committing to
one design, when the aesthetic direction is a real open question, generate
**N (3–4) divergent full directions** as **standalone static-HTML mockups
of the key screens** — written to an ephemeral, non-tracked scratch path —
for the human to compare *perceptually* side-by-side, then pick a direction
to carry into `/frontend-design` (which then commits to that one
direction). This is distinct from the analytical compare-grid above (and
Cross-Phase Rules § Optional HTML decision surfaces): the grid scores
*approaches on criteria*; this shows *fully-rendered alternatives* so the
choice is made by looking, not by reading a matrix. Keep the mockups
vanilla HTML/CSS (no build step; do **not** invoke `/web-artifacts-builder`);
they are throwaway decision aids — the committed artifact stays the
Markdown design doc. Skip for bugfix / refactor / non-visual work.
<!-- Maintainer note: divergent-visual-exploration step harvested from Anthropic's "How We Claude Code" workshop (anthropics/cwc-workshops, how-we-claude-code/phase-2-planning, Apache-2.0) via AQ-76. Distinct from the analytical compare-grid: N fully-rendered directions for a perceptual pick, not an options×criteria matrix. -->

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
- **Unfamiliar codebase path:** if the user is new to the repo (or
  the orchestrator hasn't worked here this session), invoke
  `/codebase-onboarding` instead of the grep/glob scan — generates a
  structured architecture map + conventions guide.
- For cross-service work (touching ≥2 services or service boundaries),
  use a code-graph tool if the repo has one indexed — for callers, blast
  radius, cross-repo calls, Kafka/HTTP/gRPC/data-store flows, and semantic
  search. If no code graph is available, fall back to grep + reading across
  the affected services to map callers and boundaries by hand.
- **Read canonical sources for submodule-backed assets first.** If the
  change targets an asset that lives in a git submodule (e.g. skills
  from `mobile-agent-toolkit` synced into consumer repos), the FIRST
  read MUST be the canonical path (`<submodule-repo>/skills/<name>/`),
  NOT the synced copy under `.claude/skills/` or `.agents/skills/`.
  Synced copies lag canonical by days/weeks; planning against stale
  state ships duplicate logic and causes scope conflicts.
  <!-- Maintainer note: rule originated from operator memories `e2e/decision_target_canonical_skill_source.md`, `e2e/feedback_audit_upstream_before_planning.md` (PR #42 dogfood — 2 of 8 planned changes were already upstream). -->

When Research ran, this confirms known patterns. When Research was skipped,
this provides essential codebase context.

Invoke `/writing-plans`. Plan includes:
- Ordered tasks with dependencies
- Which tasks are independent (parallelizable)
- Verification steps per task
- Estimated complexity per task

For features that span 5+ tasks or multiple subsystems, invoke
`/task-breakdown` BEFORE `/writing-plans` to decompose the spec into
discrete tasks. `/writing-plans` then formalizes the decomposition with
TDD steps + verification per task. For simple features (≤4 tasks)
skip `/task-breakdown` and go straight to `/writing-plans`.

Output: plan saved to `docs/superpowers/plans/YYYY-MM-DD-[topic]-plan.md`.

Before handing the plan to Phase 5, you may offer an ephemeral HTML
plan-tuning UI (reorder / toggle scope / tune params → Export JSON;
Cross-Phase Rules § Optional HTML decision surfaces). The Markdown plan
above stays canonical.

## Phase 4: SETUP

**Role:** `git-workflow-specialist` subagent (haiku — pure mechanics)
**Announce:** "Phase 4: Setup — creating isolated workspace."

Invoke `/using-git-worktrees`. Non-skippable — even spikes get a worktree.

**Permissions prerequisite (one-time, user-scope).** Phase 5 dispatches
engineer subagents in parallel inside the worktree. Subagents inherit
the orchestrator session's *original* project permission scope — not
its updated worktree scope — so writes to `.claude/worktrees/**` are
denied unless the user has pre-authorized them in
`~/.claude/settings.json`. Without these rules, Phase 5 silently
degrades from N parallel subagents to sequential inline writes by the
orchestrator (no error surfaced; just lost parallelism and lost
fresh-context benefit). See [`targets/claude/settings.example.json`](../../targets/claude/settings.example.json)
and its [permissions README](../../targets/claude/settings.example.README.md) for the floor permissions to merge.

Once the worktree exists, **carry the planning artifacts into it** —
they were written to the parent repo's untracked `docs/superpowers/`
tree in earlier phases and `git worktree add` does not propagate
untracked files. Move (not copy) them so there's a single source of
truth going forward:

- `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` (Phase 2 output)
- `docs/superpowers/plans/YYYY-MM-DD-<topic>-plan.md` (Phase 3 output)
- Any ADRs from Phase 2

Without this carry-over, Phase 5 executors (`/subagent-driven-development`
or `/executing-plans`) cannot find the plan file they were asked to
execute against — silent runtime failure.

**If the plan includes tasks that need a running dev server** (frontend
features, local integration tests, API smoke tests), invoke
`/setup-local-dev` now — before the worktree is handed to engineers.
Starting the server here instead of per-task prevents race conditions and
avoids hanging sub-tasks that assume it's already up.

Then persist the phase tracker (created in Phase 0 Step 4) to
`docs/superpowers/e2e-tracker.md` inside the worktree so re-entry can
resume from the last incomplete phase.

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
- **Inline orchestrator** — the orchestrator implements directly without
  dispatching subagents. Allowed ONLY when ALL of: ≤3 files modified +
  single domain (e.g. only markdown, only one config file) + no
  parallel-eligible tasks in the plan. Forbidden when crossing service
  boundaries, touching production code paths, or when a subagent's
  fresh-context review would catch issues you've grown blind to.

> Note: `tdd-workflow` is canonical here; `test-driven-development`
> in some downstream repos is a deprecated alias.

Default to `/subagent-driven-development`. The chosen executor MUST
appear in the Phase 5 exit-gate sentence (e.g. "Invoked: inline (3
markdown files, single domain)").

**TDD discipline by classification:**
- `feature` — Engineers follow `/tdd-workflow` (red → green → refactor)
  unless the task is config-only or a one-line change.
- `bugfix` — Write the failing test that reproduces the bug *first*.
- `refactor` — Run the existing test suite before starting and after
  each change; behavior must be preserved. Invoke `/repository-organization`
  when the refactor includes folder restructuring — it handles path-safe
  moves, CI/doc updates, and avoids import regressions.
- `migration` — Run the existing test suite before + after each file move;
  behavioral diff must be zero. Follow a migrate-then-verify loop for
  repo-to-repo or service-to-service moves where minimal diff matters.
- `hotfix`, `spike` — Skip TDD (speed and exploration first).

**Stack-conditional skills (wired at Phase 5):**
- `infra` stack — invoke `/mcp-builder` when the plan includes an MCP
  server scaffold; reach for your deployment / CI helper when the plan
  touches deployment manifests or CI pipeline files.

**Optional cost gate (post-P5, before P6):**
Invoke `/cost-audit` when the change includes: DB writes in loops, per-request
external API calls, expensive queries without pagination, or any new infra
resource provisioning. Reports expensive decisions before they reach code review
and are more costly to revert.

**Parallel execution:** Whenever the plan has 2+ independent tasks
running concurrently, follow `/dispatching-parallel-agents` (covers fan-
out patterns, result aggregation, and failure isolation). Before any
parallel dispatch, invoke `/multi-agent-branching` to verify branch
hygiene — each worktree on its own branch, no commits leaking to base.
Parallel engineers run with `isolation: worktree`.

**Large fan-out — prefer a Dynamic Workflow (advisory):** When the work
is a *large* fan-out — a codebase-wide sweep, a many-file migration, or N
independent parallel edits (the shape `/subagent-driven-development` would
otherwise dispatch turn-by-turn) — consider kicking it off as a Claude
Code **Dynamic Workflow** instead of turn-by-turn subagent dispatch.
Claude writes a JS orchestration script that runs in the background; the
plan and intermediate results live in *the script*, not the orchestrator's
context window, and the run is resumable within the session. This keeps
the orchestrator lean (no per-task results accumulating in context) and
survivable across interruptions — the same reason our canon keeps the
orchestration plan out of the context window (context engineering +
isolation: `investigation_toolkit/knowledge/agentic-dev/canon.md`,
principles #1 "prefer simple composable patterns / workflows over agents
for predictable tasks" and #3 "curate exactly the high-signal tokens each
step sees"). Trigger it with the `ultracode` keyword (or `/effort
ultracode`).

This is **guidance, not a MUST**: turn-by-turn subagents
(`/subagent-driven-development`) remain the default for small/medium
fan-out, where the dispatch overhead is negligible and live review of each
task is worth more than context savings. Reach for the Dynamic Workflow
when the fan-out is big enough that accumulated per-task results would
crowd the orchestrator's budget, or when resumability matters.

> Dynamic Workflows are a Claude Code **research-preview** feature
> (introduced v2.1.154). The trigger keyword is `ultracode` (renamed from
> `workflow` in v2.1.157) — verify the current keyword and availability
> against the docs (code.claude.com/docs/en/workflows) before relying on
> it, since preview surfaces shift. On harnesses without it, fall back to
> the turn-by-turn executor above.

**When an Engineer gets stuck:** dispatch a subagent with
`/systematic-debugging` (root-cause investigation) and/or
`/debug-workflow` (Log → Reproduce → Fix cycle enforcement) — they
target different failure shapes; pick one or run sequentially.

**Context:** Use `/session-memory` to persist decisions between tasks,
especially when work spans multiple chats.

## Phase 6: QUALITY GATES — HARD GATE

**Announce:** "Phase 6: Quality gates — cleanup, security, best practices."

HARD GATE — see Cross-Phase Rules § Hard Gate Contract.

All four gates run in **parallel** as subagents with clean context (no
pollution from execution phase). Numbered for reference, not sequence.
All are read-only except Cleanup and Simplifier. Run Cleanup first if
forced to serialize — its mechanical fixes prevent duplicate findings
from the other gates.

**Subagent prompt requirement** — see Cross-Phase Rules § Subagent
prompt requirement. Substitute the per-gate skill name
(`/code-cleanup`, `/code-simplification`, `/security-review`,
`/best-practices-enforcement`).

1. **Code Cleanup** — `code-cleanup` subagent (haiku — mechanical), skill:
   `/code-cleanup`. Targets debug artifacts, AI-generated noise, dead
   imports, leftover `console.log` / `print` debugging. Skip on
   `docs-only`.

2. **Simplifier** — `code-simplifier` subagent (sonnet — behavior-
   preserving refactor needs judgment). Invoke `/code-simplification`
   (covers reuse, quality, efficiency, applies fixes). The historical Claude Code
   built-in `/simplify` (which auto-applied fixes via three parallel
   review subagents) was renamed to `/code-review` in CC 2.1.147 (May
   2026) AND had its auto-fix behavior removed — `/code-review` now only
   reports correctness bugs at chosen effort levels (`/code-review high`,
   `--comment` for inline GitHub PR comments), making it a complement to
   this Simplifier gate, not a replacement. Run `/code-review` separately
   if you also want a correctness-bug pass. If neither is available, note
   in Phase 10 and skip this single gate (the other gates still run).

3. **Security Reviewer** — `security-reviewer` subagent (sonnet default,
   **opus override** when changed files fall in the Phase 8
   empirical-check categories — see that canonical list. Instruct
   read-only despite its Write/Edit tools), skill: `/security-review`.
   Scan changed files for vulnerabilities.

   **Belt-and-suspenders happy-path check (mandatory).** When security
   review proposes hardening that mutates argument structure
   (subprocess argv with `--`, URL/query rewrites, regex anchors that
   change verb semantics), the fix MUST be exercised against a real
   happy-path fixture before being marked done. Two layers of the SAME
   protection where one mutates verb semantics is a footgun (e.g.
   `git checkout -- main` shifts checkout into pathspec mode and
   silently breaks branch checkout). Prefer input validation (regex,
   allowlist) as the FIRST defense; add separators only when input
   cannot be tightly constrained. If a reviewer demands defense-in-
   depth on top of existing validation, push back: ask which CONCRETE
   attack the additional layer prevents that the existing layer doesn't.
   <!-- Maintainer note: rule originated from operator memory `e2e/feedback_security_fix_correctness_check.md` (ckpm Phase 6→7 — `git checkout --` hardening broke all GitHub source operations). -->

4. **Best Practices** — `code-reviewer` subagent (sonnet default,
   read-only), skill: `/best-practices-enforcement`. Validate coding
   standards.

> Optional 5th gate (not parallel — runs after the four above):
> `/code-optimization` when the change has measurable performance,
> memory, or efficiency goals beyond what `/code-simplification` covers
> (algorithmic improvements, hot-path refactors). Skip when the
> change has no perf-shaped requirement.

**Findings disposition (default = fix inline).** Surface findings via
a structured question with these option ordering:

1. **Fix all (Recommended)** — default for any HIGH severity finding;
   also default when MEDIUM count ≥ 2.
2. **Fix HIGH + MEDIUM, defer LOW** — when LOW findings are stylistic
   and the user wants to ship faster.
3. **Fix HIGH only** — when MEDIUM are non-actionable in scope.
4. **Commit as-is, track all in PR description** — only with explicit
   user OK and only when no HIGH findings exist.

Tracking-as-mitigation is NOT resolution. Re-run Phase 6/7/8 after
fixes (~5–10 min); the cost is worth the clean ship.
<!-- Maintainer note: from operator memory `e2e/decision_fix_findings_inline_not_followup.md` (PR #106). -->

**Skip when:** spike, docs-only — only these classifications. Hotfix
runs all four gates by default; for true seconds-count emergencies the
user can invoke the Hard Gate Contract override explicitly.

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

**Subagent prompt requirement** — see Cross-Phase Rules § Subagent
prompt requirement. For Phase 7 the literal substitution is
`/requesting-code-review` (and follow `/code-review-excellence` for
methodology).

If `/code-review-excellence` is substituted for `/requesting-code-review`
as the primary skill (rare — only when the diff is large enough that
the heavier methodology adds value), the Phase 7 exit-gate sentence
MUST document the substitution and reason.

If reviewer finds issues → fix them in the same PR before merge → reviewer
re-reviews. Do not skip re-review. If the reviewer's findings are
non-actionable (out-of-scope nitpicks, disagreement on style), explicitly
acknowledge and document the decision in the PR description rather than
silently ignoring.

**Author-side loop:** Once the reviewer returns findings, the
fix-up step invokes `/receiving-code-review` for methodology — how to
classify findings (must-fix vs nice-to-have vs disagreement), how to
respond to non-actionable feedback without being defensive, when to
push back vs comply.

For PRs with **≥2 review rounds** OR **≥10 unresolved comments**,
invoke `/address-pr-feedback` to triage the comment thread
systematically: which to apply, which to defer, which to discuss
in-thread. For first-round straightforward fixes (single round, ≤9
comments), direct apply is faster than triage — skip.

**Review-fix loop (bounded).** When the reviewer returns HIGH or MEDIUM
findings:
1. Fix the findings in the same PR (author-side loop above)
2. Dispatch a **fresh** reviewer subagent — never the same instance that
   reviewed before (reviewer bias). The fresh reviewer focuses only on the
   changed lines + original findings, not a full re-review.
3. Cap at **3 total rounds**. If findings persist after round 3, surface
   unresolved items to the user with an explicit "UNRESOLVED — needs human
   judgment" label. Do not silently drop them or keep looping.

**Skip when:** spike — only this classification. Hotfix runs P7 by
default (the gate matters more on emergency code, not less). The
Hotfix HIGH-escalation rule (Classification & Skip-Logic) is
load-bearing: any HIGH from P6 forces P7 even if the user
explicitly tries to skip via the Hard Gate Contract override.

## Phase 8: VERIFICATION

**Role:** QA / Sentinel — `verifier` subagent (**sonnet**, skeptical
validator — every rule below requires judgment haiku will fumble: the
empirical-not-static rule, restore-semantics check, smoke-test
substitution decision. PR #106 burned the team on exactly this pattern.
For test execution and failure analysis specifically, dispatch
`test-runner` (haiku) inside the verifier's flow — pure mechanical work).
**Announce:** "Phase 8: Verification — running evidence checks."

Invoke `/verification-before-completion`. Hard gate — no success claims
without evidence:

- Run test suite — all must pass (skip if classification is `docs-only`
  and no tests apply)
- Run build — must succeed
- Run linters/formatters if configured
- For `docs-only`: verify docs build and links resolve
- Present evidence (actual output) before proceeding

**Empirical, not static (mandatory for security-sensitive code):**

For any change touching:
- Cryptography (HMAC, signing, hashing)
- Networking (URL construction, header parsing, TLS)
- Payload construction (jq filters, JSON merging, templating)
- Allowlists / denylists / authorization checks

…running `actionlint` / `grep` / unit tests is **insufficient**. Phase 8
MUST execute the actual logic against an independent reference and
compare bit-for-bit:

- HMAC implementation → compare against Python `hmac` stdlib (which
  matches Go `crypto/hmac` and Node `crypto.createHmac`).
- URL allowlist → run hand-traced cases including subdomain spoofing
  (e.g. `evil.your-domain.com.attacker.com` must reject when the rule was meant to allow only `*.your-domain.com`), port stripping,
  and the legitimate happy path.
- jq payload construction → run with sample input + verify each field
  matches the wire-protocol contract.
- Authorization rules → enumerate the truth table; assert each row.

<!-- Maintainer note: rule originated from operator memory `e2e/feedback_verification_must_run_empirically.md`. -->
PR #106 grep+actionlint missed two real bugs (openssl flag-injection
and allowlist port-stripping) caught only by running the actual code.

**Cross-service seams — exercise the REAL boundary, not a hand-mocked
one (mandatory when a change spans ≥2 services / processes).** Unit
tests whose mocks are hand-written on BOTH sides of a seam validate your
*assumption* about the other component, not its behavior — they pass in
lockstep with a fully-broken integration. For any change crossing a
service / process / protocol boundary (HTTP, gRPC, MCP, DB, queue),
Phase 8 MUST do at least one of:

- **Record a golden fixture from the real producer** — call the actual
  dependency once (e.g. a raw MCP `tools/call`, the real API/DB
  response), save its EXACT shape, and assert the consumer/parser
  against THAT — never an invented shape. A mock may not define both
  ends of a contract.
- **Run a docker-compose integration test of the seam** when the repo
  can stand the dependency up locally (`docker compose up -d`) —
  exercise the real round-trip (write→read, request→response) end-to-end,
  not just each side in isolation.
- For any `things.find(x => x.name === Y)` against an external registry
  (tool list, plugin set, route table), assert `Y` is actually PRESENT
  in `things` from the real source — don’t assume reachability.

<!-- Maintainer note: rule originated from operator memory
`e2e/feedback_mock_seams_hide_integration_bugs.md`. An investigation-cache
feature passed 28 unit tests + tsc + full /e2e yet was 100% broken across
THREE seams (MCP content-block envelope shape; an admin tool absent from
the architect’s LLM tool list; a `z.datetime()` validator rejecting the
producer’s real `+00:00`/microsecond format) — each caught only by live
verification because every mock encoded the wrong contract on both sides. -->

**Restore-semantics check (mandatory for `restore` / `apply-pin` /
`reset-to-snapshot` style commands).** When the change adds a command
that is supposed to restore a recorded state (lockfile, snapshot, pin,
manifest), Phase 8 MUST include a test that:

1. Captures the recorded state hash/version.
2. Mutates the upstream / source.
3. Calls the restore command.
4. Asserts the recorded state is byte-identical after.

The bug pattern: a "restore" implemented as `apply(...)` with no flag
silently calls the snapshot-refresh routine, advancing the lockfile to
current upstream rather than enforcing the pin. This defeats the
command's purpose and corrupts the lock on drifted environments.
<!-- Maintainer note: rule originated from operator memory `e2e/feedback_restore_semantics.md` (ckpm Phase 7 — `restore` was secretly advancing the lockfile). -->

**Smoke-test fast path (upgrade-class changes).** For interpreter
upgrades, dep bumps with API migrations, base-image changes, and
lockfile regenerations where the full test suite is 15–30+ minutes,
Phase 8 MAY substitute:

1. Build the smallest affected Dockerfile (validates base image + deps
   resolve on Linux).
2. Build a representative larger Dockerfile (validates heavy deps
   like tree-sitter, native extensions).
3. Run a targeted in-container smoke test that exercises the riskiest
   changed code path end-to-end.

Total runtime ~3–5 min vs 15–30 min for full suite. CI catches the
full surface; the smoke test catches deal-breakers (image won't build,
imports fail, migration broke). Substitution MUST be documented in the
Phase 8 exit-gate sentence with the deferred suite name. NOT permitted
when changes touch logic, schemas, or wire contracts — those still
need the full suite locally.
<!-- Maintainer note: rule originated from operator memory `e2e/default_phase8_docker_build_smoke_test.md` (PR #123 Python 3.14 upgrade — validated smoke-only path in ~3 min). -->

**Read-after-write readiness gate (mandatory for e2e / browser smoke
tests that create-then-navigate).** When a smoke flow creates a resource
via the API and then immediately drives the UI to it (e.g. `POST
/api/<resource>` → `goto /<resource>/<id>`), the create call routinely
returns before the resource is queryable. The destination page's
mount-time fetches then race ahead of that write and 404, surfacing as
`console.error` / `pageerror` events that flake a "no unexpected console
errors" assertion. The fix is to **gate the navigation on resource
readiness** — poll the resource endpoint to a success status before
navigating:

```ts
await expect
  .poll(async () => (await request.get(`${API}/api/<resource>/${id}`)).status(), { timeout: 10_000 })
  .toBe(200);
```

**Do NOT silence the symptom by adding the 404 (or its console message)
to a noise allowlist** — that masks real read-after-write and missing-
resource regressions the test exists to catch. Allowlists are reserved
for genuinely-expected third-party noise (HMR, CDN egress flake), never
for a first-party resource the flow itself just created. If a fetch still
errors after the resource is confirmed ready, that is a real product bug
(e.g. the frontend `console.error`-ing on a legitimately-absent fresh-
resource sub-route) — fix it at the source after reproducing locally, do
not allowlist it.
<!-- Maintainer note: rule originated from operator memory `e2e/feedback_read_after_write_readiness_gate.md` (a create-then-navigate smoke flow flaked when the destination page's mount-time fetches 404'd on a cold mount; the masking fix was to allowlist the 404 — the non-masking fix is a poll-to-200 readiness gate before navigation). -->

If anything fails → fix and re-verify. For flaky suites or long
retry cycles, invoke `/test-until-pass` — formalizes the run →
analyze → fix → re-run loop with retry caps so the loop has an
explicit stop condition.

**Optional verification skills (stack-gated):**
- **Agent behavior changes** — invoke `/eval-harness` to verify
  agent outputs against a fixture set; relying on unit tests alone
  misses prompt/model regressions.
- **Performance-shaped changes** — invoke `/benchmark` to capture
  before/after baselines; pairs with `/code-optimization` from
  Phase 6's optional 5th gate.
- **Web-frontend stack** — invoke `/agent-browser` to run interactive
  browser tests against the running dev server (started in Phase 4 via
  `/setup-local-dev`). Catches "works locally, fails in QA" regressions
  that unit tests miss. Requires a running server — skip if Phase 4
  did not start one.
- **Agent-verifiable frontend (greenfield only)** — when building a NEW
  frontend from scratch and runtime verification matters, consider exposing
  a **machine-readable state contract**: declarative `data-*` state
  attributes plus a `window.__verify`-style handle returning declared
  unit/fixture/verdict data, so the verifier *observes declared state*
  instead of scraping rendered markup. mozart's `game-quality` probes
  already do this (`window.__mozartTest` / `qa_*`). Skip when retrofitting
  an existing app — use `/agent-browser` on the real DOM instead.
  <!-- Maintainer note: agent-verifiable-frontend pattern harvested from Anthropic's "How We Claude Code" workshop (anthropics/cwc-workshops, how-we-claude-code/phase-3-verify, Apache-2.0) via AQ-76. Greenfield-only by design: the DOM contract must be built in, not retrofit. mozart's game-quality QA hook is the in-tree precedent. -->
- **Production-traffic verification** (post-deploy or staging) —
  your metrics/dashboards tooling for metrics, and distributed-tracing
  tooling for request-flow tracing across services. Use when the
  change affects a service already in production and the test suite
  can't reproduce real traffic patterns.

## Phase 9: DELIVERY

**Role:** `git-workflow-specialist` subagent (sonnet)
**Announce:** "Phase 9: Delivery — finalizing the work."

**Commit-message hard rule (mandatory).** Never add `Co-Authored-By:`
lines (Claude attribution or any AI-attribution variant) to commit
messages or PR bodies in the user's repos. The user's commit hooks
classify these as fabricated authorship and BLOCK the commit; default
templates from system instructions or other tools must be overridden.
Strip the line entirely from every git commit message and every PR body.
<!-- Maintainer note: rule originated from operator memory `e2e/feedback_no_co_authored_by.md` (commit hooks block `Co-Authored-By: Claude ...`). -->

Invoke `/finishing-a-development-branch`, then **always surface the
delivery decision to the user via an explicit `AskUserQuestion`** — do
NOT auto-resolve it from the labelled default, even when "Create PR" is
the obvious choice. Surfacing the menu every run is mandatory: a
labelled default is a *recommendation* the user accepts in one tap, NOT
permission to skip the prompt. The only exception is a fully-autonomous /
headless run with no interactive TTY — there, proceed with the
classification default and state in the exit-gate sentence which option
you took and why.

Present these options (mark the classification default `(Recommended)`
and list it first so it is the one-tap accept):

- **Create PR + wait green** (recommended for feature / refactor /
  bug-fix / hotfix / docs) — invoke `/create-pr` for the basic PR; layer
  `/pr-workflow` for richer lifecycle (draft → ready) and `/github-ops`
  alongside for CI status checks, PR triage, and release-branch ops.
  **Then continue to the Wait-Green sub-step below — do NOT skip.**
- **Keep branch** — for continued work later
- **Discard** — only for `spike` classification when the exploration
  didn't pan out

<!-- Maintainer note: the explicit-AskUserQuestion requirement exists
because the prior "(default for …)" wording made the delivery menu
inconsistent. A transcript audit found e2e surfaced it spontaneously in
only ~1/3 of reached-delivery runs; in the rest the orchestrator
auto-resolved to the default and the user invoked
/finishing-a-development-branch by hand. Make it deterministic: the menu
is a real prompt every run; the default is pre-selected, not silently
taken. -->

**Merge gate (hard rule).** /e2e MUST NEVER merge **autonomously**: never
run `gh pr merge` unprompted, never pass `--auto`, and never treat a
"merge" from a previous session — or a follow-up aside after the user
chose another option — as authorization. That authorization does NOT
carry across /e2e runs. The default end-state remains a GREEN MERGEABLE
PR with the exact merge command printed for the user.

**The one permitted merge path is an explicit in-prompt selection.** When
the branch is confirmed GREEN MERGEABLE, the end-of-Phase-9 compound gate
(below) offers a "Merge now — I'll run it" choice via `AskUserQuestion`.
If — and only if — the user selects it in that live prompt, /e2e runs the
exact `gh pr merge {NUM} --{STRATEGY}` command for THAT PR, on THIS run.
Selecting the option *is* the authorization; it is single-use, never
implies `--auto`, and never persists to the next run. Every other option
(Keep PR open / Show command only / Discard) leaves the merge to the
human.
<!-- Maintainer note: rule originated from operator memory `e2e/feedback_never_auto_merge.md` and `e2e/feedback_never_auto_merge_even_when_nudged.md` (user wants to review PRs before merge; the merge step belongs to the human). The explicit in-prompt "Merge now" exception was added per operator request 2026-06-11: an AskUserQuestion selection made live IS valid authorization for that one merge — it is NOT autonomous and NOT a carried-over nudge. `--auto` and follow-up-message authorization remain forbidden. -->

**Release boundary (optional).** When the PR closes a release
milestone, invoke `/generate-changelog` to produce release notes,
`/generate-docs` to update any API/module docs that changed, and
pair with `/security-audit` (the deeper periodic security check for
release boundaries; `/security-review` is the per-PR scan used in Phase 6).

For **spike** classification: only show "Keep branch" and "Discard"
options. For **hotfix** that fails to deliver a working fix, use the
Error handling path in Cross-Phase Rules — not Discard.

### Prose finishing pass — stop-slop (PR description narrative only)

Before opening the PR, apply the bundled **stop-slop** prose rules to the
PR-description **narrative prose only** (the summary / "what & why"
paragraphs). Read the rules from the toolkit:

- `${CLAUDE_PLUGIN_ROOT}/assets/stop-slop/SKILL.md`

If that path doesn't resolve, **skip this pass silently** (do not block delivery).

**Scope — apply ONLY to free-prose narrative. Do NOT apply to:** code or
fenced code blocks, commit messages, file/path lists, test output,
checklists, rollback commands, version-controlled docs under `docs/`,
plans, or specs. stop-slop's absolutes (remove all adverbs, no em-dashes,
no three-item lists) degrade technical precision, so this pass is scoped to
human-facing prose by design and never rewrites technical content.
<!-- Maintainer note: stop-slop is vendored unmodified at assets/stop-slop/ (NOT under skills/, so it never auto-registers as a live skill). It is invoked explicitly here as a finishing pass. See SOURCES.md "hardikpandya/stop-slop". -->

### Wait-Green sub-step (mandatory after Create PR)

After the PR exists, poll until it's confirmed GREEN MERGEABLE before
exiting Phase 9. Hard gate — Phase 10 (Learn) does NOT run until this
completes (or until the user explicitly says "review later — proceed
to learn").

1. **Poll CI** — `gh pr checks {NUM} --watch` (or loop `gh pr checks
   {NUM}` until all required checks report SUCCESS). Default timeout:
   10 minutes for feature/refactor/bug-fix; 15 minutes for hotfix (CI
   under emergency pressure is often slower). If a check fails, return
   to the corresponding upstream phase (test failure → Phase 8;
   security/policy gate → Phase 6) — do NOT proceed.

2. **Verify mergeability** — `gh pr view {NUM} --json mergeable,mergeStateStatus,statusCheckRollup`:
   - `mergeable == "MERGEABLE"` AND `mergeStateStatus == "CLEAN"` → GREEN MERGEABLE, proceed.
   - `mergeStateStatus == "BLOCKED"` while all visible checks passed →
     **zombie check-suite** (per operator memory
     `e2e/feedback_zombie_check_suites.md`; 4 zombie suites blocked
     auto-merge on mobile-agent-toolkit and `--admin` force-merge was
     the workaround). Surface the blocking check names and offer the
     user a `gh pr merge {NUM} --admin --squash` force-merge command in
     the exit-gate sentence. Do NOT execute it.
   - `mergeStateStatus == "DIRTY"` → branch has conflicts. Resolve in
     a follow-up; do NOT auto-rebase in /e2e.
   - `mergeStateStatus == "BEHIND"` → branch needs updating from base.
     Print the `gh pr update-branch {NUM}` command for the user; do NOT
     auto-execute (it can trigger unwanted CI re-runs).

3. **Print the merge command** — the Phase 9 exit-gate sentence MUST
   contain the EXACT `gh pr merge {NUM} --{STRATEGY}` command the user
   should run when ready, selected from the repo's merge-strategy
   convention (squash is the default; check `gh repo view --json
   mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed` if
   uncertain). Include `--delete-branch` when auto-delete-on-merge is
   NOT enabled at the repo level (per
   `e2e/convention_auto_delete_branches.md`).

### Compound status + merge gate (mandatory, once GREEN MERGEABLE)

Do NOT print verification and delivery status as two scattered phase
sentences and then go quiet. Emit ONE **compound status block** that pulls
the Phase 8 verification result forward next to the gh-verified PR state,
so the user sees in a single message that *both* the work was verified
*and* the branch is mergeable — they should never have to ask "did
verification run?" or "is it actually green?" again.

**Compound status block format (mandatory):**

```
✅ Ready to merge — verified end-to-end.
  Verification (Phase 8): {tests N passed / build OK / lint OK}  ← already ran
  PR {URL} (#{NUM}):
    CI: {N} checks passed, {0_or_N} failed   (gh pr checks)
    mergeable: {MERGEABLE} · mergeStateStatus: {CLEAN | BLOCKED-zombie | DIRTY | BEHIND}   (gh pr view)
  Merge command: gh pr merge {NUM} --squash[ --delete-branch][ --admin if zombie]
  Delivery hooks: {accepted: [list]; declined: [list]}
```

Then surface the merge decision via an explicit `AskUserQuestion` (the one
permitted merge path per the Merge gate hard rule above). Present these
options, "Keep PR open" pre-selected `(Recommended)` and listed first so
the safe choice is the one-tap default:

- **Keep PR open for review (Recommended)** — stop here. The merge is
  yours to run when ready. Phase 9.5/10 wait until you signal you merged.
- **Merge now — I'll run `gh pr merge {NUM} --{STRATEGY}`** — selecting
  this IS your authorization for THIS merge. /e2e runs the exact command
  (never `--auto`), confirms the merge landed, then proceeds to Phase 9.5
  (post-deploy follow) if the PR targets a deployed service.
- **Show me the command only** — print it and stop (same as Keep open, no
  watcher).
- **Discard** — `spike` classification only.

If the user picks **Merge now**: run the printed command, verify with
`gh pr view {NUM} --json state,mergedAt` that `state == "MERGED"`, report
the result, and continue to Phase 9.5. If the merge command errors
(e.g. zombie BLOCKED needing `--admin`, or BEHIND), surface the failure
and the corrected command — do NOT silently retry with escalated flags.

**Exit-gate sentence format (mandatory):**

```
Phase 9 complete. PR {URL} is GREEN MERGEABLE.
  CI: {N} checks passed, {0_or_N} failed
  mergeStateStatus: {CLEAN | BLOCKED-zombie | DIRTY | BEHIND}
  Decision: {Merged now via gh pr merge | Kept open — merge when ready: gh pr merge {NUM} --squash[…] | Command shown | Discarded}
  Delivery hooks: {accepted: [list]; declined: [list]}
```

If the decision was Keep open / Show command, stop here per the merge-gate
hard rule; Phase 9.5 / Phase 10 follow once the user signals merge or
explicitly skips. If the decision was Merge now, proceed directly to
Phase 9.5.

**Delivery hooks (post-PR, REQUIRED ASK).** After the PR is opened
(or merged), ask the user via structured questions about each of these
follow-ons. Do NOT write to any shared system without explicit user
confirmation:

| Hook | Question | Default |
|------|----------|---------|
| Slack canvas / thread | "Update `[canvas-or-channel]`?" — uses `/slack-history` to read context + draft message | Show diff before writing |
| Jira ticket | "Transition `[ticket]` to In Review / Done?" | Confirm transition target first |
| Confluence page | "Mark `[page]` complete or add a changelog entry?" | Show diff before writing |
| GitHub Project board | "Move `[issue/PR]` to next status?" — uses `/gh-manage-project` | Confirm target status first |
| Google Doc spec/brief | "Update `[doc-url]` with implementation outcome?" — uses `/gdoc` | Show diff before writing |

If the prompt referenced a specific canvas / ticket / page (e.g.
"closes canvas item Y"), pre-populate the question with that target. If
no reference exists, ask only when there's a clear stakeholder signal
that one should be updated (e.g. PR closes a tracked issue).

<!-- Maintainer note: rule originated from operator memory `feedback_*_shared_doc_writes`. --> Writes to Slack
canvases, Confluence pages, and Jira require explicit user OK each
time. A prior canvas-update attempt was denied because the orchestrator
wrote without asking. The Phase 9 exit-gate sentence MUST list which
hooks the user accepted vs declined.

## Phase 9.5: POST-DEPLOY — FOLLOW THE ROLLOUT & OBSERVE

**Role:** QA / Sentinel — `verifier` subagent (sonnet) orchestrating a
deploy-watching pass and a monitoring pass against whatever deploy /
observability stack the repo uses. **Announce:** "Phase 9.5: Post-deploy —
following the rollout and watching production signals."

**Runs only after an actual merge** — the in-prompt "Merge now" path, or
the user signaling they merged. A still-open PR has not deployed, so this
phase waits.

**Skip when:** spike, docs-only, the PR targets a non-deployed artifact
(docs, skill/toolkit files, config without a deployed service), or no
deploy mechanism is discoverable for the repo.

**Generic by delegation — the repo knows its own specifics; this phase is
a spine that reads them rather than hard-coding them.** Stay observe-and-
report: it follows the rollout and reports health, but **every prod-
touching action (environment promotion, rollback) is an explicit
`AskUserQuestion` — never automatic.**

1. **Discover deploy context (silent).** Read the repo's `CLAUDE.md` /
   `AGENTS.md` for: deploy mechanism (ArgoCD app name, GitHub Actions,
   Helm), environment order (e.g. `stg → prod`), Grafana dashboard(s) or
   UID, log store + selector (Loki labels, or Kibana/Elasticsearch
   index), and any documented "post-deploy check" steps. If none are
   documented, ask the user **once** for the deploy target/dashboards (or
   skip the phase). This is how the phase stays generic — the repo's own
   agent context supplies what varies.

2. **Tag the deployment** — lightweight git tag linking PR → deployed commit:
   ```bash
   git tag "e2e/<session-slug>/deploy-$(git rev-parse --short HEAD)"
   git push origin "e2e/<session-slug>/deploy-$(git rev-parse --short HEAD)"
   ```

3. **Follow the rollout.** Dispatch a deploy-watching subagent to watch the
   rollout (e.g. an ArgoCD app, a GitHub Actions run, or a Helm release)
   reach a healthy state on the **first**
   environment (typically stg). For multi-env pipelines, report each
   environment's status as it progresses. **Prod promotion is never
   automatic** — surface `AskUserQuestion` `[Promote to prod] [Hold]`
   before any prod-targeting action; otherwise observe and report.
   (GitHub Actions / Helm pipelines: follow the run / release instead,
   same gating.)

4. **Post-deploy checks** (first env; repeat for prod once promoted):
   - **Logs** — query your log store (Loki / Kibana / Elasticsearch)
     for error-rate spikes, panics, and new
     `ERROR`/`FATAL` patterns in the deployed service since the deploy
     timestamp.
   - **Signals** — open the service's golden signals via your
     metrics/dashboards tooling (request rate, error rate, latency P99,
     saturation). Watch **5 minutes** (hotfix: 10). Threshold: any
     counter that was stable before the deploy spikes/drops >5% within
     the window.

5. **Document rollback command** in the PR description under a "Rollback"
   section — the exact revert (`git revert <sha> && git push`, or the
   ArgoCD/Helm rollback command for the deployed service).

6. **If anomaly detected** (bad logs OR signal breach), surface a
   structured `AskUserQuestion` before advancing — **rollback is never
   auto-executed**:
   - [1] Rollback now — run the documented rollback command
   - [2] Watch another 5 minutes — extend the window
   - [3] Expected — document as known regression and proceed

**Exit gate sentence:** "Phase 9.5 complete. Env(s): {stg: Healthy/…}.
Logs: {clean / N errors}. SLO status: [stable/anomaly]. Watch: N min.
Rollback documented: yes/no. Prod: {not promoted / promoted+healthy /
held}."

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

5. **Hotfix follow-up review** — If classification was `hotfix`, record
   a follow-up review obligation **unconditionally** (regardless of
   whether P7 ran during the emergency fix). See Cross-Phase Rules §
   Hotfix follow-up review for the re-review vs original-review
   distinction. Capture: file path, brief description, target branch.
   Surface it the next time the user runs `/e2e` in this repo, or in
   the PR description if the hotfix is still open. Prefix with
   `e2e:followup:review:`.

Format: one memory file per concept, Markdown with frontmatter.
Deduplicate: overwrite existing memories on the same topic, don't append.

Tell the user: "Saved learnings from this run. Future /e2e invocations
will be faster."

**Optional — team-visible compound note (opt-in, additive):** the memory
write above lands in the operator-PRIVATE `{MEMORY_DIR}/` and is invisible
to teammates and to other agents in a multi-agent workspace. When a
learning from this run is **team-relevant** (a decision, gotcha, or
convention the next person — human or agent — touching this repo should
know), ALSO offer to append a concise entry to a durable, repo-local,
**committed** compound note. This is the EveryInc compound-engineering
mechanism (the note, not the plugin), borrowed to make cross-agent
learnings durable and team-visible.

Hard constraints (all required):
- **Opt-in, default-off.** Offer via one structured question
  ("Append a team-visible learning to the repo's compound note? [1] Yes
  [2] No"). On decline or no team-relevant learning, do nothing extra —
  the private memory write above is unchanged. NEVER block on it.
- **Additive, never a replacement.** The compound note is written
  ALONGSIDE the `{MEMORY_DIR}/` write, not instead of it. Operator-private
  memory still captures everything; the compound note captures only the
  subset worth sharing.
- **Where it lives (repo-local, committed, team-visible).** Use the
  repo's existing decisions/learnings home if one exists (in priority
  order: `docs/decisions/`, `docs/superpowers/`, an existing
  `docs/compound-notes/`); otherwise create `docs/compound-notes/`. One
  file per repo (`COMPOUND_NOTES.md`) or one file per concept — match the
  surrounding convention. It is a normal tracked file, committed on the
  PR branch (NOT gitignored, NOT a scratch path).
- **Format.** Append (don't overwrite) a dated, sourced bullet:
  `- YYYY-MM-DD — <one-line learning> (from /e2e, PR #<n> / branch <name>)`.
  Keep it concise — one to three lines. Group under a `## Learnings`
  heading if the file is new.
- **Tool-agnostic.** Plain Markdown + git; no plugin, no MCP, no
  harness-specific path.

**Optional companion:** invoke `/skill-stocktake` in Quick Scan mode to
detect any sub-skills that were referenced but missing in this run —
lets the user install them before the next run rather than discovering
gaps mid-execution. Log results as `e2e:missing-skills:` in memory.

## Cross-Phase Rules

### Phase exit gate (mandatory)

Before advancing from phase N to phase N+1, the orchestrator MUST emit
the literal sentence:

> "Phase N complete. Invoked: /skill-name. Output: `[path or one-line summary]`."

If a phase was skipped per classification, emit:

> "Phase N skipped per `[classification]` classification."

If a phase substituted a different skill (e.g. `/code-review-excellence`
in place of `/requesting-code-review`), emit:

> "Phase N complete. Invoked: /actual-skill (substituted for /spec-skill — reason: `[X]`). Output: `[path]`."

Silent skips — phases that pass without an exit-gate sentence — are
**defects**. The orchestrator MUST either:
1. Re-run the phase invoking the skill, or
2. Get explicit user approval for the substitution before advancing.

### Phase entry self-check

Before starting phase N, verify that phase N-1 emitted an exit-gate
sentence (or a documented skip per the classification table). If absent,
retry N-1 first. Defense-in-depth on top of the exit-gate protocol — the
next-phase orchestrator catches what the prior-phase orchestrator forgot.

### Subagent prompt requirement (mandatory)

Every subagent dispatched as part of an `/e2e` phase — Research
(Phase 1), Design (Phase 2), Planning Step 0 (Phase 3), Execution
(Phase 5), Quality Gates (Phase 6), Review (Phase 7), Verification
(Phase 8) — MUST include this literal sentence in its prompt
(substitute the actual skill name):

> **Invoke the `/SKILL_NAME` skill explicitly. Walk through its workflow step-by-step. Do NOT improvise.**

Without it, subagents fall back to general expertise and miss
skill-specific checklists. PR #106 dogfood ran Phase 6/7 with generic
agents and missed 4 findings (1 HIGH, 2 MEDIUM, 1 LOW) that a re-run
with explicit skill invocations caught — same drift has been observed
in code-explorer (P3), brainstorming (P2), and verifier (P8) dispatches
when the requirement was scoped narrowly.
<!-- Maintainer note: rule originated from operator memory `e2e/feedback_invoke_named_skills_in_subagents.md`; scope broadened from P6/P7-only after observing the same drift in P2/P3/P5/P8 dispatches. -->

### Hotfix follow-up review (always fires, regardless of P7 outcome)

Hotfix classification keeps Phase 6/7 by default — the gates matter
*more* on emergency code, not less (see Hotfix HIGH-escalation rule
above). Phase 10 records a hotfix follow-up review obligation
**unconditionally** when classification was `hotfix`:

- If P7 ran during the emergency fix → this is a **re-review** obligation
  (sleep on it, look again with fresh eyes; the original review happened
  under pressure and bias toward shipping).
- If P7 was skipped via Hard Gate Contract override (true seconds-count
  emergency only) → this is the **original review** obligation, owed before
  any further work in the affected area.

The follow-up surfaces in the next `/e2e` invocation in this repo and
in the PR description if the hotfix is still open. Phase 10 detail:
prefix `e2e:followup:review:`.

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

`{MEMORY_DIR}/e2e/` resolves via `/session-memory` (`.claude/memory/e2e/`
on Claude Code). Phases 0 and 10 reference this location.

### Structured questions everywhere

All clarification uses structured numbered options — never dump multiple
questions as plain text. Present one question at a time, wait for answer
before next question.

### Optional HTML decision surfaces (opt-in, ephemeral)

Two decision points may *augment* — never replace — the Markdown /
AskUserQuestion default with a throwaway single-file HTML surface when it
genuinely helps the human:

- **Phase 2 design compare-grid** — when ≥2 approaches compete across
  ≥3 trade-off dimensions (a matrix AskUserQuestion's flat option
  previews can't render), an HTML grid (options × criteria) the human
  scans side-by-side.
- **Phase 3 plan-tuning UI** — when the human wants to reorder tasks,
  toggle scope, or tune params before execution, a throwaway HTML editor
  with an **Export JSON** button; ingest the exported JSON to re-prompt
  the plan.

Hard constraints (all required):
- **Opt-in, default-off.** Offer via one structured question only when
  the trigger above holds. If the user declines or doesn't engage, the
  existing Markdown + AskUserQuestion flow runs unchanged — never block
  on the HTML surface.
- **Ephemeral only.** Write to a non-tracked scratch path (a temp dir or
  a gitignored `*-workspace/`). NEVER commit it or `git add` it. The
  committed artifact stays Markdown — the Phase 2 design doc and Phase 3
  plan under `docs/superpowers/` remain the single source of truth
  because they're diffable / greppable / PR-reviewable and HTML isn't.
- **Lightweight, self-contained.** One inline-written HTML file (vanilla
  HTML/CSS/JS, no build step). Do NOT invoke `/web-artifacts-builder` —
  it owns elaborate multi-component React artifacts and is overkill here.
  If the surface needs more than a single throwaway file, that's the
  signal to stop and stay in Markdown.

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

### Re-entry and phase checkpoints

Phase tracker persists to `docs/superpowers/e2e-tracker.md`. On next
`/e2e` invocation in the same worktree, check for this file and offer
to resume from the last incomplete phase. For Phase 5, check completed
tasks in the tracker and resume from the first incomplete task, not from
the beginning of the phase.

**Phase checkpoints (rewind support).** At each phase exit (Phases 3,
4, 5, 6, 7, 8), the `git-workflow-specialist` creates a lightweight
local git tag:

```bash
git tag "e2e/<session-slug>/p<N>"
```

Tags are local by default (not pushed). Re-entry detects these tags and
offers two options in addition to "resume":
1. **Resume** — continue from the last incomplete phase (existing behavior)
2. **Rewind to phase N** — `git reset --hard "e2e/<session-slug>/p<N>"`,
   discarding phase N+1 and later work, then resume from phase N's output

When the worktree is discarded (spike → Discard, or delivery complete),
delete the tags: `git tag -d $(git tag -l "e2e/<session-slug>/*")`.

### Phase budget envelopes

Maximum subagent dispatches per phase. Hard caps prevent runaway loops.
When a phase reaches its soft cap, the orchestrator announces it and
presents a structured choice before dispatching more.

| Phase | Soft cap | Hard cap | Over-budget action |
|---|---|---|---|
| 0 INTAKE | 2 subagents | 3 | Run inline; log in Phase 10 |
| 1 RESEARCH | 3 subagents | 5 | Stop early; note gaps in brief |
| 2 DESIGN | 3 subagents | 5 | Surface to user before P3 |
| 3 PLANNING | 2 subagents | 3 | Simplify plan (fewer parallel tasks) |
| 4 SETUP | 1 subagent | 2 | Run inline |
| 5 EXECUTION | 1 per task | 2× task count | Stop; surface incomplete tasks |
| 6 QUALITY GATES | 4 subagents | 5 | Skip optional 5th gate |
| 7 REVIEW | 2 (review + re-review) | 3 rounds | Surface unresolved to user |
| 8 VERIFICATION | 2 (verifier + test-runner) | 3 | Substitute smoke-test |
| 9 DELIVERY | 1 subagent | 2 | Run inline |
| 9.5 POST-DEPLOY | 2 subagents (deployment-investigator + monitoring-analyst) | 3 | Skip rollout-follow; report-only |
| 10 LEARN | 1 subagent | 1 | Run inline |

### Blast-radius gate (Phase 3 Step 0 addition)

When changed files touch **≥2 modules** OR modify a **public API**
(HTTP endpoint, gRPC service definition, Kafka message schema, exported
function signature), run a callers scan before writing the plan:

- Code-graph tool available → use it to find all callers of the changed symbol
- No code graph → `grep -r "<changed-symbol>" --include="*.go" .` (or
  language equivalent) across the repo

Document the caller count in the plan. If callers > 10, flag affected
tasks as `high-blast-radius` and add a regression test task to the plan.

This runs regardless of stack tag — blast-radius is orthogonal to
technology choice.

### Context budget — conditional compaction trigger

Invoke `/strategic-compact` between phases when remaining context drops
below ~20% (< 200K on a 1M session, < 40K on a 200K session). Natural
checkpoints: after Phase 1 / Phase 5, **before Phase 6 / Phase 7**
(both dispatch subagents whose findings you reason over), after any
unplanned deep-dive. If you can't measure precisely, compact
preemptively past Phase 5 or after reading >5 large files in a row.
A full e2e run dispatches 10+ subagents — running individual phases
manually is the cost-aware alternative.

For deeper diagnosis of context consumption (what's eating the budget,
not just when to compact), invoke `/context-budget` — audits agents,
skills, MCP servers, and rules and returns a prioritized token-savings
report. For per-subagent model tiering decisions (Haiku/Sonnet/Opus
picks, MCP-vs-CLI tradeoffs, modular file splits), invoke
`/agent-token-optimization`.

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
