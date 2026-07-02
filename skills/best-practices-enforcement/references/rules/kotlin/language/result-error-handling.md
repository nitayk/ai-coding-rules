# Kotlin Result Type

Use `Result<T>` for expected, recoverable failures. Prefer over exceptions when you need explicit handling and preserved control flow.

---

## When to Use Result vs Sealed Classes

**Use `Result<T>`** for wrapping operations that may throw (I/O, parsing, external APIs). Standard library support, `runCatching`, `getOrElse`.

**Use sealed classes** when you need domain-specific error variants, custom error types, or exhaustive when handling with rich data.

```kotlin
// Good: Result for simple success/failure
fun parseJson(json: String): Result<User> = runCatching { Json.decodeFromString(json) }

// Good: Sealed class for domain errors with variants
sealed class ApiResponse<out T> {
    data class Success<T>(val data: T) : ApiResponse<T>()
    data class HttpError(val code: Int) : ApiResponse<Nothing>()
    object NetworkError : ApiResponse<Nothing>()
}
```

---

## Use runCatching for Automatic Wrapping

**Wrap throwing code** with `runCatching` to convert exceptions to Result:

```kotlin
// Good: runCatching wraps exceptions
fun divide(a: Int, b: Int): Result<Int> = runCatching { a / b }

// Good: Suspend with runCatching
suspend fun fetchUser(id: String): Result<User> = runCatching {
    api.getUser(id)
}

// Bad: Manual try-catch when runCatching suffices
fun divide(a: Int, b: Int): Result<Int> {
    return try {
        Result.success(a / b)
    } catch (e: Exception) {
        Result.failure(e)
    }
}
```

---

## Handle Both Success and Failure

**Always handle the failure case.** Use `fold`, `getOrElse`, or exhaustive `when`:

```kotlin
// Good: fold for unified handling
result.fold(
    onSuccess = { showUser(it) },
    onFailure = { showError(it.message) }
)

// Good: getOrElse with default
val value = result.getOrElse { return@getOrElse default }

// Bad: Ignoring failure
val value = result.getOrNull() ?: return  // Loses error context
```

---

## Use flatMap for Chaining, Not map

**Avoid `Result<Result<T>>`** - use `flatMap` when the next operation returns Result:

```kotlin
// Good: flatMap for chaining
fun loadUser(id: String): Result<User> = runCatching { fetchUser(id) }
    .flatMap { runCatching { parseUser(it) } }

// Bad: map produces Result<Result<User>>
runCatching { fetchUser(id) }
    .map { runCatching { parseUser(it) } }  // Nested Result!
```

---

## Avoid runCatching for Coroutine Suspend Functions

**Coroutine cancellation** must propagate. `runCatching` catches all Throwables including `CancellationException`, which breaks structured concurrency.

```kotlin
// Good: try/catch that rethrows CancellationException
suspend fun fetchUser(id: String): Result<User> {
    return try {
        Result.success(api.getUser(id))
    } catch (e: CancellationException) {
        throw e  // Must propagate
    } catch (e: Exception) {
        Result.failure(e)
    }
}

// Bad: runCatching swallows CancellationException
viewModelScope.launch {
    runCatching { suspendFetch() }  // Prevents cancellation propagation
}
```

---

## Related Rules

- [Sealed Classes Patterns](sealed-classes-patterns.md) - Domain error modeling
- [Coroutines Patterns](coroutines-patterns.md) - Error handling in coroutines

---

## References

- [Kotlin Result](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-result/)
- [Functional Error Handling in Kotlin](https://www.baeldung.com/kotlin/functional-error-handling)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
