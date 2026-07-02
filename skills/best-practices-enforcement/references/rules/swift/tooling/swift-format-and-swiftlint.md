# swift-format + SwiftLint (the two-tool stack)

Swift's code-style automation splits cleanly across two tools that do **different jobs** and should run together:

- **[swift-format](https://github.com/swiftlang/swift-format)** — Apple's official formatter, now under the `swiftlang` org. Handles layout: indentation, line wrapping, brace placement, import ordering. Bundled with Xcode 16+ (Editor → Structure → Format File With swift-format).
- **[SwiftLint](https://github.com/realm/SwiftLint)** — Realm-maintained community linter. Handles semantic rules: force-unwrap detection, cyclomatic complexity, missing docs, type-name conventions, deprecated API usage. ~200 built-in rules.

There is non-zero overlap (both can enforce indentation), but in practice you let swift-format own layout and SwiftLint own semantics — see the rule-split table below.

Source: [swiftlang/swift-format](https://github.com/swiftlang/swift-format) · [realm/SwiftLint](https://github.com/realm/SwiftLint) · [Google Swift Style Guide](https://google.github.io/swift/) (swift-format's default rule basis).

---

## Rule-split: who owns what

| Concern | swift-format | SwiftLint |
|---|---|---|
| Indentation, line length, brace style | ✅ owns | leave off |
| Import grouping and ordering | ✅ owns | leave off |
| Trailing whitespace, blank lines | ✅ owns | leave off |
| Force unwraps (`!`), force-try (`try!`) | — | ✅ owns |
| Cyclomatic complexity, function length | — | ✅ owns |
| Type naming (PascalCase / camelCase) | partial | ✅ owns (more configurable) |
| Missing docs on public API | partial | ✅ owns |
| Custom regex rules | — | ✅ owns |
| Auto-fix on save | ✅ (Xcode 16+ built-in) | ✅ (`swiftlint --fix`) |

Run swift-format first (reformats), then SwiftLint (lints the formatted output). This avoids spurious lint errors caused by formatter rewrites.

---

## swift-format config (`.swift-format` at repo root)

```json
{
  "version": 1,
  "lineLength": 120,
  "indentation": { "spaces": 4 },
  "tabWidth": 4,
  "respectsExistingLineBreaks": true,
  "lineBreakBeforeControlFlowKeywords": false,
  "lineBreakBeforeEachArgument": false,
  "indentConditionalCompilationBlocks": false,
  "rules": {
    "AllPublicDeclarationsHaveDocumentation": false,
    "AlwaysUseLowerCamelCase": true,
    "DoNotUseSemicolons": true,
    "FileScopedDeclarationPrivacy": true,
    "NoLeadingUnderscores": false
  }
}
```

```bash
# Format in place (Xcode 16+ ships the binary; older Xcode: brew install swift-format)
swift-format format --in-place --recursive Sources/ Tests/

# Lint only (no rewrite) — useful in CI
swift-format lint --strict --recursive Sources/ Tests/
```

```swift
// ✅ Good: SwiftPM plugin invocation — runs as part of `swift package format-source-code`
// In Package.swift:
.target(
    name: "MyTarget",
    plugins: [.plugin(name: "Format", package: "swift-format")]
)
```

---

## SwiftLint config (`.swiftlint.yml` at repo root)

```yaml
included:
  - Sources
  - Tests

excluded:
  - .build
  - Carthage
  - Pods
  - "**/Generated"

# Disable rules already owned by swift-format
disabled_rules:
  - line_length
  - trailing_whitespace
  - vertical_whitespace
  - opening_brace
  - statement_position

# Opt-in rules worth turning on
opt_in_rules:
  - empty_count
  - explicit_init
  - force_unwrapping
  - implicit_return
  - first_where
  - last_where
  - sorted_imports
  - toggle_bool
  - unused_import

# Tune defaults
cyclomatic_complexity:
  warning: 12
  error: 20

function_body_length:
  warning: 60
  error: 120

identifier_name:
  min_length: 2
  excluded: [id, x, y, z, db]

# Repo-specific custom rules
custom_rules:
  no_print_in_production:
    name: "No print() in production code"
    regex: '^\s*print\('
    message: "Use Logger / os_log instead of print()"
    severity: warning
    excluded:
      - "Tests/.*"
      - "Examples/.*"
```

```bash
# Lint (read-only) — fail CI on any violation
swiftlint lint --strict

# Auto-fix the fixable subset
swiftlint --fix
```

```swift
// ✅ Good: SwiftLint as a SwiftPM build-tool plugin (runs on every build)
.target(
    name: "MyTarget",
    plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
)
```

```swift
// ❌ Bad: invoking SwiftLint via a shell script phase that hardcodes /opt/homebrew —
// breaks on Intel Macs and CI runners
```

---

## Xcode 16 bundled formatter

Xcode 16+ ships swift-format as a built-in editor command (Editor → Structure → Format File With swift-format). It uses Xcode's **default** settings, not your repo's `.swift-format` file, unless you configure the project's Format on Save behavior to pick it up via the SwiftPM plugin path.

For consistency: rely on a **repo-pinned** swift-format (via SwiftPM dep or `brew`) for CI, and configure the bundled Xcode formatter only as a developer convenience. The CI gate is the source of truth.

---

## Recommended pipeline

```bash
# .git/hooks/pre-commit (or via lefthook/husky)
swift-format format --in-place --recursive Sources/ Tests/
swiftlint --fix --quiet
swiftlint lint --strict --quiet  # fail commit if any unfixable issue remains
```

```yaml
# .github/workflows/lint.yml (CI mirror)
- run: swift-format lint --strict --recursive Sources/ Tests/
- run: swiftlint lint --strict --reporter github-actions-logging
```

CI runs `lint` (no auto-fix) — auto-fix on CI hides drift. Developers run `--fix` locally before pushing.

---

## What about SwiftLint's autocorrect overlap with swift-format?

SwiftLint historically grew layout rules (`trailing_whitespace`, `line_length`, `opening_brace`) because no official formatter existed. With swift-format now bundled in Xcode, the community consensus is to **disable SwiftLint's layout rules** (the `disabled_rules:` block above) and let swift-format own that surface. SwiftLint focuses on the semantic rules where it remains uniquely valuable.

---

## Related rules

- [Style Guide](../language/style-guide.md) — naming and structural conventions both tools enforce
- [Swift Package Manager](swift-package-manager.md) — host config for the SwiftPM plugin variants

---

## References

- [swiftlang/swift-format](https://github.com/swiftlang/swift-format) — official formatter, v602.0.0+ bundled with Xcode 16+
- [realm/SwiftLint](https://github.com/realm/SwiftLint) — de-facto community linter, v0.63+
- [Google Swift Style Guide](https://google.github.io/swift/) — the rule basis swift-format ships
- [SwiftLint rules reference](https://realm.github.io/SwiftLint/rule-directory.html) — all ~200 rules

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
