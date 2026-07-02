# Swift Error Handling Patterns

## Triggers
**APPLY WHEN:** Writing error handling code, choosing between Result and throws, defining custom errors, or handling async failures.
**SKIP WHEN:** Code already uses appropriate error handling patterns.

## Core Directive
**Use `throws` for synchronous code and `Result` for async/callback contexts.** Define custom errors with `enum` conforming to `Error`. Never use optional returns to signal failure when an error reason matters.

---

## Use Throws for Synchronous Code

**Prefer `throws` when errors propagate through call stack:**

```swift
// Good: throws for synchronous operations
enum ValidationError: Error {
    case invalidFormat
    case missingField(String)
}

func validateUser(_ user: User) throws {
    guard !user.email.isEmpty else {
        throw ValidationError.missingField("email")
    }
}

func processUser(_ user: User) throws {
    try validateUser(user)
    // ...
}

// Good: do-try-catch at call site
do {
    try processUser(user)
} catch ValidationError.invalidFormat {
    // Handle specific error
} catch ValidationError.missingField(let field) {
    // Handle with associated value
} catch {
    // Handle unknown errors
}
```

```swift
// Bad: Optional to signal failure - loses error context
func validateUser(_ user: User) -> Bool {
    guard !user.email.isEmpty else { return false }
    return true
}
```

---

## Use Result for Async and Callbacks

**Use `Result` when errors travel through completion handlers or when you need to defer handling:**

```swift
// Good: Result for completion handlers
func fetchUser(id: String, completion: @escaping (Result<User, NetworkError>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            completion(.failure(.requestFailed(error)))
            return
        }
        guard let data = data else {
            completion(.failure(.noData))
            return
        }
        do {
            let user = try JSONDecoder().decode(User.self, from: data)
            completion(.success(user))
        } catch {
            completion(.failure(.decodingFailed(error)))
        }
    }.resume()
}

// Good: Result with async/await (convert at boundary)
func fetchUser(id: String) async -> Result<User, NetworkError> {
    do {
        let user = try await performRequest(id)
        return .success(user)
    } catch {
        return .failure(.from(error))
    }
}
```

```swift
// Bad: Optional + error parameter - ambiguous state
func fetchUser(id: String, completion: @escaping (User?, Error?) -> Void) {
    // Can both be nil, or both non-nil - unclear!
}
```

---

## Define Custom Errors with Enum

**Use enums with associated values for structured error context:**

```swift
// Good: Custom error enum with rich context
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingFailed(underlying: Error)
    case statusCode(Int)
}

enum ApiError: Error {
    case unauthorized
    case rateLimited(retryAfter: Int)
    case serverError(String)
}
```

```swift
// Bad: String errors - no type safety
func process() throws {
    throw "Something went wrong"
}
```

---

## Use try? for Optional Conversion

**Use `try?` when you want to discard the error and get an optional:**

```swift
// Good: try? when error is acceptable to ignore
func loadCachedConfig() -> Config? {
    try? Data(contentsOf: configURL).flatMap { try? JSONDecoder().decode(Config.self, from: $0) }
}
```

```swift
// Bad: try! - crashes on any error
let data = try! Data(contentsOf: url)
```

---

## Propagate Errors in Async Functions

**Use `throws` with async - errors propagate naturally:**

```swift
// Good: async throws
func fetchUser(id: String) async throws -> User {
    let data = try await performRequest(id)
    return try JSONDecoder().decode(User.self, from: data)
}

// Call site
do {
    let user = try await fetchUser(id: "123")
} catch {
    handleError(error)
}
```

---

## Related Rules

- [Style Guide](style-guide.md) - Swift conventions
- [Swift Concurrency Patterns](swift-concurrency-patterns.md) - Async error handling with Task

---

## References

- [Swift Error Handling - Apple Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/errorhandling/)
- [Understanding Swift's Result type - Hacking with Swift](https://www.hackingwithswift.com/books/ios-swiftui/understanding-swifts-result-type)
- [Functional Error Handling in Swift](https://softwarepatternslexicon.com/swift/functional-programming-patterns/functional-error-handling-with-result-and-throws/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
