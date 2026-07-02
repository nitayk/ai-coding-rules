# compilerOptions {} Gradle DSL (Kotlin 2.2+)

`kotlinOptions {}` is **no longer deprecated — it is a hard error** in Kotlin 2.2 and above. The replacement is the `compilerOptions {}` DSL on the Kotlin Gradle Plugin's task / extension types. This is one of the listed [breaking changes in Kotlin 2.2](https://kotlinlang.org/docs/whatsnew22.html).

Two other related deletions in the same release worth knowing:

- `kotlin-android-extensions` Gradle plugin is **removed** (long deprecated; use ViewBinding / Compose).
- A handful of long-deprecated stdlib symbols are removed too — see the linked release notes.

---

## What to write instead

### Module-level (per-target)

```kotlin
// ✅ Good: compilerOptions {} on the Android extension
android {
    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
            freeCompilerArgs.add("-Xjsr305=strict")
            allWarningsAsErrors.set(true)
        }
    }
}

// ✅ Good: compilerOptions on KotlinCompile tasks (multiplatform / plain JVM)
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
        freeCompilerArgs.add("-Xcontext-parameters")
    }
}
```

```kotlin
// ❌ Bad: kotlinOptions {} — fails the build on Kotlin 2.2+
android {
    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs = listOf("-Xjsr305=strict")
    }
}
```

### Property migration cheatsheet

| `kotlinOptions {}` (old)              | `compilerOptions {}` (new)                                  |
|---------------------------------------|-------------------------------------------------------------|
| `jvmTarget = "17"`                    | `jvmTarget.set(JvmTarget.JVM_17)`                           |
| `freeCompilerArgs = listOf(...)`      | `freeCompilerArgs.set(listOf(...))` / `.add(...)`           |
| `apiVersion = "1.9"`                  | `apiVersion.set(KotlinVersion.KOTLIN_1_9)`                  |
| `languageVersion = "2.0"`             | `languageVersion.set(KotlinVersion.KOTLIN_2_0)`             |
| `allWarningsAsErrors = true`          | `allWarningsAsErrors.set(true)`                             |

The shape is now `Property<T>` everywhere — assign with `.set(...)` or use the `=` operator on Gradle's lazy property syntax. Strings are replaced with typed enums (`JvmTarget`, `KotlinVersion`).

---

## Where you'll hit it

- Any module that hasn't touched its build script since before 2024 — the silent deprecation became loud.
- Convention plugins in `buildSrc/` or `build-logic/` that wrap `kotlinOptions { ... }` in a helper — those die first, taking every consumer module with them.
- Third-party Gradle plugins that still configure `kotlinOptions` reflectively; check for plugin updates before patching downstream.

---

## Related rules

- [Android Best Practices](android-best-practices.md) — Android module patterns
- [KSP over kapt](ksp-over-kapt.md) — Other Gradle-side migration

---

## References

- [What's new in Kotlin 2.2 — Breaking changes and deprecations](https://kotlinlang.org/docs/whatsnew22.html) — `kotlinOptions{}` removal; `kotlin-android-extensions` removal
- [Kotlin Gradle plugin DSL reference](https://kotlinlang.org/docs/gradle-compiler-options.html) — Full `compilerOptions {}` API

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
