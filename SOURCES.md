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

- **Repo**: https://github.com/ironsource-mobile/mobile-agent-toolkit (work; checked out locally at `~/Repos/manage/mobile-agent-toolkit`). Formerly `mobile-cursor-rules` (MCR) — the older name still appears in notes below.
- **License**: internal (only generic, non-Unity-specific skills pulled here)
- **Sync model**: NOT covered by `acr update` (which only refreshes `obra/superpowers` + `anthropics/skills`). Pulled manually by copying selected `skills/`, `agents/`, `commands/` dirs; re-run by hand when the toolkit adds new generic skills you want.
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
- **Preserved as personal-custom (2026-05-12 — SUPERSEDED, see 2026-07-02 refresh below)**:
  - `skills/best-practices-enforcement`, `skills/git-workflow`, `skills/multi-agent-branching`, `skills/prd-generation` were kept as the larger personal versions in the 2026-05-12 sync. The 2026-07-02 full-overwrite refresh replaced them with the toolkit versions (see below); recover the old personal versions from git history if wanted.
- **Full-overwrite refresh (2026-07-02)** — pulled from `~/Repos/manage/mobile-agent-toolkit` (renamed from mobile-cursor-rules):
  - **Skills**: 14 new generic added — `a11y-audit`, `design-ops`, `grilling`, `handoff`, `harness-bench`, `interaction-design`, `localization-design`, `markitdown`, `polyglot`, `tech-debt-audit`, `ui-uplift`, `ux-writing-skill`, `verify-branch-health`, `visual-critique`. All 85 overlapping skills overwritten with the toolkit version (incl. the four formerly-preserved custom ones above; `e2e` grew 992→1421 lines).
  - **Agents**: 2 new added — `code-cleanup`, `harness-optimizer`; 18 overlapping overwritten.
  - **Commands**: 2 new added — `ecc-env`, `evolve`; 5 overlapping overwritten.
- **Explicitly NOT pulled** (work-coupled to Unity Ads infra / org MCPs): `aerospike-best-practices`, `argocd-deployment`, `argocd-onboarding`, `atlas-analysis`, `code-graph-architect`, `full-network-analysis`, `grafana-monitoring`, `kronus-onboarding`, `memgraph-analysis`, `read-consul-keys`, `slack-history`, `trino-validation`, `victoria-traces-analysis`, `org-level-search`, `ai-news-digest`, `fff-search`, `e2e-workspace`. Same for toolkit-only agents `memgraph-specialist`, `victoria-traces-specialist`, `deployment-investigator`, `service-{breakdown,migration,refactoring}-specialist`.
- **Removed during the 2026-07-02 refresh** — `github-actions-workflows-helper` was deleted: it documents Unity's internal CI infra end-to-end (`vault.corp.unity3d.com`, `kronus`, WIF, `@unity/*`) and can't be meaningfully de-Unity'd. It stays in the toolkit.
- **Internal-reference scrub (2026-07-02)** — the synced generic skills were passed to strip Unity-internal specifics not appropriate for a public repo: dropped the `## Unity Internal References` sections from the 9 `best-practices-enforcement/references/rules/*/index.md` files (internal Confluence/Jira/corp links); removed `harness-bench/BURN_RESULTS.md` (internal benchmark output) and pointed its `example_tasks/*.yaml` at a placeholder repo; rewrote `ui-uplift`'s context-awareness from WORK(Unity)/PERSONAL to generic DESIGN-SYSTEM/GREENFIELD; and generalized one-line `@unity/cloud-ui` / `ironSource` mentions in `design-ops` and `tech-debt-audit`. Public `Unity-Technologies` GitHub-org references (a public org) were left as-is.
  - Note: `code-structure-analysis`, `service-breakdown`, `service-migration`, `service-refactoring` were already present (pulled 2026-05-12 as generic methodology) and were refreshed in place; they still reference Memgraph/Trino in their bodies.
- **NOT auto-updated — review manually**: `hooks/` (executes code, may have repo-specific paths/creds). Use `diff -r ~/Personal/ai-coding-rules/hooks ~/Repos/manage/mobile-agent-toolkit/.agents/hooks` to review.

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
