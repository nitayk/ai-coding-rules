---
name: cost-audit
description: "Use when auditing LLM token spend across coding-agent sessions, building a cost baseline, or hunting for waste (unused MCPs, oversized CLAUDE.md files, low cache hit rates). Reads local session data via codeburn — no API keys, no cloud upload. Do NOT use for runtime app performance (use /code-optimization) or for token-output compression (use /agent-token-optimization with RTK)."
---

# Cost Audit

Measure where your LLM tokens go across coding-agent sessions (Claude Code, Cursor, etc.). Surface waste patterns. **Treat findings as hypotheses to verify, not prescriptions to execute.**

## When to Use

**APPLY WHEN:**
- Building a baseline cost picture across projects ("which repos cost what per session?")
- Hunting for waste: unused MCP servers, bloated CLAUDE.md files, ghost skills, low cache hit rates
- Comparing model spend (Opus vs Sonnet vs Haiku) on actual workload
- After a major harness change (new MCP, new skill set), measuring impact
- Quarterly health check on the agent harness

**SKIP WHEN:**
- Optimizing application runtime perf → `/code-optimization`
- Reducing tool-output bloat in-flight → `/agent-token-optimization` (covers RTK and similar shell-output compressors)
- Single-session debugging — codeburn is for cross-session aggregates, not real-time
- The harness is fresh / has < 1 week of session history (insufficient data)

## Install (required)

```bash
# Try once, no install
npx -y codeburn --version

# Or persistent install via Homebrew (requires the tap first)
brew tap getagentseal/codeburn
brew install codeburn
```

Reads session data from agent-specific local paths and prices via [LiteLLM](https://github.com/BerriAI/litellm) cached locally. **Nothing leaves the machine.**

CodeBurn auto-detects which agent harnesses you use. Per-tool data locations (Claude Code, Cursor, Codex, Copilot, etc.) are in [the CodeBurn README's "Supported Providers" table](https://github.com/getagentseal/codeburn#supported-providers); see also [AGENTS.md](../../AGENTS.md) for this repo's per-target install paths.

## Workflow

### 1. Baseline (read-only, safe)

```bash
npx -y codeburn report --format json -p week    # 7d aggregate, programmatic
npx -y codeburn yield -p 30days                 # productive vs reverted/abandoned spend
npx -y codeburn compare                         # per-model actuals
```

Capture: total spend, calls, sessions, **cache hit rate** (>90% is healthy), per-project cost, **per-session $ outliers**.

### 2. Generate findings

```bash
npx -y codeburn optimize -p week --provider claude
```

Returns ranked findings + A–F health grade. Typical categories:

| Finding | Common cause |
|---|---|
| Read:Edit ratio low | Methodology may mislead when Bash dominates exploration |
| Same files re-read | Cross-session cold starts; existing memory may already address |
| Unused MCP servers | Verify scope (project vs global) — many MCPs are product-scoped |
| Long CLAUDE.md | Verify ownership before trimming |
| Reading build/dep dirs | Real, easy CLAUDE.md fix |
| Bash output uncapped | Real, set `BASH_MAX_OUTPUT_LENGTH=15000` |
| Unused skills | Hook-driven skills are invisible to CodeBurn's counter |

### 3. **Verify before acting** (critical)

CodeBurn's `optimize` is a **hypothesis generator**, not a finding. On real audits, half or more of prescriptions can fail verification. **Do not** include CodeBurn fixes in any "safe autonomous actions" bucket without per-item verification.

Quick checks per category:

```bash
# Skill flagged "unused"? Check hook references AND transcripts
grep <skill-name> ~/.claude/settings.json
grep -rl <skill-name> ~/.claude/projects/

# MCP flagged "unused"? Check scope
for f in ~/Repos/.mcp.json ~/Repos/*/.mcp.json; do
  grep -l <mcp-name> "$f" 2>/dev/null
done

# Long CLAUDE.md? Check ownership
git log --format='%an' <CLAUDE.md path> | sort -u

# Bad Read:Edit ratio? Check Bash:Read first (in tools array of report JSON)
```

If a "ghost skill" is hook-connected, an "unused MCP" is project-scoped to a sunsetting product, or a CLAUDE.md is owned by another engineer — leave them alone.

## Output

Per audit, produce a short report:

| Section | Content |
|---|---|
| **Baseline** | Total spend, sessions, cache hit %, per-project breakdown |
| **Outlier sessions** | Top 3 most-expensive-per-session projects + cheapest one (template) |
| **Verified findings** | Only those that survived per-category verification |
| **Phantom findings** | Flagged but turned out intentional/scoped/hook-driven (saves the next auditor the work) |
| **Trend** | Improving / regressing / stable vs last audit |

## Companions

| Need | Skill |
|---|---|
| Compress shell output before it reaches the model | `/agent-token-optimization` (covers RTK) |
| Optimize app runtime perf | `/code-optimization` |
| Memory hygiene across sessions | `/session-memory` |
| Phase-aware compaction | `/strategic-compact` |

## Cursor vs Claude Code

| Surface | Notes |
|---|---|
| **Claude Code** | Reads `~/.claude/projects/<project-id>/*.jsonl` session data |
| **Cursor** | Reads `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (SQLite). Cursor "Auto" mode hides actual model — costs are estimated at Sonnet rates (labeled `Auto (Sonnet est.)`) |

CodeBurn auto-detects which agents you use; press `p` in the dashboard TUI to toggle providers, or use `--provider <name>` to scope.
