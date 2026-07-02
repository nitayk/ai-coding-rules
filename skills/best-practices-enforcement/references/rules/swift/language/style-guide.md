# Swift Style Guide

## 1. Naming
- **Classes/Structs/Enums**: PascalCase.
- **Functions/Variables**: camelCase.
- **Protocols**: PascalCase (often ending in `able`, `ible`, or `Protocol`).

## 2. Formatting
- **Indentation**: 4 spaces.
- **Line Length**: 100-120 characters.
- **Braces**: K&R style (opening brace on same line).

## 3. Best Practices
- **Safety**: Prefer `if let` or `guard let` for optional unwrapping. Avoid forced unwrapping (`!`).
- **Structs vs Classes**: Prefer `struct` (value types) by default. Use `class` only when reference semantics or inheritance are needed.
- **Access Control**: Use `private` and `fileprivate` to restrict access appropriately.
- **Extensions**: Use extensions to organize code and implement protocols.

## 4. Error Handling
- Use `do-try-catch` blocks.
- Define custom error types using `enum` conforming to `Error`.

## 5. Concurrency
- Use modern `async/await` where possible (iOS 15+, Swift 5.5+).
- For older codebases, use GCD (`DispatchQueue`) with caution regarding retain cycles (`[weak self]`).
- For Swift 6 language-mode mechanics and `Sendable` see [`swift-concurrency-patterns.md`](swift-concurrency-patterns.md) and [`strict-concurrency-migration.md`](strict-concurrency-migration.md).

## 6. Enforcement Stack

Use **two tools, different jobs** — see [`../tooling/swift-format-and-swiftlint.md`](../tooling/swift-format-and-swiftlint.md) for full config.

- **[swift-format](https://github.com/swiftlang/swift-format)** (Apple, bundled with Xcode 16+) — owns layout: indentation, line wrapping, brace placement, import ordering.
- **[SwiftLint](https://github.com/realm/SwiftLint)** (community, ~200 rules) — owns semantic rules: force-unwraps, cyclomatic complexity, naming, deprecated API usage, custom regex rules.

Pipeline: run swift-format first (it rewrites layout), then SwiftLint (it lints semantics on the formatted output). Disable SwiftLint's layout rules (`line_length`, `trailing_whitespace`, etc.) to avoid overlap.

## References

- [Google Swift Style Guide](https://google.github.io/swift/) — most-cited public guide; swift-format's rule basis
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) — official naming conventions
- [swift-format](https://github.com/swiftlang/swift-format)
- [SwiftLint rule directory](https://realm.github.io/SwiftLint/rule-directory.html)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
