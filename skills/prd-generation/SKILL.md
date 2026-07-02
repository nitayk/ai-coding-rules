---
name: prd-generation
description: "Use when starting new features, planning major changes, clarifying requirements, or documenting feature specs. Do NOT use for quick bug fixes, simple well-understood changes, or purely technical refactoring."
last-reviewed: 2026-06-08
---
# PRD Generation

Generate comprehensive Product Requirements Documents through structured conversation.

**CRITICAL**: Ask clarifying questions BEFORE writing PRD. Use numbered questions with lettered options.

## When to Use This Skill

**APPLY WHEN:**
- Starting new features or major changes
- Planning product enhancements
- Clarifying ambiguous requirements
- Documenting feature specifications
- Need structured requirements before coding

**DO NOT USE WHEN:**
- Quick bug fixes (no PRD needed)
- Simple, well-understood changes
- Requirements already documented
- Purely technical refactoring

## Core Directive

Ask questions, get answers, generate PRD, save to file.

## Process

### Phase 1: Initial Request

User provides initial idea.

### Phase 2: Clarifying Questions

Ask 3-5 structured questions with lettered options:

```
1. What types of shortcuts do you want?
   A) Navigation shortcuts
   B) Action shortcuts
   C) Both
   D) Custom configurable

2. Which parts of the app should support shortcuts?
   A) Only main editor
   B) All views and dialogs
   ...
```

### Phase 3: User Response

User answers with letter codes (e.g., "1C, 2B, 3C").

### Phase 4: Generate PRD

Generate complete PRD based on answers. Required sections:
- Goals
- Success Metrics
- User Stories
- Functional Requirements (P0/P1/P2)
- Non-Goals
- Technical Considerations
- Open Questions
- Timeline

### Phase 5: Save PRD

Save under the repo's PRD/plans convention — prefer
`docs/prds/prd-{feature-name}.md` (or the repo's existing PRD/plans
directory); fall back to `tasks/prd-{feature-name}.md` only if the repo
has no `docs/` convention.

**Verification**: PRD saved to file before proceeding.

**Handoff**: pass the saved PRD to `/writing-plans` (or `/task-breakdown`)
to turn requirements into an implementation plan — this is the design→plan
step the rest of the pipeline (and `/e2e`) expects after a spec exists.

## Output

- Structured PRD document
- Saved under the repo's docs/PRD convention (e.g. `docs/prds/prd-{feature-name}.md`)
- Ready for the design→plan handoff (writing-plans / task-breakdown)

## Related Skills

- writing-plans - Turn the PRD into a step-by-step implementation plan (design→plan handoff)
- task-breakdown - Break PRD into actionable tasks
- tdd-workflow - Write tests based on PRD requirements
- pr-workflow - Reference PRD in PR description

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
