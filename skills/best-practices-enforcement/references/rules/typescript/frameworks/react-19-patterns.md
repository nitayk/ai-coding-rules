# React 19 Patterns

React 19 (Dec 2024) and the React Compiler (RC throughout 2025) materially changed how idiomatic React is written. This rule covers the new shape of components; baseline hook rules and performance patterns from earlier React eras still apply (see `frameworks/react-patterns.md`).

---

## React Compiler — stop hand-memoising

The React Compiler automatically memoises components, hooks, and dependency-tracked values. In a Compiler-enabled project, **most existing `useMemo` / `useCallback` / `React.memo` calls become noise** — the Compiler does the equivalent, more reliably, with less code.

✅ Good — let the Compiler handle it:
```tsx
function UserList({ users, onUserClick }: Props) {
  const sortedUsers = users.slice().sort((a, b) => a.name.localeCompare(b.name));
  const handleClick = (id: string) => onUserClick(id);

  return sortedUsers.map(u => <UserCard key={u.id} user={u} onClick={handleClick} />);
}
```

❌ Bad — manual memoisation on a Compiler-enabled file:
```tsx
function UserList({ users, onUserClick }: Props) {
  const sortedUsers = useMemo(
    () => users.slice().sort((a, b) => a.name.localeCompare(b.name)),
    [users],
  );
  const handleClick = useCallback((id: string) => onUserClick(id), [onUserClick]);
  // ...
}
```

