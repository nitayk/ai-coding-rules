# Modern TypeScript Features (5.x)

TypeScript 5.0–5.8 introduced several features that materially change how we write idiomatic TS — most usefully `satisfies`, `const` type parameters, and `using` for explicit resource cleanup. This rule covers what's worth reaching for in 2026 and what's still niche.

The strict-type rules in `language/typescript-strict-type-safety.md` remain the foundation; this file is additive.

---

## `satisfies` — validate without widening

`satisfies` (TS 5.0) checks that a value matches a type **without** replacing the value's inferred (narrower) type. This is the missing tool for "I want type-checking on a constant, but I also want autocomplete on its specific keys."

✅ Good:
```ts
type Palette = Record<string, `#${string}` | [number, number, number]>;

const palette = {
  red: "#ff0000",
  green: [0, 255, 0],
  blue: "#0000ff",
} satisfies Palette;

palette.red.toUpperCase();     // OK — TS knows red is a string
palette.green[0];              // OK — TS knows green is a tuple
```

❌ Bad — type annotation widens:
```ts
const palette: Palette = {
  red: "#ff0000",
  green: [0, 255, 0],
  blue: "#0000ff",
};
palette.red.toUpperCase();     // Error — TS only knows red is string | tuple
```

❌ Bad — `as` is unsafe:
```ts
const palette = {
  red: "#zzzzzz",              // typo accepted because `as` skips checking
} as Palette;
```

Rule of thumb: reach for `satisfies` whenever you'd otherwise write `as const` plus a separate type assertion. Source: [Total TypeScript: 5 Ways to Use the Satisfies Operator](https://www.totaltypescript.com/how-to-use-satisfies-operator).

---

## `const` type parameters — preserve literal inference

`const T` (TS 5.0) tells TS to infer the **narrowest possible** type for a generic argument — the same effect as the caller writing `as const`, but without burdening the caller.

✅ Good:
```ts
function defineRoutes<const T extends readonly string[]>(routes: T): T {
  return routes;
}

const routes = defineRoutes(["/home", "/about", "/contact"]);
//    ^? readonly ["/home", "/about", "/contact"]
```

Without `const T`, `routes` would be inferred as `string[]` and the literal info would be lost.

❌ Bad — forcing the caller to remember `as const`:
```ts
function defineRoutes<T extends readonly string[]>(routes: T): T { return routes; }
const routes = defineRoutes(["/home", "/about"] as const);   // boilerplate at every call site
```

Use `const T` for builder-style APIs, config helpers, and anywhere you want callers to keep literal types without thinking about it. Source: [TypeScript 5.0 Release Notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html#const-type-parameters).

---

## `using` and `await using` — explicit resource cleanup

TS 5.2 added support for the stage-3 [Explicit Resource Management](https://github.com/tc39/proposal-explicit-resource-management) proposal. Variables declared with `using` automatically call `[Symbol.dispose]()` when they go out of scope; `await using` calls `[Symbol.asyncDispose]()`.

This replaces nested `try/finally` blocks for any resource you'd otherwise have to remember to close.

✅ Good — synchronous cleanup:
```ts
function withTempFile<T>(fn: (path: string) => T): T {
  using temp = createTempFile();   // disposed at end of scope
  return fn(temp.path);
}

class TempFile implements Disposable {
  constructor(public readonly path: string) {}
  [Symbol.dispose]() {
    fs.unlinkSync(this.path);
  }
}
```

✅ Good — async cleanup:
```ts
async function readFromDb(query: string) {
  await using conn = await pool.acquire();   // released even if query throws
  return conn.query(query);
}
```

❌ Bad — manual try/finally that's easy to forget:
```ts
async function readFromDb(query: string) {
  const conn = await pool.acquire();
  try {
    return await conn.query(query);
  } finally {
    await conn.release();        // every caller has to remember this
  }
}
```

**Runtime requirements:** Node.js 22+, modern browsers (or a polyfill via `disposablestack/auto`). Most bundlers and runtimes handle the downlevelling in 2026, but verify before adopting in older targets. Source: [TypeScript 5.2 Release Notes — `using`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-2.html#using-declarations-and-explicit-resource-management).

---

## Stage-3 decorators

TS 5.0 shipped support for the [TC39 stage-3 decorators proposal](https://github.com/tc39/proposal-decorators) (not the older "experimental" decorators that required `experimentalDecorators: true`). The new form is what landed in ECMAScript.

```ts
function loggable<This, Args extends any[], Return>(
  target: (this: This, ...args: Args) => Return,
  context: ClassMethodDecoratorContext<This>,
) {
  return function (this: This, ...args: Args): Return {
    console.log(`-> ${String(context.name)}(${args.join(", ")})`);
    return target.apply(this, args);
  };
}

class Calculator {
  @loggable
  add(a: number, b: number) { return a + b; }
}
```

**Status:** Usable in greenfield code. Don't mix with `experimentalDecorators: true` — they're incompatible. Most existing decorator-heavy libraries (Angular, NestJS, TypeORM) still ship the experimental form; check before migrating. Source: [TypeScript 5.0 Release Notes — Decorators](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html#decorators).

---

## `--erasableSyntaxOnly` — emit-friendly TS

TS 5.8 introduced `--erasableSyntaxOnly` to flag any TS syntax that **isn't** a pure type erasure — namely `enum`, `namespace` with runtime members, parameter properties (`constructor(public x: number)`), and the legacy `experimentalDecorators`. Useful when you want your TS to be runnable by Node.js's built-in type stripping (Node 22.6+) or by `ts-blank-space`.

```jsonc
{
  "compilerOptions": {
    "erasableSyntaxOnly": true
  }
}
```

Once enabled, expect errors on:
- `enum Status { Active, Inactive }` → use `as const` objects + a union type
- `class Foo { constructor(public name: string) {} }` → assign explicitly in the body
- `namespace Foo { export const x = 1 }` → use modules

✅ Good replacement for an enum:
```ts
const Status = { Active: "active", Inactive: "inactive" } as const;
type Status = typeof Status[keyof typeof Status];
```

Source: [TypeScript 5.8 Release Notes — `--erasableSyntaxOnly`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-8.html).

---

## A note on `tsgo` / TypeScript 7

Microsoft is porting the TS compiler to Go (`tsgo`) for ~7–10x faster type-checking; it ships as TypeScript 7. Type-checking is near feature-complete; declaration emit and project-reference parity still have gaps as of late 2025.

**Don't switch defaults yet.** Continue to use the JS compiler for builds. Stop investing in `ts-node` / SWC workarounds that exist purely to dodge `tsc` performance — `tsgo` is the long-term answer. Track [Progress on TypeScript 7 — Dec 2025](https://devblogs.microsoft.com/typescript/progress-on-typescript-7-december-2025/) for the green light.

---

## See also

- `language/typescript-strict-type-safety.md` — strict flags, type guards, discriminated unions
- `language/async-patterns.md` — Promise, AbortController (companion to `await using`)
- `meta/toolchain-roadmap.md` — when to revisit Biome / Oxlint / tsgo

---

## References

- [TypeScript 5.0 Release Notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-0.html) — `satisfies`, `const T`, decorators
- [TypeScript 5.2 Release Notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-2.html) — `using` / `await using`
- [TypeScript 5.8 Release Notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-8.html) — `--erasableSyntaxOnly`
- [Progress on TypeScript 7 — Dec 2025](https://devblogs.microsoft.com/typescript/progress-on-typescript-7-december-2025/)
- [Total TypeScript: 5 Ways to Use Satisfies](https://www.totaltypescript.com/how-to-use-satisfies-operator)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
