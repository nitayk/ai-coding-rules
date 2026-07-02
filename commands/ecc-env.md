# ECC environment

Print **ECC-related hook environment variables** and the **current session id** file (from `ecc/memory-lifecycle.sh`), if present.

## Usage

```
/ecc-env
```

## What to do

1. From the **git repository root**, copy and run this one-liner to find and execute the script:

```bash
for f in scripts/ecc-env.sh; do [ -f "$f" ] && bash "$f" && break; done
```

2. Paste the terminal output into chat if you need the agent to see current toggles.

## Variables

| Variable | Role |
|----------|------|
| `MCR_STRATEGIC_COMPACT_THRESHOLD` | Edit/Write tool count before strategic `/compact` nudge (`0` = off) |
| `MCR_ECC_STOP_NUDGE` | `1` = enable `ecc/stop-learning-nudge.sh` on Stop |
| `MCR_ECC_PRECOMPACT_NUDGE` | `1` = enable `ecc/precompact-verify-nudge.sh` on PreCompact (Claude) |

**Session id**: written to **`.claude/sessions/.session_id`** or **`.cursor/sessions/.session_id`** on SessionStart; lines in **`lifecycle.log`** include `session_id=...`.

See **`/ecc-harness-playbook`** and **`hooks/README.md`**.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
