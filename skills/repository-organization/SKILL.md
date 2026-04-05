---
name: repository-organization
description: >
  Restructure messy folders into clear subfolders, README indexes, and a single source of truth.
  Use whenever the user asks to organize, clean up, consolidate, deduplicate, deprecate, archive,
  or "find a home for" files; when flat scripts/ or docs/ is unnavigable; when they need path-safe
  moves, CI/doc updates, or hygiene for untracked and generated files. Use when they ask what to
  commit vs gitignore, how to merge duplicate docs, or how to avoid breaking imports after moves.
  Also use when they want one canonical place per concept (e.g. all tests for area X together),
  or to replace two equivalent mechanisms (scripts, bootstrap helpers, duplicate how-tos) with a
  single approach. Triggers: "organize this folder", "repo cleanup", "scripts everywhere",
  "merge duplicate plans", "single source of truth", "same thing two ways", "unify testing layout",
  "README index", "archive old docs", "untracked files", "flatten", "misc folder", "lost its way".
---

# Repository organization

## Overview

Make a directory **navigable and maintainable** without surprising the user or breaking consumers.

**Principles:** (1) **Context before moves** — purpose, consumers, drift, constraints. (2) **One primary axis per directory level** — do not mix lifecycle + domain + audience at the same depth. (3) **Mechanics** — classify, `git mv`, fix references and path resolution, index, dedupe or deprecate explicitly. (4) **Hygiene** — end with a clear `git status` story. (5) **Single source of truth by concept** — map each *area* (e.g. a subsystem, a test theme, a doc topic) to **one canonical home**; the same concern should not live in multiple trees without a named reason (e.g. `manual/` vs `pytest`). (6) **One way to do it** — if the repo already has two scripts, two doc pages, or two test layouts for the *same* job, **converge** on a single approach and retire the other (wrapper stub, deprecation banner, then delete when references are clean).

**Announce at start:** "I'm using the repository-organization skill for this restructure."

**Progressive disclosure:** For large, cross-team, or ambiguous jobs, read `references/fine-details.md` (questions, edge cases, anti-patterns, verification checklist).

**Different trees, different promises:** The **package / source tree** (where the product is built) should read like the system—modules, boundaries, imports. **`scripts/`**, **`docs/`**, **`plans/`**, and similar are **auxiliary**: they hold operational steps, narrative knowledge, and history that often **cross-cut** the code. Good names there answer “what kind of task is this?” (dev setup, graph validation, monitoring) rather than mirroring package names 1:1. Do not force the same mental model on both; index each area so newcomers know which tree they are in. See `references/fine-details.md` § Source tree vs scripts and docs.

---

## Phase 0 — Gate (30 seconds)

If the user only asked for a **small rename** or **single-file** edit, do that normally—do not run the full multi-phase workflow.

**Assessment-only:** If they want a **rating, audit, or review** without moves (“don’t change anything”, “how bad is it”, “score this layout”), run **Phases 1–3** (understand → inventory → propose target shape) and output **findings + severity + recommendations**. Do **not** `git mv`, edit CI, or delete—unless they explicitly ask to execute.

If the task is **reorganize a tree**, **dedupe docs**, or **cleanup scripts area**, continue into execution when they want it.

---

## Phase 1 — Understand (do not skip)

Produce a short **mental model** before proposing moves:

1. **Artifact type** — Deployable app? Library? Docs-only? Mixed? Mixed is a drift signal. Separate **“where the code lives”** from **“where we keep how-to and automation”** when reasoning about target layout (details in `references/fine-details.md`).
2. **Consumers** — Who/what references this path: humans, CI, Dockerfiles, `package.json`/`pyproject` scripts, other repos, bookmarks?
3. **Purpose in one sentence** — If you cannot state it, draft a **contract** (README paragraph: what belongs here, what does not).
4. **Concept map (SSoT)** — List major *concepts* (features, domains, test themes) and where they currently live. If two folders both “own” the same concept (e.g. integration tests for service X split between `tests/e2e/` and root `test_*.py`), that is a **unification** target: pick one canonical layout and migrate the rest.
5. **Duplicate mechanisms** — Same job done in two ways (two validators, two “how to run tests” sections, two env loaders)? Note them; the redesign should leave **one** path and redirect or remove the other.
6. **Drift** — `misc/`, `temp/`, duplicate plan names, prod+scratch in one folder.
7. **Constraints** — Ask if unclear: delete vs archive, submodules, secrets, compliance, **breaking external links OK?**

