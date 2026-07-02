# Approachable concurrency (Swift 6.2+)

Swift 6.2 introduced a set of opt-in build settings collectively called **approachable concurrency**: new modules are single-threaded and main-actor-isolated by default, and you explicitly opt in to background work. The goal is to make Swift 6's data-race safety the easy path for UI-heavy code (most apps), not a wall of warnings.

For the mechanics of getting an existing module into Swift 6 language mode at all, see `strict-concurrency-migration.md`. This file covers the new defaults you should turn on **after** that migration succeeds, and on every greenfield module.

Source: [WWDC25 "Embracing Swift concurrency" (session 268)](https://developer.apple.com/videos/play/wwdc2025/268/).

---

## The three approachable-concurrency settings

Swift 6.2 ships three independent upcoming features that, together, make concurrency opt-in instead of opt-out. Enable them per-target in `Package.swift`:

```swift
// ✅ Good: greenfield UI module — all three on
.target(
    name: "AppUI",
    swiftSettings: [
        .swiftLanguageMode(.v6),
        // 1. Top-level code, vars, and unannotated types default to @MainActor.
        .defaultIsolation(MainActor.self),
        // 2. Nonisolated async functions stay on the caller's actor (no implicit hop).
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        // 3. Inferred-Sendable closures get isolation-correct capture inference.
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
)
```

```swift
// ✅ Good: background-heavy module (networking, DB) — keep nonisolated default
.target(
    name: "Networking",
    swiftSettings: [
        .swiftLanguageMode(.v6),
        // Intentionally NOT setting defaultIsolation — this module's types
        // should be nonisolated/actor by design.
    ]
)
```

---

## Main-actor-by-default removes most @MainActor annotations

With `defaultIsolation(MainActor.self)`, every unannotated type, top-level binding, and global is implicitly `@MainActor`. You only annotate **exceptions** — code that runs off the main actor.

```swift
// ✅ Good: under main-actor-default, the annotation is implicit
final class FeedViewModel: ObservableObject {  // implicitly @MainActor
    @Published var items: [Item] = []
    func load() async {
        let fetched = await api.fetch()  // hops off main for the await
        items = fetched                  // back on main — safe
    }
}

// ✅ Good: explicitly nonisolated when the type genuinely doesn't touch UI
nonisolated final class JSONCoder {
    func encode<T: Encodable>(_ value: T) throws -> Data { /* … */ }
}

// ✅ Good: explicit actor for shared mutable state
actor RequestCache {
    private var entries: [URL: Data] = [:]
    func get(_ url: URL) -> Data? { entries[url] }
}
```

```swift
// ❌ Bad: redundantly annotating @MainActor on every type under main-actor-default
@MainActor final class FeedViewModel { /* … */ }  // already MainActor!
@MainActor final class SettingsView { /* … */ }   // noise
```

---

## NonisolatedNonsendingByDefault: async funcs don't hop unexpectedly

Pre-Swift-6.2, a `nonisolated` async function executed on a cooperative thread pool — calling it from `@MainActor` involved a context switch (and required arguments to be `Sendable`). The new feature makes `nonisolated` async functions inherit the **caller's** actor by default, which removes a whole class of spurious `Sendable` errors.

```swift
// ✅ Good (Swift 6.2 with feature on): no Sendable error, no actor hop
@MainActor
final class ViewModel {
    func refresh() async {
        let raw = MyNonSendableRequest()
        let result = await formatter.format(raw) // runs on MainActor — caller's actor
    }
}

final class Formatter {
    // 'nonisolated' but stays on caller's actor under the new default
    func format(_ req: MyNonSendableRequest) async -> String { /* … */ }
}
```

```swift
// ❌ Bad (pre-6.2 behavior): same code errored —
// "non-sendable type 'MyNonSendableRequest' exiting MainActor context".
```

To force a function back onto the global pool (i.e. the old `nonisolated async` behavior), annotate the function with `@concurrent` — explicit beats implicit:

```swift
@concurrent
nonisolated func parse(_ data: Data) async throws -> Model { /* heavy work, off main */ }
```

---

## When NOT to enable main-actor-default

Main-actor-default is the right choice for app targets, SwiftUI feature modules, and most leaf UI packages. It's the **wrong** choice for:

- **Networking / persistence / parsing modules** — these should be `nonisolated` or `actor`-based; forcing them onto MainActor pessimizes the whole app.
- **CLI tools and server-side Swift** — no main thread to bind to.
- **Cross-platform libraries** — main actor doesn't exist on Linux/Windows the way it does on Apple platforms.

Mix freely: a UI feature module with `defaultIsolation(MainActor.self)` can depend on a networking module without it. The isolation flows from the type, not from who imports it.

---

## Migration order: language mode 6 first, defaults second

Approachable-concurrency settings make sense **after** a module compiles under language mode 6, not before. Trying to flip both at once means you can't tell which errors come from data-race safety and which come from the new default isolation. Sequence:

1. Get the module to language mode 6 (`strict-concurrency-migration.md`).
2. For UI modules, add `.defaultIsolation(MainActor.self)` and delete the now-redundant `@MainActor` annotations.
3. Add `NonisolatedNonsendingByDefault` once you've audited any `nonisolated async` functions you actually want to stay on the global pool (mark them `@concurrent`).

---

## Related rules

- [Swift 6 Strict-Concurrency Migration](strict-concurrency-migration.md) — prerequisite
- [Swift Concurrency Patterns](swift-concurrency-patterns.md) — actors, async-let, TaskGroup idioms

---

## References

- [WWDC25 "Embracing Swift concurrency" (268)](https://developer.apple.com/videos/play/wwdc2025/268/) — the canonical introduction to approachable concurrency
- [Swift Migration Guide](https://www.swift.org/migration/documentation/migrationguide/)
- [Swift Evolution proposal index](https://www.swift.org/swift-evolution/) — search SE-0466, SE-0461, SE-0470 for the underlying proposals

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
