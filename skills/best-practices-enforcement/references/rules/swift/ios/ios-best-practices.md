# iOS Swift Best Practices

## 1. Architecture
- **MVVM**: Model-View-ViewModel is the preferred architecture for UIKit and SwiftUI apps.
  - **View**: Displays UI and delegates user input to ViewModel.
  - **ViewModel**: Holds state, handles business logic, transforms data for View.
  - **Model**: Data structures and networking.

## 2. UI Development
- **UIKit**:
  - Prefer programmatic UI or XIBs over Storyboards for better merge conflict resolution.
  - Use Auto Layout constraints efficiently.
- **SwiftUI**:
  - Prefer `@Observable` and `@Bindable` (iOS 17+) over `ObservableObject` for better performance and simpler syntax.
  - Use `@State`, `@Binding`, `@StateObject`, `@ObservedObject` when targeting iOS 16 or earlier.
  - Use `@State` for local view state, `@Environment` for dependency injection.

## 3. Memory Management
- **Retain Cycles**: Always use `[weak self]` in closures that capture `self`, especially in ViewModels and Network handlers.
- **Deinit**: Implement `deinit` to verify objects are being released (debug only).

## 4. Combine / Async
- Prefer Combine or Async/Await for handling asynchronous streams of data over delegates or closures where appropriate.

## 5. Modern State Management (iOS 17+)
- Use `@Observable` macro instead of `ObservableObject` for view models - finer-grained updates, no `@Published` needed.
- Use `@Bindable` in child views when passing observable objects.
- `@Observable` tracks property access; views update only when read properties change.
- Owning view uses `@State` (NOT `@StateObject`) with an `@Observable` type; environment injection becomes `.environment(value)` + `@Environment(Type.self)`.
- Full pattern set — migration mapping, `@ObservationIgnored`, iOS 16 fallback — in [`observation-framework.md`](observation-framework.md).

## 6. References
- [Apple — Observation framework](https://developer.apple.com/documentation/observation)
- [Apple — Migrating from ObservableObject to Observable](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
