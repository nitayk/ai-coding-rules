---
name: interaction-design
description: >-
  Depth on forms, motion, and interaction states for an existing or planned UI. Use
  whenever the work is about HOW a UI behaves over time — form flows that minimise
  friction and prevent errors, animation/motion design, micro-interaction specs
  (trigger→rules→feedback→loop), loading/skeleton/progressive-reveal states, or
  feedback patterns (confirmations, toasts, status, notifications). Trigger phrases:
  "improve this form", "the form is confusing", "add motion/animation", "spec the
  micro-interactions", "loading states", "empty/error/success feedback", "transitions
  feel off". Do NOT use for static visual styling (ui-ux-pro-max) or copy (ux-writing-skill).
---

# Interaction Design — forms, motion & interaction states

Where `ui-ux-pro-max` covers static component states, this skill goes deep on the
*temporal/behavioral* layer. It is the **forms/motion depth** node `ui-uplift` routes to.

## Pick the reference for the concern
Read the matching reference file and apply its patterns:

| Concern | Reference file |
|---------|----------------|
| Form structure, validation, error prevention, completion | `references/form-design.md` |
| Motion / animation principles (easing, duration, purpose) | `references/animation-principles.md` |
| Micro-interaction spec (trigger / rules / feedback / loop & mode) | `references/micro-interaction-spec.md` |
| Loading, skeleton, progressive content reveal | `references/loading-states.md` |
| Feedback: confirmations, status updates, notifications | `references/feedback-patterns.md` |

## Method
1. Identify which of the five concerns is in play (often more than one — a form usually
   needs form-design + loading-states + feedback-patterns together).
2. Read the relevant reference file(s) and apply the pattern to the actual component.
3. Keep motion purposeful and respect `prefers-reduced-motion`; keep interactions
   accessible (focus, keyboard, target size) — defer the a11y check to `a11y-audit`.

## Guardrails
- Behavior over decoration — every animation/micro-interaction must serve a user goal.
- Stay inside the project's existing motion/interaction conventions; don't invent a new
  motion language unless asked.
- This is the knowledge layer; `ui-uplift` owns the audit→fix→verify sequence.

<!-- PROVENANCE / LOCAL PILOT (2026-06-08):
  Source: Owl-Listener/designer-skills (MIT, © 2026 MC Dean) — `interaction-design` plugin.
  Sub-skills form-design / animation-principles / micro-interaction-spec / loading-states /
  feedback-patterns copied verbatim under references/. Wrapper authored locally to expose
  the bundle as one routable skill. Promoted to mobile-agent-toolkit (AQ-3 ui-uplift suite). -->

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
