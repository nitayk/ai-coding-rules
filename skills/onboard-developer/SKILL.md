---
name: onboard-developer
description: "Use when ramping up a NEW developer (human, not agent) on an existing codebase — produces a personalized day-1/week-1 checklist and picks 2-5 concrete 'good first issues' from the repo. Triggers on: onboard developer, /onboard, new hire ramp-up, first-week plan, good first issue picks. Defer to codebase-onboarding when the goal is generating the onboarding GUIDE / CLAUDE.md itself."
disable-model-invocation: true
last-reviewed: 2026-05-27
---
# Onboard New Developer

Produce a personalized ramp-up plan for a human joining the codebase: a sequenced checklist and 2-5 concrete first issues. The unique value is human-facing — accounts, access, pairing, first PR — not generating the architectural doc itself.

## When to Use

**APPLY WHEN:**
- A new human developer is joining and needs a day-1 / week-1 checklist
- You need to pick 2-5 "good first issues" from the actual backlog
- Tailoring an existing onboarding guide to a specific person / focus area

**DO NOT USE — defer instead:**
| Goal | Use this instead |
|------|------------------|
| Generate the onboarding GUIDE or starter `CLAUDE.md` | `codebase-onboarding` (auto-analyzes repo, emits structured guide) |
| Architecture deep-dive / system design questions | `/council` |
| Map service dependencies before a refactor | code search / your code-graph tool |
| Set up dev server / local environment | `setup-local-dev` |

If the user wants both a generated guide AND a personalized checklist, run `codebase-onboarding` first, then this skill consumes its output.

## Inputs to Gather

Before producing the checklist, ask (or infer):
1. **Role / focus area** — backend, frontend, data, SRE, full-stack
2. **Experience level** — senior with stack / senior new to stack / junior
3. **Existing onboarding doc?** — link or path; if missing, run `codebase-onboarding` first
4. **Team contacts** — buddy/mentor, EM, on-call rotation
5. **Access systems** — which need tickets (VPN, prod read, datastore, Slack channels)

## Process

1. **Confirm guide exists** — if no onboarding guide / `CLAUDE.md`, stop and recommend `codebase-onboarding` first. Don't duplicate that work.
2. **Build the checklist** — sequenced day-1 → week-1 → week-2+, grouped: Access, Environment, Reading, People, First PR.
3. **Pick first issues** — query the issue tracker (GitHub `gh issue list --label "good first issue"`, Jira via MCP) for 2-5 candidates that match the role/focus. For each, note: scope (LOC estimate), files touched, who can review, why it's a good starter.
4. **Identify pairing opportunities** — name the buddy and 1-2 concrete pairing sessions (e.g. "pair on first deploy", "shadow on-call rotation Wed").
5. **Define the first-PR target** — a specific, small, mergeable change with a named reviewer and rough timeline (typically end of week 1).

## Checklist Template

```markdown
## Week 0 (pre-start)
- [ ] Hardware + IDE access provisioned
- [ ] Accounts: GitHub org, Slack, Jira, SSO, VPN
- [ ] Buddy assigned: <name>

## Day 1
- [ ] Clone repo, run setup per <link to guide>
- [ ] Tour: 1:1 with buddy walking the architecture diagram
- [ ] Join channels: #<team>, #<oncall>, #<eng-help>

## Week 1
- [ ] Read: <CLAUDE.md / onboarding guide>, top 3 ADRs
- [ ] Run the test suite locally — green
- [ ] Shadow code review on 2 PRs
- [ ] Pick a first issue from the list below
- [ ] Open first PR (target: <Fri date>)

## Week 2+
- [ ] Carry pager (shadow first, then primary)
- [ ] Present learnings in team standup
- [ ] Update onboarding doc with anything that was wrong/missing
```

## First-Issue Selection Heuristics

A good first issue:
- **Scoped**: < 200 LOC, < 5 files
- **Clear acceptance criteria** already in the ticket
- **Not on the critical path** — failure to land doesn't block the team
- **Has a willing reviewer** named up-front
- **Teaches the workflow** — touches at least one core module + tests + CI

Avoid: open-ended research tickets, anything blocked on external teams, anything tagged `flaky` / `intermittent`.

## Output Format

Return:
1. The personalized checklist (markdown)
2. A table of 2-5 first issues: `id | title | files | reviewer | why good`
3. Named pairing sessions with proposed times
4. First-PR target with date

## Best Practices

- The new hire should update the onboarding guide as they go — make this an explicit checklist item.
- Don't regenerate the guide if one exists; tailor instead.
- Check first-issue candidates aren't stale (last comment > 90 days = likely landmine).
- If using Jira/GitHub MCP, prefer one query over multiple — surface the raw list, then filter.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
