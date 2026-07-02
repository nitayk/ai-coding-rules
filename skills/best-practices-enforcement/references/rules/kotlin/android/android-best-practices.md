# Android Best Practices (Kotlin)

## 1. Architecture
- **MVVM/MVI**: Follow Google's recommended architecture guide.
  - **UI Layer**: Activities/Fragments observe ViewModel state.
  - **ViewModel**: Holds state, handles UI logic, survives configuration changes.
  - **Data Layer**: Repositories mediate between local (Room) and remote (Retrofit) data sources.

## 2. Coroutines and Flow
- **Scopes**:
  - Use `viewModelScope` in ViewModels.
  - Use `lifecycleScope` in Activities/Fragments.
- **Dispatchers**:
  - `Dispatchers.Main`: UI interactions.
  - `Dispatchers.IO`: Database/Network operations.
  - `Dispatchers.Default`: CPU-intensive tasks.
- **Flows**:
  - Use `StateFlow` for UI state (hot stream).
  - Use `SharedFlow` for one-off events (navigation, snackbars).
  - Collect flows using `repeatOnLifecycle` or `flowWithLifecycle` for safety.

## 3. Dependency Injection
- Prefer constructor injection.
- If using Hilt/Dagger, follow standard annotation patterns (`@Inject`, `@HiltViewModel`).

## 4. Resource Management
- Avoid hardcoding strings/colors. Use `R.string`, `R.color`.
- Clean up resources (listeners, receivers) in appropriate lifecycle methods (`onStop`, `onDestroy`).

## 5. UI Implementation
- **ViewBinding**: Prefer ViewBinding over `findViewById` or Kotlin Synthetics (deprecated). The `kotlin-android-extensions` Gradle plugin was **removed** in Kotlin 2.2 — migrate any remaining usage. ([What's new in Kotlin 2.2](https://kotlinlang.org/docs/whatsnew22.html))
- **Compose**: If transitioning to Jetpack Compose, follow Compose-specific rules (hoisting state, side effects). For release performance see [compose-stability-baseline-profiles](compose-stability-baseline-profiles.md).

## 6. Gradle / Build
- **`compilerOptions {}`, not `kotlinOptions {}`** — `kotlinOptions{}` is a hard error on Kotlin 2.2+. See [compiler-options-dsl](compiler-options-dsl.md).
- **Prefer KSP over kapt** for any new annotation-processor wiring (Room, Moshi, Hilt all ship KSP variants); KSP1 will not support Kotlin 2.3 / AGP 9. See [ksp-over-kapt](ksp-over-kapt.md).

---

## References

- [Android developer hub: Kotlin](https://developer.android.com/kotlin) — Canonical Android Kotlin entry point (the older `/kotlin/guides` URL is dead — use specific subpages from this hub).
- [Jetpack Compose docs hub](https://developer.android.com/develop/ui/compose) — Replacement for the dead `/jetpack/compose/documentation` path.
- [What's new in Kotlin 2.2](https://kotlinlang.org/docs/whatsnew22.html) — `kotlinOptions{}` removal; `kotlin-android-extensions` removal.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