**Adoption checklist:**
1. Install `babel-plugin-react-compiler` and enable in your build (see [React Compiler docs](https://react.dev/learn/react-compiler)).
2. Install `eslint-plugin-react-compiler` and fix all of its diagnostics first — the Compiler only optimises components that follow the Rules of React.
3. Roll out per-directory using `compilationMode: "annotation"` plus a `"use memo"` directive, before flipping the project-wide switch.
4. Once on, remove `useMemo` / `useCallback` calls in new code. Leave existing ones — the Compiler tolerates them.

**Don't reach for the Compiler if:**
- Your codebase has a backlog of Rules-of-React violations the lint plugin flags (fix those first)
- You're on React 18 or earlier — the Compiler targets React 19+

Source: [React Compiler](https://react.dev/learn/react-compiler).

---

## Server Components and the `use client` boundary

Server Components run on the server, never ship JS to the client, and can be async. They're the default in App-Router Next.js (16.x) and any other RSC-enabled framework. Client Components opt in via the `"use client"` directive at the top of the file.

✅ Good — server data fetch + client interactivity boundary:
```tsx
// app/users/page.tsx — Server Component (default)
import { UserList } from "./UserList";   // client component

export default async function UsersPage() {
  const users = await db.user.findMany();   // runs on server, no client JS
  return <UserList initialUsers={users} />;
}
```

```tsx
// app/users/UserList.tsx
"use client";

import { useState } from "react";

export function UserList({ initialUsers }: { initialUsers: User[] }) {
  const [filter, setFilter] = useState("");
  // ...interactive UI
}
```

**Boundary rules:**
- A Server Component can render a Client Component (passing serialisable props)
- A Client Component **cannot** import a Server Component module directly; pass it as `children` or a prop instead
- Functions and class instances can't cross the boundary — only serialisable values

Source: [React Reference — Server Components](https://react.dev/reference/rsc/server-components).

---

## `use()` — read promises and context conditionally

`use()` (React 19) reads a Promise or Context. Unlike other hooks, it can be called **inside conditionals, loops, and early returns** — it integrates with Suspense for promises.

✅ Good — Suspense-friendly data reading:
```tsx
import { use, Suspense } from "react";

function UserName({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);    // suspends until resolved
  return <span>{user.name}</span>;
}

function UserPage({ userId }: { userId: string }) {
  const userPromise = fetchUser(userId);   // create the promise; don't await
  return (
    <Suspense fallback={<Spinner />}>
      <UserName userPromise={userPromise} />
    </Suspense>
  );
}
```

❌ Bad — creating a new promise on every render (causes infinite loops):
```tsx
function UserName({ userId }: { userId: string }) {
  const user = use(fetchUser(userId));   // new promise every render
  return <span>{user.name}</span>;
}
```

Always create the promise outside the rendering call — typically in a Server Component, a parent that owns the cache, or via a data-fetching library that returns a stable promise per cache key.

Source: [React Reference — use](https://react.dev/reference/react/use).

---

## Actions and `useActionState`

An Action is an async function passed to a form's `action` prop (or to `useActionState` / `useTransition`). React tracks the pending state and the latest result without manual `useState`.

✅ Good — form Action with built-in pending and error state:
```tsx
"use client";
import { useActionState } from "react";

async function submitUser(prevState: SubmitState, formData: FormData): Promise<SubmitState> {
  try {
    const user = await createUser({
      name: String(formData.get("name")),
      email: String(formData.get("email")),
    });
    return { status: "ok", userId: user.id };
  } catch (err) {
    return { status: "error", message: (err as Error).message };
  }
}

export function NewUserForm() {
  const [state, formAction, isPending] = useActionState(submitUser, { status: "idle" });

  return (
    <form action={formAction}>
      <input name="name" required />
      <input name="email" type="email" required />
      <button disabled={isPending}>{isPending ? "Saving..." : "Save"}</button>
      {state.status === "error" && <p role="alert">{state.message}</p>}
    </form>
  );
}
```

❌ Bad — re-implementing pending/error tracking by hand:
```tsx
const [isSubmitting, setSubmitting] = useState(false);
const [error, setError] = useState<string | null>(null);
const onSubmit = async (e: FormEvent) => {
  e.preventDefault();
  setSubmitting(true);
  // ...all the boilerplate Actions handle for you
};
```

Source: [React Reference — useActionState](https://react.dev/reference/react/useActionState).

---

## `useOptimistic` — optimistic UI without manual rollback

`useOptimistic` lets you render a temporary state while an Action is pending, automatically reverting if the Action throws.

✅ Good:
```tsx
"use client";
import { useOptimistic } from "react";

function MessageList({ messages, sendMessage }: Props) {
  const [optimisticMessages, addOptimisticMessage] = useOptimistic(
    messages,
    (state, newMessage: string) => [
      ...state,
      { id: "optimistic", text: newMessage, pending: true },
    ],
  );

  async function send(formData: FormData) {
    const text = String(formData.get("text"));
    addOptimisticMessage(text);
    await sendMessage(text);       // server round-trip; revert on throw
  }

  return (
    <>
      {optimisticMessages.map(m => (
        <li key={m.id} style={{ opacity: m.pending ? 0.5 : 1 }}>{m.text}</li>
      ))}
      <form action={send}>...</form>
    </>
  );
}
```

Source: [React Reference — useOptimistic](https://react.dev/reference/react/useOptimistic).

---

## Error boundaries — prefer libraries

React 19 still ships the class-component `componentDidCatch` API, but most projects should use a library that integrates with Suspense and Actions — `react-error-boundary` is the de-facto choice.

✅ Good:
```tsx
import { ErrorBoundary } from "react-error-boundary";

<ErrorBoundary
  fallback={<ErrorPage />}
  onError={(err, info) => logError(err, info)}
  onReset={() => queryClient.resetQueries()}
>
  <UserDashboard />
</ErrorBoundary>
```

The class-component pattern from `language/error-handling-patterns.md` still works, but the library handles reset, retry, and Suspense interaction out of the box.

---

## See also

- `frameworks/react-patterns.md` — Rules of Hooks, baseline patterns (still apply)
- `language/error-handling-patterns.md` — error boundary fallback semantics
- `frameworks/nextjs-app-router-patterns.md` — when using React 19 inside Next.js App Router

---

## References

- [React Reference (react.dev)](https://react.dev/reference/react) — React 19 + Compiler + Rules of React
- [React Compiler](https://react.dev/learn/react-compiler)
- [React Server Components](https://react.dev/reference/rsc/server-components)
- [useActionState](https://react.dev/reference/react/useActionState)
- [useOptimistic](https://react.dev/reference/react/useOptimistic)
- [use()](https://react.dev/reference/react/use)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
