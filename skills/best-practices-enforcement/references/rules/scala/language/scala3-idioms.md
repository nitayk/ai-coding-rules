# Scala 3 idioms cheatsheet

Scala 3 reshaped the contextual-abstractions story (`implicit` is mostly gone), added first-class `enum`, `opaque type`, and quiet/indented syntax. This rule is a mapping reference — what to write in new Scala 3 code, and what to flag in code review when 2.13 idioms leak forward.

Sources: [Scala 3 Reference — Contextual Abstractions](https://docs.scala-lang.org/scala3/reference/contextual/), [Scala 3 Migration: tooling tour](https://docs.scala-lang.org/scala3/guides/migration/tooling-tour.html).

---

## Core Directive

**In Scala 3 code, prefer `given`/`using` over `implicit`, `extension` over implicit classes, `enum` over manual sealed-trait + object hierarchies, and `opaque type` over value classes.** When cross-building, use `Scala213Source3` and write the shared subset.

---

## Idiom mapping table

| 2.13 idiom | Scala 3 idiom | Why |
|---|---|---|
| `implicit val x: T` | `given T = ...` | Distinguishes term from import; cleaner derivation |
| `implicit def f(x: A): B` (conversion) | `given Conversion[A, B] = ...` | Conversions are now opt-in via the `Conversion` typeclass |
| `implicit class FooOps(val a: A)` | `extension (a: A) def ...` | No wrapper class allocated; clearer call site |
| `def f(implicit ec: EC): T` | `def f(using ec: EC): T` | `using`/`given` symmetry |
| `sealed trait X; case object A; case object B` | `enum X { case A, B }` | Built-in `values`, `valueOf`, ordinal |
| `case class UserId(value: String) extends AnyVal` | `opaque type UserId = String` | No boxing edge cases; type-only at compile time |
| `f(implicitly[T])` | `f(summon[T])` | `summon` replaces `implicitly` |
| Type lambda via Kind-Projector `λ[X => F[X]]` | `[X] =>> F[X]` | First-class, no plugin |
| `import x._` | `import x.*` | Wildcard is `*` |

---

## Pattern: given / using

✅ Good — Scala 3:

```scala
trait Show[A]:
  def show(a: A): String

given Show[Int] with
  def show(a: Int): String = a.toString

given Show[String] with
  def show(a: String): String = s"\"$a\""

def render[A](a: A)(using s: Show[A]): String = s.show(a)

// Call site
render(42)
render("hello")
```

❌ Bad — leaking 2.13 implicit style into a Scala 3 file:

```scala
trait Show[A] { def show(a: A): String }
object Show {
  implicit val showInt: Show[Int] = (a: Int) => a.toString
  implicit val showString: Show[String] = (a: String) => s"\"$a\""
}
def render[A](a: A)(implicit s: Show[A]): String = s.show(a)
```

The 2.13 version still compiles in Scala 3, but it bypasses the new derivation primitives and confuses reviewers about which era the code targets.

### Anonymous givens

```scala
// Good — when only one instance is sensible, drop the name
given Ordering[UserId] = Ordering.by(_.value)

// Less good — named when not needed clutters auto-import
given userIdOrdering: Ordering[UserId] = Ordering.by(_.value)
```

---

## Pattern: extension methods

✅ Good:

```scala
extension (s: String)
  def isHttp: Boolean = s.startsWith("http://") || s.startsWith("https://")
  def asUri: java.net.URI = java.net.URI.create(s)

"https://example.com".isHttp  // true
```

❌ Bad — implicit class in Scala 3 file (allocates wrapper, harder to read):

```scala
implicit class StringOps(val s: String) extends AnyVal {
  def isHttp: Boolean = s.startsWith("http")
}
```

### With type parameters

```scala
extension [A](list: List[A])
  def secondOption: Option[A] = list.drop(1).headOption
```

---

## Pattern: enum

✅ Good — Scala 3 `enum`:

```scala
enum HttpMethod:
  case Get, Post, Put, Delete

enum Json:
  case JNull
  case JBool(b: Boolean)
  case JNum(n: Double)
  case JStr(s: String)
  case JArr(items: List[Json])
  case JObj(fields: Map[String, Json])

// Built in:
HttpMethod.values          // Array[HttpMethod]
HttpMethod.valueOf("Get")  // HttpMethod.Get
HttpMethod.Get.ordinal     // 0
```

❌ Bad — hand-rolled when an `enum` would do:

```scala
sealed trait HttpMethod
object HttpMethod {
  case object Get extends HttpMethod
  case object Post extends HttpMethod
  case object Put extends HttpMethod
  case object Delete extends HttpMethod
  val values: List[HttpMethod] = List(Get, Post, Put, Delete)
}
```

**Caveat**: when you need custom companion methods on each case, or non-trivial inheritance, stick with sealed traits. See [Scala Complex Enum Best Practices](../data/scala-complex-enum-best-practices.md).

---

## Pattern: opaque types

✅ Good — zero-runtime-cost newtype:

```scala
object ids:
  opaque type UserId = String
  object UserId:
    def apply(s: String): UserId = s
    extension (id: UserId) def value: String = id

  opaque type OrderId = String
  object OrderId:
    def apply(s: String): OrderId = s
    extension (id: OrderId) def value: String = id

import ids.*

def lookupUser(id: UserId): Option[User] = ???
// lookupUser(OrderId("x"))  // ❌ compile error — exactly what we want
```

❌ Bad — value class with all its boxing footguns:

```scala
case class UserId(value: String) extends AnyVal
```

Value classes box in many situations (pattern match, generic context, Array element). Opaque types do not — they vanish at compile time.

---

## Pattern: indented vs braced syntax

Scala 3 allows indented "quiet" syntax. Both styles are valid; **pick one per repo and enforce via Scalafmt** (`rewrite.scala3.removeOptionalBraces = yes` or `no`).

```scala
// Indented
class Foo:
  def bar: Int =
    val x = 1
    x + 1

// Braced
class Foo {
  def bar: Int = {
    val x = 1
    x + 1
  }
}
```

There is **no objective winner**. Mixed-style files are the failure mode — Scalafmt should normalise.

---

## Cross-building 2.13 ↔ 3 (`Scala213Source3`)

When the same source compiles under both:

```scala
// project/Build.scala
crossScalaVersions := Seq("2.13.18", "3.6.0")
scalacOptions ++= {
  CrossVersion.partialVersion(scalaVersion.value) match {
    case Some((2, 13)) => Seq("-Xsource:3")           // 2.13 honours Scala 3 syntax
    case Some((3, _))  => Seq("-source:3.0-migration") // 3 accepts 2.13 idioms with warnings
    case _             => Nil
  }
}
```

In the shared sources: stick to the **2.13 syntax subset** that Scala 3 also accepts. Use `sbt-scala3-migrate` to surface the diffs ([migration tour](https://docs.scala-lang.org/scala3/guides/migration/tooling-tour.html)).

---

## Common code-review flags

| Sighting in a Scala 3 file | Fix |
|---|---|
| `implicit val foo: T = ...` | `given T = ...` |
| `def f(implicit ec: EC)` | `def f(using ec: EC)` |
| `import scala.language.implicitConversions` | Replace with a named `given Conversion[A, B]` |
| `case class UserId(v: String) extends AnyVal` | `opaque type UserId = String` |
| `implicit class FooOps(...)` | `extension (foo: Foo) ...` |
| `implicitly[T]` | `summon[T]` |
| `import x._` | `import x.*` (style consistency) |

---

## Related Rules

- [Compiler-Friendly Types](compiler-friendly-types.md) — opaque types are the strongest "stop lying to compiler" tool in Scala 3
- [Make Illegal States Unrepresentable](make-illegal-states-unrepresentable.md) — `enum` is the Scala 3 expression of this
- [Scala Complex Enum Best Practices](../data/scala-complex-enum-best-practices.md) — when to keep sealed traits over `enum`
- [Scala Code Style](../meta/scala-code-style.md) — indent vs brace decision

---

## References

- [Scala 3 Reference — Contextual Abstractions](https://docs.scala-lang.org/scala3/reference/contextual/) — `given`, `using`, `extension`, conversions
- [Scala 3 Reference — Enums](https://docs.scala-lang.org/scala3/reference/enums/enums.html)
- [Scala 3 Reference — Opaque Types](https://docs.scala-lang.org/scala3/reference/other-new-features/opaques.html)
- [Scala 3 Migration: tooling tour](https://docs.scala-lang.org/scala3/guides/migration/tooling-tour.html) — `sbt-scala3-migrate`, source levels
- [Scala 3 Migration Compatibility](https://docs.scala-lang.org/scala3/guides/migration/compatibility-intro.html)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
