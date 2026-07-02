# Kotlin Development Rules

## Available Rules

### Language Features (`language/`)
**Load**: `references/rules/kotlin/language/index.md`
- **[Style Guide](language/style-guide.md)** - Kotlin naming conventions, formatting, code organization
- **[Coroutines Patterns](language/coroutines-patterns.md)** - Structured concurrency, dispatchers, error handling, Flow
- **[supervisorScope vs coroutineScope](language/supervisor-vs-coroutine-scope.md)** - Sibling-failure isolation vs fail-fast aggregation
- **[No GlobalScope, inject dispatcher](language/no-global-scope-inject-dispatcher.md)** - Lifecycle and testability mandate
- **[Sealed Classes Patterns](language/sealed-classes-patterns.md)** - Closed hierarchies, exhaustive when expressions
- **[Scope Functions](language/scope-functions.md)** - let, apply, run, with, also
- **[Extension Functions](language/extension-functions.md)** - When to use, organization, nullable receivers
- **[Result Error Handling](language/result-error-handling.md)** - Result type, runCatching, fold
- **[Collections Patterns](language/collections-patterns.md)** - Mutable vs immutable, sequences
- **[Kotlin DSL Patterns](language/kotlin-dsl-patterns.md)** - Type-safe builders, @DslMarker
- **[Context parameters over receivers](language/context-parameters-over-receivers.md)** - Kotlin 2.4 stable form
- **[stdlib Base64 and HexFormat](language/stdlib-base64-hexformat.md)** - Replace android.util.Base64 and bespoke hex helpers (Kotlin 2.2 stable)

### Android Development (`android/`)
**Load**: `references/rules/kotlin/android/index.md`
- **[Android Best Practices](android/android-best-practices.md)** - Android-specific patterns and conventions
- **[Android Performance](android/android-performance.md)** - Memory leaks, profiling, Compose performance
- **[Compose stability + Baseline Profiles](android/compose-stability-baseline-profiles.md)** - Release-mode jank-free checklist
- **[KSP over kapt](android/ksp-over-kapt.md)** - Annotation processing toolchain
- **[compilerOptions DSL](android/compiler-options-dsl.md)** - Kotlin 2.2 Gradle DSL migration

### Testing (`testing/`)
**Load**: `references/rules/kotlin/testing/index.md`
- **[Kotlin Testing](testing/kotlin-testing.md)** - MockK, coroutines-test, Turbine, ViewModel testing

### Meta (`meta/`)
**Load**: `references/rules/kotlin/meta/index.md`
- **[Kotlin Production Patterns](meta/kotlin-production-patterns.md)** - Timeouts, resource cleanup, validation
- **[Detekt version pinning](meta/detekt-version-pinning.md)** - Pin Detekt to 1.23.x; 2.0 is alpha-only

**Graph Structure**: This is a Layer 2 node that routes directly to Layer 0 leaves (rule files) based on keywords.

---

## Keyword -> File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **kotlin style**, kotlin formatting, kotlin naming, style guide | `language/style-guide.md` |
| **kotlin coroutines**, coroutines, structured concurrency, dispatchers, flow | `language/coroutines-patterns.md` |
| **kotlin sealed**, sealed classes, sealed interfaces, exhaustive when | `language/sealed-classes-patterns.md` |
| **scope functions**, let apply run with also | `language/scope-functions.md` |
| **extension functions**, kotlin extensions | `language/extension-functions.md` |
| **result type**, runCatching, kotlin error handling | `language/result-error-handling.md` |
| **kotlin collections**, mutable immutable, sequences | `language/collections-patterns.md` |
| **kotlin dsl**, type-safe builder, dsl marker | `language/kotlin-dsl-patterns.md` |
| **production**, production readiness, withTimeout, reliability | `meta/kotlin-production-patterns.md` |
| **android**, android development, android architecture, mvvm android, compose | `android/android-best-practices.md` |
| **android performance**, android memory leak, android profiling, compose performance | `android/android-performance.md` |
| **compose stability**, baseline profile, r8, compose jank, derivedStateOf | `android/compose-stability-baseline-profiles.md` |
| **ksp**, kapt, annotation processor, Room, Moshi, Hilt | `android/ksp-over-kapt.md` |
| **compilerOptions**, kotlinOptions, kotlin 2.2, kotlin-android-extensions | `android/compiler-options-dsl.md` |
| **supervisorScope**, coroutineScope, sibling failure, partial success | `language/supervisor-vs-coroutine-scope.md` |
| **GlobalScope**, inject dispatcher, viewModelScope, lifecycleScope | `language/no-global-scope-inject-dispatcher.md` |
| **context parameters**, context receivers, kotlin 2.4, -Xcontext-parameters | `language/context-parameters-over-receivers.md` |
| **Base64**, HexFormat, android.util.Base64, hex helper | `language/stdlib-base64-hexformat.md` |
| **detekt**, detekt version, detekt 1.23, detekt 2.0 alpha | `meta/detekt-version-pinning.md` |
| **kotlin test**, mockk, coroutines test, turbine, flow test | `testing/kotlin-testing.md` |

