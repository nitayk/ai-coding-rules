---
name: debug-workflow
description: "Use when enforcing Log -> Reproduce -> Fix cycle for debugging. Do NOT use when fix is already identified."
---

# Debug Workflow

**Purpose**: Enforce a strict "Log -> Reproduce -> Fix" cycle for debugging.

## When to Use This Skill
**APPLY WHEN:**
- User asks to "debug", "fix", "investigate error", "troubleshoot"
- Fixing a bug reported in logs
- Investigating test failures

## The Protocol

### Phase 1: Evidence (Mandatory)
**Stop! Do not touch code yet.**
1.  **Read Logs**: Find the stack trace or error message.
2.  **Reproduce**: Create a minimal reproduction case or run the failing test.
3.  **Confirm**: "I have reproduced the issue. The error is..."

### Phase 2: Hypothesis
1.  **Trace**: Use `grep` or code search to trace the flow. (Code graph / Memgraph if available.)
2.  **Theorize**: "I believe the root cause is..."
3.  **Verify Hypothesis**: Add log statements or breakpoints to confirm.

### Phase 3: Remediation
1.  **Fix**: Apply the fix.
2.  **Test**: Run the reproduction case again.
3.  **Verify**: "Test passed. Error is gone."

## Streamlined Workflows (Zero Context Switching)

### Slack Bug Thread
1.  **Input**: User pastes a Slack bug thread and says "fix".
2.  **Action**: Extract error details directly from the thread text. Treat it as the "Read Logs" step. Proceed to Reproduction.

### CI Failures
1.  **Input**: User says "Go fix the failing CI tests."
2.  **Action**: 
    - Locate CI output (ask user for log paste if not available).
    - Identify failing test targets.
    - Run those tests locally to reproduce.
    - Fix.

### Docker Logs
1.  **Input**: User points to docker logs.
2.  **Action**: 
    - Read logs to troubleshoot distributed systems issues.
    - Look for service interactions, timeouts, or connection errors.

## Strict Rules
- **NEVER** fix blindly ("I'll try changing this").
- **NEVER** skip reproduction (unless it's a syntax error).
- **ALWAYS** provide evidence of the fix (test output).

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
