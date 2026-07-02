# Swift Value Types vs Reference Types

## Triggers
**APPLY WHEN:** Creating new types, modeling domain data, or deciding between struct and class.
**SKIP WHEN:** Type choice is already dictated by framework (e.g., UIView subclass).

## Core Directive
**Prefer `struct` by default.** Use `class` only when you need reference semantics, inheritance, or identity-based equality. Value types are thread-safe by copy and avoid unintended shared mutation.

---

## Prefer Struct for Data and Value Semantics

**Use structs for models, DTOs, and value objects:**

```swift
// Good: Struct for data model
struct User {
    let id: String
    var name: String
    var email: String
}

struct Coordinate {
    let latitude: Double
    let longitude: Double
}

// Copy on assignment - no shared mutation
var user1 = User(id: "1", name: "Alice", email: "a@example.com")
var user2 = user1
user2.name = "Bob"  // user1 unchanged
```

```swift
// Bad: Class for simple data when struct is sufficient
class User {
    let id: String
    var name: String
    var email: String
    // Reference semantics - shared mutation risk
}
```

---

## Use Class When You Need Reference Semantics

**Use class when:**

- Reference identity matters (e.g., `===` comparison)
- You need inheritance
- Shared mutable state is required (e.g., singleton, coordinator)

```swift
// Good: Class for identity and shared state
class SessionManager {
    static let shared = SessionManager()
    private(set) var currentUser: User?

    private init() {}
}

// Good: Class for inheritance (UIKit/AppKit)
class CustomViewController: UIViewController {
    // ...
}
```

---

## Use Enum for State and Options

**Enums are value types ideal for mutually exclusive states:**

```swift
// Good: Enum for state
enum LoadingState<T> {
    case idle
    case loading
    case success(T)
    case error(Error)
}

enum AuthState {
    case unauthenticated
    case authenticated(User)
    case expired
}
```

---

## Value Types Are Thread-Safe by Copy

**Each copy is independent - no data races when passing between threads:**

```swift
// Good: Struct passed to async - safe copy
struct User { let id: String; let name: String }

func processUser(_ user: User) async {
    // user is copied - no shared mutable state
    await heavyComputation(user)
}

let user = User(id: "1", name: "Alice")
Task { await processUser(user) }
```

---

## When to Use Class

| Use Class When | Use Struct When |
|----------------|-----------------|
| Inheriting from framework type (UIView, NSObject) | Modeling data |
| Need `===` identity comparison | Value semantics |
| Singleton or shared coordinator | DTOs, configuration |
| Reference must be shared across owners | Most domain models |

---

## Related Rules

- [Style Guide](style-guide.md) - Prefer struct by default
- [Swift Concurrency Patterns](swift-concurrency-patterns.md) - Sendable and value types
- [Protocol-Oriented Patterns](protocol-oriented-patterns.md) - Protocols with value types

---

## References

- [Choosing Between Structures and Classes - Apple](https://developer.apple.com/documentation/swift/choosing-between-structures-and-classes)
- [Value and Reference Types - Swift.org](https://swift.org/documentation/articles/value-and-reference-types.html)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
