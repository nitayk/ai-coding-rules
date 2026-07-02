# Kotlin Scope Functions

Choose the right scope function based on receiver reference (`this` vs `it`), return value (context object vs lambda result), and use case.

---

## Quick Reference

| Function | Receiver | Return | Use Case |
|----------|----------|--------|----------|
| `let` | `it` | Lambda result | Transformations, null-safe chains |
| `apply` | `this` | Context object | Object configuration, builder pattern |
| `run` | `this` | Lambda result | Multiple calls on object, compute result |
| `also` | `it` | Context object | Side effects (logging, validation) |
| `with` | `this` | Lambda result | Group calls (not extension) |

---

## Use `let` for Transformations and Null-Safe Chains

**Use when:** Transforming a value, chaining after null check, or passing to a function that expects a different type.

```kotlin
// Good: Null-safe transformation
val length = name?.let { it.length } ?: 0

// Good: Transform and chain
val formatted = user?.let { "${it.name} (${it.email})" }

// Good: Pass to function expecting different type
intent?.let { startActivity(it) }

// Bad: Unnecessary let when not transforming
val result = value.let { it }  // Redundant - just use value
```

---

## Use `apply` for Object Configuration

**Use when:** Configuring an object and returning it. Builder pattern, initialization blocks.

```kotlin
// Good: Object configuration
val dialog = AlertDialog.Builder(context).apply {
    setTitle("Confirm")
    setMessage("Are you sure?")
    setPositiveButton("OK") { _, _ -> }
}.create()

// Good: Initializing properties
val user = User().apply {
    name = "Alice"
    email = "alice@example.com"
}

// Bad: Using apply when you need the lambda result
val count = list.apply { size }  // Returns list, not size! Use run instead
```

---

## Use `run` for Multiple Calls with a Result

**Use when:** Calling multiple methods on an object and returning a computed value.

```kotlin
// Good: Multiple calls, return result
val size = mutableListOf("a", "b").run {
    add("c")
    size
}

// Good: Scoped block with result
val result = repository.run {
    val data = fetchData()
    process(data)
}

// Bad: run when apply is clearer for configuration
val builder = Builder().run {
    setX(1)
    setY(2)
    this  // Awkward - use apply
}
```

---

## Use `also` for Side Effects

**Use when:** Performing side effects (logging, validation) while passing through the original object.

```kotlin
// Good: Logging in chain
val user = fetchUser().also { logger.debug("Fetched: $it") }

// Good: Validation side effect
val validated = input.also { require(it.isNotBlank()) }

// Bad: Using also when you need transformation
val doubled = numbers.also { it.map { n -> n * 2 } }  // Returns original! Use let
```

---

## Use `with` for Grouping Non-Extension Calls

**Use when:** Grouping multiple calls on an object. Not an extension - pass object as argument.

```kotlin
// Good: Grouping calls
with(recyclerView) {
    layoutManager = LinearLayoutManager(context)
    adapter = myAdapter
    addItemDecoration(divider)
}

// Good: With result
val first = with(listOf(1, 2, 3)) {
    println("Size: $size")
    first()
}
```

---

## Avoid Over-Nesting

**Prefer flat chains over deeply nested scope functions:**

```kotlin
// Good: Flat, readable
val result = data
    ?.let { parse(it) }
    ?.also { validate(it) }
    ?: default

// Bad: Deep nesting
val result = data?.let { d ->
    parse(d)?.also { p ->
        validate(p)?.let { v -> process(v) }
    }
}
```

---

## Related Rules

- [Style Guide](style-guide.md) - Kotlin style conventions
- [Sealed Classes Patterns](sealed-classes-patterns.md) - Modeling outcomes

---

## References

- [Kotlin Scope Functions](https://kotlinlang.org/docs/scope-functions.html)
- [Kotlin: When to use apply, let, also, and run](https://redmugguy.dev/posts/kotlin-scope-functions)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
