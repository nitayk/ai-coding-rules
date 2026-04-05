---
name: create-pr
description: Creates a pull request with the correct template, base branch, and title convention for the repository. Use whenever the user asks to open, create, submit, or file a pull request, even if they don't explicitly say "PR". Also use this when the user mentions opening a merge request, reviewing code changes, or getting their work reviewed on GitHub. Do NOT use when the user only needs ongoing PR monitoring, bot triage, or merge coordination—use `/pr-workflow` instead.
disable-model-invocation: true
---

# Create PR

Use this skill when the user wants to create a pull request for their changes.

## 1. Check for uncommitted changes

Run `git status` to check for uncommitted changes (staged, unstaged, or untracked files). If there are any uncommitted changes, **stop and inform the user** about what is uncommitted. Wait for the user's guidance on how to proceed (e.g. commit, stash, or continue anyway) before moving on.

## 2. Identify the repository

Determine the repository name and path using `git rev-parse --show-toplevel`. This gives you the root directory of the git repository. The repository name is the basename of this path.

## 3. Determine the base branch

- For **unity-ads-sdk** repositories (`unity-ads-sdk-android`, `unity-ads-sdk-ios`): use `release/next`.
- For all other repositories: use `main`.

## 4. Find the PR template

Search for a PR template in the following locations (in order of priority):

1. `pull_request_template.md` in the repo root
2. `pull-request-template.md` in the repo root
3. `.github/pull_request_template.md`

Read the first template found and use it as the structure for the PR body.

For **unity-ads-sdk** repositories, prefer the repo-root template; only use `Unity/SDK/pull_request_template.md` if the change is confined to that subtree.

**If no template is found**, use this default structure:
```
## What
[Description of the change]

## Why
[Rationale and context]

## Risks
[Any known risks or side effects]
```

## 5. Build the PR description

1. Read the template or use the default format (section 4).
2. Extract context from:
   - The current user's message and intent
   - Commit history (use `git log --oneline` to see recent commits on this branch)
   - Current branch name and recent work
3. Fill every section the template defines. For each section:
   - Use the commit messages to understand what was changed
   - Use the user's description of their work to understand why the change was made
   - Infer testing approach and risks from the nature of the changes
   - If the template has checkboxes (like "tested locally", "code reviewed"), leave them unchecked — the user can check them on GitHub
   - If a section seems empty (e.g., "JIRA link"), write "N/A" if it doesn't apply

## 6. Choose PR title

### Unity Ads SDK repositories

```
<type>(<scope>):<platform>: <subject>
```

| Part         | Values / rules |
|--------------|----------------|
| `<type>`     | `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf` |
| `<scope>`    | JIRA ticket number, e.g. `UASDK-5000` or `UASDK-NA` |
| `<platform>` | `Android`, `iOS`, `Web` |
| `<subject>`  | Short imperative description of the change |

### Other repositories

Use a short imperative title, e.g. `feat: add X` or `fix: Y`.

## 7. Ask about draft status

Before creating the PR, ask the user: "Should this be a draft PR (work in progress) or ready for review?" If the user doesn't specify or says it's ready, create a regular PR. If they say draft, add the `--draft` flag.

## 8. Open the PR

1. **Push the branch** if it has not been pushed yet:
   `git push -u origin HEAD`
2. **Create the PR** with `gh pr create`:

```
gh pr create --base <base-branch> --title "<title>" --body-file <path-to-filled-body>
```

- Add `--draft` if the user indicated this should be a draft PR.
- Use the base branch from section 3.

3. If `gh` is unavailable, provide the user with the PR details (title, body, base branch) so they can create the PR manually on GitHub.

## Notes

- Always derive the PR body from the correct template so the format matches the repo's expectations.
- Do not run commands to verify the PR was created on GitHub after `gh pr create` succeeds.
