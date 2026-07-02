# Kotlin Production Patterns

Patterns for production-ready Kotlin/Android apps. Focus on reliability, timeouts, and proper resource handling.

---

## Add Timeouts to Outbound Calls

**Fail fast.** Use `withTimeout` or `withTimeoutOrNull` for network and I/O operations.

```kotlin
// Good: Timeout on API call
suspend fun fetchUser(id: String): User = withContext(Dispatchers.IO) {
    withTimeout(10.seconds) {
        api.getUser(id)
    }
}

// Good: withTimeoutOrNull for optional timeout handling
suspend fun fetchWithFallback(id: String): User? {
    return withTimeoutOrNull(5.seconds) {
        api.getUser(id)
    } ?: cachedUser(id)
}

// Bad: No timeout - slow network blocks indefinitely
suspend fun fetchUser(id: String) = api.getUser(id)
```

**Note:** `withTimeout` throws `TimeoutCancellationException`. Handle or let it propagate. `withTimeoutOrNull` returns null on timeout.

---

## Clean Up Resources in Coroutines

**Timeout cancels the block** - ensure resources acquired inside are released. Use `try/finally` or `use` for closeables.

```kotlin
// Good: Cleanup in finally
withTimeout(5.seconds) {
    val connection = openConnection()
    try {
        connection.fetch()
    } finally {
        connection.close()
    }
}

// Good: use for Closeable
withTimeout(5.seconds) {
    FileInputStream(path).use { it.readBytes() }
}

// Bad: Resource leak on timeout
withTimeout(5.seconds) {
    val connection = openConnection()
    connection.fetch()  // If timeout, connection never closed
}
```

---

## Validate Input at Boundaries

**Never trust external input.** Validate at API boundaries, user input, and intent extras.

```kotlin
// Good: Validation at boundary
fun parseUserId(s: String): Result<UserId> = runCatching {
    require(s.isNotBlank()) { "User ID cannot be blank" }
    require(s.all { it.isDigit() }) { "Invalid user ID format" }
    UserId(s.toLong())
}

// Good: Sealed class for validation result
sealed class ValidationResult {
    data class Valid<T>(val value: T) : ValidationResult()
    data class Invalid(val message: String) : ValidationResult()
}

// Bad: Trusting input
fun loadUser(id: String) = repository.getUser(id.toLong())  // Crashes on invalid input
```

---

## Avoid Blocking in Coroutines

**Use `withContext(Dispatchers.IO)`** for blocking calls. Never block the main thread or `Dispatchers.Default`.

```kotlin
// Good: Switch to IO for blocking
suspend fun readFile(path: String): String = withContext(Dispatchers.IO) {
    File(path).readText()
}

// Bad: Blocking on main/default
suspend fun readFile(path: String): String = File(path).readText()  // Blocks!
```

---

## Handle TimeoutCancellationException Appropriately

**Don't swallow timeout.** Either handle explicitly or let it propagate for upstream handling.

```kotlin
// Good: Explicit timeout handling
suspend fun fetchWithRetry(id: String): User {
    return try {
        withTimeout(5.seconds) { api.getUser(id) }
    } catch (e: TimeoutCancellationException) {
        throw ApiTimeoutException("User fetch timed out", e)
    }
}

// Good: withTimeoutOrNull when null is acceptable
val user = withTimeoutOrNull(3.seconds) { api.getUser(id) }
    ?: return@launch  // Or show error to user
```

---

## Related Rules

- [Coroutines Patterns](../language/coroutines-patterns.md) - Dispatchers, error handling
- [Result Error Handling](../language/result-error-handling.md) - runCatching, fold
- [Android Performance](../android/android-performance.md) - Memory, profiling

---

## References

- [Kotlin Cancellation and Timeouts](https://kotlinlang.org/docs/cancellation-and-timeouts.html)
- [Android Coroutines Best Practices](https://developer.android.com/kotlin/coroutines/coroutines-best-practices)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
