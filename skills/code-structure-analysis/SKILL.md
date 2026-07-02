---
name: code-structure-analysis
description: "Use when analyzing code structure, investigating services, tracing execution flows, mapping dependencies, or understanding complex codebases. Do NOT use when simple single-file changes, Memgraph MCP not available, or quick code understanding. Requires Memgraph MCP for graph queries."
last-reviewed: 2026-05-20
---

# Code Structure Analysis

**Context**: iAds-side analysis using **Memgraph MCP + Atlas MCP**. **Scope: LP (LevelPlay), ISX, IDP, and Ad Quality only** — iAds core delivery/DS/SDK is sunsetting April 2026, so do not invest in deep analysis there beyond bug-fix scope. For UADS use `/code-graph-architect` (Code Graph MCP). For cross-repo network mapping use `/full-network-analysis`.

**CRITICAL**: Always combine file reading, graph queries, and grep searches — never rely on a single approach. Graphs don't model external systems; use grep to bridge them.

## When to Use This Skill

**APPLY WHEN** (iAds-side, active repos only — LP / ISX / IDP / Ad Quality):
- Investigating an LP, ISX, IDP, or Ad Quality service before migration or refactoring
- Tracing execution flows and call chains within those repos
- Mapping dependencies inside a single repo (combining code + runtime)
- Finding external system integrations (Kafka, HTTP, gRPC, databases) for an active iAds service
- **MANDATORY** before service-breakdown / migration / refactoring on an active iAds service

**DO NOT USE WHEN:**
- Working in iAds core delivery/DS/SDK (sunsetting Apr 2026 — bug fixes only, no deep analysis)
- Working in UADS repos — use `/code-graph-architect` (Code Graph MCP, Neo4j) instead
- Cross-repo / cross-product network mapping — use `/full-network-analysis`
- Pure graph traversal with no Read/grep — use `/memgraph-analysis` directly
- Pure runtime topology (Kafka producers/consumers, Aerospike) with no code reading — use `/atlas-analysis`
- Simple single-file changes or quick code understanding (Read alone suffices)
- Memgraph MCP not available

## Core Directive

**Always combine file reading, graph queries, and grep searches** - Never rely on a single approach. Graphs don't model external systems; use grep to bridge them. **Prefer `git grep` over `grep` for large codebases** — avoids timeouts.

## The Problem

Code graphs (Memgraph) **DO NOT** model external system links:
- Kafka topics
- HTTP endpoints  
- gRPC services
- Aerospike keys
- Database connections
- Redis keys
- External API calls

**Graphs only show**: Code-to-code relationships (calls, inheritance, imports)

## Prerequisites

- [ ] Memgraph MCP configured (for graph queries)
- [ ] Code indexed in Memgraph (verify with test query)
- [ ] Access to codebase files (for reading and grep)
- [ ] Atlas MCP configured (optional, for runtime topology - Kafka, Aerospike, service deps)

**If Memgraph unavailable**: Use file reading + grep only (graph queries will be skipped)

**If Atlas available**: Use for runtime connectivity - `get_service_topology`, `get_resource_usage` (Kafka topics, Aerospike clusters). See `the /atlas-analysis skill`

## Tool Selection

| Task | Tool | Reference |
|------|------|-----------|
| Code structure, callers, dead code | Memgraph / git grep | `the /memgraph-analysis skill`, `references/git.md` |
| Production metrics, dashboards | Grafana | `the /grafana-monitoring skill` |
| Data schemas, SQL validation | Trino | `the /trino-validation skill` |
| Kubernetes deployments | ArgoCD | `the /argocd-deployment skill` |
| Kafka topics, consumers | kcat | `references/kcat.md` |

## Process

### Phase 1: Read Files → Understand Main Flow

**Purpose**: Get high-level understanding of structure and flow

**Steps**:
1. **Read main entry points** - Main classes, service entry points, key files
2. **Understand structure** - Package organization, module boundaries
3. **Identify key components** - Core classes, utilities, handlers
4. **Note external system usage** - Look for Kafka, HTTP, gRPC, database references

**Example**:
```scala
// Read main service file
def buildStream(...) {
  val thresholdsTable = streamsBuilder.globalTable(...)
  buildCountersStream(...)
  buildInflightStreams(...)
}
```

**What you learn**:
- Main entry points
- High-level structure
- Key components and their relationships
- External system usage patterns

