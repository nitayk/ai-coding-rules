# Objective-C Language Patterns Index

**Purpose**: Router for Objective-C language patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **objective-c style**, objc style, objc formatting, style guide | `style-guide.md` |
| **arc**, memory management, retain cycles, weak strong | `arc-memory-management.md` |
| **blocks**, gcd, dispatch, grand central dispatch, async objc | `blocks-gcd.md` |
| **nullability**, swift interop, NS_ASSUME_NONNULL, NS_SWIFT_NAME | `nullability-swift-interop.md` |
| **nserror**, error handling, objc error | `error-handling.md` |
| **protocol**, delegate, objc delegate | `protocols-delegates.md` |
| **category**, categories, extending class | `categories.md` |

---

## Language Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Style Guide](style-guide.md) | Naming, formatting, pragma marks, literals | objective-c style, objc formatting |
| [ARC Memory Management](arc-memory-management.md) | Strong/weak, retain cycles, property attributes | arc, memory management |
| [Blocks and GCD](blocks-gcd.md) | Blocks, Grand Central Dispatch, async patterns | blocks, gcd, dispatch |
| [Nullability and Swift Interop](nullability-swift-interop.md) | Swift interoperability, nullability annotations | nullability, swift interop |
| [Error Handling](error-handling.md) | NSError patterns, propagation | nserror, error handling |
| [Protocols and Delegates](protocols-delegates.md) | Delegate pattern, weak, optional methods | protocol, delegate |
| [Categories](categories.md) | Extending classes, method prefixes | category, categories |

---

## Quick Reference

| Need | Load |
|------|------|
| Style guide | `style-guide.md` |
| ARC memory management | `arc-memory-management.md` |
| Blocks and GCD | `blocks-gcd.md` |
| Swift interoperability | `nullability-swift-interop.md` |
| Error handling | `error-handling.md` |
| Protocols and delegates | `protocols-delegates.md` |
| Categories | `categories.md` |

---

## Related Resources

- **iOS**: See `../ios/index.md` for iOS patterns

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
