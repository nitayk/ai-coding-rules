# Swift Protocol-Oriented Patterns

## Triggers
**APPLY WHEN:** Designing abstractions, enabling mocking, or composing behavior with protocols.
**SKIP WHEN:** Simple data types with no abstraction need.

## Core Directive
**Use protocols as contracts for "can do" behavior, not "is a" hierarchy.** Prefer protocol extensions for default implementations. Use protocol composition over inheritance.

---

## Protocol as Contract

**Define protocols for capabilities, not implementation details:**

```swift
// Good: Protocol defines capability
protocol UserFetching {
    func fetchUser(id: String) async throws -> User
}

protocol ImageLoading {
    func loadImage(from url: URL) async throws -> UIImage
}

// Types conform to multiple protocols
struct ApiService: UserFetching, ImageLoading {
    func fetchUser(id: String) async throws -> User { /* ... */ }
    func loadImage(from url: URL) async throws -> UIImage { /* ... */ }
}
```

```swift
// Bad: Protocol as inheritance substitute
protocol UserProtocol {
    var id: String { get }
    var name: String { get }
    func save()  // Mixes data and behavior
}
```

---

## Protocol Extensions for Default Implementations

**Add default behavior via extensions without modifying conforming types:**

```swift
// Good: Default implementation in extension
protocol Describable {
    var description: String { get }
}

extension Describable {
    var debugDescription: String {
        "\(type(of: self)): \(description)"
    }
}

struct User: Describable {
    let id: String
    let name: String
    var description: String { "User(\(id): \(name))" }
}
// debugDescription automatically available
```

---

## Constrained Protocol Extensions

**Provide specialized defaults for specific conforming types:**

```swift
// Good: Constrained extension
extension Collection where Element: Equatable {
    func containsAll(_ elements: [Element]) -> Bool {
        elements.allSatisfy { contains($0) }
    }
}

extension Array where Element: Comparable {
    var isSorted: Bool {
        guard count > 1 else { return true }
        return zip(dropLast(), dropFirst()).allSatisfy { $0 <= $1 }
    }
}
```

---

## Protocol Composition

**Combine protocols with `&` for flexible requirements:**

```swift
// Good: Protocol composition
func display<T: UserFetching & ImageLoading>(_ service: T) {
    // Service must conform to both
}

protocol Identifiable {
    var id: String { get }
}

func process<T: Identifiable & UserFetching>(_ item: T) async throws {
    let user = try await item.fetchUser(id: item.id)
}
```

---

## Prefer Protocols Over Inheritance for Behavior

**Use protocols for testability and flexibility:**

```swift
// Good: Protocol for injectable dependency
protocol NetworkClient {
    func request(_ url: URL) async throws -> Data
}

class ViewModel {
    private let network: NetworkClient

    init(network: NetworkClient) {
        self.network = network
    }

    func load() async throws {
        let data = try await network.request(url)
        // ...
    }
}

// Test with mock
class MockNetworkClient: NetworkClient {
    func request(_ url: URL) async throws -> Data { /* ... */ }
}
```

```swift
// Bad: Concrete dependency - hard to test
class ViewModel {
    private let network = URLSession.shared

    func load() async throws {
        let data = try await network.data(from: url)
        // Cannot inject mock
    }
}
```

---

## Use Self for Protocol Requirements

**Use `Self` when the return type should match the conforming type:**

```swift
// Good: Self for protocol factories
protocol Copyable {
    func copy() -> Self
}

struct Config: Copyable {
    var value: Int

    func copy() -> Self {
        Config(value: value)
    }
}
```

---

## Related Rules

- [Value Types Patterns](value-types-patterns.md) - Structs with protocols
- [Error Handling Patterns](error-handling-patterns.md) - Result in protocol methods
- [iOS Best Practices](../ios/ios-best-practices.md) - MVVM with protocols

---

## References

- [Protocol-Oriented Programming in Swift - Apple](https://developer.apple.com/videos/play/wwdc2015/408/)
- [Protocols - Swift Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/protocols/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
