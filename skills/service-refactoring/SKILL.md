---
name: service-refactoring
description: "Use when refactoring services to improve structure, removing dead code, or consolidating scattered code. Do NOT use when moving code to another repo (use /service-migration), when just documenting (use /service-breakdown), when service breakdown is not completed, or when tests do not exist or pass. REQUIRES /service-breakdown first."
last-reviewed: 2026-06-02
---
# Service Refactoring

Systematic process for refactoring services safely with validation and testing.

**CRITICAL**: This skill produces **REFACTORED CODE** - improves structure in same repo. For understanding only, use `/service-breakdown`. For moving code, use `/service-migration`.

## Skill Comparison: Breakdown vs Migration vs Refactoring

| Skill | Purpose | Output | Code Changes |
|-------|---------|--------|--------------|
| **`/service-breakdown`** | Understand & document | Documentation files | None |
| **`/service-migration`** | Move code between repos | Migrated code | Copy + adapt |
| **`/service-refactoring`** | Improve structure | Refactored code | Modify + improve |

**This skill (`/service-refactoring`) REQUIRES `/service-breakdown` to be completed first.**

## When to Use This Skill

**APPLY WHEN:**
- Refactoring services to improve structure
- Improving code organization without changing behavior
- Consolidating scattered code
- Removing dead code
- Improving maintainability
- Reducing complexity

**SKIP WHEN:**
- Moving code to another repo (use `/service-migration`)
- Just documenting a service (use `/service-breakdown`)
- Service breakdown not completed (prerequisite!)
- Tests don't exist or don't pass (fix tests first!)

## Core Directive

**IMPROVE structure, don't change behavior. Tests are your safety net - run them after every change.**

## The Five Rules

1. **Understand before changing** - Complete breakdown first
2. **Tests are your safety net** - All tests must pass before AND after
3. **One module at a time** - Don't refactor everything at once
4. **Behavior must not change** - Same inputs → same outputs
5. **Commit stable states** - Compiles + tests pass + task complete

## Prerequisites

**MANDATORY before refactoring:**

- [ ] Module/service breakdown completed
- [ ] All tests passing (baseline established)
- [ ] All callers identified (who depends on this?)
- [ ] All dependencies mapped (what does it use?)
- [ ] Dead code identified (what can be removed?)

## Tool Priority

| Tool | Use For | Reference |
|-----|---------|-----------|
| **Memgraph** | Finding TRUE dependencies (grep lies). Dead code detection. | `technologies/memgraph-reference-guide.md` |
| **Tests** | Verifying behavior is preserved. | — |

