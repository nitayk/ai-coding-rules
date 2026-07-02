# Create Pull Request

Create a pull request for the current changes.

## Usage

```
/pr [optional message]
```

## What it does

1. Analyzes staged and unstaged changes with `git diff`
2. Writes a clear commit message based on what changed
3. Commits and pushes to the current branch
4. Uses `gh pr create` to open a pull request with title/description
5. Returns the PR URL when done

## Prose finishing pass (stop-slop)

Before step 4, apply the bundled **stop-slop** prose rules to the
PR-description **narrative prose only** (the summary / "what & why"
paragraphs). Read the rules from the toolkit:

- `${CLAUDE_PLUGIN_ROOT}/assets/stop-slop/SKILL.md`

If that path doesn't resolve, skip this pass silently.

**Scope — apply ONLY to free-prose narrative. Do NOT apply to:** code or
fenced code blocks, the commit message, file/path lists, test output,
checklists, rollback commands, version-controlled docs under `docs/`,
plans, or specs. stop-slop's absolutes (remove all adverbs, no em-dashes,
no three-item lists) degrade technical precision, so this pass is scoped to
human-facing prose by design and never rewrites technical content.

## Example

```
/pr fixes authentication bug
```

This command requires the GitHub CLI (`gh`) to be installed and authenticated.

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
