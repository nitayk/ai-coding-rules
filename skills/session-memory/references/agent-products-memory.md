# Session memory and hook automation (Claude Code)

This toolkit ships as a Claude-Code-only plugin (the Cursor and Copilot install
targets were removed in v2.0 — [ADR-009](../../../docs/decisions/ADR-009-plugin-v2-self-contained.md)).
Session memory is a **local file** the agent reads/writes; hook-driven automation
runs via the plugin's Claude hooks.

| Concern | Claude Code |
|---------|-------------|
| **Scratchpad file** | `.claude/memory/active_context.md` — resolve via **`/session-memory`**; work from the repo root (or set `REPO_ROOT`). |
| **Which path in chat** | **`/session-memory`** resolves the path; store it in `MEMORY_FILE` rather than hardcoding. |
| **Hooks** | `.claude/hooks/` + `hooks.json`, wired by the plugin — see [hooks/README.md](../../../hooks/README.md). |
| **"Learn from session" automation** | Claude `Stop`-hook nudges only. The `/continuous-learning-v2` skill was removed per AppSec review (see [SOURCES.md](../../../SOURCES.md#removed-skills-appsec)); consume upstream ECC directly if you need the instinct pipeline. |

**Takeaway:** Use **`/session-memory`** for the scratchpad and **`/agent-token-optimization`**
for hook-driven persistence (opt-in per [hooks/README.md](../../../hooks/README.md)).

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
