---
name: scala-dependency-hell
description: "Use when library upgrades have group ID changes (e.g., Play JSON 2.x to 3.x), NoClassDefFoundError at runtime, binary incompatibility warnings, duplicate class errors in sbt assembly, or test failures with class loading exceptions. Do NOT use for simple version bumps without group ID changes or when conflicts are already resolved. Prefer `/scala-upgrade-agent` when the primary goal is bumping the Scala compiler/stdlib version itself (then use this skill if dependency graph conflicts remain)."
---
# Scala Dependency Hell Resolution

Systematic approach to detecting, analyzing, and resolving Scala/SBT dependency conflicts, especially during library upgrades with group ID changes.

## When to Use This Skill

**APPLY WHEN:**
- Library upgrades with group ID changes (e.g., Play JSON: `com.typesafe.play` to `org.playframework`)
- NoClassDefFoundError or ClassNotFoundException at runtime despite successful compilation
- Binary incompatibility warnings in SBT
- Duplicate class errors during `sbt assembly`
- Test failures with class loading exceptions after dependency upgrades

**DO NOT USE WHEN:**
- Simple version bumps without group ID changes
- Conflicts already resolved

## Core Problem

When a library changes its Maven group ID, SBT cannot automatically evict the old version. Both versions end up on classpath, causing binary incompatibility and runtime failures.

## Process

### Phase 1: Identify Affected Modules

```bash
sbt "projects" | grep -E "module-pattern"
sbt "show <module>/dependencyTree" > /tmp/dep-tree-<module>.txt
grep -E "(old-group-id|new-group-id)" /tmp/dep-tree-*.txt
```

### Phase 2: Detect Runtime Conflicts

```scala
// project/plugins.sbt
addSbtPlugin("com.github.xuwei-k" % "sbt-conflict-classes" % "0.2.0")
```

```bash
sbt conflictClasses
```

### Phase 3: Resolution Strategies

**Global exclusions** (recommended for group ID changes):

```scala
excludeDependencies ++= Seq(
  ExclusionRule("old.group.id", "library-name_2.13"),
  ExclusionRule("old.group.id", "library-name").withCrossVersion(CrossVersion.binary)
)
```

**Transitive exclusions**: Use `excludeAll(ExclusionRule(...))` on specific dependencies

**Assembly merge strategies**: For unavoidable conflicts, use targeted `MergeStrategy.first` or `MergeStrategy.concat`

**Dependency overrides**: For specific versions, use `dependencyOverrides` (sparingly)

### Phase 4: Verification

```bash
sbt clean
sbt "<module>/undeclaredCompileDependencies"
sbt "<module>/unusedCompileDependencies"
sbt conflictClasses
sbt "show <module>/dependencyTree" | grep -E "(conflict|evicted|WARN)"
sbt "<module>/assembly"
sbt "<module>/test"
```

**Verification**: Run full test suite before pushing. Check runtime classpath for old group IDs.

## Common Patterns

**Play JSON 2.x to 3.x**: Add `org.playframework` explicitly, exclude `com.typesafe.play`. If using JodaWrites/JodaReads, include `play-json-joda` from new group.

**Akka to Pekko**: Exclude `com.typesafe.akka`, add `org.apache.pekko` dependencies.

## Key Principles

1. Group ID changes are invisible to SBT eviction - handle manually
2. Exclude globally when possible
3. Declare direct dependencies explicitly
4. Test assembly early
5. Run tests for ALL affected modules
6. Check runtime classpath - dependencyTree does not show everything

## Anti-Patterns

- Only testing one module
- Excluding without understanding
- Using MergeStrategy.first blindly
- Assuming compile = works

## References

- sbt-conflict-classes: https://github.com/xuwei-k/sbt-conflict-classes
- sbt-eviction-rules: https://github.com/scalacenter/sbt-eviction-rules

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
