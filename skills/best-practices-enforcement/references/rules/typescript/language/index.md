# JavaScript/TypeScript Language Patterns Index

**Purpose**: Router for JS/TS language patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **typescript strict**, ts strict, strict type safety, type guards, avoid any | `typescript-strict-type-safety.md` |
| **api defensive**, safe property access, schema change resilience | `api-defensive-programming.md` |
| **async**, promises, await, retry, timeout, concurrent | `async-patterns.md` |
| **error handling**, try catch, error boundaries, graceful degradation | `error-handling-patterns.md` |
| **modern javascript**, es6, es modules, destructuring, const let | `modern-javascript-patterns.md` |

---

## Language Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [TypeScript Strict Type Safety](typescript-strict-type-safety.md) | Strict mode, avoid any, use unknown, type guards | typescript strict, ts strict, strict type safety |
| [API Defensive Programming](api-defensive-programming.md) | Safe property access, schema change resilience | api defensive, safe property access |
| [Async Patterns](async-patterns.md) | Promises, async/await, retries, timeouts, AbortController | async, promises, retry, timeout |
| [Error Handling Patterns](error-handling-patterns.md) | Try/catch, error boundaries, custom errors | error handling, try catch, error boundaries |
| [Modern JavaScript Patterns](modern-javascript-patterns.md) | ES6+, const/let, destructuring, modules | modern javascript, es6, es modules |

---

## Quick Reference

| Need | Load |
|------|------|
| TypeScript strict | `typescript-strict-type-safety.md` |
| API safety | `api-defensive-programming.md` |
| Async patterns | `async-patterns.md` |
| Error handling | `error-handling-patterns.md` |
| Modern JS | `modern-javascript-patterns.md` |

---

## Related Resources

- **Frameworks**: See `../frameworks/index.md` for React/Vue patterns
- **Testing**: See `../testing/index.md` for testing patterns

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
