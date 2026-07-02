# Prefer context parameters over context receivers

Kotlin's "context" feature shipped in two forms:

- **`context(...)` receivers** — the original 1.6.20 prototype. The values inside the block became implicit `this` receivers.
- **`context(name: Type)` parameters** — the redesigned replacement, **stabilized in Kotlin 2.4.0-RC** per the [What's new EAP](https://kotlinlang.org/docs/whatsnew-eap.html) page. Values are explicitly named and behave more like a normal parameter list.

**For new code, use context parameters.** Don't introduce new `context(...)` receiver code in modules that will outlive Kotlin 2.4 — the receivers syntax is the deprecation target, parameters are the stable form.

(Lower urgency in modules already on the iAds Android sunset path — flag in review, don't enforce a rewrite.)

---

## What context parameters look like

```kotlin
// ✅ Good: context parameter (Kotlin 2.4+)
context(logger: Logger)
fun audit(action: String) {
    logger.info("audit: $action")
}

context(logger: Logger, tx: Transaction)
fun debit(account: AccountId, cents: Long) {
    tx.update("UPDATE accounts SET balance = balance - ? WHERE id = ?", cents, account)
    logger.info("debit $cents from $account")
}

// Call site
with(loggerInstance) {
    with(txInstance) {
        debit(accountId, 100L)
    }
}
```

```kotlin
// ❌ Bad in new code: context(...) receivers form
context(Logger, Transaction)
fun debit(account: AccountId, cents: Long) {
    update("UPDATE accounts SET balance = balance - ? WHERE id = ?", cents, account) // which receiver?
    info("debit $cents from $account") // implicit, harder to read
}
```

The named-parameter form makes it explicit *which* context value a call refers to, which is the single biggest readability complaint with the receivers form.

---

## When you'd use this at all

Context parameters are for values that are **threaded through many functions but are not domain inputs**. Typical examples:

- `Logger` — every call logs, but logger is not part of the business operation.
- `Transaction` — every DB call participates, but transaction is ambient.
- `Json` / `Codec` — every serialization call uses the same instance.
- `CoroutineScope` for a region — though for coroutines, explicit `CoroutineScope` parameters are still usually clearer.

Do **not** reach for context parameters to avoid passing one or two args. They're a structural tool for code that would otherwise carry the same `Logger`/`Tx` through 20 function signatures.

---

## Migrating from `context(...)` receivers

If you have existing `context(Logger, Transaction)` code, the mechanical translation is to name each type:

```kotlin
// Before (receivers)
context(Logger, Transaction)
fun process(id: Id) { /* ... */ }

// After (parameters)
context(log: Logger, tx: Transaction)
fun process(id: Id) { /* ... */ }
```

Inside the body, replace ambiguous implicit calls with the named binding (`log.info(...)`, `tx.update(...)`).

---

## Gradle flag

```kotlin
// build.gradle.kts — opt in until your toolchain is on stable 2.4
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        freeCompilerArgs.add("-Xcontext-parameters")
    }
}
```

Once you're on Kotlin 2.4 stable, the flag becomes unnecessary.

---

## Related rules

- [Style Guide](style-guide.md) — Naming and formatting
- [Extension Functions](extension-functions.md) — The other tool for implicit receivers

---

## References

- [What's new in Kotlin (EAP)](https://kotlinlang.org/docs/whatsnew-eap.html) — Context parameters stable in 2.4.0-RC
- [What's new in Kotlin 2.2](https://kotlinlang.org/docs/whatsnew22.html) — Surrounding language-level changes

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
