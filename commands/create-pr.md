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

## Example

```
/pr fixes authentication bug
```

This command requires the GitHub CLI (`gh`) to be installed and authenticated.
