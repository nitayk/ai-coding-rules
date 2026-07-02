# Frontend Frameworks Index

**Purpose**: Router for frontend frameworks - detects keywords and routes to specific framework files.

**Chaining**: Router → Category Index → Language Index → This Index (Router) → Files

**Graph Structure**: This is a Layer 1 node that routes to Layer 0 leaves (rule files) based on keywords.

---

## Keyword → File Routing

| Keywords/Intent | Load File |
|----------------|-----------|
| **react**, react patterns, react hooks, react components, react best practices | `react-patterns.md` |
| **vue**, vue.js, vue patterns, vue composition api, vue best practices | `vue-best-practices.md` |
| **vuex**, vuex state, vuex store, vuex patterns, state management vue | `vuex-state-management.md` |

---

## Framework Pattern Files (Leaves)

| File | Purpose | Keywords |
|------|---------|----------|
| [React Patterns](react-patterns.md) | React hooks, components, React 19 features | react, react patterns, react hooks, react components |
| [Vue Best Practices](vue-best-practices.md) | Vue.js Composition API, reactivity, lifecycle | vue, vue.js, vue patterns, composition api |
| [Vuex State Management](vuex-state-management.md) | Vuex actions, mutations, getters, modules | vuex, vuex state, vuex store, state management |

---

## Quick Reference

| Need | Load |
|------|------|
| React patterns | `react-patterns.md` |
| Vue patterns | `vue-best-practices.md` |
| Vuex patterns | `vuex-state-management.md` |

---

## Related Resources

- **Language**: See `../language/index.md` for TypeScript/JavaScript patterns
- **Testing**: See `../testing/index.md` for testing patterns

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
