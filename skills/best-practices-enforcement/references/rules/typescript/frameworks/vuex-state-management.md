> **DEPRECATED — DO NOT USE FOR NEW CODE.**
>
> The Vue team officially recommends **[Pinia](https://pinia.vuejs.org/)** as the state-management solution for Vue 3 ([source](https://vuejs.org/guide/scaling-up/state-management.html#pinia)). Vuex 4 is in maintenance mode — bug fixes only, no new features. The original Vuex author (Evan You) created Pinia, and it is effectively "Vuex 5".
>
> **Migration path (high level):**
> - A Pinia store is a Vue 3 composable: `defineStore("user", () => { ... })`.
> - Mutations disappear — call store methods directly; reactivity handles the rest.
> - Modules become separate stores; cross-store references work via direct import.
> - Devtools, SSR, and the plugin API are preserved.
> - Official migration guide: <https://pinia.vuejs.org/cookbook/migration-vuex.html>.
>
> This file is kept so existing Vuex codebases still have a reference. Once your project has finished migrating, delete the Vuex rule import from your config.

---

# Vuex State Management (legacy reference)

## 1. Structure
- **Modules**: Split state into modules by domain (e.g., `user`, `cart`, `products`).
- **Namespacing**: Always use `namespaced: true` for modules to avoid naming collisions.

## 2. Typing (TypeScript)
- Define interfaces for `State` in each module.
- Define a `RootState` interface that combines all module states.
- Use `InjectionKey` to provide a typed `useStore()` hook.

```typescript
// store/types.ts
export interface UserState {
  profile: User | null;
  isAuthenticated: boolean;
}

export interface RootState {
  user: UserState;
  // other modules...
}
```

## 3. Best Practices
- **Mutations**: Must be synchronous. Use constants for mutation types.
- **Actions**: Can be asynchronous. Use for API calls and complex logic. Commit mutations to change state.
- **Getters**: Use for derived state (like `computed` properties).

## 4. Usage in Components
- Use `computed` for accessing state and getters.
- Use `dispatch` for actions.
- Avoid committing mutations directly from components; use actions instead.

```typescript
// Component
const store = useStore();
const user = computed(() => store.state.user.profile);
const isLoggedIn = computed(() => store.getters['user/isAuthenticated']);

function login() {
  store.dispatch('user/login', { ... });
}
```

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
