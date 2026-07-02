# Android Development Patterns Index

**Purpose**: Router for Android patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **android**, android development, android architecture, mvvm android, compose | `android-best-practices.md` |
| **android performance**, android memory leak, android profiling, compose performance | `android-performance.md` |

---

## Android Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Android Best Practices](android-best-practices.md) | MVVM, Coroutines, Flow, Compose patterns | android, android development, android architecture |
| [Android Performance](android-performance.md) | Memory leaks, profiling, Compose performance | android performance, android memory leak, compose performance |

---

## Quick Reference

| Need | Load |
|------|------|
| Android best practices | `android-best-practices.md` |
| Android performance | `android-performance.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for Kotlin language patterns

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
