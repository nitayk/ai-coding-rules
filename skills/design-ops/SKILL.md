---
name: design-ops
description: >-
  Design-to-development handoff and implementation QA. Use whenever the work crosses
  the design→code boundary: writing a developer handoff spec (measurements, spacing,
  behaviors, assets, edge cases, states), or building a design-QA checklist to verify
  an implementation matches the intended design. Trigger phrases: "handoff spec",
  "hand this off to dev", "spec this for engineering", "design QA", "does the build
  match the design", "implementation review checklist", "redline this". Do NOT use to
  critique aesthetics (visual-critique) or to implement the UI (ui-ux-pro-max / ui-uplift).
---

# Design Ops — handoff specs & implementation QA

The bridge between a design intent and a faithful build. Two modes:

| Mode | When | Reference file |
|------|------|----------------|
| **Handoff spec** | Producing a precise spec for an engineer to build from | [`references/handoff-spec.md`](references/handoff-spec.md) |
| **Design QA checklist** | Verifying a built UI matches the intended design | [`references/design-qa-checklist.md`](references/design-qa-checklist.md) |

## Step 0 — find the source of truth (check Claude Design FIRST)
Before treating mockups/PRDs dropped in the repo as the design source, check whether the
surface has a **Claude Design project** (claude.ai/design). If it does, that — not a flat
PNG + prose PRD — is the source of truth, and it's structured + buildable:
- `DesignSync` MCP tool → `list_projects` to find a matching project, then `get_file` on
  `_ds_manifest.json` for machine-readable **tokens** (name/value/kind/definedIn), card
  groups, and font status; plus the project's real `.jsx`/`.css` component files and any
  `_adherence.oxlintrc.json` lint config. (The `/design-sync` skill orchestrates this.)
  **If the `DesignSync` tools aren't available, don't skip this check silently** — tell the
  user and prompt them to enable it (it ships with Claude Code's design integration; the first
  call adds `user:design:read/write` scopes to the claude.ai login). Proceed once available, or
  record that the source-of-truth check was skipped.
- Build the handoff spec / QA checklist **from those tokens + components**, citing token
  names — don't re-measure off a screenshot when the exact values are right there.
- No Claude Design project? Fall back to the normal flow below (mockups + the repo's tokens).
- Verified good on a real round-trip (AQ-64, 2026-06-27): tokens round-trip byte-perfect and
  the manifest is directly consumable. This genuinely replaces the manual mockup-drop loop —
  *when a designer/PM maintains the project.* For code-is-truth dev tools it adds nothing.

## Method
- **Handoff:** read [`references/handoff-spec.md`](references/handoff-spec.md) and produce measurements, spacing,
  behaviors, asset references, all states, and edge cases — leave nothing implicit.
- **QA:** read [`references/design-qa-checklist.md`](references/design-qa-checklist.md) and produce a checklist that
  verifies spacing/type/color tokens, states, responsive behavior, and a11y against the
  spec. This is the **verify** companion to `ui-uplift`'s final step.

## Guardrails
- **Prefer a Claude Design project as the source of truth** when one exists (Step 0) — pull
  exact tokens/components via `DesignSync`/`/design-sync` rather than re-deriving from a
  mockup. Otherwise reference the project's existing design tokens and component library
  (see ui-uplift's context-awareness section). Don't invent values.
- This is process/handoff knowledge; `ui-uplift` owns the end-to-end sequence.

---

*Concept adapted in spirit (MIT) from Owl-Listener/designer-skills (`design-ops`, © 2026 MC Dean,
[github.com/Owl-Listener/designer-skills](https://github.com/Owl-Listener/designer-skills)). This
skill and its two reference files (`handoff-spec`, `design-qa-checklist`) are an original rewrite —
the handoff/QA dimensions are common design-engineering practice; the wording, the Claude Design
Step 0, and the Unity-context guardrails are ours.*

<!-- PROVENANCE: originated as a user-level local pilot (2026-06-08); the wrapper + reference
content were authored/rewritten in original wording (NOT a verbatim vendor of the upstream — so
this carries no .subtree-source and is editable in-tree, track (b) per SOURCES.md conventions /
the /handoff precedent). 2026-06-27 (AQ-64): added Step 0 — check for a Claude Design project
(DesignSync / /design-sync) as the source of truth before falling back to mockups-in-the-dir.
Promoted to mobile-agent-toolkit on 2026-06-28 via AQ-64. -->

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
