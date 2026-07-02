# Scalafmt + Scalafix baseline

Scalafmt and Scalafix are the de-facto formatter and linter/refactor tool for Scala. **Both should be in every Scala repo**, both should run in CI, and both should fail the build on violation. They have non-overlapping responsibilities — Scalafmt rewrites whitespace and layout; Scalafix rewrites code (renames, deprecations, semantic refactors). Use them together.

Sources: [Scalafmt configuration](https://scalameta.org/scalafmt/docs/configuration.html), [Scalafix rules overview](https://scalacenter.github.io/scalafix/docs/rules/overview.html), [Scalafmt installation](https://scalameta.org/scalafmt/docs/installation.html).

---

## Core Directive

**Pin both tools, commit both config files, and gate CI on both.** Treat formatter and linter output as binary — no "mostly formatted" PRs.

---

## Scalafmt — formatter

### Minimum config

```hocon
# .scalafmt.conf
version = "3.11.1"
runner.dialect = scala213   # or scala3, or scala213source3 for cross-build
maxColumn = 120
align.preset = none
align.openParenCallSite = false
align.openParenDefnSite = false
assumeStandardLibraryStripMargin = true
rewrite.rules = [
  RedundantBraces,
  RedundantParens,
  SortModifiers,
  PreferCurlyFors
]
rewrite.redundantBraces.stringInterpolation = true
docstrings.style = Asterisk
docstrings.wrap = no
trailingCommas = preserve
```

✅ Good — `version` pinned, `runner.dialect` explicit. Both prevent surprise reformats when devs run different CLI versions or when the parser misreads Scala 3 code as 2.13.

❌ Bad:

```hocon
# Missing version → every dev formats slightly differently
maxColumn = 200    # too wide for code review
align.preset = most  # alignment churn on every variable rename
```

### CI gate

```bash
# Fail the build if formatting is not idempotent
sbt scalafmtCheckAll scalafmtSbtCheck
```

In Mill: `./mill __.checkFormat`. Run **on every PR**, not nightly.

### Pre-commit hook (optional but recommended)

```bash
# .git/hooks/pre-commit
#!/bin/bash
exec sbt scalafmtCheck scalafmtSbtCheck
```

---

## Scalafix — linter and refactor

Scalafix rules come in two flavours: **syntactic** (work on the AST, no compilation needed, cheap) and **semantic** (require the SemanticDB compiler plugin, more powerful, slower).

### Minimum config

```hocon
# .scalafix.conf
rules = [
  DisableSyntax,
  LeakingImplicitClassVal,
  NoAutoTupling,
  NoValInForComprehension,
  ProcedureSyntax,
  RedundantSyntax,
  RemoveUnused,
  OrganizeImports
]

DisableSyntax.noVars = true
DisableSyntax.noThrows = false   # allow throws in `lazy val` / Future bodies
DisableSyntax.noNulls = true
DisableSyntax.noReturns = true
DisableSyntax.noFinalize = true
DisableSyntax.noXml = true

RemoveUnused.imports = true
RemoveUnused.privates = true
RemoveUnused.locals = true
RemoveUnused.patternvars = true

OrganizeImports {
  groupedImports = Merge
  removeUnused = true
  targetDialect = Scala213
}
```

✅ Good — `DisableSyntax` flags `var`, `null`, `return`, and `.finalize`, which align with [Compiler-Friendly Types](../language/compiler-friendly-types.md) and [Make Illegal States Unrepresentable](../language/make-illegal-states-unrepresentable.md).

### Enable SemanticDB for semantic rules

```scala
// project/plugins.sbt
addSbtPlugin("ch.epfl.scala" % "sbt-scalafix" % "0.13.0")

// build.sbt
ThisBuild / scalafixDependencies += "com.github.liancheng" %% "organize-imports" % "0.6.0"
ThisBuild / semanticdbEnabled := true
ThisBuild / semanticdbVersion := scalafixSemanticdb.revision
```

### CI gate

```bash
sbt "scalafixAll --check"
```

`--check` fails if any rule would rewrite — exactly the CI semantic you want.

---

## Pattern: format → lint → compile

The right order in CI:

```yaml
# .github/workflows/ci.yml (excerpt)
- run: sbt scalafmtCheckAll scalafmtSbtCheck
- run: sbt "scalafixAll --check"
- run: sbt Test/compile
- run: sbt test
```

Running format-check **before** compile catches the cheap mistakes first and keeps the feedback loop tight.

---

## Common refactors worth automating

| Rule | What it does | When to run |
|---|---|---|
| `RemoveUnused` | Drops unused imports, vals, params | Every PR |
| `OrganizeImports` | Canonicalises import grouping/order | Every PR |
| `LeakingImplicitClassVal` | Marks `val` in implicit class as `private` | Every PR |
| `NoAutoTupling` | Forbids accidental `f(1, 2)` → `f((1, 2))` | Every PR |
| `ProcedureSyntax` | Rewrites `def foo() {` → `def foo(): Unit = {` | One-off cleanup |
| `ExplicitResultTypes` | Adds explicit return types to public defs | One-off, big diff |
| `MissingFinal` | Marks `case class`es / sealed leaves `final` | One-off |

Run the one-off rules in a dedicated PR, not mixed with feature work.

---

## Anti-patterns

### Multiple format styles per repo

❌ Bad — different sub-projects with different `.scalafmt.conf`:

```
core/.scalafmt.conf    # maxColumn = 80
api/.scalafmt.conf     # maxColumn = 120
```

✅ Good — single root `.scalafmt.conf`. Use `fileOverride` blocks if a sub-tree genuinely needs different rules:

```hocon
fileOverride {
  "glob:**/legacy/**" {
    maxColumn = 200
    rewrite.rules = []
  }
}
```

### Scalafix without CI gate

If `scalafixAll` is a manual command, devs forget. Either gate it in CI with `--check` or remove it entirely; "configured but not enforced" is worse than absent.

### Pinning to a moving target

```hocon
version = "latest.release"   # ❌ non-reproducible
```

Pin to an exact version and update via a normal dependency-bump PR.

---

## Related Rules

- [Compiler-Friendly Types](../language/compiler-friendly-types.md) — Scalafix `DisableSyntax` enforces several of these
- [Scala Code Style](../meta/scala-code-style.md) — what Scalafmt automates vs what humans still decide
- [Build Tool Selection](build-tool-selection.md) — both tools work on sbt, Mill, and Scala-CLI

---

## References

- [Scalafmt Configuration](https://scalameta.org/scalafmt/docs/configuration.html) — full HOCON reference
- [Scalafmt Installation](https://scalameta.org/scalafmt/docs/installation.html) — sbt/Mill/CLI/Maven setup
- [Scalafix Rules Overview](https://scalacenter.github.io/scalafix/docs/rules/overview.html) — built-in rule catalog
- [Scalafix Configuration](https://scalacenter.github.io/scalafix/docs/users/configuration.html) — HOCON schema
- [Official Scala Style Guide](https://docs.scala-lang.org/style/) — the spec Scalafmt implements

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
