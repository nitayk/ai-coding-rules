# Cats Effect 3.6 — Resource and IOApp patterns

The Cats Effect **3.6.x** line (current as of May 2026) is the recommended Typelevel runtime. The most notable shifts since 3.5.x are **Scala Native multithreading on LLVM**, refined `Async` / `Cont` semantics, and clearer guidance on `Resource` composition.

This rule covers the patterns that compose well today. For the underlying type-class hierarchy see the upstream tutorial; this is the in-codebase quick reference.

Sources: [Cats Effect documentation](https://typelevel.org/cats-effect/), [Cats Effect versions](https://typelevel.org/cats-effect/versions), [Cats Effect releases](https://github.com/typelevel/cats-effect/releases).

---

## Core Directive

**Every effect that owns external state should be a `Resource[IO, A]`. Every entry point should be an `IOApp`. Never call `unsafeRun*` in library or service code — that's an `IOApp` responsibility.**

---

## Resource — acquire/release that always releases

`Resource[F, A]` guarantees `release` runs even on error or fiber cancellation. Use it for everything that has a lifecycle: sockets, files, DB pools, HTTP clients, kafka producers, executors.

✅ Good — `Resource.make`:

```scala
import cats.effect.{IO, Resource}

def connection(url: String): Resource[IO, java.sql.Connection] =
  Resource.make(
    acquire = IO.blocking(java.sql.DriverManager.getConnection(url))
  )(
    release = conn => IO.blocking(conn.close()).handleErrorWith(_ => IO.unit)
  )

connection("jdbc:postgresql://...").use { conn =>
  IO.blocking(conn.createStatement().executeQuery("SELECT 1"))
}
```

❌ Bad — manual try/finally inside `IO`:

```scala
def fetch(): IO[Int] = IO.blocking {
  val conn = DriverManager.getConnection("...")
  try {
    val rs = conn.createStatement().executeQuery("SELECT 1")
    rs.next(); rs.getInt(1)
  } finally conn.close()   // close not guaranteed under cancellation
}
```

Under fiber cancellation the `IO.blocking` block can be interrupted **before** `finally` runs. `Resource` handles cancellation correctly.

### Composing resources

```scala
val program: Resource[IO, AppDeps] =
  for
    pool   <- connectionPool(config.db)
    client <- httpClient(config.http)
    queue  <- kafkaProducer(config.kafka)
  yield AppDeps(pool, client, queue)

program.use(deps => runApp(deps))
```

Resources release in **reverse acquisition order** — exactly what you want for shutdown.

### `Resource.eval` vs `Resource.pure`

```scala
Resource.eval(IO.pure(42))    // run an effect during acquisition; no release
Resource.pure[IO, Int](42)    // pure value lifted; no acquisition effect
```

Don't reach for `Resource.make` when you don't actually own state to release.

---

## IOApp — the right entry point

The IOApp variants in 3.6.x:

| Variant | Use when |
|---|---|
| `IOApp.Simple` | `def run: IO[Unit]` — no args, no exit code |
| `IOApp` | `def run(args: List[String]): IO[ExitCode]` — full control |

✅ Good — `IOApp.Simple` for simple services:

```scala
import cats.effect.{IO, IOApp}

object Main extends IOApp.Simple:
  def run: IO[Unit] =
    appResource.use(_.serve)
```

✅ Good — `IOApp` when you need args or exit codes:

```scala
import cats.effect.{ExitCode, IO, IOApp}

object Main extends IOApp:
  def run(args: List[String]): IO[ExitCode] =
    args match
      case Nil   => IO.println("usage: app <config>").as(ExitCode.Error)
      case c :: _ => loadConfig(c).flatMap(serve).as(ExitCode.Success)
```

❌ Bad — calling `unsafeRunSync` from a `main`:

```scala
object Main {
  def main(args: Array[String]): Unit = {
    import cats.effect.unsafe.implicits.global
    appResource.use(_.serve).unsafeRunSync()   // bypasses IOApp lifecycle
  }
}
```

This skips the runtime install, signal handlers, and graceful shutdown that `IOApp` sets up for you.

---

## Blocking work — `IO.blocking`, not `IO.delay`

```scala
IO.blocking(jdbcConnection.query("..."))   // ✅ dispatched onto blocking pool
IO.delay(jdbcConnection.query("..."))      // ❌ pins a compute-pool thread
```

`IO.blocking` shifts to the dedicated blocking executor; `IO.delay` doesn't. Tag every blocking JDBC, file I/O, sleeping, or third-party-library call accordingly.

---

## Structured concurrency — `parTraverse`, `Supervisor`

✅ Good — `parTraverseN` for bounded parallelism:

```scala
import cats.syntax.all.*

def fetchAll(ids: List[UserId]): IO[List[User]] =
  ids.parTraverseN(8)(fetchUser)   // max 8 concurrent
```

`parTraverse` (no `N`) is unbounded — fine for small lists, dangerous for large ones. Default to `parTraverseN` and pick a real limit.

For long-lived background work, use `Supervisor`:

```scala
import cats.effect.std.Supervisor

Supervisor[IO].use { sup =>
  for
    _ <- sup.supervise(metricsHeartbeat)
    _ <- sup.supervise(cacheRefresh)
    _ <- serve
  yield ()
}
```

Supervisor guarantees all supervised fibers are cancelled when the scope exits.

---

## Scala Native multithreading (3.6.x)

Cats Effect 3.6 ships **multithreaded LLVM** support for Scala Native ≥ 0.5. The same code that runs on the JVM runs on the native runtime — but **only with the multithreaded native runtime selected**:

```scala
// project.scala / build.sbt
nativeConfig ~= { _.withMultithreading(true) }
```

This is the headline 3.5 → 3.6 change and the reason CE bumped a minor version. If you target Scala Native, ensure multithreading is enabled — single-threaded native runtimes are deprecated in CE 3.6.

See the [CE 3.6.0 release notes](https://github.com/typelevel/cats-effect/releases/tag/v3.6.0) for the full list.

---

## Migration 3.5.x → 3.6.x

Most code requires no source changes. Things to check:

- **Scala Native users**: enable `withMultithreading(true)`; single-threaded path is being removed.
- **`Async` instance authors**: `Async#cont` signature was tightened — re-derive instances against the 3.6 API.
- **`Resource` users**: no breaking changes; `Resource.both` semantics clarified for `Sync` instances.
- **`IO.async` / `IO.async_`**: prefer `IO.async_` for one-shot callbacks; the runtime hint helps the scheduler.

Run `sbt update` and watch for `evicted` — fix per [sbt dependency management](../build/sbt-dependency-management.md).

---

## Anti-patterns

### `unsafeRunSync` inside library code

If a library exposes `def doThing(): T` that calls `io.unsafeRunSync()` internally, it traps callers — they cannot compose. Expose `def doThing: IO[T]` instead.

### Resource inside `IO.delay`

```scala
// ❌ Bad — the resource is acquired and immediately released
IO.delay(connection(url).use(query).unsafeRunSync())

// ✅ Good — keep the Resource shape all the way out
def runQuery: IO[Result] = connection(url).use(query)
```

### Mixing Future and IO in the same layer

See [Cats and ZIO Effect Patterns](cats-zio-effect-patterns.md) — pick one effect system per module. If you must bridge, `IO.fromFuture(IO(fut))` is the conversion point, not a regular pattern.

---

## Related Rules

- [Cats and ZIO Effect Patterns](cats-zio-effect-patterns.md) — when to pick CE vs ZIO vs Future
- [Future Error Handling Conventions](future-error-handling-conventions.md) — bridging into IO via `IO.fromFuture`
- [Scala Production Patterns](../meta/scala-production-patterns.md) — graceful shutdown wires into Resource release

---

## References

- [Cats Effect documentation](https://typelevel.org/cats-effect/) — landing page
- [Cats Effect versions](https://typelevel.org/cats-effect/versions) — 3.6.x is the current line
- [Cats Effect 3.6.0 release notes](https://github.com/typelevel/cats-effect/releases/tag/v3.6.0) — Scala Native multithreading, `Async`/`Cont` changes
- [Resource tutorial](https://typelevel.org/cats-effect/docs/std/resource) — full Resource API
- [IOApp tutorial](https://typelevel.org/cats-effect/docs/getting-started) — entry-point variants

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
