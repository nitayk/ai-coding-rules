---
name: service-breakdown
description: "Use when creating service breakdowns, before migrating code between repositories, before refactoring services, or understanding complex service architecture. Do NOT use when you need to modify code (use /service-migration or /service-refactoring), when you already have complete breakdown documentation, or for simple tasks that do not require deep analysis. Requires Memgraph MCP for code graph analysis and Trino MCP for data validation. Prerequisite for service-migration and service-refactoring skills."
---
# Service Breakdown Analysis

**Context**: **iAds** — Memgraph MCP + Atlas MCP. **UADS** — Code Graph MCP (Neo4j backend); use `/code-graph-architect` patterns.

Complete service breakdown methodology for analyzing code structure before migrations and refactoring.

**CRITICAL**: This skill produces **DOCUMENTATION ONLY** - no code changes. For moving code, use `/service-migration`. For improving code, use `/service-refactoring`.

## Skill Comparison

| Skill | Purpose | Output | Code Changes |
|-------|---------|--------|--------------|
| **`/service-breakdown`** | Understand and document | Documentation files | None |
| **`/service-migration`** | Move code between repos | Migrated code | Copy and adapt |
| **`/service-refactoring`** | Improve structure | Refactored code | Modify and improve |

**This skill is a prerequisite for migration and refactoring.**

## When to Use This Skill

**APPLY WHEN:**
- Creating service breakdowns for documentation
- Before migrating code between repositories (prerequisite)
- Before refactoring services (prerequisite)
- Understanding complex service architecture
- Analyzing service dependencies and execution flows

**SKIP WHEN:**
- You need to modify code (use `/service-migration` or `/service-refactoring`)
- You already have complete breakdown documentation
- Task is simple and does not require deep analysis

## Core Directive

**Complete comprehensive investigation FIRST, then create documentation. NO code changes.**

## CRITICAL: Combined Methodology

Follow the Combined Methodology from `/code-structure-analysis` skill: Read files, query Memgraph, grep for external links.

## Tools Hierarchy (Priority Order)

| Priority | Tool | Purpose |
|----------|------|---------|
| **1st** | **Combined Approach** | Read, Graph, Grep, Graph - always |
| **2nd** | **Memgraph MCP** | Code graph analysis - relationships, call chains |
| **3rd** | **Code Reading** | First - understand main flow before graph queries |
| 4th | **grep** | Find Kafka topics, HTTP endpoints, gRPC services |
| 5th | **Consul/Config Access** | Runtime configuration values |
| 6th | **Context7 MCP** | Library documentation |
| 7th | **Web Search** | Fill knowledge gaps |

## Prerequisites

**Verification gate - before starting:**
- [ ] Memgraph MCP is available (`mcp_memgraph_run_query`)
- [ ] Target service path is known
- [ ] Repository has been indexed in Memgraph
- [ ] Access to production configuration (Consul/deployment API)

## The Process

### Phase 1: Investigation (80% of time)

**DO NOT skip to writing documentation.** Complete FULL investigation first.

#### Step 0: Memgraph Validation (Mandatory First)

Verify Memgraph has data before starting. See `.cursor/rules/shared/technologies/memgraph-reference-guide.mdc` for schema and optimization rules.

**Quick validation:**
```cypher
MATCH (c:Class)
WHERE c.repo_name = '{repo-name}' AND c.path CONTAINS '{service-path}'
RETURN count(c) as class_count
```

If Memgraph has incomplete data: Use what IS available, fill gaps with direct file reading. Do NOT skip Memgraph entirely.

#### Step 0.1: Broad Discovery (30-50 queries)

Use code structure analysis (see `/code-structure-analysis` skill): Read files, Graph queries, Grep for external links, Graph queries on connected areas.

**Example workflow:**
1. Read entry point file - Understand main flow
2. Graph query: Find all methods called by main entry
3. Read topology builder - Understand structure
4. Graph query: Find all methods called
5. Grep: Find Kafka topic names
6. Graph query: Find all code that references these topics
7. Grep: Find HTTP endpoints
8. Graph query: Find route handlers
9. Grep: Find Consul keys
10. Graph query: Find code that reads these keys
11. Combine all findings

