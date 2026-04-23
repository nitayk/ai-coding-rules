---
name: gh-search
description: "Search for code, repositories, issues, PRs, commits, and users across GitHub using the gh CLI. Use when the user asks to find code, search GitHub, look up a repository, find issues or PRs, search commits by author, or locate files across the organization. Also use when the user says 'search GitHub for', 'find code that', 'who contributed to', or 'what repos have'. Do NOT use for local file search or grep — this is for GitHub's remote search API only."
---

# Search GitHub Code & Resources

Search for code, repositories, issues, PRs, commits, and users across GitHub using the `gh` CLI.

## When to Use This Skill

**APPLY WHEN:**
- User wants to find code across GitHub repositories
- User wants to search for issues, PRs, or commits
- User wants to find repositories by name, topic, or description
- User wants to look up a contributor's work or find team members
- User asks "who worked on X", "find repos that have Y", "search for Z in GitHub"

**SKIP WHEN:**
- User wants to search local files (use grep, ripgrep, or Glob instead)
- User wants to read a specific file they already know the path for (use `gh api` or Read)
- User wants to create or modify issues/PRs (use `/fix-issue` or `/create-pr`)
- User wants to add issues to a project board or manage sprints (use `/gh-manage-project`)

## Requirements

- **GitHub CLI (`gh`)**: Installed and authenticated
- Sufficient token scopes for the search type (code search needs `repo` scope)

## Rate Limits

GitHub enforces a **secondary rate limit of ~30 requests per minute**. If you get HTTP 403 with "You have exceeded a secondary rate limit":

1. Keep searches to **3-4 per batch**, then pause or consolidate
2. Use specific queries with filters to reduce the number of calls
3. Wait 60 seconds before retrying if rate limited

## Search Types

### Code Search

Find specific code patterns, function definitions, or configuration across repositories.

```bash
gh search code "QUERY" --owner ORG --limit 10
```

**Useful qualifiers** (add directly to the query string):
- `language:java` — filter by programming language
- `path:src/main` — filter by file path
- `filename:config.yaml` — filter by filename
- `extension:py` — filter by file extension
- `repo:ORG/REPO` — scope to a single repo

**Examples:**
```bash
# Find all uses of a function
gh search code "RowLevelComplianceProcessor" --owner Unity-Technologies --limit 10

# Find YAML configs with a specific key
gh search code "enableGreatExpectationsDataQualityChecks" --owner Unity-Technologies --limit 10

# Find Java files implementing an interface
gh search code "implements FluentMetrics language:java" --owner Unity-Technologies --limit 10
```

### Repository Search

Find repositories by name, description, README content, or topics.

```bash
gh search repos "QUERY" --owner ORG --limit 10
```

**Useful qualifiers:**
- `topic:TOPIC` — filter by repo topic
- `language:LANG` — primary language
- `stars:>N` — minimum stars
- `archived:false` — exclude archived repos

**Examples:**
```bash
# Find repos related to a project
gh search repos "flair" --owner Unity-Technologies --limit 10

# Find repos by topic
gh search repos "topic:data-platform" --owner Unity-Technologies --limit 10
```

### Issue Search

```bash
gh search issues "QUERY" --owner ORG --limit 10
```

**Useful qualifiers:**
- `state:open` or `state:closed`
- `label:LABEL`
- `author:USER`
- `assignee:USER`
- `is:issue` (excludes PRs from results)

### PR Search

```bash
gh search prs "QUERY" --owner ORG --limit 10
```

**Useful qualifiers:**
- `state:open`, `state:closed`, `state:merged`
- `author:USER`
- `review:approved`, `review:changes_requested`
- `draft:true` or `draft:false`

### Commit Search

Find commits by author, message, or date range.

```bash
gh search commits --author USERNAME --owner ORG --limit 10
gh search commits --author USERNAME --repo ORG/REPO --limit 10
```

**Tips:**
- When searching for a repo by contributor, search commits by author first — the repo name appears in the results.
- Use `--repo` to narrow to a specific repository.

### User Search

```bash
gh search users "QUERY" --limit 10
```

## Viewing Results

After finding what you need, use these to get details:

```bash
# Repo details
gh repo view ORG/REPO

# Issue or PR details
gh issue view NUMBER --repo ORG/REPO
gh pr view NUMBER --repo ORG/REPO

# File contents via API (files under 1MB only; larger files need the Git blob API)
gh api repos/ORG/REPO/contents/PATH --jq '.content' | base64 -d

# List directory contents
gh api repos/ORG/REPO/contents/PATH --jq '.[].name'
```

## Local Checkout Threshold

If you have made **10 or more** GitHub API calls targeting the **same repository** during a session, **clone the repo locally** instead:

```bash
gh repo clone ORG/REPO ~/repos/REPO
```

Then switch to local tools (Read, Grep, Glob) for all subsequent file reads and code searches. Continue using the GitHub API only for operations that require it (creating/updating PRs, issues, reviews).

## Gotchas

- **Code search results are snippets, not full files.** After finding a match, use `gh api repos/ORG/REPO/contents/PATH` to read the full file, or clone the repo if you need to explore further.
- **Code search indexes the default branch only.** To search other branches, clone the repo and search locally.
- **`--owner` scopes to an org/user.** Always use it to avoid searching all of GitHub.
- **Sort and order are separate flags.** Do not put `sort:` in the query string — use `--sort` and `--order` flags instead.
- **`--limit` caps results.** Always use it to avoid pulling excessive data.

## Related Skills

- `/fix-issue` — Fetch a GitHub issue and implement a fix
- `/create-pr` — Create a pull request for your changes
- `/gh-manage-project` — Manage GitHub Projects V2 boards and sprints
