# Never use GlobalScope; inject scope and dispatcher

`GlobalScope` is unstructured — it has no parent, no lifecycle, and no way to be cancelled by the code that owns the surrounding work. Every Android team eventually files the same bug: a `GlobalScope.launch { ... }` survives an Activity rotation, an `onCleared()`, or a logout, and writes stale data into the wrong session. The Android coroutines best-practices page lists this as the [#1 rule](https://developer.android.com/kotlin/coroutines/coroutines-best-practices): *"Inject Dispatchers" / "Avoid GlobalScope."*

The same page mandates **injecting** `CoroutineDispatcher` (not calling `Dispatchers.IO` / `Dispatchers.Default` inline), because tests cannot otherwise substitute a `TestDispatcher` and assert ordering deterministically.

---

## Inject CoroutineScope + CoroutineDispatcher

```kotlin
// ✅ Good: scope and dispatcher are constructor-injected
class SyncManager(
    private val scope: CoroutineScope,
    private val ioDispatcher: CoroutineDispatcher,
    private val api: Api,
) {
    fun startSync(): Job = scope.launch(ioDispatcher) {
        api.pull()
    }
}

// ✅ Good: production wiring (DI module)
@Provides
fun provideAppScope(): CoroutineScope =
    CoroutineScope(SupervisorJob() + Dispatchers.Default)

@IoDispatcher
@Provides
fun provideIoDispatcher(): CoroutineDispatcher = Dispatchers.IO
```

```kotlin
// ❌ Bad: GlobalScope — survives owner death, leaks
class SyncManager(private val api: Api) {
    fun startSync() {
        GlobalScope.launch(Dispatchers.IO) { api.pull() }
    }
}

// ❌ Bad: hardcoded Dispatchers.IO — untestable
class UserRepository(private val api: Api) {
    suspend fun fetch(id: String): User =
        withContext(Dispatchers.IO) { api.getUser(id) } // tests can't control timing
}
```

---

## In Android UI classes

Lifecycle-aware scopes are already provided — use them:

| Owner | Scope |
|-------|-------|
| `ViewModel` | `viewModelScope` (cancelled in `onCleared`, uses `SupervisorJob`) |
| `Fragment` view | `viewLifecycleOwner.lifecycleScope` |
| `Activity` / `Fragment` instance | `lifecycleScope` |
| `LifecycleService` | `lifecycleScope` |

```kotlin
// ✅ Good: viewModelScope — auto-cancels on onCleared()
class FeedViewModel(
    private val repo: FeedRepository,
) : ViewModel() {
    fun refresh() = viewModelScope.launch { repo.refresh() }
}
```

Never spin up a private `CoroutineScope` field inside a `ViewModel` or `Fragment` — you're re-inventing `viewModelScope` and forgetting to cancel it.

---

## Testing payoff

Injected dispatchers make tests deterministic with `kotlinx-coroutines-test`:

```kotlin
@Test
fun `syncs on background dispatcher`() = runTest {
    val testDispatcher = StandardTestDispatcher(testScheduler)
    val scope = TestScope(testDispatcher)
    val manager = SyncManager(scope, testDispatcher, fakeApi)

    manager.startSync()
    testScheduler.advanceUntilIdle()

    assertTrue(fakeApi.wasPulled)
}
```

With `withContext(Dispatchers.IO)` hardcoded, this test is either non-deterministic or requires `Dispatchers.setMain` plus brittle delays.

---

## The narrow exceptions

`GlobalScope` is acceptable in **two** situations, both rare:

1. **Truly application-lifetime work** that must outlive any other owner (e.g. enqueuing a final crash-log POST). Even then, prefer `WorkManager`.
2. **Top-level entry points in standalone tools/scripts** (CLIs, build-time codegen) where there is no other lifecycle.

Anywhere else, treat `GlobalScope` in code review as a defect.

---

## Related rules

- [Coroutines Patterns](coroutines-patterns.md) — Structured concurrency baseline
- [supervisorScope vs coroutineScope](supervisor-vs-coroutine-scope.md) — Failure-isolation choice

---

## References

- [Android coroutines best practices](https://developer.android.com/kotlin/coroutines/coroutines-best-practices) — Inject Dispatchers; avoid GlobalScope; main-safety
- [Coroutines overview](https://kotlinlang.org/docs/coroutines-overview.html) — Structured-concurrency primer

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
