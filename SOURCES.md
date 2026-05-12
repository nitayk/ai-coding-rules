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

## ironsource-mobile/mobile-agent-toolkit (one-time pull, manual)

- **Repo**: https://github.com/ironsource-mobile/mobile-agent-toolkit (work; mirrored locally at `~/Repos/manage/mobile-cursor-rules`)
- **License**: internal (only generic, non-Unity-specific skills pulled here)
- **Sync model**: NOT in `update-community.sh`. Pulled manually; re-run by hand when MCR adds new generic skills you want.
- **First pull (2026-05-12) — new skills**:
  - `skills/agent-system-design` -- Agent decomposition, tool boundaries, orchestration
  - `skills/cost-audit` -- LLM token spend audit via codeburn
  - `skills/service-breakdown` -- Service architecture analysis (NOTE: body references Memgraph/Atlas/Trino MCPs — generic methodology, light edits if you want it MCP-free)
  - `skills/service-migration` -- Cross-repo service migration
  - `skills/service-refactoring` -- Service refactoring with validation
- **Refresh sync (2026-05-12) — overlapping skills updated to MCR's version (50 total)**:
  - Notable upgrades (large diffs): `e2e` (461→992 lines), `skill-creator`, `council`, `frontend-design`, `code-optimization`, `brainstorming`, `session-memory`, `test-until-pass`, `scala-testing`, `finishing-a-development-branch`, `writing-plans`
  - Plus 39 smaller diffs (mostly additive / minor wording fixes)
  - Plus flagged-then-applied: `using-git-worktrees`, `security-audit`
- **Refresh sync — agents updated**: `architect`, `code-reviewer`, `data-validator`, `documentation-writer`, `git-workflow-specialist`, `monitoring-analyst`, `security-auditor`, `test-runner`, `verifier`
- **Refresh sync — commands updated**: `create-pr`, `fix-issue`, `generate-changelog`, `generate-docs`, `test-until-pass`
- **Preserved as personal-custom (NOT overwritten — personal version is heavily customized)**:
  - `skills/best-practices-enforcement` (560 vs MCR's 118 lines)
  - `skills/git-workflow` (521 vs 109)
  - `skills/multi-agent-branching` (507 vs 104)
  - `skills/prd-generation` (322 vs 87)
- **Explicitly NOT pulled** (work-coupled to Unity Ads infra): `aerospike-best-practices`, `argocd-deployment`, `argocd-onboarding`, `atlas-analysis`, `code-graph-architect`, `full-network-analysis`, `grafana-monitoring`, `kronus-onboarding`, `memgraph-analysis`, `read-consul-keys`, `slack-history`, `trino-validation`, `victoria-traces-analysis`, `fff-search`, `e2e-workspace`. Same for MCR-only agents `memgraph-specialist`, `victoria-traces-specialist`, `deployment-investigator`, `service-{breakdown,migration,refactoring}-specialist`.
- **NOT auto-updated — review manually**: `hooks/` (executes code, may have repo-specific paths/creds). Files differing from MCR: `hooks.json`, `hooks-cursor.json`, `cursor-adapter.js`, `run-hook.cmd`, `session-start`, `ecc/tool-observe.sh`, `ecc-hooks/{README.md,hooks.json}`, `quality/validate-yaml.py`, `security/block-dangerous-commands.sh`. Personal-only: `session-start.sh`. Use `diff -r ~/Personal/ai-coding-rules/hooks ~/Repos/manage/mobile-cursor-rules/.agents/hooks` to review.

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
