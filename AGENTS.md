# Agent Guidance: ai-coding-rules

**Purpose**: Help LLM/AI agents navigate and use this rules repository.

**For Human Documentation**: See [`README.md`](README.md).

---

## How to Find Things

| Need | Go To |
|------|-------|
| **Find a specific rule** | `index.mdc` (complete catalog with keyword routing) |
| **Auto-detect intent** | `ROUTER.mdc` (always loaded, routes by keywords) |
| **Style guide for rules** | `meta/cursor-rules-style-guide.mdc` |
| **MCP configuration** | `mcp/example-config.json` |

## Structure Overview

```
ai-coding-rules/
├── ROUTER.mdc          <- Always loaded, keyword-based routing
├── index.mdc           <- Complete catalog (load on demand)
├── generic/            <- Universal best practices (all languages)
├── backend/            <- Scala, Python, Go, Java, PHP
├── frontend/           <- JavaScript/TypeScript
├── mobile/             <- Swift, Kotlin, Objective-C, CocoaPods, Gradle
├── tools/              <- CLI references (curl, jq, git, docker, kcat, kubectl, aws-cli, gh-cli)
├── meta/               <- Style guides, continuous improvement
├── rules/              <- Investigation patterns, core rules
├── mcp/                <- MCP configuration examples
└── docs/               <- Setup guides, Cursor feature docs
```

## Rule Loading Priority

1. **Repo-specific rules**: `.cursor/repo-rules/` (highest priority)
2. **Shared rules**: `.cursor/rules/shared/` (this repository as submodule)
3. **Auto-loading**: Rules with `alwaysApply: true` or matching `globs` patterns

## Agent Conventions

- **Skills** (`skills/*/SKILL.md`): Multi-step workflows. Invoked via `/skill-name` or natural language.
- **Subagents** (`agents/*.md`): Context-isolated specialists. Auto-delegated or invoked via `/agent-name`.
- **Commands** (`commands/*.md`): Quick slash commands. Invoked via `/command-name`.
- **Rules** (`.mdc` files): Auto-loaded by globs or manually loaded. Provide patterns, not workflows.

### When to Use What

| Use | When |
|-----|------|
| **Skill** | Repeatable multi-step workflow (e.g., service breakdown, TDD) |
| **Subagent** | Context-heavy parallel work needing isolation (e.g., 100+ graph queries) |
| **Command** | Quick single-purpose action (e.g., create PR, run tests) |
| **Rule** | Passive guidance triggered by file patterns (e.g., Scala style on `.scala` files) |

## Cursor Features Reference

| Feature | Location | Notes |
|---------|----------|-------|
| **Commands** | `.cursor/commands/` | Type `/` in chat |
| **Skills** | `.cursor/skills/` | Auto-discovered at startup |
| **Subagents** | `.cursor/agents/` | Auto or explicit invocation |
| **Rules** | `.cursor/rules/` | Version-controlled, glob-triggered |
| **MCP** | `.cursor/mcp.json` | stdio, SSE, or Streamable HTTP |
| **Semantic Search** | Automatic | Indexing at workspace open |
| **@ Mentions** | `@Files`, `@Code`, `@Docs` | Reference files and docs |
