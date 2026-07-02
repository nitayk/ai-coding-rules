# Swift Testing framework (@Test / #expect / @Suite)

Swift Testing is Apple's macro-based replacement for XCTest. It ships **bundled with Xcode 16+** (and as a SwiftPM dependency for older Xcode), runs alongside XCTest in the same target, and is the recommended framework for **new** test code. XCTest remains supported for existing suites and is still required for UI tests (`XCUIApplication`) and performance tests (`measure`).

This file covers the framework's primary primitives and an incremental migration path. Day-to-day mocking, ViewModel test patterns, and SwiftUI-specific testing patterns live in `swift-testing.md` (sibling file).

Source: [Apple Swift Testing landing](https://developer.apple.com/xcode/swift-testing/) · [WWDC24 "Meet Swift Testing" (10179)](https://developer.apple.com/videos/play/wwdc2024/10179/) · [swiftlang/swift-testing](https://github.com/swiftlang/swift-testing).

---

## @Test and #expect replace XCTest functions and assertions

A test is a free function or method annotated `@Test`. Assertions use the `#expect` macro (non-fatal) or `#require` (fatal — short-circuits the test).

```swift
// ✅ Good: Swift Testing — free function, no class boilerplate
import Testing

@Test func userInitialization() {
    let user = User(id: "1", name: "Alice")
    #expect(user.id == "1")
    #expect(user.name == "Alice")
}

// ✅ Good: #require for preconditions that must hold to continue
@Test func decodingProducesUser() throws {
    let data = try #require(sampleJSON.data(using: .utf8))
    let user = try JSONDecoder().decode(User.self, from: data)
    #expect(user.name == "Alice")
}
```

```swift
// ❌ Bad: mixing XCTest and Swift Testing assertion styles in the same test
@Test func userInitialization() {
    let user = User(id: "1", name: "Alice")
    XCTAssertEqual(user.id, "1")  // XCTest assertion in a @Test — won't fail correctly
}
```

`#expect` produces rich failure messages by re-evaluating the expression — no `XCTAssertEqual` / `XCTAssertGreaterThan` zoo to memorize. Use a normal Swift expression (`==`, `>`, `contains`, etc.) and the macro reports both sides on failure.

---

## @Suite groups related tests and shares setup via init/deinit

A `@Suite` is a struct, class, or actor whose stored properties are the per-test fixture. **Swift Testing constructs a fresh instance per test** — no `setUp` / `tearDown` static-state contamination. Use `init` for setup, `deinit` for teardown.

```swift
// ✅ Good: per-test fixture via init; isolation via the type
@Suite("User repository")
struct UserRepositoryTests {
    let mockService: MockUserService
    let repo: UserRepository

    init() {
        mockService = MockUserService()
        repo = UserRepository(service: mockService)
    }

    @Test func fetchHitsService() async throws {
        _ = try await repo.fetch(id: "1")
        #expect(mockService.fetchCallCount == 1)
    }

    @Test func cacheReturnsSecondCall() async throws {
        _ = try await repo.fetch(id: "1")
        _ = try await repo.fetch(id: "1")
        #expect(mockService.fetchCallCount == 1)  // cached
    }
}
```

```swift
// ❌ Bad: XCTestCase-style shared mutable state across tests
final class UserRepositoryTests: XCTestCase {
    static var repo: UserRepository!  // shared — order-dependent flakiness
    override class func setUp() { repo = UserRepository(service: MockUserService()) }
}
```

Suites can nest (`@Suite` types declared inside other `@Suite` types) and inherit traits — useful for "all tests in this suite need a MainActor" or "tag these as integration tests".

---

## Parameterized tests — one declaration, many cases

`@Test(arguments:)` runs the same test body for each argument, with per-case reporting in the Xcode test navigator.

```swift
// ✅ Good: one test, many cases, individually reported
@Test(arguments: [
    ("alice@example.com", true),
    ("bob@example.org", true),
    ("not-an-email", false),
    ("", false),
])
func validateEmail(input: String, expected: Bool) {
    #expect(EmailValidator.isValid(input) == expected)
}

// ✅ Good: zipped arguments for paired inputs
@Test(arguments: zip([1, 2, 3], ["one", "two", "three"]))
func numberToWord(n: Int, word: String) {
    #expect(NumberFormatter.spell(n) == word)
}
```

```swift
// ❌ Bad: hand-rolled loop inside one test — failures aren't individually reported
@Test func validateEmails() {
    for (input, expected) in cases {
        #expect(EmailValidator.isValid(input) == expected)  // first failure hides the rest
    }
}
```

---

## Traits: tags, conditional runs, time limits, serialization

Traits modify how a test runs. Pass them after the test name in `@Test(...)` or `@Suite(...)`.

```swift
import Testing

// Tag tests for filtering: `swift test --filter .integration`
extension Tag {
    @Tag static var integration: Self
    @Tag static var slow: Self
}

@Test(.tags(.integration, .slow))
func endToEndAuctionFlow() async throws { /* … */ }

// Skip a test conditionally
@Test(.disabled("Awaiting backend fix — JIRA-1234"))
func brokenForNow() { }

@Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_NETWORK_TESTS"] == "1"))
func networkRequest() async throws { /* … */ }

// Cap runtime
@Test(.timeLimit(.minutes(1)))
func longComputation() async { /* … */ }

// Force suite tests to run serially (default is parallel in Swift Testing)
@Suite(.serialized)
struct DatabaseMigrationTests { /* tests mutate shared on-disk DB */ }
```

Parallel-by-default is a behavioral shift from XCTest — tests that share file paths, network ports, or process-wide state need `.serialized` or per-test sandboxing.

---

## MainActor and async tests work naturally

Async test bodies are first-class — no `expectation` / `wait(for:)` ceremony. Annotate the test or suite with `@MainActor` when touching UI state.

```swift
// ✅ Good: async test, MainActor-isolated suite
@MainActor
@Suite struct FeedViewModelTests {
    @Test func loadPopulatesItems() async throws {
        let vm = FeedViewModel(api: MockAPI(items: [.sample]))
        await vm.load()
        #expect(vm.items.count == 1)
    }
}
```

---

## Migration: run XCTest and Swift Testing side-by-side

You do not need to rewrite your suite to adopt Swift Testing — both run in the same test target. Migrate file-by-file as you touch them.

| Step | Action |
|---|---|
| 1 | Bump deployment to Xcode 16+ (or add `swift-testing` SwiftPM dep for older Xcode) |
| 2 | Write all **new** tests as `@Test` / `@Suite` |
| 3 | When editing an existing XCTest file, convert that file (don't touch its neighbors) |
| 4 | Keep `XCTestCase` for UI tests (`XCUIApplication`) and `measure` performance tests — Swift Testing doesn't replace those yet |
| 5 | Delete the XCTest target only when zero `XCTAssert*` calls remain |

Common XCTest → Swift Testing mappings:

| XCTest | Swift Testing |
|---|---|
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertTrue(x)` / `XCTAssertFalse(x)` | `#expect(x)` / `#expect(!x)` |
| `XCTAssertThrowsError(try f())` | `#expect(throws: MyError.self) { try f() }` |
| `XCTUnwrap(opt)` | `try #require(opt)` |
| `XCTFail("msg")` | `Issue.record("msg")` |
| `setUp()` / `tearDown()` | `init()` / `deinit` on `@Suite` type |
| `XCTSkip("reason")` | `@Test(.disabled("reason"))` or `withKnownIssue` |

---

## Related rules

- [Swift testing patterns](swift-testing.md) — mocking, ViewModel testing, SwiftUI patterns (framework-agnostic)
- [Swift Concurrency Patterns](../language/swift-concurrency-patterns.md) — async/await idioms used in test bodies

---

## References

- [Apple Swift Testing landing](https://developer.apple.com/xcode/swift-testing/)
- [WWDC24 "Meet Swift Testing" (10179)](https://developer.apple.com/videos/play/wwdc2024/10179/)
- [swiftlang/swift-testing](https://github.com/swiftlang/swift-testing) — source repo, full API docs

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