**Verification**: Can you explain the main flow in 2-3 sentences?

### Phase 2: Graph Queries → Finalize Scope

**Purpose**: Find all code relationships for specific functions/files/classes.

**Delegate query patterns to `/memgraph-analysis`** — that skill owns the Cypher patterns (callers/callees, 10-level recursion, dead-code detection, indexed-filter ordering) plus the full schema reference at `the /memgraph-analysis skill (references/memgraph-reference-guide.md)`. Do not restate them here.

**What this phase contributes** (on top of `/memgraph-analysis`):
- Drives queries from the entry points discovered in Phase 1, not from a blank slate
- Feeds results back into Phase 3 grep (e.g. method names found here become grep seeds for external-system identifiers)
- Holds the scope question: "have we queried until finding nothing new?" (50–200+ queries expected for complex services)

**Verification**: Have you traced callers, callees, and dead code for every entry point identified in Phase 1?

### Phase 3: Grep → Connect External Systems

**Purpose**: Find external system identifiers, then query graph for each

**Steps**:
1. **Grep for Kafka topics** - Find topic names, consumer/producer configs
2. **Grep for HTTP endpoints** - Find route definitions, path patterns
3. **Grep for gRPC services** - Find service definitions, method names
4. **Grep for database keys** - Find Aerospike keyspaces, Redis keys, table names
5. **Grep for configuration** - Find Consul keys, config file references
6. **For each identifier found** - Query graph to find code that uses it

**Prefer `git grep` over `grep -r` for large codebases** — avoids timeouts.

**Pattern**: grep for a bare identifier (topic, endpoint, key), then ask `/memgraph-analysis` to find `Method` nodes whose `source_code CONTAINS` that identifier (always filter `repo_name` first for the index). Example:

```bash
git grep "{topic-name}" -- {service-path}/         # then graph-query for usage
git grep 'path(".*")' -- {service-path}/           # then graph-query for handlers
```

**What you learn**:
- External system identifiers (topics, endpoints, services)
- Code that uses these identifiers
- Complete flow from code → external system → response handling

**Verification**: Have you found all external integrations? (Kafka, HTTP, gRPC, databases, config)

### Phase 4: Atlas (Optional) → Runtime Connectivity

**Purpose**: When Atlas MCP is available, add runtime topology to complete the picture

**Steps**:
1. **get_service_topology(serviceName)** - For each key service, get upstream/downstream (HTTP, Kafka, Aerospike)
2. **list_resources(kafka_topic)** - Get all Kafka topics with traffic
3. **get_resource_usage(topic/cluster)** - For key topics/clusters, find producers and consumers
4. **Map runtime flow** - Connect code (Memgraph) with runtime (Atlas) for full network

**Example**: `get_service_topology("my-service")` → gateway → downstream, Kafka topics

**Reference**: `the /atlas-analysis skill`

### Phase 5: Combine Findings → Unified Understanding

**Purpose**: Load all results (Read + Graph + Grep + Atlas) into same context for complete picture

**Steps**:
1. **Combine internal structure** - Call chains from graph queries
2. **Combine external links** - External systems from grep + graph queries
3. **Map complete flow** - From entry point → internal calls → external systems → response handling
4. **Document findings** - Create unified understanding of service architecture

**Example Complete Workflow**:

**Goal**: Understand main flow completely

**Step 1: Read the file**
```scala
// Read main service file
def buildStream(...) {
  val thresholdsTable = streamsBuilder.globalTable[String, Option[ThresholdValue]](
    KafkaTopics.thresholdsTopic, ...
  )
  val countersStream = buildCountersStream(...)
  InflightHandler.buildInflightStreams(...)
  handleStatusStream(...)
}
```

**Step 2: Graph query for internal calls** — delegate to `/memgraph-analysis` (10-level recursive `CALLS` from `buildStream` in `{ClassName}` within `{repo-name}`).

**Step 3: Grep for Kafka topics**
```bash
git grep "{topic-name}" -- {service-path}/
```

**Step 4: Graph query for Kafka usage** — `/memgraph-analysis` query: `Method` nodes where `source_code CONTAINS '{topic-name}'` (filter `repo_name` first for index).

**Step 5: Grep for HTTP endpoints**
```bash
git grep 'path(".*")' -- {service-path}/
```

