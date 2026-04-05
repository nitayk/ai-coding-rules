---
name: security-audit
description: "Use when auditing code for security vulnerabilities. Scans for SQL injection, XSS, secrets, auth issues. Make sure to use when user says: security audit, security review, scan for vulnerabilities, check for security issues, or audit before release."
disable-model-invocation: true
---
# Security Audit

Perform a security audit on the codebase.

## When to Use This Skill

**APPLY WHEN:**
- User wants security review before release
- User says "security audit", "security review", "scan for vulnerabilities"
- Auditing before merging sensitive code

**SKIP WHEN:**
- General code review (use `/code-review`)
- User wants security documentation only

## Core Directive

**Scan for vulnerabilities → Review against OWASP Top 10 → Generate report with severity levels and remediation steps.**

## Usage

```
/security-audit [path-or-pattern]
```

## Process

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
