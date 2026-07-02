# ESLint Flat Config

ESLint v9 (Apr 2024) made flat config (`eslint.config.js`) the default; **ESLint v10 (Feb 2026) removed `.eslintrc.*` support entirely**. New projects use flat config; existing projects should migrate now while there is still a transition path.

This rule covers the minimum a TS-heavy repo needs: file shape, `defineConfig`, `extends`, `globalIgnores`, and how to wire typescript-eslint v8 plus the common framework plugins.

---

## Why flat config

- **Single explicit array**. No cascading discovery, no merging surprises across nested `.eslintrc.json` files. Each config object explicitly says what files it applies to.
- **Plain JavaScript**. Imports work the same as anywhere else — no shareable-config indirection (`extends: ["airbnb"]`) that hides a network of transitive plugins.
- **Forward-compatible**. Legacy `.eslintrc.*` no longer accepts new plugin features as of v10.

Source: [ESLint Flat Config Migration Guide](https://eslint.org/docs/latest/use/configure/migration-guide).

---

## File shape

Use `eslint.config.js` (or `.mjs` / `.ts`). The default export is an array of config objects; each object can scope to specific files via `files` and ignore via `ignores`.

✅ Good — minimal TS + Prettier setup:

```js
// eslint.config.js
import { defineConfig } from "eslint/config";
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import prettier from "eslint-config-prettier";

export default defineConfig([
  // 1. Global ignores (replaces .eslintignore)
  {
    ignores: ["dist/**", "build/**", "coverage/**", "**/*.generated.ts"],
  },

  // 2. Base JS rules
  js.configs.recommended,

  // 3. typescript-eslint v8 (flat-config-native)
  ...tseslint.configs.recommendedTypeChecked,
  {
    files: ["**/*.ts", "**/*.tsx"],
    languageOptions: {
      parserOptions: {
        projectService: true,          // type-aware rules, auto-detects tsconfig
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },

  // 4. Project-specific overrides
  {
    files: ["**/*.ts", "**/*.tsx"],
    rules: {
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "@typescript-eslint/consistent-type-imports": "error",
    },
  },

  // 5. Turn off rules that conflict with Prettier — must be LAST
  prettier,
]);
```

`defineConfig` (added in ESLint v9.21) gives you type hints and validates the shape — prefer it over a bare array literal.

Source: [Evolving flat config with extends, defineConfig, and globalIgnores](https://eslint.org/blog/2025/03/flat-config-extends-define-config-global-ignores/).

---

## Migrating from `.eslintrc.*`

```bash
npx @eslint/migrate-config .eslintrc.json   # writes eslint.config.js
```

The codemod handles ~90% of cases. Manual fix-ups usually needed for:
- Plugins that haven't shipped flat-config presets (rare in 2026)
- `overrides:` blocks → become separate config objects with their own `files:`
- `.eslintignore` → moved into the `ignores:` field of an early config object
- `parserOptions.project: true` → prefer `projectService: true` for typescript-eslint v8

❌ Bad — don't keep `.eslintrc.*` around "just in case":

```
.eslintrc.json       # ESLint v10 ignores this entirely
.eslintignore        # also ignored
eslint.config.js     # the only file ESLint will read
```

Delete the legacy files in the same PR as the migration — leaving them is a future-confusion trap.

---

## typescript-eslint v8 specifics

Use the **flat-config-native** preset (`tseslint.configs.recommendedTypeChecked`), not the legacy `plugin:@typescript-eslint/recommended` extends string.

Three preset tiers from lightest to strictest:
- `tseslint.configs.recommended` — fast, no type info needed
- `tseslint.configs.recommendedTypeChecked` — adds rules that need the type checker (catches more real bugs; slower)
- `tseslint.configs.strictTypeChecked` — strict project baseline; expect noise on legacy code

For monorepos, set `parserOptions.projectService: true` (v8 default) — it auto-discovers `tsconfig.json` per file and is dramatically faster than the old `project: [array]` configuration.

Source: [typescript-eslint Getting Started](https://typescript-eslint.io/getting-started/).

---

## Framework plugins

### React

```js
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";

export default defineConfig([
  // ...base config
  {
    files: ["**/*.{jsx,tsx}"],
    ...react.configs.flat.recommended,
    settings: { react: { version: "detect" } },
  },
  {
    files: ["**/*.{jsx,tsx}"],
    plugins: { "react-hooks": reactHooks },
    rules: reactHooks.configs.recommended.rules,
  },
]);
```

React Compiler (React 19+) ships its own lint rule via `eslint-plugin-react-compiler` — add it if you're on the compiler track.

### Vue 3

```js
import vue from "eslint-plugin-vue";

export default defineConfig([
  ...vue.configs["flat/recommended"],
  {
    files: ["**/*.vue"],
    languageOptions: {
      parserOptions: {
        parser: tseslint.parser,         // TS inside <script setup lang="ts">
      },
    },
  },
]);
```

### Next.js

`eslint-config-next` shipped a flat-config build in 2025. Import it directly:

```js
import next from "@next/eslint-plugin-next";
// or: import nextConfig from "eslint-config-next/flat";
```

---

## `globalIgnores` (ESLint v9.21+)

Use the dedicated helper to make ignores explicit and shareable:

```js
import { defineConfig, globalIgnores } from "eslint/config";

export default defineConfig([
  globalIgnores(["dist/**", "**/*.snap", ".next/**"]),
  // ...
]);
```

Functionally equivalent to an `{ignores: [...]}` object at index 0, but reads more clearly.

---

## CI integration

Run `eslint .` (no `--ext` flag needed — flat config decides scope via `files:`).

```bash
# package.json
"scripts": {
  "lint": "eslint .",
  "lint:fix": "eslint . --fix"
}
```

In CI, fail on warnings: `eslint . --max-warnings=0`.

---

## What about Biome / Oxlint?

See `meta/toolchain-roadmap.md`. Short version: **stay on ESLint + typescript-eslint** for now if you depend on framework-specific plugins (React Hooks, Next, Vue) — Biome v2 and Oxlint v1 are faster but don't yet match ecosystem coverage. Oxlint is safe to run **alongside** ESLint as a fast pre-filter.

---

## See also

- `meta/javascript-typescript-style-guide.md` — naming, imports, formatting
- `meta/toolchain-roadmap.md` — when to revisit Biome / Oxlint / tsgo
- `language/typescript-strict-type-safety.md` — strict tsconfig flags

---

## References

- [ESLint Flat Config Migration Guide](https://eslint.org/docs/latest/use/configure/migration-guide) — canonical migration steps
- [Evolving flat config — defineConfig, globalIgnores, extends](https://eslint.org/blog/2025/03/flat-config-extends-define-config-global-ignores/)
- [typescript-eslint Getting Started](https://typescript-eslint.io/getting-started/)
- [typescript-eslint v8 release notes](https://typescript-eslint.io/blog/announcing-typescript-eslint-v8/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
