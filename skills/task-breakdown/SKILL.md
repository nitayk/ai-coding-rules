---
name: task-breakdown
description: "Breaks PRDs into actionable task lists. Two-phase: parent tasks then sub-tasks. Use when PRD is approved and ready for implementation planning."
version: "1.0.0"
last_updated: "2026-01-25"
tags: ["planning", "tasks", "workflow", "universal"]
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

**For each parent task, generate detailed sub-tasks:**

```markdown
# Tasks: Keyboard Shortcuts Feature

## Parent Tasks

- [ ] 0.0 Create feature branch
- [ ] 1.0 Implement navigation shortcuts
  - [ ] 1.1 Create ShortcutManager service
  - [ ] 1.2 Implement arrow key navigation
  - [ ] 1.3 Implement tab navigation
  - [ ] 1.4 Add Escape key handling for modals
  - [ ] 1.5 Test navigation shortcuts
- [ ] 2.0 Implement action shortcuts
  - [ ] 2.1 Add standard shortcuts (Ctrl+S, Ctrl+Z, etc.)
  - [ ] 2.2 Implement shortcut registry
  - [ ] 2.3 Handle shortcut conflicts
  - [ ] 2.4 Test action shortcuts
- [ ] 3.0 Create shortcut cheat sheet
  - [ ] 3.1 Design cheat sheet UI
  - [ ] 3.2 Implement Ctrl+? trigger
  - [ ] 3.3 Populate shortcut list
  - [ ] 3.4 Add search/filter functionality
  - [ ] 3.5 Test cheat sheet
- [ ] 4.0 Add shortcut customization
  - [ ] 4.1 Create preferences UI
  - [ ] 4.2 Implement shortcut storage
  - [ ] 4.3 Add conflict detection
  - [ ] 4.4 Test customization
- [ ] 5.0 Write tests
  - [ ] 5.1 Unit tests for ShortcutManager
  - [ ] 5.2 Integration tests for shortcuts
  - [ ] 5.3 E2E tests for user flows
- [ ] 6.0 Update documentation
  - [ ] 6.1 Update user guide
  - [ ] 6.2 Add developer docs
- [ ] 7.0 Create PR and merge
  - [ ] 7.1 Run pre-PR checks
  - [ ] 7.2 Create PR with description
  - [ ] 7.3 Address feedback
  - [ ] 7.4 Merge when ready
```

**Key principles:**
- Each sub-task fits in one context window
- Sub-tasks are actionable and specific
- Sub-tasks reference `/pr-workflow` for PR tasks
- Numbering: `1.0` → `1.1`, `1.2`, `1.3` (parent.sub)

## Task Sizing Guidelines

### Right-Sized Tasks

**Each task should:**
- Fit in one context window (implementation + tests)
- Be completable in 1-4 hours
- Have clear acceptance criteria
- Be independently testable

**Examples:**
- "Add login form UI" ✓
- "Add email validation" ✓
- "Add auth API hook" ✓
- "Add error handling" ✓

### Too Large Tasks

**Avoid tasks that:**
- Require multiple context windows
- Take more than 1 day
- Have unclear boundaries

**Examples:**
- "Build entire auth system" ✗
- "Implement user dashboard" ✗

**Solution:** Break into smaller tasks

## Task Structure

### Task Format

```markdown
- [ ] X.Y Task title
  - [ ] X.Y.1 Sub-task 1
  - [ ] X.Y.2 Sub-task 2
```

### Task Naming

**Use action verbs:**
- "Create", "Implement", "Add", "Update", "Fix", "Test", "Refactor"

**Be specific:**
- Good: "Add email validation to login form"
- Bad: "Fix login"

### Task Dependencies

**Note dependencies:**
```markdown
- [ ] 2.0 Implement action shortcuts
  - [ ] 2.1 Add standard shortcuts (Ctrl+S, Ctrl+Z, etc.)
  - [ ] 2.2 Implement shortcut registry (depends on 2.1)
  - [ ] 2.3 Handle shortcut conflicts (depends on 2.2)
```

## Integration with PRD

**Reference PRD requirements:**

```markdown
- [ ] 1.0 Implement navigation shortcuts (US-001)
  - [ ] 1.1 Create ShortcutManager service
  - [ ] 1.2 Implement arrow key navigation (P0)
  - [ ] 1.3 Implement tab navigation (P0)
```

**Link to PRD:**
- Reference user stories (US-001, US-002)
- Reference priorities (P0, P1, P2)
- Link to PRD file: `See tasks/prd-keyboard-shortcuts.md`

## Workflow Integration

### Always Include

**Every task list includes:**

1. **Branch creation** (0.0)
   ```markdown
   - [ ] 0.0 Create feature branch
   ```

2. **PR creation** (last task)
   ```markdown
   - [ ] 7.0 Create PR and merge
     - [ ] 7.1 Run pre-PR checks
     - [ ] 7.2 Create PR with description
     - [ ] 7.3 Address feedback (use /pr-workflow)
     - [ ] 7.4 Merge when ready
   ```

### Reference Other Skills

**Link to relevant skills:**

```markdown
- [ ] 5.0 Write tests
  - [ ] 5.1 Unit tests (use /tdd-workflow)
  - [ ] 5.2 Integration tests
```

## Best Practices

### Task Granularity

**Break down until:**
- Each task is independently completable
- Each task has clear acceptance criteria
- Each task fits in one context window
- Tasks can be worked on in parallel (when possible)

### Task Ordering

**Order tasks by:**
- Dependencies (prerequisites first)
- Priority (P0 before P1)
- Risk (risky tasks early)
- Value (high-value tasks first)

### Task Estimation

**Optional: Add time estimates**

```markdown
- [ ] 1.0 Implement navigation shortcuts (4 hours)
  - [ ] 1.1 Create ShortcutManager service (1 hour)
  - [ ] 1.2 Implement arrow key navigation (2 hours)
  - [ ] 1.3 Implement tab navigation (1 hour)
```

## Common Patterns

### Feature Implementation Pattern

```
0.0 Create feature branch
1.0 Setup/Infrastructure
2.0 Core implementation
3.0 UI/UX
4.0 Testing
5.0 Documentation
6.0 PR and merge
```

### Refactoring Pattern

```
0.0 Create feature branch
1.0 Analysis (understand current code)
2.0 Write tests (safety net)
3.0 Refactor incrementally
4.0 Verify tests pass
5.0 Update documentation
6.0 PR and merge
```

## Integration with Other Skills

**Use with:**
- `/prd-generation` - Break down generated PRD
- `/tdd-workflow` - Write tests for each task
- `/git-workflow` - Commit after each task
- `/pr-workflow` - Create PR from task list

## Common Pitfalls

### Tasks Too Large

**Problem:** Task requires multiple context windows

**Solution:** Break into smaller sub-tasks

### Missing Dependencies

**Problem:** Tasks attempted out of order

**Solution:** Note dependencies explicitly

### No Testing Tasks

**Problem:** Tests forgotten

**Solution:** Always include testing tasks

### No PR Task

**Problem:** PR creation forgotten

**Solution:** Always include PR task at end

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
