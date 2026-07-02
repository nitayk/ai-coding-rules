# Cats Effect and ZIO Patterns

## Triggers

**APPLY WHEN:** Using Cats Effect or ZIO, choosing between effect systems, writing effectful code.
**SKIP WHEN:** Using only Future, or effect system already established.

---

## Core Directive

**Pick one effect system per codebase.** Use Resource/bracket for cleanup. Model errors in the effect type. Do not mix Future with IO/ZIO in the same layer.

---

## When to Use Which

| Use | When |
|-----|------|
| **Future** | Legacy code, simple async, minimal dependencies, team not familiar with FP |
| **Cats Effect IO** | Typelevel ecosystem, existing Cats usage, shared libraries |
| **ZIO** | New projects, rich error handling, ZLayer, built-in retry/timeout |

---

## ZIO Patterns

### 1. Effect as Blueprint

ZIO values are descriptions, not execution. Compose effects; run at the boundary.

```scala
// Good: Compose effects, run at boundary
def fetchUser(id: UserId): ZIO[Database, DbError, User] = ???
def validateUser(user: User): ZIO[Any, ValidationError, ValidUser] = ???

val program: ZIO[Database, AppError, ValidUser] = for {
  user <- fetchUser(userId)
  valid <- validateUser(user)
} yield valid

// Run at application boundary
Runtime.default.unsafeRun(program.provideLayer(databaseLayer))
```

### 2. Error Type in Signature

Use `ZIO[R, E, A]` - E is the error type. Prefer domain errors over Throwable.

```scala
// Good: Typed errors
def processOrder(order: Order): ZIO[OrderService, OrderError, OrderResult] = ???

// Bad: Throwable loses domain semantics
def processOrder(order: Order): ZIO[OrderService, Throwable, OrderResult] = ???
```

### 3. ZLayer for Dependencies

Use ZLayer for dependency injection. Compose layers; acquire/release is automatic.

```scala
// Good: ZLayer for dependency injection
val databaseLayer: ZLayer[Any, DbError, Database] = ZLayer.scoped {
  ZIO.acquireRelease(acquireDb)(_.close())
}

val appLayer = databaseLayer ++ loggingLayer
val program = fetchUser(userId).provideLayer(appLayer)
```

### 4. Resource Safety with acquireRelease

Use `ZIO.acquireReleaseWith` or `ZIO.scoped` for resources.

```scala
// Good: Resource guaranteed release
def withConnection[A](f: Connection => A): ZIO[Any, DbError, A] =
  ZIO.acquireReleaseWith(
    ZIO.attempt(connectionPool.getConnection()).mapError(DatabaseError.ConnectionError)
  )(
    conn => ZIO.succeed(conn.close())
  )(conn => ZIO.attempt(f(conn)).mapError(DatabaseError.QueryError))
```

### 5. Do Not Nest ZIO in yield

Avoid returning ZIO from for-comprehension yield. Use flatMap.

```scala
// Bad: Nested ZIO in yield
for {
  id <- getUserId
  user <- fetchUser(id)
} yield fetchProfile(user)  // Returns ZIO[..., Profile], not Profile

// Good: flatMap for sequential effects
for {
  id <- getUserId
  user <- fetchUser(id)
  profile <- fetchProfile(user)
} yield profile
```

---

## Cats Effect Patterns

### 1. IO for Deferred Effects

IO wraps side effects. Use `IO.delay` or `IO.blocking` for blocking work.

```scala
// Good: IO for side effects
def readConfig(path: String): IO[Config] =
  IO.blocking(readFile(path)).flatMap(parseConfig)

// IO.blocking for blocking I/O - uses dedicated thread pool
```

### 2. Resource for Cleanup

Use `Resource` for acquire/release. Guarantees release even on failure.

```scala
// Good: Resource for safe cleanup
val resource: Resource[IO, Connection] = Resource.make(
  acquire = IO.blocking(connectionPool.getConnection())
)(
  release = conn => IO.blocking(conn.close())
)

resource.use { conn =>
  executeQuery(conn, query)
}
```

### 3. IOApp for Entry Point

Use `IOApp.Simple` or `IOApp` for main. Handles runtime and shutdown.

```scala
// Good: IOApp for application entry
object Main extends IOApp.Simple {
  def run: IO[Unit] =
    program.provide(configLayer)
}
```

### 4. Use IO.cede for CPU-Bound Loops

In tight CPU loops, yield to other fibers with `IO.cede`.

```scala
// Good: Fairness in CPU-bound work
def processLargeList(items: List[Item]): IO[List[Result]] =
  items.traverse { item =>
    processItem(item) <* IO.cede  // Yield after each item
  }
```

---

## Common Patterns

### Do Not Mix Effect Systems

Pick one effect system per service or module. Do not wrap Futures in IO or vice versa.

```scala
// Bad: Mixing Future and ZIO
def mixedEffects(id: String): Future[ZIO[Any, Error, User]] = ???

// Good: Single effect system
def fetchUser(id: String): ZIO[Database, DbError, User] = ???
```

### Error Handling in Effect Type

Model recoverable errors in the effect type. Use `mapError` to transform.

```scala
// Good: Domain errors in type
sealed trait AppError
case class NotFound(id: String) extends AppError
case class ValidationError(msg: String) extends AppError

def fetchUser(id: String): ZIO[Database, AppError, User] =
  db.findUser(id).mapError {
    case DbError.NotFound => NotFound(id)
    case e => ValidationError(e.getMessage)
  }
```

### Testability

Effects are values. Provide test implementations via layers or type classes.

```scala
// Good: Testable with fake layer
val testDbLayer = ZLayer.succeed(new Database {
  override def findUser(id: String): IO[Option[User]] = IO.pure(Some(testUser))
})

val testProgram = program.provideLayer(testDbLayer)
```

---

## Related Rules

- [Future Error Handling Conventions](future-error-handling-conventions.md) - Future[Either[E, A]], EitherT
- [Scala Efficient Future Management](../performance/scala-efficient-future-management.md) - When to consider ZIO over Future
- [Referential Transparency](referential-transparency.md) - Pure functions, effect boundaries
- [Validation and Safe Operations](validation-and-safe-operations.md) - ZIO validation with accumulation

---

## References

- [ZIO Coding Guidelines](https://zio.dev/coding-guidelines) - ZIO 2.1 current line
- [Cats Effect documentation](https://typelevel.org/cats-effect/) - landing page
- [Cats Effect versions](https://typelevel.org/cats-effect/versions) - **3.6.x** is the current line (Scala Native multithreading on LLVM)
- [Cats Effect 3 Resource & IOApp Patterns](cats-effect-3-resource-patterns.md) - in-repo deep dive on CE 3.6+ specifics
- [Cats Effect Resource Handling](https://www.baeldung.com/scala/cats-effect-resource-handling) - supplemental walkthrough

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
