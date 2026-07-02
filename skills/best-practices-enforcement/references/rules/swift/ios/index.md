# iOS Swift Development Patterns Index

**Purpose**: Router for iOS Swift patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **ios**, ios development, ios architecture, mvvm ios, swiftui, uikit | `ios-best-practices.md` |
| **@Observable**, Observation framework, @Bindable, iOS 17 state management | `observation-framework.md` |
| **ios performance**, ios memory management, instruments, swiftui performance | `ios-performance.md` |

---

## iOS Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [iOS Best Practices](ios-best-practices.md) | MVVM, UIKit/SwiftUI, memory management | ios, ios development, ios architecture, swiftui |
| [Observation Framework](observation-framework.md) | @Observable macro, @Bindable, iOS 17+ state management | @Observable, Observation, @Bindable |
| [iOS Performance](ios-performance.md) | Memory management, profiling, Instruments, SwiftUI performance | ios performance, ios memory management, instruments |

---

## Quick Reference

| Need | Load |
|------|------|
| iOS best practices | `ios-best-practices.md` |
| iOS performance | `ios-performance.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for Swift language patterns

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
