---
name: service-migration
description: "Use when migrating services between repos, moving code while preserving behavior, or minimizing diffs for code review. Do NOT use when improving code structure (use /service-refactoring), when just documenting a service (use /service-breakdown), or when service breakdown is not completed. REQUIRES /service-breakdown first."
last-reviewed: 2026-06-02
---
# Service Migration

Complete guide for migrating services between repositories with minimal diff.

**CRITICAL**: This skill produces **MIGRATED CODE** - moves code from source to target repo. For understanding only, use `/service-breakdown`. For improving code, use `/service-refactoring`.

## Skill Comparison: Breakdown vs Migration vs Refactoring

| Skill | Purpose | Output | Code Changes |
|-------|---------|--------|--------------|
| **`/service-breakdown`** | Understand & document | Documentation files | None |
| **`/service-migration`** | Move code between repos | Migrated code | Copy + adapt |
| **`/service-refactoring`** | Improve structure | Refactored code | Modify + improve |

**This skill (`/service-migration`) REQUIRES `/service-breakdown` to be completed first.**

## When to Use This Skill

**APPLY WHEN:**
- Migrating services between repositories
- Moving code while preserving behavior
- Minimizing diffs for easier code review
- Splitting monoliths into separate repos
- Repository reorganization

**SKIP WHEN:**
- Improving code structure (use `/service-refactoring`)
- Just documenting a service (use `/service-breakdown`)
- Service breakdown not completed (prerequisite!)

## Core Directive

**MOVE code, don't REWRITE it. Minimize diff. Source is working code - all answers are there.**

## The Eight Rules

1. **Migration ≠ Refactoring** - Move code, don't rewrite it. Minimize diff!
2. **Source is working code** - All answers are in the source repo
3. **Copy first, think later** - Let the compiler guide you
4. **Source = truth for logic** - Don't change business logic
5. **Target = truth for infrastructure** - Use target's patterns
6. **Check shared libs FIRST** - Source's code often exists in target
7. **No stubs ever** - Real implementations or nothing
8. **Use Memgraph heavily** - Code graph > text search

## Critical Rule: Minimal Diff

| Goal | Diff |
|------|------|
| Perfect | Zero differences |
| Reality | Minimize differences |

**Acceptable changes:**
- Package/import paths (necessary)
- Using target's infrastructure patterns
- Using shared-lib instead of copied code

**Unacceptable changes:**
- Fixing bugs (separate PR!)
- "Improving" code style (separate PR!)
- Refactoring (separate PR!)

## Prerequisites

**MANDATORY before writing ANY code:**

- [ ] Service breakdown completed (`service-breakdown` skill)
- [ ] Memgraph queries run on BOTH repos (10+ levels deep)
- [ ] Shared libraries searched
- [ ] Architecture differences identified (embedded vs remote)
- [ ] Type compatibility matrix created (source vs target types)
- [ ] Dead code identified and excluded from migration plan

## Validation Checklist (Before Writing Code)

**You are FORBIDDEN from creating .scala files until:**

1. [ ] SERVICE_BREAKDOWN.md exists
2. [ ] Architecture checked (embedded vs remote?)
3. [ ] Target repo searched in Memgraph
4. [ ] Shared libraries searched

## The Migration Process

### Phase 0: Preparation (Day 1 - NO CODING)

**THE DAY 1 RULE: On Day 1, you ONLY analyze. You NEVER copy code, wire dependencies, create stubs, or make "quick fixes".**

1. **Complete service breakdown** (use `service-breakdown` skill)
2. **Run DEEP Memgraph queries** (10+ levels) on both source and target
3. **Identify dead code** in source - DO NOT migrate it. Use Memgraph to find methods/classes with no callers.
4. **Create type compatibility matrix** - Compare source types vs target types. Document adapters needed.

   Example matrix format:

   | Source Type | Source Fields | Target Type | Target Fields | Compatible? | Notes |
   |-------------|---------------|-------------|---------------|-------------|-------|
   | `Request` | 70 fields | `Request` | 2 fields | No | Need adapter |
   | `Response` | 10 fields | `Response` | 10 fields | Yes | Direct map |

5. **Search target repo** for existing implementations:

**For complete schema, indexes, and optimization rules, see:**
`the /memgraph-analysis skill`

**Quick Reference:**
- **Schema**: Unified - all nodes use `path` (not `file_path`), `qualified_name` is PK
- **Optimization**: Always filter by `repo_name` FIRST, use exact `qualified_name` match when possible

