---
name: visual-critique
description: >-
  Heuristic and expert critique of an EXISTING UI screen/component — structured,
  severity-rated feedback rather than fixes. Use whenever the user wants a UI/UX
  "critique", "design review", "heuristic evaluation", "Nielsen review", "what's
  wrong with this screen", "usability problems", or a graded read on visual hierarchy,
  composition/layout balance, typography systems, or brand consistency. Produces
  observation→problem→fix notes with pass / minor / major ratings and 0–4 Nielsen
  severity scores. Do NOT use to implement fixes (that's ui-uplift / ui-ux-pro-max)
  or to write copy (ux-writing-skill).
---

# Visual Critique — structured UI critique & heuristic evaluation

Diagnose, don't fix. This skill gives an existing screen a disciplined, severity-rated
critique across five lenses. It is the **heuristic/critique** node that `ui-uplift`
routes to during its Audit phase — feed its findings back into ui-uplift's prioritize
step.

## When to run which lens
Pick the lenses that match the concern; run all five for a full design review.

| Lens | Reference file | Output |
|------|----------------|--------|
| Visual hierarchy (entry point, eye flow, weight, emphasis) | `references/critique-visual-hierarchy.md` | pass/minor/major per dimension |
| Composition (balance, whitespace, rhythm, gestalt) | `references/critique-composition.md` | pass/minor/major per dimension |
| Typography (scale, readability, consistency, token compliance) | `references/critique-typography.md` | pass/minor/major + token names |
| Brand consistency (mood / voice / tokens) | `references/critique-brand-consistency.md` | divergences vs project ref files |
| **Heuristic evaluation (Nielsen 10 + 0–4 severity)** | `references/heuristic-evaluation.md` | issue list rated 0 (none) – 4 (catastrophe) |

## Method
1. **Scope** — name the screen(s)/flow being critiqued; capture ground truth (read the
   code, and screenshot via Playwright MCP if a running app is available).
2. **Run the lenses** — read each relevant reference file above and apply its dimensions.
   For each finding emit **Observation → Problem → Fix**, then a rating.
3. **Heuristic pass** — walk the flow against Nielsen's 10 heuristics; rate each issue
   0–4 severity (0 = not a problem … 4 = usability catastrophe, must fix before release).
4. **Compile** — sort by severity, group by lens, surface the top 5 must-fix items.

## Guardrails
- Critique only — propose fixes as text, do not edit code here. Hand the prioritized
  list to `ui-uplift` (which owns audit→fix→verify) or `ui-ux-pro-max` for recipes.
- Brand lens needs project `mood.md` / `voice.md` / `tokens.md`; if absent, say so and
  skip that lens — never invent brand rules.
- Be specific: every finding cites a concrete element/location and an actionable change.

<!-- PROVENANCE / LOCAL PILOT (2026-06-08):
  Source: Owl-Listener/designer-skills (MIT, © 2026 MC Dean) — `visual-critique` plugin
  (critique-visual-hierarchy / -composition / -typography / -brand-consistency) +
  `prototyping-testing/heuristic-evaluation`. Sub-skills copied verbatim under references/.
  Wrapper authored locally to make the bundle one routable skill for the ui-uplift router.
  Promoted to mobile-agent-toolkit (AQ-3 ui-uplift suite). -->

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
