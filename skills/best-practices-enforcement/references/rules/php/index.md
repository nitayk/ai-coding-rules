# PHP Development Rules

**PHP-Specific Rules**: Implementation details for PHP code.

**How It Works**:
- Generic rules (SOLID, DRY, KISS, correctness first) load **automatically** when you open PHP files
- This index loads **automatically** when you open PHP files (via globs)
- Use this to discover PHP-specific patterns (PHP 8+ features, type declarations, static analysis)

**Key Principle**: This directory contains ONLY PHP-specific patterns. Universal principles are in `generic/` and load automatically - they're referenced from here.

**Graph Structure**: This is a Layer 2 node that routes directly to Layer 0 leaves (rule files) based on keywords. Flattened for efficiency.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **php**, php language, modern php, php patterns, php 8 | `language/modern-php-patterns.md` |
| **php style**, php formatting, PSR, PSR-1, PSR-12, PSR-4, naming | `language/style-guide.md` |
| **php testing**, phpunit, php mock, unit test | `testing/php-testing-patterns.md` |
| **php security**, sql injection, xss, csrf, prepared statement | `meta/php-security-patterns.md` |
| **php production**, opcache, php-fpm, composer deploy | `meta/php-production-patterns.md` |

---

## Available Rules (Leaves)

### Language Features (`language/`)
- **[Modern PHP Patterns](language/modern-php-patterns.md)** - PHP 8+ features, type safety, static analysis, SOLID principles
- **[Style Guide](language/style-guide.md)** - PSR-1, PSR-12, PSR-4, naming conventions

### Testing (`testing/`)
- **[PHP Testing Patterns](testing/php-testing-patterns.md)** - PHPUnit, mocking, AAA, design for testability

### Meta (`meta/`)
- **[PHP Security Patterns](meta/php-security-patterns.md)** - SQL injection, XSS, CSRF, input validation
- **[PHP Production Patterns](meta/php-production-patterns.md)** - OPcache, PHP-FPM, Composer, error handling

## Core Principles
- **Type Safety**: Use type declarations everywhere
- **Modern PHP**: Leverage PHP 8+ features (enums, readonly, match, named arguments)
- **Static Analysis**: Use PHPStan or Psalm
- **SOLID Principles**: Follow SOLID for maintainable code

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../generic/code-quality/core-principles.md) - Universal SOLID, DRY, KISS, YAGNI principles
- [Generic Architecture Principles](../../generic/architecture/core-principles.md) - Universal architecture principles
- [Generic Error Handling Principles](../../generic/error-handling/universal-patterns.md) - Universal error handling patterns

**PHP-Specific:**
- This directory contains PHP-specific implementations and examples

---

## Key Resources
- [PHP The Right Way](https://phptherightway.com/)
- [PHP Documentation](https://www.php.net/docs.php)
- [PHPStan](https://phpstan.org/)
- [Psalm](https://psalm.dev/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
