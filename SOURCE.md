# Source of truth

This repository **is** [nitayk/ai-coding-rules](https://github.com/nitayk/ai-coding-rules): the canonical package (rules, skills, installers).

**Consumers** add it as a submodule and run installers from the submodule path, for example:

- `.cursor/rules/shared` → `bash .cursor/rules/shared/install-cursor.sh`
- Claude Code: symlink or place at `.claude/rules/shared` → `bash .claude/rules/shared/install-claude.sh`

**`.cursor/skills`** in a consumer repo should be a **symlink** to `rules/shared/skills` (created by `install-cursor.sh` by default). Use `--copy` only if Cursor does not discover symlinked skill trees.

See also [UPSTREAM_SCOPE.md](./UPSTREAM_SCOPE.md) for how this pack relates to ironsource **mobile-cursor-rules** and Unity **ai-agent-skills**.
