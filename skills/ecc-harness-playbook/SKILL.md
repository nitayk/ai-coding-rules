---
name: ecc-harness-playbook
description: "Use when maximizing agent harness value (ECC / Everything Claude Code patterns): token economics, memory persistence hooks, strategic compaction, PreCompact/stop opt-in nudges (MCR_ECC_*), session id lifecycle, /ecc-env, verification loops, git worktrees, subagent orchestration. Maps Longform topics to this repo's skills and hooks — not a substitute for upstream ECC install."
---

# ECC harness playbook (mobile-cursor-rules)

This skill ties **Longform / Shorthand ECC topics** to **what this repo actually ships** after `install.sh`. For the upstream plugin and full skill packs, see [everything-claude-code](https://github.com/affaan-m/everything-claude-code).

## Topic → repo surface

| Topic | What to use here |
|--------|-------------------|
| **Token optimization** | `/agent-token-optimization`; cap MCPs; model tiering in agent YAML where you control it |
| **Memory persistence** | `/session-memory` (`active_context.md`); **hooks**: `ecc/memory-lifecycle.sh` on Claude `SessionStart` / `PreCompact` / `Stop` and Cursor `sessionStart` / `stop` (see `hooks/README.md`). Each **start** writes **`.claude/sessions/.session_id`** or **`.cursor/sessions/.session_id`** and logs **`session_id=...`** in **`lifecycle.log`** on start / pre-compact / stop. |
| **ECC env + session** | Slash command **`/ecc-env`**; script **`scripts/ecc-env.sh`** prints `MCR_*` variables and current session id file(s). |
| **Strategic compaction** | `/strategic-compact` skill; **hook** `ecc/strategic-compact-nudge.sh` (PreToolUse, Edit/Write-class tools); env `MCR_STRATEGIC_COMPACT_THRESHOLD` (default 50, `0` disables) |
| **PreCompact → verify (opt-in, Claude)** | **`ecc/precompact-verify-nudge.sh`** — stderr only when **`MCR_ECC_PRECOMPACT_NUDGE=1`**. Reminds you to verify/tests before context compaction. **Cursor** has no `PreCompact` event. |
| **Continuous learning** | `/continuous-learning-v2`; `ecc/tool-observe.sh` logs as optional input; full ECC `observe.sh` is upstream |
| **Stop → verify / learn (opt-in)** | **`ecc/stop-learning-nudge.sh`** on Claude `Stop` and Cursor `stop` — stderr reminder only when **`MCR_ECC_STOP_NUDGE=1`** (default off). Pairs verification + learning without spamming every turn. |
| **Local churn in git** | **`sync-rules.sh` / `install.sh`** append **`.claude/sessions/`**, **`.cursor/sessions/`**, **`.claude/hooks/logs/`**, **`.cursor/hooks/logs/`** to `.gitignore` (idempotent block) alongside agent memory. |
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

```bash
bash .cursor/rules/shared/install.sh --target cursor,claude
```

Restart the IDE. Requires **`jq`** for per-target `hooks.json` filtering.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
