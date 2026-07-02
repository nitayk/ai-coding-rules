# PHP Production Patterns

Configure OPcache, tune PHP-FPM, optimize Composer autoload. Log errors; never display them to users.

---

## Triggers

**APPLY WHEN:** Deploying PHP applications, configuring production servers, optimizing performance.
**SKIP WHEN:** Local development only, no deployment concerns.

---

## Core Directive

**Enable OPcache in production.** Use optimized Composer autoload. Log errors; never expose stack traces to users.

---

## Enable and Tune OPcache

**Enable OPcache** for production. Configure memory and validate timestamps appropriately.

```ini
; Good: Production OPcache
opcache.enable=1
opcache.memory_consumption=256
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0   ; Production: no file checks
opcache.revalidate_freq=0

; Development: allow file changes
; opcache.validate_timestamps=1
; opcache.revalidate_freq=2
```

```php
// Bad: OPcache disabled or default low memory
; opcache.enable=0
; opcache.memory_consumption=128  ; Often too low for large apps
```

---

## Optimize Composer Autoload

**Use `composer dump-autoload -o`** in production. Class map is faster than PSR-4 scanning.

```bash
# Good: Optimized autoload for production
composer install --no-dev --optimize-autoloader

# Or explicitly
composer dump-autoload -o --classmap-authoritative
```

```json
// Good: Production install
"scripts": {
    "post-install-cmd": "@composer dump-autoload -o"
}
```

---

## Configure Error Handling for Production

**Log errors; never display.** Use `display_errors=Off` and proper `error_log`.

```php
// Good: Production error config
ini_set('display_errors', '0');
ini_set('log_errors', '1');
ini_set('error_log', '/var/log/php/error.log');

// Use set_exception_handler for uncaught exceptions
set_exception_handler(function (Throwable $e): void {
    error_log($e->getMessage() . "\n" . $e->getTraceAsString());
    http_response_code(500);
    echo 'An error occurred.';  // Generic message only
});
```

```php
// Bad: Exposing errors to users
ini_set('display_errors', '1');  // Stack traces visible!
```

---

## Tune PHP-FPM Process Manager

**Set `pm.max_children`** based on memory. Use `pm = dynamic` or `ondemand` appropriately.

```ini
; Good: Calculate based on (available_memory / avg_process_memory)
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35

; For low-traffic: ondemand saves memory
; pm = ondemand
; pm.max_children = 50
```

---

## Use PHP 8.x in Production

**Prefer PHP 8.2+** for performance (JIT, readonly) and security. Lock version in CI/CD.

```bash
# Good: Explicit version in deployment
php -v  # Ensure 8.2+
composer config platform.php 8.2.0
```

---

## Lock Dependencies in Production

**Commit `composer.lock`.** Use `composer install` (not `update`) in deployment.

```bash
# Good: Reproducible install
composer install --no-dev --optimize-autoloader

# Bad: Unlocked versions
composer update --no-dev  # May change versions
```

---

## Related Rules

- [PHP Security Patterns](php-security-patterns.md) - Input validation, error logging
- [Modern PHP Patterns](../language/modern-php-patterns.md) - Exception handling

---

## References

- [PHP The Right Way - Deployment](https://phptherightway.com/#deployment)
- [PHP OPcache Documentation](https://www.php.net/manual/en/book.opcache.php)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
