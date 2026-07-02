# Source of truth

This repository **is** [nitayk/nitays-agent-toolkit](https://github.com/nitayk/nitays-agent-toolkit): the canonical package (skills, agents, commands, hooks, core rules, installer). It targets **Claude Code**.

**Consumers** add it as a submodule and run the `acr` installer:

```bash
git submodule add https://github.com/nitayk/nitays-agent-toolkit.git .cursor/rules/shared
go build -o ~/.local/bin/acr ./.cursor/rules/shared/cli
acr install
```

The submodule lives at `.cursor/rules/shared` on purpose — **never** under `.claude/rules/`, because Claude Code auto-loads every `.md` file under `.claude/` and a submodule there would cause a context explosion. Claude ignores `.cursor/`, so it's a safe home for the checkout. `acr sync` copies skills/agents/commands/hooks to the correct `.claude/` paths.

Skills are always **copied** (not symlinked) because Claude Code does not discover symlinked skill directories. Agents and commands use symlinks for automatic updates; use `--copy` to fall back to full copying.

See [SOURCES.md](./SOURCES.md) for upstream provenance.