**Step 6: Graph query for route handlers** — `/memgraph-analysis` query: `Method` nodes where `source_code CONTAINS '{endpoint-path}'`.

**Step 7: Combine all findings**
- Internal call chain: `buildStream` → `buildCountersStream` → ...
- Kafka topics: `{topic-name}` used in N methods
- HTTP endpoints: `{endpoint-path}` handled by route handler
- Complete flow: HTTP request → Route handler → Kafka Streams → Topic → Consumer

## When to Use Each Tool

| Tool | Best For | Limitations |
|------|----------|-------------|
| **File Reading** | Understanding structure, flow, external system usage | Doesn't show call chains, relationships |
| **Graph Queries** | Code relationships, call chains, dead code, inheritance | Doesn't show external system links |
| **Grep** | Finding external identifiers (topics, endpoints, services) | Doesn't show relationships, just text matches |
| **Atlas** | Runtime topology - Kafka producers/consumers, Aerospike, HTTP service deps | Requires Atlas MCP; shows runtime only, not code |

## Anti-Patterns to Avoid

### Graph Only: Missing External System Connections

**Problem**: Code graphs don't model Kafka topics, HTTP endpoints, gRPC services

**Solution**: Use grep to find external identifiers, then query graph

### Grep Only: Missing Code Relationships

**Problem**: Text search doesn't show method calls, inheritance, dependencies

**Solution**: Use graph queries to find complete call chains

### File Reading Only: Missing Complete Scope

**Problem**: Reading files doesn't reveal all callers, callees, or dead code

**Solution**: Use graph queries to finalize scope

### Sequential Approach: Inefficient

**Problem**: Reading everything, then querying everything misses connections

**Solution**: Iterative approach - Read → Graph → Grep → Graph → Combine

## Output

**This skill produces comprehensive code analysis combining:**

### Internal Structure (from Graph Queries)
- Complete call chains (10 levels deep)
- All callers and callees
- Dead code identification
- Inheritance hierarchies
- Dependencies

### External Integrations (from Grep + Graph)
- Kafka topics and usage
- HTTP endpoints and handlers
- gRPC services and methods
- Database connections and keys
- Configuration sources

### Code Flow (from File Reading)
- Main entry points
- High-level structure
- Key components
- Execution patterns

### Unified Understanding
- Complete service architecture
- End-to-end execution flows
- External system connections
- Dependency mapping

**Note**: This skill produces **analysis results**, not files. Results are used by other skills (service-breakdown, service-migration, service-refactoring) or documented in investigation logs.

## Success Criteria

- **Used all three approaches** - Read, Graph, Grep (Atlas when available for runtime connectivity)
- **Found complete call chains** - 10-level recursive queries
- **Identified external integrations** - Kafka, HTTP, gRPC, databases
- **Combined findings** - Unified understanding of service architecture
- **Documented complete flow** - From entry point to external systems

## Related Skills

- **`/full-network-analysis`** — **use this instead** when the question crosses repo boundaries (Memgraph + Atlas + grep + semantic across multiple iAds repos). This skill is single-service scope.
- **`/memgraph-analysis`** — owns the Cypher patterns and schema reference; this skill orchestrates around it.
- **`/atlas-analysis`** — owns runtime topology (Kafka producers/consumers, Aerospike, HTTP service deps); use directly when code reading isn't needed.
- **`/code-graph-architect`** — UADS equivalent (Code Graph MCP / Neo4j). Use it for any `uads/**` work; this skill is iAds-only.
- **`/service-breakdown`** / **`/service-migration`** / **`/service-refactoring`** — downstream consumers of this skill's output.

## Related References

- **Memgraph Reference Guide** - `the /memgraph-analysis skill (references/memgraph-reference-guide.md)` - Complete schema, indexes, optimization
- **Atlas Reference Guide** - `the /atlas-analysis skill` - Runtime topology (Kafka, Aerospike, service deps)
- **Service Breakdown Skill** - the `/service-breakdown` skill - Complete service analysis methodology
- **Memgraph Analysis Skill** - the `/memgraph-analysis` skill - Graph query patterns

## Remember

> "Always combine all three approaches - Read, Graph, Grep. Never rely on a single method."

> "Graphs don't model external systems - use grep to bridge them."

> "Use 10-level recursive queries, not 5."

> "Query until you find NOTHING NEW."

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
