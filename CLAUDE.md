# AI-Powered Development with Claude Code

Follow ALL instructions in this file and loaded rules. Ask if ambiguous.
Make minimal, focused changes - only what is necessary for the task.

## Core Rules

See `rules/critical-rules.md` for full details.

- **100% means 100%** - actual config values, actual metrics, actual behavior.
- **Verify, don't assume** - existing knowledge is guidance, not shortcuts.
- **No garbage files** - only create files with permanent value.

## Investigation

See `rules/investigation-protocol.md` for full methodology and tool selection.

- Read code first, then grep for external links.
- Get production values from actual sources (not variable names).

## Communication

See `rules/communication-standards.md` for templates and examples.

- **BLUF** - lead with the answer, then explain.
- **Evidence-based** - cite sources for every claim.
- **Tool education** - briefly explain MCP tools when first using them.

## Extension Points

| Type | Location | Trigger | Purpose |
|------|----------|---------|---------|
| **Rules** | `rules/*.md` | Referenced here / on demand | Core prose standards |
| **Skills** | `skills/` | Auto or `/skill-name` | Multi-step workflows |
| **Agents** | `agents/` | Auto delegation | Specialized expertise |
| **Commands** | `commands/` | `/command-name` | Quick workflows |

## Context Management

- **Skill references** (files under a skill's `references/`) load ON-DEMAND only. Do NOT read them unless the task specifically needs them.
- **Domain skills** (docx, pdf, xlsx, pptx) require explicit `/skill-name` invocation.
- When you need a reference, read ONE specific file -- never bulk-read a directory.

## Setup

1. Add as submodule: `git submodule add <repo-url> .cursor/rules/shared`
   (the checkout lives under `.cursor/` on purpose — Claude ignores `.cursor/`, so it avoids the `.claude/` auto-load context explosion)
2. Build the CLI: `go build -o acr ./.cursor/rules/shared/cli` (put `acr` on your PATH)
3. Run setup: `acr install` (see `.cursor/rules/shared/cli/README.md`)
4. Optional: Configure `.claude/settings.json` for permissions
