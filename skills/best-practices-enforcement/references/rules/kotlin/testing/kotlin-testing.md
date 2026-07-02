# Kotlin Testing

Use MockK for Kotlin-first mocking, kotlinx-coroutines-test for coroutines, and Turbine for Flow testing.

---

## Use MockK for Kotlin Mocking

**Prefer MockK over Mockito** - MockK handles Kotlin features (suspend, inline, final classes) correctly.

```kotlin
// Good: MockK for suspend functions
@Test
fun `fetchUser returns user`() = runTest {
    coEvery { repository.getUser(any()) } returns User("1", "Alice")
    val result = viewModel.loadUser("1")
    coVerify { repository.getUser("1") }
}

// Bad: Mockito with suspend - requires extra setup, can fail
whenever(repository.getUser(any())).thenReturn(...)  // Suspend needs coEvery
```

**Key MockK functions:**
- `coEvery` / `coVerify` - Suspend functions
- `every` / `verify` - Regular functions
- `slot` - Capture arguments for verification

---

## Use runTest for Coroutine Tests

**Use `kotlinx-coroutines-test`** - `runTest` provides controlled dispatcher and virtual time.

```kotlin
@Test
fun `loadData updates state`() = runTest {
    coEvery { repository.fetchData() } returns testData
    viewModel.loadData()
    advanceUntilIdle()
    assertEquals(UiState.Success(testData), viewModel.uiState.value)
}
```

**Inject TestDispatcher** for ViewModels that take a CoroutineScope or dispatcher:

```kotlin
// Good: Injected dispatcher for test control
class UserViewModel(
    private val repository: UserRepository,
    private val dispatcher: CoroutineDispatcher = Dispatchers.Main.immediate
) {
    fun loadUser() = CoroutineScope(dispatcher).launch { ... }
}

@Test
fun `loadUser`() = runTest {
    val vm = UserViewModel(mockRepo, testDispatcher)
    vm.loadUser()
    advanceUntilIdle()
    // assert
}
```

---

## Use Turbine for Flow Testing

**Use Turbine** to collect Flow emissions and assert on them:

```kotlin
@Test
fun `uiState emits Loading then Success`() = runTest {
    coEvery { repository.fetch() } returns testData
    viewModel.loadData()
    viewModel.uiState.test {
        assertEquals(UiState.Loading, awaitItem())
        assertEquals(UiState.Success(testData), awaitItem())
        awaitComplete()
    }
}
```

**For StateFlow**, use `test` with `skipItems` if initial value is emitted:

```kotlin
viewModel.uiState.test {
    skipItems(1)  // Skip initial Loading
    assertEquals(UiState.Success(data), awaitItem())
}
```

---

## Mock External Dependencies

**Isolate the unit under test** - mock repositories, APIs, use cases:

```kotlin
// Good: Mock dependencies
@Test
fun `loadUser shows error on failure`() = runTest {
    coEvery { repository.getUser(any()) } throws IOException()
    viewModel.loadUser("1")
    advanceUntilIdle()
    assertTrue(viewModel.uiState.value is UiState.Error)
}
```

---

## Test Both Success and Failure Paths

**Cover conditional logic** - verify success and failure branches:

```kotlin
@Test
fun `loadUser success`() = runTest { ... }

@Test
fun `loadUser network error`() = runTest {
    coEvery { repository.getUser(any()) } throws IOException()
    // assert error state
}

@Test
fun `loadUser empty id`() = runTest {
    viewModel.loadUser("")
    // assert validation
}
```

---

## Dependencies

```kotlin
// build.gradle.kts
dependencies {
    testImplementation("io.mockk:mockk:1.13.8")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    testImplementation("app.cash.turbine:turbine:1.0.0")
}
```

---

## Related Rules

- [Coroutines Patterns](../language/coroutines-patterns.md) - Inject dispatchers for testability
- [Android Best Practices](../android/android-best-practices.md) - Architecture patterns
- [Generic Testing](../../../generic/testing/core-principles.md) - Core testing principles

---

## References

- [Android Coroutines Test](https://developer.android.com/kotlin/coroutines/test)
- [MockK Documentation](https://mockk.io/)
- [Turbine - Flow Testing](https://github.com/cashapp/turbine)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
