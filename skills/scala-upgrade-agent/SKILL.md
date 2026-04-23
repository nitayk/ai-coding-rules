---
name: scala-upgrade-agent
description: "Use when upgrading Scala (e.g., 2.13.12 to 2.13.18), fixing compilation errors, resolving dependency conflicts, or addressing test failures after upgrades. Do NOT use for simple dependency version bumps without Scala upgrade or when upgrade scope is already complete."
---
# Scala Upgrade Agent

Expert agent for upgrading Scala versions (e.g., 2.13.12 to 2.13.18) and dependencies in large codebases.

## When to Use This Skill

**APPLY WHEN:**
- Upgrading Scala version
- Fixing compilation errors after upgrade
- Resolving dependency conflicts

**DO NOT USE WHEN:**
- Simple dependency version bumps without Scala upgrade
- Upgrade scope already complete

## Critical Learnings

### Silencer and WartRemover Incompatibility

Do NOT rely on `silencer` for WartRemover suppression when upgrading to Scala 2.13.18+ or with `-Xfatal-warnings`. Replace `@silent` with:
- `@SuppressWarnings(Array("org.wartremover.warts.WartName"))` for WartRemover
- `@scala.annotation.nowarn("msg=regex")` for standard scalac warnings
- Merge multiple suppressions into single annotation

### CI vs Local Discrepancies

Run `sbt undeclaredCompileDependenciesTest unusedCompileDependenciesTest` and `sbt compile` with `-Xfatal-warnings` locally to reproduce CI failures.

### ai.x vs com.gu Play JSON Extensions

`ai.x:play-json-extensions:0.42.0` is binary-incompatible with Scala 2.13.18. Replace with `com.gu:play-json-extensions:1.0.4`. Update imports: `com.gu.ai.x.play.json.Jsonx` instead of `ai.x.play.json.Jsonx`.

### Duplicate @SuppressWarnings

Merge into single annotation: `@SuppressWarnings(Array("Wart1", "Wart2"))`

### Python Script Corruption

Avoid invisible null bytes when editing Scala files. Use binary mode when editing. Scan for null bytes after mass replacements.

## Process

### Step 1: Analyze

Check `build.sbt`, `plugins.sbt`, `project/` for version definitions.

### Step 2: Reproduce

Run failed CI command locally.

### Step 3: Fix

Apply code changes, config updates, or tool automation.
- Bump Scala version
- Update plugins and dependencies
- Add JVM options for large builds: `-Xss8m`, `-Xmx4G`
- Update CI workflow: `-J-Xss64m` in SBT_FLAGS

### Step 4: Verify

Compile and test locally BEFORE pushing.

### Step 5: Document

Update this skill with new findings.

## Checklist

- [ ] Bump Scala version
- [ ] Update plugins
- [ ] Update dependencies, handle package renames
- [ ] Run `sbt compile` (apply mass @silent replacement if silencer fails)
- [ ] Run `sbt test` (fix NaN assertions, JSON serialization)
- [ ] Verify CI passes

## Detailed Reference

For phases, code snippets, Play JSON migration, assembly merge strategy, and common issues: **Read `references/upgrade-guide.mdc`** (bundled with this skill).

## Last Resort

If WartRemover suppressions not working reliably: Temporarily comment out `-Xfatal-warnings` in scalacOptions. Re-enable after stabilizing.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
