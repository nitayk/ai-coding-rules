# Design QA Checklist

A QA checklist turns "does the build match the design?" into a systematic pass instead of a
vibe check. Verify against the spec (or the Claude Design project per `design-ops` Step 0), not
from memory, and check exact values with browser dev tools.

## What to verify

**Visual accuracy**
- Colors resolve to the spec's design tokens
- Typography matches the specified style/size/weight/line-height
- Spacing and sizing match the token scale
- Radius, shadow/elevation, opacity are correct
- Icons render at the right size and color; images keep aspect ratio and quality

**Layout**
- Grid alignment is correct; nothing is off by a half-step
- Responsive behavior matches the spec at each breakpoint
- Content reflows cleanly — no unexpected overflow, clipping, or collapse
- Min/max widths respected

**Interaction**
- All states render: default, hover, focus, active, disabled (plus loading/empty/error)
- Transitions/animations match duration and easing
- Touch/click targets meet the minimum hit size (~44px)
- Keyboard navigation follows the intended order; focus indicators are visible

**Content**
- Real content fits — no placeholder/lorem left in
- Truncation behaves as specified
- Empty, loading, and error states display as designed with the right copy

**Accessibility**
- Contrast meets the target (WCAG AA unless stated otherwise)
- Screen reader announces sensibly; ARIA roles/labels are correct
- Focus management works; reduced-motion preference is respected

**Cross-platform**
- Works in the required browsers and devices
- Holds up under OS text-size and screen-density changes

## Running the pass
1. Developer self-checks against this list before requesting QA.
2. Designer does a visual QA pass against the spec.
3. File issues with side-by-side design-vs-build screenshots; rank by severity.
4. Verify each fix; log recurring misses so they become spec defaults next time.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
