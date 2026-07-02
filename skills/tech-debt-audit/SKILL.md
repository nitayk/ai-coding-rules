---
name: tech-debt-audit
description: "Whole-repo, evidence-grounded tech-debt and architecture audit. Produces TECH_DEBT_AUDIT.md: hotspot-ranked, file-cited findings with severity/effort, owners, a debt-ratio rollup, and a required per-finding 'why this might actually be fine' counterfactual. Use when the user asks for a debt audit, codebase health check, architecture review, hotspot analysis, or a whole-repo code-quality / maintainability assessment — including 'where is the debt concentrated', 'what should we refresh', or 'is this codebase healthy'. Do NOT use for: a single diff/PR review (use /code-review-excellence), tactical cleanup of recently-changed code (use /code-cleanup or /code-simplification), a real security review (use /security-audit), or token/cost waste (use /cost-audit). User-invoked only; writes a file."
last-reviewed: 2026-06-22
disable-model-invocation: true
---

<!--
  Clean-room reimplementation. The whole-repo debt-audit *concept* and three design
  choices kept here (churn-first orientation, mandatory file:line citations, a required
  "looks fine" section) were inspired by ksimback/tech-debt-skill (MIT). No text was
  copied; this protocol, its evidence-grounding model, stack tooling, hotspot/coupling/
  bus-factor steps, org alignment, and cross-skill routing are first-party to
  mobile-agent-toolkit. Harness mechanics (task tracking, parallel subagents) are
  referenced via AGENTS.md so the skill stays portable across agent harnesses.
-->

# Tech Debt Audit

A deliberate, evidence-grounded audit of an **entire** repository (or a scoped module)
that produces `TECH_DEBT_AUDIT.md`: a ranked, cited, actionable debt register — not a
generic best-practices checklist.

Everything from here to the `---` divider is the protocol. The section after it is for
humans maintaining the skill.

## Operating principles

Two failure modes kill audits like this. Internalize both before you start — most of the
protocol exists to defend against them.

- **Vague filler.** "Error handling is inconsistent" with no anchor is a vibe, and vibes
  don't get fixed. So: **anchor first, narrate second.** Every concrete finding ties to a
  *deterministic anchor* — a real `file:line` you have read (not guessed), a tool's output
  (a linter/vuln/type-checker hit), a failing test, or a git-history fact. Before you write
  a citation, confirm it resolves to the code you're describing. An audit's whole value is
  that an engineer can act on it without re-deriving it.
- **Overcorrection.** The dominant failure of an LLM doing this job is *flagging correct,
  load-bearing code as broken* — and it gets worse the harder you push toward "find
  problems" and "propose fixes." A pattern that looks wrong in isolation is often there for
  a reason you can't see yet. So you **read code before judging it**, you carry a
  *confidence* level on every finding, and for each finding you do the adversarial check:
  "why might this be intentional / correct?" (this is what the required "looks fine" section
  is for — see Phase 3).

Also: find what's actually wrong in *this* repo — no diplomacy, no "overall well-structured"
filler. And don't pad: if a dimension has nothing material, say "Nothing material" and move
on. Padding makes an audit *feel* thorough while burying the findings that matter.

## Phase 1 — Orient and rank (do not skip)

Forming opinions before understanding the system produces bad audits. The goal of this
phase is to earn the right to have opinions in Phase 2 — and, crucially, to **point your
limited attention at the code that actually costs the team**, not the code that merely
looks messy.

1. Read the README, the package manifest (`go.mod` / `package.json` / `pyproject.toml` /
   `build.sbt` / `Cargo.toml`), and architecture docs (`/docs`, `/adr`, `CLAUDE.md` /
   `AGENTS.md`). Map the major modules/layers and the boundaries between them.
