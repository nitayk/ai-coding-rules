# Scala Rules Navigation Guide

**Scala-Specific Rules**: Implementation details for Scala code.

**How It Works**:
- Generic rules (SOLID, DRY, KISS, correctness first) load **automatically** when you open Scala files
- This index loads **automatically** when you open Scala files (via globs)
- Use this to discover Scala-specific patterns (sealed traits, Option/Either/Try, functional patterns)

**Key Principle**: This directory contains ONLY Scala-specific patterns. Universal principles are in `generic/` and load automatically - they're referenced from here.

**Graph Structure**: This is a Layer 2 node that routes to Layer 1 nodes (subcategory indexes) based on keywords.

---

## Keyword → Subcategory Index Routing

| Keywords/Intent | Load Subcategory Index |
|----------------|----------------------|
| **language**, error handling, functional programming, type safety, scala language | `references/rules/scala/language/index.md` |
| **architecture**, structural guidelines, trait composition, facade, shared library | `references/rules/scala/architecture/index.md` |
| **data**, json serialization, kafka, spark, enums, schema generation | `references/rules/scala/data/index.md` |
| **performance**, collections, memory, future optimization, FP performance | `references/rules/scala/performance/index.md` |
| **testing**, pure testing, scalatest, test patterns | `references/rules/scala/testing/index.md` |
| **meta**, code style, correctness, functional principles, code smells, production | `references/rules/scala/meta/index.md` |
| **build**, sbt, mill, scala-cli, dependency conflict, dependency hell, build.sbt, Dependencies.scala, build tool selection | Use the `/scala-dependency-hell` skill |

---

## Quick Rule Discovery

### When Writing New Scala Code

**Load these rules in order:**
1. [Compiler-Friendly Types](language/compiler-friendly-types.md) - **Start here** - Core principle: stop lying to compiler
2. [Error Handling Patterns](language/error-handling-patterns.md) - Essential error handling with Option, Either, Try
3. [Referential Transparency](language/referential-transparency.md) - Pure functional programming principles
4. [Make Illegal States Unrepresentable](language/make-illegal-states-unrepresentable.md) - Type-safe invariants with sealed traits

### When Handling Errors

**Load these rules:**
- [Error Handling Patterns](language/error-handling-patterns.md) - Option, Either, Try patterns
- [Future Error Handling Conventions](language/future-error-handling-conventions.md) - Async error handling with Future[Either[E, A]]
- [Avoid Option Blindness](language/avoid-option-blindness.md) - When Option loses domain semantics
- [Make Illegal States Unrepresentable](language/make-illegal-states-unrepresentable.md) - Sealed traits for error types

### When Writing Tests

**Load these rules:**
- [Pure Testing Patterns](testing/pure-testing-patterns.md) - **Start here** - Functional testing approach
- [Scala Testing Best Practices](testing/scala-testing-best-practices.md) - ScalaTest patterns
- [Correctness First](meta/correctness-first.md) - Make it correct, then optimize

### When Building for Production

**Load these rules:**
- [Scala Production Patterns](meta/scala-production-patterns.md) - ExecutionContext, timeouts, graceful shutdown
- [Monitoring and Observability Patterns](meta/monitoring-and-observability-patterns.md) - Logging, metrics

### When Optimizing Performance

**Load these rules:**
- [Correctness First](meta/correctness-first.md) - **Make it correct first**
- [Performance Conscious FP](performance/performance-conscious-fp.md) - FP optimization patterns
- [Scala Efficient Future Management](performance/scala-efficient-future-management.md) - Async optimization

---

## Keyword → Subcategory Index Routing

