# PHP Security Patterns

Prevent SQL injection, XSS, and CSRF. Use prepared statements. Validate and sanitize input. Encode output.

---

## Triggers

**APPLY WHEN:** Writing database queries, handling `$_GET`/`$_POST`, rendering HTML, processing forms.
**SKIP WHEN:** Code has no user input or output.

---

## Core Directive

**Never concatenate user input into SQL.** Use prepared statements. Encode output before display. Validate and sanitize all input.

---

## Prevent SQL Injection with Prepared Statements

**Use PDO or MySQLi prepared statements.** Bind parameters; never interpolate user input into SQL.

```php
// Good: PDO prepared statement
$stmt = $pdo->prepare('SELECT * FROM users WHERE id = :id AND email = :email');
$stmt->execute(['id' => $userId, 'email' => $email]);

// Good: MySQLi prepared statement
$stmt = $connection->prepare('SELECT * FROM users WHERE id = ?');
$stmt->bind_param('i', $userId);
$stmt->execute();

// Bad: String concatenation - SQL injection
$sql = "SELECT * FROM users WHERE id = " . $_GET['id'];  // Dangerous!
$result = $pdo->query($sql);
```

---

## Prevent XSS with Output Encoding

**Encode output before displaying.** Use `htmlspecialchars` with `ENT_QUOTES` and `UTF-8`.

```php
// Good: Encode output
echo htmlspecialchars($user->getName(), ENT_QUOTES, 'UTF-8');

// Good: In templates
<input value="<?= htmlspecialchars($email, ENT_QUOTES, 'UTF-8') ?>">

// Bad: Raw output - XSS
echo $user->getName();  // User-controlled data!
```

---

## Validate and Sanitize Input

**Validate type, length, and format.** Use `filter_var` for common cases.

```php
// Good: Validate email
if (!filter_var($_POST['email'], FILTER_VALIDATE_EMAIL)) {
    throw new InvalidArgumentException('Invalid email');
}

// Good: Validate integer
$id = filter_var($_GET['id'], FILTER_VALIDATE_INT);
if ($id === false) {
    throw new InvalidArgumentException('Invalid id');
}

// Bad: Trust input
$email = $_POST['email'];  // No validation
```

---

## Protect Against CSRF

**Use CSRF tokens** for state-changing requests. Verify token on POST/PUT/DELETE.

```php
// Good: CSRF token verification
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $token = $_POST['csrf_token'] ?? '';
    if (!hash_equals($_SESSION['csrf_token'] ?? '', $token)) {
        throw new RuntimeException('Invalid CSRF token');
    }
}

// Good: Generate token for form
$_SESSION['csrf_token'] = bin2hex(random_bytes(32));

// Bad: No CSRF protection
// Form submits without token check
```

---

## Use Secure Session Configuration

**Configure sessions securely.** Random ID, HTTP-only cookie, secure flag in production.

```php
// Good: Secure session config
ini_set('session.cookie_httponly', 1);
ini_set('session.cookie_secure', 1);  // HTTPS only
ini_set('session.use_strict_mode', 1);
session_regenerate_id(true);  // On login
```

---

## Related Rules

- [Modern PHP Patterns](../language/modern-php-patterns.md) - Exception handling, type safety
- [PHP Production Patterns](php-production-patterns.md) - Error logging, environment config

---

## References

- [OWASP PHP Security](https://owasp.org/www-project-web-security-testing-guide/)
- [PHP The Right Way - Security](https://phptherightway.com/#security)
- [PHP Manual - filter_var](https://www.php.net/manual/en/function.filter-var.php)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
