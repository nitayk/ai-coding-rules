# Agent Behavior Rules

**Purpose**: Control how AI agents behave — prevent hallucinations, enforce verification, manage assumptions.

## Rules in This Category

| File | Purpose | Always Apply |
|------|---------|-------------|
| `critical-rules.md` | Verify before claiming, 100% means 100%, no temp files | Yes |
| `anti-hallucination.md` | Prevent inventing APIs, guessing requirements, hallucinating code | Yes |
| `token-control.md` | Redirect long output to file; prefer git grep for large codebases | No |
| `context-management.md` | Context window limits, phase splits, intermediate artifacts, ~50% rule | No |
| `helper-tools-first.md` | Prefer small scoped tools over large end-to-end automation | No |

## When These Apply

These rules apply **universally** to all agent interactions regardless of language or framework. They govern agent behavior itself, not code patterns.

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
