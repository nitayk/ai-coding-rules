---
name: session-memory
description: "Use when starting complex tasks (Build, Refactor, Migration), resuming work from a previous session, storing scratchpad notes or temporary decisions, when the user asks to remember something, or switching between agents/modes. Do NOT use when task is simple and does not span sessions, when context is not needed for continuity, or for one-off quick fixes."
last-reviewed: 2026-06-08
---
# Session Memory

Manages persistent context across chat sessions using a local file at
`REPO_ROOT/.claude/memory/active_context.md`.

## When to Use This Skill

**APPLY WHEN:**
- Starting a complex task (Build, Refactor, Migration)
- Resuming work from a previous session
- Need to store scratchpad notes or temporary decisions
- The user asks to "remember" something
- Switching between different agents/modes

**SKIP WHEN:**
- Task is simple and does not span sessions
- Context is not needed for continuity
- One-off quick fixes

## Memory file path

`REPO_ROOT/.claude/memory/active_context.md` — created by the plugin. Work
from the repository root, or set `REPO_ROOT` and prefix the paths below.
Store the resolved
path in `MEMORY_FILE` for all commands:

```bash
MEMORY_FILE="${REPO_ROOT:-.}/.claude/memory/active_context.md"
```

> Cursor and Copilot install targets were removed in v2.0 (ADR-009), so
> this skill is Claude Code-only — there is no longer a `.cursor/memory`
> path to resolve against. See AGENTS.md in the repository root for the
> canonical paths.

## Context file structure

- **Current Focus**: What is being worked on right now
- **Recent Decisions**: Key technical or product decisions made
- **Scratchpad**: Temporary notes, code snippets, or thoughts

## Workflow

### 1. Read context

```bash
mkdir -p "$(dirname "$MEMORY_FILE")"
test -f "$MEMORY_FILE" && cat "$MEMORY_FILE"
```

### 2. Update context

Update when a sub-task completes, a major decision is made, or before
ending the turn after significant progress.

```bash
mkdir -p "$(dirname "$MEMORY_FILE")"
cat > "$MEMORY_FILE" <<EOF
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

- **DO NOT** commit this file (it is ignored by `.gitignore`)
- **DO NOT** delete sections unless they are obsolete
- **ALWAYS** `mkdir -p` the parent directory before writing

<!-- Cross-platform note: Cursor/Copilot install targets were removed in v2.0 (ADR-009); this skill is Claude Code only. See AGENTS.md in the repository root. -->

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
