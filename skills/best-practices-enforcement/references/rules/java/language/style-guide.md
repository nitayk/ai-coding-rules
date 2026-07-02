# Java Style Guide

## 1. Formatting
- **Indentation**: 2 spaces (Google standard).
- **Line Length**: 100 characters.
- **Braces**: K&R style (opening brace on same line).

## 2. Naming
- **Classes**: PascalCase.
- **Methods/Variables**: camelCase.
- **Constants**: UPPER_SNAKE_CASE (`static final`).

## 3. Best Practices
- **Annotations**: Always use `@Override`.
- **Visibility**: Minimize visibility (prefer `private` or package-private).
- **Final**: Use `final` for immutable variables and fields where possible.
- **Exceptions**: Catch specific exceptions, never `catch (Exception e)` without a very good reason.
- **Imports**: Avoid wildcard imports (`import foo.bar.*`); use explicit imports for clarity and to prevent accidental shadowing.
- **Formatting**: Use auto-formatters (e.g., `google-java-format`) for consistency.

## 4. Kotlin Interop
- **Nullability Annotations**: 
  - `@androidx.annotation.NonNull` or `@javax.annotation.Nonnull`
  - `@androidx.annotation.Nullable` or `@javax.annotation.Nullable`
  - Critical for Kotlin to treat types as `T` or `T?` instead of platform types `T!`.
- **Getters/Setters**: Follow standard JavaBean naming (`getFoo`, `setFoo`) for Kotlin property access syntax support.

---

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../../../generic/code-quality/core-principles.md) - Universal principles (meaningful names, code organization, comments)

**Java-Specific:**
- This file provides Java-specific style conventions (Google Java Style Guide)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
