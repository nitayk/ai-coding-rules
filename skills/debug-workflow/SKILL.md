---
name: debug-workflow
description: "Use as a quick-triage entry point for debugging — Log → Reproduce → Fix protocol with three concrete entry shortcuts (Slack thread, CI failure, Docker logs). For deep root-cause methodology and four-phase analysis, defer to /systematic-debugging. Do NOT use when fix is already identified or when the bug needs multi-hypothesis investigation."
last-reviewed: 2026-05-27
---

# Debug Workflow

**Purpose**: Quick-triage entry point for debugging. Enforces a strict Log → Reproduce → Fix cycle and routes three common bug entry shortcuts (Slack thread paste, CI failure, Docker logs).

## When to Use This Skill

**APPLY WHEN:**
- Quick triage — bug is roughly understood, just need disciplined Log → Reproduce → Fix
- One of the three concrete entry shortcuts applies (Slack bug thread / CI failure / Docker logs)
- User asks "debug", "fix", "investigate error", "troubleshoot" and the scope feels tactical (single failure, single hypothesis)

**DO NOT USE WHEN:**
- Bug requires deep root-cause analysis or multi-hypothesis investigation → **use [`/systematic-debugging`](../systematic-debugging/SKILL.md)** (four-phase methodology, richer than this skill)
- Fix is already identified — just apply it
- The failure mode is "test pass-rate dropped" or "behavior changed silently" → those need a root-cause hunt, not this lightweight cycle

## Routing vs `/systematic-debugging`

| If… | Use |
|---|---|
| You have a stack trace + a failing test | This skill (tactical) |
| You need to understand *why* before fixing | `/systematic-debugging` |
| You want a quick Slack-thread / CI / Docker-logs entry | This skill |
| The bug crosses multiple services or has multiple hypotheses | `/systematic-debugging` |

## The Protocol

### Phase 1: Evidence (Mandatory)
**Stop! Do not touch code yet.**
1. **Read Logs**: Find the stack trace or error message.
2. **Reproduce**: Create a minimal reproduction case or run the failing test.
3. **Confirm**: "I have reproduced the issue. The error is..."

### Phase 2: Hypothesis
1. **Trace**: Use `grep` or code search to trace the flow. (A code-graph tool if available.)
2. **Theorize**: "I believe the root cause is..."
3. **Verify Hypothesis**: Add log statements or breakpoints to confirm.

### Phase 3: Remediation
1. **Fix**: Apply the fix.
2. **Test**: Run the reproduction case again.
3. **Verify**: "Test passed. Error is gone."

## Streamlined Entry Shortcuts (the unique value of this skill)

### Slack Bug Thread
1. **Input**: User pastes a Slack bug thread and says "fix".
2. **Action**: Extract error details directly from the thread text. Treat it as the "Read Logs" step. Proceed to Reproduction.

### CI Failures
1. **Input**: User says "Go fix the failing CI tests."
2. **Action**:
   - Locate CI output (ask user for log paste if not available).
   - Identify failing test targets.
   - Run those tests locally to reproduce.
   - Fix.

### Docker Logs
1. **Input**: User points to docker logs.
2. **Action**:
   - Read logs to troubleshoot distributed systems issues.
   - Look for service interactions, timeouts, or connection errors.

## Strict Rules
- **NEVER** fix blindly ("I'll try changing this").
- **NEVER** skip reproduction (unless it's a syntax error).
- **ALWAYS** provide evidence of the fix (test output).
- **ESCALATE to `/systematic-debugging`** if Phase 2 hypothesis fails to verify — that's the signal you need depth, not triage.

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
