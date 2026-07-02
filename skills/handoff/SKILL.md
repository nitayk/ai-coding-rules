---
name: handoff
description: Use when you need to peel an OUT-OF-SCOPE sub-task off the current session and hand it to a FRESH, separate agent (possibly a different harness — Codex, Copilot CLI, a new Claude session) while keeping THIS session focused and "pure". Writes a disposable, portable handoff brief to the OS temp dir (not the repo) describing just the slice to pick up, with a suggested-skills section and pointers to existing artifacts. Triggers on "hand this off", "spin up a fresh session for X", "offload this out-of-scope bit", "/handoff". Do NOT use for same-session context compaction (use strategic-compact), checkpointing your OWN work to resume later (use pause/unpause), relaying to an ALREADY-running peer agent (use agent-mailbox), or a fire-and-forget autonomous subtask (use a subagent).
---

# Handoff

Compact a *slice* of the current conversation into a disposable, portable brief
so a **fresh** agent — in a new session, or even a different harness — can pick
up an out-of-scope sub-task while the current session stays focused on its main
thread.

The brief is throwaway markdown written to the OS temp dir. It is a pointer, not
a copy: it references existing artifacts rather than duplicating them, and it
tells the receiving session which skills to invoke.

## When to use this (and when NOT to)

This skill fills one specific seam. Pick the right primitive:

| You want to… | Use | Not this skill because… |
|---|---|---|
| Continue the **same** session with less context noise | `strategic-compact` | same-session compaction, no handoff |
| Checkpoint **your own** work and resume it **yourself** later | `/pause` + `/unpause` | persisted self-resume, not a brief for a *different* agent |
| Message an **already-running peer** agent | `agent-mailbox` | peer relay to a live session, not spin-up of a fresh one |
| Run an autonomous subtask and get findings back | a subagent (`Agent` tool) | fire-and-forget, same harness, no human in the loop |
| Peel an **out-of-scope slice** off to a **fresh / cross-harness, human-driven** session, parent untouched | **`/handoff`** ← you are here | |

Two patterns this enables:
- **Offload-during-grilling** — when a question is out of scope for the current
  design/grill, hand the slice off ("picked up elsewhere") so the current
  session stays sharp instead of sprawling.
- **Round-trip** — hand a heavy sub-investigation (e.g. a large prototype that
  won't fit in the current budget) to a fresh session, then hand the *learnings*
  back to this one. A DIY subagent: one context window per task, compressed in
  and out.

## Workflow

1. **Take the next-session purpose as the argument.** If the user passed text
   (e.g. `/handoff "prototype the Redis cache layer"`), that is the slice — scope
   the brief to it. If not, ask one line: "What will the next session focus on?"

2. **Write the brief to the OS temp dir, NOT the repo.** Use `$TMPDIR` (macOS) /
   `/tmp` (Linux) / `%TEMP%` (Windows). It is disposable scratch — never commit
   it, never `git add` it. Suggested name: `handoff-<slug>-<date>.md`. Print the
   path so the user can open it in the fresh session.

3. **Reference, don't duplicate.** Point at existing artifacts (PRDs, plans,
   ADRs, issues, PRs, commits, design docs) by **path or URL**. Do not paste
   their contents — the receiving agent can open them. Duplication rots.

4. **Include a "Suggested skills" section** so the fresh session auto-flavors
   itself (e.g. "invoke `/e2e` for the build", "do a code-search pass to map
   callers first"). This is what lets a cold session start warm.

5. **Redact secrets / PII** — no API keys, tokens, passwords, or personal data
   in the brief. It is a file on disk that may outlive the task.

6. **Keep it portable.** Plain markdown, no harness-specific syntax, so the brief
   works whether the next session is Claude Code, Codex, Copilot CLI, or a web
   chat.

## Brief template

```md
# Handoff: <slice / purpose>

**Written:** <date> · from <this session's topic> · **disposable — temp dir, not the repo**

## The slice (what THIS session is for)
<one paragraph: the out-of-scope sub-task being picked up, and its boundary>

## Context (pointers, not copies)
- Repo / branch / worktree: <path>
- Relevant artifacts: <PRD/plan/ADR/PR/issue/design-doc paths or URLs>
- Key decisions already made: <one-liners + where they're recorded>

## State so far
<what's done, what's in flight, what's blocked — terse>

## Next actions
1. <first concrete step>
2. <…>

## Suggested skills
- `/<skill>` — <why, when in the flow>

## Constraints
<branch rules, don't-touch zones, deadlines, versions, security/privacy limits>
```

## Notes

- This is a **complement**, never a replacement for the primitives in the table
  above. When in doubt, name which one applies and why.
- The brief is intentionally lossy — it carries the *slice*, not the whole
  session. If the receiving agent needs more, it follows the pointers.

---

*Adapted in spirit (MIT) from Matt Pocock's `/handoff` skill
([mattpocock/skills](https://github.com/mattpocock/skills), MIT). The original
is a deliberately tiny prompt; this version keeps that spirit and adds explicit
complement-routing against the rest of the toolkit's handoff/compaction
primitives (`strategic-compact`, `pause`/`unpause`, `agent-mailbox`, subagents)
so the seam it fills is unambiguous.*

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