**Stop and ask** before destructive deletes, secret paths, or vendor subtrees—see `references/fine-details.md`.

---

## Phase 2 — Inventory

- **Structure**: tree or IDE view; tag files as source / doc / generated / binary.
- **References**: `rg` old path segments **before** moves (include CI, Docker, Make, IDE configs).
- **Duplicates**: basename collisions; content hash for files; for docs, overlapping topics → plan **merge** to one canonical file or **stub + pointer** at old names.
- **Scattered concepts**: `rg` and directory review for the *same* subsystem or test theme appearing in multiple roots (e.g. `scripts/`, `tests/`, `tools/`). Treat as **inventory of unification work**, not only as “dup files.”
- **Untracked**: classify into commit / `.gitignore` / delete—do not leave ambiguous `??` forever (table below).

---

## Phase 3 — Design target shape

Pick **one axis** for the first split (examples: **domain**, **lifecycle** `active|completed|archive`, **audience** `dev|ops`). Nested levels can use a **second** axis—never two axes at the same level.

**Per concept, one primary story:** e.g. all automated tests for module `foo` under `tests/.../foo/` or mirror `src/`; all **manual** scratch checks under `tests/manual/` or `scripts/qa/`—pick one convention and document it in the index README. Avoid splitting “how we test X” across three unrelated folders without a labeled exception list.

**Typical `scripts/` buckets** (rename to fit the repo):

| Folder | Holds |
|--------|--------|
| `dev/` | setup, docker build, local helpers |
| `graph/` or `validation/` | DB/graph checks, smoke tests |
| `schema/` | audits, migrations, one-off refactors |
| `mcp/` | MCP / API integration tests |
| `ops/` | monitoring, batch, CI parity scripts |
| `qa/` | pre-release suites |

**Docs/plans:** often `plans/active`, `plans/completed`, `archive/` with README explaining policy.

Deliverable: **target map** (bullet tree or table) + **what references must change**.

---

## Phase 4 — Execute safely

- Use **`git mv`** when history matters; branch per theme or per subdirectory if the diff is huge.
- **Path resolution after depth changes:**
  - **Python:** walk up to repo marker (`pyproject.toml`, etc.) or a small anchor module (e.g. `scripts/_repo_root.py`) + `bootstrap_script(__file__)`.
  - **Bash:** walk up to same marker; shared `lib/bash_common.sh` pattern.
- **No machine-specific absolute paths** in committed scripts.
- **Duplicates:** merge content → canonical → remove or stub the loser.
- **Deprecation:** `archive/` + banner, or README stub at old path for one release cycle; delete when `rg` is clean or user confirms.
- **Executable bits:** verify `+x` on scripts after move.

---

## Phase 5 — Sustain

- **README index** at reorganized root: purpose, layout table, how to run top commands; link to `references/fine-details.md`-style detail only if the repo keeps long runbooks elsewhere.
- **Cursor rules** with `globs` for the subtree if the workspace uses rules.
- **CODEOWNERS** optional on hot paths.

---

## Untracked & generated files

| Situation | Action |
|-----------|--------|
| Deliberate new work | `git add` + commit on feature branch |
| Build/cache | `.gitignore` + comment |
| Scratch / mistake | Delete or quarantine `archive/` |
| Unclear | **One** explicit question; resolve same session |

---

## CLI quick reference

`fd`, `rg` (discovery), `git mv`, `shasum`/`jdupes` (dupes), `python -m py_compile` / `bash -n` (syntax). Prefer small commits.

---

## What this skill is not

- Not **service migration** or **domain refactor** of business logic—use product-specific skills when moving services between repos.
- Not permission to **delete** without confirmation or to touch **secrets** casually.

---

## Related examples

Concrete path-bootstrap patterns (adjust names): `manage/code-graph-system/scripts/_cg_repo_root.py`, `scripts/lib/bash_common.sh`.
