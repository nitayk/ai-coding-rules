---
name: prd-generation
description: "Generates Product Requirements Documents through structured conversation by asking clarifying questions about goals, user needs, requirements, and technical constraints. Creates comprehensive PRD documents with goals, user stories, functional requirements, non-functional requirements, technical considerations, and acceptance criteria. Use when starting new features, planning major changes, clarifying requirements, or documenting feature specs. Produces well-structured PRD documents ready for review and implementation planning."
version: "1.0.0"
last_updated: "2026-01-25"
tags: ["planning", "documentation", "requirements", "universal"]
---
# PRD Generation

Generate comprehensive Product Requirements Documents through structured conversation.

**CRITICAL**: Ask clarifying questions BEFORE writing PRD. Use numbered questions with lettered options for easy responses.

## When to Use This Skill

**APPLY WHEN:**
- Starting new features or major changes
- Planning product enhancements
- Clarifying ambiguous requirements
- Documenting feature specifications
- Need structured requirements before coding

**SKIP WHEN:**
- Quick bug fixes (no PRD needed)
- Simple, well-understood changes
- Requirements already documented
- Purely technical refactoring

## Core Directive

**Ask questions → Get answers → Generate PRD → Save to file.**

## The PRD Generation Flow

### Phase 1: Initial Request

**User provides initial idea:**

```
User: "I want to add keyboard shortcuts to the app"
```

### Phase 2: Clarifying Questions

**AI asks 3-5 structured questions:**

```
I need to understand your requirements better. Please answer:

1. What types of shortcuts do you want?
   A) Navigation shortcuts (arrow keys, tab)
   B) Action shortcuts (Ctrl+S to save, Ctrl+Z to undo)
   C) Both navigation and action shortcuts
   D) Custom shortcuts configurable by users

2. Which parts of the app should support shortcuts?
   A) Only main editor/view
   B) All views and dialogs
   C) Specific views only (list them)
   D) Everywhere including modals

3. How should users discover shortcuts?
   A) Built-in help menu
   B) Tooltip hints on hover
   C) Cheat sheet dialog (Ctrl+?)
   D) No discovery mechanism needed

4. Should shortcuts be customizable?
   A) Yes, fully customizable
   B) No, fixed shortcuts only
   C) Some shortcuts fixed, some customizable

5. What's the priority?
   A) P0 - Critical, needed immediately
   B) P1 - High priority, this sprint
   C) P2 - Nice to have, next sprint
```

### Phase 3: User Response

**User answers with letter codes:**

```
User: "1C, 2B, 3C, 4C, 5B"
```

### Phase 4: Generate PRD

**AI generates complete PRD based on answers:**

```markdown
# Product Requirements Document: Keyboard Shortcuts

## Goals
Enable efficient navigation and actions via keyboard shortcuts across the entire application.

## Success Metrics
- 80% of power users use shortcuts within 1 week
- Average task completion time reduced by 20%
- Zero accessibility regressions

## User Stories

### US-001: Navigation Shortcuts
As a power user, I want to navigate between views using arrow keys so that I can work faster without using mouse.

**Acceptance Criteria:**
- Arrow keys navigate between main views
- Tab cycles through interactive elements
- Escape closes modals/dialogs

### US-002: Action Shortcuts
As a user, I want to perform common actions via keyboard (Ctrl+S to save, Ctrl+Z to undo) so that I can work more efficiently.

**Acceptance Criteria:**
- Standard shortcuts work (Ctrl+S, Ctrl+Z, Ctrl+C, Ctrl+V)
- Custom shortcuts configurable for user-specific workflows
- Shortcuts work in all views

### US-003: Shortcut Discovery
As a new user, I want to discover available shortcuts via a cheat sheet (Ctrl+?) so that I can learn shortcuts without searching documentation.

**Acceptance Criteria:**
- Ctrl+? opens shortcut cheat sheet
- Cheat sheet shows all shortcuts with descriptions
- Cheat sheet searchable/filterable

## Functional Requirements

### P0 (Must Have)
- [ ] Navigation shortcuts (arrow keys, tab)
- [ ] Standard action shortcuts (Ctrl+S, Ctrl+Z, etc.)
- [ ] Shortcut cheat sheet (Ctrl+?)
- [ ] Shortcuts work in all views

### P1 (Should Have)
- [ ] Customizable shortcuts for power users
- [ ] Tooltip hints showing shortcuts
- [ ] Shortcut conflict detection

### P2 (Nice to Have)
- [ ] Import/export shortcut configurations
- [ ] Shortcut themes/presets
- [ ] Analytics on shortcut usage

## Non-Goals (Out of Scope)
- Voice commands
- Gesture-based shortcuts
- Mobile app shortcuts (desktop only for now)

## Technical Considerations

### Implementation Approach
- Use existing keyboard event handling framework
- Create ShortcutManager service for centralized handling
- Store custom shortcuts in user preferences

### Dependencies
- Keyboard event library (already in use)
- User preferences storage system

### Performance
- Shortcut handling must be <10ms latency
- No impact on existing keyboard input

### Accessibility
- All shortcuts must be keyboard accessible
- Screen reader compatible
- No conflicts with assistive technologies

## Open Questions
- Should shortcuts be different on Mac (Cmd vs Ctrl)?
- How to handle shortcuts in nested modals?
- Should we support multi-key shortcuts (Ctrl+K, Ctrl+S)?

## Timeline
- Sprint 1: P0 requirements
- Sprint 2: P1 requirements
- Sprint 3: P2 requirements (if time permits)
```

