# Kotlin Extension Functions

Add behavior to existing types without inheritance. Prefer extensions over static utility methods for readability and discoverability.

---

## When to Use Extension Functions

**Use extensions when:**
- Adding utility methods to types you don't control (stdlib, third-party)
- Functions that operate primarily on a single object
- Replacing Java-style static helpers for cleaner call sites

```kotlin
// Good: Extension - readable call site
val escaped = input.escapeForXml()

// Bad: Static utility - less discoverable
val escaped = StringUtils.escapeForXml(input)
```

---

## Organize by Ownership

**For types you own:** Define extensions in the same file as the class when they are core to the type's API.

**For types you don't own:** Create separate extension files (e.g., `StringExtensions.kt`, `ContextExtensions.kt`).

```kotlin
// Good: Extension in same file for owned type
class User(val id: String, val name: String)

fun User.displayName(): String = "$name ($id)"

// Good: Separate file for stdlib/third-party
// StringExtensions.kt
fun String.escapeForXml(): String = ...
```

---

## Use Nullable Receivers for Optional Behavior

**Extension on nullable type** handles null at call site without explicit checks:

```kotlin
// Good: Nullable receiver - call site stays clean
fun String?.orEmpty(): String = this ?: ""

val display = nullableName.orEmpty()

// Bad: Caller must null-check
fun orEmpty(s: String?): String = s ?: ""
val display = orEmpty(nullableName)
```

---

## Keep Extensions Focused

**One logical operation per extension.** Avoid extensions that do multiple unrelated things.

```kotlin
// Good: Focused extension
fun String.toSlug(): String = lowercase().replace(Regex("[^a-z0-9]+"), "-").trim('-')

// Bad: Extension doing too much
fun String.processAndValidateAndFormat(): String { ... }
```

---

## Avoid Shadowing Members

**Don't create extensions that shadow existing members** - causes confusion and breaks polymorphism.

```kotlin
// Bad: Shadows List.size
fun List<*>.size(): Int = 0  // Never use - breaks expectations

// Good: Add new behavior, don't replace
fun List<*>.isEmptyOrNull(): Boolean = isEmpty()
```

---

## Prefer Extension Properties for Simple Accessors

**Use extension properties** when the value is derived from the receiver without side effects:

```kotlin
// Good: Extension property
val String.isValidEmail: Boolean
    get() = Regex("^[\\w.-]+@[\\w.-]+\\.\\w+$").matches(this)

// Acceptable: Extension function for consistency
fun String.isValidEmail(): Boolean = ...
```

---

## Related Rules

- [Scope Functions](scope-functions.md) - let, apply, run, with, also
- [Style Guide](style-guide.md) - Kotlin conventions

---

## References

- [Kotlin Extension Functions](https://kotlinlang.org/docs/extensions.html)
- [Extension Functions - Baeldung](https://www.baeldung.com/kotlin/extension-methods)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
