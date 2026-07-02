# Objective-C Development Rules

## Available Rules

### Language Features (`language/`)
**Load**: `references/rules/objective-c/language/index.md`
- **[Style Guide](language/style-guide.md)** - Naming, formatting, pragma marks, literals
- **[ARC Memory Management](language/arc-memory-management.md)** - Strong/weak, retain cycles
- **[Blocks and GCD](language/blocks-gcd.md)** - Blocks, Grand Central Dispatch, async patterns
- **[Nullability and Swift Interop](language/nullability-swift-interop.md)** - NS_ASSUME_NONNULL, Swift API
- **[Error Handling](language/error-handling.md)** - NSError patterns, propagation
- **[Protocols and Delegates](language/protocols-delegates.md)** - Delegate pattern, weak, optional
- **[Categories](language/categories.md)** - Extending classes, method prefixes

### iOS Development (`ios/`)
**Load**: `references/rules/objective-c/ios/index.md`
- **[iOS Best Practices](ios/ios-best-practices.md)** - Interoperability, delegates, legacy
- **[iOS Performance](ios/ios-performance.md)** - Instruments, profiling, main thread

### Testing (`testing/`)
**Load**: `references/rules/objective-c/testing/index.md`
- **[Objective-C Testing](testing/objc-testing.md)** - XCTest, OCMock, dependency injection

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **objective-c style**, objc style, objc formatting, style guide | `language/style-guide.md` |
| **arc**, memory management, retain cycles, weak strong | `language/arc-memory-management.md` |
| **blocks**, gcd, dispatch, grand central dispatch, async objc | `language/blocks-gcd.md` |
| **nullability**, swift interop, NS_ASSUME_NONNULL, NS_SWIFT_NAME | `language/nullability-swift-interop.md` |
| **nserror**, error handling, objc error | `language/error-handling.md` |
| **protocol**, delegate, objc delegate | `language/protocols-delegates.md` |
| **category**, categories, extending class | `language/categories.md` |
| **ios**, ios development, ios app, ios architecture, objective-c ios | `ios/ios-best-practices.md` |
| **ios performance**, objc performance, instruments, profiling | `ios/ios-performance.md` |
| **objc test**, objective-c test, xctest, ocmock | `testing/objc-testing.md` |

---

## Available Rules (Leaves)

### Language Features (`language/`)
- **[Style Guide](language/style-guide.md)** - Naming, formatting, pragma marks, literals
- **[ARC Memory Management](language/arc-memory-management.md)** - Strong/weak, retain cycles
- **[Blocks and GCD](language/blocks-gcd.md)** - Blocks, GCD, async patterns
- **[Nullability and Swift Interop](language/nullability-swift-interop.md)** - Swift interoperability
- **[Error Handling](language/error-handling.md)** - NSError patterns
- **[Protocols and Delegates](language/protocols-delegates.md)** - Delegate pattern
- **[Categories](language/categories.md)** - Extending classes

### iOS Development (`ios/`)
- **[iOS Best Practices](ios/ios-best-practices.md)** - Interoperability, delegates
- **[iOS Performance](ios/ios-performance.md)** - Instruments, profiling

### Testing (`testing/`)
- **[Objective-C Testing](testing/objc-testing.md)** - XCTest, OCMock

---

## Core Principles
- **ARC**: Use Automatic Reference Counting for all new code
- **Memory Safety**: Avoid retain cycles with weak references
- **Interoperability**: Support Swift interoperability with nullability annotations

## Key Resources
- [Apple: Transitioning to ARC](https://developer.apple.com/library/archive/releasenotes/ObjectiveC/RN-TransitioningToARC/)
- [Memory Management Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MemoryMgmt/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
