# Security Audit

Perform a security audit on the codebase.

## Usage

```
/security-audit [path-or-pattern]
```

## What it does

1. Scans code for common security vulnerabilities:
   - SQL injection risks
   - XSS vulnerabilities
   - CSRF protection
   - Authentication/authorization issues
   - Secrets in code
   - Dependency vulnerabilities
2. Reviews security best practices:
   - Input validation
   - Output encoding
   - Secure session management
   - HTTPS enforcement
   - Rate limiting
3. Generates a security report with severity levels
4. Provides remediation suggestions

## Examples

```
/security-audit
```

Audit entire codebase.

```
/security-audit src/auth/
```

Audit authentication module.

## Security Checklist

### High Severity
- SQL injection vulnerabilities
- XSS vulnerabilities
- Hardcoded secrets/credentials
- Missing authentication checks
- Insecure cryptography

### Medium Severity
- Missing input validation
- Insufficient rate limiting
- Weak password requirements
- Missing CSRF protection
- Insecure session configuration

### Low Severity
- Missing security headers
- Verbose error messages
- Outdated dependencies
- Missing security documentation

## Requirements

- May run security scanners (npm audit, snyk, etc.)
- Reviews code patterns against OWASP Top 10
- Checks for secrets with tools like truffleHog

## Output

Returns a structured security report:
- Summary of findings by severity
- File locations and line numbers
- Remediation steps
- References to security best practices
