# Repository organization — fine detail

Load this when the task is large, ambiguous, or cross-team. The main `SKILL.md` stays the spine; this file is the appendix.

**Assessment-only:** Same questions and verification ideas apply, but deliver a **rubric** (e.g. axis clarity, duplication, consumer coupling, submodule/generated-tree risks) and **prioritized fixes**—no file moves unless the user switches to execution mode.

## Questions to answer before any `git mv`

Answer explicitly (in chat or a short `ORG_NOTES.md` the user can delete after). If unknown, **ask once**—do not guess on destructive actions.

| # | Question | Why it matters |
|---|----------|----------------|
| 1 | What is **in scope** (one path) vs **out of scope**? | Prevents scope creep into unrelated packages. |
| 2 | **Consumers**: humans only, CI, other repos, Docker `COPY`, package `files:` in npm/poetry? | Each needs reference updates. |
| 3 | **Delete vs archive vs leave** for deprecated items? | Legal/compliance may require retention. |
| 4 | **Submodule or nested git** under the tree? | `git mv` rules differ; submodules are not ordinary folders. |
| 5 | **Generated dirs** (`dist/`, `target/`, `.venv/`)—already ignored? | Do not "organize" generated trees into source layout. |
| 6 | **Binary assets** (PDF, xlsx, large CSV)—belong in repo or LFS / external store? | Moving may bloat history. |
| 7 | **Single branch** or must **backport** structure to release branches? | Affects commit plan. |
| 8 | **Breaking change** acceptable for external links (wiki, Slack, bookmarks)? | Add redirects or stub READMEs at old paths. |
| 9 | **Concept ownership** — For each major feature/domain, is there exactly **one** canonical place for tests, docs, and helper scripts? | If not, the reorg should *reduce* scatter, not freeze it. |
| 10 | **Parallel mechanisms** — Two ways to validate, deploy, or document the same thing? | Plan to keep **one**; the other becomes thin wrapper or removal candidate. |

## Concept map and single source of truth

Reorganization is not only “fewer files at root.” It is aligning **mental model ↔ tree**. Before large moves:

1. **List concepts** (product areas, layers, or test themes relevant to *this* repo—not a generic taxonomy).
2. For each concept, note **every path** that currently touches it (tests, docs, scripts, CI).
3. Decide **canonical home** per concept: one directory family (or one doc + one test subtree) that is the *authoritative* place for that concern.
4. **Testing:** Automated coverage for the same component or behavior should live **together** (same package tree, same naming prefix, or same parent folder policy the repo already uses). Manual or scratch checks belong in a **single** labeled bucket (`tests/manual/`, `scripts/qa/`, etc.)—not randomly mixed with pytest files *unless* the repo explicitly documents that pattern.
5. **Exceptions** — If two locations must remain (e.g. fast unit tests vs slow e2e), document **why** in the nearest README so the split is intentional, not drift.

This map can be a short bullet list in chat or a temporary note the user deletes after the PR.

## Source tree vs scripts and docs

New contributors often **read folder names first** to build a mental model. That works best when the model matches what the folder *is for*.

| Tree | Role | What “good names” signal |
|------|------|---------------------------|
| **Source / package tree** (`src/`, `lib/`, `packages/`, language-specific layout) | The **product**: what runs, how it is packaged, import boundaries | Subsystems, layers, deployable units—aligned with **code** structure and build tools |
| **Scripts** (`scripts/`, `tools/`, `bin/`) | **Automation and one-off operations**: CI parity, local dev, batch jobs, smoke tests | **Kind of work** (dev / graph / ops / qa), not necessarily a mirror of every package name |
| **Docs & plans** (`docs/`, `plans/`, runbooks) | **Narrative knowledge**: design intent, procedures, completed work, policies | Topic, audience, or **lifecycle** (active vs archive)—often **not** “one folder per module” |

**Why it feels different:** In the code tree, folders usually follow **dependencies and cohesion**. In `scripts/` and `docs/`, material is often **orthogonal** to a single module—e.g. one script touches many packages, or one doc describes a pipeline across services. That is not failed organization; it is a **different axis**. Problems start when auxiliary trees look like junk drawers (`misc/`, duplicate how-tos) or when naming **pretends** to be the package tree but is not (confusing newcomers).

**Practical takeaway:** When reorganizing, choose **one primary axis per level** *within each tree* (see main skill). Explicit **README index** at `scripts/` and `docs/` roots: “if you want X, look under Y”—so the first scan of top-level names still helps, even though those trees are not “the code project” in the same sense.

## Unifying duplicate mechanisms

“Duplication” includes **behavior**, not only file copies.

