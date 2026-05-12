# Cursor, Claude Code, and GitHub Copilot: file memory vs hook automation

This repo supports **`install.sh --target`** combinations of **cursor**, **claude**, and **copilot**. Session memory is a **local file** the agent reads/writes; hooks and automation differ by product. See [PRODUCT_COMPARISON.md](../../../targets/copilot/PRODUCT_COMPARISON.md) for full product mapping.

| Concern | Cursor | Claude Code | GitHub Copilot |
|---------|--------|---------------|----------------|
| **Scratchpad file** | `.cursor/memory/active_context.md` (`cursor` target) | `.claude/memory/active_context.md` (`claude` target) | Same path as Cursor for this package: **`.cursor/memory/active_context.md`** — `sync-rules.sh` uses `MEMORY_DIR=.cursor/memory` for the **`copilot`** target too (VS Code / repo workspace). |
| **Which path in chat** | **`/session-memory`** — resolve by runtime and existing files | Same; **do not** hardcode `.cursor/` if Claude isolation blocks it | Use **`.cursor/memory/`** when present; Copilot repo instructions (`.github/copilot-instructions.md`) do not replace this file — they point at submodule **rules**, not the scratchpad path. |
| **Hooks** | `.cursor/hooks.json` — see [hooks/README.md](../../../hooks/README.md) | `.claude/hooks/` + `hooks.json` | No parity with this repo’s hook packs on **Copilot-only** install; use **`cursor,copilot`** or **`claude,copilot`** if you need Copilot instructions **and** hooks. |
| **“Learn from session” automation** | No default ECC Stop-hook parity | [`/continuous-learning-v2`](../../continuous-learning-v2/SKILL.md) + Claude hooks | Same as Cursor for hook availability — typically need a **multi-target** install. |

**Takeaway:** Use **`/session-memory`** and resolve **Cursor vs Claude vs Copilot** using the skill’s decision order. For **hook-driven** persistence, read **`/agent-token-optimization`** and **`/continuous-learning-v2`** (opt-in per [hooks/README.md](../../../hooks/README.md)).

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
