# Smart Gates

## 1. Clarification Gate (Build/Refactor/Migrate)

- **Trigger**: "build", "refactor", "migrate", "implement", "add feature", "create"
- **Action**: STOP and ask 3-4 clarifying questions (Language? Framework? Edge Cases? Tests?)
- **Exception**: If user explicitly provides a PRD, comprehensive spec, or says "skip clarification".

## 2. Session Memory (Complex Tasks)

- **Trigger**: Any multi-step task, "continue", "resume", "remember", "context"
- **Action**: LOAD `.cursor/memory/active_context.md` immediately.
- **Rule**: Use the `/session-memory` skill or read `references/rules/common/generic/memory-interface.md`.

## 3. Debug Protocol (Debug/Fix)

- **Trigger**: "debug", "fix", "error", "bug", "broken", "investigate"
- **Action**: Enforce root cause investigation before fixes. NEVER fix blindly.
- **Rule**: Use `/systematic-debugging` skill (if available) or read `references/rules/common/generic/debugging/strategies.md`.

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
