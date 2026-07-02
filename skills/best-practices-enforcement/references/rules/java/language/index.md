# Java Language Patterns Index

**Purpose**: Router for Java language patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **modern java**, java patterns, records, virtual threads, effective java | `modern-java-patterns.md` |
| **java style**, java formatting, java naming, style guide | `style-guide.md` |
| **java concurrency**, java locking, synchronized, ReentrantLock, StampedLock | `concurrency-locking.md` |
| **java parallel**, CompletableFuture, ExecutorService, parallel streams | `parallel-processing.md` |

---

## Language Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Modern Java Patterns](modern-java-patterns.md) | Effective Java principles, records, virtual threads | modern java, java patterns, records, virtual threads |
| [Style Guide](style-guide.md) | Java coding standards based on Google Java Style Guide | java style, java formatting, java naming |
| [Concurrency and Locking](concurrency-locking.md) | synchronized, ReentrantLock, StampedLock, deadlock prevention | java concurrency, locking, thread safety |
| [Parallel Processing](parallel-processing.md) | CompletableFuture, ExecutorService, virtual threads | java parallel, async, parallel streams |

---

## Quick Reference

| Need | Load |
|------|------|
| Modern Java | `modern-java-patterns.md` |
| Style guide | `style-guide.md` |
| Concurrency/locking | `concurrency-locking.md` |
| Parallel processing | `parallel-processing.md` |

---

## Related Resources

- **Generic**: See `references/rules/common/generic/index.md` for universal principles
- **Backend Index**: See `../index.md` for all backend languages

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
