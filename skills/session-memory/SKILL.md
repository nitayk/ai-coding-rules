---
name: session-memory
description: "Use when starting complex tasks (Build, Refactor, Migration), resuming work from a previous session, storing scratchpad notes or temporary decisions, when the user asks to remember something, or switching between agents/modes. Do NOT use when task is simple and does not span sessions, when context is not needed for continuity, or for one-off quick fixes."
---
# Session Memory

Manages persistent context across chat sessions using a local file. **The path depends on where the agent runs** — **Cursor**, **Claude Code**, or **GitHub Copilot** — resolve it before any read or write.

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

## Resolve memory file path (do this first)

Work from the **repository root** (or set `REPO_ROOT` and prefix paths below).

| Product | File path | Notes |
|---------|-----------|--------|
| **Claude Code** | `REPO_ROOT/.claude/memory/active_context.md` | `install.sh --target claude` (or first target `claude`). |
| **Cursor** | `REPO_ROOT/.cursor/memory/active_context.md` | `install.sh --target cursor` (default). |
| **GitHub Copilot** | **`REPO_ROOT/.cursor/memory/active_context.md`** | This package’s **`copilot`** target still uses **`MEMORY_DIR=.cursor/memory`** in `sync-rules.sh` (same on-disk file as Cursor). Use when the session is Copilot in VS Code / GitHub and this path exists or you create it. |

**`install.sh` / `sync-rules.sh`** create the matching directory per target (`claude` → `.claude/memory`, `cursor` / `copilot` → `.cursor/memory`).

### Decision order (stop at first match)

1. **Known runtime**  
   - **Claude Code** (Claude’s app/CLI, or repo is Claude-primary): **`.claude/memory/active_context.md`**.  
   - **Cursor** (Cursor IDE chat): **`.cursor/memory/active_context.md`**.  
   - **GitHub Copilot** (Copilot Chat in VS Code, or Copilot agent surfaces tied to this repo): **`.cursor/memory/active_context.md`** (not `.github/` — instructions live there, scratchpad stays under `.cursor/memory/` for this package).

2. **Claude isolation**  
   If **`.claude/settings.json`** contains `permissions.deny` that blocks reading paths under **`.cursor/`** (default in this package’s Claude install): you **must** use **`.claude/memory/active_context.md`** — do not read or write under `.cursor/` in that session.

3. **Existing file**  
   - If only **`.claude/memory/active_context.md`** exists → use it.  
   - If only **`.cursor/memory/active_context.md`** exists → use it.  
   - If **both** exist → use the **newer** file (bash: test `-nt`).

4. **No file yet**  
   - If only **`.claude/memory/`** exists (empty dir) → use `.claude/memory/active_context.md`.  
   - If only **`.cursor/memory/`** exists → use `.cursor/memory/active_context.md`.  
   - If **`.claude/skills/`** exists and **`.cursor/agents/`** does not → prefer `.claude/memory/`.  
   - If **`.cursor/agents/`** exists and **`.claude/skills/`** does not → prefer `.cursor/memory/`.  
   - If **`.github/copilot-instructions.md`** exists (Copilot-oriented repo) and neither memory file exists yet → create/use **`.cursor/memory/active_context.md`** (aligned with `copilot` target in `sync-rules.sh`).

5. **Fallback**  
   Use **`.cursor/memory/active_context.md`** (Cursor, Copilot, and `copilot` install target; common default when the editor is unclear).

Store the chosen path in a variable (e.g. `MEMORY_FILE`) for all commands below.

## Context file structure

Structure:
- **Current Focus**: What is being worked on right now
- **Recent Decisions**: Key technical or product decisions made
- **Scratchpad**: Temporary notes, code snippets, or thoughts

## Workflow

### 1. Read context

After resolving `MEMORY_FILE`:

```bash
mkdir -p "$(dirname "$MEMORY_FILE")"
test -f "$MEMORY_FILE" && cat "$MEMORY_FILE"
```

### 2. Update context

Update when a sub-task completes, a major decision is made, or before ending the turn after significant progress.

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

### 3. Optional: pick newer file when both exist (ambiguous runtime)

From repo root, bash 3.2+:

```bash
if [ -f .claude/memory/active_context.md ] && [ -f .cursor/memory/active_context.md ]; then
  if [ .claude/memory/active_context.md -nt .cursor/memory/active_context.md ]; then
    MEMORY_FILE=.claude/memory/active_context.md
  else
    MEMORY_FILE=.cursor/memory/active_context.md
  fi
fi
```

## See also

- [Cursor, Claude Code, and GitHub Copilot: file memory vs hooks](references/agent-products-memory.md) — scratchpad vs hooks across **cursor / claude / copilot** targets.
- [PRODUCT_COMPARISON.md](../../targets/copilot/PRODUCT_COMPARISON.md) — what each product loads.

## Rules

- **DO NOT** commit this file (it is ignored by `.gitignore`)
- **DO NOT** delete sections unless they are obsolete
- **ALWAYS** resolve path and `mkdir -p` the parent directory before writing
- **Claude Code + deny on `.cursor`**: only use `.claude/memory/` (see above)
- **GitHub Copilot**: use **`.cursor/memory/`** for this skill (same as `copilot` target in `sync-rules.sh`), not only `.github/` instructions

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
