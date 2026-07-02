# Compose stability + Baseline Profiles checklist

Jetpack Compose **only matches View-system runtime performance under three conditions together**: the app is built with **R8** (full mode), shipped with a **Baseline Profile**, and the recomposed Composables receive **stable parameters**. Drop any one and you'll see avoidable jank — usually as first-launch stutter or scroll hitches in lists. This is the explicit guidance on the [Jetpack Compose performance page](https://developer.android.com/develop/ui/compose/performance) (updated 2026-05-15).

Always benchmark in **release**, not debug — debug Compose is ~10x slower than release and tells you nothing useful.

---

## The mandatory release-mode checklist

| # | Requirement | Why |
|---|-------------|-----|
| 1 | `isMinifyEnabled = true` (R8 full mode) in the release build type | Compose runtime relies on R8 for inlining and dead-code elimination; debug builds miss critical optimizations |
| 2 | Baseline Profile generated and shipped (`androidx.benchmark:benchmark-macro-junit4` + the Baseline Profiles Gradle plugin) | AOT-compiles the critical-path Composables on first run; without it, first-frame is JIT-only |
| 3 | All Composable parameters are **stable** (primitives, `@Immutable`/`@Stable`-annotated types, or `kotlinx.collections.immutable` lists) | Unstable params force recomposition even when values are equal |
| 4 | Lambda parameters are referentially stable (don't allocate new `{ }` on every recomposition without `remember`) | Prevents Compose from invalidating the child unnecessarily |
| 5 | `LazyColumn`/`LazyRow` items have a stable `key` | Enables item reuse, prevents full re-layout on data change |

---

## Stability — what to write

```kotlin
// ✅ Good: stable parameter types
@Immutable
data class CartLine(val productId: String, val qty: Int, val priceCents: Long)

@Composable
fun CartRow(line: CartLine, onRemove: () -> Unit) { /* ... */ }
```

```kotlin
// ❌ Bad: List<T> from stdlib is unstable; lambda re-created every frame
@Composable
fun CartRow(line: CartLine, tags: List<String>) {
    Button(onClick = { remove(line) }) { Text("x") } // new lambda each recomp
}
```

```kotlin
// ✅ Good: kotlinx.collections.immutable + remembered lambda
import kotlinx.collections.immutable.ImmutableList

@Composable
fun CartRow(line: CartLine, tags: ImmutableList<String>, onRemove: (CartLine) -> Unit) {
    val click = remember(line) { { onRemove(line) } }
    Button(onClick = click) { Text("x") }
}
```

The Compose compiler reports stability via the [compiler metrics task](https://developer.android.com/develop/ui/compose/performance) — wire it into CI for any Compose-heavy module and watch the "unstable parameters" count.

---

## Baseline Profiles — minimum wiring

```kotlin
// app/build.gradle.kts
plugins {
    id("androidx.baselineprofile")
}

dependencies {
    implementation("androidx.profileinstaller:profileinstaller:1.4.1")
    "baselineProfile"(project(":baselineprofile"))
}
```

A `:baselineprofile` Gradle module runs Macrobenchmark journeys (cold start, scroll the main list) and writes `baseline-prof.txt` into the APK/AAB. The profile is consumed by ART on first install.

Skipping this step is the single largest preventable cause of "Compose feels janky" complaints.

---

## What `remember` and `derivedStateOf` are actually for

- `remember(keys) { ... }` — cache an expensive object across recompositions; recompute only when a key changes.
- `derivedStateOf { ... }` — convert several frequently-changing `State`s into one rarely-changing `State`; **only useful when the derived value changes less often than its inputs**. Using it everywhere makes things slower, not faster.

```kotlin
// ✅ Good: derivedStateOf — isAtTop changes far less often than scrollState
val isAtTop by remember { derivedStateOf { scrollState.firstVisibleItemIndex == 0 } }

// ❌ Bad: derivedStateOf wrapping a trivial 1:1 transform
val doubled by remember { derivedStateOf { count * 2 } } // just compute count * 2
```

---

## Avoid backwards-writes during composition

Writing to a `MutableState` from inside the composition phase that reads the same state triggers an immediate re-composition loop. The compiler will warn; treat the warning as an error.

```kotlin
// ❌ Bad: state mutated during composition that reads it
@Composable
fun Counter() {
    var count by remember { mutableStateOf(0) }
    count++ // re-triggers composition forever
    Text("$count")
}
```

Move the write into a `LaunchedEffect`, a click handler, or `SideEffect { }`.

---

## Related rules

- [Android Performance](android-performance.md) — Memory leaks and broader Android perf
- [Android Best Practices](android-best-practices.md) — Architecture and DI

---

## References

- [Jetpack Compose performance](https://developer.android.com/develop/ui/compose/performance) — Baseline Profiles, R8, stability, `derivedStateOf`, backwards-writes (2026-05-15)
- [Jetpack Compose docs hub](https://developer.android.com/develop/ui/compose) — Canonical Compose entry point

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
