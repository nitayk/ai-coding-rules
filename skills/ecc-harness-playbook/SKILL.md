---
name: ecc-harness-playbook
description: "Use when maximizing agent harness value (ECC / Everything Claude Code patterns): token economics, memory persistence hooks, strategic compaction, PreCompact/stop opt-in nudges (MCR_ECC_*), session id lifecycle, /ecc-env, verification loops, git worktrees, subagent orchestration. Maps Longform topics to this repo's skills and hooks — not a substitute for upstream ECC install."
last-reviewed: 2026-05-20
---

# ECC harness playbook (mobile-agent-toolkit)

This skill ties **Longform / Shorthand ECC topics** to **what this repo actually ships** as the Claude Code plugin. For the upstream plugin and full skill packs, see [everything-claude-code](https://github.com/affaan-m/everything-claude-code).

## Topic → repo surface

| Topic | What to use here |
|--------|-------------------|
| **Token optimization** | `/agent-token-optimization`; cap MCPs; model tiering in agent YAML where you control it |
| **Memory persistence** | `/session-memory` (`active_context.md`); **hooks**: `ecc/memory-lifecycle.sh` on Claude `SessionStart` / `PreCompact` / `Stop` (see `hooks/README.md`). Each **start** writes **`.claude/sessions/.session_id`** and logs **`session_id=...`** in **`lifecycle.log`** on start / pre-compact / stop. |
| **ECC env + session** | Slash command **`/ecc-env`**; script **`scripts/ecc-env.sh`** prints `MCR_*` variables and current session id file(s). |
| **Strategic compaction** | `/strategic-compact` skill; **hook** `ecc/strategic-compact-nudge.sh` (PreToolUse, Edit/Write-class tools); env `MCR_STRATEGIC_COMPACT_THRESHOLD` (default 50, `0` disables) |
| **PreCompact → verify (opt-in)** | **`ecc/precompact-verify-nudge.sh`** — stderr only when **`MCR_ECC_PRECOMPACT_NUDGE=1`**. Reminds you to verify/tests before context compaction. |
| **Continuous learning** | `ecc/tool-observe.sh` logs are still available as optional input. The `/continuous-learning-v2` skill was removed per AppSec review (see SOURCES.md) — no in-tree replacement; consume upstream ECC directly if you need the instinct pipeline. |
| **Stop → verify / learn (opt-in)** | **`ecc/stop-learning-nudge.sh`** on Claude `Stop` — stderr reminder only when **`MCR_ECC_STOP_NUDGE=1`** (default off). Pairs verification + learning without spamming every turn. |
| **Local churn in git** | Hooks write **`.claude/sessions/`** and **`.claude/hooks/logs/`** at runtime — add them to your `.gitignore` (the submodule installer that used to append them was removed). |
| **Verification loops** | `/verification-before-completion`, `/tdd-workflow`, `/test-until-pass` (as applicable); checkpoint vs continuous = workflow choice; **eval vocabulary** (pass@k, graders): use project docs or upstream ECC — not shipped as code here |
| **Parallelization** | `/using-git-worktrees`, `/dispatching-parallel-agents`, `/multi-agent-branching` |
| **Subagent orchestration** | `/subagent-driven-development`, `/dispatching-parallel-agents`; keep context small per agent |

## Environment variables (opt-in ECC hooks)

| Variable | Default | Effect |
|----------|---------|--------|
| `MCR_STRATEGIC_COMPACT_THRESHOLD` | `50` | Edit/Write-class tool calls before strategic `/compact` stderr nudge; **`0`** disables counting |
| `MCR_ECC_STOP_NUDGE` | `0` | **`1`** enables **`ecc/stop-learning-nudge.sh`** on Stop / `stop` |
| `MCR_ECC_PRECOMPACT_NUDGE` | `0` | **`1`** enables **`ecc/precompact-verify-nudge.sh`** on **PreCompact** (Claude only) |

## Security (agentic hooks / MCP)

Repo-controlled hooks and MCP config are a **trust boundary**. Keep Claude Code updated; review `.claude/` and `.mcp.json` like supply-chain config. See `hooks/README.md` § Security.

## Install

Installed as the **mobile-agent-toolkit Claude Code plugin** (the legacy `install.sh` submodule installer was removed). Update with `claude plugin update mobile-agent-toolkit@mobile-agent-toolkit`, then run `/reload-plugins` or restart the session.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