---

## Available Rules (Leaves)

### Language Features (`language/`)
- **[Style Guide](language/style-guide.md)** - Kotlin naming conventions, formatting, code organization
- **[Coroutines Patterns](language/coroutines-patterns.md)** - Structured concurrency, dispatchers, error handling, Flow
- **[supervisorScope vs coroutineScope](language/supervisor-vs-coroutine-scope.md)** - Sibling-failure isolation decision rule
- **[No GlobalScope, inject dispatcher](language/no-global-scope-inject-dispatcher.md)** - Lifecycle and testability mandate
- **[Sealed Classes Patterns](language/sealed-classes-patterns.md)** - Closed hierarchies, exhaustive when expressions
- **[Scope Functions](language/scope-functions.md)** - let, apply, run, with, also
- **[Extension Functions](language/extension-functions.md)** - Extension function best practices
- **[Result Error Handling](language/result-error-handling.md)** - Result type patterns
- **[Collections Patterns](language/collections-patterns.md)** - Mutable vs immutable, sequences
- **[Kotlin DSL Patterns](language/kotlin-dsl-patterns.md)** - Type-safe builders, @DslMarker
- **[Context parameters over receivers](language/context-parameters-over-receivers.md)** - Kotlin 2.4 stable form
- **[stdlib Base64 and HexFormat](language/stdlib-base64-hexformat.md)** - Kotlin 2.2 stdlib encoders

### Android Development (`android/`)
- **[Android Best Practices](android/android-best-practices.md)** - Android-specific patterns and conventions
- **[Android Performance](android/android-performance.md)** - Memory leaks, profiling, Compose performance
- **[Compose stability + Baseline Profiles](android/compose-stability-baseline-profiles.md)** - Release-mode jank-free checklist
- **[KSP over kapt](android/ksp-over-kapt.md)** - Annotation-processing toolchain
- **[compilerOptions DSL](android/compiler-options-dsl.md)** - Kotlin 2.2 Gradle DSL migration

### Testing (`testing/`)
- **[Kotlin Testing](testing/kotlin-testing.md)** - MockK, coroutines-test, Turbine

### Meta (`meta/`)
- **[Kotlin Production Patterns](meta/kotlin-production-patterns.md)** - Timeouts, resource cleanup, validation
- **[Detekt version pinning](meta/detekt-version-pinning.md)** - Pin Detekt to 1.23.x; 2.0 is alpha-only

---

## Core Principles
- **Conciseness**: Reduce boilerplate, but not at the expense of readability.
- **Safety**: Leverage null safety and type system features.
- **Interoperability**: Write Kotlin that is friendly to Java callers when necessary.
- **Coroutines**: Prefer Coroutines and Flow for asynchronous operations over callbacks or RxJava.

## References

- [Kotlin coding conventions (kotlinlang.org)](https://kotlinlang.org/docs/coding-conventions.html) — JetBrains canonical style guide
- [Android Kotlin style guide](https://developer.android.com/kotlin/style-guide) — Google Android-specific rules; pair with kotlinlang.org
- [K2 compiler migration guide](https://kotlinlang.org/docs/k2-compiler-migration-guide.html) — Stable + default since Kotlin 2.0
- [Coroutines overview](https://kotlinlang.org/docs/coroutines-overview.html) — Suspend / Job / Dispatcher / Flow / StateFlow
- [kotlinx.coroutines: exception handling](https://github.com/Kotlin/kotlinx.coroutines/blob/master/docs/topics/exception-handling.md) — SupervisorJob, supervisorScope, CoroutineExceptionHandler
- [Android coroutines best practices](https://developer.android.com/kotlin/coroutines/coroutines-best-practices) — Inject dispatchers, no GlobalScope, ViewModel scope, cancellability
- [KSP overview](https://kotlinlang.org/docs/ksp-overview.html) and [Why KSP](https://kotlinlang.org/docs/ksp-why-ksp.html) — Prefer KSP over kapt
- [google/ksp](https://github.com/google/ksp) — KSP2 GA; KSP1 EoLs at Kotlin 2.3 / AGP 9
- [Jetpack Compose performance](https://developer.android.com/develop/ui/compose/performance) — Baseline Profiles + R8 + stability
- [Jetpack Compose docs hub](https://developer.android.com/develop/ui/compose) — Canonical entry point
- [What's new in Kotlin 2.2](https://kotlinlang.org/docs/whatsnew22.html) — Stable guards/break-continue/multi-$; `kotlinOptions{}` is now an error
- [Detekt](https://detekt.dev/) — De-facto static analyzer; pin 1.23.x (2.0 is alpha-only)

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
