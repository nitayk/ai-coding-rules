# JavaScript & TypeScript Style Guide

A team-neutral baseline for how we write TS/JS across the workspace. Based on the [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html) (also mirrored at [ts.dev/style](https://ts.dev/style/)), adapted for our React 19 / Vue 3 / Vite / Vitest stack. Airbnb's style guide is no longer recommended for new TS code — it assumes Babel-era tooling and has slowed in maintenance.

This file covers what to name things, how to organise a file, and how to format it. Type-system rules (avoid `any`, prefer `unknown`, strict mode) live in `language/typescript-strict-type-safety.md`; lint config lives in `meta/eslint-flat-config.md`.

---

## Naming

| Kind | Style | Example |
|------|-------|---------|
| Variables, parameters, functions, methods, properties, module-local | `camelCase` | `userCount`, `fetchUser()` |
| Classes, interfaces, type aliases, enums, decorators | `PascalCase` | `UserService`, `LoadingState` |
| Enum members | `PascalCase` (Google) — not `CONSTANT_CASE` | `Status.Active` |
| Module-level constants (true compile-time constants only) | `CONSTANT_CASE` | `MAX_RETRY_COUNT` |
| React components, Vue components | `PascalCase` | `UserCard`, `ProductList.vue` |
| React hooks | `useCamelCase` | `useUser`, `useDebounce` |
| Type parameters | Single uppercase, or `PascalCase` if descriptive | `T`, `TResponse`, `TItem` |
| Files | `kebab-case` for modules, `PascalCase` for single-component files | `user-service.ts`, `UserCard.tsx` |

**Don't:**
- Hungarian notation (`strName`, `IUser`)
- Trailing/leading underscores (`_private`, `name_`) — use `#private` fields or TS `private` instead
- Single-letter names outside very short loops or type parameters

✅ Good:
```ts
const MAX_RETRY_COUNT = 3;
class UserService {
  async fetchUser(id: string): Promise<User> { ... }
}
function useUser(userId: string) { ... }
```

❌ Bad:
```ts
const max_retry_count = 3;          // wrong case for constant
class userService { ... }            // class must be PascalCase
interface IUser { ... }              // no "I" prefix
function GetUser() { ... }           // function must be camelCase
```

Source: [Google TS Style Guide — Identifiers](https://google.github.io/styleguide/tsguide.html#identifiers).

---

## Imports

### Use ES module syntax

✅ Good:
```ts
import { debounce } from "lodash-es";
import type { User } from "./types";
```

❌ Bad:
```ts
const lodash = require("lodash");          // CommonJS in TS source
import * as everything from "./utils";     // namespace import for normal modules
```

### Use `import type` for type-only imports

This enables `isolatedModules` / `--erasableSyntaxOnly` (TS 5.8) and lets bundlers drop the import entirely. Mix runtime and type imports with the inline `type` specifier.

✅ Good:
```ts
import type { User } from "./types";
import { fetchUser, type FetchOptions } from "./api";
```

### Import ordering

Standard order (separate groups by a blank line):

1. Node/runtime built-ins (`node:fs`, `node:path`)
2. External packages (`react`, `lodash-es`)
3. Internal absolute imports (`@/components/...`)
4. Relative parent imports (`../`)
5. Relative sibling imports (`./`)
6. Side-effect / stylesheet imports (`./styles.css`)

Most teams delegate this to `eslint-plugin-import` or `simple-import-sort` — pin the order in lint config, don't fight it manually.

### Path aliases

Use TS `paths` (in `tsconfig.json`) plus the matching bundler config (`vite.config.ts` `resolve.alias`, etc.). Conventional aliases: `@/` → `src/`, `@test/` → `test/`. Don't invent a new alias per package.

---

## Exports

### Prefer named exports

Named exports give you grep-ability, safer refactors, and consistent identifiers across callers. Default exports invite drift (each caller picks its own name) and break tree-shaking heuristics in some bundlers.

✅ Good:
```ts
// user-service.ts
export class UserService { ... }
export function createUserService(): UserService { ... }
```

❌ Bad:
```ts
// user-service.ts
export default class UserService { ... }    // each caller picks the name
```

**Exceptions:** React lazy-loaded components (`React.lazy(() => import('./X'))` resolves the default), Next.js / Nuxt page files, and Vue SFCs (`<script setup>` is effectively a default export).

### Avoid wildcard re-exports in barrels

`export * from "./foo"` defeats tree-shaking and silently re-exports any new symbol added to `foo`. Use explicit re-exports, and keep barrel files small (or skip them entirely for large feature modules).

✅ Good:
```ts
// components/index.ts
export { Button } from "./Button";
export { Modal } from "./Modal";
```

See also `meta/performance-best-practices.md` § "Avoid Barrel File Bloat".

---

## File structure

Aim for **one logical unit per file**. A React component file may co-locate its props type, sub-components, and small helpers; a service file should not also export unrelated utilities.

Recommended top-to-bottom order inside a file:

1. License/copyright header (if applicable)
2. Imports (ordered as above)
3. Type aliases, interfaces, enums
4. Constants
5. The primary exported symbol (component, class, main function)
6. Helper functions (un-exported)
7. Test-only exports (gated behind `if (import.meta.vitest)` or in a sibling `__tests__/`)

Keep files under ~300 lines as a soft cap. Past that, split by concern (extract a sub-component, extract a hook, extract a service).

---

## Formatting

**Delegate to Prettier (v3.x).** Don't bikeshed in PRs about commas, quotes, or wrapping — the formatter decides.

Workspace defaults (set once in `.prettierrc`):

```json
{
  "semi": true,
  "singleQuote": false,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "arrowParens": "always"
}
```

Run `prettier --write` in pre-commit (via `lint-staged` or a Husky hook). CI should run `prettier --check` and fail on diffs.

ESLint and Prettier do **not** overlap: ESLint catches bugs and enforces patterns; Prettier handles whitespace. Use `eslint-config-prettier` to disable any ESLint rules that conflict with Prettier output.

---

## Comments and JSDoc

Use JSDoc (`/** ... */`) for **exported** functions, classes, and types so editors can surface the docs on hover. Use line comments (`// ...`) for implementation notes.

✅ Good:
```ts
/**
 * Fetches a user by id and validates the response shape.
 *
 * @throws {ApiError} when the response is not 2xx
 * @throws {ValidationError} when the response body doesn't match the schema
 */
export async function fetchUser(id: string): Promise<User> { ... }
```

- Don't restate TypeScript types in JSDoc (`@param {string} id`) — the type system already says it.
- Don't write JSDoc for self-evident wrappers.
- Do document **behaviour the type can't express**: thrown errors, side-effects, units, valid ranges, why a workaround exists.
- Prefer linking to a ticket or doc over reproducing context inline.

---

## TODOs

Format TODOs so they're searchable and assigned:

```ts
// TODO(b/12345): Drop the legacy fallback once all clients are on v2.
// FIXME(@alice): Race condition when two tabs open simultaneously.
```

Include an issue link or username. A `TODO` with no owner has a half-life of forever.

---

## Strings, numbers, booleans

- Double quotes for strings (Prettier default in this guide). Template literals for interpolation.
- Booleans should read as questions or states: `isLoading`, `hasError`, `canEdit`. Never `flag`, `bool`, or `state`.
- Numeric literals: use underscore separators for readability — `const MAX_BYTES = 10_000_000`.
- Don't compare against `true`/`false` explicitly: `if (isLoading)` not `if (isLoading === true)`.

---

## See also

- `language/typescript-strict-type-safety.md` — type-system rules (`any`/`unknown`, strict flags, type guards)
- `language/modern-typescript-features.md` — `satisfies`, `const T`, `using`, decorators
- `meta/eslint-flat-config.md` — lint configuration (replaces legacy `.eslintrc.js`)
- `meta/performance-best-practices.md` — barrel files, tree-shaking

---

## References

- [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html) — primary basis for this rule
- [ts.dev/style](https://ts.dev/style/) — community-maintained mirror with rationale
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [Prettier Docs](https://prettier.io/docs/en/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
