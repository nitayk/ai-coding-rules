---
name: ui-uplift
description: >-
  Point this at an EXISTING UI (a component, page, screen, or running app) and it
  systematically makes it better — clearer, more readable, better visual hierarchy,
  more accessible, more polished. Use whenever the user says "make this UI/screen
  better", "improve the UX", "clean this up", "this looks off / cluttered / hard to
  read", "polish this page", "improve accessibility/readability", or points at a
  frontend file and wants it improved. This is the unified CONTEXT-AWARE ROUTER — it
  owns the audit→prioritize→fix→verify SEQUENCE and, for each UI/UX aspect, DELEGATES
  the design KNOWLEDGE to the right specialist skill (ui-ux-pro-max, frontend-design,
  a11y-audit, polyglot, localization-design, ux-writing-skill, visual-critique,
  interaction-design, design-ops, web-artifacts-builder, webapp-testing). Do NOT use
  for building a brand-new UI from scratch (use ui-ux-pro-max directly) or for
  non-visual refactors.
---

# UI Uplift — the context-aware UI/UX router

You are a **conductor**, not an encyclopedia. The design *knowledge* lives in specialist
skills. This skill owns the **"when / in what order"** and, for every aspect, **routes to
the skill that owns the "what."** A disciplined pass that turns "make it better" into
prioritized, reviewable changes on code that already exists.

**Core principle:** never rewrite wholesale. Audit → rank by user-impact → fix the
high-impact issues → verify. Preserve behavior, the existing design system, and the
project's conventions. Improve, don't redesign (unless the user explicitly asks).

---

## Routing table — aspect → skill (delegate by *invoking*, never duplicate)

**How to delegate (this is the whole point of the router — do not skip it):** when an aspect
below is in play, **actually invoke the specialist via the Skill tool** to pull its recipe —
e.g. `Skill(skill="a11y-audit")`, `Skill(skill="ui-ux-pro-max:ui-ux-pro-max")`. Do **not**
write design rules from your own memory when a specialist owns them; the specialist is the
source of truth and stays current as it's updated. The **Invoke** column gives the *exact*
skill id — copy it verbatim. Bare names for user-level skills; `plugin:skill` for plugin
skills (a bare `Skill(skill="ui-ux-pro-max")` will NOT resolve — it must be the namespaced id).