**Verification gate:** Run queries until you find NOTHING NEW. Expected: 30-200+ queries depending on complexity.

**Cypher query catalog:** See `.cursor/rules/shared/technologies/memgraph-reference-guide.mdc` for full query patterns.

#### Step 0.5: Dynamic Configuration Analysis

**Combined approach:** Grep for external identifiers, Graph query for each, Get ACTUAL production values from config.

**Document:** Actual Kafka topic names (not variables), Aerospike namespace.set combinations, Feature flag values, AB test distributions.

#### Step 0.7: Enrich Understanding

For EACH external dependency, create enrichment: Code location, Config (production values), Real Behavior.

#### Step 1-4: Execution Flow Mapping

Use DFS (Depth-First Search), NOT BFS. For every line of code: Read file, Graph query (10-level deep), Grep for external systems, Graph query for handlers, Document hidden complexity.

#### Track Files Read (CRITICAL)

Maintain Files Read section. **Verification:** Files Read count MUST equal Total Files.

### Phase 2: Synthesis (20% of time)

**ONLY after Phase 1 is complete.**

Create Service Breakdown Document with: Build Overview, Entry Point, Execution Map, External Dependencies (Aerospike, Kafka, Consul), Dead Code Summary, Complexity Hotspots.

## Completion Checklist

**Phase 1 must be complete before Phase 2:**
- [ ] Ran 30-50+ Memgraph queries (minimum)
- [ ] All queries numbered and documented
- [ ] Accessed ACTUAL production config values
- [ ] Files Read count = Total Files count
- [ ] investigation_log.md exists (500+ lines)
- [ ] DFS investigation stack maintained
- [ ] Dead code identified
- [ ] Enrichment examples created (code + config)

**Automatic failure if:** investigation_log.md < 200 lines, Breakdown created before investigation complete, Files Read count does not equal Total Files, No enrichment examples, Only variable names not actual values.

## Output (DOCUMENTATION ONLY)

**During Investigation:** `{investigation-workspace}/investigations/{service-name}/investigation_log.md`

**Final Breakdown:** `{investigation-workspace}/knowledge/repositories/{repo}/{service}/service-breakdown.md` and `metadata.json`

**NO code files are created or modified.**

## Anti-Patterns to Avoid

1. **Skipping Memgraph** - Use graph analysis first
2. **Using BFS instead of DFS** - Go deep, not wide
3. **Documenting before investigating** - Investigation first, docs second
4. **Variable names instead of values** - Get actual production config
5. **Not tracking files read** - Track every file explicitly

## Success Criteria

- investigation_log.md is 500+ lines
- Files Read count matches Total Files
- All queries numbered and documented
- Enrichment examples show code + config
- Dead code identified and documented
- Can answer: What does this service ACTUALLY do in production?

## Quick Reference (Cypher Snippets)

Schema/optimization: `technologies/memgraph-reference-guide.mdc`

- **Entry Points**: `MATCH (c:Class) WHERE c.path CONTAINS 'service-name' AND (c.name CONTAINS 'Main' OR c.name CONTAINS 'App') RETURN c.name, c.path`
- **Call Graph**: `MATCH path=(entry:Method)-[:CALLS*1..7]->(called:Method) WHERE entry.qualified_name CONTAINS 'Main' RETURN path LIMIT 100`
- **Dead Code**: `MATCH (m:Method) WHERE m.path CONTAINS 'service-name' AND NOT (m)<-[:CALLS]-() RETURN m.name, m.path`

**Checklist**: Entry points, call graph, dead code, external integrations (Kafka, HTTP), runtime config values.

## Related Skills

- **Service Migration** - Uses breakdown output (produces code)
- **Service Refactoring** - Uses breakdown output (produces code)
- **Memgraph Analysis** - Full Cypher query reference
- **Cypher Queries** - See `.cursor/rules/shared/technologies/memgraph-reference-guide.mdc`

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
