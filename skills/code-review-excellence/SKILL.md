---
name: code-review-excellence
description: Master effective code review practices to provide constructive feedback, catch bugs early, and foster knowledge sharing while maintaining team morale. Use when reviewing pull requests, establishing review standards, or mentoring developers. Do NOT use when you only need the repo’s generic /review command with no methodology, or when the codebase skill is product-specific (e.g. Memgraph/Neo4j graph review).
last-reviewed: 2026-05-27
---

# Code Review Excellence

Review methodology — how to give feedback, structure a review pass, and
handle disagreement. Stack-specific patterns and security checks live
elsewhere (see Related skills & rules below).

## When to Use

- Reviewing PRs or change sets
- Establishing review standards / mentoring
- Conducting architecture reviews
- Improving review cycle time

## Do NOT Use

- You just need the repo's `/review` slash command with no methodology
- A product-specific code-review skill exists (e.g. Memgraph/Neo4j graph review) — use that
- Security-sensitive diff — invoke `/security-review` (it has the checklist)
- Stack rule enforcement — `/best-practices-enforcement` runs the language rule files mechanically

## Review Mindset

| Goals | Not goals |
|---|---|
| Catch bugs and edge cases | Show off knowledge |
| Ensure maintainability | Nitpick formatting (use linters) |
| Share knowledge | Block progress unnecessarily |
| Enforce standards | Rewrite to your preference |
| Improve design | — |

## Effective Feedback

Good feedback is **specific, actionable, educational, balanced, prioritized**.

```markdown
Bad : "This is wrong."
Good: "Race condition when two users hit this simultaneously —
       consider a mutex."

Bad : "Why didn't you use X?"
Good: "Have you considered the Repository pattern? It would make
       this easier to test — example: [link]"

Bad : "Rename this."
Good: "[nit] `userCount` reads clearer than `uc` — not blocking."
```

## Review Process (≈20–35 min for a 200–400 line PR)

| Phase | Time | Focus |
|---|---|---|
| 1. Context | 2–3 min | PR description, linked issue, CI status, PR size (>400 lines? ask to split) |
| 2. High-level | 5–10 min | Architecture fit, file organization, test strategy |
| 3. Line-by-line | 10–20 min | Logic, security, performance, maintainability |
| 4. Summary | 2–3 min | Concerns + praise + clear decision (Approve / Comment / Request changes) |

### What to review manually vs delegate

| Review manually | Delegate to tooling |
|---|---|
| Logic correctness, edge cases | Formatting (Prettier/Black/gofmt) |
| Security implications | Import organization |
| Performance hot paths | Lint violations |
| Test coverage & quality | Typos |
| API design & naming | Stack rule violations (`/best-practices-enforcement`) |
| Architectural fit | Security checklist (`/security-review`) |

## Review Techniques

### Feedback severity labels — UNIQUE TO THIS SKILL

Tag every comment so the author can triage:

| Label | Meaning |
|---|---|
| `[blocking]` | Must fix before merge |
| `[important]` | Should fix; discuss if you disagree |
| `[nit]` | Nice to have, not blocking |
| `[suggestion]` | Alternative to consider |
| `[learning]` | Educational, no action needed |
| `[praise]` | Good work — name it explicitly |

Example: `"[blocking] SQL query is concatenated — please parameterize."`

### Question approach — UNIQUE TO THIS SKILL

Ask, don't assert. Authors defend less and think more.

```markdown
Bad : "This will fail if the list is empty."
Good: "What happens if `items` is an empty array?"

Bad : "You need error handling here."
Good: "How should this behave if the API call fails?"

Bad : "This is inefficient."
Good: "This loops through all users — have we considered the impact
       at 100k users?"
```

### Suggest, don't command

```markdown
Bad : "You must change this to use async/await."
Good: "Suggestion: async/await might read cleaner here — what do you think?"

Bad : "Extract this into a function."
Good: "This logic appears in 3 places — would a shared utility help?"
```

## Giving Difficult Feedback

### Sandwich method (modified) — UNIQUE TO THIS SKILL

Traditional Praise + Criticism + Praise feels fake. Use
**Context + Specific Issue + Helpful Solution** instead.

```markdown
[Context]   "The payment logic is inline in the controller, which
             makes it hard to test and reuse."
[Issue]     "calculateTotal() mixes tax, discount, and DB queries —
             hard to unit-test."
[Solution]  "Could we extract a PaymentService class? Happy to pair
             on this if useful."
```

### Handling disagreement

1. **Seek to understand** — "Help me understand what led you to this pattern."
2. **Acknowledge valid points** — "Good point about X, hadn't considered that."
3. **Provide data** — "Concerned about perf — can we add a benchmark?"
4. **Escalate** — bring in an architect/senior if stuck.
5. **Know when to let go** — perfection is the enemy of progress.

## Best Practices

- Review within 24 hours (same day ideal)
- Cap PR size at 200–400 lines; ask to split bigger ones
- Review in ≤60 min blocks
- Automate what you can (lint, format, security scans)
- Offer to pair on complex issues
- Praise explicitly — emoji and empathy matter

## Common Pitfalls

- **Perfectionism** — blocking on minor style
- **Scope creep** — "while you're at it…"
- **Inconsistency** — different bar for different authors
- **Delayed reviews** — letting PRs sit for days
- **Ghosting** — request changes then disappear
- **Rubber stamping** — approve without reading
- **Bike-shedding** — long debates on trivial details

## Related skills & rules

| Need | Use this instead |
|---|---|
| Security-sensitive diff | `/security-review` (skill) |
| Enforce language rule files mechanically | `/best-practices-enforcement` (skill) |
| Stack-specific patterns (Python/TS/Go/Scala/…) | `references/language-patterns.md` (this skill) + the `/best-practices-enforcement` skill's bundled `references/rules/<lang>/` |
| Receiving review feedback | `/receiving-code-review` (skill) |
| Asking for a review | `/requesting-code-review` (skill) |

## References

- `references/language-patterns.md` — Python/TS/test review catches (demoted from inline)
- `references/CODE_REVIEW_EXTENDED.md` — extended methodology notes
- `references/pr-review-comment-template-inline.md` — copy-paste PR comment structure

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
