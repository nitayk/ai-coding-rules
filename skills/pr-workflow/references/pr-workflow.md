# PR Workflow — Reference

Demoted detail for `pr-workflow` SKILL. Load on demand when SKILL.md points here.

## `mergeable` vs `mergeable_state`

These are **different** fields on the GitHub PR API and are routinely confused:

| Field | Meaning | Safe to merge? |
|-------|---------|----------------|
| `mergeable: true` | No git conflicts with base branch | No — checks may still be running or failing |
| `mergeable_state: "clean"` | All required checks passed, no conflicts, ready | Yes |
| `mergeable_state: "dirty"` | Merge conflicts | No |
| `mergeable_state: "unstable"` | Non-required checks failing | Maybe (project policy) |
| `mergeable_state: "blocked"` | Required reviews/checks missing | No |
| `mergeable_state: "behind"` | Branch behind base | Update branch first |

**Rule:** Only merge when `mergeable_state == "clean"`.

```bash
gh pr view <pr-number> --json mergeableState -q .mergeableState
```

## Monitoring loop (autonomous mode)

Poll every 30–60s until `mergeable_state: "clean"`:

```bash
# 1. State
gh pr view <pr> --json mergeableState,statusCheckRollup,comments

# 2. Bot comments
gh pr view <pr> --json comments \
  -q '.comments[] | select(.author.type == "Bot")'

# 3. CI status
gh pr checks <pr>

# 4. Rerun flaky
gh pr checks <pr> --rerun-failed
```

## Bot feedback handling

| Bot signal | Typical cause | Action |
|------------|---------------|--------|
| Coverage below threshold | Untested new code | Add tests, push |
| Lint errors | Style violations | Run formatter, push |
| Security vuln (Dependabot/Snyk) | CVE in dep | Bump dep or suppress with justification |
| Missing changelog | Release-please / similar | Add changelog entry |
| Doc build fails | Broken link / syntax | Fix referenced docs |
| Required check pending too long | CI runner backed up | Wait, do not rerun blindly |

**Rule:** address every bot comment — they're nearly always right. If a bot is wrong, post a reply explaining why before dismissing.

## Pre-PR checks (multi-stack)

### Type check / compile
```bash
sbt compile          # Scala
npm run typecheck    # TS
mypy .               # Python
go build ./...       # Go
```

### Lint / format
```bash
sbt scalafmtCheck    # Scala
npm run lint         # TS
ruff check .         # Python
golangci-lint run    # Go
```

### Tests
```bash
sbt test
npm test
pytest
go test ./...
```

### Secrets scan
```bash
git secrets --scan
# or trufflehog / gitguardian / npm audit / safety check
```

## PR description template

```markdown
## What
<one-line summary>

## Why
<motivation, ticket link>

## How
<implementation notes>

## Testing
<how verified>

## Checklist
- [ ] Code compiles
- [ ] Tests pass
- [ ] No security issues
- [ ] Docs updated

Closes #<issue>
```

PR template lookup order: `.github/pull_request_template.md` → `docs/pull_request_template.md` → `PULL_REQUEST_TEMPLATE.md`.

## Merge strategies

| Strategy | When |
|----------|------|
| `--squash` | Default for feature branches; clean history |
| `--merge` | Preserve commit history (long-lived branches) |
| `--rebase` | Linear history, if repo policy allows |

```bash
gh pr merge <pr> --squash --delete-branch
```

## Common pitfalls

- **Merging on `mergeable: true` alone** — checks may still be running. Use `mergeable_state: "clean"`.
- **Ignoring bot comments** — they encode org policy; address or justify.
- **Not polling** — PRs stall waiting for human attention.
- **Skipping local pre-PR checks** — CI will catch it slower and more expensively.
- **Auto-rerunning failed checks** — only rerun if you've confirmed flakiness; otherwise fix.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