**Useful Memgraph Queries:**
- **Find Dependencies**: `MATCH (service:File)-[:IMPORTS|USES|INHERITS*]->(dep:File) WHERE service.path CONTAINS 'my-service' RETURN DISTINCT dep.path`
- **Find Dead Code**: `MATCH (c:Class {name: "LegacyClass"})<-[:CALLS|USES]-(caller) RETURN count(caller)` — If 0, do not migrate
- **Find External Calls**: `MATCH (m:Method)-[:CALLS]->(ext:Method) WHERE m.path CONTAINS 'my-service' AND (ext.qualified_name CONTAINS 'Kafka' OR ext.qualified_name CONTAINS 'Aerospike') RETURN DISTINCT ext.qualified_name, m.path`

   Use the queries in the **[Memgraph Query Patterns](#memgraph-query-patterns)** section below to check whether each class already exists in the target and to spot shared-library implementations.

3. **Create migration plan**:
   - What needs to be copied
   - What exists in target already
   - What's in shared libraries
   - What's dead code (skip it!)

### Phase 1: Copy Structure

**Copy source files to target:**

```bash
# Copy service directory structure
cp -r source-repo/service target-repo/service

# Update package declarations
find target-repo/service -name "*.scala" -exec sed -i 's/package com.old/package com.new/g' {} \;
```

### Phase 2: Fix Imports

**Use target's infrastructure patterns:**

```scala
// Source's embedded Aerospike
val aerospike = new AerospikeClient()

// Target's remote Aerospike
val aerospike = AerospikeService.client
```

### Phase 3: Wire Infrastructure

**Replace embedded with remote:**

```markdown
| Source (Embedded) | Target (Remote) | How to Wire |
|-------------------|-----------------|-------------|
| AerospikeClient() | AerospikeService | Inject dependency |
| KafkaProducer() | KafkaService | Use existing producer |
| ConsulKV() | ConfigService | Use config service |
```

### Phase 4: Testing

**Validation checklist:**

```bash
# 1. Compile
sbt compile

# 2. Run tests
sbt test

# 3. Compare behavior
# Source vs Target: Same inputs → same outputs

# 4. Check diff size
git diff --stat  # Should be minimal!
```

## Common Pitfalls

1. **Rewriting instead of moving**
   - Fix: Copy first, preserve structure
   
2. **Missing shared library implementations**
   - Fix: Query Memgraph for existing code
   
3. **Creating stubs**
   - Fix: Wire to real implementations
   
4. **Copying dead code**
   - Fix: Use service breakdown to identify dead code

5. **Not querying target repo**
   - Fix: Run Memgraph queries on target first

## Memgraph Query Patterns

```cypher
// Find if class exists in target
MATCH (c:Class {name: 'ClassName'})
WHERE c.qualified_name STARTS WITH 'target-repo'
RETURN c.name, c.qualified_name, c.path

// OPTIMIZED: Check shared libraries
MATCH (c:Class)
WHERE c.repo_name = '{repo-name}'           // Indexed: reduces dataset
  AND (c.qualified_name CONTAINS 'shared-logic'  // Additional filter
    OR c.path CONTAINS 'shared-logic')
RETURN c.name, c.path, c.qualified_name

// Find similar classes (different names)
MATCH (c:Class)
WHERE c.name CONTAINS 'Key'
  AND c.qualified_name STARTS WITH 'target-repo'
RETURN c.name, c.qualified_name, c.path

// Verify no dead code copied (use size() for performance)
MATCH (m:Method)
WHERE m.repo_name = '{repo-name}'           // Indexed: reduces dataset
  AND m.qualified_name CONTAINS 'new-service'  // Additional filter
WITH m, size([()-[:CALLS]->(m) | 1]) as incoming_calls
WHERE incoming_calls = 0
RETURN m.name, m.qualified_name, m.path
```

## Success Criteria

- **Code compiles in target**
- **All tests pass**
- **Minimal diff** (mostly imports/packages)
- **No dead code copied**
- **Using target's infrastructure patterns**
- **No stubs created**
- **Service breakdown guided the migration**

## Output (MIGRATED CODE)

Produces migrated code in the **target repository**: copied service files (updated package declarations + imports), infrastructure wired from embedded → remote patterns, updated tests/docs as needed. Delivered as a clean, minimal git diff (mostly package/import changes) across multiple commits per `/git-workflow` (each: compiles + tests pass + logical task complete). Result: the service runs in the target with the same behavior as the source, no dead code copied, easy to review.

**Key difference from refactoring:** migration *moves* code between repos and minimizes the diff; refactoring *improves* code in the same repo and changes structure.

## Related Skills

- **Service Breakdown** - **MUST complete first** (prerequisite!)
- **Memgraph Analysis** - For finding existing code in target repo
- **Git Workflow** - For managing migration commits

## Remember

> "Migration is MOVING, not REWRITING."

> "The source is working production code - all answers are there."

> "Check shared libraries FIRST - don't copy what already exists."

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
