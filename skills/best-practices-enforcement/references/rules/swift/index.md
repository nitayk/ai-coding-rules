# Swift Development Rules

This index provides comprehensive guidance for Swift development.

**Graph Structure**: This is a Layer 2 node that routes directly to Layer 0 leaves (rule files) based on keywords. Flattened for efficiency.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **swift style**, swift formatting, swift naming, style guide | `language/style-guide.md` |
| **swift concurrency**, swift async await, actors, @MainActor, structured concurrency | `language/swift-concurrency-patterns.md` |
| **swift 6 migration**, strict concurrency, Sendable errors, language mode 6, @preconcurrency, nonisolated(unsafe) | `language/strict-concurrency-migration.md` |
| **approachable concurrency**, main-actor-default, defaultIsolation, Swift 6.2, NonisolatedNonsendingByDefault | `language/approachable-concurrency.md` |
| **swift error**, error handling, Result, throws, do-try-catch | `language/error-handling-patterns.md` |
| **swift value types**, struct vs class, value semantics | `language/value-types-patterns.md` |
| **swift protocol**, protocol-oriented, POP, protocol extension | `language/protocol-oriented-patterns.md` |
| **swift test**, swift unit test, swift mocking, swiftui test, xctest | `testing/swift-testing.md` |
| **swift testing framework**, @Test, #expect, @Suite, parameterized tests, xctest migration | `testing/swift-testing-framework.md` |
| **ios**, ios development, ios architecture, mvvm ios, swiftui, uikit | `ios/ios-best-practices.md` |
| **@Observable**, Observation framework, @Bindable, @State vs @StateObject, ObservableObject migration | `ios/observation-framework.md` |
| **ios performance**, ios memory management, instruments, swiftui performance | `ios/ios-performance.md` |
| **swift package manager**, SPM, Package.swift, swiftSettings, dependency management | `tooling/swift-package-manager.md` |
| **swift-format**, SwiftLint, formatter, linter, .swiftlint.yml, .swift-format | `tooling/swift-format-and-swiftlint.md` |

---

## Available Rules (Leaves)

### Language Features (`language/`)
- **[Style Guide](language/style-guide.md)** - Swift naming conventions, formatting, and code organization
- **[Swift Concurrency Patterns](language/swift-concurrency-patterns.md)** - Day-to-day async/await, actors, @MainActor, structured concurrency
- **[Strict-Concurrency Migration](language/strict-concurrency-migration.md)** - Swift 6 language-mode mechanics (Sendable, @preconcurrency, nonisolated(unsafe))
- **[Approachable Concurrency](language/approachable-concurrency.md)** - Swift 6.2 main-actor-default + NonisolatedNonsendingByDefault
- **[Error Handling Patterns](language/error-handling-patterns.md)** - Result vs throws, do-try-catch, custom errors
- **[Value Types Patterns](language/value-types-patterns.md)** - Struct vs class, when to use each
- **[Protocol-Oriented Patterns](language/protocol-oriented-patterns.md)** - Protocols, extensions, composition

### iOS Development (`ios/`)
- **[iOS Best Practices](ios/ios-best-practices.md)** - iOS-specific patterns, MVVM, retain cycles
- **[Observation Framework](ios/observation-framework.md)** - @Observable macro, @Bindable, iOS 17+ state management
- **[iOS Performance](ios/ios-performance.md)** - Memory management, profiling, Instruments, SwiftUI performance

### Testing (`testing/`)
- **[Swift Testing Patterns](testing/swift-testing.md)** - Unit tests, mocking, SwiftUI testing, async tests
- **[Swift Testing Framework](testing/swift-testing-framework.md)** - @Test / #expect / @Suite — the XCTest replacement

### Tooling (`tooling/`)
- **[Swift Package Manager](tooling/swift-package-manager.md)** - SPM as canonical dependency manager, per-target swiftSettings
- **[swift-format + SwiftLint](tooling/swift-format-and-swiftlint.md)** - The two-tool formatting+linting stack

## Planned Categories

- Generics and associated types
- Typed throws (Swift 6) and noncopyable types (Swift 5.9+) coverage in error-handling / value-types

## References

### Canonical (Swift.org / Apple)
- [Swift Documentation](https://www.swift.org/documentation/) — official hub (replaces docs.swift.org); Swift 6.3.2 current
- [Swift Evolution](https://www.swift.org/swift-evolution/) — proposal index (replaces broken /evolution/)
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) — official naming conventions
- [Swift Migration Guide](https://www.swift.org/migration/documentation/migrationguide/) — Swift 6 strict-concurrency adoption
- [Swift 6 Concurrency Migration Guide](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/) — focused data-race-safety enablement
- [Updating an app to use strict concurrency](https://developer.apple.com/documentation/swift/updating-an-app-to-use-strict-concurrency) — Apple task guide

### WWDC sessions (canonical for concurrency + testing)
- [WWDC24 "Migrate your app to Swift 6"](https://developer.apple.com/videos/play/wwdc2024/10169/) — practical migration walkthrough
- [WWDC25 "Embracing Swift concurrency"](https://developer.apple.com/videos/play/wwdc2025/268/) — approachable concurrency + main-actor-default (Swift 6.2)
- [WWDC24 "Meet Swift Testing"](https://developer.apple.com/videos/play/wwdc2024/10179/) — @Test / #expect / @Suite

### Testing + tooling
- [Swift Testing (Apple)](https://developer.apple.com/xcode/swift-testing/) — official framework landing
- [swift-format](https://github.com/apple/swift-format) — Apple formatter, bundled with Xcode 16+
- [SwiftLint](https://github.com/realm/SwiftLint) — de-facto community linter (v0.63.2, Jan 2026)

### Style
- [Google Swift Style Guide](https://google.github.io/swift/) — most-cited public style guide

### Community (supplemental)
- [SwiftLee — Antoine van der Lee](https://www.avanderlee.com/) — weekly cadence (active 2026)
- [Hacking with Swift — Paul Hudson](https://www.hackingwithswift.com/) — tutorials + reference (still authoritative)

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
