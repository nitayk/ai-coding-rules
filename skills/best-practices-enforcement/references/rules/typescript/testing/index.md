# Frontend Testing Patterns Index

**Purpose**: Router for frontend testing patterns - detects keywords and routes to specific pattern files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **vitest**, vue testing, component testing, frontend testing | `vitest-best-practices.md` |
| **vue component testing**, test utils, vue test utils | `vue-component-testing.md` |
| **playwright**, e2e playwright, @playwright/test | `playwright-best-practices.md` |
| **cypress**, e2e cypress, cypress.config | `cypress-best-practices.md` |

---

## Testing Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [Vitest Best Practices](vitest-best-practices.md) | Vitest testing patterns and best practices | vitest, vue testing, component testing |
| [Vue Component Testing](vue-component-testing.md) | @vue/test-utils patterns | vue component testing, test utils |
| [Playwright Best Practices](playwright-best-practices.md) | Playwright E2E patterns - locators, POM, assertions | playwright, e2e |
| [Cypress Best Practices](cypress-best-practices.md) | Cypress E2E patterns - data-cy, intercept, isolation | cypress, e2e |

---

## Quick Reference

| Need | Load |
|------|------|
| Vitest patterns | `vitest-best-practices.md` |
| Vue component testing | `vue-component-testing.md` |
| Playwright E2E | `playwright-best-practices.md` |
| Cypress E2E | `cypress-best-practices.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for language patterns
- **Frameworks**: See `../frameworks/index.md` for framework patterns
- **Generic**: See `references/rules/common/generic/testing/core-principles.md` for universal testing principles

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
