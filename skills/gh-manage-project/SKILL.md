---
name: gh-manage-project
description: "Manage GitHub Projects V2 boards: create issues, add them to a project board, assign sprints, set status/dates/fields, and query board items. Use when the user asks to create sprint tasks, add issues to a project board, assign work to a sprint, update project board items, check sprint status, or manage a GitHub project. Also use when the user mentions 'project board', 'sprint planning', 'iteration', 'kanban', or provides a GitHub project URL. Do NOT use for basic issue creation without a project board — use gh issue create directly for that."
---

# Manage GitHub Projects V2

Create issues, add them to GitHub Projects V2 boards, assign sprints, and manage board fields using the GraphQL API.

## When to Use This Skill

**APPLY WHEN:**
- User wants to create tasks and add them to a GitHub project board
- User wants to assign issues to a sprint/iteration
- User wants to update status, dates, or other fields on project board items
- User provides a GitHub project URL (e.g. `https://github.com/orgs/ORG/projects/NUMBER/...`)
- User mentions sprint planning, kanban boards, or project board management

**SKIP WHEN:**
- User wants to create a standalone issue without a project board (use `gh issue create`)
- User wants to create a PR (use `/create-pr`)
- User wants to search for issues (use `/gh-search`)

## Requirements

- **GitHub CLI (`gh`)**: Installed and authenticated
- **Project scopes**: The token needs `read:project` and `project` scopes

If you get `INSUFFICIENT_SCOPES` errors mentioning `read:project`, ask the user to run:

```bash
gh auth refresh -s read:project,project
```

Then retry the operation.

## Process

### 1. Identify the Project

Extract the org name and project number from the project URL:

```
https://github.com/orgs/ORG/projects/NUMBER/views/...
```

If the user doesn't provide a URL, ask which org and project number to use.

### 2. Discover Project Metadata

Run this query to get the project ID, all field IDs, option values, and current sprint iterations. **Save these IDs in your context and reuse them for all subsequent mutations in this conversation** — do not re-query.

```bash
gh api graphql -f query='
query {
  organization(login: "ORG") {
    projectV2(number: NUMBER) {
      id
      title
      fields(first: 30) {
        nodes {
          ... on ProjectV2Field {
            id
            name
            dataType
          }
          ... on ProjectV2SingleSelectField {
            id
            name
            dataType
            options { id name }
          }
          ... on ProjectV2IterationField {
            id
            name
            dataType
            configuration {
              iterations { id title startDate duration }
            }
          }
        }
      }
    }
  }
}'
```

From the response, extract and save in your context:
- `projectV2.id` — the project's node ID (starts with `PVT_`)
- Field IDs for Status, Sprint/Iteration, Start Date, Release Date, Priority, etc.
- Option IDs for each single-select field (e.g., Status options: Todo, In Progress, Done)
- Current iteration/sprint IDs and their date ranges

Present the project title and available sprints to the user for confirmation before proceeding.

### 3. Determine Target Repository

Issues must live in a repository — GitHub Projects V2 **draft items cannot have assignees**. Always create proper issues.

If the user doesn't specify a repo, check what repos existing items on the board use:

```bash
gh api graphql -f query='
query {
  organization(login: "ORG") {
    projectV2(number: NUMBER) {
      items(first: 5, orderBy: {field: POSITION, direction: DESC}) {
        nodes {
          content {
            ... on Issue {
              title
              repository { nameWithOwner }
            }
          }
        }
      }
    }
  }
}'
```

Suggest the most common repo to the user, or ask them to choose.

### 4. Create Issues

Create issues in the target repo. Run multiple `gh issue create` commands **in parallel** if creating several independent issues.

```bash
gh issue create --repo ORG/REPO \
  --title "Issue title" \
  --body "Description" \
  --assignee USERNAME
```

To find the current user's GitHub username:
```bash
gh api user --jq '.login'
```

### 5. Add Issues to the Project Board

First, get node IDs for all created issues in a single query:

```bash
gh api graphql -f query='
query {
  issue1: repository(owner: "ORG", name: "REPO") {
    issue(number: N1) { id }
  }
  issue2: repository(owner: "ORG", name: "REPO") {
    issue(number: N2) { id }
  }
}'
```

