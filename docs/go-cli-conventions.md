# Go CLI conventions (pilot notes for a downstream Go CLI)

This `acr` CLI was built as a pilot to prove a clean, transferable Go-CLI pattern
for future Go CLI efforts. These are the conventions worth
carrying over, the things to fix first, and what the pilot taught about
wrapper-vs-reimplement.

## Project layout

```
cli/
  go.mod                 self-contained module, isolated from the repo root
  main.go                thin: os.Exit-style entry → cmd.Execute()
  cmd/                    cobra wiring ONLY (flags, args, --help, error print)
    root.go  <verb>.go    one file per subcommand
  internal/
    ui/                   colored logger + run Stats
    fsx/                  pure filesystem primitives (symlink, copy, compare)
    <domain>json/         pure JSON transforms (here: hooksjson)
    <parser>/             pure config parsing (here: skillgroups)
    <engine>/             one package per subcommand's business logic
  parity/                 integration tests vs the thing being replaced
  testdata/
```

Keeping the module under `cli/` (not the repo root) keeps the Go toolchain out
of a repo that is mostly Markdown/config. For a downstream Go CLI, do the same if it lives in
a mixed repo.

## Cobra patterns

- **`cmd/` is wiring, not logic.** Each subcommand file builds a typed `Options`
  struct from flags and calls `internal/<engine>.Run(opts)`. No business logic in
  `cmd/`. This made the engines unit-testable without cobra.
- **Engines expose `Options` + `Run(Options) error`.** The struct *is* the public
  API; flags map 1:1 onto fields. Easy to call an engine from another engine
  (`installer` calls `syncer.Run` in-process — no shelling to itself).
- **Errors flow up; print once at the top.** `root.go` sets `SilenceUsage` and
  `SilenceErrors`, and `Execute()` prints the wrapped error chain once. Engines
  wrap with `fmt.Errorf("...: %w", err)`.
- **One persistent flag (`--verbose`).** Per-command flags are local to each
  `new<Verb>Cmd()`.
- **Parse-and-validate at the entry, once.** `syncer.ParseTargets` is the single
  authoritative `--target` parser, shared by the cobra layer and the installer.
  The first pilot draft duplicated this in three places with divergent behavior —
  don't. For a downstream Go CLI: one parser per flag, called at the boundary.

## Pure-core / imperative-shell split

The high-leverage decision was pushing all *policy-free* logic into pure packages
(`fsx`, `hooksjson`, `skillgroups`) that take values and return values/errors,
and keeping *policy* (dry-run, force, logging, skip-if-identical) in the engines.
This is why the unit tests are fast and the parity tests are small. Carry this to
a downstream Go CLI: filesystem and serialization primitives should not know about flags or
print anything.

## Logging

`ui.Logger` is a concrete struct with a `Stats` counter. **Recommended change
before a downstream Go CLI grows a second engine:** make engines depend on a small `Logger`
*interface* instead of the concrete type, so output can be captured/stubbed in
tests and the `Stats` surface is explicit. The pilot left it concrete to stay
close to the shell scripts' inline logging; it is the first thing to refactor.

## Testing approach

Two layers, both worth copying:

1. **Unit tests** for the pure packages — table-driven, on-disk temp fixtures for
   filesystem behavior. Fast, hermetic.
2. **Parity tests** (`parity/`) that run the *real* artifact being replaced (here,
   the bash scripts) and the new binary against identical fixtures, then diff the
   **effects** — not stdout. Key techniques:
   - Compare *effects*, not logs: symlink targets resolved via `EvalSymlinks`,
     files byte-for-byte, JSON decoded-and-compared (avoids jq-vs-Go formatting),
     `.gitignore` compared on functional (non-comment) lines.
   - For repo-relative symlinks, compare the target resolved **relative to each
     repo root** (two temp repos at different paths otherwise never match; macOS
     `/var`↔`/private/var` also bites here).
   - `TestMain` builds the binary once; `requireTools` skips when
     `bash/jq/python3/git` or the baseline are absent.

For a downstream Go CLI, if it wraps or replaces an existing tool, write the effect-diff
parity harness *first* — it caught every behavioral mismatch here and gave the
confidence to delete 2200 lines of shell.

## Packaging

`go build -o acr ./cli` → one static binary, no runtime deps beyond `git`.
Dropping the `jq`/`python3` dependencies (native `encoding/json` + `filepath.Rel`)
is a real operational win over the scripts. For distribution, a `GOOS/GOARCH`
matrix build is the obvious next step (not done in the pilot).

## Security notes carried from review

- Never interpolate user-controlled values into generated shell scripts. The
  post-merge hook embeds `--skills`/`--target`; these are now validated against a
  strict character allowlist at the entry (`installer.filterPattern`) before they
  can reach the hook. Empirically tested (backtick/`$()`/`;`/quote payloads all
  rejected).
- `CopyDir` refuses symlinks whose target escapes the source tree (absolute or
  `../`-escaping), so copied upstream content can't smuggle a pointer to e.g.
  `~/.ssh`.
- Caches go under `os.UserCacheDir()`, not a predictable `/tmp` path.

## Wrapper vs reimplement — pilot observation (decision deferred)

The task deferred the wrapper-vs-reimplement call for a downstream Go CLI. What this pilot
suggests: **reimplementing** these scripts in Go was clearly right *because the
logic was non-trivial but self-contained* (string/JSON/path manipulation), and
the reimplementation shed the `jq`/`python3` deps and added type safety and
tests. A thin wrapper around the bash would have preserved the deps and the
untestability. The signal for "reimplement": the original's complexity lives in
*data transformation* you can port and test, not in orchestrating external tools
you don't control. Where the work is mostly orchestrating an external binary
(e.g. `git` here), `acr` *wraps* (`os/exec`) rather than reimplements — so the
real answer is per-concern, not per-tool. Apply that lens to a downstream Go CLI.
