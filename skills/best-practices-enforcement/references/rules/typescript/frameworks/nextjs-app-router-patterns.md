# Next.js App Router Patterns

The App Router (`app/` directory) is the recommended default for new Next.js projects from v13 onward; v16 makes it the primary documentation track. The Pages Router (`pages/`) remains supported for existing apps but does not get most new features.

This rule covers the boundary patterns and data-fetching shapes that show up in every App Router project. React 19 features (Actions, `use()`, `useOptimistic`) ship inside Next.js — see `frameworks/react-19-patterns.md` for those.

---

## Server vs Client components — the boundary rule

App Router components are **Server Components by default**. Add the `"use client"` directive at the top of a file to opt that file (and its imports) into client rendering.

| Server Component | Client Component |
|---|---|
| Default; no directive | First line: `"use client"` |
| Runs on server only | Hydrates and runs in the browser |
| Can be `async` | Cannot be `async` |
| Direct DB / filesystem / secrets access | No secrets — code ships to the browser |
| Cannot use `useState`, `useEffect`, event handlers | Full React hooks |
| Cannot use browser APIs (`window`, `localStorage`) | Yes |

✅ Good — fetch on the server, pass to client island:
```tsx
// app/products/page.tsx — Server Component
import { ProductFilter } from "./ProductFilter";

export default async function ProductsPage() {
  const products = await db.product.findMany();   // server-only
  return <ProductFilter products={products} />;
}
```

```tsx
// app/products/ProductFilter.tsx
"use client";
import { useState } from "react";

export function ProductFilter({ products }: { products: Product[] }) {
  const [query, setQuery] = useState("");
  // ...interactivity here
}
```

❌ Bad — pushing `"use client"` to the root:
```tsx
// app/layout.tsx
"use client";   // forces the entire tree to client render — defeats RSC
```

**Push the `"use client"` boundary as deep into the tree as possible.** Each `"use client"` file is a hydration island; the smaller the island, the smaller the JS shipped.

Source: [Next.js Docs — Server and Client Components](https://nextjs.org/docs/app/building-your-application/rendering/composition-patterns).

---

## Data fetching — fetch where you render

In the App Router, **data fetching belongs in the component that needs the data** — usually a Server Component. No more `getServerSideProps` indirection.

✅ Good — co-located fetch in the consuming component:
```tsx
async function ProductDetails({ id }: { id: string }) {
  const product = await fetch(`https://api.example.com/products/${id}`, {
    next: { revalidate: 3600 },   // cache for an hour
  }).then(r => r.json());

  return <article>{product.name}</article>;
}
```

✅ Good — parallel fetches with `Promise.all`:
```tsx
async function ProductPage({ id }: { id: string }) {
  const [product, reviews] = await Promise.all([
    fetchProduct(id),
    fetchReviews(id),
  ]);
  return <Layout product={product} reviews={reviews} />;
}
```

❌ Bad — fetching in a Client Component that doesn't need interactivity:
```tsx
"use client";
import useSWR from "swr";

function ProductDetails({ id }: { id: string }) {
  const { data } = useSWR(`/api/products/${id}`);    // extra round-trip from browser
  return <article>{data?.name}</article>;
}
```

Reach for SWR / TanStack Query only when you need client-driven refetching, polling, or mutations from outside an Action.

Source: [Next.js Docs — Data Fetching](https://nextjs.org/docs/app/building-your-application/data-fetching).

---

## Server Actions

Server Actions are server-side functions invoked from client components via form submissions or programmatic calls. Mark a file or function with `"use server"`.

✅ Good — Server Action in a module:
```ts
// app/users/actions.ts
"use server";

import { revalidatePath } from "next/cache";

export async function createUser(formData: FormData) {
  const name = String(formData.get("name"));
  const email = String(formData.get("email"));
  await db.user.create({ data: { name, email } });
  revalidatePath("/users");
}
```

```tsx
// app/users/NewUserForm.tsx
"use client";
import { createUser } from "./actions";

export function NewUserForm() {
  return (
    <form action={createUser}>
      <input name="name" required />
      <input name="email" type="email" required />
      <button>Create</button>
    </form>
  );
}
```

**Security:**
- Treat every Server Action as a public API. Validate every input — never trust the form payload. Use Zod or Valibot.
- Authorise inside the action. The `"use server"` directive does not authenticate the caller.
- Don't return secrets — the return value travels back to the client.

Source: [Next.js Docs — Server Actions](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations).

---

## Caching and revalidation

The App Router caches aggressively by default. Four cache layers, from outermost to innermost:

1. **Router Cache** (client memory, per session)
2. **Full Route Cache** (server, build-time or after first request)
3. **Data Cache** (server, per `fetch` call)
4. **Request Memoisation** (per-render dedup)

Common controls:

```ts
// Per-fetch
await fetch(url, { next: { revalidate: 60 } });          // ISR every 60s
await fetch(url, { cache: "no-store" });                 // dynamic, never cached
await fetch(url, { next: { tags: ["products"] } });      // tag for invalidation

// Per-route (in page.tsx or layout.tsx)
export const revalidate = 3600;
export const dynamic = "force-dynamic";                  // bail out of caching entirely

// Programmatic invalidation (inside a Server Action or route handler)
revalidatePath("/products");
revalidateTag("products");
```

**Audit rule:** every `fetch` should have an explicit `cache` or `next.revalidate` option. Implicit caching surprises debug sessions weeks later. If you genuinely want the default, leave a comment saying so.

Source: [Next.js Docs — Caching](https://nextjs.org/docs/app/building-your-application/caching).

---

## Route handlers — when an API endpoint is the right shape

For endpoints consumed by external clients, third-party webhooks, or non-React callers, use Route Handlers (`app/api/.../route.ts`). For React-only mutations, prefer Server Actions.

```ts
// app/api/users/[id]/route.ts
import { NextRequest } from "next/server";

export async function GET(_: NextRequest, { params }: { params: { id: string } }) {
  const user = await db.user.findUnique({ where: { id: params.id } });
  if (!user) return Response.json({ error: "Not found" }, { status: 404 });
  return Response.json(user);
}
```

Decision rule:
- **Server Action** — invoked from your own React app, returns serialisable data
- **Route Handler** — invoked by anything else, returns a `Response`

---

## Middleware

`middleware.ts` runs on every matched request — keep it small and edge-runtime-compatible (no Node.js APIs, no large dependencies). Use it for auth redirects, locale rewrites, A/B routing.

```ts
// middleware.ts
import { NextResponse, type NextRequest } from "next/server";

export function middleware(req: NextRequest) {
  if (!req.cookies.get("session")) {
    return NextResponse.redirect(new URL("/login", req.url));
  }
}

export const config = { matcher: ["/dashboard/:path*", "/account/:path*"] };
```

Never call your own API from middleware — it adds a hop on every request. Validate sessions against a JWT or signed cookie inline.

---

## See also

- `frameworks/react-19-patterns.md` — React 19 Actions, `use()`, `useOptimistic`
- `language/api-defensive-programming.md` — validating Server Action inputs
- `meta/security-best-practices.md` — XSS, CSRF (Server Actions handle CSRF for same-origin forms automatically)

---

## References

- [Next.js Docs](https://nextjs.org/docs) — v16.x; App Router primary track
- [Server and Client Composition Patterns](https://nextjs.org/docs/app/building-your-application/rendering/composition-patterns)
- [Server Actions and Mutations](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
- [Caching](https://nextjs.org/docs/app/building-your-application/caching)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
