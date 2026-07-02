# Plan: Replace shell install/sync tooling with a Go CLI (`acr`)

**Classification:** refactor (bash→Go reimplementation at filesystem-behavior parity)
**Stack:** backend-go · cobra · single static binary · style-focused (pilot for future Go CLIs)

## Goal

Replace the 4 active shell scripts with one strongly-typed Go CLI, `acr`, exposing
subcommands `install` / `sync` / `link` / `update`. Delete the 4 deprecated stubs.
Behavior parity = identical **filesystem effects** (paths, symlink layout, file
contents, JSON merges, gitignore blocks). Log wording may differ; effects may not.

| Script (lines) | Subcommand |
|---|---|
| `sync-rules.sh` (1319) | `acr sync` |
| `install.sh` (485) | `acr install` |
| `update-community.sh` (297) | `acr update` |
| `link-to-project.sh` (108) | `acr link` |
| `install-{global,claude,cursor}.sh`, `setup-project.sh` (stubs) | deleted |

## Project layout (self-contained module under `cli/`)

```
cli/
  go.mod                       module github.com/nitayk/ai-coding-rules/cli
  main.go                      thin: os.Exit(cmd.Execute())
  cmd/                         cobra wiring only (flags, help, arg validation)
    root.go  install.go  sync.go  link.go  update.go
  internal/
    ui/        colored logger + run stats (Info/Success/Warn/Error/Verbose)
    fsx/       symlink rel-path, copy file/dir, checksum, identical, gitignore edits
    skillgroups/  YAML-ish group resolver (no yq/python dep)
    hooksjson/    merge + per-target filter of hooks.json (encoding/json)
    syncer/    core sync engine (was sync-rules.sh)
    installer/ submodule + post-merge-hook orchestration (was install.sh)
    linker/    symlink repo into a project (was link-to-project.sh)
    updater/   upstream clone/pull + community sync (was update-community.sh)
  testdata/    fixtures for parity + unit tests
```

Self-contained module under `cli/` keeps the Go toolchain isolated from the
rules-repo root (matches the "keep self-contained for now" constraint). Build:
`go build -o acr ./cli` (or `cd cli && go build -o ../acr .`).

## Cobra patterns (to transfer to a downstream Go CLI)

- `cmd/` holds **only** cobra wiring: flag binding into a typed `Options` struct,
  `Args` validators, `--help` text. No business logic.
- Each subcommand builds an `Options` and calls `internal/<pkg>.Run(opts)`.
- Mutating commands (`install`, `sync`, `update`) carry `--dry-run`. `link` is
  effectively idempotent symlink creation; it gets `--dry-run` too for uniformity.
- `RunE` returns errors; root sets `SilenceUsage`/`SilenceErrors` and prints the
  structured error once. Errors are `fmt.Errorf("...: %w", err)` chains; a small
  set of sentinel/typed errors (e.g. `ErrNotInRepo`) where callers branch.
- Persistent flags: `--verbose`. Per-command typed flags mirror the scripts.

## Behavior-parity specifics (the load-bearing details)

- **Skills are always copied, never symlinked** (Cursor/Claude don't index symlinked
  skill trees) even when `--symlinks`. Agents/commands/hooks symlink by default.
- **Relative symlink target** = `filepath.Rel(destDir, source)` (matches the bash
  python3 `os.path.relpath`).
- **Target paths**: cursor → `.agents/skills` + `.cursor/{agents,commands,hooks,memory}`;
  claude → `.claude/{skills,agents,commands,hooks,memory}`. Submodule always at
  `.cursor/rules/shared` (never `.claude/rules/` — context explosion).
- **Skill/agent filter** resolved from `config/skill-groups.yaml` (`defaults: all`,
  `exclude_from_defaults: scala`); line-based parse, no yq.
- **hooks.json**: discover `*.sh/*.py/*.js/*.cmd/session-start` excluding
  `*/ecc-hooks/*`; merge shared+repo (dedupe array items); filter PascalCase keys
  for cursor / camelCase for claude; for claude resolve `${CLAUDE_PLUGIN_ROOT}/hooks/`
  → `<hooksdir>/`, inject into `.claude/settings.json`, delete `hooks.json`.
- **claude isolation**: `permissions.deny` + `allow` seeded into `.claude/settings.json`.
- **gitignore**: managed block (`.agents/`, `*-workspace/`) + memory dir + ECC paths.
- **install**: detect repo root (walk up for `.git`); if run from the ai-coding-rules
  repo itself, call sync directly; else add/update submodule (SSH→HTTPS fallback);
  install/append post-merge hook. The hook now invokes `acr sync` (not `bash sync-rules.sh`)
  — a deliberate, documented deviation since the tool itself is being replaced.
- **update**: clone/pull obra/superpowers + anthropics/skills into cache dir; sync
  skills-dirs/files/dir-copy; `--dry-run`/`--diff`.

## Testing approach

1. **Unit tests** for pure logic: skillgroups resolver, hooksjson merge/filter,
   fsx rel-path + identical + gitignore edits, target-path resolution, arg parsing.
2. **Integration parity tests** (`-tags parity`): build a fixture repo, run the real
   `*.sh` (baseline) and `acr` (candidate) in two temp copies, then assert the
   resulting trees are identical — symlink targets, file contents, and JSON
   (semantically, via decode-compare). Cover `sync` (cursor/claude/both, copy/symlink,
   filters, dry-run) and `link`. These run **before** any `.sh` is deleted.
3. `go vet` + `gofmt` clean; never skip hooks/tests.

## Out of scope (deferred)

- Merging with `ccpm` install/context domain. `acr install`/`acr sync` overlap ccpm's
  "set up a repo's agent assets" domain, but this pilot stays standalone to prove the
  Go-CLI pattern cleanly. Wrapper-vs-reimplement decision for a downstream Go CLI is observed, not
  decided here.
- Publishing/release packaging beyond `go build` + a short README.

## Binary name

Primary suggestion **`acr`** (ai-coding-rules; short, unshadowed). Alt: `ruler` —
rejected as a default because an unrelated AI-rules tool already ships as `ruler`
(`npx @intellectronica/ruler`), so the name would collide/confuse.
