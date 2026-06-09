# `acr` — ai-coding-rules CLI

`acr` is a single static Go binary that manages the ai-coding-rules shared
submodule and the skills, agents, commands, and hooks it deploys into Cursor and
Claude Code projects. It replaces four shell scripts with one typed CLI:

| Old script | Subcommand |
|---|---|
| `install.sh` | `acr install` |
| `sync-rules.sh` | `acr sync` |
| `link-to-project.sh` | `acr link` |
| `update-community.sh` | `acr update` |

The deprecated stubs (`install-global.sh`, `install-claude.sh`,
`install-cursor.sh`, `setup-project.sh`) were removed.

## Why `acr`?

Short, unshadowed, and maps to **a**i-**c**oding-**r**ules. The alternative
`ruler` was rejected as a default because an unrelated AI-rules tool already
ships as `ruler` (`npx @intellectronica/ruler`), so the name would collide.

## Build & install

```bash
# from the repo root
go build -o acr ./cli
# put it on your PATH (the post-merge hook calls `acr sync`)
mv acr ~/.local/bin/    # or anywhere on $PATH
```

Requires Go 1.23+. No runtime dependencies beyond `git` (for `install` and
`update`). Unlike the shell scripts, `acr` needs no `jq`/`python3` — JSON
merging and relative-symlink math are done natively.

## Commands

All mutating commands accept `--dry-run` and the global `-v/--verbose`.

### `acr install`
One-shot setup for a consumer repo: reconciles the `.cursor/rules/shared`
submodule, runs a sync, and installs a `post-merge` git hook so syncs happen
after every `git pull`. Run from inside the ai-coding-rules checkout itself, it
skips the submodule/hook steps and just syncs.

```bash
acr install                         # Cursor (default)
acr install --target claude         # Claude Code paths
acr install --target cursor,claude  # both
acr install --dry-run
```

### `acr sync`
Deploys skills/agents/commands/hooks into a project. Skills are always **copied**
(Cursor/Claude don't index symlinked skill trees); agents, commands, and hooks
are **symlinked** by default (`--copy` to copy instead).

```bash
acr sync                          # Cursor, from a consumer repo
acr sync --target cursor,claude
acr sync --skills core,git        # only these skill groups
acr sync --no-skills scala        # everything except the scala group
acr sync --copy --force
```

### `acr link`
Symlinks this checkout into a project's `.cursor/rules/shared` (and/or
`.claude/rules/shared`) instead of using a submodule. One clone, many projects.

```bash
acr link ~/projects/my-app          # Cursor only
acr link ~/projects/my-app --both   # Cursor + Claude
```

### `acr update`
Refreshes vendored community skills from `obra/superpowers` and
`anthropics/skills` into this checkout. Review with `git diff` afterward.

```bash
acr update --dry-run
acr update --diff
```

## Behavior parity

`acr` reproduces the shell scripts' **filesystem effects** exactly: destination
paths, symlink layout, file contents, JSON (semantically), and `.gitignore`
patterns. Two deliberate, documented deviations:

1. The generated post-merge hook calls `acr sync` instead of `bash sync-rules.sh`
   (the tool being replaced).
2. `acr update` caches upstream clones under the user cache dir
   (`os.UserCacheDir()`) instead of a world-writable `/tmp` path — a security
   hardening over the script.

Parity was proven by `cli/parity/`, which runs the **real** shell scripts and
`acr` against identical fixtures and diffs the resulting trees. Those tests are
the gate that ran green before the scripts were deleted; they skip gracefully
when the original `.sh` baselines are absent (recover them from git history to
re-run).

## Tests

```bash
cd cli
go test ./...        # unit + parity (parity needs bash/jq/python3/git + scripts)
go vet ./... && gofmt -l .
```

## Relationship to `ccpm`

`acr install` / `acr sync` overlap `ccpm`'s "set up a repo's agent assets"
domain. This pilot intentionally stays **standalone** — no merge with `ccpm` —
to prove the Go-CLI pattern cleanly. The wrapper-vs-reimplement question for the
`cgctl` effort is deferred; see [`docs/go-cli-conventions.md`](../docs/go-cli-conventions.md)
for the structure/conventions meant to transfer there.
