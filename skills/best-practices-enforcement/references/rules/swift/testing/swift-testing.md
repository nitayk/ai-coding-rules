# Swift Testing Patterns

## Triggers
**APPLY WHEN:** Writing unit tests, mocking dependencies, testing ViewModels, or testing SwiftUI views.
**SKIP WHEN:** Code does not require test coverage or tests already follow these patterns.

## Core Directive
**Test ViewModels and business logic first.** Use protocol-based dependency injection for mocking. Prefer async/await in tests over XCTestExpectation. Add `accessibilityIdentifier` for UI test discovery.

---

## Use Protocol Mocks for Dependencies

**Inject protocols and create mock implementations:**

```swift
// Good: Protocol for testable dependency
protocol UserService {
    func fetchUser(id: String) async throws -> User
}

class ViewModel {
    private let userService: UserService

    init(userService: UserService) {
        self.userService = userService
    }

    func loadUser(id: String) async throws {
        let user = try await userService.fetchUser(id: id)
        // ...
    }
}

// Test mock
class MockUserService: UserService {
    var fetchUserResult: Result<User, Error> = .failure(URLError(.badURL))

    func fetchUser(id: String) async throws -> User {
        try fetchUserResult.get()
    }
}
```

```swift
// Bad: Hardcoded dependency - cannot mock
class ViewModel {
    private let userService = ApiUserService()

    func loadUser(id: String) async throws {
        let user = try await userService.fetchUser(id: id)
        // Real network calls in tests
    }
}
```

---

## Use Async/Await in Tests

**Mark test methods as `async` and await directly:**

```swift
// Good: Async test without XCTestExpectation
func testLoadUser() async throws {
    let mock = MockUserService()
    mock.fetchUserResult = .success(User(id: "1", name: "Alice"))

    let viewModel = ViewModel(userService: mock)
    try await viewModel.loadUser(id: "1")

    XCTAssertEqual(viewModel.user?.name, "Alice")
}
```

```swift
// Bad: XCTestExpectation when async suffices
func testLoadUser() {
    let expectation = expectation(description: "load")
    viewModel.loadUser(id: "1") {
        expectation.fulfill()
    }
    wait(for: [expectation], timeout: 5)
}
```

---

## Test ViewModels, Not Views Directly

**SwiftUI views are functions of state - test the state source:**

```swift
// Good: Test ViewModel logic
@MainActor
func testViewModelLoadsItems() async throws {
    let mock = MockItemService()
    mock.items = [Item(id: "1", name: "Test")]

    let viewModel = ItemListViewModel(service: mock)
    await viewModel.load()

    XCTAssertEqual(viewModel.items.count, 1)
    XCTAssertEqual(viewModel.items[0].name, "Test")
}
```

---

## Add Accessibility Identifiers for UI Tests

**Use `accessibilityIdentifier` for XCUITest discovery:**

```swift
// Good: Accessibility identifiers for UI tests
Button("Submit") {
    submit()
}
.accessibilityIdentifier("submitButton")

TextField("Email", text: $email)
    .accessibilityIdentifier("emailField")
```

---

## Test Cancellation

**Verify async code respects cancellation:**

```swift
// Good: Test cancellation
func testLoadCancels() async throws {
    let mock = MockUserService()
    mock.delay = 10  // Simulate slow response

    let task = Task {
        try await viewModel.loadUser(id: "1")
    }
    task.cancel()

    do {
        _ = try await task.value
        XCTFail("Should have thrown CancellationError")
    } catch is CancellationError {
        // Expected
    }
}
```

---

## Use Swift Testing Framework for New Tests (Swift 5.10+ / Xcode 16+)

**Write new tests as `@Test` / `@Suite` with `#expect` — XCTest stays only for existing files and UI/performance tests.**

```swift
// Good: Swift Testing — no XCTestCase, no boilerplate
import Testing

@Test func loadUserSucceeds() async throws {
    let mock = MockUserService()
    mock.fetchUserResult = .success(User(id: "1", name: "Alice"))

    let viewModel = ViewModel(userService: mock)
    try await viewModel.loadUser(id: "1")

    #expect(viewModel.user?.name == "Alice")
}
```

For the full Swift Testing surface — `@Suite`, parameterized tests, traits, tags, the XCTest → Swift Testing migration table — see [Swift Testing framework](swift-testing-framework.md).

---

## Related Rules

- [Swift Testing framework](swift-testing-framework.md) - @Test / #expect / @Suite — the modern framework
- [Protocol-Oriented Patterns](../language/protocol-oriented-patterns.md) - Protocol design for mocking
- [Error Handling Patterns](../language/error-handling-patterns.md) - Result in tests
- [iOS Best Practices](../ios/ios-best-practices.md) - MVVM testability

---

## References

- [Testing with Xcode - Apple](https://developer.apple.com/documentation/xcode/testing-with-xcode)
- [Swift Testing — Apple landing](https://developer.apple.com/xcode/swift-testing/)
- [WWDC24 "Meet Swift Testing" (10179)](https://developer.apple.com/videos/play/wwdc2024/10179/)
- [swiftlang/swift-testing](https://github.com/swiftlang/swift-testing)
- [ViewInspector - SwiftUI view testing](https://github.com/nalexn/ViewInspector)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