| UI/UX aspect | Invoke (exact `skill` id) | Notes |
|---|---|---|
| Visual / typography / color / dark-mode | `ui-ux-pro-max:ui-ux-pro-max` | 50+ styles, 161 palettes, 57 type pairings |
| Components + interaction states (hover/focus/active/disabled) | `ui-ux-pro-max:ui-ux-pro-max` | static states & component patterns |
| Performance — *knowledge* (what to optimize) | `ui-ux-pro-max:ui-ux-pro-max` | perf guidelines |
| Forms-knowledge / charts / data-viz | `ui-ux-pro-max:ui-ux-pro-max` | 99 UX guidelines, 25 chart types |
| Taste / "make it look good" judgment | `mobile-agent-toolkit:frontend-design` | aesthetic sensibility |
| Prototyping / build a throwaway to compare | `mobile-agent-toolkit:web-artifacts-builder` | new artifact, not the real app |
| Functional testing (does it work) | `mobile-agent-toolkit:webapp-testing` | native Playwright |
| **Accessibility AUDIT (real WCAG violations)** | **`a11y-audit`** | axe-core via Playwright on a running app |
| **Runtime-defect EVIDENCE — perf/jank/console/network on a LIVE page** | **`chrome-devtools` MCP** (raw MCP, not a skill — call its tools directly) | real **LCP + layout-shift (CLS)**, **console errors**, network waterfall on a *running* page; the "why is the live page broken" axis Playwright can't answer. **REQUIRES the chrome-devtools MCP. First check its `mcp__chrome-devtools__*` tools are available; if they are NOT, do not skip silently — tell the user it's not installed and prompt them to install it:** `claude mcp add chrome-devtools -s user -- npx chrome-devtools-mcp@latest` (needs Chrome; then `/mcp` reconnect or restart). Proceed only once it's installed, or explicitly record that runtime-evidence was skipped because the user declined. |
| **RTL / i18n — code actions** | **`polyglot`** | string→t() extraction, logical props, bidi, Intl |
| **RTL / i18n — design decisions** | **`localization-design`** | text expansion, RTL mirror rules, cultural |
| **Microcopy / UX writing** | **`ux-writing-skill`** | errors, empty states, onboarding, tone, audit |
| **Heuristic critique / Nielsen review** | **`visual-critique`** | severity-rated diagnosis |
| **Forms depth / motion / micro-interactions / loading / feedback** | **`interaction-design`** | the temporal/behavioral layer |
| **Design→dev handoff / implementation QA** | **`design-ops`** | handoff-spec, design-qa-checklist |
| **Design-system source of truth (pull tokens/components from Claude Design)** | **`design-ops`** (Step 0) + **`DesignSync` MCP** / `/design-sync` | when a designer/PM maintains the surface's system in claude.ai/design — pull structured tokens + components instead of guessing from a mockup. **Needs the `DesignSync` MCP. Check its tools are available; if NOT, don't skip silently — tell the user and prompt them to enable it (it ships with Claude Code's design integration; the first call adds `user:design:read/write` scopes to the claude.ai login).** Proceed only once available, or record that the design source-of-truth check was skipped. |

> a11y *knowledge* (how to fix an ARIA pattern, contrast theory) stays with
> `ui-ux-pro-max:ui-ux-pro-max`; `a11y-audit` produces the *evidence* (the violation list).
> RTL needs BOTH `polyglot` (code) and `localization-design` (design) — invoke both; they are
> complementary, not either/or.
>
> **Cross-plugin delegates are OPTIONAL — never hard dependencies.** `ui-ux-pro-max:ui-ux-pro-max`
> ships in its own **separate plugin** (not this toolkit), and `frontend-design` /
> `web-artifacts-builder` / `webapp-testing` are toolkit skills that a consumer may not have
> enabled. This router does **not** assume any of them is installed. Treat every routed
> specialist as invoke-**if-available**: try the `Skill(...)` call, and if it doesn't resolve,
> degrade gracefully per the rule below. Do not bundle or vendor another plugin's skill to
> satisfy a route.
>
> **If a `Skill(...)` invocation fails to resolve** (skill not installed in this environment),
> say so explicitly, fall back to your own best knowledge for that aspect, and flag that the
> recipe is un-sourced — never silently pretend you delegated.

---

## Context-awareness — detect the repo type FIRST

Before auditing, determine whether the target UI lives in a repo with an
**established design system** (DESIGN-SYSTEM) or is a **greenfield / personal
project** (GREENFIELD). Check the stack and conventions: presence of a first-party
component library (e.g. an `@org/*` design-system package that wraps a UI kit like
MUI), design-token packages, or a project `AGENTS.md`/`CLAUDE.md` documenting UI
standards → **DESIGN-SYSTEM**. A fresh Svelte/Tailwind/shadcn project with no house
component library → **GREENFIELD**.

### DESIGN-SYSTEM → reference the house standard (do NOT reinvent)
- **Component library:** reuse the project's existing component library before writing
  new components. If the house rule is "never import the underlying UI kit (e.g.
  `@mui/material`) directly — always go through the wrapper library," honor it.
- **Design tokens:** use the project's semantic design tokens, not raw hex/px.
- **Accessibility bar:** hold to the project's documented accessibility standard
  (target WCAG **AA** by default). Run `a11y-audit` for evidence.
