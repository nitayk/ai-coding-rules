# Scala Data Handling Patterns Index

**Purpose**: Router for Scala data patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **json serialization**, play json, json patterns | `json-serialization-patterns.md` |
| **play json gotchas**, play json pitfalls, json gotchas | `play-json-gotchas.md` |
| **kafka**, service discovery, kafka topics, kafka patterns | `kafka-service-discovery-patterns.md` |
| **spark**, dataframes, spark optimization, spark patterns | `spark-dataframe-best-practices.md` |
| **enumeratum**, enums, type-safe enums, enumeratum patterns | `enumeratum-enum-best-practices.md` |
| **sealed enums**, complex enums, sealed trait enums | `scala-complex-enum-best-practices.md` |
| **proto**, avro, schema generation, schema registry | `proto-avro-schema-generation.md` |
| **configuration**, config objects, type-safe config | `configuration-object-patterns.md` |

---

## Data Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [JSON Serialization Patterns](json-serialization-patterns.md) | Play JSON serialization patterns | json serialization, play json |
| [Play JSON Gotchas](play-json-gotchas.md) | Play JSON common pitfalls | play json gotchas, json pitfalls |
| [Kafka Service Discovery Patterns](kafka-service-discovery-patterns.md) | Patterns for tracing Kafka topics and service discovery | kafka, service discovery, kafka topics |
| [Spark DataFrame Best Practices](spark-dataframe-best-practices.md) | Spark DataFrame optimization patterns | spark, dataframes, spark optimization |
| [Enumeratum Enum Best Practices](enumeratum-enum-best-practices.md) | Type-safe enums with enumeratum | enumeratum, enums, type-safe enums |
| [Scala Complex Enum Best Practices](scala-complex-enum-best-practices.md) | Complex enum patterns using sealed traits | sealed enums, complex enums |
| [Proto/Avro Schema Generation](proto-avro-schema-generation.md) | Schema generation for Kafka and data pipelines | proto, avro, schema generation, schema registry |
| [Configuration Object Patterns](configuration-object-patterns.md) | Type-safe configuration objects | configuration, config objects |

---

## Quick Reference

| Need | Load |
|------|------|
| JSON serialization | `json-serialization-patterns.md`, `play-json-gotchas.md` |
| Kafka patterns | `kafka-service-discovery-patterns.md` |
| Spark DataFrames | `spark-dataframe-best-practices.md` |
| Enum patterns | `enumeratum-enum-best-practices.md`, `scala-complex-enum-best-practices.md` |
| Schema generation | `proto-avro-schema-generation.md` |
| Configuration | `configuration-object-patterns.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Architecture**: See `../architecture/index.md` for architectural patterns

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