2. **Mine git history once — it yields four cheap, high-signal rankings:**
   - **Hotspots = churn × size/complexity.** `git log --format= --name-only --since="12 months ago" | sort | uniq -c | sort -rn` for change frequency; cross it with LOC/complexity. A file that is large *and* changes constantly is where debt compounds; a large file nobody touches is usually fine. **Deep-read the top hotspots; skim the cold corners.** This is the single best use of your attention budget.
   - **Change coupling.** Files that repeatedly change together in the same commits but have no static dependency reveal hidden coupling / a missing abstraction — a finding class you cannot see reading files one at a time.
   - **Defect density.** `git log --oneline --grep -iE 'fix|bug|hotfix' --since="12 months ago"` per file ranks where bugs cluster. (Caveat: grep-on-message is approximate — renames/refactors inflate it; treat as a signal, not proof.)
   - **Knowledge risk (bus factor).** `git shortlog -sn -- <hotspot>` — a hot, complex file authored ~entirely by one person (especially someone no longer active) is an operational risk worth flagging even when the code is fine.
3. Identify entry points, hot paths, and cold corners. Publish a phase plan with your
   harness's task-tracking mechanism (see `AGENTS.md`) so progress is visible.

Write a 1–2 paragraph mental model of the architecture **as it actually is** before Phase 2.
If it contradicts the README, that contradiction is itself a finding.

## Phase 2 — Audit across these dimensions

Ground every finding with `rg` / `ast-grep` / language-native tooling, anchored per the
operating principles. Concentrate effort on the Phase-1 hotspots.

1. **Architectural decay** — circular deps, layering violations, god files (>500 LOC) and
   god functions, logic duplicated across 3+ sites where an abstraction belongs, abstractions
   nobody uses, dead code (unused exports, unreachable branches, stale commented-out blocks),
   and the change-coupling pairs from Phase 1.
2. **Consistency rot** — multiple ways to do the same thing (HTTP clients, error handling,
   logging, config loading, validation, date handling). Naming drift. Folder structure that
   no longer reflects what the code does.
3. **Type & contract debt** — escape hatches (`any` / `as any` / `interface{}` / loose
   `dict` / `# type: ignore`), untyped boundaries, missing schema validation at trust
   boundaries.
4. **Test debt** — coverage gaps on hotspots/critical paths, tests that assert implementation
   instead of behavior, skipped/flaky tests, assertion-free tests, hot files with no tests.
5. **Dependency & config debt** — known CVEs (audit tools below) **and** freshness/EOL
   (abandoned deps, lockfile drift, majors behind — `go list -m -u all`, `npm outdated`,
   `pip list --outdated`), duplicate deps doing the same job, license risk, env-var sprawl
   (referenced but undocumented; defaults inconsistent across environments).
6. **Performance, concurrency & resource hygiene** — N+1 queries, sync work on async paths,
   blocking I/O on hot paths, leaked listeners/handles/goroutines, needless serialization.
   **Go: data races** — does CI run `go test -race`? `go vet` clean? (race bugs are invisible
   to default static analysis and are a high-severity class for a Go shop.)
7. **Error handling & observability** — swallowed exceptions, blanket catches, errors logged
   but not handled, inconsistent error shapes, missing structured logs on critical paths.
   Operability: do critical alerts have playbooks; are SLOs/monitoring present where they matter.
8. **Security hygiene** — obvious-only: hardcoded secrets, string-concatenated SQL, missing
   input validation at trust boundaries, permissive auth/CORS, weak crypto. This is a hygiene
   pass, **not** a security review — route anything real to `/security-audit`.
9. **Documentation drift** — README/docs claims that don't match reality, comments that
   contradict adjacent code, public APIs with no docstrings.

For a frontend repo, delegate accessibility/i18n debt to `/a11y-audit` and `/polyglot`
rather than reinventing them here.

### Stack tooling

Detect the stack from the manifest and run the relevant tools (in parallel where possible).
Prefer to **consume signals that already exist** over recomputing them — if the org runs
SonarQube (tech-debt badge), Codecov (coverage), Dependabot (vulns), or a committed
`.golangci.yml`, read those first and cross-check. If a tool isn't installed, note that in
the audit and move on — **don't** install dev tools globally without permission.

