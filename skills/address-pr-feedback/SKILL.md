---
name: address-pr-feedback
description: Address PR feedback and comments. Fetch comments from an open PR on the current branch, evaluate the suggested changes, make clear and reasonable modifications to the codebase, skip unclear or uncertain items, and ask the user for confirmation before committing. Use this skill whenever the user asks to address, handle, or respond to PR feedback or review comments.
---

# Address PR Feedback

This skill helps you systematically address feedback from a pull request review. It fetches comments from the open PR on your current branch, evaluates which changes make sense, applies those changes, and asks for your confirmation before committing.

## Requirements

- **GitHub CLI (`gh`)**: Installed and authenticated.
- **`jq`** (optional): Useful when feedback JSON is written to a file and you need counts or filtered views.

## Workflow

### 1. Fetch PR Comments

From the skill directory (or with `scripts/` on your path), run:

```bash
bash scripts/fetch_pr_comments.sh
```

The script resolves the current git branch and its open PR, then prints one JSON object to **stdout** with `basic_info`, `review_comments` (GraphQL payload: reviews with per-file line comments, diff hunks, authors, states), and PR-level discussion comments.

**Large output:** Payloads can be very large (many reviews, long diff hunks). **Redirect to a file** and work from that path instead of holding the whole blob in chat:

```bash
bash scripts/fetch_pr_comments.sh > pr-feedback.json
```

Use **`jq`** (or similar) to slice the file. Replace `pr-feedback.json` with whatever path you used.

**Review-thread shape** (under the combined JSON’s `review_comments` key — this mirrors the GraphQL `data.repository.pullRequest` tree):

```
.review_comments.data.repository.pullRequest.reviews.nodes[]
  └─ .author.login          (reviewer)
  └─ .comments.nodes[]     (line/file comments in that review)
      ├─ .path
      ├─ .body
      └─ .author.login      (often same as review author)
```

**Handy `jq` filters:**

1. Count review threads (top-level review nodes):

   ```bash
   jq '.review_comments.data.repository.pullRequest.reviews.nodes | length' pr-feedback.json
   ```

2. Comment counts per review author:

   ```bash
   jq '.review_comments.data.repository.pullRequest.reviews.nodes[] | {author: .author.login, comments: (.comments.nodes | length)}' pr-feedback.json
   ```

In GitHub, **`u-pr`** and **`copilot-pull-request-reviewer`** are **automated code review** accounts (bots), not human reviewers—prioritize and interpret them accordingly (examples 3–4 filter those logins).

3. All comments from a given reviewer login (example: `u-pr`):

   ```bash
   jq '.review_comments.data.repository.pullRequest.reviews.nodes[] | select(.author.login == "u-pr") | .comments.nodes[] | {author: .author.login, path: .path, body: .body}' pr-feedback.json
   ```

4. All comments from Copilot’s reviewer login:

   ```bash
   jq '.review_comments.data.repository.pullRequest.reviews.nodes[] | select(.author.login == "copilot-pull-request-reviewer") | .comments.nodes[] | {author: .author.login, path: .path, body: .body}' pr-feedback.json
   ```

If there is no open PR on the current branch, the script exits with an error. Tell the user and stop.

Parse the JSON (from the file or stdout) to identify:

- Code-specific feedback (review comments with paths and lines)
- General discussion (PR comments)
- Type and priority of each item

### 2. Parse and Categorize Comments

- **Action items**: Comments that clearly request a specific change (e.g. rename, add error handling, remove unused import)
- **Questions / unclear**: Ambiguous comments or those needing design decisions
- **Praise / non-actionable**: No code change required


## Key Principles

- **Skip uncertainty**: Prefer asking the user over guessing when a comment is ambiguous or needs a product/design call.
- **Match intent**: Changes should reflect what the reviewer asked, not a different “improvement.”
- **Confirm before commit**: Do not `git commit` (or push) without explicit user approval.
