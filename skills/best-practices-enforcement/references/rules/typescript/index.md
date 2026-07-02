# JavaScript & TypeScript Development Rules

**Stack Coverage**: 
- Vanilla JS/TS
- Vue.js 3 (Composition API & Options API)
- Node.js backend services
- Browser/Client-side applications

**Graph Structure**: This is a Layer 2 node that routes to Layer 1 nodes (subcategory indexes) or Layer 0 leaves (framework files) based on keywords.

---

## Keyword → Subcategory/Framework Routing

| Keywords/Intent | Load Subcategory Index |
|----------------|----------------------|
| **frameworks**, react, vue, vuex, framework patterns | `references/rules/typescript/frameworks/index.md` |
| **language**, typescript, javascript, type safety, api defensive | `references/rules/typescript/language/index.md` |
| **async**, promises, await, retry, timeout, concurrent | `language/async-patterns.md` |
| **error handling**, try catch, error boundaries, graceful degradation | `language/error-handling-patterns.md` |
| **modern javascript**, es6, es modules, destructuring | `language/modern-javascript-patterns.md` |
| **testing**, vitest, vue testing, playwright, cypress, component testing | `references/rules/typescript/testing/index.md` |
| **accessibility**, a11y, wcag, aria, screen reader | `meta/accessibility-best-practices.md` |
| **security**, xss, csrf, input validation | `meta/security-best-practices.md` |
| **performance**, bundle size, lazy loading, tree-shaking | `meta/performance-best-practices.md` |

---

## Quick Reference

### Core Language Patterns (`language/`)
**Load**: `references/rules/typescript/language/index.md` ← Points to language pattern files
- **[@TypeScript Strict Type Safety](language/typescript-strict-type-safety.md)** - Strict mode, avoid any, use unknown, type guards
- **[@API Defensive Programming](language/api-defensive-programming.md)** - Safe property access, schema change resilience, backward compatibility
- **[@Modern JavaScript Patterns](language/modern-javascript-patterns.md)** - ES6+, const/let, destructuring, modules
- **[@Error Handling Patterns](language/error-handling-patterns.md)** - Try/catch, error boundaries, graceful degradation
- **[@Async Patterns](language/async-patterns.md)** - Promises, async/await, retries, timeouts, AbortController

### Architecture & Design (Planned)
- **[@Module Organization](architecture/module-organization.md)** - ES modules, exports, barrel files
- **[@Component Design](architecture/component-design-patterns.md)** - Composition, single responsibility
- **[@State Management](architecture/state-management-patterns.md)** - Vuex, local state, reactive patterns
- **[@Dependency Injection](architecture/dependency-injection.md)** - Service patterns, testability

### Framework-Specific (`frameworks/`)
**Load**: `references/rules/typescript/frameworks/index.md` ← Points to framework pattern files
- **[@Vue.js Best Practices](frameworks/vue-best-practices.md)** - Composition API, reactivity, lifecycle
- **[@Vuex Patterns](frameworks/vuex-state-management.md)** - **[DEPRECATED]** legacy reference; new code should use Pinia
- **[@React Patterns](frameworks/react-patterns.md)** - Hooks, performance optimization (baseline)
- **[@React 19 Patterns](frameworks/react-19-patterns.md)** - React Compiler, Server Components, `use()`, Actions, `useOptimistic`
- **[@Next.js App Router Patterns](frameworks/nextjs-app-router-patterns.md)** - Server/client boundaries, Server Actions, caching, route handlers

### Testing (`testing/`)
**Load**: `references/rules/typescript/testing/index.md` ← Points to testing pattern files
- **[@Testing Best Practices](testing/vitest-best-practices.md)** - Vitest, Jest, mocking
- **[@Vue Component Testing](testing/vue-component-testing.md)** - @vue/test-utils patterns

### Code Quality & Meta (`meta/`)
- **[@Code Style Guide](meta/javascript-typescript-style-guide.md)** - Naming, imports, exports, file structure, JSDoc, Prettier baseline
- **[@ESLint Flat Config](meta/eslint-flat-config.md)** - `eslint.config.js`, `defineConfig`, typescript-eslint v8 wiring (replaces legacy `.eslintrc.*`)
- **[@Toolchain Roadmap](meta/toolchain-roadmap.md)** - Advisory stance on Biome v2, Oxlint v1, tsgo / TypeScript 7
- **[@Performance Best Practices](meta/performance-best-practices.md)** - Bundle size, tree-shaking, lazy loading
- **[@Security Best Practices](meta/security-best-practices.md)** - XSS, CSRF, input validation
- **[@Accessibility Best Practices](meta/accessibility-best-practices.md)** - WCAG, ARIA, semantic HTML, keyboard nav

### Language Features (`language/`)
- **[@Modern TypeScript Features](language/modern-typescript-features.md)** - `satisfies`, `const T`, `using`/`await using`, stage-3 decorators, `--erasableSyntaxOnly`

---

## When to Use These Rules

### For Vue.js Projects
- Follow Vue-specific patterns in `frameworks/vue-best-practices.md`
- Use Composition API for new components
- Apply Vuex patterns for global state

### For Mixed JS/TS Projects
- Gradually adopt TypeScript patterns
- Use strict null checks where possible
- Maintain compatibility with existing JS code

### For New TypeScript Projects
- Start with strict mode enabled
- Use interfaces over types for objects
- Leverage utility types (Partial, Pick, Omit)

---

## Rule Hierarchy

