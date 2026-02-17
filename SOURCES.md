# Sources

This file tracks the upstream sources for community content in this repo.

Run `bash update-community.sh` to pull the latest from all sources.

## obra/superpowers

- **Repo**: https://github.com/obra/superpowers
- **License**: MIT
- **What we sync**:
  - `skills/` -- All 14 skills (brainstorming, test-driven-development, systematic-debugging, verification-before-completion, executing-plans, subagent-driven-development, writing-plans, dispatching-parallel-agents, requesting-code-review, receiving-code-review, using-git-worktrees, finishing-a-development-branch, using-superpowers, writing-skills)
  - `agents/` -- code-reviewer.md
  - `commands/` -- brainstorm.md, execute-plan.md, write-plan.md
  - `hooks/` -- hooks.json, session-start.sh, run-hook.cmd

## anthropics/skills

- **Repo**: https://github.com/anthropics/skills
- **License**: Apache 2.0 (example skills), source-available (document skills)
- **What we sync**:
  - `skills/docx`, `skills/pdf`, `skills/xlsx`, `skills/pptx` -- Document manipulation
  - `skills/mcp-builder` -- MCP server creation guide
  - `skills/skill-creator` -- Skill authoring guide
  - `skills/webapp-testing` -- Playwright web testing
  - `skills/frontend-design` -- Frontend design patterns
  - `skills/web-artifacts-builder` -- Web artifact creation
  - `spec/` -- Agent Skills specification
  - `template/` -- Skill template

## Custom (not synced from upstream)

These skills are original and maintained directly in this repo:

- `skills/session-memory` -- Persistent context across sessions
- `skills/git-workflow` -- Stable-state commit workflow
- `skills/pr-workflow` -- Full PR lifecycle management
- `skills/prd-generation` -- PRD generation via conversation
- `skills/task-breakdown` -- Break PRDs into actionable tasks
- `skills/multi-agent-branching` -- Feature-branch isolation
- `skills/setup-local-dev` -- Persistent dev server with pm2
- `skills/tdd-workflow` -- Red-Green-Refactor cycle
- `skills/code-cleanup` -- Three-phase cleanup
- `skills/best-practices-enforcement` -- Code quality validation
- `skills/debug-workflow` -- Log-Reproduce-Fix cycle

## Adding New Sources

To add a new upstream source to the update script:

1. Add the repo URL to the `SOURCES` array in `update-community.sh`
2. Define what to sync in a new `*_ITEMS` array
3. Add the sync logic in the main section
4. Document it here in `SOURCES.md`
