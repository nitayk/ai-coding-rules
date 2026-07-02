# Pin Detekt to 1.23.x (not 2.0-alpha)

[Detekt](https://detekt.dev/) is the de-facto static analyzer for Kotlin. The **stable line is 1.23.x** (1.23.8, released 2025-02-21). The 2.x line is **alpha-only** — the latest is `2.0.0-alpha.3` (2024-04-24), with no GA on the public roadmap. Production toolchains should pin **1.23.x** and treat 2.x as opt-in experiment territory only.

---

## What to write

```kotlin
// ✅ Good: pin 1.23.x in libs.versions.toml
[versions]
detekt = "1.23.8"

[plugins]
detekt = { id = "io.gitlab.arturbosch.detekt", version.ref = "detekt" }

[libraries]
detekt-formatting = { module = "io.gitlab.arturbosch.detekt:detekt-formatting", version.ref = "detekt" }
```

```kotlin
// build.gradle.kts (root)
plugins {
    alias(libs.plugins.detekt)
}

detekt {
    toolVersion = libs.versions.detekt.get()
    config.setFrom("$rootDir/config/detekt/detekt.yml")
    buildUponDefaultConfig = true
    allRules = false
}

dependencies {
    detektPlugins(libs.detekt.formatting)
}
```

```kotlin
// ❌ Bad: jumping the gun on 2.0-alpha
plugins {
    id("io.gitlab.arturbosch.detekt") version "2.0.0-alpha.3"
}
```

The 2.0 line has a different rule-pack layout and a partially-rewritten engine. Third-party detekt rule packs (twitter-detekt, detekt-hint, etc.) target 1.23.x — most will not load against 2.0-alpha.

---

## Common pitfalls on 1.23.x

- **Kotlin compiler version mismatch.** Detekt 1.23.x bundles a specific kotlin-compiler-embeddable. If your project is on Kotlin 2.0+ with K2, set `detekt { toolVersion = "1.23.8" }` explicitly — letting the plugin pick the version sometimes resolves to an older 1.x that pre-dates K2.
- **`baseline.xml` drift.** Generate the baseline once with `./gradlew detektBaseline`, commit it, and treat new violations as build failures. Without a baseline, every new author chases pre-existing warnings.
- **`buildUponDefaultConfig = true`** is correct; the default config is the source of truth. Your project YAML should only *override* keys, not redefine the entire rule set.

---

## When to evaluate 2.0

Track [github.com/detekt/detekt/releases](https://github.com/detekt/detekt/releases). Consider 2.0 only when:

1. A beta or RC ships (no longer `alpha-N`).
2. The rule packs you depend on have published 2.x-compatible builds.
3. You can dedicate a spike to re-baseline (rule names and severities have moved).

Until then, **1.23.x is the production answer.**

---

## Related rules

- [Kotlin Production Patterns](kotlin-production-patterns.md) — Companion production rules
- [Style Guide](../language/style-guide.md) — What Detekt is enforcing

---

## References

- [Detekt](https://detekt.dev/) — Project home; 1.23.8 stable, 2.0.0-alpha.3 latest 2.x
- [github.com/detekt/detekt/releases](https://github.com/detekt/detekt/releases) — Release feed (track for 2.0 GA signal)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
