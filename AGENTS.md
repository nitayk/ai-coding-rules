# Agent Guidance: ai-coding-rules

**Purpose**: Help LLM/AI agents navigate and use this toolkit.

**For Human Documentation**: See [`README.md`](README.md).

This is a **Claude Code** toolkit: `CLAUDE.md` + skills, agents, commands, and
hooks. (Cursor `.mdc` rules were removed — Claude Code doesn't load them.)

---

## How to Find Things

| Need | Go To |
|------|-------|
| **Project instructions / entry point** | `CLAUDE.md` |
| **A multi-step workflow** | `skills/<name>/SKILL.md` (invoke via `/<name>`) |
| **A specialized subagent** | `agents/<name>.md` |
| **A slash command** | `commands/<name>.md` |
| **Core rules (prose)** | `rules/*.md` (critical rules, investigation, communication) |
| **MCP configuration** | `mcp/example-config.json` |

## Structure Overview

```
ai-coding-rules/
├── CLAUDE.md             <- Project instructions (entry point)
├── skills/               <- 103 multi-step workflow skills
├── agents/               <- 20 specialized subagents
├── commands/             <- 14 slash commands
├── hooks/                <- Quality, security, observability, ECC hooks
├── rules/                <- Core rules as prose .md (referenced from CLAUDE.md)
├── cli/                  <- `acr` Go CLI (install/sync/link/update)
├── config/               <- skill-groups.yaml (skill-group tags for acr sync)
├── mcp/                  <- MCP configuration examples
├── spec/ , template/     <- Agent Skills spec + skill template
└── docs/                 <- Dev docs (go-cli conventions, plans)
```

## Agent Conventions

- **Skills** (`skills/*/SKILL.md`): Multi-step workflows. Invoked via `/skill-name` or natural language.
- **Subagents** (`agents/*.md`): Context-isolated specialists. Auto-delegated or invoked via `/agent-name`.
- **Commands** (`commands/*.md`): Quick slash commands. Invoked via `/command-name`.
- **Rules** (`rules/*.md`): Core prose standards referenced from `CLAUDE.md` — patterns, not workflows.

### When to Use What

| Use | When |
|-----|------|
| **Skill** | Repeatable multi-step workflow (e.g., TDD, service migration) |
| **Subagent** | Context-heavy parallel work needing isolation |
| **Command** | Quick single-purpose action (e.g., create PR, run tests) |
| **Rule** | Baseline standard you cite while working (read on demand) |

## Deployment

Skills/agents/commands/hooks are deployed into a consumer repo's `.claude/`
directory by the `acr` CLI (`acr install` / `acr sync`). This checkout is added
as a submodule at `.cursor/rules/shared` — that path lives under `.cursor/` on
purpose, because Claude Code auto-loads everything under `.claude/` and a
submodule there would cause a context explosion. Claude ignores `.cursor/`, so
it's a safe home for the checkout. See [`cli/README.md`](cli/README.md).
