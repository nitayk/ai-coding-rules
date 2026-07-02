# Java Development Rules

**Java-Specific Rules**: Implementation details for Java code.

**How It Works**:
- Generic rules (SOLID, DRY, KISS, correctness first) load **automatically** when you open Java files
- This index loads **automatically** when you open Java files (via globs)
- Use this to discover Java-specific patterns (records, virtual threads, Effective Java patterns)

**Key Principle**: This directory contains ONLY Java-specific patterns. Universal principles are in `generic/` and load automatically - they're referenced from here.

**Graph Structure**: This is a Layer 2 node that routes directly to Layer 0 leaves (rule files) based on keywords. Flattened for efficiency.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **java style**, java formatting, java naming, style guide | `language/style-guide.md` |
| **modern java**, java patterns, records, virtual threads, effective java | `language/modern-java-patterns.md` |
| **virtual threads**, JEP 444, pinning, carrier thread, Thread.ofVirtual | `language/virtual-threads.md` |
| **pattern matching**, switch patterns, sealed types, JEP 441, record patterns, visitor replacement | `language/pattern-matching-switch.md` |
| **records**, DTO, value object, immutable data, Lombok @Value migration, compact constructor | `language/records-as-dtos.md` |
| **text blocks**, multi-line string, embedded SQL/JSON/GraphQL | `language/text-blocks.md` |
| **var**, local-variable inference, readability, when to use var | `language/var-local-inference.md` |
| **java concurrency**, java locking, synchronized, ReentrantLock, StampedLock, thread safety | `language/concurrency-locking.md` |
| **java parallel**, CompletableFuture, ExecutorService, virtual threads, parallel streams, structured concurrency | `language/parallel-processing.md` |
| **null safety**, NullAway, Error Prone, JSpecify, NPE prevention, static analysis | `tooling/null-safety-errorprone-nullaway.md` |
| **java testing**, java unit test, testable code, JUnit, Mockito, Testcontainers | `testing/java-testing-patterns.md` |
| **java production**, production-ready, resource management, null safety | `meta/java-production-patterns.md` |
| **JFR**, Java Flight Recorder, jcmd, JMC, always-on profiling, JVM observability | `meta/jfr-observability.md` |

---

## Available Rules (Leaves)

### 📝 Language Features (`language/`)
- **[Style Guide](language/style-guide.md)** - Java naming conventions, formatting, code organization
- **[Modern Java Patterns](language/modern-java-patterns.md)** - Effective Java principles, records, virtual threads, immutability (overview)
- **[Virtual Threads](language/virtual-threads.md)** - JDK 21 GA; adoption decisions and pinning hazards (JEP 444)
- **[Pattern Matching for switch](language/pattern-matching-switch.md)** - Sealed types + exhaustive switch; replaces visitor boilerplate (JEP 441)
- **[Records as DTOs](language/records-as-dtos.md)** - When records fit, defensive copies for mutable components, Lombok `@Value` migration
- **[Text Blocks](language/text-blocks.md)** - Embedded SQL/JSON/GraphQL with readable multi-line literals
- **[`var` Local-Variable Inference](language/var-local-inference.md)** - When `var` helps vs hurts readability
- **[Concurrency and Locking](language/concurrency-locking.md)** - synchronized, ReentrantLock, StampedLock, deadlock prevention
- **[Parallel Processing](language/parallel-processing.md)** - CompletableFuture, ExecutorService, virtual threads, parallel streams

### 🔧 Tooling (`tooling/`)
- **[Null Safety: Error Prone + NullAway](tooling/null-safety-errorprone-nullaway.md)** - Compile-time NPE prevention; modern alternative to ad-hoc `@Nullable`

### 🧪 Testing (`testing/`)
- **[Java Testing Patterns](testing/java-testing-patterns.md)** - Design for testability, DI, Arrange-Act-Assert, JUnit/Mockito, Testcontainers

### 🏭 Production (`meta/`)
- **[Java Production Patterns](meta/java-production-patterns.md)** - Resource management, null safety, security, thread-safe collections
- **[JFR Observability](meta/jfr-observability.md)** - Java Flight Recorder for always-on prod JVM observability

## Core Principles
- **Context**: Most new mobile-SDK development should be in Kotlin. Java is primarily for maintaining existing code (legacy Android SDK / delivery modules) or library code that requires pure Java compatibility.
- **Style**: Follow Google Java Style Guide.
- **Nullability**: Use compile-time null-safety checking via [Error Prone + NullAway](tooling/null-safety-errorprone-nullaway.md) on new code; `@Nullable` / `@NonNull` annotations support Kotlin interoperability either way.
- **Modern Java**: Use Java 17+ features (records, sealed types, pattern matching, text blocks) and Java 21+ (virtual threads, pattern-matching switch GA) where the target JDK supports them.

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../generic/code-quality/core-principles.md) - Universal principles (SOLID, DRY, KISS, YAGNI, correctness first, pure functions)
- [Generic Architecture Principles](../../generic/architecture/core-principles.md) - Universal architecture principles
- [Generic Testing Principles](../../generic/testing/core-principles.md) - Universal testing principles
- [Generic Error Handling Principles](../../generic/error-handling/universal-patterns.md) - Universal error handling patterns

**Java-Specific:**
- This directory contains Java-specific implementations and examples

---

## Key Resources

**Canonical (language / spec / portal):**
- [Java Language Specification (Java SE hub)](https://docs.oracle.com/javase/specs/) — normative spec, currently Java SE 26 (JSR 401, March 2026)
- [dev.java](https://dev.java/) — Oracle's current official Java developer portal (replaces the old `docs.oracle.com/javase/tutorial`)
- [dev.java/learn](https://dev.java/learn/) — official tutorials: records, pattern matching, virtual threads, FFM, modules
- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html) — de-facto industry style guide

**Modern language features (normative JEPs):**
- [JEP 444: Virtual Threads](https://openjdk.org/jeps/444) — **GA in JDK 21** (Sept 2023); see for pinning hazards
- [JEP 441: Pattern Matching for switch](https://openjdk.org/jeps/441) — **GA in JDK 21**
- [JEP 480: Structured Concurrency](https://openjdk.org/jeps/480) — **still incubator** as of Java 23/24; track before adopting

**Books (still recommended in 2026, with caveats):**
- [Effective Java, 3rd Edition (Joshua Bloch, 2017)](https://www.informit.com/store/effective-java-9780134685991) — canonical idioms; 4th ed not announced; covers up to Java 9 — pair with JEPs above for ≥ 17 features
- [Java Concurrency in Practice (Goetz et al., 2006)](https://jcip.net/) — **fundamentals only** (memory model, happens-before, immutability); predates virtual threads — pair with JEP 444 / JEP 480 for modern concurrency

**Tooling (de-facto picks NOW):**
- [Error Prone](https://errorprone.info/) — Google static analyzer (active; `last-modified 2026-05`)
- [NullAway](https://github.com/uber/NullAway) — modern null-safety checker (Error Prone plugin)
- [Gradle User Manual](https://docs.gradle.org/current/userguide/userguide.html) — current Gradle 9.x; or [Maven Guides](https://maven.apache.org/guides/) per repo
- [JUnit 5 User Guide](https://docs.junit.org/current/user-guide/) — canonical test framework (URL updated from `junit.org/junit5/...` 301)
- [Testcontainers for Java](https://java.testcontainers.org/) — integration-test standard

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
