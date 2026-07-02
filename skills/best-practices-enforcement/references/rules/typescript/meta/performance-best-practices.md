# Performance Best Practices

Minimize bundle size. Use tree-shaking. Lazy load routes and heavy components. Avoid circular dependencies.

---

## Triggers

**APPLY WHEN:** Optimizing bundle size, adding new dependencies, implementing lazy loading, performance review.
**SKIP WHEN:** Internal-only scripts or negligible bundle impact.

---

## Core Directive

**Keep initial bundle small** - Use tree-shaking. Lazy load non-critical code. Split vendor and app chunks.

---

## Tree-Shaking Friendly Imports

**Use named imports; avoid importing entire libraries:**

```typescript
// Good: Named import (tree-shakeable)
import { debounce } from "lodash-es";
import { format } from "date-fns";

// Good: Path import for lodash
import debounce from "lodash/debounce";

// Bad: Full library import
import _ from "lodash";  // Entire library bundled
```

---

## Dynamic Imports for Code Splitting

**Lazy load routes and heavy components:**

```typescript
// Good: Route-based code splitting
const Dashboard = lazy(() => import("./pages/Dashboard"));
const Settings = lazy(() => import("./pages/Settings"));

// Good: Conditional heavy component
const HeavyChart = lazy(() => import("./HeavyChart"));
function Report() {
  const [showChart, setShowChart] = useState(false);
  return (
    <>
      <button onClick={() => setShowChart(true)}>Show Chart</button>
      {showChart && (
        <Suspense fallback={<Spinner />}>
          <HeavyChart />
        </Suspense>
      )}
    </>
  );
}

// Bad: Eager import of all routes
import Dashboard from "./pages/Dashboard";
import Settings from "./pages/Settings";
```

---

## Avoid Barrel File Bloat

**Be careful with barrel files (index.ts) that re-export everything:**

```typescript
// Bad: Barrel that pulls in everything
// components/index.ts
export * from "./Button";
export * from "./Modal";
export * from "./Chart";  // Heavy
// Usage: import { Button } from "./components" - may pull Chart

// Good: Direct imports for heavy components
import { Button } from "./components/Button";
import { Chart } from "./components/Chart";  // Explicit
```

---

## Bundle Analysis

**Use bundle analyzer to find large dependencies:**

```bash
# Vite
vite build --mode analyze

# Webpack
webpack --stats
```

Check for: duplicate packages, large transitive deps, unused imports.

---

## Module Preloading

**Use modulepreload for critical modules:**

```html
<link rel="modulepreload" href="/critical-module.js" />
```

---

## React Compiler — let it handle render-level memoisation

In a project using the React Compiler (React 19+ with `babel-plugin-react-compiler`), most existing `useMemo` / `useCallback` / `React.memo` calls become redundant — the Compiler auto-memoises components and dependency-tracked values. Audit new PRs to avoid hand-memoising under the Compiler. See `frameworks/react-19-patterns.md` § "React Compiler" for the migration checklist.

Bundle-level optimisations on this page (tree-shaking, code splitting, lazy loading, barrel-file discipline) are **not** replaced by the Compiler — they remain the developer's responsibility.

---

## Related Rules

- [React Patterns](../frameworks/react-patterns.md) - useMemo, useCallback, lazy
- [React 19 Patterns](../frameworks/react-19-patterns.md) - React Compiler, Server Components
- [Vue Best Practices](../frameworks/vue-best-practices.md) - Vue lazy loading

---

## References

- [Vite: Build Optimizations](https://vite.dev/guide/build.html) (replaces broken vitejs.dev URL)
- [webpack: Code Splitting](https://webpack.js.org/guides/code-splitting/) — secondary; most UADS-Web uses Vite
- [React Compiler](https://react.dev/learn/react-compiler) — auto-memoisation in React 19+

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
