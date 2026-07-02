---
name: a11y-audit
description: >-
  Automated accessibility (a11y) testing of a RUNNING web app via axe-core driven
  through Playwright — real WCAG violations, not guesses. Use whenever the user wants
  to "run an accessibility audit", "check a11y", "axe scan", "WCAG check", "find
  accessibility violations", "is this screen accessible", or accessibility comes up as
  a must-fix during a UI review. Loads the page, injects axe-core, runs the WCAG 2.0/2.1
  A+AA ruleset, and reports violations grouped by impact (critical→minor) with rule id,
  help URL, offending selectors, and fix pointers. Do NOT use for static a11y *knowledge*
  /ARIA-pattern guidance (use ui-ux-pro-max) or for general functional UI testing
  (use webapp-testing) — this is the programmatic a11y-violation scanner specifically.
---

# a11y-audit — programmatic accessibility testing

A **thin runner**: it drives [axe-core](https://github.com/dequelabs/axe-core) (MPL-2.0,
fetched at runtime — not vendored) through Playwright against a *running* page and
reports real WCAG violations. Knowledge (how to fix an ARIA pattern, contrast theory)
lives in `ui-ux-pro-max`; functional Playwright mechanics live in `webapp-testing`.
This skill is the bridge that produces evidence.

## Prerequisites
- A running app or a built HTML file to point at.
- Playwright: `pip install playwright && playwright install chromium`.
- axe-core is pulled from CDN at runtime; for offline use pass `--axe-path` to a local
  `node_modules/axe-core/axe.min.js`.

## Run it
Always start with `--help`. The script is a black box — don't read its source unless
you must customize.

```bash
python scripts/run_axe.py --help
python scripts/run_axe.py --url http://localhost:5173
# tighten/loosen the ruleset:
python scripts/run_axe.py --url http://localhost:5173 --tags wcag2aa,wcag21aa
# audit a built file with no server:
python scripts/run_axe.py --file ./dist/index.html
# keep the raw JSON for diffing across runs:
python scripts/run_axe.py --url http://localhost:5173 --json axe-before.json
```

If the app isn't running yet, start its dev server first (the `webapp-testing` skill's
`scripts/with_server.py` manages server lifecycle — reuse it rather than reinventing).

## How to use the output
The runner prints violations grouped **critical → serious → moderate → minor**, each with:
rule id, help text + WCAG help URL, affected element selectors/snippets, and axe's
`failureSummary` fix hint. Exit code `1` = violations found, `0` = clean.

Triage order for reporting back into `ui-uplift`:
1. **critical** + **serious** → must-fix (color-contrast, missing form labels, missing
   alt text, ARIA misuse, keyboard traps, document-language).
2. **moderate** / **minor** → fix opportunistically.
3. For each, hand the fix to `ui-ux-pro-max` (the *how*) and apply via `ui-uplift`'s fix step.

## Caveats (state honestly)
- axe-core catches ~30–50% of WCAG issues automatically; it cannot judge meaningful
  alt-text quality, logical focus order intent, or whether copy makes sense. Pair an
  automated scan with the manual a11y lens in `visual-critique` / `ui-ux-pro-max`.
- RTL note: run with the app in its real direction; a clean axe pass does NOT prove RTL
  layout correctness — that's `polyglot` + `localization-design` territory.

## Optional: programmatic contrast spot-check
axe already reports `color-contrast`. If you need a one-off contrast ratio for a specific
pair, compute WCAG relative luminance directly rather than installing a tool — the formula
is in axe's `color-contrast` help URL.

<!-- PROVENANCE / LOCAL PILOT (2026-06-08):
  Authored locally (no good off-the-shelf install existed). Drives axe-core (Deque, MPL-2.0,
  fetched at runtime — NOT vendored here, so no license entanglement) via Playwright,
  reusing the webapp-testing skill's native-Playwright pattern. Promoted to mobile-agent-toolkit (AQ-3 ui-uplift suite). -->

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