- **Go** — `govulncheck ./...`, `go vet ./...`, `staticcheck ./...`, `golangci-lint run`, `go test -race`.
- **TypeScript / JavaScript** — `npm audit`, `tsc --noEmit` (type drift), `npm outdated`. `npx knip`
  (dead exports) / `npx madge --circular` (cycles) / `npx depcheck` (unused deps) are useful but
  net-new tooling, not an org standard — note them as such if you rely on them.
- **Python** — `pip-audit`, `ruff check`, `vulture` (dead code), `mypy` (type drift), `pip list --outdated`.
- **Scala** — `sbt evicted` / dependency-check (conflicts), `scalafix` / `wartremover` if configured.
- **Rust** — `cargo audit`, `cargo udeps`, `cargo clippy -- -W clippy::pedantic`.

## Phase 3 — Deliverable

Write `TECH_DEBT_AUDIT.md` in the repo root. Frame debt as **interest, not principal**: the
question isn't "how ugly is this" but "how much does it tax every change" — which is exactly
why the hotspot ranking drives prioritization (a mess in code touched weekly costs far more
than a mess in code touched yearly). Structure:

- **Executive summary** — max 10 bullets, ranked by impact, plus a one-line **debt-ratio
  rollup** (rough remediation effort vs. codebase size, banded A–E) so the number is
  comparable across re-runs.
- **Architectural mental model** — the system as it actually is.
- **Findings table** — one row per finding, register-compatible so items paste straight into
  a tracker: `ID | Category | File:Line | Severity (H/M/L) | Confidence (High/Med/Low) |
  Effort (S/M/L or ~wks) | Owner | Root cause | Implication | Recommendation`. Owner = from
  `CODEOWNERS` or `git blame`. Aim for 30–80 findings; past that is noise.
- **Severity rubric (state it explicitly, then apply it).** Define what H/M/L mean for *this*
  repo up front and hold the line — LLMs systematically inflate severity, so expect the pull
  and resist it. **Cap the High band** (if everything is High, nothing is). Carry Confidence
  separately from Severity: a high-severity, low-confidence finding belongs in Open Questions,
  not as an assertion.
- **Top 5 ("if you fix nothing else")** — each with a concrete diff sketch or refactor
  outline, not vague advice.
- **Quick wins** — Low effort × Medium+ severity, as a checklist.
- **Things that look bad but are actually fine** — this is the overcorrection defense, so it
  is **required** and it is not one closing paragraph: for findings you considered and
  *dropped*, name them and give the evidence that they're intentional/load-bearing. An empty
  section means you didn't run the adversarial check — which means the findings above are
  under-scrutinized. This section is the best single signal that the audit went past
  checklist depth.
- **Open questions for the maintainer** — things you genuinely couldn't tell were debt vs.
  intentional (and every high-severity / low-confidence call). When in doubt, ask here; do
  not assert.

## Rules

- Anchor first: every concrete finding ties to a verified `file:line`, tool output, failing
  test, or git fact — confirm the citation resolves before writing it.
- Carry Confidence on every finding; route low-confidence calls to Open Questions, not assertions.
- Recommend specific, scoped changes. **Never recommend a rewrite** — and note this is a
  correctness safeguard, not just scope discipline: pushing toward fix-generation is exactly
  what drives the model to over-flag correct code.
- Don't pad. "Nothing material" is a valid, honest result.
- No sycophancy. Report what's broken — and, in the looks-fine section, what isn't.

## Output homes (org)

Don't leave an orphan doc. The audit is designed to feed existing surfaces — land it where
your org already tracks debt:
- A per-team **Tech Debt register** (the H/M/L + Root cause + Implication + Effort schema
  above matches the common Confluence template) — paste high/medium rows in.
