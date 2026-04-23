# Source of truth

This repository **is** [nitayk/ai-coding-rules](https://github.com/nitayk/ai-coding-rules): the canonical package (rules, skills, installers).

**Consumers** add it as a submodule and run the unified installer from the submodule path:

```bash
# Add submodule + sync (Cursor, default)
bash .cursor/rules/shared/install.sh

# Claude Code target
bash .cursor/rules/shared/install.sh --target claude

# Both targets
bash .cursor/rules/shared/install.sh --target cursor,claude
```

The submodule always lives at `.cursor/rules/shared` (never under `.claude/rules/` — Claude Code auto-loads all `.md` files there, causing context explosion). `sync-rules.sh` handles copying skills/agents/commands to the correct `.claude/` paths.

Skills are always **copied** (not symlinked) because Cursor and Claude Code do not discover symlinked skill directories. Agents and commands use symlinks for automatic updates; use `--copy` to fall back to full copying.

See also [UPSTREAM_SCOPE.md](./UPSTREAM_SCOPE.md) for how this pack relates to ironsource **mobile-cursor-rules** and Unity **ai-agent-skills**.
