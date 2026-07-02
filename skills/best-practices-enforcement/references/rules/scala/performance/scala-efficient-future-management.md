**NOTE: Consider ZIO over Future for Functional Programming**

While this guide covers Future best practices, consider migrating to ZIO for better:
- **Referential transparency** (Futures are eager and have hidden side effects)
- **Composability** (ZIO provides better error handling and resource management)
- **Testability** (ZIO effects are values that can be tested without execution)

```scala
// Good: ZIO for pure functional effects
def fetchUserProfile(id: UserId): ZIO[Database, DbError, UserProfile] = ???

// Acceptable but less FP: Future with side effects
def fetchUserProfile(id: UserId): Future[UserProfile] = ???
```

---

## Best Practices
### 1. Pool Management
- Use a dedicated `ExecutionContext` for blocking I/O (e.g., database calls to ad event logs):

```scala
val ioEC: ExecutionContext = ExecutionContext.fromExecutor(
  Executors.newFixedThreadPool(100) // Match your ad exchange's rate limits
)
```

- Reserve the default EC for CPU-bound tasks (e.g., bid price calculations).

---

### 2. Avoid Nested Futures

```scala
// Bad: Creates 3 separate thread hops
Future(processAdRequest()).flatMap(_ => Future(updateBudget()))

// Good: Single thread hop
Future {
  processAdRequest()
  updateBudget()
}(ioEC)
```

---

### 3. Batch Operations

- Use `Future.sequence` for bulk ad event writes:

```scala
val writes: List[Future[Unit]] = adEvents.map(e => Future(writeToDB(e))(ioEC))
Future.sequence(writes) // 1 thread context vs N
```

---

### 4. Timeout Critical Paths

```scala
import scala.concurrent.duration._

val bidFuture = adExchange.submitBid(bidRequest)
bidFuture.withTimeout(100.millis)(system.scheduler) // Fail fast during traffic spikes
```

---

### 5. Reuse Futures

- Cache frequently used ad configs:

```scala
lazy val adPolicy: Future[AdPolicy] = fetchPolicyFromCMS() // Executes once
```

---

## Anti-Pattern Detection

- Flag code that creates `Future` inside `map`/`flatMap`:

```scala
// Bad: Nested Future
Future(parseAdRequest()).map(req => Future(validate(req)))
```

---

## AdTech-Specific Configuration

```hocon
// application.conf (Akka, Pekko, or Play — same dispatcher config shape)
ad-tech-dispatcher {
  executor = "thread-pool-executor"
  throughput = 1
  thread-pool-executor {
    fixed-pool-size = 32 // Match CPU cores for bid logic
  }
}
```

Note: under Apache Pekko, the same dispatcher block lives under `pekko.*` instead of `akka.*`. See [Akka → Pekko Migration](akka-to-pekko-migration.md) for the rename mechanics.

---

## Why This Matters in AdTech

- A 100-thread pool handling 10k RPS can reduce EC2 costs by 40% vs unbounded pools.
- Proper batching cuts Redis call volume by 70% in user profile updates.
- Timeouts prevent 90th percentile latency spikes during ad exchange failures.

This rule ensures your `Future` usage aligns with the "money path" requirements of real-time bidding systems.

---

## Related Rules

**Universal Principles:**
- [Generic Performance Principles](../../../../generic/performance/core-principles.md) - Universal performance principles (measure first, optimize bottlenecks, resource management)

**Scala-Specific:**
- [Future Error Handling Conventions](../language/future-error-handling-conventions.md) - **Adopt explicit error handling conventions for Future** - Distinguish business errors from defects, use Future[Either[E, A]] or EitherT
- [Error Handling Patterns](../language/error-handling-patterns.md) - Foundation for error handling with Option, Either, Try

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
