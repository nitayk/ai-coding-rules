# Language-Specific Review Patterns

Demoted from SKILL.md to keep the always-loaded skill focused on review
methodology. For the canonical, enforced versions of these rules, see
the `best-practices-enforcement` skill's bundled catalog under
`references/rules/<lang>/` (e.g. `references/rules/python/`,
`references/rules/typescript/`, `references/rules/go/`,
`references/rules/scala/`).

This file keeps a small "watch for these in review" cheat sheet — the
stack rules are the source of truth.

## Python — common review catches

```python
# Mutable default arguments — shared across calls
def add_item(item, items=[]):  # bug
    items.append(item); return items

def add_item(item, items=None):  # fix
    items = items if items is not None else []
    items.append(item); return items

# Bare except — swallows KeyboardInterrupt/SystemExit
try:    risky()
except: pass             # bad
except ValueError as e: logger.error(e); raise   # good

# Mutable class attribute — shared instance state
class User: permissions = []        # bad
class User:
    def __init__(self): self.permissions = []   # good
```

## TypeScript / JavaScript — common review catches

```typescript
// `any` defeats type safety — require a concrete interface
function processData(data: any) { return data.value; }   // bad

// Unhandled async errors — check response.ok and try/catch
async function fetchUser(id: string): Promise<User> {
  const r = await fetch(`/api/users/${id}`);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}

// Prop mutation in React — notify the parent instead
function UserProfile({ user, onView }: Props) {
  useEffect(() => onView(user.id), [user.id]);
  return <div>{user.name}</div>;
}
```

## Test quality — behavior over implementation

```typescript
// Bad: asserts on internal state
expect(component.state.counter).toBe(1);

// Good: asserts on user-visible behavior
expect(screen.getByText('Count: 1')).toBeInTheDocument();
```

Review questions for tests:

- Behavior, not implementation?
- Names describe the scenario and expectation?
- Edge cases + error cases covered?
- Independent (no shared mutable state, any order)?

## Security

Do not duplicate a security checklist here — invoke `/security-review`
(skill) on any diff that touches auth, input handling, secrets, crypto,
or external IO. It covers OWASP categories, secret scanning, and the
authn/authz/data-protection checklists this file used to inline.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