**Find Unused Methods (safe to delete):** see the dead-code query in the [Memgraph Query Patterns](#memgraph-query-patterns) section below.

## The Core Principle: Tests Are Your Safety Net

**Before any refactoring:**
```bash
sbt test  # Note pass count
```

**After every change:**
```bash
sbt test  # Must have SAME pass count
```

**If tests fail → you changed behavior → undo and retry.**

## The Refactoring Process

### Phase 0: Analysis (Day 0 - NO CODE CHANGES!)

**Activities:**
1. Complete module breakdown (callers, dependencies, dead code)
2. Run all tests, record pass count
3. Identify refactoring candidates via Memgraph:

**For complete schema, indexes, and optimization rules, see:**
`the /memgraph-analysis skill`

**Quick Reference:**
- **Schema**: Unified - all nodes use `path` (not `file_path`), `qualified_name` is PK
- **Optimization**: Always filter by `repo_name` FIRST, use exact `qualified_name` match when possible

```cypher
// OPTIMIZED: Find scattered files that should be consolidated
MATCH (c:Class)
WHERE c.repo_name = '{repo-name}'           // Indexed: reduces dataset
  AND c.qualified_name CONTAINS '{module}'  // Additional filter
MATCH (c)-[:DEFINES]->(m:Method)
WITH c.name as className, collect(DISTINCT m.path) as files
WHERE size(files) > 1
RETURN className, files

// Find dead code to remove → see the dead-code query in "Memgraph Query Patterns" below

// OPTIMIZED: Find high-complexity methods to simplify
MATCH (m:Method)
WHERE m.repo_name = '{repo-name}'           // Indexed: reduces dataset
  AND m.qualified_name CONTAINS '{module}'  // Additional filter
MATCH (m)-[:CALLS*1..5]->(called:Method)
WITH m, count(DISTINCT called) as complexity
WHERE complexity > 10
RETURN m.name, m.qualified_name, complexity
ORDER BY complexity DESC
```

4. **Create refactoring plan** with priorities

### Phase 1: Remove Dead Code (Easiest First!)

**Safest refactoring = deletion.** Find methods with no callers using the dead-code query in [Memgraph Query Patterns](#memgraph-query-patterns) (exclude `main`).

**Process:**
1. Identify dead code
2. Remove it
3. Compile and test
4. Commit

### Phase 2: Extract Common Code

**When code is duplicated across files:**

1. **Identify duplication** (Memgraph or manual review)
2. **Extract to utility/helper**
3. **Replace call sites** one by one
4. **Test after each replacement**
5. **Commit when all replaced**

### Phase 3: Reorganize Structure

**Move files to better locations:**

```bash
# Example: Move related files together
mv scattered/FileA.scala module/handlers/
mv scattered/FileB.scala module/handlers/

# Update package declarations
sed -i 's/package scattered/package module.handlers/g' module/handlers/*.scala
```

**After each move:**
```bash
sbt compile && sbt test
git commit -m "refactor: move handlers to module/handlers/"
```

### Phase 4: Simplify Complex Methods

**Break down complex methods:**

```scala
// Before: Complex method with multiple responsibilities
def processRequest(request: Request): Response = {
  // 100 lines of validation, processing, response building
}

// After: Extracted responsibilities
def processRequest(request: Request): Response = {
  val validated = validateRequest(request)
  val processed = processData(validated)
  buildResponse(processed)
}

private def validateRequest(request: Request): ValidatedRequest = { ... }
private def processData(validated: ValidatedRequest): ProcessedData = { ... }
private def buildResponse(processed: ProcessedData): Response = { ... }
```

**Process:**
1. Extract one responsibility at a time
2. Test after each extraction
3. Commit stable state

## Git Workflow

**Every commit must:**
- Compile: `sbt compile`
- Pass tests: `sbt test`
- Represent complete logical task

```bash
# Before EVERY commit
sbt compile && sbt test
git commit -m "refactor(module): <completed task>"
```

## Common Pitfalls

1. **Refactoring without tests**
   - Fix: Ensure tests exist and pass first
   
2. **Changing behavior**
   - Fix: Run tests after every change
   
3. **Too many changes at once**
   - Fix: One module at a time, commit often
   
4. **Not using Memgraph**
   - Fix: Query for dead code, call chains, dependencies

5. **Refactoring during migration**
   - Fix: Separate concerns - migrate first, refactor later

## Validation Checklist

After refactoring:

- [ ] All tests pass (same count as before)
- [ ] Code compiles without warnings
- [ ] Behavior unchanged (same inputs → same outputs)
- [ ] Dead code removed
- [ ] Related code consolidated
- [ ] Commit history shows stable states

## Memgraph Query Patterns

```cypher
// OPTIMIZED: Find dead code (use size() for performance)
MATCH (m:Method)
WHERE m.repo_name = '{repo-name}'           // Indexed: reduces dataset
  AND m.qualified_name CONTAINS '{module}'  // Additional filter
WITH m, size([()-[:CALLS]->(m) | 1]) as incoming_calls
WHERE incoming_calls = 0
RETURN m.name, m.qualified_name, m.path

// OPTIMIZED: Find all callers (impact analysis) - exact match fastest
MATCH (m:Method {qualified_name: '{exact-methodQualifiedName}'})
MATCH (caller:Method)-[:CALLS]->(m)
RETURN caller.name, caller.qualified_name, caller.path

// If exact QN not known:
MATCH (m:Method)
WHERE m.repo_name = '{repo-name}'           // Indexed: reduces dataset
  AND m.qualified_name CONTAINS '{methodQualifiedName}'  // Additional filter
MATCH (caller:Method)-[:CALLS]->(m)
RETURN caller.name, caller.qualified_name, caller.path

// OPTIMIZED: Find dependencies (what will break?) - exact match fastest
MATCH (m:Method {qualified_name: '{exact-methodQualifiedName}'})
MATCH (m)-[:CALLS]->(dep:Method)
RETURN dep.name, dep.qualified_name, dep.path

// OPTIMIZED: Find complexity hotspots
MATCH (m:Method)
WHERE m.repo_name = '{repo-name}'           // Indexed: reduces dataset
  AND m.qualified_name CONTAINS '{module}'  // Additional filter
MATCH (m)-[:CALLS*1..5]->(called:Method)
WITH m, count(DISTINCT called) as complexity
WHERE complexity > 10
RETURN m.name, m.qualified_name, complexity
ORDER BY complexity DESC
```

## Success Criteria

- **All tests pass** (same count as before)
- **No behavior changes**
- **Dead code removed**
- **Related code consolidated**
- **Complexity reduced**
- **Clean commit history**
- **Module structure improved**

## Output (REFACTORED CODE)

Produces refactored code in the **same repository**: dead code removed, complex methods extracted/simplified, scattered files consolidated, imports/tests updated to match. Delivered as multiple commits (one per stable state; each compiles + passes tests + completes a logical task) with a clean history. Result: better-organized, lower-complexity, more maintainable code with provably unchanged behavior. (Refactoring improves code in the same repo; migration moves it between repos — see the comparison table above.)

## Related Skills

- **Service Breakdown** - **MUST complete first** (prerequisite!)
- **Memgraph Analysis** - For finding dead code and dependencies
- **Git Workflow** - For managing refactoring commits

## Remember

> "Tests are your safety net - run them after every change."

> "Refactor one module at a time, commit stable states."

> "If tests fail, you changed behavior - undo and retry."

> "Delete dead code first - it's the safest refactoring."

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
