# Kotlin Collections Patterns

Default to immutable collections. Use mutable only when necessary and encapsulate. Prefer sequences for chained operations.

---

## Prefer Immutable Collections by Default

**Use `listOf`, `setOf`, `mapOf`** for read-only collections. Use mutable variants only when you need to modify.

```kotlin
// Good: Immutable by default
val items: List<String> = listOf("a", "b", "c")
val config: Map<String, String> = mapOf("key" to "value")

// Good: Mutable only when building
val builder = mutableListOf<String>()
items.forEach { builder.add(it.uppercase()) }
val result = builder.toList()  // Expose immutable

// Bad: Unnecessary mutable
val items = mutableListOf("a", "b", "c")  // Never modified - use listOf
```

---

## Encapsulate Mutable Collections

**Keep mutable collections private.** Expose read-only views via properties or `toList()`.

```kotlin
// Good: Private mutable, public immutable
class UserRepository {
    private val _users = mutableListOf<User>()
    val users: List<User> get() = _users.toList()

    fun add(user: User) { _users.add(user) }
}

// Bad: Exposing mutable collection
class UserRepository {
    val users = mutableListOf<User>()  // Callers can modify!
}
```

---

## Use Sequences for Chained Operations

**Prefer `asSequence()`** when chaining `map`, `filter`, etc. to avoid intermediate collections.

```kotlin
// Good: Sequence - no intermediate lists
val result = items
    .asSequence()
    .filter { it.isActive }
    .map { it.name }
    .toList()

// Acceptable: Direct chain for small collections
val result = items.filter { it.isActive }.map { it.name }

// Bad: Multiple intermediate collections for large data
val filtered = items.filter { ... }  // New list
val mapped = filtered.map { ... }     // Another new list
```

---

## Choose the Right Collection Type

**List** for ordered, possibly duplicate elements. **Set** for unique elements. **Map** for key-value pairs.

```kotlin
// Good: Set for uniqueness
val uniqueIds: Set<String> = items.map { it.id }.toSet()

// Good: Map for lookup
val byId: Map<String, User> = users.associateBy { it.id }

// Bad: List when Set is needed
val ids = items.map { it.id }  // May contain duplicates
```

---

## Return Immutable from Public APIs

**Never return mutable collections** from public functions. Callers may mutate and break invariants.

```kotlin
// Good: Return copy or immutable view
fun getItems(): List<Item> = internalList.toList()

// Bad: Returning mutable
fun getItems(): MutableList<Item> = internalList  // Caller can mutate
```

---

## Related Rules

- [Style Guide](style-guide.md) - Prefer val, expression bodies
- [Android Performance](../android/android-performance.md) - Avoid allocations in loops

---

## References

- [Kotlin Collections Overview](https://kotlinlang.org/docs/collections-overview.html)
- [Kotlin Collections Guide](https://www.baeldung.com/kotlin/collection-guide)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
