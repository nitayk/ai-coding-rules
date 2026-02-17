---
name: code-cleanup
description: "Three-phase code cleanup with certainty-graded findings. Detects AI slop (debug statements, TODOs, placeholder text), dead code, excessive comments, and common anti-patterns. Phase 1: regex patterns (HIGH certainty), Phase 2: heuristic analyzers (MEDIUM certainty), Phase 3: optional CLI tools (LOW certainty). Use when cleaning up code before commit or PR, after AI-generated code, removing debug artifacts, or reducing code noise. Do NOT use for feature implementation, code review (use code-reviewer agent), or refactoring logic (use /service-refactoring)."
---

# Code Cleanup

Three-phase detection pipeline that finds and removes AI slop, debug artifacts, dead code, and code noise. Inspired by certainty-graded detection methodology.

## When to Use This Skill

**APPLY WHEN:**
- Cleaning up code before commit or PR
- After AI-generated code sessions (removing debug prints, TODOs, placeholder text)
- Removing debug artifacts from production code
- Reducing code noise (excessive comments, dead imports)
- Pre-merge cleanup

**DO NOT USE WHEN:**
- Implementing features (just write clean code)
- Code review (use code-reviewer agent instead)
- Refactoring logic (use `/service-refactoring`)
- Only reading code without cleanup intent

## Core Directive

Detect code issues using three phases of increasing uncertainty. Report findings grouped by certainty level. Only auto-fix HIGH certainty findings unless explicitly asked.

## Process

### Phase 1: Pattern Detection (HIGH Certainty)

Scan target files for definite issues using regex patterns. These are safe to auto-fix.

**Debug Statements:**
- `console.log(`, `console.debug(`, `console.warn(` (JS/TS)
- `println(`, `print(` outside of logging frameworks (Scala/Java)
- `print(`, `pprint(`, `breakpoint()` (Python)
- `fmt.Println(`, `log.Println(` outside logging wrappers (Go)
- `NSLog(`, `debugPrint(` (Swift/Objective-C)
- `Log.d(`, `Log.v(` outside production logging (Kotlin/Android)

**TODO/FIXME/HACK markers:**
- `// TODO`, `// FIXME`, `// HACK`, `// XXX`, `// TEMP`
- `# TODO`, `# FIXME`, `# HACK` (Python/Shell)

**Dead Code Indicators:**
- Commented-out code blocks (3+ consecutive commented lines with code syntax)
- Unused imports (language-specific detection)
- Empty catch/except blocks
- Disabled linter rules (`// eslint-disable`, `// noinspection`, `// scalastyle:off`)

**Security/Quality:**
- Hardcoded strings matching secret patterns (`AKIA`, `sk-`, `ghp_`, `password=`)
- `var` instead of `val`/`const`/`let` where appropriate
- `null` returns in Scala/Kotlin (use Option/nullable types)

**Output format for Phase 1:**
```
HIGH [file:line]: [category] - [description]
  Fix: [specific fix]
```

### Phase 2: Heuristic Analysis (MEDIUM Certainty)

Analyze code structure for probable issues that need human judgment.

**Documentation Noise:**
- Comment-to-code ratio > 40% in a file (excessive comments)
- AI preamble patterns ("Sure, here's", "Let me", "I'll create", "Here's how")
- Redundant comments that restate the code (`i++ // increment i`)
- JSDoc/Scaladoc on every trivial function

**Over-Engineering Indicators:**
- Single-implementation interfaces/traits (premature abstraction)
- Wrapper classes that add no behavior
- Factory patterns for simple object creation
- Deeply nested generics (3+ levels)

**Dead Code Candidates:**
- Functions with zero callers (use Memgraph if available, grep otherwise)
- Unused class fields/properties
- Unreachable code after return/throw/break

**Stub/Placeholder Code:**
- Functions returning hardcoded values with TODO comments
- `NotImplementedError` / `???` / `throw new UnsupportedOperationException`
- Empty function bodies (non-interface/trait methods)

**Output format for Phase 2:**
```
MEDIUM [file:line]: [category] - [description]
  Context: [why this might be intentional]
  Suggested fix: [recommendation]
```

### Phase 3: CLI Tool Analysis (LOW Certainty, Optional)

Run language-specific CLI tools if available. These findings are suggestions, not definitive issues.

**JavaScript/TypeScript:**
- `npx jscpd --min-lines 5` (copy-paste detection)
- `npx madge --circular` (circular dependencies)

**Python:**
- `ruff check --select ALL` (comprehensive linting)
- `vulture` (dead code detection)

**Scala:**
- `sbt scalafix` (if configured)
- `wartremover` findings

**Go:**
- `golangci-lint run` (comprehensive linting)

**General:**
- `tokei` (code statistics for context)

**Output format for Phase 3:**
```
LOW [file:line]: [tool] - [finding]
  Note: [context about false positive likelihood]
```

### Step 4: Generate Report

Group all findings by certainty level. Lead with HIGH, then MEDIUM, then LOW.

```
Code Cleanup Report
===================

Summary: X HIGH | Y MEDIUM | Z LOW findings

HIGH Certainty (safe to auto-fix):
  [findings]

MEDIUM Certainty (review recommended):
  [findings]

LOW Certainty (suggestions):
  [findings]

Recommended Actions:
  1. Auto-fix all HIGH findings
  2. Review MEDIUM findings with context
  3. Consider LOW findings if time permits
```

### Step 5: Apply Fixes (If Requested)

When user says "apply", "fix", or "clean":
1. Apply ALL HIGH certainty fixes
2. Ask before applying each MEDIUM certainty fix
3. Report LOW certainty findings but do not apply

## Thoroughness Levels

- **quick**: Phase 1 only (fastest, 30 seconds)
- **normal**: Phase 1 + Phase 2 (default, 2-5 minutes)
- **deep**: All three phases if tools are available (5-15 minutes)

## Output

Code Cleanup Report (in chat, not file):
1. Summary with finding counts by certainty level
2. Grouped findings with file:line references
3. Recommended actions
4. If "apply" mode: applied changes with before/after

## Related

- `/code-review` command - Broader code review
- `/best-practices-enforcement` skill - Standards validation
- `/service-refactoring` skill - Structural improvements
- `code-reviewer` agent - Full code review