- File **high-severity rows as Jira issues** with the established `tech-debt` label (plus
  qualifiers like `maintainability` / `hygiene` where they fit), each with acceptance criteria
  and a `verified at commit <sha>` provenance line.
- If the org runs a Backstage / IDP **scorecard**, the debt-ratio rollup and per-dimension
  findings map onto its quality pillar.

## Large repos — scope or fan out

If the repo is large (>50k LOC or >5 top-level modules), don't read it serially — you'll
exhaust context before you can write findings. Either **scope to one module**
(`tech-debt-audit src/payments`) or **fan out parallel subagents**, one per module (see
`AGENTS.md` and `/dispatching-parallel-agents`). Give each subagent: its module scope, the
dimensions list, the anchor-first citation requirement, and a finding cap. The lead merges,
dedupes, ranks, and writes the single deliverable.

## Repeat-run mode

If `TECH_DEBT_AUDIT.md` already exists, read it first. Mark fixed findings `RESOLVED`, update
stale ones, tag new ones `NEW`, and compare the debt-ratio rollup to last time so the trend
(getting better or worse?) is visible. This is where the audit earns its keep over time.

---

# Maintainer notes

## Why this skill exists

The toolkit's other review skills are scoped narrower: `/code-review-excellence` and the
`code-reviewer` agent are diff/PR-scoped, `/code-cleanup` and `/code-simplification` act on
recently-changed code, `/security-audit` is security-only, `/cost-audit` is token spend.
None answer "what is the accumulated debt across this *whole* repo, ranked by what it
actually costs us, and what do I fix first?" — this one does.

## Design choices that do the work

- **Hotspot-first attention (churn × complexity).** Process metrics (churn, author count)
  predict where defects and maintenance cost concentrate better than static size/complexity
  alone. Steering the deep read toward hot, complex files — and explicitly *away* from
  cold code — is the highest-leverage prioritization move and concentrates limited LLM
  attention where the "interest" is highest.
- **Anchor-first, verified citations.** Requiring every finding to resolve to deterministic
  evidence (read code / tool output / git fact) is the strongest defense against the two
  things that make automated audits worthless: hallucinated findings and ungrounded vibes.
- **The "looks fine" section as a per-finding adversarial check.** The dominant LLM failure
  here is *overcorrection* — flagging correct code as broken, made worse by fix-generation
  pressure. Forcing an evidence-backed counterfactual per finding (and forbidding rewrites)
  is aimed squarely at that, not at complacency.
- **Confidence separate from severity + a capped High band.** Models over-rate severity and
  are overconfident; separating the two axes and capping High keeps the ranking trustworthy.

## Limitations

Static + historical audit. Not a security audit (route to `/security-audit`) and not a
business-logic review (needs domain knowledge the model lacks). git-message defect-density
and bus-factor are approximate signals, not proof. It cannot see **dark debt** — failures
that emerge only from unforeseen runtime interactions — so the absence of a finding is not a
clean bill of health. It can't distinguish intentional from accidental simplicity; that's
what Open Questions is for.

## Tuning

The 9 dimensions are a floor. Add domain dimensions per repo — e.g. for agent/LLM codebases:
"prompt-injection surface", "tool-call cost per turn", "eval coverage"; for data/RTB repos
(ISX, IDP): "schema/API backward-compatibility". A project-level
`.claude/skills/tech-debt-audit/SKILL.md` overrides this global one when a repo needs custom
dimensions or different severity thresholds.

## Attribution

Clean-room reimplementation; the whole-repo-debt-audit concept and its three original design
choices were inspired by [`ksimback/tech-debt-skill`](https://github.com/ksimback/tech-debt-skill)
(MIT). No text was copied. The evidence-grounding model, hotspot/coupling/bus-factor/
defect-density steps, severity+confidence rubric, interest-not-principal framing, and org
output-homes are first-party additions grounded in code-health research (churn×complexity
hotspots, change coupling, truck factor) and general team conventions.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
