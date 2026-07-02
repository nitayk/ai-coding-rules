# Scala More Best Practices

- Use **property-based testing** (`ScalaCheck`, `Arbitrary`) instead of relying solely on example-based tests.  
- Prefer `forAll` with automatic shrinking to improve coverage and catch edge cases.  
- Tag slow-running properties with annotations like `@Slow` for CI filtering.  
- Example:
  ```scala
  import org.scalacheck.Prop.forAll

  property("reverse twice is identity") = forAll { (xs: List[Int]) =>
    xs.reverse.reverse == xs
  }
  ```
- Use implicits only for:  
  - Type classes (`Ordering[Int]`, `Encoder[User]`)  
  - Contextual abstractions (`Clock`, `Logger`, `RequestId`)  
- **Avoid implicits for primitive types** (`String`, `Int`) unless wrapped in a value or case class.  
- Prevent ambiguous implicits and avoid using implicits for global mutable state.  

- Good:
  ```scala
  case class RequestId(value: String)

  def log(msg: String)(implicit reqId: RequestId): Unit =
    println(s"[$reqId] $msg")
  ```

- Bad:
  ```scala
  implicit val defaultString: String = "danger" // Avoid


- Use **2-space indentation** consistently.  
- Avoid mixing **tabs and spaces**.  
- Maximum line length: **120 characters**.  
- Use tools like `scalafmt` or `scapegoat` to auto-enforce formatting.  

- Example:
  ```scala
  def process(
    input: String,
    config: Config
  ): Either[Error, Result] =
    for
      parsed    <- parse(input)
      validated <- validate(parsed)
    yield transform(validated, config)
  ```

- Audit dependencies regularly for unused or conflicting versions.  
- Use `sbt` plugins like:  
  - `sbt-explicit-dependencies`  
  - `sbt-dependency-graph`  
- Recommended routine tasks:  
  - `sbt evicted` – detect version conflicts  
  - `sbt unusedCompileDependencies` – find unused dependencies  
  - `sbt dependencyTree` – visualize dependency graph  
- Prefer `%%` to ensure Scala version alignment.  
- Avoid overusing `dependencyOverrides`.  
- **Prune unused dependencies weekly** to keep the build clean.

- **Use typed wrappers (tiny types) instead of primitives** for domain concepts:  
  ```scala
  // Bad: Primitive obsession - easy to mix up IDs
  def createUser(userId: Int, appId: Int, postId: Int): User = ???
  
  // Good: Typed wrappers - compiler prevents mixing up IDs
  case class UserId(value: Int) extends AnyVal
  case class AppId(value: Int) extends AnyVal
  case class PostId(value: Int) extends AnyVal
  
  def createUser(userId: UserId, appId: AppId, postId: PostId): User = ???
  ```
  
- **Add validation to typed wrappers** when appropriate:  
  ```scala
  case class PositiveNumber(value: Int) extends AnyVal {
    require(value > 0, "Must be positive")
  }
  
  // Or with smart constructor
  case class AgeOver18(value: Int) extends AnyVal
  object AgeOver18 {
    def apply(value: Int): Option[AgeOver18] = {
      if (value >= 18) Some(new AgeOver18(value))
      else None
    }
  }
  ```
  
- **See [Compiler-Friendly Types](compiler-friendly-types.md)** for comprehensive guidance on typed wrappers, avoiding casts, and leveraging the compiler.

- **Use @tailrec for recursive functions** - Ensures tail-call optimization and prevents stack overflow:
  ```scala
  // Good: Tail-recursive with @tailrec
  import scala.annotation.tailrec

  @tailrec
  def sum(list: List[Int], acc: Int = 0): Int = list match {
    case Nil => acc
    case h :: t => sum(t, acc + h)
  }

  // Bad: Non-tail-recursive (no @tailrec, may stack overflow)
  def sum(list: List[Int]): Int = list match {
    case Nil => 0
    case h :: t => h + sum(t)
  }
  ```

- **Use Scalafix and Scalafmt** - Enforce code standards and consistent formatting:
  - Scalafix: `DisableSyntax` to disable `var`, `throws`, `null`; custom rules for refactoring
  - Scalafmt: 2-space indentation, 120 char line length, consistent style
  - Integrate with CI: `scalafix --check`, `scalafmt --check`

---

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../../../generic/code-quality/core-principles.md) - Universal principles (SOLID, DRY, KISS, YAGNI, correctness first)
- [Generic Testing Principles](../../../../generic/testing/core-principles.md) - Universal testing principles (property-based testing)

**Scala-Specific:**
- [Compiler-Friendly Types](compiler-friendly-types.md) - Comprehensive guidance on typed wrappers, avoiding casts

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