| Situation | Unification direction |
|-----------|------------------------|
| Two scripts both “validate the graph” | One implementation; second is `deprecated` wrapper calling the first or removed after CI updates. |
| Two README sections describe the same install path | Merge into one section; link from the other location if the path must stay for discovery. |
| Two env/bootstrap patterns (`parent.parent` vs walk to root) | Standardize on **one** helper (e.g. `_repo_root.py` / `load_env.sh`) per repo. |
| Two test styles for the same module (ad-hoc script + pytest) | Prefer **pytest** for repeatable checks; move ad-hoc to `manual_*` or fold into fixtures—do not leave two “official” ways without naming which is canonical. |
| Same doc in `docs/` and duplicated in Slack/wiki | Repo doc is canonical; external copy gets a line “source of truth: …” or is replaced by a link. |

**Rule of thumb:** After unification, a new contributor should need **one** obvious entry point per task (“run tests for X”, “validate Y”, “read how Z works”).

## Questions that often arise mid-process

| Situation | What to decide |
|-----------|----------------|
| Two files **similar but not identical** | Prefer **merge** with a short "Merged from X on DATE" section, or **keep both** with clearer names—never silent delete. |
| **Name collision** after move | Rename with domain prefix (e.g. `graph_validate.sh` vs `mcp_validate.sh`). |
| **Script invoked by relative path** in docs | Update doc and consider a **stable alias** (wrapper script at old path) for one release cycle. |
| **IDE / workspace** paths (`.vscode`, `.idea`) | Grep for old paths; update or document "regenerate config". |
| **Makefile / CI** uses `scripts/foo.sh` | Update every reference in same PR or a chained commit. |
| **Package entry points** (`pyproject.toml` `scripts`, `package.json` `bin`) | Registry must point to new paths. |
| **Symlinks** | Preserve symlinks vs copy targets—breaking symlinks breaks tools. |
| **Permissions** (`chmod +x`) | Re-apply after moves if `git` loses executable bit. |

## Signals to **stop and ask** (do not auto-resolve)

- Deletes that remove **only copy** of something with no backup.
- Moves that **touch secrets** (`.env`, keys, credentials paths).
- **Legal/PII** in filenames or paths (exports, HR, customer data).
- **Vendor/third_party** subtrees—often forked; reorganize only with explicit OK.
- **Mixed product lines** in one folder—use repo routing rules before blending.

## Anti-patterns (negative patterns)

| Bad | Good |
|-----|------|
| One giant commit with 200 moves | Small commits: by theme (`chore(scripts): move graph validators`) or by subdirectory. |
| Flatten everything into `docs/` | One axis per level; use `active/`, `archive/`, or domain slices. |
| README in every folder with duplicated prose | Index at **entry points** only; subfolders get a **one-line** purpose when needed. |
| Assuming `parent.parent` from script location | **Walk to repo root** or shared helper (see `SKILL.md`). |
| Merging duplicate **code** without running tests | Merge docs freely with care; code merges need tests. |
| Same concept tested or documented in **unrelated** folders with no README explaining the split | One canonical subtree per concept, or a documented **intentional** split (e.g. unit vs e2e). |
| Leaving two **equivalent** entry points (“use either script”) | Pick one; deprecate the other so automation and humans have a single answer. |

## Verification after moves (checklist)

- [ ] `rg` (or `git grep`) for **old path strings** across repo — zero unexpected hits.
- [ ] **Syntax**: `python -m py_compile` / `bash -n` on edited scripts.
- [ ] **Tests / CI** relevant to touched paths (or user confirms N/A).
- [ ] **README** at reorganized root lists **new** paths for "how to run".
- [ ] **`git status`** — no stray untracked junk; `.gitignore` updated if needed.

## Commit message convention (suggested)

- `chore(docs): reorganize plans into active/completed`
- `chore(scripts): group validation scripts under scripts/graph`
- `docs: add README index for scripts/`

## When to stop reorganizing

If the **next** move would split "things that change together" across distant folders, or the **cost** of churn (links, PRs, training) exceeds **clarity gained**, pause and propose a **smaller** incremental step instead of a perfect taxonomy.

## Skill-creator eval workspace (maintainers)

Benchmarks and `generate_review.py` output for this skill live in a **sibling directory** to the skill folder (skill-creator convention):

`skills/repository-organization-workspace/` (e.g. `iteration-1/`, `benchmark.json`, `review.html`).

That path is **gitignored** by `skills/*-workspace/` in the repo root `.gitignore`—regenerable local artifacts only. Agents and humans should use this location when running the skill-creator eval loop for **repository-organization**, not a random folder under `manage/`.
