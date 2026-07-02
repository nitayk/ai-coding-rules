# Scala Production Patterns

Patterns for production-ready Scala services. Based on Effective Scala, Scala Best Practices, and production experience.

---

## Use Dedicated ExecutionContexts for Workload Types

**Separate CPU-bound from I/O-bound.** Use a dedicated EC for blocking I/O (DB, HTTP) to avoid starving the default pool.

```scala
// Good: Dedicated EC for blocking I/O
val ioEC: ExecutionContext = ExecutionContext.fromExecutor(
  Executors.newFixedThreadPool(32)
)

def fetchUser(id: UserId): Future[User] =
  Future(blockingDbCall(id))(ioEC)
```

Reserve the default EC for CPU-bound tasks. See [Scala Efficient Future Management](../performance/scala-efficient-future-management.md).

---

## Add Timeouts to Outbound Calls

**Fail fast.** Use `withTimeout` or `akka.pattern.after` for external service calls.

```scala
// Good: Timeout on external call
import scala.concurrent.duration._

val bidFuture = adExchange.submitBid(request)
bidFuture.withTimeout(100.millis)(system.scheduler)
```

---

## Avoid Blocking in Async Code

**Use `blocking` for unavoidable blocking.** Never block the default EC with `Await.result` in request handlers.

```scala
// Bad: Blocks default EC
val result = Await.result(future, 5.seconds)

// Good: Use blocking {} for known blocking calls
Future {
  blocking {
    jdbcConnection.execute(query)
  }
}(ioEC)
```

---

## Implement Graceful Shutdown

**Drain in-flight work.** Use Coordinated Shutdown (Akka/Play) or custom lifecycle. Do not kill threads abruptly.

```scala
// Good: Coordinated shutdown (Akka/Play)
CoordinatedShutdown(system).addTask(
  CoordinatedShutdown.PhaseServiceRequestsDone,
  "drain-connections"
) { () =>
  drainConnections()
}
```

---

## Use Bounded Concurrency for Unbounded Work

**Prevent unbounded resource consumption.** Use semaphores, bounded queues, or `Future.sequence` with chunking.

```scala
// Good: Bounded parallelism
def processWithLimit[A, B](items: List[A], limit: Int)(f: A => Future[B]): Future[List[B]] = {
  Future.sequence(
    items.grouped(limit).map(chunk => Future.sequence(chunk.map(f)))
  ).map(_.flatten)
}
```

---

## Validate Input at Boundaries

**Never trust external input.** Validate at API boundaries. Use typed wrappers with validation.

```scala
// Good: Validation at boundary
def parseUserId(s: String): Either[ValidationError, UserId] =
  if (s.nonEmpty && s.forall(_.isDigit)) Right(UserId(s.toLong))
  else Left(ValidationError("Invalid user ID"))
```

---

## Use Structured Logging with Context

**Enable correlation.** Pass request ID, trace ID, or correlation context through implicit parameters.

```scala
// Good: Implicit context for logging
def processRequest(req: Request)(implicit ctx: RequestContext): Future[Response] = {
  logger.info("Processing request", "request_id" -> ctx.requestId)
  // ...
}
```

See [Monitoring and Observability Patterns](monitoring-and-observability-patterns.md).

---

## Return Empty Collections, Not Null

**Callers should not null-check.** Return `Nil`, `Option.empty`, or `Either.Left` with explicit error.

```scala
// Good: Empty collection
def findActiveUsers(): List[User] =
  repository.findAll().filter(_.isActive)

// Good: Option for single result
def findUser(id: String): Option[User] =
  Option(repository.findById(id))
```

---

## Related Rules

- [Scala Efficient Future Management](../performance/scala-efficient-future-management.md) - EC pools, batching, timeouts
- [Future Error Handling Conventions](../language/future-error-handling-conventions.md) - Future[Either[E, A]]
- [Monitoring and Observability Patterns](monitoring-and-observability-patterns.md) - Logging, metrics
- [Error Handling Patterns](../language/error-handling-patterns.md) - Option, Either, Try

---

## References

- [Effective Scala](https://twitter.github.io/effectivescala/)
- [Scala Best Practices](https://nrinaudo.github.io/scala-best-practices/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