| Keywords/Intent | Load Subcategory Index |
|----------------|----------------------|
| **language**, error handling, functional programming, type safety, scala language | `references/rules/scala/language/index.md` |
| **architecture**, structural guidelines, trait composition, facade, shared library | `references/rules/scala/architecture/index.md` |
| **data**, json serialization, kafka, spark, enums, schema generation | `references/rules/scala/data/index.md` |
| **performance**, collections, memory, future optimization, FP performance | `references/rules/scala/performance/index.md` |
| **testing**, pure testing, scalatest, test patterns | `references/rules/scala/testing/index.md` |
| **meta**, code style, correctness, functional principles, code smells | `references/rules/scala/meta/index.md` |
| **build**, sbt, dependency conflict, dependency hell, build.sbt, Dependencies.scala | Use the `/scala-dependency-hell` skill |

---

## Rule Categories (Subcategory Indexes - Layer 1 Nodes)

### Language Features

**Core Patterns:**
- [Compiler-Friendly Types](language/compiler-friendly-types.md) - Stop lying to compiler
- [Make Illegal States Unrepresentable](language/make-illegal-states-unrepresentable.md) - Sealed traits prevent invalid combinations
- [Error Handling Patterns](language/error-handling-patterns.md) - Option, Either, Try
- [Future Error Handling Conventions](language/future-error-handling-conventions.md) - Future error handling
- [Cats and ZIO Effect Patterns](language/cats-zio-effect-patterns.md) - Cats Effect, ZIO, ZLayer, Resource
- [Cats Effect 3 Resource & IOApp Patterns](language/cats-effect-3-resource-patterns.md) - **NEW** - CE 3.6.x: Resource composition, IOApp variants, Scala Native multithreading
- [Scala 3 Idioms Cheatsheet](language/scala3-idioms.md) - **NEW** - given/using, extension, enum, opaque types; 2.13→3 mapping
- [Referential Transparency](language/referential-transparency.md) - Pure functions

**Advanced Features:**
- [Avoid Overloading](language/avoid-overloading.md) - Prefer explicit naming
- [Avoid Anonymous Function Dependencies](language/avoid-anonymous-function-dependencies.md) - Use named traits
- [Prefer Case Classes Over Tuples](language/prefer-case-classes-over-tuples.md) - Better structured data
- [Iterator Safety](language/iterator-safety.md) - Beware leaking iterators
- [Lazy Evaluation and Productivity](language/lazy-evaluation-and-productivity.md) - LazyList patterns

### Architecture
- [Core Structural Guidelines](architecture/core-structural-guidelines.md) - Application structure
- [Functional Integration in Facade](architecture/functional-integration-in-facade.md) - Facade patterns
- [Trait Composition Patterns](architecture/trait-composition-patterns.md) - Mixin strategies

### Performance
- [Performance Conscious FP](performance/performance-conscious-fp.md) - FP optimization
- [Scala Efficient Future Management](performance/scala-efficient-future-management.md) - Async patterns
- [Akka (and Pekko) Actor Patterns](performance/akka-actor-patterns.md) - Actor best practices, tell vs ask (applies to both Akka and Pekko)
- [Akka → Pekko Migration](performance/akka-to-pekko-migration.md) - **NEW** - BSL relicense, dependency swap, package rename for the ASF Pekko fork
- [Collections and Memory](performance/collections-and-memory.md) - Collection performance, memory optimization

### Testing
- [Pure Testing Patterns](testing/pure-testing-patterns.md) - Functional testing
- [Scala Testing Best Practices](testing/scala-testing-best-practices.md) - ScalaTest guide

### Data Handling
- [JSON Serialization Patterns](data/json-serialization-patterns.md) - Play JSON
- [Scala Complex Enum Best Practices](data/scala-complex-enum-best-practices.md) - Sealed traits
- [Spark DataFrame Best Practices](data/spark-dataframe-best-practices.md) - Spark patterns

### Meta
- [Functional Programming Principles](meta/functional-programming-principles.md) - Core FP patterns
- [Correctness First](meta/correctness-first.md) - Make it correct, then optimize
- [Scala Code Smells](meta/scala-code-smells.md) - Anti-patterns to avoid
- [Scala Production Patterns](meta/scala-production-patterns.md) - Production readiness
- [Scalafmt + Scalafix Baseline](meta/scalafmt-scalafix-baseline.md) - **NEW** - Formatter + linter config, CI gates, common refactors

