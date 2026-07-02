# Handoff Spec

A handoff spec is the contract a developer builds from. The goal: an engineer can implement
the design accurately without guessing and without a second round-trip. Specify behavior and
exact values, not just appearance — reference design tokens, never raw hex/px, whenever the
project has them (or pull them from a Claude Design project per `design-ops` Step 0).

## What a complete spec covers

**Layout & visual**
- Spacing and sizing as token references (or exact px when no token exists)
- Color as token names, not literal hex
- Typography: style/role, size, weight, line-height
- Radius, shadow/elevation, opacity
- Responsive behavior per breakpoint (what reflows, what stays fixed)

**Interaction & motion**
- Every state: default, hover, focus, active, disabled — plus loading, empty, error
- Transitions/animations: trigger, duration, easing, which properties animate
- Pointer/gesture and keyboard behavior (tab order, shortcuts, focus management)

**Content**
- Min/max content, truncation and overflow rules
- Dynamic content: what varies and within what bounds
- Localization: text-expansion headroom, RTL mirroring
- The actual copy for empty / loading / error states

**Assets**
- Icons (format + naming convention), images (resolution/format/responsive variants),
  fonts (files or service), any custom graphics

**Edge cases & implementation notes**
- Smallest and largest realistic content
- Browser/device specifics worth calling out
- Accessibility requirements (roles/labels, keyboard, screen-reader, contrast target)
- Which existing components to reuse; data-shape and API assumptions; perf considerations

## How to write it well
- Tokens over raw values — the build stays on-system and survives a token change.
- Annotate behavior, not only the static frame.
- Cover all states, never just the happy path.
- Add redlines for any layout where spacing isn't obvious from tokens.
- When a Claude Design project exists, derive values from its `_ds_manifest.json` and cite the
  token names directly rather than re-measuring a screenshot.

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
