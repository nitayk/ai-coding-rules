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
  IDEA → 0 INTAKE → 1 RESEARCH → 2 DESIGN → 3 PLANNING → 4 SETUP →
         5 EXECUTION → 6 QUALITY GATES → 7 REVIEW → 8 VERIFICATION →
         9 DELIVERY → 10 LEARN → MERGED PR
```

Roles + model per phase: see Roles table below.

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
| **Security Reviewer** | `security-reviewer` | sonnet → opus on auth/crypto/payment/allowlist diffs | OWASP, secrets, injection, auth. Read-only in this skill (instruct via prompt). Tier up when Phase 8 empirical-check categories appear in changed files. |
| **Code Cleanup** | `code-cleanup` (or `general-purpose` fallback) | haiku | Mechanical removal of debug artifacts, dead imports, AI noise (Phase 6 gate 1) |
| **Simplifier** | `code-simplifier` | sonnet | Code clarity, DRY, complexity reduction. Preserves behavior exactly |
| **Code Reviewer** | `code-reviewer` | sonnet → override to opus | Requirements coverage, readability, edge cases. Never writes code |
| **QA / Sentinel** | `verifier` | sonnet (haiku-only for nested test-runner) | Skeptical validator: acceptance criteria, empirical-not-static checks, restore-semantics, smoke-test substitution decisions. Sonnet because every Phase 8 rule requires judgment haiku will fumble (PR #106 burned the team on exactly this). |
| **Test Runner** | `test-runner` | haiku | Execute test suites, parse failures. Pure mechanical — dispatched *inside* QA/Sentinel's flow when iterating |
| **Code Explorer** | `code-explorer` | sonnet → opus on cross-service stack | Trace execution paths, map dependencies (Phase 1 / Phase 3). Tier up when scan invokes /memgraph-analysis / /atlas-analysis / /full-network-analysis — sonnet routinely misses transitive call paths there. |
| **Git Workflow** | `git-workflow-specialist` | haiku for Phase 4 (mechanical setup); sonnet for Phase 9 (delivery decisions) | Phase 4 = `git worktree add` + file moves + tracker write (zero design judgment). Phase 9 = commit-message hard rule + delivery-hook decisions (judgment work — haiku will write `Co-Authored-By` lines) |
| **Skeptic** | `general-purpose` | opus | Challenge premises, find failure modes. Only when ambiguity detected |

**Key rules:**
- Same agent never writes AND reviews its own code
- Reviewers and QA are read-only in this skill — they report, they don't
  fix. Even if the agent type's tool list includes Write/Edit (e.g.
  `security-reviewer`), instruct it explicitly to report findings only.
- Engineers get focused context per task — not the full session history
- Escalate when stuck, don't guess

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
| **migration** | Research (use `/codebase-onboarding` instead), Design (replaced by `/service-breakdown` + `/code-migration`) | Repo-to-repo or service-to-service moves where preserving behavior + minimal diff matter more than design exploration |

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

**Stack sub-classification (NEW):** After picking the primary
classification (feature / bugfix / etc.), pick a stack tag that gates
the conditional skills downstream:

| Stack | Triggers / file patterns | Conditional skills enabled |
|-------|--------------------------|----------------------------|
| `langchain` | `langchain` import, `LangChain` in plan | `/framework-selection`, `/langchain-fundamentals`, `/langchain-middleware`, `/langchain-rag`, `/langchain-dependencies` |
| `langgraph` | `langgraph` import, `StateGraph`/`Send`/`interrupt()` in plan | `/framework-selection`, `/langgraph-fundamentals`, `/langgraph-persistence`, `/langgraph-human-in-the-loop` |
| `deep-agents` | `deepagents` import, `create_deep_agent()` in plan | `/framework-selection`, `/deep-agents-core`, `/deep-agents-memory`, `/deep-agents-orchestration` |
| `code-graph` | `code-graph/` path, Memgraph/Neo4j edits | `/code-graph-architect`, `/code-graph-fix-cycle`, `/code-graph-qa` |
| `web-frontend` | `*.tsx`, `package.json` with React/Vite, `chat-ui/` path | `/frontend-design`, `/web-artifacts-builder`, `/webapp-testing` |
| `infra` | `Dockerfile`, K8s manifests, ArgoCD, GitHub Actions | `/docker-patterns`, `/argocd-onboarding`, `/github-actions-workflows-helper`, `/kronus-onboarding` |
| `data` | Trino, BigQuery, Aerospike paths | `/trino-validation`, `/aerospike-best-practices` |
| `backend-go` | `go.mod`, `*.go` files | `/golang-testing` |
| `backend-scala` | `build.sbt`, `*.scala` files | `/scala-testing`, `/scala-dependency-hell`, `/scala-upgrade-agent` |
| `claude-api` | `import anthropic`, `@anthropic-ai/sdk`, Claude Messages API patterns | `/claude-api` |
| `rest-api` | new HTTP endpoints, `*Controller.scala`, `routes.go`, OpenAPI specs | `/api-design` |
| `service-architecture` | cross-service tracing, Memgraph/Atlas analysis, dependency mapping | `/code-structure-analysis`, `/memgraph-analysis`, `/atlas-analysis`, `/full-network-analysis` |
| `generic` | None of the above | (no extra skills enabled) |

> **Skill availability footnote:** Stack-conditional skills are invoked
> *when available*. Some (e.g. `framework-selection`, `langchain-*`,
> `langgraph-*`, `deep-agents-*`, `code-graph-fix-cycle`,
> `code-graph-qa`) live in **consumer project repos** (e.g.
> `agentic-evolution/.claude/skills/`) rather than this submodule. If
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

For broader multi-source synthesis (firecrawl + exa MCPs), invoke
`/deep-research` — appropriate for novel domains, library surveys, or
industry pattern scans. Skip for narrow tasks where docs lookup
suffices.

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

Invoke `/council` when the user expresses uncertainty between approaches,
or when approaches have fundamentally different trade-off profiles with no
dominant option. Council voices: Architect, Skeptic, Pragmatist, Critic.

For non-trivial architectural decisions (library/framework picks, key
patterns, data-model shape), invoke `/architecture-decision-records` to
capture the chosen approach and rejected alternatives as ADRs alongside
the design doc. Skip when there was a single viable approach.

**Stack-gated skills (NEW):** If the Phase 0 stack tag is `langchain` /
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
  default to `/memgraph-analysis` (callers, dead-code, execution paths
  via Cypher); escalate to `/atlas-analysis` (Kafka/Aerospike topology),
  `/code-structure-analysis` (deeper structural mapping), or
  `/full-network-analysis` (multi-repo end-to-end flows) only when
  Memgraph alone doesn't answer.
- **Read canonical sources for submodule-backed assets first.** If the
  change targets an asset that lives in a git submodule (e.g. skills
  from `mobile-cursor-rules` synced into consumer repos), the FIRST
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

## Phase 4: SETUP

**Role:** `git-workflow-specialist` subagent (haiku — pure mechanics)
**Announce:** "Phase 4: Setup — creating isolated workspace."

Invoke `/using-git-worktrees`. Non-skippable — even spikes get a worktree.

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
  behavioral diff must be zero. Invoke `/service-migration` for
  repo-to-repo or service-to-service moves where minimal diff matters.
- `hotfix`, `spike` — Skip TDD (speed and exploration first).

**Stack-conditional skills (wired at Phase 5):**
- `infra` stack — invoke `/mcp-builder` when the plan includes an MCP
  server scaffold; invoke `/argocd-onboarding` or
  `/github-actions-workflows-helper` when the plan touches deployment
  manifests or CI pipeline files.

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
(`/code-cleanup`, `/simplify`, `/security-review`,
`/best-practices-enforcement`).

1. **Code Cleanup** — `code-cleanup` subagent (haiku — mechanical), skill:
   `/code-cleanup`. Targets debug artifacts, AI-generated noise, dead
   imports, leftover `console.log` / `print` debugging. Skip on
   `docs-only`.

2. **Simplifier** — `code-simplifier` subagent (sonnet — behavior-
   preserving refactor needs judgment). **Default (cross-platform):**
   invoke `/code-simplification` (works on Claude Code, Cursor, Copilot
   — covers reuse, quality, efficiency, fixes). **Claude Code upgrade:**
   when running on Claude Code, prefer the built-in `/simplify` command
   — it dispatches three parallel review subagents which is broader than
   the single-agent skill. If neither is available, note in Phase 10
   and skip this single gate (the other gates still run).

3. **Security Reviewer** — `security-reviewer` subagent (sonnet default,
   **opus override** when changed files include cryptography, networking
   /URL/header parsing, payload construction, allowlists/denylists, or
   authentication code; see Phase 8 empirical-check categories for the
   canonical list. Instruct read-only despite its Write/Edit tools),
   skill: `/security-review`. Scan changed files for vulnerabilities.

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
> memory, or efficiency goals beyond what `/simplify` covers
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
<!-- Maintainer note: rule originated from operator memory `e2e/decision_fix_findings_inline_not_followup.md` (PR #106 dogfood — user picked "Fix all" for 4 findings). -->

> Note: `/security-review` is the per-PR scan (used here);
> `/security-audit` is a deeper periodic check for release boundaries.

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

**Author-side loop (NEW):** Once the reviewer returns findings, the
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
- **Production-traffic verification** (post-deploy or staging) —
  `/grafana-monitoring` for metrics dashboards, `/victoria-traces-
  analysis` for request-flow tracing across services. Use when the
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

Invoke `/finishing-a-development-branch`. Present delivery options as a
numbered list and wait for the user's choice:

- **Create PR** — invoke `/create-pr` for the basic PR; layer
  `/pr-workflow` for richer lifecycle (draft → ready → merge-strategy
  pick) and `/github-ops` alongside for CI status checks, PR triage,
  and release-branch ops
- **Merge to main** — if merge rights and CI passes
- **Keep branch** — for continued work later
- **Discard** — only for `spike` classification when the exploration
  didn't pan out

**Release boundary (optional).** When the PR closes a release
milestone, invoke `/generate-changelog` to produce release notes,
`/generate-docs` to update any API/module docs that changed, and
pair with `/security-audit` (the deeper periodic check referenced
earlier).

For **spike** classification: only show "Keep branch" and "Discard"
options. For **hotfix** that fails to deliver a working fix, use the
Error handling path in Cross-Phase Rules — not Discard.

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

## Phase 9.5: POST-DEPLOY VALIDATION (optional)

**Role:** QA / Sentinel — `verifier` subagent (sonnet)
**Announce:** "Phase 9.5: Post-deploy — watching production signals."

**Skip when:** spike, docs-only, or the PR targets a non-deployed artifact
(docs, skill files, config without a deployed service).

1. **Tag the deployment** — create a lightweight git tag linking the PR to
   the deployed commit:
   ```bash
   git tag "e2e/<session-slug>/deploy-$(git rev-parse --short HEAD)"
   git push origin "e2e/<session-slug>/deploy-$(git rev-parse --short HEAD)"
   ```

2. **Watch SLO panels** — invoke `/grafana-monitoring` to open the service's
   golden signals (request rate, error rate, latency P99, saturation). Watch
   for **5 minutes** (hotfix: 10 minutes). Alert threshold: any counter that
   was stable before the PR drops >5% within the watch window.

3. **Document rollback command** in the PR description under a "Rollback"
   section — the exact command to revert (e.g. `git revert <sha> && git push`,
   or the ArgoCD/Helm rollback command for deployed services).

4. **If anomaly detected**, surface a structured question before advancing:
   - [1] Rollback now — execute the rollback command documented in step 3
   - [2] Watch another 5 minutes — extend the window
   - [3] Expected — document as known regression and proceed

**Exit gate sentence:** "Phase 9.5 complete. SLO status: [stable/anomaly].
Watch duration: N min. Rollback documented: yes/no."

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
| 9.5 POST-DEPLOY | 1 subagent | 2 | Skip post-deploy watch |
| 10 LEARN | 1 subagent | 1 | Run inline |

### Blast-radius gate (Phase 3 Step 0 addition)

When changed files touch **≥2 modules** OR modify a **public API**
(HTTP endpoint, gRPC service definition, Kafka message schema, exported
function signature), run a callers scan before writing the plan:

- Code Graph MCP available → `/code-graph-architect` — find all callers
  of the changed symbol
- No Code Graph → `grep -r "<changed-symbol>" --include="*.go" .` (or
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

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
