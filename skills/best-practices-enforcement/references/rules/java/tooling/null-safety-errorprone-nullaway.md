# Null safety: Error Prone + NullAway

Runtime `NullPointerException` is one of the most common Java production failures. Java has no compiler-enforced nullness in the type system, so the modern industry standard is to **bolt a static checker onto the build** that fails the compile when nullness contracts are violated.

The de-facto pairing in 2026 is **[Error Prone](https://errorprone.info/)** (Google's static analyzer, actively maintained) + **[NullAway](https://github.com/uber/NullAway)** (Uber's null checker, runs as an Error Prone plugin). NullAway is **~10–20× faster** than a full pluggable-type checker like Checker Framework, which is the main reason it has won broad adoption.

This pairing should replace the older "decorate fields with `@Nullable` and hope" convention referenced in [style-guide.md § Kotlin Interop](../language/style-guide.md).

---

## How it works

- **Error Prone** is a `javac` plugin: it runs as part of every compile, surfaces bug patterns as warnings or errors, and ships hundreds of checks.
- **NullAway** plugs into Error Prone and adds a single, focused capability: a fast nullness checker.
- You declare nullness with `@Nullable` on parameters, return types, and fields. Anything **not** annotated is treated as `@NonNull` (the inverse of the JSR-305 default — saves annotation noise).
- The compile fails when you dereference a `@Nullable` value without a null check, or pass `null` (or a `@Nullable`) to a `@NonNull` parameter.

---

## Gradle setup (sketch)

```groovy
plugins {
    id "net.ltgt.errorprone" version "3.1.0"
}

dependencies {
    errorprone "com.google.errorprone:error_prone_core:2.27.0"
    errorprone "com.uber.nullaway:nullaway:0.11.0"
    compileOnly "com.google.code.findbugs:jsr305:3.0.2"   // for @Nullable
}

tasks.withType(JavaCompile).configureEach {
    options.errorprone {
        check("NullAway", net.ltgt.gradle.errorprone.CheckSeverity.ERROR)
        option("NullAway:AnnotatedPackages", "com.example.myservice")
    }
}
```

Set `AnnotatedPackages` to the packages **you own** — third-party code without nullness annotations is then trusted to be `@NonNull` (a deliberate scoping choice).

For Maven, configure via `maven-compiler-plugin` with the same `-Xplugin:ErrorProne` and `-XepOpt:NullAway:AnnotatedPackages=...` flags.

---

## Annotation conventions

✅ Good — annotate only what's nullable; everything else is implicitly `@NonNull`

```java
import javax.annotation.Nullable;

public class UserService {
    @Nullable
    public User findUser(String id) {           // id is @NonNull (default)
        return repository.findById(id);         // may return null
    }

    public User requireUser(String id) {        // return is @NonNull
        User u = findUser(id);
        if (u == null) throw new NotFound(id);
        return u;
    }
}
```

❌ Bad — old convention: annotate everything, including `@NonNull` on every parameter

```java
public class UserService {
    @NonNull
    public User findUser(@NonNull String id) { ... }    // noisy; pre-NullAway style
}
```

For Kotlin interop, the same `@Nullable` annotation Kotlin already recognizes (`javax.annotation.Nullable`, `androidx.annotation.Nullable`, or `org.jspecify.annotations.Nullable`) doubles as NullAway's contract — no parallel annotation system needed.

---

## What NullAway catches

```java
@Nullable User findUser(String id) { ... }

User u = findUser("123");
u.name();                                       // ERROR — dereferencing @Nullable without null check

User u2 = findUser("123");
if (u2 != null) u2.name();                      // OK — null-checked

String name = u.name();                          // ERROR if u typed @Nullable

void send(User u) { ... }                       // u is @NonNull (default)
send(findUser("123"));                          // ERROR — passing @Nullable to @NonNull
```

It also tracks **field initialization**: a `@NonNull` field that isn't set in every constructor path fails the compile.

---

## Migration strategy

1. **Add the plugin in warn mode first**: `CheckSeverity.WARN`. Walk through the existing warning list — there will be many.
2. **Annotate top-down**: start with public API on a small package, expand. Use `@NullUnmarked` to opt-out tricky transitional code.
3. **Flip to ERROR** once a package is clean — the compile then prevents regressions.
4. **JSpecify is the future**: [JSpecify](https://jspecify.dev/) is the cross-tool standard nullness annotation set (Google, Uber, JetBrains, Oracle). Prefer `org.jspecify.annotations.Nullable` on **new** code; NullAway recognizes it.

---

## Why not Checker Framework?

[Checker Framework](https://checkerframework.org/) is more powerful (full pluggable type system, many checkers beyond nullness) but is significantly slower and more invasive. NullAway is the **pragmatic** choice — it focuses on nullness, runs fast enough to keep in every CI compile, and the false-negative tradeoffs are well-documented in the project README.

Use Checker Framework when you need formal verification beyond nullness (e.g. units of measure, regex correctness, tainting). Use NullAway when you want NPE prevention in normal product code.

---

## Cross-cutting tooling pairing

- **Error Prone** also catches many non-nullness bugs (mutability mistakes, `equals`/`hashCode` mismatches, format-string errors, etc.) — keep its default checks on.
- **SpotBugs** is alive but less actively maintained than Error Prone (per the research: `last-modified 2025-03`). Use it as **supplementary** if your existing build already runs it; prefer Error Prone for new setups.

---

## Related rules

- [Style guide](../language/style-guide.md) — Kotlin-interop nullability annotations (this rule supersedes the "decorate manually" baseline)
- [Production patterns](../meta/java-production-patterns.md) — Optional usage, null-returning anti-patterns
- [Modern Java patterns](../language/modern-java-patterns.md) — Optional, records (immutable inputs)

---

## References

- [Error Prone](https://errorprone.info/) — Google static analyzer (active; `last-modified 2026-05`)
- [NullAway (Uber)](https://github.com/uber/NullAway) — Error Prone plugin for null safety
- [JSpecify](https://jspecify.dev/) — cross-tool nullness annotation standard

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
