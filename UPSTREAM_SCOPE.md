# Upstream comparison (nitayk scope)

This file compares **[nitayk/ai-coding-rules](https://github.com/nitayk/ai-coding-rules)** to:

| Upstream | Role |
|----------|------|
| [ironsource-mobile/mobile-cursor-rules](https://github.com/ironsource-mobile/mobile-cursor-rules) | Large shared rules pack + **~70+ skills** (IADS / org-oriented investigation tooling). |
| [Unity-Technologies/ai-agent-skills](https://github.com/Unity-Technologies/ai-agent-skills) | **Unity Ads**–centric skills + marketplace plugins; many skills **migrated from** the IronSource-era pack per their `SOURCES.md`. |

**This pack is not a byte-for-byte superset of both.** It intentionally keeps **community + generic workflows** and **drops org-internal** stacks (Atlas, Memgraph MCP, internal Grafana/Consul/Trino, Unity Ads BigQuery/K2, etc.).

---

## What you already align with (all three)

These come from the **same community roots** (obra/superpowers, anthropics/skills) or equivalents:

- Core workflows: brainstorming, TDD/systematic-debugging, verification-before-completion, executing-plans, writing-plans, dispatching-parallel-agents, git worktrees, finishing-a-branch, receiving/requesting-code-review, using-superpowers, subagent-driven-development, writing-skills.
- Document skills: docx, pdf, pptx, xlsx, frontend-design, mcp-builder, skill-creator, web-artifacts-builder, webapp-testing.
- **Unity’s README** explicitly lists skills **migrated from** `mobile-cursor-rules` (code-cleanup, multi-agent-branching, session-memory, prd-generation, task-breakdown, etc.) — your pack already carries the **generic** side of those patterns where they overlap.

So for **“good stuff without org glue”**, you are **largely covered** on shared community content.

---

## mobile-cursor-rules: what you are **not** shipping (on purpose)

**Org / internal investigation (exclude for personal):**

- `atlas-analysis`, `memgraph-analysis`, `code-graph-architect`, `code-structure-analysis`, `full-network-analysis`, `victoria-traces-analysis`
- `argocd-deployment`, `grafana-monitoring`, `trino-validation`
- `read-consul-keys`, `slack-history`
- `service-breakdown`, `service-migration`, `service-refactoring` (heavy Memgraph/Trino assumptions)
- `ecc-harness-playbook` (Longform/org harness; optional if you want personal ECC later)

**Nice-to-have generic skills present in mcr but not necessarily in nitayk today** (candidates to **copy in** from mcr if you want parity on “generic” only):

- `agent-browser`, `council`, `create-pr`, `fix-issue`, `generate-changelog`, `generate-docs`, `test-until-pass`, `security-audit`, `code-review-excellence`, `deep-research`, `prompt-optimizer`, `repository-organization`, `search-first`, `continuous-learning-v2`, `gdoc`, Scala-focused `scala-*` skills — **only if** you still use those stacks personally.

**Rules layout:** mcr uses `rules/{go,scala,typescript,...}`; nitayk uses `backend/`, `frontend/`, `generic/`, `tools/`, etc. Same **idea** (ROUTER → indexes → `.mdc` files), different directory naming — not a functional gap for a personal repo.

---

## Unity ai-agent-skills: what to **ignore** for personal

Unity’s repo is **optimized for Unity Ads** (see their README: BigQuery, DSP anomalies, K2/ArgoCD, internal Grafana, Aerospike, IAB TCF, unity-ads-sdk tests).

**Exclude for personal (work / product-specific):**

- `skills/ads/*` (bigquery, dsp, grafana-monitoring, service-investigator, iab-tcf, run-android/ios tests tied to their SDK)
- `skills/infra/k2-deployment`, `skills/infra/aerospike` (Unity infra context)
- Plugin groups like `unity-ads-platform`, `unity-ads-infra` in their marketplace

**Keep taking from Unity only via shared upstreams** (same as nitayk): anthropics + superpowers vendor paths under `skills/vendor/*` — you already consume those families through **ai-coding-rules** / `update-community.sh`.

---

## Claude `settings.json` vs “reading rules”

If `.claude/settings.json` **denies** `Read` on `./.claude/rules/shared/tools/**`, the **CLI `.mdc` guides** (curl, jq, git, …) are blocked even though `ROUTER.mdc` routes to them. Consider removing or narrowing those denies so tool guides remain readable.

---

## Summary

| Question | Answer |
|----------|--------|
| Same repo as ironsource-mobile? | **No** — smaller skill set, no org investigation stack. |
| Same as Unity ai-agent-skills? | **No** — Unity is mostly Ads/infra; your overlap is **community** skills. |
| “All the good stuff” without work? | **Community + generic workflows: yes.** **Org tooling: intentionally no.** |
| To add more generic skills | Pull selected folders from **mcr** `skills/` into **nitayk/ai-coding-rules** (or submodule path), **not** from Unity `ads/` / `infra/`. |

Last compared: 2026-04-05 (against `main` on both upstreams via shallow clone).
