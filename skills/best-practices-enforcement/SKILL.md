---
name: best-practices-enforcement
description: "Systematically validates code against universal best practices and language-specific patterns. Enforces code quality (SOLID, DRY, KISS, YAGNI), security (input validation, least privilege), testing (AAA pattern, behavior over implementation), performance (measure first, optimize bottlenecks), architecture (separation of concerns, dependency injection), and error handling (fail fast, explicit errors). Automatically detects language from file extensions and loads both generic rules (@shared/generic/) and language-specific rules (Scala/Python/Go/Java/JS/TS/Swift/Kotlin/Objective-C). Use when reviewing code before commit or PR, ensuring code quality standards, validating security practices, checking test coverage, performance optimization review, architecture compliance validation, or onboarding new code. Skip when only reading code, code already reviewed, or quick syntax fixes. Produces structured best practices audit report in chat (not file)."
version: "1.2.0"
last_updated: "2026-01-25"
tags: ["best-practices", "code-quality", "security", "testing", "code-review", "enforcement"]
---
# Best Practices Enforcement

Systematically validate code against universal best practices and language-specific patterns. Report violations with specific recommendations.

## What is Best Practices Enforcement?

Best practices enforcement is a systematic code review process that validates code against established standards across multiple dimensions: code quality, security, testing, performance, architecture, and error handling. It combines universal principles (SOLID, DRY, KISS, YAGNI) with language-specific patterns (Python type hints, Scala immutability, Go error handling, etc.) to ensure code meets quality standards.

**Core Concept**: Code should be:
- ✅ **Correct** - Works as intended, handles edge cases
- ✅ **Secure** - Validates input, follows least privilege, no vulnerabilities
- ✅ **Testable** - Well-tested with behavior-focused tests
- ✅ **Performant** - Efficient algorithms, measured optimizations
- ✅ **Maintainable** - Clear structure, separation of concerns, readable
- ✅ **Robust** - Proper error handling, fail-fast patterns

## Why This Matters

### The Problem: Inconsistent Code Quality

**Without systematic enforcement:**
- Code quality varies between developers
- Security vulnerabilities slip through
- Technical debt accumulates
- Code becomes hard to maintain
- Performance issues go unnoticed
- Tests are missing or poorly written

**Example of problems:**
```
# Security issue: No input validation
def process_user_email(email):
    db.query("SELECT * FROM users WHERE email = %s" % email)  # SQL injection risk

# Code quality: Violates SRP
class UserService:
    def create_user(self): ...
    def send_email(self): ...  # Should be separate EmailService
    def generate_report(self): ...  # Should be separate ReportService

# Testing: Tests implementation, not behavior
def test_user_creation():
    assert user._internal_state == "created"  # Testing private state
```

### The Solution: Systematic Validation

**With best practices enforcement:**
- ✅ Consistent quality across codebase
- ✅ Security vulnerabilities caught early
- ✅ Technical debt prevented
- ✅ Maintainable, readable code
- ✅ Performance issues identified
- ✅ Comprehensive test coverage

**Example of improvements:**
```
# Security: Input validated
def process_user_email(email: str) -> User:
    if not is_valid_email(email):
        raise ValueError("Invalid email format")
    return db.query("SELECT * FROM users WHERE email = ?", email)

# Code quality: Single responsibility
class UserService:
    def create_user(self): ...

class EmailService:
    def send_email(self): ...

# Testing: Tests behavior
def test_user_creation():
    user = service.create_user("test@example.com")
    assert user.email == "test@example.com"  # Test public behavior
```

## Understanding the Categories

### 1. Code Quality

**Principles**: SOLID, DRY, KISS, YAGNI, Boy Scout Rule

