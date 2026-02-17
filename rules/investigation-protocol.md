# Investigation Protocol

## Triggers
**APPLY WHEN:** Analyzing services, investigating code, breaking down architecture.
**SKIP WHEN:** Simple code changes, single-file edits, known patterns.

## Core Directive

Use the Combined Methodology (Read + Graph + Grep) for any investigation.

## Process

1. **Map code structure first** - Find callers, dependencies, dead code, call chains before reading code.
2. **Read 100% of live code** - No shortcuts. 80% is not 100%.
3. **Grep for external links** - Kafka topics, HTTP endpoints, gRPC services, config keys. Graph does not model these.
4. **Get production values** - From config sources/Deployment API/Grafana. Not variable names. Not estimates.
5. **Verify everything** - Challenge assumptions, verify claims against actual data.

## Tool Selection

| Task | Tool |
|------|------|
| Code structure, callers, dead code | Code graph tool / grep |
| Production metrics, dashboards | Grafana |
| Service config, feature flags | Config sources |
| Data schemas, SQL validation | Trino |
| Kubernetes deployments | ArgoCD |
| Kafka topics, consumers | Kafka CLI / kcat |

## Why Combined Methodology

Graph limitations: Code graphs do not model external links (Kafka topics, HTTP endpoints, gRPC services, Aerospike keys).

To connect external systems:
1. Use grep to find external identifiers (topic names, endpoint URLs, service names)
2. Run graph queries on each connected area
3. Connect the graphs using grep results
