# Swift Tooling Index

**Purpose**: Router for Swift dependency management and code-quality tooling.

---

## Keyword to File Routing

| Keywords/Intent | Load File |
|-----------------|-----------|
| **swift package manager**, SPM, Package.swift, swiftSettings, dependency management, .binaryTarget | `swift-package-manager.md` |
| **swift-format**, SwiftLint, formatter, linter, .swiftlint.yml, .swift-format, pre-commit, Xcode 16 formatter | `swift-format-and-swiftlint.md` |

---

## Tooling Rule Files

| File | Purpose | Keywords |
|------|---------|----------|
| [Swift Package Manager](swift-package-manager.md) | SPM as canonical dependency manager; per-target swiftSettings | SPM, Package.swift, dependencies |
| [swift-format + SwiftLint](swift-format-and-swiftlint.md) | Two-tool formatting+linting stack with rule-split table | swift-format, SwiftLint, formatter |

---

## Related Resources

- **Language**: See `../language/index.md` for Swift language patterns (style-guide, concurrency)
- **Strict-concurrency migration**: per-target `swiftSettings` patterns documented in `../language/strict-concurrency-migration.md`

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