**What it checks:**
- Single Responsibility Principle (SRP) - Classes/functions do one thing
- DRY (Don't Repeat Yourself) - No code duplication
- KISS (Keep It Simple, Stupid) - Simple solutions preferred
- YAGNI (You Aren't Gonna Need It) - No premature features
- Meaningful names - Clear, descriptive identifiers
- Pure functions - No side effects where possible

**Why it matters**: Maintainable code is easier to understand, modify, and debug.

### 2. Security

**Principles**: Input validation, least privilege, defense in depth

**What it checks:**
- Input validation - All user input validated
- Least privilege - Minimal permissions required
- Defense in depth - Multiple security layers
- Secure defaults - Safe by default
- No secrets in code - Credentials properly managed
- SQL injection prevention - Parameterized queries
- XSS prevention - Output sanitization

**Why it matters**: Security vulnerabilities can lead to data breaches, system compromise, and legal issues.

### 3. Testing

**Principles**: AAA pattern, behavior over implementation, isolation

**What it checks:**
- Tests exist - Code is tested
- AAA pattern - Arrange, Act, Assert structure
- Behavior over implementation - Test what, not how
- Isolation - Tests don't depend on each other
- Edge cases - Boundary conditions tested
- Test coverage - Critical paths covered

**Why it matters**: Tests provide confidence in code correctness and enable safe refactoring.

### 4. Performance

**Principles**: Measure first, optimize bottlenecks, avoid premature optimization

**What it checks:**
- No premature optimization - Optimize after measuring
- Bottlenecks identified - Performance issues known
- Efficient algorithms - Appropriate data structures
- Caching - Where beneficial
- Resource cleanup - Memory, connections, files

**Why it matters**: Performance issues impact user experience and system scalability.

### 5. Architecture

**Principles**: Interface-centric design, separation of concerns, dependency injection

**What it checks:**
- Interface-centric - Depend on abstractions
- Separation of concerns - Clear boundaries
- Dependency injection - Loose coupling
- Clear boundaries - Module responsibilities defined
- Layered architecture - Proper layering

**Why it matters**: Good architecture enables scalability, testability, and maintainability.

### 6. Error Handling

**Principles**: Fail fast, explicit errors, proper propagation

**What it checks:**
- Fail fast - Errors detected early
- Explicit errors - Clear error types
- Proper propagation - Errors handled at appropriate layer
- Appropriate layers - Errors handled where context exists
- No silent failures - Errors are visible
- Swallowed errors - No empty catch blocks
- InterruptedExceptions - Handled correctly

**Why it matters**: Proper error handling prevents bugs from propagating and improves debugging.

## Prerequisites

1. **Detect language(s)** from file extensions or paths:
   - `.scala` → Scala (`@shared/backend/scala/index.mdc`)
   - `.py` → Python (`@shared/backend/python/index.mdc`)
   - `.go` → Go (`@shared/backend/go/index.mdc`)
   - `.java` → Java (`@shared/backend/java/index.mdc`)
   - `.js`, `.ts`, `.tsx`, `.jsx` → JavaScript/TypeScript (`@shared/frontend/javascript-typescript/index.mdc`)
   - `.swift` → Swift (`@shared/mobile/swift/index.mdc`)
   - `.kt` → Kotlin (`@shared/mobile/kotlin/index.mdc`)
   - `.m`, `.mm` → Objective-C (`@shared/mobile/objective-c/index.mdc`)
2. **Load generic rules** (always): `@shared/generic/`
3. **Load language-specific index** (if detected): Use index file to discover all language rules

## Methodology

### Step 1: Detect Languages and Load Rules

**CRITICAL: You MUST actually load the rule files, not just mention them.**

#### 1.1 Detect Language(s) from Target Files

**FIRST: Scan the actual target files/directories to detect languages**

1. Use `glob_file_search` or `list_dir` to find files in the target directory
2. Check file extensions in the actual files found:
   - `.py` → Python
   - `.scala` → Scala
   - `.go` → Go
   - `.java` → Java
   - `.js`, `.ts`, `.tsx`, `.jsx` → JavaScript/TypeScript
   - `.swift` → Swift
   - `.kt` → Kotlin
   - `.m`, `.mm` → Objective-C
3. **Announce detected languages**: Write a message like "Detected languages: Python, Scala" so the user can see what was found
4. **IMPORTANT**: If multiple languages detected (e.g., both `.py` and `.scala` files), load rules for ALL detected languages

#### 1.2 ALWAYS Load Generic Rules First

**Announce and load generic rules:**

Write: "📚 Loading generic best practice rules..."

**Use `read_file` to load these files:**
- `@shared/generic/code-quality/core-principles.mdc`
- `@shared/generic/security/core-principles.mdc`
- `@shared/generic/testing/core-principles.mdc`
- `@shared/generic/performance/core-principles.mdc`
- `@shared/generic/architecture/core-principles.mdc`
- `@shared/generic/error-handling/universal-patterns.mdc`
- `@shared/generic/error-handling/silent-failure-check.mdc`

After loading, write: "SUCCESS: Loaded generic rules"

#### 1.3 AUTOMATICALLY Load Language-Specific Index

**For EACH detected language, announce and load the index file:**

**Before loading each language, write a message like:**
- "Loading Python best practice rules..."
- "Loading Scala best practice rules..."
- "Loading Go best practice rules..."
- etc.

**Then use `read_file` to load the index file for each detected language:**

- **Python** (if `.py` files found): `@shared/backend/python/index.mdc`
- **Scala** (if `.scala` files found): `@shared/backend/scala/index.mdc`
- **Go** (if `.go` files found): `@shared/backend/go/index.mdc`
- **Java** (if `.java` files found): `@shared/backend/java/index.mdc`
- **JavaScript/TypeScript** (if `.js`, `.ts`, `.tsx`, `.jsx` files found): `@shared/frontend/javascript-typescript/index.mdc`
- **Swift** (if `.swift` files found): `@shared/mobile/swift/index.mdc`
- **Kotlin** (if `.kt` files found): `@shared/mobile/kotlin/index.mdc`
- **Objective-C** (if `.m`, `.mm` files found): `@shared/mobile/objective-c/index.mdc`

**After loading each index, write: "SUCCESS: Loaded [Language] index"**

**CRITICAL**: If multiple languages detected (e.g., both Python and Scala), load indexes for ALL of them.

#### 1.4 Load Relevant Language-Specific Rule Files

**After reading each language index, announce and load specific rule files:**

**For Python (if `.py` files detected):**

Write: "Loading Python-specific rule files..."

Load these files using `read_file`:
- `@shared/backend/python/language/type-annotations-everywhere.mdc` - Type hints
- `@shared/backend/python/language/error-handling-patterns.mdc` - Exception handling
- `@shared/backend/python/language/pythonic-patterns.mdc` - Comprehensions, dataclasses, EAFP
- `@shared/backend/python/meta/pep8-style-guide.mdc` - PEP 8 style guide
- `@shared/backend/python/language/async-patterns.mdc` - If async code detected
- `@shared/backend/python/testing/python-testing-best-practices.mdc` - If reviewing tests
- `@shared/backend/python/performance/profiling-and-optimization.mdc` - If reviewing performance

Write: "SUCCESS: Loaded Python-specific rules"

**For Scala (if `.scala` files detected):**

Write: "Loading Scala-specific rule files..."

Load relevant rules from the index (language/, architecture/, testing/, performance/, data/, meta/)

Write: "SUCCESS: Loaded Scala-specific rules"

**For other languages:** Follow the same pattern - announce, load, confirm.

**IMPORTANT**: 
- **Always announce before loading**: Write "Loading [Language] rules..." so user can see progress
- Use `read_file` tool to actually load these files - don't just mention them
- Load language-specific rules BEFORE analyzing code
- **If multiple languages detected, load rules for ALL detected languages** (e.g., if both Python and Scala files found, load both sets of rules)
- After loading each language's rules, write a confirmation message

### Step 2: Analyze Code Structure

**After loading all rules, analyze the code:**

For each file/module, check:

1. **Code Quality**: SRP, DRY, KISS, YAGNI, Boy Scout Rule, meaningful names, pure functions
2. **Security**: Input validation, least privilege, defense in depth, secure defaults, no secrets
3. **Testing**: Tests exist, AAA pattern, behavior over implementation, isolation, edge cases
4. **Performance**: No premature optimization, bottlenecks measured, efficient algorithms, caching
5. **Architecture**: Interface-centric, separation of concerns, dependency injection, clear boundaries
6. **Error Handling**: Fail fast, explicit errors, proper propagation, appropriate layers

### Step 3: Language-Specific Validation

**Apply the language-specific rules you loaded in Step 1.4:**

- **Python**: Check for type annotations, PEP 8 compliance, Pythonic patterns (comprehensions vs loops, EAFP, context managers), async/await patterns
- **Scala**: Option/Either/Try, immutability, case classes, referential transparency, pattern matching
- **Go**: Small interfaces, explicit error handling, context patterns, concurrency patterns
- **Java**: Modern Java patterns, interfaces over inheritance, style guide
- **JS/TS**: Type safety, strict mode, async/await patterns, defensive programming
- **Swift**: Optionals, protocol-oriented design, concurrency patterns, style guide
- **Kotlin**: Sealed classes, coroutines, null safety, style guide
- **Objective-C**: ARC memory management, style guide, iOS best practices

**Reference the specific rule files you loaded** when identifying violations.

### Step 4: Generate Report

Structure findings by category with violations, locations, recommendations, and priority (Critical/Warning/Suggestion). Report in chat, not file.

## Reference Rules

**Generic (always load):**
- `@shared/generic/code-quality/core-principles.mdc`
- `@shared/generic/security/core-principles.mdc`
- `@shared/generic/testing/core-principles.mdc`
- `@shared/generic/performance/core-principles.mdc`
- `@shared/generic/architecture/core-principles.mdc`
- `@shared/generic/error-handling/universal-patterns.mdc`

**Language-specific indexes (load based on detected language):**
- Scala: `@shared/backend/scala/index.mdc`
- Python: `@shared/backend/python/index.mdc`
- Go: `@shared/backend/go/index.mdc`
- Java: `@shared/backend/java/index.mdc`
- JavaScript/TypeScript: `@shared/frontend/javascript-typescript/index.mdc`
- Swift: `@shared/mobile/swift/index.mdc`
- Kotlin: `@shared/mobile/kotlin/index.mdc`
- Objective-C: `@shared/mobile/objective-c/index.mdc`

**After loading index, load specific rule files** from categories: `language/`, `testing/`, `performance/`, `architecture/`, `data/`, `meta/` as needed.

## Output

Best Practices Audit Report (in chat, not file):
1. Summary: compliance status with counts
2. By category: violations, locations, recommendations, priority (Critical/Warning/Suggestion)
3. Language-specific findings if applicable

## Common Patterns

### Pattern 1: Multi-Language Codebase

**When codebase has multiple languages:**

```python
# Python file: src/api/handlers.py
def handle_request(data):
    # Check Python-specific: type hints, PEP 8, Pythonic patterns
    pass
```

```scala
// Scala file: src/services/UserService.scala
class UserService {
  // Check Scala-specific: Option/Either, immutability, case classes
}
```

**Approach**: Detect all languages, load rules for ALL detected languages, apply language-specific checks to each file.

### Pattern 2: Security-First Review

**For security-critical code:**

1. Load security rules first
2. Check input validation
3. Check authentication/authorization
4. Check sensitive data handling
5. Check for common vulnerabilities (SQL injection, XSS, etc.)

**Priority**: Security violations are always Critical.

### Pattern 3: Test-Driven Validation

**When reviewing test files:**

1. Check test structure (AAA pattern)
2. Verify behavior-focused tests (not implementation)
3. Check test isolation
4. Verify edge cases covered
5. Check test naming clarity

**Focus**: Tests should be maintainable and reliable.

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Mentioning Rules Without Loading

**Bad:**
```
"I'll check against SOLID principles..."
# Never actually loads the rule files
```

**Good:**
```
"Loading generic best practice rules..."
# Actually uses read_file to load @shared/generic/code-quality/core-principles.mdc
```

### ❌ Anti-Pattern 2: Skipping Language Detection

**Bad:**
```
# Assumes Python without checking files
# Loads Python rules for Scala codebase
```

**Good:**
```
# Scans files first
glob_file_search("**/*.scala")
# Detects: Scala
# Loads: Scala rules
```

### ❌ Anti-Pattern 3: Single Language When Multiple Present

**Bad:**
```
# Detects: Python, Scala
# Only loads Python rules
```

**Good:**
```
# Detects: Python, Scala
# Loads: Python rules AND Scala rules
```

### ❌ Anti-Pattern 4: Vague Recommendations

**Bad:**
```
Violation: Code quality issue
Recommendation: Fix it
```

**Good:**
```
Violation: SRP violation in UserService
Location: src/services/UserService.scala:45
Issue: UserService handles both user CRUD and email sending
Recommendation: Extract EmailService, keep UserService focused on user management
Priority: Medium
```

## Examples

**Example 1: Code Quality Violation**
```
Violation: SRP violation in UserService
Location: src/services/UserService.scala:45
Issue: UserService handles both user CRUD and email sending
Recommendation: Extract EmailService, keep UserService focused on user management
Priority: Medium
```

**Example 2: Security Violation**
```
Violation: Missing input validation
Location: src/api/UserController.scala:23
Issue: Email parameter not validated before database query
Recommendation: Add email format validation using regex or library
Priority: Critical
```

**Example 3: Testing Violation**
```
Violation: Test checks implementation detail
Location: src/test/UserServiceTest.scala:67
Issue: Test asserts on private _internalState variable
Recommendation: Test public behavior (user creation success) instead
Priority: Medium
```

**Example 4: Performance Violation**
```
Violation: N+1 query problem
Location: src/services/ReportService.scala:89
Issue: Loop executes database query for each iteration
Recommendation: Use batch query or eager loading to fetch all data at once
Priority: High
```

**Example 5: Architecture Violation**
```
Violation: Tight coupling to concrete implementation
Location: src/services/OrderService.scala:12
Issue: Directly instantiates DatabaseConnection instead of using dependency injection
Recommendation: Inject IDatabaseConnection interface, use DI container
Priority: Medium
```

## Integration

Use with `/code-review` (broader review), `/service-refactoring` (apply during refactoring), `/service-migration` (ensure migrated code follows practices).

## Execution Checklist

**When executing this skill, follow this checklist and ANNOUNCE each step:**

1. **Detect languages**: 
   - Scan target files/directories for language extensions using `glob_file_search` or `list_dir`
   - **Write**: "Detected languages: [list languages found]" (e.g., "Detected languages: Python, Scala")
   
2. **Load generic rules**: 
   - **Write**: "Loading generic best practice rules..."
   - Use `read_file` to load all 6 generic rule files
   - **Write**: "SUCCESS: Loaded generic rules"
   
3. **Load language indexes**: 
   - For EACH detected language:
     - **Write**: "Loading [Language] best practice rules..."
     - Use `read_file` to load the index file (e.g., `@shared/backend/python/index.mdc`)
     - **Write**: "SUCCESS: Loaded [Language] index"
   - **If multiple languages**: Load indexes for ALL of them (e.g., both Python and Scala)
   
4. **Load specific rules**: 
   - For EACH detected language:
     - **Write**: "Loading [Language]-specific rule files..."
     - Load relevant rule files based on index contents (e.g., for Python: type-annotations, PEP 8, error-handling, pythonic-patterns)
     - **Write**: "SUCCESS: Loaded [Language]-specific rules"
   - **If multiple languages**: Load specific rules for ALL detected languages
   
5. **Analyze code**: 
   - **Write**: "Analyzing code against loaded rules..."
   - Apply all loaded rules to find violations
   
6. **Report findings**: 
   - Structure violations by category with locations and recommendations
   - Reference which language-specific rules were applied

**CRITICAL REMINDERS:**
- **Always announce loading steps** - write messages so user can see "Loading..." progress
- You MUST actually load rule files using `read_file` - don't just mention them
- If Python detected (`.py` files), you MUST load Python-specific rules
- If Scala detected (`.scala` files), you MUST load Scala-specific rules
- **If BOTH Python and Scala detected, load rules for BOTH languages**
- Load language-specific rules BEFORE analyzing code
- After each loading step, write a confirmation message

## Notes

- **CRITICAL**: You MUST actually load rule files using `read_file` - don't just mention them
- **CRITICAL**: Always announce loading steps with messages like "Loading..." so user can see progress
- Report in chat, not files
- Language-aware: auto-detect and apply language rules based on actual files found
- Prioritize critical security/correctness issues
- Every violation needs specific recommendation
- Consider codebase's existing patterns
- If Python detected, you MUST load Python-specific rules (type annotations, PEP 8, Pythonic patterns)
- If multiple languages detected, load rules for ALL detected languages
