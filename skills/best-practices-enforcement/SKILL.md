---
name: best-practices-enforcement
description: "Use as the language-/stack-rules enforcement gate (Phase 6 #4 in /e2e). Loads the repo's coding-standard rule files for detected languages and validates the diff against them — primarily a rule-driven mechanical check, not deep review. Do NOT use for: review methodology / feedback quality (use /code-review-excellence), debug artifact removal (use /code-cleanup), broader reuse / clarity refactor (use /code-simplification), or general code reading."
last-reviewed: 2026-05-20
---
# Best Practices Enforcement

The language-rules / stack-rules enforcement gate. Loads this repo's authoritative rule files for the detected language(s) and validates the diff against them. **Mechanical checking against named rules** — *not* a substitute for `/code-review-excellence` (which is about review methodology and feedback quality).

## When to use

**APPLY WHEN:**
- Phase 6 #4 of `/e2e` (the "Standards" gate)
- You want a diff validated against the language-/framework-specific rule files this skill bundles under its own `references/rules/`
- Standalone "did I follow our conventions?" check before committing

**DO NOT USE WHEN:**
- Review methodology / feedback quality / mentoring → use `/code-review-excellence`
- Debug artifacts / dead imports / `console.log` cleanup → use `/code-cleanup`
- Broader reuse / DRY / clarity refactor → use `/code-simplification` (auto-applies fixes; the old `/simplify` was renamed to `/code-review` in CC 2.1.147 but lost its auto-fix behavior — `/code-review` now only reports correctness bugs)
- Just reading code with no review intent
- (The rule files now ship *with* this skill under `references/rules/`, so they are always available — no separate install needed.)

**Boundaries with neighbors:**
| Skill | Concern | Output |
|---|---|---|
| `/code-cleanup` | Mechanical noise removal | Edits |
| `/code-simplification` | Reuse, clarity, complexity refactor | Edits |
| `/code-review` (CC built-in) | Correctness bug finder (formerly `/simplify`, behavior changed in CC 2.1.147 — auto-fix removed) | Findings report |
| `/best-practices-enforcement` | **This skill** — diff vs named rule files | Findings report |
| `/code-review-excellence` | Review *methodology*, prioritization, feedback quality | Methodology guidance |
| `/security-review` (per-PR) | Vulnerability scan | Findings report |
| `/security-audit` (release) | Deep security audit | Findings report |

If you're tempted to invoke this AND `/code-review-excellence` AND `/code-cleanup` in the same gate run, you're double-counting — pick the one that matches the goal.

## Token-bomb guard (READ FIRST)

This skill loads ~10 rule files into context. **If the orchestrator already loaded any of those rule files earlier in the session (e.g. via `/code-review`, `/service-refactoring`, or a prior gate run), SKIP the load step** — just reference them by path. Re-loading the same rule files compounds context cost across phases. Track which rules are already in context; only `read_file` the missing ones.

## Core Directive

Validate code against SOLID, DRY, KISS, YAGNI, security (input validation, least privilege), testing (AAA, behavior over implementation), performance (measure first), architecture (separation of concerns, DI), error handling (fail fast, explicit errors, check immediately), defensive programming (trust boundaries, whitelist validation), guard clauses, and interface design (small interfaces, ISP).

## Prerequisites

1. **Detect language(s)** from file extensions: `.scala`, `.py`, `.go`, `.java`, `.php`, `.js`/`.ts`/`.tsx`/`.jsx`, `.swift`, `.kt`, `.m`/`.mm`
2. **Load generic rules** from `references/rules/common/generic/` (see Step 1 list)
3. **Load language-specific index** for each detected language (stack layout under `references/rules/<stack>/`):
   - Go, Python, Scala, Java, PHP: `references/rules/<lang>/index.md`
   - JS/TS: `references/rules/typescript/index.md`
   - Kotlin, Swift, Objective-C: `references/rules/<kotlin|swift|objective-c>/index.md`

**Verification**: Announce detected languages before loading rules. Load rules using `read_file` - do not just mention them.

**Path convention**: rule files are bundled with this skill. Generic files resolve as `references/rules/common/generic/<path>` (e.g. `references/rules/common/generic/code-quality/core-principles.md`). Language stacks: `references/rules/<lang>/...`. Paths are relative to this skill's directory.

## Process

### Step 1: Detect Languages and Load Rules

1. Scan target files for language extensions (glob or list_dir)
2. Announce: "Detected languages: [list]"
3. Load generic rules (use `references/rules/common/generic/index.md` to route; load these files relative to **`references/rules/common/generic/`**):
   - `code-quality/core-principles.md` (SOLID, DRY, KISS, YAGNI, lazy programmer, pure functions)
   - `error-handling/universal-patterns.md` (fail fast, check errors immediately)
   - `error-handling/silent-failure-check.md` (no silent failures)
   - `testing/core-principles.md`
   - `performance/core-principles.md`
   - `security/core-principles.md`
   - `architecture/core-principles.md`
   - `architecture/interface-design.md` (small interfaces, ISP, composition)
   - `defensive-programming/trust-boundaries.md` (validate at boundaries, whitelist)
   - `control-flow/guard-clauses.md` (early returns, reduce nesting)
4. For each detected language, load index and relevant rule files from `references/rules/<stack>/` (e.g. `references/rules/scala/language/…`)
5. **Verification**: If multiple languages detected, load rules for ALL

### Step 2: Analyze Code Structure

For each file/module, check:
- **Code Quality**: SRP, DRY, KISS, YAGNI, meaningful names, pure functions, lazy programmer (effort for maximal gain)
- **Security**: Input validation (whitelist over blacklist), least privilege, no secrets, SQL injection prevention
- **Testing**: Tests exist, AAA pattern, behavior over implementation, isolation
- **Performance**: No premature optimization, bottlenecks measured, efficient algorithms
- **Architecture**: Interface-centric, separation of concerns, DI, small interfaces (ISP), composition
- **Error Handling**: Fail fast, explicit errors, check errors immediately, proper propagation, no silent failures
- **Defensive Programming**: Trust boundaries (validate external data at entry), whitelist validation, schema evolution
- **Control Flow**: Guard clauses, early returns, reduce nesting, happy-path emphasis

### Step 3: Language-Specific Validation

Apply loaded language rules: Python (type hints, PEP 8), Scala (Option/Either, immutability), Go (explicit errors), Java (interfaces), PHP (modern patterns), JS/TS (type safety, async, error handling), Swift (optionals), Kotlin (null safety, coroutines).

### Step 4: Generate Report

Structure findings by category: violations, locations, recommendations, priority (Critical/Warning/Suggestion). Report in chat, not file.

## Output

Best Practices Audit Report (in chat):
1. Summary: compliance status with counts
2. By category: violations, locations, recommendations, priority
3. Language-specific findings if applicable

## Anti-Patterns

- **Mentioning rules without loading**: Use `read_file` to actually load rule files
- **Skipping language detection**: Scan files first, load rules for detected languages only
- **Single language when multiple present**: Load rules for ALL detected languages
- **Loading only legacy categories**: Load all 10 generic rule files (including defensive-programming, guard-clauses, interface-design, silent-failure-check)
- **Ignoring frontend**: JS/TS files route to `rules/typescript/`, not `rules/scala/` etc.
- **Vague recommendations**: Include file:line, specific issue, concrete fix

## Related

- `/code-review` command (`commands/code-review.md`) - Broader code review
- `/service-refactoring` skill - Apply during refactoring
- `/service-migration` skill - Ensure migrated code follows practices

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
