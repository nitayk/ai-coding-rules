---
name: agent-token-optimization
description: "Use when optimizing LLM/agent token cost and context usage—model tiering (Haiku/Sonnet/Opus), subagent model choice, avoiding huge shell/MCP output in context, MCP vs CLI tradeoffs, modular files, eval harness vocabulary (pass@k, checkpoint vs continuous). Do NOT use for runtime CPU/memory of your app—use /code-optimization for that."
---

# Agent Token Optimization

Reduce **LLM and agent-harness** cost: context window usage, model tiering, and how much text you feed the model—not application runtime performance.

## When to Use

**APPLY WHEN:**
- User asks about **token cost**, **billable context**, **cheaper model**, or **smaller prompts**
- Choosing **which model** for a subagent or background task
- **Streaming** large command or tool output is blowing the context window
- Comparing **MCP in-chat** vs **CLI outside** the agent for heavy operations
- Structuring work so the agent reads **smaller, focused files** instead of megabytes
- Discussing **eval harness** design (checkpoint vs continuous, pass@k) in agent workflows

**SKIP WHEN:**
- Optimizing **application** CPU, memory, or algorithmic performance → use `/code-optimization`
- Only improving **prompt wording** for clarity (not cost)—consider `/prompt-optimizer`
- Simple “run tests before done” → `/verification-before-completion`

## Practices

### Model tiering (heuristic)

- Use the **least capable model that fits** the task for delegated/subagent work (e.g. narrow search, formatting, repetitive edits).
- Reserve **strongest models** for architecture, security-sensitive edits, or when cheaper models failed once.
- **Mass-repo playbooks** (same change in many repositories): use the **strongest** tier for **planning** and the **first few pilot repos**; once the checklist is stable and mistakes are rare, switch **bulk application** to a **cheaper** tier. See `/mass-repo-orchestration`.
- Exact names and pricing change over time—verify current docs for your harness.

### Avoid huge context in the agent

- Prefer **summaries** or **excerpts** of command output instead of streaming full logs into the chat.
- Run **long jobs** in a terminal (`tmux`, background), then paste only the **relevant slice** or a **failure snippet**.
- Optional tools (e.g. **mgrep**-style search) may reduce token use vs naive grep in some setups—evaluate in your environment.

### Modular codebases

- Smaller files and clear modules mean fewer tool reads and less re-reading—aligns with Longform-style guidance.

### MCP vs CLI

- Heavy operations (large DB pulls, deploys) often cost fewer **agent** tokens if run **via CLI** outside the agent, with results summarized in chat—especially if your MCP loads large payloads into context.

### Advanced (external)

- **System prompt** / static overhead tuning is harness-specific; treat any “patch” workflows as **external** and optional.

## Eval vocabulary (agents)

This is **not** a substitute for `/verification-before-completion` (honesty gate before “done”). It names **harness-level** evaluation ideas:

- **Checkpoint evals** — judge output at defined milestones (e.g. after each task).
- **Continuous evals** — monitor behavior or metrics over a longer run.
- **Grader** — automated or LLM-based scorer for a criterion.
- **pass@k** — success rate over *k* attempts or samples (common in agent benchmarks).

**Further reading:** [Anthropic: Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) (Jan 2026).

## Relationship to other skills

| Need | Skill |
|------|--------|
| “Don’t claim done without running checks” | `/verification-before-completion` |
| Runtime app performance | `/code-optimization` |
| Session scratchpad file | `/session-memory` |
| Phase-aware compaction | `/strategic-compact` |
| Hook-based learning (instincts) | `/continuous-learning-v2` |
| Parallel worktrees / agents | `/using-git-worktrees`, `/dispatching-parallel-agents` |
| Same change across many repos | `/mass-repo-orchestration` |
| Subagent workflow discipline | `/subagent-driven-development` |

## Cursor vs Claude Code

| Surface | What you get |
|---------|----------------|
| **Cursor** | Rules + skills + optional **Cursor hooks** (`hooks-cursor.json` pattern in this repo). File memory via **`/session-memory`** and `.cursor/memory/active_context.md` (created by install). |
| **Claude Code** | Same skills + **Claude `hooks.json`** hooks (e.g. `SessionStart`, lifecycle hooks). **Continuous learning** automation is **most** aligned with Claude Code hook paths—see `/continuous-learning-v2`; full ECC-style automation is **opt-in**, not guaranteed by submodule install alone. |

Do **not** assume Cursor and Claude expose identical hook events or paths—see [hooks/README.md](../../hooks/README.md).
