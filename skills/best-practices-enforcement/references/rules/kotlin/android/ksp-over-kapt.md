# Prefer KSP over kapt

KSP (Kotlin Symbol Processing) is the strategic replacement for kapt. New modules should start on **KSP2** (default since KSP 2.0.0). kapt is in de-facto maintenance mode — the Kotlin docs for kapt explicitly steer to the [KSP migration guide](https://kotlinlang.org/docs/ksp-kapt-migration.html) as the next step, and **KSP1 will not support Kotlin 2.3+ or AGP 9+** ([google/ksp](https://github.com/google/ksp)).

The official rationale ([Why KSP](https://kotlinlang.org/docs/ksp-why-ksp.html)) cites: build-performance (Glide reported ~2x faster builds vs kapt; the KSP Glide processor itself is ~7.5x faster at code-gen), idiomatic Kotlin API instead of a Java/javac model, and no JVM dependency.

---

## When to use KSP

**Use KSP for any new annotation-processor wiring** where the processor publishes a KSP artifact:

- Room (`androidx.room:room-compiler` ships KSP)
- Moshi (`com.squareup.moshi:moshi-kotlin-codegen` ships KSP)
- Hilt (`com.google.dagger:hilt-android-compiler` supports KSP via the Hilt Gradle plugin)
- Glide (`com.github.bumptech.glide:ksp`)

```kotlin
// ✅ Good: KSP for Room (build.gradle.kts)
plugins {
    id("com.google.devtools.ksp") version "2.0.21-1.0.28"
}

dependencies {
    implementation("androidx.room:room-runtime:2.7.0")
    ksp("androidx.room:room-compiler:2.7.0")
}
```

```kotlin
// ❌ Bad: kapt for the same processor in a new module
plugins {
    id("org.jetbrains.kotlin.kapt")
}

dependencies {
    implementation("androidx.room:room-runtime:2.7.0")
    kapt("androidx.room:room-compiler:2.7.0")
}
```

---

## When kapt is still acceptable

**Only if the processor does not ship a KSP variant.** In that case, isolate the kapt module so the rest of the build stays on KSP — a single kapt module forces extra javac rounds for that module only, not the whole build.

```kotlin
// Acceptable: kapt confined to one legacy module
// :legacy-processor/build.gradle.kts
plugins {
    id("org.jetbrains.kotlin.kapt")
}

dependencies {
    kapt("com.example.legacy:processor:1.4.0") // no KSP artifact upstream
}
```

When considering kapt, first check upstream issues for a KSP port — most active processors have one in flight.

---

## Migration discipline

When migrating an existing module from kapt to KSP, follow the official migration guide step-by-step. Common pitfalls:

- **Plugin order** — apply `com.google.devtools.ksp` after `org.jetbrains.kotlin.android`.
- **Generated-source dirs** — KSP writes to `build/generated/ksp/<variant>/kotlin/` (not `build/generated/source/kapt/`); update any custom `sourceSets` blocks.
- **Mixed kapt + KSP in one module** — works, but you lose most of the KSP build-speed win because kapt still triggers stub generation. Migrate fully or not at all.

---

## Why this matters now

The end-of-life signal is concrete: KSP1 stops supporting **Kotlin 2.3 / AGP 9** (per the [google/ksp README](https://github.com/google/ksp)). Modules still on kapt will hit an upgrade wall the moment the project bumps to Kotlin 2.3 or AGP 9. Doing the KSP migration on your own schedule is much cheaper than doing it under a Kotlin-upgrade deadline.

---

## Related rules

- [Android Best Practices](android-best-practices.md) — Gradle DSL conventions
- [compilerOptions DSL migration](compiler-options-dsl.md) — Kotlin 2.2 Gradle DSL changes

---

## References

- [Why KSP](https://kotlinlang.org/docs/ksp-why-ksp.html) — Official rationale; advantages over kapt
- [KSP overview](https://kotlinlang.org/docs/ksp-overview.html) — Entry point to KSP docs
- [google/ksp](https://github.com/google/ksp) — KSP2 GA; KSP1 EoLs at Kotlin 2.3 / AGP 9
- [Migrate from kapt to KSP](https://kotlinlang.org/docs/ksp-kapt-migration.html) — Step-by-step migration guide

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
