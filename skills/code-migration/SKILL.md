---
name: code-migration
description: "Systematic code migration workflow between repositories with mandatory Day 1 analysis before any code copying. Use when: (1) Migrating service from repo A to repo B, (2) Moving code between repositories, (3) Copying components to another project. Do NOT use when making in-repo refactors, adding new features, or when service-breakdown analysis is not available."
disable-model-invocation: true
---

# Code Migration

## Critical Rules

### THE DAY 1 RULE: NO CODING

**On Day 1, you ONLY analyze**:
- Run DEEP Memgraph queries (10+ levels)
- Check what ALREADY EXISTS in target repo
- Identify dead code in source (don't migrate it!)
- Create type compatibility matrix
- Document all decisions

**On Day 1, you NEVER**:
- Copy code
- Wire dependencies
- Create stubs
- Make "quick fixes"

### Prerequisites

Before starting migration, you MUST have:
1. **Complete service breakdown** of source service
2. **Complete service breakdown** of target repo structure
3. **Type compatibility matrix** (source types vs target types)
4. **Dependency map** (what's available in target)

## Instructions

### Step 1: Analyze Source Service

Use `service-breakdown` skill on source service to get: live code (excluding dead), external dependencies, execution paths, configuration requirements.

### Step 2: Analyze Target Repository

Use Memgraph to understand target repo:
- What shared utilities already exist?
- What types are available?
- What dependencies are available?

**Key Query**:
```cypher
// Find if component already exists in target
MATCH (c:Class {name: 'ComponentName'})
WHERE c.qualified_name STARTS WITH 'target-repo'
RETURN c.qualified_name, c.file_path, c.source_code
```

### Step 3: Create Compatibility Matrix

Compare types between source and target:

| Source Type | Source Fields | Target Type | Target Fields | Compatible? | Notes |
|-------------|---------------|-------------|---------------|-------------|-------|
| `Request` | 70 fields | `Request` | 2 fields | No | Need adapter |
| `Response` | 10 fields | `Response` | 10 fields | Yes | Direct map |

### Step 4: Identify Dead Code

Use Memgraph to find methods/classes with no callers. **DO NOT MIGRATE DEAD CODE.**

### Step 5: Document Migration Plan

Create plan in `investigation_toolkit/initiatives/{migration-name}/`:
- What code needs copying (only live code!)
- What already exists in target (reuse!)
- Type adapters needed
- Dependency changes required

### Step 6: Execute Migration (Day 2+)

Only after Day 1 analysis is complete and documented.

## Common Failures

- **Copying existing component**: Query Memgraph in target repo first
- **Copying dead code**: Find methods with no callers before migrating
- **Type mismatches**: Create compatibility matrix, don't assume compatibility
- **Missing dependencies**: Read target build.sbt before migrating

## Tools Required

- MCP: Memgraph (primary - for both repos)
- Read: For build files and code
- Grep: For finding patterns

## Success Criteria

**Verify before proceeding:**
- Complete service breakdown exists for source
- Checked target repo for existing components
- Created type compatibility matrix
- Identified and excluded dead code
- Documented migration plan
- Day 1 = Analysis only (no coding)
