---
name: code-structure-analysis
description: "Use when analyzing code structure, investigating services, tracing execution flows, mapping dependencies, or understanding complex codebases. Do NOT use when simple single-file changes, Memgraph MCP not available, or quick code understanding. Requires Memgraph MCP for graph queries."
---

# Code Structure Analysis

**Context**: **iAds** — Memgraph MCP + Atlas MCP. **UADS** — Code Graph MCP (Neo4j backend); no Atlas.

**CRITICAL**: Always combine file reading, graph queries, and grep searches - Never rely on a single approach. Graphs don't model external systems; use grep to bridge them. **For full cross-repo network**: Add Atlas MCP for runtime topology (Kafka producers/consumers, Aerospike, service dependencies).

## When to Use This Skill

**APPLY WHEN:**
- Analyzing code structure and architecture
- Investigating services before migration or refactoring
- Tracing execution flows and call chains
- Mapping dependencies and relationships
- Understanding complex codebases
- Finding external system integrations (Kafka, HTTP, gRPC, databases)
- Mapping cross-repo runtime connectivity
- **MANDATORY** before service breakdown, migration, or refactoring

**DO NOT USE WHEN:**
- Simple single-file changes that do not require comprehensive analysis
- Memgraph MCP not available (use file reading + grep only)
- Quick code understanding (file reading may be sufficient)

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

**If Atlas available**: Use for runtime connectivity - `get_service_topology`, `get_resource_usage` (Kafka topics, Aerospike clusters). See `technologies/atlas-reference-guide.mdc`

## Tool Selection

| Task | Tool | Reference |
|------|------|-----------|
| Code structure, callers, dead code | Memgraph / git grep | `technologies/memgraph-reference-guide.mdc`, `tools/git.mdc` |
| Production metrics, dashboards | Grafana | `technologies/grafana-reference-guide.mdc` |
| Data schemas, SQL validation | Trino | `technologies/trino-reference-guide.mdc` |
| Kubernetes deployments | ArgoCD | `technologies/argocd-reference-guide.mdc` |
| Kafka topics, consumers | kcat | `tools/kcat.mdc` |

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

**Purpose**: Find all code relationships for specific functions/files/classes

**Reference**: For complete Memgraph schema, indexes, and optimization rules, see `.cursor/rules/shared/technologies/memgraph-reference-guide.mdc`

**Steps**:
1. **Find classes** - Query for all classes in service/package
2. **Find methods** - Query for methods in key classes
3. **Trace call chains** - Use 10-level recursive queries (not 5!)
4. **Find callers** - Who calls this method/class?
5. **Find dependencies** - What does this code depend on?
6. **Detect dead code** - Methods/classes with no callers

**Example**:
```cypher
// OPTIMIZED: Find all methods called by buildStream
MATCH (m:Method)
WHERE m.repo_name = '{repo-name}'           // Indexed: reduces dataset
  AND m.name = 'buildStream'                // Indexed: name lookup
  AND m.qualified_name CONTAINS '{ClassName}'     // Additional filter
MATCH (m)-[:CALLS*1..10]->(called:Method)
RETURN called.name, called.qualified_name, called.path
```

**What you learn**:
- Complete call chains (10 levels deep)
- All callers and callees
- Dead code detection
- Inheritance chains
- Implementation relationships

**Verification**: Have you queried until finding NOTHING NEW? (50-200+ queries expected for complex services)

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

**Example**:
```bash
# Step 1: Grep for Kafka topic names (git grep preferred for large repos)
git grep "{topic-name}" -- {service-path}/

# Step 2: Graph query for each topic name found (non-indexed filter after indexed)
MATCH (m:Method)
WHERE m.repo_name = '{repo-name}'           // Indexed: reduces dataset
WITH m
WHERE m.source_code CONTAINS '{topic-name}'       // Non-indexed: after WITH
RETURN m.name, m.qualified_name, m.path

# Step 3: Grep for HTTP endpoints
git grep 'path(".*")' -- {service-path}/

# Step 4: Graph query for route handlers (non-indexed filter after indexed)
MATCH (m:Method)
WHERE m.repo_name = '{repo-name}'           // Indexed: reduces dataset
WITH m
WHERE m.source_code CONTAINS '{endpoint-path}'    // Non-indexed: after WITH
RETURN m.name, m.qualified_name, m.path
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

**Reference**: `.cursor/rules/shared/technologies/atlas-reference-guide.mdc`

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

**Step 2: Graph query for internal calls**
```cypher
// OPTIMIZED: Find all methods called by buildStream
MATCH (m:Method)
WHERE m.repo_name = '{repo-name}'           // Indexed: reduces dataset
  AND m.name = 'buildStream'                 // Indexed: name lookup
  AND m.qualified_name CONTAINS '{ClassName}'     // Additional filter
MATCH (m)-[:CALLS*1..10]->(called:Method)
RETURN DISTINCT called.name, called.qualified_name
```

**Step 3: Grep for Kafka topics**
```bash
# Find Kafka topic references
grep -r "{topic-name}" {service-path}/
```

**Step 4: Graph query for Kafka usage**
```cypher
// Find all code that uses budgetOnlineThresholdsTopic
MATCH (m:Method)
WHERE m.source_code CONTAINS '{topic-name}'
RETURN m.name, m.qualified_name, m.path
```

**Step 5: Grep for HTTP endpoints**
```bash
# Find HTTP route definitions
grep -r 'path(".*")' {service-path}/
```

**Step 6: Graph query for route handlers**
```cypher
// Find handlers for endpoint
MATCH (m:Method)
WHERE m.source_code CONTAINS '{endpoint-path}'
RETURN m.name, m.qualified_name, m.path
```

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

- **Full Network Analysis** - Combines Memgraph + Atlas + Grep + Semantic search for complete cross-repo mapping
- **Atlas Analysis** - Runtime topology patterns (Kafka, Aerospike, service deps)
- **Service Breakdown** - Uses code structure analysis methodology extensively
- **Service Migration** - Uses code structure analysis to understand source service
- **Service Refactoring** - Uses code structure analysis to identify dead code and dependencies
- **Memgraph Analysis** - Provides graph query patterns and optimization

## Related References

- **Memgraph Reference Guide** - `.cursor/rules/shared/technologies/memgraph-reference-guide.mdc` - Complete schema, indexes, optimization
- **Atlas Reference Guide** - `.cursor/rules/shared/technologies/atlas-reference-guide.mdc` - Runtime topology (Kafka, Aerospike, service deps)
- **Service Breakdown Skill** - `.cursor/rules/shared/skills/service-breakdown/SKILL.md` - Complete service analysis methodology
- **Memgraph Analysis Skill** - `.cursor/rules/shared/skills/memgraph-analysis/SKILL.md` - Graph query patterns

## Remember

> "Always combine all three approaches - Read, Graph, Grep. Never rely on a single method."

> "Graphs don't model external systems - use grep to bridge them."

> "Use 10-level recursive queries, not 5."

> "Query until you find NOTHING NEW."

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
