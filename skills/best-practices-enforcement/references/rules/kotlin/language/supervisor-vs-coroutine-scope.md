# supervisorScope vs coroutineScope — decision rule

Both `coroutineScope { }` and `supervisorScope { }` are suspending builders that wait for their children to finish before returning, and both cancel their children if the caller is cancelled. The single semantic difference is **what happens when one child fails**:

- **`coroutineScope`** — a failure in one child cancels every sibling and re-throws. Fail-fast aggregation.
- **`supervisorScope`** — a failure in one child does **not** cancel siblings. Each child's failure is delivered to its own `await()` (or `CoroutineExceptionHandler` for `launch`). Sibling-isolation.

This is the canonical contract from [kotlinx.coroutines: exception handling](https://github.com/Kotlin/kotlinx.coroutines/blob/master/docs/topics/exception-handling.md).

---

## Decision rule

| You want… | Use |
|-----------|-----|
| All-or-nothing: if any child fails, abort all and surface the error | `coroutineScope` |
| Best-effort aggregation: collect what you can, log what failed, return partial results | `supervisorScope` |
| Background fan-out where failures are expected & individually handled | `supervisorScope` |
| A single suspending operation that internally parallelizes a transactional step | `coroutineScope` |

If you can't articulate which side of that table you're on, default to **`coroutineScope`** — fail-fast is the safer default; silent partial success is a long-tail bug class.

---

## Examples

### Fail-fast: load a coherent object graph

```kotlin
// ✅ Good: coroutineScope — if either side fails, abort the whole load
suspend fun loadUserScreen(userId: String): UserScreen = coroutineScope {
    val profile = async { api.getProfile(userId) }
    val posts   = async { api.getPosts(userId) }
    UserScreen(profile.await(), posts.await())
}
```

If `getProfile` throws, `getPosts` is cancelled immediately and the exception propagates out of `loadUserScreen`. There is never a `UserScreen` constructed from partial data.

### Sibling isolation: dashboard tiles

```kotlin
// ✅ Good: supervisorScope — each tile is independent
suspend fun loadDashboard(): Dashboard = supervisorScope {
    val weather  = async { runCatching { weatherApi.today() } }
    val news     = async { runCatching { newsApi.headlines() } }
    val calendar = async { runCatching { calendarApi.next() } }

    Dashboard(
        weather  = weather.await().getOrNull(),
        news     = news.await().getOrNull(),
        calendar = calendar.await().getOrNull(),
    )
}
```

A flaky weather service does not blank out the news feed. Each child's failure is wrapped via `runCatching` and inspected at the join point.

### The classic mistake

```kotlin
// ❌ Bad: coroutineScope used where partial success was intended
suspend fun loadDashboard(): Dashboard = coroutineScope {
    val weather  = async { weatherApi.today() }
    val news     = async { newsApi.headlines() }
    val calendar = async { calendarApi.next() }
    // One service down → whole dashboard fails to render
    Dashboard(weather.await(), news.await(), calendar.await())
}
```

---

## CoroutineScope construction (long-lived owners)

The same dichotomy shows up when constructing a long-lived `CoroutineScope`:

```kotlin
// Fail-fast scope (rare for long-lived owners)
val scope = CoroutineScope(Job() + Dispatchers.Default)

// Sibling-isolated scope (typical for ViewModels, Repositories, Managers)
val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
```

`viewModelScope` already uses `SupervisorJob` — one failed coroutine in a ViewModel does not crater the ViewModel.

---

## Don't mix the two without thinking

Nesting `supervisorScope { coroutineScope { ... } }` is legitimate (an inner all-or-nothing region inside an outer best-effort region), but flipping the order — `coroutineScope { supervisorScope { ... } }` — is usually a confused refactor. Audit when you see either.

---

## Related rules

- [Coroutines Patterns](coroutines-patterns.md) — Structured concurrency, dispatchers, Flow
- [No GlobalScope, inject dispatcher](no-global-scope-inject-dispatcher.md) — Companion testability rule

---

## References

- [kotlinx.coroutines: exception handling](https://github.com/Kotlin/kotlinx.coroutines/blob/master/docs/topics/exception-handling.md) — SupervisorJob / supervisorScope semantics
- [Coroutines overview](https://kotlinlang.org/docs/coroutines-overview.html) — Structured-concurrency primer

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