### Build
- [Build Tool Selection](build/build-tool-selection.md) - **NEW** - sbt vs Mill vs Scala-CLI decision matrix
- [SBT Dependency Management](build/sbt-dependency-management.md) - Dependency conflicts, eviction, `Dependencies.scala` patterns
- For Scala 3 migration patterns, see [Scala 3 Idioms](language/scala3-idioms.md) under Language Features

---

## How to Use This Index

**For LLMs:**
- Use this file to discover which rules to load based on task context
- Load rules using `@filename.md` syntax
- Rules auto-attach when Scala files match their globs
- Use descriptions to decide when to load agent-requested rules

**Rule Loading Priority:**
1. **Always rules** (`alwaysApply: true`) - Always loaded
2. **Auto-attached** (via globs) - Loaded when matching files referenced
3. **Agent-requested** (via description) - LLM decides based on context
4. **Manual** (`@ruleName`) - Explicitly requested

---

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../generic/code-quality/core-principles.md) - Universal principles (SOLID, DRY, KISS, YAGNI, correctness first, pure functions, make illegal states unrepresentable)
- [Generic Architecture Principles](../../generic/architecture/core-principles.md) - Universal architecture principles
- [Generic Testing Principles](../../generic/testing/core-principles.md) - Universal testing principles
- [Generic Error Handling Principles](../../generic/error-handling/universal-patterns.md) - Universal error handling patterns
- [Generic Performance Principles](../../generic/performance/core-principles.md) - Universal performance principles

**Scala-Specific:**
- This directory contains Scala-specific implementations and examples (sealed traits, Option/Either/Try, functional programming patterns)

---

## Related Files

- [index.md](../index.md) - Complete catalog of all rules across languages (root index)
- [ROUTER.md](../ROUTER.md) - Smart intent router (auto-loads)

---

## References

### Canonical (language + tooling)
- [Official Scala Style Guide](https://docs.scala-lang.org/style/) — naming, declarations, layout
- [Scala 3 Migration Guide](https://docs.scala-lang.org/scala3/guides/migration/compatibility-intro.html) — 2.13 ↔ 3.x interop, sbt-scala3-migrate
- [Scala Collections — 2.13 performance characteristics](https://docs.scala-lang.org/overviews/collections-2.13/performance-characteristics.html) — Big-O lookup
- [Scalafmt](https://scalameta.org/scalafmt/) — de-facto formatter, `.scalafmt.conf` (HOCON)
- [Scalafix](https://scalacenter.github.io/scalafix/) — de-facto linter / refactor tool
- [SIP-46 — Scala CLI as default `scala` runner](https://docs.scala-lang.org/sips/scala-cli.html)

### Frameworks
- [Apache Pekko](https://pekko.apache.org/docs/pekko/current/index.html) — Apache 2.0 fork of Akka 2.6.x; **use this, not Akka, for new code** ([why: Akka BSL FAQ](https://akka.io/bsl-license-faq))
- [Cats Effect](https://typelevel.org/cats-effect/) — 3.6.x; Resource, IOApp, Async
- [ZIO](https://zio.dev/) + [Coding Guidelines](https://zio.dev/coding-guidelines) — ZIO 2.1
- [Apache Spark](https://spark.apache.org/docs/latest/) — DataFrame / Iceberg pipelines

### Community (Strong)
- [Scala Best Practices — Rinaudo](https://nrinaudo.github.io/scala-best-practices/)
- [Scala with Cats](https://www.scalawithcats.com/) — Underscore Press (free book)
- [Daniel Beskin's blog (ncreep)](https://blog.daniel-beskin.com/) — most cited source across our existing rules; post archive updated through Dec 2025

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
