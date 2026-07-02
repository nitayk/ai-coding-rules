# PHP Style Guide

Follow PSR-1, PSR-12, and PSR-4 for consistent, maintainable PHP code.

---

## Triggers

**APPLY WHEN:** Writing or formatting PHP code, setting up project structure, configuring autoloading.
**SKIP WHEN:** Only reading code without modification.

---

## Core Directive

**Follow PSR standards** - PSR-1 (basic coding standard), PSR-12 (extended coding style), PSR-4 (autoloading).

---

## PSR-1: Basic Coding Standard

**Files:**
- Use `<?php` or `<?=` only (no short tags)
- Use UTF-8 without BOM
- One class per file; class name must match filename

**Namespaces and classes:**
- Use PSR-4 autoloading
- Class names in `StudlyCaps`
- Constant names in `UPPER_SNAKE_CASE`

```php
// Good: PSR-1 compliant
<?php

namespace App\Service;

class UserService
{
    public const DEFAULT_LIMIT = 100;
}

// Bad: Wrong casing, mixed concerns
<?php
class user_service {  // Should be UserService
    const defaultLimit = 100;  // Should be UPPER_SNAKE_CASE
}
```

---

## PSR-12: Extended Coding Style

**Indentation:** 4 spaces (no tabs).

**Line length:** Soft limit 120 characters; wrap when readability suffers.

**Method and function:**
- Opening brace on same line for methods; closing brace on new line
- One argument per line when many parameters

```php
// Good: PSR-12 brace style
class UserService
{
    public function createUser(
        string $name,
        string $email,
        ?DateTimeImmutable $createdAt = null
    ): User {
        // ...
    }
}

// Bad: Wrong brace placement
class UserService {
    public function createUser($name, $email) {  // No types
```

**Control structures:**
- Space after `if`, `for`, `foreach`, `while`
- Opening brace on same line; closing brace on new line

```php
// Good
if ($user !== null) {
    $user->activate();
}

foreach ($items as $item) {
    process($item);
}

// Bad
if($user !== null){
    $user->activate();
}
```

---

## PSR-4: Autoloading

**Namespace to path mapping:**
- `App\` or `Vendor\Package\` maps to `src/` or `src/Package/`
- Underscores in class names do NOT imply directory structure

```php
// Good: PSR-4
// File: src/Service/UserService.php
namespace App\Service;

class UserService
{
}

// composer.json
// "autoload": { "psr-4": { "App\\": "src/" } }

// Bad: Non-PSR-4 or wrong mapping
// File: src/UserService.php with namespace App\Service\UserService
```

---

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Class | StudlyCaps | `UserService`, `OrderRepository` |
| Method | camelCase | `findUserById`, `createOrder` |
| Property | camelCase | `$userName`, `$createdAt` |
| Constant | UPPER_SNAKE_CASE | `MAX_RETRIES`, `DEFAULT_LIMIT` |
| Variable | camelCase | `$userId`, `$orderTotal` |

---

## Related Rules

- [Modern PHP Patterns](modern-php-patterns.md) - Type declarations, PHP 8+ features
- [Generic Code Quality Principles](../../../generic/code-quality/core-principles.md) - SOLID, DRY, KISS

---

## References

- [PSR-1: Basic Coding Standard](https://www.php-fig.org/psr/psr-1/)
- [PSR-12: Extended Coding Style](https://www.php-fig.org/psr/psr-12/)
- [PSR-4: Autoloader](https://www.php-fig.org/psr/psr-4/)
- [PHP The Right Way](https://phptherightway.com/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
