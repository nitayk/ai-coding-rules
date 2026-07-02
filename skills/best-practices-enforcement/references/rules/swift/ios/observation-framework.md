# Observation framework (@Observable)

The Observation framework, introduced with iOS 17 / macOS 14 / Swift 5.9, replaces `ObservableObject` + `@Published` with a single `@Observable` macro. The runtime tracks which properties a view actually **reads** during body evaluation and invalidates only those views when those specific properties change — finer-grained than `@Published`, which invalidates every observer on every update.

For iOS 16 and earlier you still need `ObservableObject` / `@Published`. For new code on iOS 17+, `@Observable` is the default.

Source: [Apple — Observation framework](https://developer.apple.com/documentation/observation) · [Apple — Migrating from the Observable Object protocol to the Observable macro](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro).

---

## @Observable replaces ObservableObject + @Published

The macro is class-level and removes every `@Published` annotation. Stored properties become observable automatically; `let` and computed properties are tracked when read.

```swift
// ✅ Good: iOS 17+ — single macro, no per-property annotation
import Observation

@Observable
final class FeedViewModel {
    var items: [Item] = []
    var isLoading = false
    var error: Error?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do { items = try await api.fetch() }
        catch { self.error = error }
    }
}
```

```swift
// ❌ Bad: leaving @Published / ObservableObject on iOS 17+ code
final class FeedViewModel: ObservableObject {
    @Published var items: [Item] = []   // every property change invalidates every view
    @Published var isLoading = false
    @Published var error: Error?
}
```

The `@Observable` version delivers the same API to call sites but with **property-level** invalidation: a view that only reads `isLoading` won't re-render when `items` changes.

---

## Property wrappers change at the call site

| Old (`ObservableObject`) | New (`@Observable`) |
|---|---|
| `@StateObject var vm = FeedViewModel()` | `@State var vm = FeedViewModel()` |
| `@ObservedObject var vm: FeedViewModel` | `let vm: FeedViewModel` (just store it) |
| `@EnvironmentObject var vm: FeedViewModel` | `@Environment(FeedViewModel.self) var vm` |
| Pass a `@Binding` into a child | Annotate child with `@Bindable` |

```swift
// ✅ Good: owning view uses @State (NOT @StateObject) with @Observable
struct FeedRoot: View {
    @State private var vm = FeedViewModel()
    var body: some View {
        FeedList(vm: vm)
    }
}

// ✅ Good: child stores the reference plainly — no @ObservedObject
struct FeedList: View {
    let vm: FeedViewModel
    var body: some View { ForEach(vm.items) { ItemRow(item: $0) } }
}
```

```swift
// ❌ Bad: using @StateObject with an @Observable type — compiler will reject
struct FeedRoot: View {
    @StateObject private var vm = FeedViewModel()  // error: type doesn't conform to ObservableObject
}
```

The shift is subtle but important: `@StateObject` was needed because `@State` couldn't track external object identity. `@Observable` integrates with `@State` directly, eliminating the wrapper.

---

## @Bindable for two-way binding to a child view

When a child view needs to bind to a property of an `@Observable` parent (e.g. `TextField($name)`), the child annotates the reference with `@Bindable`:

```swift
// ✅ Good: child gets a @Bindable wrapper for $-prefixed bindings
struct ProfileEditor: View {
    @Bindable var user: User  // U is @Observable

    var body: some View {
        Form {
            TextField("Name", text: $user.name)
            TextField("Email", text: $user.email)
        }
    }
}
```

```swift
// ❌ Bad: trying to use $user.name without @Bindable
struct ProfileEditor: View {
    let user: User  // no @Bindable — $user.name doesn't compile
    var body: some View { TextField("Name", text: $user.name) }
}
```

---

## Environment injection by type

`@Observable` types are stored in the SwiftUI environment by their type, not by a named key:

```swift
// ✅ Good: inject by type, read by type
@main struct MyApp: App {
    @State private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)  // no key
        }
    }
}

struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    var body: some View { Text(session.user.name) }
}
```

```swift
// ❌ Bad: legacy .environmentObject + @EnvironmentObject with @Observable
.environmentObject(session)  // error: SessionStore is not ObservableObject
```

---

## Opting properties out of tracking

Sometimes a stored property genuinely shouldn't trigger view updates (caches, intermediate buffers). Use `@ObservationIgnored`:

```swift
@Observable
final class FeedViewModel {
    var items: [Item] = []

    @ObservationIgnored
    private var prefetchCache: [URL: Data] = [:]  // changes never invalidate views
}
```

---

## iOS 16 fallback: keep ObservableObject

If you support iOS 16 or earlier, you cannot use `@Observable`. Two viable patterns:

1. **Two implementations** — `@Observable` class for iOS 17+, `ObservableObject` class for iOS 16, choose at the call site with `#available`.
2. **Stay on `ObservableObject`** — the simpler option for apps with a long-tail deployment target. Migrate once the floor moves to iOS 17.

Mixing the two in the same view hierarchy works but adds cognitive overhead — pick one per feature module.

---

## Why this matters for performance

`@Published` invalidates *every* subscriber on *any* property change. A list view that observes a ViewModel with 20 `@Published` properties re-renders whenever any of those 20 changes, even if the view body only reads two of them.

`@Observation` tracks the **specific properties accessed during body evaluation** and invalidates only those views when those specific properties mutate. For complex screens this materially reduces SwiftUI's diffing work — measured in the WWDC23 "Discover Observation in SwiftUI" session and visible in Instruments' SwiftUI template.

---

## Related rules

- [iOS Best Practices](ios-best-practices.md) — MVVM, retain cycles, broader iOS patterns
- [iOS Performance](ios-performance.md) — Instruments, SwiftUI render performance

---

## References

- [Apple — Observation framework](https://developer.apple.com/documentation/observation)
- [Apple — Migrating from ObservableObject to Observable](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [WWDC23 "Discover Observation in SwiftUI"](https://developer.apple.com/videos/play/wwdc2023/10149/) — original introduction

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
