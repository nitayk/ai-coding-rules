---
name: scala-testing
description: "Use when writing Scala tests (*Test.scala, *Spec.scala), reviewing test code, or code review involves test files. Covers ScalaTest (FlatSpec / AsyncFlatSpec), ScalaCheck property tests, async patterns, and common pitfalls. Do NOT use for non-Scala tests, quick syntax fixes, or when user explicitly requests a different testing approach."
last-reviewed: 2026-05-20
---

# Scala Testing

## Core Principles

### Pure tests
Tests must be pure: no shared mutable state, deterministic outcomes, no order dependencies. A test that passes alone but fails in a suite (or vice versa) is broken.

### Behavior-focused names
Test name describes the *observable behavior*, not the implementation. `"returns 404 when user does not exist"` not `"testGetUser_negativeCase_2"`.

### Async without blocking
Never `Await.result(...)` in tests — use `AsyncFlatSpec` and `map`/`flatMap` over the `Future`. Blocking on Futures masks deadlocks and slows the suite ~10×.

### Property tests where invariants exist
For functions with mathematical invariants (associativity, idempotence, round-trip), prefer `forAll` over example-based tests.

## Examples

### Sync — `AnyFlatSpec` with matchers

```scala
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class CalculatorSpec extends AnyFlatSpec with Matchers {

  // Fresh SUT per test — no shared state
  def newCalc = new Calculator()

  "Calculator.add" should "return the sum of two positive integers" in {
    newCalc.add(2, 3) shouldBe 5
  }

  it should "handle negatives" in {
    newCalc.add(-1, -1) shouldBe -2
  }
}
```

### Async — `AsyncFlatSpec` with `map`

```scala
import org.scalatest.flatspec.AsyncFlatSpec
import org.scalatest.matchers.should.Matchers
import scala.concurrent.Future

class UserServiceSpec extends AsyncFlatSpec with Matchers {

  def newService = new UserService(repo = new InMemoryUserRepo)

  "fetchUser" should "return the user when it exists" in {
    val svc = newService
    svc.repo.put(User(id = 1, name = "Ada"))
    svc.fetchUser(1).map { result =>
      result shouldBe Some(User(1, "Ada"))
    }
    // returns Future[Assertion] — ScalaTest awaits internally
  }

  it should "return None when the user is missing" in {
    newService.fetchUser(999).map { _ shouldBe None }
  }
}
```

**Anti-pattern:** `Await.result(svc.fetchUser(1), 5.seconds) shouldBe ...` — blocks the test thread, hides timeouts, defeats `AsyncFlatSpec`.

### Property — ScalaCheck `forAll`

```scala
import org.scalatest.propspec.AnyPropSpec
import org.scalatestplus.scalacheck.ScalaCheckPropertyChecks

class Base64Spec extends AnyPropSpec with ScalaCheckPropertyChecks {

  property("encode then decode is identity for any byte array") {
    forAll { (bytes: Array[Byte]) =>
      Base64.decode(Base64.encode(bytes)) shouldBe bytes
    }
  }

  property("encoded length is at least the input length") {
    forAll { (bytes: Array[Byte]) =>
      Base64.encode(bytes).length should be >= bytes.length
    }
  }
}
```

Use `forAll` when you can articulate an invariant. Don't replace specific edge-case tests with `forAll` — both have a place.

### Mocks without mutable state

```scala
// BAD — shared mutable counter, race-prone, order-dependent
class FlakyMock extends UserRepo {
  var calls = 0
  def fetch(id: Long): Future[Option[User]] = {
    calls += 1
    Future.successful(if (id == 1) Some(User(1, "Ada")) else None)
  }
}

// GOOD — pure factory, behavior parameterized per test
def fakeRepo(stored: Map[Long, User] = Map.empty): UserRepo = new UserRepo {
  def fetch(id: Long): Future[Option[User]] = Future.successful(stored.get(id))
}
```

## Common failure modes

- **Blocking on Futures** — `Await.result` in tests. Switch to `AsyncFlatSpec` + `map`.
- **Mutable mock state shared across tests** — replace with pure factory + per-test SUT.
- **Order-dependent tests** — usually a sign of leaked global state (singletons, system properties, mutable companion-object vals). Run with `runner.parallel = true` to surface.
- **Missing `tag`s on slow tests** — long-running integration tests should be `taggedAs(Slow)` so the unit-test run stays fast.
- **`shouldBe` on `Future` directly** — `future shouldBe expected` will compare the `Future` instance, not its result. Always `.map { result => result shouldBe expected }`.
- **Implicit `ExecutionContext` confusion** — in `AsyncFlatSpec`, ScalaTest provides one; don't import the global EC and shadow it.
- **Collection equality with `Array`** — `Array.equals` is reference equality. Use `.toSeq` or `should contain theSameElementsAs ...`.
- **Mocking too much** — if every dependency is a mock, you're testing the mocks. Real in-memory implementations (e.g. `InMemoryUserRepo`) read better and catch more bugs.

## Workflow

1. **Find the right base trait** — `AnyFlatSpec` for sync, `AsyncFlatSpec` for `Future`-returning code, `AnyPropSpec` for property tests
2. **Build a fresh SUT factory** — function or `def` that returns a clean instance per test
3. **Name the test by observable behavior** — what the caller sees, not what the implementation does
4. **One assertion per behavior** — multiple `shouldBe` per test only when they describe the same behavior
5. **Run alone, then in suite** — both must pass; if alone-pass + suite-fail, you have hidden state
6. **For invariant code, add a `forAll`** — alongside example tests, not replacing them

## Pair with

- `/scala-dependency-hell` — when a test failure is actually a dep-resolution issue (`NoClassDefFoundError`, version skew)
- `/test-until-pass` — when a test is genuinely flaky and you need a bounded retry loop with diagnostics

## Success criteria

Before completing:
- Tests are pure (no shared mutable state)
- Async uses `AsyncFlatSpec` + `map`, no `Await.result`
- Test names describe behavior, not implementation
- Tests pass both alone and in the full suite
- Property tests added where invariants exist

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