- **Review lens — audit dimensions** (apply these; ground each against the project's
  own component/best-practices docs where they exist — don't fabricate house specifics):
  1. **Component reuse** — reach for an existing house/library component before building one.
  2. **Design-token / no style-override** — use theme variables, not raw hex/px; avoid custom
     styling & style overrides.
  3. **All states present** — hover/focus/active/disabled **plus** loading + error + empty,
     surfaced clearly to the user.
  4. **Responsive** — view adapts across breakpoints.
  5. **WCAG-AA / inclusive design** — hold to the project's accessibility guidelines; run
     `a11y-audit` for the evidence (cite the audit output; don't invent rule IDs).

### GREENFIELD / personal → generic knowledge + the project's own stack
- Lean on `ui-ux-pro-max` general rules + `frontend-design` taste; honor the project's
  existing **Tailwind/shadcn** conventions and tokens.
- **CLI caveat:** `ui-ux-pro-max`'s per-stack CLI/scaffold commands are **React-Native-only**.
  For **web / Svelte / React-web**, use its *general* rules (styles, palettes, type, UX,
  a11y, charts) but do **not** run its RN stack commands — defer build/taste to
  `frontend-design` and the project's own tooling.

---

## The sequence

### 1. Capture the current state — and STATE the context
- Read the target file(s). Note stack, styling system, existing tokens/components.
- **Check for a Claude Design project as the design source of truth** before assuming the
  design lives only in the code or in dropped mockups: `DesignSync` MCP `list_projects`
  (the call may silently add design scopes to the claude.ai login). If a project matches
  this surface, pull its `_ds_manifest.json` tokens + components via `design-ops` Step 0 and
  audit against *those* — that's the intended design, the code is the implementation of it.
  If the surface is a **code-is-truth dev tool with no designer** (e.g. an internal console),
  skip this — there's no upstream project to consult and the repo tokens are the truth.
- **Determine and explicitly announce: DESIGN-SYSTEM or GREENFIELD** (per "Context-awareness"
  above), and *why* — cite the signals you used (a house component library / `@org/*`
  design-system import, a project `AGENTS.md` documenting UI standards, vs a fresh
  Tailwind+shadcn project). This is the first thing you output, because it picks the standard
  you audit against. Don't proceed until you've said it.
- If a running app/URL exists, screenshot it (Playwright MCP) for visual ground truth.
- **Respect what's there:** existing tokens, component library, i18n, and especially
  **RTL** (e.g. Hebrew-first UIs — never break direction-awareness).

### 2. Audit — run every lens, INVOKING each routed specialist
Score the UI against each lens; record concrete issues with evidence (file:line / visual).
For the *standards* behind each lens, **invoke the routed specialist via the Skill tool**
(exact id from the routing table) and use *its* recipe — don't invent rules from memory. If a
lens clearly applies (e.g. the screen is RTL, or has user-facing copy, or has a11y risks), the
corresponding `Skill(...)` call is **expected**, not optional. Skipping a clearly-applicable
specialist is the failure mode this router exists to prevent.

1. **Clarity & hierarchy** → `visual-critique` (visual-hierarchy, composition) + `ui-ux-pro-max`.
2. **Readability** → `ui-ux-pro-max` (typography) + `visual-critique` (critique-typography).
3. **Accessibility** *(must-fix)* → `a11y-audit` for real WCAG violations; `ui-ux-pro-max`
   for the fix patterns. DESIGN-SYSTEM repos: hold to the project's inclusive-design guidelines / WCAG AA.
4. **RTL / i18n** *(must-fix when localized)* → `polyglot` (code: logical props, bidi,
   t()-extraction, Intl) + `localization-design` (design: expansion, mirroring).
5. **Microcopy** → `ux-writing-skill` (labels, errors, empty/loading states, tone).
6. **Consistency** → `ui-ux-pro-max` + (DESIGN-SYSTEM) component-reuse/design-token compliance.
   All states present: hover/focus/active/disabled + loading/empty/error.
7. **Forms / motion depth** → `interaction-design` (form-design, animation, micro-interaction,
   loading-states, feedback-patterns).
8. **Polish** → `ui-ux-pro-max` + `frontend-design` taste.
9. *(optional)* **Heuristic pass** → `visual-critique`'s `heuristic-evaluation` (Nielsen 10, 0–4 severity).

### 3. Prioritize by user-impact
Rank: **clarity > readability > accessibility(must-fix) > RTL/i18n(must-fix when localized)
> consistency > microcopy > forms/motion > polish.** Present a short prioritized plan
(top issues + proposed fix + which skill supplies the recipe) **before touching code.**
This is the review gate.

### 4. Improve — implement, with review
- Apply fixes in priority order. For each, pull the concrete recipe from the **routed**
  skill (exact spacing/scale/contrast/component/RTL/copy pattern for the stack).
- **Work reviewably:** worktree/branch or clearly-scoped diff; small, labeled commits per
  issue class. Never a big-bang rewrite. Keep behavior identical unless the user OK'd a change.
- Stay inside the existing design system — DESIGN-SYSTEM: reuse the house component library +
  design tokens; GREENFIELD: reuse Tailwind/shadcn tokens. Don't introduce a new style language unless asked.

### 5. Verify
- Re-check the changed UI against the Step-2 lenses — did the issues actually close?
- Re-run `a11y-audit` (compare violation count before/after) and, if you screenshotted,
  show before/after. For DESIGN-SYSTEM repos, run the `design-ops` design-QA checklist.
- **If a live page is in play, runtime-verify with the `chrome-devtools` MCP:** first confirm
  its `mcp__chrome-devtools__*` tools are available — **if they are NOT, don't silently skip:
  tell the user and prompt them to install it** (`claude mcp add chrome-devtools -s user -- npx
  chrome-devtools-mcp@latest`, needs Chrome; then `/mcp` reconnect or restart). Once available,
  confirm the uplift introduced **no new console errors** (`list_console_messages`) and didn't
  regress perf — capture **LCP + layout-shift (CLS)** via `performance_start_trace`/`_stop_trace`
  before vs after. This is the runtime counterpart to the a11y before/after diff. Genuinely skip
  only when there's no running app (static-only change) — not when the MCP is merely missing.
- Run the project's lint/tests/build so the change is green.
- Report: issues found → fixed → deferred (with why), and what to eyeball.

---

## Guardrails
- **Delegate, don't duplicate.** If you're about to write design rules from scratch, stop —
  route to the owning skill (see table). This skill is the workflow + routing only.
- **Improve ≠ redesign.** Match the product's existing taste; minimal, high-impact diffs.
- **Accessibility & RTL are must-fix**, not optional polish.
- **Review before write** (Step 3 gate) and **verify after** (Step 5). No silent rewrites.
- **Right standard for the context:** DESIGN-SYSTEM → the house component library + design tokens +
  the project's a11y guidelines; GREENFIELD → generic `ui-ux-pro-max`/`frontend-design` + the project's stack
  (and remember the RN-only CLI caveat for web/Svelte).

<!-- PROVENANCE: originated as a user-level local pilot (2026-06-08), expanded from a seed
audit-orchestrator into this unified context-aware UI/UX router. Validated in real use before
promotion: context (DESIGN-SYSTEM/GREENFIELD) detection correct across runs, and specialist delegation
fires end-to-end (a11y-audit returns real axe WCAG violations; polyglot / localization-design /
ux-writing-skill / visual-critique / interaction-design and the namespaced
ui-ux-pro-max:ui-ux-pro-max all resolve when present).

Design choices baked in (don't regress): (1) the routing table lists EXACT invocable skill ids —
a bare `ui-ux-pro-max` does NOT resolve; it must be `ui-ux-pro-max:ui-ux-pro-max`, and
frontend-design / web-artifacts-builder / webapp-testing are `mobile-agent-toolkit:`-namespaced;
(2) delegation is an expected `Skill(...)` call, not passive "route to"; (3) DESIGN-SYSTEM/GREENFIELD context
is a stated first action; (4) cross-plugin delegates are optional — degrade gracefully, never
bundle another plugin's skill; (5) fallback-honesty when a skill won't resolve.

Promoted to mobile-agent-toolkit on 2026-06-28 via AQ-64 (supersedes the earlier 2026-06-18
keep-local decision — reversed by Nitay 2026-06-28). The same change set added the Step-1
"check for a Claude Design project as the source of truth" check + the DesignSync routing row
(verified round-trip: byte-perfect token sync; structured _ds_manifest.json + buildable .jsx/.css;
gated to surfaces with a designer/PM-maintained Claude Design project, skipped for code-is-truth
dev tools). -->

<!-- NOT in scope here: image-first pipelines (image→code, imagegen mood-boards) require an
image-generation capability this environment lacks; harvest those only if an image-gen tool lands
AND a greenfield visual-reference need appears. ui-ux-pro-max + this router already cover
improve-existing. -->

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