### Phase 5: Save PRD

**Save to file:**

```bash
# Create tasks directory if needed
mkdir -p tasks

# Save PRD
# File: tasks/prd-keyboard-shortcuts.md
```

## PRD Structure Template

### Required Sections

1. **Goals** - What we're trying to achieve
2. **Success Metrics** - How we measure success
3. **User Stories** - User perspective requirements
4. **Functional Requirements** - Prioritized feature list (P0/P1/P2)
5. **Non-Goals** - Explicitly out of scope
6. **Technical Considerations** - Implementation notes
7. **Open Questions** - Unresolved decisions
8. **Timeline** - Rough schedule

### Optional Sections

- **Background** - Context and motivation
- **User Research** - User feedback/data
- **Design Mockups** - UI/UX references
- **API Changes** - Backend modifications
- **Database Changes** - Schema modifications
- **Migration Plan** - Data migration if needed

## Question Design Principles

### Good Questions

**Structured, specific, actionable:**

```
1. What's the primary use case?
   A) Option 1 (clear description)
   B) Option 2 (clear description)
   C) Option 3 (clear description)
```

### Bad Questions

**Vague, open-ended:**

```
What do you want? (too vague)
Tell me everything about this feature (too broad)
```

### Question Count

**Ask 3-5 questions:**
- Too few (1-2): Missing important details
- Too many (6+): User fatigue, lower response rate
- Sweet spot (3-5): Comprehensive but manageable

## Best Practices

### Before Writing PRD

- **Ask questions first** - Don't assume requirements
- **Use structured format** - Numbered questions, lettered options
- **Be specific** - Clear options, not vague questions
- **Cover key areas** - Functionality, scope, priority, UX

### PRD Quality

- **Junior-developer readable** - Clear enough for new team members
- **Explicit scope boundaries** - What's IN and OUT
- **Prioritized requirements** - P0/P1/P2 clearly marked
- **Actionable** - Can be broken into tasks

### After PRD Generation

- **Review with stakeholders** - Get approval before implementation
- **Break into tasks** - Use `/task-breakdown` skill
- **Reference in PRs** - Link PRD in implementation PRs

## Integration with Other Skills

**Use with:**
- `/task-breakdown` - Break PRD into actionable tasks
- `/tdd-workflow` - Write tests based on PRD requirements
- `/pr-workflow` - Reference PRD in PR description

## Common Pitfalls

### Skipping Questions

**Problem:** Assuming requirements, writing incomplete PRD

**Solution:** Always ask clarifying questions first

### Vague Questions

**Problem:** User doesn't understand options

**Solution:** Make options specific and clear

### Too Many Questions

**Problem:** User gets overwhelmed

**Solution:** Limit to 3-5 key questions

### Not Saving PRD

**Problem:** PRD lost in chat history

**Solution:** Always save to `tasks/prd-{feature-name}.md`

## Success Criteria

- **Clarifying questions asked** before writing PRD
- **PRD generated** based on user answers
- **PRD saved** to file
- **All required sections** included
- **Requirements prioritized** (P0/P1/P2)
- **Scope boundaries** clearly defined

## Output

**This skill produces:**
- Structured PRD document
- Saved to `tasks/prd-{feature-name}.md`
- Ready for task breakdown and implementation

## Remember

> "Ask questions before writing - prevents rework"

> "Structured questions get better answers"

> "PRD is the foundation - make it solid"
