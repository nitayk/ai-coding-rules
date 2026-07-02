# Akka → Apache Pekko Migration

Lightbend relicensed Akka under the **Business Source License (BSL) 1.1** starting Akka 2.7 (Sep 2022). Apache **Pekko** is the Apache Software Foundation's Apache 2.0 fork of Akka **2.6.21**, and is the path forward for projects that cannot or do not want to take a commercial Akka license. As of May 2026 Pekko is at **1.6.0** and considered production-ready by the ASF.

This rule covers when to migrate, the mechanical replacements, and the gotchas.

Sources: [Akka BSL FAQ](https://akka.io/bsl-license-faq), [Apache Pekko documentation](https://pekko.apache.org/docs/pekko/current/index.html).

---

## Core Directive

**For new Scala code, depend on Apache Pekko, not Akka.** For existing code already on Akka 2.6.x, migrate to Pekko 1.x as part of normal maintenance — the API surface is nearly identical and the migration is a mechanical rename plus dependency swap. **Only stay on Akka ≥ 2.7 if your org has paid for a Lightbend commercial license.**

---

## Why Migrate

### The BSL Math

The Akka BSL FAQ explicitly states: BSL versions **auto-revert to Apache 2.0 three years after release** ([source](https://akka.io/bsl-license-faq)). That means:

| Akka version | Release | Apache 2.0 from |
|---|---|---|
| 2.6.x | pre-Sep 2022 | Apache 2.0 since release |
| 2.7.x | Sep 2022 | Sep 2025 |
| 2.8.x | 2023 | 2026 |
| 2.9.x / 2.10.x | 2024+ | 2027+ |

Most production-relevant versions remain commercial today. Pekko 1.x tracks the Akka 2.6.x API and accepts community contributions under Apache 2.0 — no commercial gate.

### What Pekko Inherits

- Actor system, typed actors, classic actors
- Streams, HTTP, persistence, cluster, sharding
- Persistence query, distributed data, projection

If you used Akka 2.6.x, Pekko 1.x supports the same primitives. The Pekko 1.6.0 release notes are the authoritative compatibility map ([Pekko docs](https://pekko.apache.org/docs/pekko/current/index.html)).

---

## Migration Mechanics

### 1. Dependency Swap (sbt)

✅ Good — Pekko coordinates:

```scala
// build.sbt
val pekkoVersion = "1.6.0"
libraryDependencies ++= Seq(
  "org.apache.pekko" %% "pekko-actor-typed"      % pekkoVersion,
  "org.apache.pekko" %% "pekko-stream"           % pekkoVersion,
  "org.apache.pekko" %% "pekko-http"             % "1.2.0",
  "org.apache.pekko" %% "pekko-actor-testkit-typed" % pekkoVersion % Test
)
```

❌ Bad — staying on commercial Akka without a license:

```scala
// BSL-licensed; commercial license required for production use
libraryDependencies += "com.typesafe.akka" %% "akka-actor-typed" % "2.10.0"
```

### 2. Package Rename

Almost every `akka.*` import becomes `org.apache.pekko.*`. The actor APIs are otherwise unchanged.

```scala
// Akka
import akka.actor.{Actor, ActorRef, ActorSystem, Props}
import akka.actor.typed.ActorRef as TypedRef
import akka.pattern.{ask, pipe}
import akka.stream.scaladsl.{Source, Sink, Flow}
import akka.http.scaladsl.Http

// Pekko equivalents
import org.apache.pekko.actor.{Actor, ActorRef, ActorSystem, Props}
import org.apache.pekko.actor.typed.ActorRef as TypedRef
import org.apache.pekko.pattern.{ask, pipe}
import org.apache.pekko.stream.scaladsl.{Source, Sink, Flow}
import org.apache.pekko.http.scaladsl.Http
```

A scripted bulk rename gets you 95% of the way:

```bash
# Inside the project root
find . -name "*.scala" -o -name "*.sbt" \
  | xargs sed -i.bak 's/\bakka\./org.apache.pekko./g'
# Then handle group ids and artifact names in build files manually.
```

### 3. Configuration Keys

HOCON configuration keys are renamed `akka.*` → `pekko.*`. Same shape, different prefix.

```hocon
# application.conf — Akka
akka {
  loglevel = "INFO"
  actor.provider = "cluster"
}

# application.conf — Pekko
pekko {
  loglevel = "INFO"
  actor.provider = "cluster"
}
```

If you bridge both (e.g. a library still emits `akka.*` keys), Pekko respects `pekko.*` first; document the override clearly.

### 4. Serialization Manifests

Persistence and remoting serialize the class FQCN. After migration, schema upgraders must map old `akka.*` manifests to the new `org.apache.pekko.*` ones. **Plan a migration journal pass for any persisted state** (Akka Persistence, Cluster Sharding state, snapshot stores).

---

## Decision Matrix

| Situation | Choice |
|---|---|
| Greenfield Scala actor code | **Pekko 1.x** |
| Existing Akka 2.6.x, no BSL exposure | **Migrate to Pekko 1.x** at next maintenance window |
| Existing Akka ≥ 2.7, org has commercial license | Stay on Akka, plan eventual Pekko evaluation |
| Existing Akka ≥ 2.7, **no** commercial license | **Immediate Pekko migration** — license non-compliance risk |
| Using Akka HTTP / Akka Streams only | Pekko HTTP / Pekko Streams are drop-in replacements |
| Heavy Lightbend Telemetry / Akka Insights dependency | Evaluate cost vs migration; no full OSS equivalent |

---

## Gotchas

### Transitive Akka Pulls

A library may still pull in `com.typesafe.akka` even after you depend on Pekko. Audit:

```bash
sbt "evicted" | grep -i akka
sbt "dependencyTree" | grep -i akka
```

Common culprits: older Play 2.x, older Alpakka modules (use Pekko Connectors instead), older Lagom.

### Mixed Classpath Is Broken

You **cannot** run Akka and Pekko actor systems side-by-side in the same JVM and have them interoperate as one cluster. They are distinct packages, distinct serialization namespaces, distinct config trees. If you must bridge, use a network boundary (HTTP/gRPC/Kafka), not in-process actors.

### Prioritizing migration

For long-lived, actively-maintained subsystems, plan the Pekko migration proactively — staying on BSL Akka indefinitely is a compliance and bus-factor risk. Modules already slated for deprecation can stay on whatever Akka version they ship with.

---

## Related Rules

- [Akka (and Pekko) Actor Patterns](akka-actor-patterns.md) — message and concurrency patterns that apply to both
- [Scala Efficient Future Management](scala-efficient-future-management.md) — Future interop with actors
- [Build Tool Selection](../meta/build-tool-selection.md) — sbt remains the default for Pekko projects

---

## References

- [Apache Pekko documentation](https://pekko.apache.org/docs/pekko/current/index.html) — Pekko 1.6.0 (May 2026)
- [Akka BSL License FAQ](https://akka.io/bsl-license-faq) — license terms, 3-year reversion, what triggers commercial use
- [Pekko Connectors](https://pekko.apache.org/docs/pekko-connectors/current/) — replaces Alpakka
- [Pekko HTTP](https://pekko.apache.org/docs/pekko-http/current/) — replaces Akka HTTP

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
