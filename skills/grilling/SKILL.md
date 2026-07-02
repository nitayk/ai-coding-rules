---
name: grilling
description: Relentlessly interview the user to stress-test an EXISTING plan or design before building — walk the design tree in dependency order, recommend an answer per question, one at a time, and explore the codebase instead of asking. Use on "grill me", "stress-test this", "poke holes in this plan", or to sharpen /brainstorming's clarifying step inside /e2e Phase 2. Not a full design-to-spec workflow (that is /brainstorming).
---

# Grilling

Interview the user relentlessly about every aspect of this plan until you reach a
shared understanding. Walk down each branch of the design tree, resolving
dependencies between decisions one-by-one. For each question, provide your
recommended answer.

Ask the questions **one at a time**, waiting for feedback on each before
continuing. Asking multiple questions at once is bewildering.

**If a question can be answered by exploring the codebase, explore the codebase
instead of asking.** In this toolkit that means: grep, read the files, and for
cross-file or cross-service questions reach for `/code-graph-architect` (UADS +
active iAds-side repos) or `/memgraph-analysis` (iAds-core) before spending a
question on the user. Only ask the user what the code genuinely cannot answer.

## Why this is sharper than a flat question list

- **Dependency order, not arbitrary order.** Resolve the decision that other
  decisions hinge on first, then walk into the branches it opens. A plan is
  under-specified exactly where an upstream choice was never pinned down — this
  ordering surfaces those gaps instead of burying them under detail questions.
- **One question at a time** keeps each answer crisp and lets the next question
  adapt to it.
- **Recommend an answer every time.** Surfacing your prior lowers the user's
  burden to a yes/no/adjust and exposes your reasoning for them to correct.
- **Explore over ask.** Anything the codebase already settles is not a question —
  it is a lookup. Spend the user's attention only on genuine unknowns.

## When to use vs /brainstorming

`/grilling` is **only the interview**. It does not propose alternatives, write a
spec document, run a spec self-review, or hand off to planning. Use it to
pressure-test a plan or design the user *already has* — or, inside `/e2e`
Phase 2, to make `/brainstorming`'s clarifying-questions step relentless.

For the full design-to-spec flow (explore → alternatives → design → spec → review
→ writing-plans), use `/brainstorming` instead.

<!--
Adapted from mattpocock/skills `grilling` skill (https://github.com/mattpocock/skills),
MIT License, © Matt Pocock. Copied once with attribution — not auto-synced. See SOURCES.md.
Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths.
-->
