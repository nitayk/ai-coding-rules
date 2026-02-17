---
name: debug-workflow
description: "Enforce a strict Log-Reproduce-Fix cycle for debugging. Use when fixing bugs, investigating errors, or troubleshooting failures."
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
1.  **Trace**: Use `grep` or `Memgraph` to trace the flow.
2.  **Theorize**: "I believe the root cause is..."
3.  **Verify Hypothesis**: Add log statements or breakpoints to confirm.

### Phase 3: Remediation
1.  **Fix**: Apply the fix.
2.  **Test**: Run the reproduction case again.
3.  **Verify**: "Test passed. Error is gone."

## Strict Rules
- **NEVER** fix blindly ("I'll try changing this").
- **NEVER** skip reproduction (unless it's a syntax error).
- **ALWAYS** provide evidence of the fix (test output).
