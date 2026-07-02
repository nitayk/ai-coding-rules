# Swift 6 strict-concurrency migration

Swift 6 promotes data-race safety from a warning-only checker (Swift 5.x) to a compile-time error (language mode `6`). The migration is **incremental and per-target** — flip warnings on first, fix them module-by-module, then bump the language mode. This file is the mechanics playbook; the day-to-day concurrency idioms live in `swift-concurrency-patterns.md`, and the "approachable concurrency" defaults shipped in Swift 6.2 live in `approachable-concurrency.md`.

Source: [Swift 6 Concurrency Migration Guide](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/) · [WWDC24 "Migrate your app to Swift 6"](https://developer.apple.com/videos/play/wwdc2024/10169/).

---

## Migrate one module at a time, warnings first

Do **not** flip `-swift-version 6` on the whole project in one commit. The official migration path is: enable complete checking as warnings → fix → upgrade the language mode for that one module → repeat.

```swift
// ✅ Good: Package.swift — one target at a time, warnings before errors
.target(
    name: "Networking",
    swiftSettings: [
        // Phase 1: surface every data-race issue as a warning
        .enableExperimentalFeature("StrictConcurrency"),
        // .enableUpcomingFeature("StrictConcurrency"), // for SwiftPM 5.10+
    ]
),
.target(
    name: "Models",
    swiftSettings: [
        // Phase 2: this module is clean — flip to language mode 6 (errors)
        .swiftLanguageMode(.v6),
    ]
),
```

```swift
// ❌ Bad: top-level flip with no triage — hundreds of errors, no incremental progress
// (In Xcode: setting "Swift Language Version = Swift 6" on the whole app target)
```

In Xcode, the equivalent build settings are **Strict Concurrency Checking** (`Minimal` / `Targeted` / `Complete`) and **Swift Language Version** (`5` / `6`). Use `Complete` to mirror what language mode 6 will enforce, then flip the version once the module is clean.

---

## Make types Sendable when they cross isolation domains

Any value passed between actors (or captured by `@Sendable` closures) must conform to `Sendable`. Value types with `Sendable` stored properties get conformance for free; reference types need help.

```swift
// ✅ Good: value type — implicit Sendable
struct User: Sendable {
    let id: UUID
    let email: String
}

// ✅ Good: immutable reference type — explicit, safe
final class Configuration: Sendable {
    let apiURL: URL
    let timeout: TimeInterval
    init(apiURL: URL, timeout: TimeInterval) {
        self.apiURL = apiURL
        self.timeout = timeout
    }
}

// ✅ Good: mutable class guarded by internal synchronization — opt out, document why
// @unchecked is a promise to the compiler that YOU have proven thread-safety.
final class MetricsBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var samples: [Double] = []
    func append(_ x: Double) { lock.withLock { samples.append(x) } }
}
```

```swift
// ❌ Bad: mutable class with no synchronization marked @unchecked Sendable
final class Cache: @unchecked Sendable {
    var entries: [String: Data] = [:] // unsynchronized — silent data race
}
```

`@unchecked Sendable` silences the compiler but does **not** make the type safe. Reach for it only when you can name the synchronization mechanism (lock, serial queue, atomics).

---

## @MainActor for UI; isolation flows from the type

Annotate the class (or the whole module — see `approachable-concurrency.md`) rather than sprinkling `@MainActor` on every method. The annotation transitively isolates stored properties and instance methods.

```swift
// ✅ Good: class-level isolation — all methods/properties are MainActor
@MainActor
final class FeedViewModel: ObservableObject {
    @Published var items: [Item] = []

    func load() async {
        let fetched = await api.fetchItems() // hop off MainActor for the await
        items = fetched                       // back on MainActor — safe
    }
}
```

```swift
// ❌ Bad: per-method annotation drift — easy to miss one and race
final class FeedViewModel: ObservableObject {
    @Published var items: [Item] = []
    @MainActor func load() async { /* … */ }
    func refresh() async { items = [] } // forgot @MainActor — error in Swift 6
}
```

---

## Bridge legacy APIs with @preconcurrency

Third-party SDKs and Objective-C delegates predate `Sendable`. Use `@preconcurrency` on imports and protocol conformances to downgrade their warnings while you migrate.

```swift
// ✅ Good: legacy SDK without Sendable annotations
@preconcurrency import LegacyAdSDK

@preconcurrency
extension MyViewController: LegacyDelegate {
    func didReceiveCallback(_ payload: LegacyPayload) { /* … */ }
}
```

This is a temporary stance — the goal is for the upstream library to ship real `Sendable` annotations and for you to remove `@preconcurrency`.

---

## Escape hatches: nonisolated(unsafe) and MainActor.assumeIsolated

Two surgical tools for situations the type system can't express:

```swift
// ✅ nonisolated(unsafe): a global the compiler can't prove is safe,
// but you know is set once at startup before any concurrency starts.
nonisolated(unsafe) var buildInfo: BuildInfo!

@main struct App {
    static func main() {
        buildInfo = BuildInfo.load() // single writer, before any Task
    }
}
```

```swift
// ✅ MainActor.assumeIsolated: callback you KNOW runs on the main thread,
// but the framework signature doesn't say so (typical: older Apple APIs).
extension MyViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        legacyAPI.onUpdate = { value in
            MainActor.assumeIsolated {
                self.label.text = value // safe: callback is documented main-thread
            }
        }
    }
}
```

```swift
// ❌ Bad: assumeIsolated on a callback that actually fires on a background queue
// → runtime crash in debug, undefined behavior in release.
```

Both tools shift the safety obligation from compiler to programmer. Comment **why** every use is safe.

---

## Common migration pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| "Capture of 'self' with non-sendable type in a `@Sendable` closure" | Class instance captured by `Task { … }` | Annotate class `@MainActor`, or capture a `Sendable` snapshot |
| "Stored property '…' of `Sendable`-conforming class … is mutable" | `final class X: Sendable { var y }` | Make stored property `let`, or move to an `actor` |
| "Main actor-isolated property cannot be referenced from a non-isolated context" | Touching `@MainActor` state from a background `Task` | Wrap the touch in `await MainActor.run { … }` or hoist the method to `@MainActor` |
| Hundreds of warnings on a module you just opened | Strict checking was off; default Swift 5 inference hid them | Enable `Complete` first, **don't** jump to language mode 6 |

---

## Migration checklist

1. Pick the **leaf-most** module (no upward dependencies).
2. Set `swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]` → fix warnings.
3. Add `Sendable` to value types; audit reference types; use `@preconcurrency` for legacy imports.
4. Hoist UI types to `@MainActor` at the type level, not per-method.
5. Flip `.swiftLanguageMode(.v6)` for that module.
6. Move up one dependency level and repeat.
7. Consider enabling the Swift 6.2 "approachable concurrency" defaults once your modules compile under language mode 6 — see `approachable-concurrency.md`.

---

## Related rules

- [Swift Concurrency Patterns](swift-concurrency-patterns.md) — day-to-day actors/async-await idioms
- [Approachable Concurrency (Swift 6.2)](approachable-concurrency.md) — main-actor-default opt-in
- [Value Types Patterns](value-types-patterns.md) — why structs make Sendable easy

---

## References

- [Swift 6 Concurrency Migration Guide](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/)
- [Swift Migration Guide (hub)](https://www.swift.org/migration/documentation/migrationguide/)
- [Updating an app to use strict concurrency — Apple](https://developer.apple.com/documentation/swift/updating-an-app-to-use-strict-concurrency)
- [WWDC24 "Migrate your app to Swift 6"](https://developer.apple.com/videos/play/wwdc2024/10169/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