Then add all issues to the project in one mutation:

```bash
gh api graphql -f query='
mutation {
  add1: addProjectV2ItemById(input: {
    projectId: "PROJECT_ID"
    contentId: "ISSUE1_NODE_ID"
  }) { item { id } }
  add2: addProjectV2ItemById(input: {
    projectId: "PROJECT_ID"
    contentId: "ISSUE2_NODE_ID"
  }) { item { id } }
}'
```

### 6. Set Fields on Board Items

Batch all field updates into a single mutation using aliases. Each item × field combination gets its own alias.

```bash
gh api graphql -f query='
mutation {
  i1sprint: updateProjectV2ItemFieldValue(input: {
    projectId: "PROJECT_ID"
    itemId: "ITEM1_ID"
    fieldId: "SPRINT_FIELD_ID"
    value: { iterationId: "ITERATION_ID" }
  }) { projectV2Item { id } }
  i1status: updateProjectV2ItemFieldValue(input: {
    projectId: "PROJECT_ID"
    itemId: "ITEM1_ID"
    fieldId: "STATUS_FIELD_ID"
    value: { singleSelectOptionId: "TODO_OPTION_ID" }
  }) { projectV2Item { id } }
  i1start: updateProjectV2ItemFieldValue(input: {
    projectId: "PROJECT_ID"
    itemId: "ITEM1_ID"
    fieldId: "START_DATE_FIELD_ID"
    value: { date: "2026-04-06" }
  }) { projectV2Item { id } }
  i1end: updateProjectV2ItemFieldValue(input: {
    projectId: "PROJECT_ID"
    itemId: "ITEM1_ID"
    fieldId: "RELEASE_DATE_FIELD_ID"
    value: { date: "2026-04-10" }
  }) { projectV2Item { id } }
}'
```

### Field Value Types

| Field Type | Value format |
|---|---|
| Single select (Status, Priority) | `{ singleSelectOptionId: "OPTION_ID" }` |
| Iteration (Sprint) | `{ iterationId: "ITERATION_ID" }` |
| Date | `{ date: "YYYY-MM-DD" }` |
| Text | `{ text: "value" }` |
| Number | `{ number: 5 }` |

## Querying Board Items

### List items in a sprint

This query fetches all board items. **Filter the results client-side** by matching each item's iteration `title` field to the target sprint name — the Projects V2 API does not support server-side iteration filtering.

```bash
gh api graphql -f query='
query {
  organization(login: "ORG") {
    projectV2(number: NUMBER) {
      items(first: 50) {
        nodes {
          fieldValues(first: 15) {
            nodes {
              ... on ProjectV2ItemFieldIterationValue {
                title
                field { ... on ProjectV2IterationField { name } }
              }
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
              ... on ProjectV2ItemFieldDateValue {
                date
                field { ... on ProjectV2Field { name } }
              }
            }
          }
          content {
            ... on Issue {
              title
              number
              assignees(first: 5) { nodes { login } }
              repository { nameWithOwner }
            }
          }
        }
      }
    }
  }
}'
```

### Delete an item from the board

```bash
gh api graphql -f query='
mutation {
  deleteProjectV2Item(input: {
    projectId: "PROJECT_ID"
    itemId: "ITEM_ID"
  }) { deletedItemId }
}'
```

## Gotchas

- **Draft items cannot have assignees.** Always create issues in a repo first, then add to the project. Never use `addProjectV2DraftIssue` if the user needs assignees.
- **Sprint/iteration IDs rotate.** Always query current iterations from the project metadata — never hardcode them.
- **Field IDs are project-specific.** Different projects have different field IDs even if the field names are the same. Always discover them per project.
- **Batch mutations aggressively.** Use GraphQL aliases to combine multiple operations into one request. This avoids rate limits and is faster.
- **The Assignees field cannot be set via `updateProjectV2ItemFieldValue`.** Assignees are set on the issue itself (via `--assignee` on `gh issue create` or `gh issue edit`), not on the project board item.
- **`gh project` CLI exists but is limited.** The GraphQL API is more reliable for field updates and iteration assignment.

## Related Skills

- `/gh-search` — Search for code, issues, PRs across GitHub
- `/create-pr` — Create a pull request
- `/fix-issue` — Fix a GitHub issue
