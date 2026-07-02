# Java Production Patterns

Patterns for production-ready Java services. Resource management, null safety, security, and reliability.

---

## Use try-with-resources for All Closeable Resources

**Guarantee cleanup.** Use try-with-resources for streams, connections, readers, writers.

```java
// ✅ Good: try-with-resources
try (BufferedReader reader = Files.newBufferedReader(path);
     BufferedWriter writer = Files.newBufferedWriter(outputPath)) {
    String line;
    while ((line = reader.readLine()) != null) {
        writer.write(process(line));
    }
}

// ✅ Good: Multiple resources, closed in reverse order
try (Connection conn = dataSource.getConnection();
     PreparedStatement stmt = conn.prepareStatement(sql);
     ResultSet rs = stmt.executeQuery()) {
    return mapResults(rs);
}

// ❌ Bad: Manual close in finally (error-prone, can leak)
BufferedReader reader = null;
try {
    reader = Files.newBufferedReader(path);
    return reader.lines().collect(Collectors.joining());
} finally {
    if (reader != null) {
        reader.close();  // Can throw, previous exception lost
    }
}
```

---

## Return Empty Collections, Not Null

**Callers should not need null checks for "no results."** Return `Collections.emptyList()`, `Optional.empty()`, or empty arrays.

```java
// ✅ Good: Empty collection
public List<User> findActiveUsers() {
    List<User> users = repository.findAll();
    if (users.isEmpty()) {
        return Collections.emptyList();
    }
    return users.stream().filter(User::isActive).toList();
}

// ✅ Good: Optional for single result
public Optional<User> findUser(String id) {
    return Optional.ofNullable(repository.findById(id));
}

// ❌ Bad: Null return forces caller to check
public List<User> findActiveUsers() {
    // ...
    return null;  // Caller must null-check
}
```

---

## Use Optional Only for Return Values

**Do not use `Optional` as a field, parameter, or in collections.** Use for return types only.

```java
// ✅ Good: Optional as return type
public Optional<User> findUser(String id) {
    return Optional.ofNullable(repository.findById(id));
}

// ❌ Bad: Optional as parameter (overload instead)
public void process(Optional<String> value) { }  // Awkward

// ❌ Bad: Optional in collection
List<Optional<User>> users;  // Use List<User> and filter nulls
```

---

## Validate and Sanitize Input at Boundaries

**Validate at API boundaries.** Use bean validation for DTOs. Never trust client input.

```java
// ✅ Good: Bean validation on DTO
public record CreateUserRequest(
    @NotBlank @Size(min = 1, max = 100) String name,
    @Email String email,
    @Min(0) @Max(150) int age
) {}

// ✅ Good: Parameterized queries (SQL injection prevention)
try (PreparedStatement stmt = conn.prepareStatement(
        "SELECT * FROM users WHERE id = ?")) {
    stmt.setString(1, userId);
    return stmt.executeQuery();
}

// ❌ Bad: String concatenation in SQL
String sql = "SELECT * FROM users WHERE id = '" + userId + "'";  // SQL injection!
```

---

## Never Log Sensitive Data

**Passwords, tokens, PII must not appear in logs.**

```java
// ✅ Good: Redact sensitive fields
logger.info("User login attempt: userId={}", userId);  // No password

// ❌ Bad: Logging sensitive data
logger.info("Login: user={}, password={}", userId, password);
```

---

## Use Thread-Safe Collections for Shared State

**Prefer `ConcurrentHashMap`, `CopyOnWriteArrayList` over synchronized wrappers.**

```java
// ✅ Good: ConcurrentHashMap for concurrent access
private final Map<String, Config> cache = new ConcurrentHashMap<>();

// ✅ Good: CopyOnWriteArrayList for read-heavy lists
private final List<Listener> listeners = new CopyOnWriteArrayList<>();

// ❌ Bad: Synchronized wrapper (coarse-grained, more contention)
private final Map<String, Config> cache = Collections.synchronizedMap(new HashMap<>());
```

---

## Shut Down Thread Pools and Executors

**Executors hold non-daemon threads.** Shut down in finally or use try-with-resources (Java 19+).

```java
// ✅ Good: Explicit shutdown
ExecutorService executor = Executors.newFixedThreadPool(4);
try {
    executor.submit(() -> doWork());
} finally {
    executor.shutdown();
    if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
        executor.shutdownNow();
    }
}
```

---

## Handle Exceptions Specifically

**Catch specific exceptions.** Avoid empty catch blocks. Log with context.

```java
// ✅ Good: Specific catch, log and rethrow or handle
try {
    return repository.findById(id);
} catch (SQLException e) {
    logger.error("Database error loading user id={}", id, e);
    throw new UserNotFoundException(id, e);
}

// ❌ Bad: Swallowing or broad catch
try {
    return repository.findById(id);
} catch (Exception e) {
    // Silent failure
}
```

---

## Copy Collections at API Boundaries

**Avoid exposing internal mutable state.** Return copies when returning collections.

```java
// ✅ Good: Return copy
public List<Item> getItems() {
    lock.lock();
    try {
        return new ArrayList<>(items);
    } finally {
        lock.unlock();
    }
}

// ❌ Bad: Return internal reference (caller can mutate)
public List<Item> getItems() {
    return items;  // Caller can modify items!
}
```

---

## Related Rules

**Java-Specific:**
- [Concurrency and Locking](../language/concurrency-locking.md) - Thread-safe collections
- [Parallel Processing](../language/parallel-processing.md) - Executor shutdown
- [Modern Java Patterns](../language/modern-java-patterns.md) - try-with-resources, Optional
- [JFR Observability](jfr-observability.md) - Always-on JVM-level event recording for prod
- [Null Safety: Error Prone + NullAway](../tooling/null-safety-errorprone-nullaway.md) - compile-time NPE prevention

**Universal:**
- [Generic Architecture Principles](../../../generic/architecture/core-principles.md) - Dependency injection

---

## References

- [Effective Java, 3rd Edition (Joshua Bloch, 2017)](https://www.informit.com/store/effective-java-9780134685991)
- [Java Code Review Checklist (JetBrains)](https://www.jetbrains.com/pages/static-code-analysis-guide/java-code-review-checklist/)
- [Try-with-resources (Oracle)](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html)
- [JDK Flight Recorder programming guide](https://docs.oracle.com/en/java/javase/21/jfapi/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