1. **Global Rules** (always apply)
   - `@generic/communication/business-communication-standards.md`
   - `@generic/communication/tool-communication-pattern.md`

2. **Language-Specific** (this folder)
   - Modern JavaScript patterns
   - TypeScript type safety
   - Error handling

3. **Framework-Specific** (when using Vue/React)
   - Vue.js patterns
   - Vuex state management

---

## Common Patterns

### DO: Use Modern JavaScript
```typescript
// Use const/let, not var
const apiUrl = 'https://api.example.com';
let retryCount = 0;

// Use arrow functions for callbacks
const numbers = [1, 2, 3].map(n => n * 2);

// Use destructuring
const { id, name } = user;
const [first, ...rest] = array;

// Use async/await over raw promises
async function fetchData(): Promise<Data> {
  const response = await fetch(url);
  return response.json();
}
```

### DO: Leverage TypeScript
```typescript
// Define interfaces for data shapes
interface User {
  id: string;
  name: string;
  email: string;
}

// Use union types for state
type LoadingState = 'idle' | 'loading' | 'success' | 'error';

// Use generics for reusable functions
function first<T>(arr: T[]): T | undefined {
  return arr[0];
}
```

### DON'T: Mix Patterns
```typescript
// BAD: Mixing callbacks and promises
function badAsync(callback) {
  return fetch(url)  // Returns promise
    .then(res => callback(res));  // Uses callback
}

// GOOD: Consistent async/await
async function goodAsync(): Promise<Response> {
  return await fetch(url);
}
```

---

## Integration with Existing Rules

- **Error Handling**: See `language/error-handling-patterns.md` and `generic/error-handling/universal-patterns.md`
- **Testing**: See `@testing/vitest-best-practices.md`
- **Git Workflow**: Use the `/git-workflow` skill
- **Refactoring**: Use the `/code-simplification` skill

---

## Tool Configuration

### ESLint Flat Config (`eslint.config.js`)

`.eslintrc.*` is **removed in ESLint v10 (Feb 2026)**. New projects use flat config; existing projects should migrate now. See `meta/eslint-flat-config.md` for the full guide.

```javascript
// eslint.config.js
import { defineConfig } from "eslint/config";
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import prettier from "eslint-config-prettier";

export default defineConfig([
  { ignores: ["dist/**", "build/**", "coverage/**"] },
  js.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    files: ["**/*.ts", "**/*.tsx"],
    languageOptions: {
      parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
    },
    rules: {
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "@typescript-eslint/consistent-type-imports": "error",
    },
  },
  prettier, // must be last — disables ESLint rules that conflict with Prettier
]);
```

For Vue / React / Next plugin wiring, see `meta/eslint-flat-config.md` § "Framework plugins". Note: `airbnb-base` is no longer recommended (assumes Babel-era tooling; community has moved off) — use the Google TypeScript Style Guide as the style basis instead. See `meta/javascript-typescript-style-guide.md`.

### TypeScript (tsconfig.json)
```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

---

## See Also

- **[@Python Rules](../backend/python/index.md)** - For backend services
- **[@Scala Rules](../backend/scala/index.md)** - For JVM services
- **[@Go Rules](../backend/go/index.md)** - For microservices

---

**Last Updated**: 2026-05-27
**Maintainers**: DevOps/Platform Team

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->

---

## References

### Canonical language & runtime
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) — official, last updated 2026-05-25
- [TypeScript Release Notes (5.0+)](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html) — `satisfies`, `const T`, `using`, decorators
- [Progress on TypeScript 7 — Dec 2025](https://devblogs.microsoft.com/typescript/progress-on-typescript-7-december-2025/) — native (Go) compiler `tsgo` status
- [MDN JavaScript Guide](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide) — language reference
- [TC39 Finished Proposals](https://github.com/tc39/proposals/blob/main/finished-proposals.md) — what is actually in ECMAScript

### Style & tooling
- [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html) — primary style basis (Airbnb's guide is no longer recommended for new TS code)
- [typescript-eslint](https://typescript-eslint.io/) — de-facto TS + ESLint integration (v8.x)
- [ESLint Flat Config Migration Guide](https://eslint.org/docs/latest/use/configure/migration-guide) — mandatory format as of ESLint v10 (Feb 2026)

### Frameworks
- [React Reference](https://react.dev/reference/react) — React 19, React Compiler, Rules of React
- [Vue 3 Guide](https://vuejs.org/guide/introduction.html) — Composition API is recommended default
- [Next.js Docs](https://nextjs.org/docs) — App Router is the recommended default (v16.x)
- [Vite Guide](https://vite.dev/guide/build.html) — v8.x (replaces broken vitejs.dev URLs)

### Testing & quality
- [Vitest Guide](https://vitest.dev/guide/) — v4.x; default unit-test framework
- [Playwright Best Practices](https://playwright.dev/docs/best-practices) — locator strategy, web-first assertions

### Security
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [MDN Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP) (redirect-corrected from `/Web/HTTP/CSP`)

### Track-but-don't-adopt-yet (toolchain alternatives)
- [Biome v2](https://biomejs.dev/) — single-binary lint+format, ~80% ESLint rule parity; reconsider when type-aware rules land
- [Oxlint v1](https://oxc.rs/docs/guide/usage/linter.html) — Rust linter, 650+ rules, used by Shopify/Preact; safe as ESLint coexistence

<!-- Cross-platform: see AGENTS.md in this repository for Cursor, Claude Code, and Copilot paths. -->
