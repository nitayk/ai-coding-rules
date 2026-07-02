# Kotlin DSL Patterns

Type-safe builders use lambda with receiver (`T.() -> Unit`) to create declarative, compile-time-safe DSLs.

---

## Use Lambda with Receiver for Builder Pattern

**Receiver type** gives the lambda access to the builder's methods and properties.

```kotlin
// Good: Lambda with receiver
class HtmlBuilder {
    fun body(init: Body.() -> Unit) {
        val body = Body().apply(init)
        children.add(body)
    }
}

fun html(init: HtmlBuilder.() -> Unit): HtmlBuilder {
    val html = HtmlBuilder()
    html.init()
    return html
}

// Usage
html {
    body {
        div { text("Hello") }
    }
}
```

---

## Use @DslMarker for Nested Scope Safety

**Prevent ambiguous calls** in nested DSLs. Without it, inner lambdas can accidentally call outer scope methods.

```kotlin
// Good: DslMarker restricts scope
@DslMarker
annotation class HtmlTagMarker

@HtmlTagMarker
class Body {
    fun div(init: Div.() -> Unit) { ... }
}

@HtmlTagMarker
class Div {
    fun text(s: String) { ... }
}

// With @DslMarker, div { body { } } fails - body is not in Div scope
```

---

## Provide Top-Level Entry Point

**Single entry function** that creates the root builder and invokes the lambda.

```kotlin
// Good: Clear entry point
fun html(init: HtmlBuilder.() -> Unit): HtmlBuilder = HtmlBuilder().apply(init)

// Good: With return type for chaining
fun buildConfig(init: ConfigBuilder.() -> Unit): Config = ConfigBuilder().apply(init).build()
```

---

## Use initTag Helper for Nested Builders

**Avoid duplication** when multiple tags share the same init pattern.

```kotlin
// Good: Generic helper for nested tags
protected fun <T : Element> initTag(tag: T, init: T.() -> Unit): T {
    tag.init()
    children.add(tag)
    return tag
}

fun div(init: Div.() -> Unit) = initTag(Div(), init)
fun span(init: Span.() -> Unit) = initTag(Span(), init)
```

---

## Keep DSL Scopes Focused

**Each builder type** should expose only methods relevant to its scope. Avoid leaking parent methods.

```kotlin
// Good: Div only has div-specific methods
class Div : Element() {
    fun text(s: String) { ... }
    fun span(init: Span.() -> Unit) { ... }
}

// Bad: Div inherits unrelated parent methods
class Div : Element() {
    // Exposes html(), body() from parent - confusing in nested scope
}
```

---

## Related Rules

- [Extension Functions](extension-functions.md) - Extending types
- [Scope Functions](scope-functions.md) - apply, run for builder setup

---

## References

- [Kotlin Type-Safe Builders](https://kotlinlang.org/docs/type-safe-builders.html)
- [Kotlin Builder Inference](https://kotlinlang.org/docs/using-builders-with-builder-inference.html)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
