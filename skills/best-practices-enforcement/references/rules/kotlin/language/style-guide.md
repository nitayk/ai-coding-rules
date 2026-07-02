# Kotlin Style Guide

## 1. Naming Conventions
- **Classes/Objects**: PascalCase (`MyClass`, `MyObject`).
- **Functions/Properties**: camelCase (`myFunction`, `myProperty`).
- **Constants**: UPPER_SNAKE_CASE (`const val MAX_COUNT = 10`).
- **Backing Properties**: `_privateProperty` for private mutable backing fields.

## 2. Formatting
- **Indentation**: 4 spaces (standard), NO TABS.
- **Line Length**: 100 characters generally, but flexible for readability.
- **Braces**: K&R style (opening brace on same line).

## 3. Idiomatic Usage
- **Null Safety**:
  - Avoid `!!` operator. Use `?` (safe call), `?:` (Elvis operator), or `let`.
  - Use `lateinit` only when dependency injection or lifecycle methods require it.
- **Immutability**: Prefer `val` over `var`.
- **Expressions**: Prefer expression bodies for simple functions.
  ```kotlin
  // Good
  fun sum(a: Int, b: Int) = a + b
  
  // Acceptable (if logic expands later)
  fun sum(a: Int, b: Int): Int {
      return a + b
  }
  ```
- **String Templates**: Use string templates (`$var` or `${expr}`) instead of concatenation.

## 4. Classes and Objects
- **Data Classes**: Use for POJOs/DTOs.
- **Sealed Classes/Interfaces**: Use for modeling restricted hierarchies (e.g., UI States, Results).
- **Companion Objects**: Place at the bottom of the class.

## 5. Control Flow
- **When Expression**: Prefer `when` over long `if-else` chains.
- **Loops**: Prefer `forEach`, `map`, `filter` on collections over manual loops.

---

## References

- [Kotlin coding conventions (kotlinlang.org)](https://kotlinlang.org/docs/coding-conventions.html) — JetBrains canonical style guide (last updated 2025-06-11); pair with the Android-specific one below.
- [Android Kotlin style guide](https://developer.android.com/kotlin/style-guide) — Google Android-flavoured rules, leans on hard rules and Java-interop concerns.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
