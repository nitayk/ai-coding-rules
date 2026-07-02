# iOS Objective-C Development Patterns Index

**Purpose**: Router for iOS Objective-C patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **ios**, ios development, ios app, ios architecture, objective-c ios | `ios-best-practices.md` |
| **ios performance**, objc performance, instruments, profiling | `ios-performance.md` |

---

## iOS Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [iOS Best Practices](ios-best-practices.md) | Interoperability, legacy maintenance, delegates | ios, ios development |
| [iOS Performance](ios-performance.md) | Instruments, profiling, main thread | ios performance, instruments |

---

## Quick Reference

| Need | Load |
|------|------|
| iOS Objective-C patterns | `ios-best-practices.md` |
| iOS performance | `ios-performance.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for Objective-C language patterns

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
