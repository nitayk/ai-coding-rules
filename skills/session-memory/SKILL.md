---
name: session-memory
description: "Manages persistent context across chat sessions using a local memory file. Use when resuming work, storing decisions, or maintaining continuity across long-running tasks."
---

# Session Memory

Manages persistent context across chat sessions using a local file.

## Description
Reads and updates the `.cursor/memory/active_context.md` file to maintain continuity across long-running tasks. This file acts as the "brain" of the session, storing the current focus, recent decisions, and scratchpad notes.

## When to Use This Skill
**APPLY WHEN:**
- Starting a complex task (Build, Refactor, Migration)
- Resuming work from a previous session
- Need to store scratchpad notes or temporary decisions
- The user asks to "remember" something
- Switching between different agents/modes

## Context File Structure
The file is located at `.cursor/memory/active_context.md` (provisioned by `sync-rules.sh`).

Structure:
- **Current Focus**: What is being worked on right now.
- **Recent Decisions**: Key technical or product decisions made.
- **Scratchpad**: Temporary notes, code snippets, or thoughts.

## Workflow

### 1. Read Context
Always read the memory file at the start of a task.

```bash
cat .cursor/memory/active_context.md
```

### 2. Update Context
Update the file when:
- A sub-task is completed
- A major decision is made
- You are about to end the turn (if significant progress was made)

```bash
# Example update
cat > .cursor/memory/active_context.md <<EOF
# Active Context
## Current Focus
Implementing the Login component (Task 1.2)

## Recent Decisions
- Using JWT for session management
- Storing tokens in HttpOnly cookies

## Scratchpad
- Need to check if the API supports refresh tokens
EOF
```

## Rules
- **DO NOT** commit this file (it is ignored by .gitignore).
- **DO NOT** delete sections unless they are obsolete.
- **ALWAYS** check for existence before writing (create if missing, though `sync-rules.sh` should handle it).
