# Playwright Best Practices

End-to-end tests must be **deterministic, fast, and trustworthy** — a flaky E2E suite trains the team to ignore failures. The patterns below come from the official [Playwright Best Practices](https://playwright.dev/docs/best-practices) page plus what we've learned in our own suites.

**APPLY WHEN:** Writing or reviewing Playwright end-to-end tests.

---

## Use `@playwright/test`, not the bare `playwright` library

Use the official test runner for fixtures, isolation, parallelism, and web-first assertions. The low-level `playwright` library is for scripting browsers programmatically — not for tests.

✅ Good:
```ts
import { test, expect } from "@playwright/test";

test("navigates to home", async ({ page }) => {
  await page.goto("/");
  await expect(page).toHaveTitle(/Home/);
});
```

❌ Bad:
```ts
import { chromium } from "playwright";
const browser = await chromium.launch();
// Manual setup/teardown, no fixtures, no parallelism
```

---

## Locator strategy — user-facing first

Prefer locators that resemble how a user finds the element. They're resilient to refactors that change CSS, class names, or DOM nesting.

**Preference order:**

1. `getByRole(role, { name })` — uses the accessibility tree
2. `getByLabel(text)` — for form inputs
3. `getByPlaceholder(text)`, `getByText(text)`, `getByAltText(text)`, `getByTitle(text)`
4. `getByTestId(id)` — when the above don't fit; add `data-testid` to the production element
5. CSS / XPath — last resort

✅ Good:
```ts
await page.getByRole("button", { name: "Add to Cart" }).click();
await page.getByLabel("Username").fill("testuser");
await page.getByTestId("product-item-123").click();
```

❌ Bad:
```ts
await page.locator("div.container > ul > li:nth-child(2) > button").click();
await page.locator("xpath=//div[3]/span").click();
```

`getByRole` doubles as accessibility coverage — if an element has no role, your screen-reader users can't find it either.

---

## Web-first assertions — never sleep

Playwright's `expect()` assertions **auto-retry** until they pass or the timeout expires. Never use `page.waitForTimeout()` — it's the single biggest source of flakiness.

✅ Good:
```ts
await expect(page).toHaveTitle(/My Page/);
await expect(page.getByText("Welcome")).toBeVisible();
await expect(page.getByRole("checkbox")).toBeChecked();
await expect(page.getByRole("list").getByRole("listitem")).toHaveCount(5);
```

❌ Bad:
```ts
await page.waitForTimeout(2000);                  // hopes the page settled
const title = await page.title();
expect(title).toBe("My Page");                    // snapshot, no retry
```

If you genuinely need to wait for a specific network call, use `page.waitForResponse()` with a URL matcher — not a fixed delay.

---

## Test isolation and parallelism

Each `test()` gets a **fresh browser context** by default — fresh cookies, fresh localStorage, isolated from siblings. Tests run in parallel across worker processes.

**Rules:**

- Don't share mutable state between tests in a module. Use fixtures.
- Don't rely on test order. Tests in a file run in declaration order by default but workers shuffle files.
- Use `test.describe.serial()` only for cases where one test really does set up the next (e.g. a multi-step user journey). Prefer fixtures.
- Use `test.describe.configure({ mode: "parallel" })` to opt files into intra-file parallelism for further speedup.

✅ Good — fixture for shared setup:
```ts
import { test as base } from "@playwright/test";

type Fixtures = { authedPage: Page };

export const test = base.extend<Fixtures>({
  authedPage: async ({ browser }, use) => {
    const ctx = await browser.newContext({ storageState: "auth/user.json" });
    const page = await ctx.newPage();
    await use(page);
    await ctx.close();
  },
});

test("dashboard loads for authed user", async ({ authedPage }) => {
  await authedPage.goto("/dashboard");
  await expect(authedPage.getByRole("heading", { name: /welcome/i })).toBeVisible();
});
```

---

## Page Object Model — for repeated flows

Encapsulate selectors and multi-step actions in dedicated classes when the same flow appears in three or more tests. Don't POM-ify single-use selectors — premature abstraction is worse than duplication.

✅ Good:
```ts
// pages/LoginPage.ts
export class LoginPage {
  constructor(readonly page: Page) {}

  async goto() { await this.page.goto("/login"); }

  async login(username: string, password: string) {
    await this.page.getByLabel("Username").fill(username);
    await this.page.getByLabel("Password").fill(password);
    await this.page.getByRole("button", { name: "Login" }).click();
    await this.page.waitForURL("/dashboard");
  }
}
```

---

## Auth state — set up once, reuse everywhere

Don't log in via the UI in every test — it's slow and adds a failure mode. Run login once in `globalSetup`, save the resulting `storageState`, and reuse it.

```ts
// playwright.config.ts
export default defineConfig({
  globalSetup: "./global-setup.ts",
  use: { storageState: "auth/user.json" },
});

// global-setup.ts
import { chromium } from "@playwright/test";
async function globalSetup() {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto("/login");
  await page.getByLabel("Username").fill(process.env.TEST_USER!);
  await page.getByLabel("Password").fill(process.env.TEST_PASSWORD!);
  await page.getByRole("button", { name: "Login" }).click();
  await page.context().storageState({ path: "auth/user.json" });
  await browser.close();
}
export default globalSetup;
```

For multiple personas (admin, regular user, guest), save a separate `storageState` per project in `playwright.config.ts`.

---

## API mocking and route blocking

Isolate UI tests from backend flakiness. Mock APIs at the network layer with `page.route()`.

✅ Good:
```ts
await page.route("**/api/products", async route => {
  await route.fulfill({
    status: 200,
    contentType: "application/json",
    body: JSON.stringify([{ id: 1, name: "Mock Product" }]),
  });
});
```

Block third-party scripts (analytics, ads) that slow tests or call out:
```ts
await context.route(/google-analytics|hotjar|segment/, route => route.abort());
```

---

## Traces, screenshots, videos

Enable trace capture on retry — it's the difference between "flaky test, no idea why" and a recording you can scrub through.

```ts
// playwright.config.ts
export default defineConfig({
  use: {
    trace: "on-first-retry",         // captures every action, network call, console log
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  retries: process.env.CI ? 2 : 0,
});
```

Open a failed trace with `npx playwright show-trace trace.zip` — it's a full DevTools-like timeline.

---

## CI guidance

- Pin the Playwright version (don't use `^`). Browser versions are bound to the library — drift causes mysterious failures.
- Cache the browser binaries: `~/.cache/ms-playwright`.
- Use `--forbid-only` in CI to fail if anyone left a `test.only` behind.
- Run on a fresh container per CI job; don't reuse browsers across jobs.
- Set `workers` explicitly for CI (`workers: process.env.CI ? 4 : undefined`) — auto-detection often gets the count wrong on shared runners.

---

## Related

- **Skill:** `/webapp-testing` — Playwright-based web testing workflow
- `testing/vitest-best-practices.md` — unit and component tests
- `meta/accessibility-best-practices.md` — `getByRole` is also your a11y signal

---

## References

- [Playwright Best Practices](https://playwright.dev/docs/best-practices) — canonical
- [Playwright Locators](https://playwright.dev/docs/locators)
- [Playwright Auth](https://playwright.dev/docs/auth)
- [Playwright Trace Viewer](https://playwright.dev/docs/trace-viewer)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
