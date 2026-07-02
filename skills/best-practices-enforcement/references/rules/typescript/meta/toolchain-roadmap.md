# TS/JS Toolchain Roadmap (2026)

A short advisory so the same "should we switch to Biome?" debate doesn't happen in every PR. Position as of **2026-05**; this file should be re-read whenever someone re-opens the question.

---

## TL;DR

| Tool | Recommendation | Re-evaluate when |
|---|---|---|
| **ESLint v9/v10 + typescript-eslint v8** | **Default — keep.** Only real option for our framework-plugin coverage (React Hooks, Next, Vue). | Biome ships type-aware rules + React Hooks parity |
| **Prettier v3** | **Default — keep.** Stable, universal editor support. | Biome formatter passes our internal diff audit (currently ~97% Prettier-compat) |
| **Biome v2** | **Track. Don't adopt as primary.** Acceptable as the only formatter for greenfield repos with no framework lint needs. | Type-aware rules + React Hooks plugin parity (~80% rule parity today) |
| **Oxlint v1** | **Track. Safe to add as a coexistence pre-filter.** Doesn't replace ESLint. | Type-aware rule support ships (currently rule-only, no type info) |
| **tsgo / TypeScript 7** | **Track. Don't switch build defaults.** Stop investing in `ts-node`/SWC workarounds — `tsgo` is the long-term answer. | Declaration emit + project references reach parity |

---

## Biome v2

Single Rust binary that handles lint + format with a Prettier-compatible output. 10–100× faster than ESLint+Prettier; ~80% ESLint rule parity (~502 rules in v2.4 release).

**Why not switch yet (for our stack):**
- No React Hooks plugin parity — `eslint-plugin-react-hooks` is irreplaceable for catching dependency-array bugs
- No Next.js plugin
- Vue support exists but is less mature than `eslint-plugin-vue`
- No type-aware rules — most of the bug-catching value in typescript-eslint v8 comes from its type-checked presets, which Biome can't yet replicate

**Where it's already fine:**
- A pure-TS library or CLI with no framework lint needs
- A new repo that hasn't accumulated a `.eslintrc` history yet
- As a **formatter-only** replacement for Prettier in performance-sensitive monorepos (run `biome format` and skip the lint side)

Source: [Biome v2](https://biomejs.dev/), [Biome vs ESLint+Prettier 2026 (PkgPulse)](https://www.pkgpulse.com/blog/biome-vs-eslint-prettier-2026).

---

## Oxlint v1

Rust linter, 650+ rules, 50–100× faster than ESLint, used in production by Shopify and Preact. Unlike Biome, Oxlint is **lint only** (no formatter) and is explicitly designed to coexist with ESLint rather than replace it.

**Suggested adoption pattern:**

```bash
# package.json
"scripts": {
  "lint:fast": "oxlint .",          # pre-commit / IDE; catches the easy wins
  "lint": "eslint .",               # CI; catches type-aware + framework-specific
  "lint:all": "oxlint . && eslint ."
}
```

Run Oxlint in pre-commit hooks and editor save; keep ESLint in CI for type-aware and framework rules. If Oxlint catches a problem, ESLint would too — failing fast is the only benefit, never the only check.

**Caveats:**
- No type-aware rules yet (the Oxlint team is working on it)
- Rule set is a subset of ESLint's; some custom rules won't have an equivalent
- Configuration is its own format — don't expect drop-in `eslint.config.js` reuse

Source: [Oxlint v1.0 Stable Released (InfoQ)](https://www.infoq.com/news/2025/08/oxlint-v1-released/), [Oxlint docs](https://oxc.rs/docs/guide/usage/linter.html).

---

## tsgo / TypeScript 7

Microsoft's native (Go) port of the TS compiler, targeting **7–10× faster type-checking**. Shipped under the `typescript-go` repository; will be released as TypeScript 7.

**Status (Dec 2025):**
- Type-checking: nearly feature-complete with the JS implementation
- Declaration emit (`.d.ts` generation): parity gaps remain
- Project references: parity gaps remain
- Editor integration: preview via the `tsgo` extension

**What this means for us:**
- **Don't switch build defaults.** Keep using `tsc` for type-check and `vite`/`tsup`/`esbuild` for emit.
- **Stop investing time in `ts-node` / SWC / babel-typescript workarounds** that exist purely to dodge `tsc`'s slowness — `tsgo` is the answer to those pains, not a third-party workaround. The exception: SWC/esbuild for production build emit remains the right call regardless of `tsgo`.
- **When to revisit:** when the `tsgo` blog series declares declaration emit and project references at parity, and at least one of our larger repos has been smoke-tested with it.

Source: [Progress on TypeScript 7 — Dec 2025](https://devblogs.microsoft.com/typescript/progress-on-typescript-7-december-2025/), [microsoft/typescript-go](https://github.com/microsoft/typescript-go), [A 10x Faster TypeScript](https://devblogs.microsoft.com/typescript/typescript-native-port/).

---

## How to use this file

When someone opens a PR or ticket proposing a toolchain swap:

1. Check the **Re-evaluate when** column in the TL;DR. If the trigger condition has happened, the recommendation is now stale — update this file first, then have the discussion.
2. If the trigger condition has not happened, link the requester here and close.
3. Greenfield repos: the recommendation in "Where it's already fine" sub-sections is the override — those teams can choose differently without re-litigating workspace defaults.

---

## See also

- `meta/eslint-flat-config.md` — what we actually use today
- `meta/javascript-typescript-style-guide.md` — naming/formatting baseline

---

## References

- [Biome v2](https://biomejs.dev/) — official site, rule index
- [Biome vs ESLint+Prettier 2026 (PkgPulse)](https://www.pkgpulse.com/blog/biome-vs-eslint-prettier-2026)
- [Oxlint docs](https://oxc.rs/docs/guide/usage/linter.html)
- [Oxlint v1.0 Stable Released (InfoQ)](https://www.infoq.com/news/2025/08/oxlint-v1-released/)
- [Progress on TypeScript 7 — Dec 2025](https://devblogs.microsoft.com/typescript/progress-on-typescript-7-december-2025/)
- [microsoft/typescript-go](https://github.com/microsoft/typescript-go)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
