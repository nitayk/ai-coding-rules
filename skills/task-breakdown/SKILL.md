---
name: task-breakdown
description: "Use when PRD is approved and ready for implementation planning, breaking down features into tasks, or creating development roadmap. Do NOT use for simple single-task changes, when PRD is not yet approved, or when requirements are unclear (use /prd-generation first)."
last-reviewed: 2026-06-02
---
# Task Breakdown

Break Product Requirements Documents or feature descriptions into structured, actionable task lists.

**CRITICAL**: Two-phase approach - generate parent tasks first, then break down into sub-tasks. Each task should fit in one context window.

## When to Use This Skill

**APPLY WHEN:**
- PRD is approved and ready for implementation
- Planning feature implementation
- Breaking down large features into manageable tasks
- Creating development roadmap
- Need structured task list for development

**SKIP WHEN:**
- Simple, single-task changes
- PRD not yet approved
- Requirements unclear (use `/prd-generation` first)

## Core Directive

**Parent tasks → User confirmation → Sub-tasks → Save to file.**

## The Task Breakdown Flow

### Phase 1: Generate Parent Tasks

**Input: PRD or feature description**

**Generate high-level parent tasks:**

```markdown
# Tasks: Keyboard Shortcuts Feature

## Parent Tasks

- [ ] 0.0 Create feature branch
- [ ] 1.0 Implement navigation shortcuts
- [ ] 2.0 Implement action shortcuts
- [ ] 3.0 Create shortcut cheat sheet
- [ ] 4.0 Add shortcut customization
- [ ] 5.0 Write tests
- [ ] 6.0 Update documentation
- [ ] 7.0 Create PR and merge
```

**Key principles:**
- Always include branch creation (0.0)
- Always include PR creation (last task)
- Group related work into logical phases
- Use decimal numbering (0.0, 1.0, 2.0) for parent tasks

### Phase 2: User Confirmation

**Present parent tasks and ask:**

```
I've generated parent tasks. Review and confirm:

[Show parent tasks]

Type "Go" to proceed with sub-task breakdown, or suggest changes.
```

**User confirms:** "Go" or provides feedback

### Phase 3: Break Down Sub-Tasks

**For each parent task, generate detailed sub-tasks** — expand the parent list above into `parent.sub` numbering (`1.0` → `1.1`, `1.2`, …). Each sub-task fits in one context window, is actionable/specific, and references `/pr-workflow` for PR tasks and `/tdd-workflow` for test tasks. Annotate dependencies, PRD links, and (optionally) estimates inline:

```markdown
- [ ] 1.0 Implement navigation shortcuts (US-001)
  - [ ] 1.1 Create ShortcutManager service (1 hour)
  - [ ] 1.2 Implement arrow key navigation (P0)
  - [ ] 1.3 Implement tab navigation (depends on 1.1)
  - [ ] 1.5 Test navigation shortcuts (use /tdd-workflow)
- [ ] 2.0 Implement action shortcuts
  - [ ] 2.1 Add standard shortcuts (Ctrl+S, Ctrl+Z, etc.)
  - [ ] 2.2 Implement shortcut registry (depends on 2.1)
- [ ] 7.0 Create PR and merge
  - [ ] 7.1 Run pre-PR checks
  - [ ] 7.2 Create PR with description (use /pr-workflow)
  - [ ] 7.3 Address feedback
  - [ ] 7.4 Merge when ready
```

## Rubric

**Sizing** — each task fits one context window (impl + tests), is completable in 1–4 hours, has clear acceptance criteria, and is independently testable. Split anything that needs multiple context windows, takes >1 day, or has unclear boundaries (e.g. "Build entire auth system" → smaller tasks).

**Naming** — action verbs (Create/Implement/Add/Update/Fix/Test/Refactor) + specific scope. Good: "Add email validation to login form". Bad: "Fix login".

**Ordering** — by dependencies (prerequisites first), priority (P0 before P1), risk (risky early), and value (high-value first). Note dependencies explicitly so tasks aren't attempted out of order.

**PRD linkage** — reference user stories (US-001), priorities (P0/P1/P2), and link the PRD file (`See tasks/prd-<feature>.md`).

**Always include** — `0.0 Create feature branch` first and a final `Create PR and merge` task; never omit testing tasks.

**Common patterns** — Feature: branch → setup → core → UI → tests → docs → PR. Refactor: branch → analysis → write tests → refactor incrementally → verify → docs → PR.

**Related skills:** `/prd-generation` (source PRD), `/tdd-workflow` (tests), `/git-workflow` (commit per task), `/pr-workflow` (PR).

## Success Criteria

- **Parent tasks generated** from PRD/description
- **User confirms** parent tasks
- **Sub-tasks generated** for each parent
- **Tasks properly sized** (fit in one context window)
- **Tasks saved** to file
- **Dependencies noted** where applicable

## Output

**This skill produces:**
- Structured task list with parent and sub-tasks
- Saved to `tasks/tasks-{feature-name}.md`
- Ready for implementation tracking

## Remember

> "Break down until tasks fit in one context window"

> "Always include branch creation and PR tasks"

> "Reference PRD requirements in tasks"

> "Tasks should be independently completable"

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
