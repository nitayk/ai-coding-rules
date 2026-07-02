# Modern Type Syntax (PEP 695 / Python 3.12+)

[PEP 695](https://peps.python.org/pep-0695/) introduced native syntax for generics, type aliases, and type parameters in Python 3.12. On Python 3.12+, prefer the native syntax over `typing.TypeVar` + `Generic[T]` + `TypeAlias`. The old forms still work but are now legacy — checkers, IDEs, and Python typing docs lead with the new syntax. Source: [typing.python.org](https://typing.python.org/en/latest/).

---

## Generic functions

```python
# ❌ Old (Python ≤ 3.11): TypeVar + explicit binding
from typing import TypeVar

T = TypeVar("T")

def first(items: list[T]) -> T:
    return items[0]
```

```python
# ✅ New (Python 3.12+): inline type parameter
def first[T](items: list[T]) -> T:
    return items[0]
```

The `[T]` binds the type parameter to the function. No module-level `TypeVar` declarations to keep in sync. Type checkers infer scoping automatically.

---

## Generic classes

```python
# ❌ Old: TypeVar + Generic[T] inheritance
from typing import Generic, TypeVar

T = TypeVar("T")

class Stack(Generic[T]):
    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> T:
        return self._items.pop()
```

```python
# ✅ New: native type parameter
class Stack[T]:
    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> T:
        return self._items.pop()
```

The `Generic[T]` base class is gone. Inheritance is unchanged; subclasses use the same syntax: `class TypedStack[T](Stack[T]): ...`.

---

## Type aliases

```python
# ❌ Old: bare assignment or TypeAlias annotation
from typing import TypeAlias

UserId: TypeAlias = int
UserMap: TypeAlias = dict[str, "User"]
```

```python
# ✅ New: `type` statement — lazy evaluation, no forward-reference quoting
type UserId = int
type UserMap = dict[str, User]      # `User` can be defined later in the file
```

The `type` statement is **lazily evaluated** — the right-hand side resolves on use, not on definition. This is what lets you reference `User` before its class definition without string-quoting.

---

## Bounds and constraints

```python
# ❌ Old
from typing import TypeVar

NumT = TypeVar("NumT", bound=float)              # bounded
StrOrBytes = TypeVar("StrOrBytes", str, bytes)   # constrained
```

```python
# ✅ New: inline bounds / constraints
def square[NumT: float](x: NumT) -> NumT:
    return x * x

def length[StrOrBytes: (str, bytes)](x: StrOrBytes) -> int:
    return len(x)
```

`T: SomeType` is a bound (T must be a subtype of SomeType). `T: (A, B, C)` is a constraint set (T must be exactly one of those types).

---

## ParamSpec and TypeVarTuple

The same `[...]` syntax handles `ParamSpec` (for callable signatures) and `TypeVarTuple` (for variadic generics):

```python
# ✅ New: ParamSpec inline (replaces typing.ParamSpec)
from collections.abc import Callable
from functools import wraps

def with_logging[**P, R](fn: Callable[P, R]) -> Callable[P, R]:
    @wraps(fn)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        log.info("calling", fn=fn.__name__)
        return fn(*args, **kwargs)
    return wrapper
```

```python
# ✅ New: TypeVarTuple inline (replaces typing.TypeVarTuple)
def stack[*Ts](*items: *Ts) -> tuple[*Ts, ...]:
    return tuple(items)
```

`**P` denotes a `ParamSpec`; `*Ts` denotes a `TypeVarTuple`. Native syntax — no `from typing import ParamSpec, TypeVarTuple` needed.

---

## Don't mix old and new in the same file

Pick one style per file. Mixing causes confusing scoping:

```python
# ❌ Bad: mixed styles in one module
from typing import TypeVar
T = TypeVar("T")

def first[U](items: list[U]) -> U:    # new
    return items[0]

def last(items: list[T]) -> T:        # old; different TypeVar
    return items[-1]
```

If the project targets Python 3.12+, migrate the whole file. If it supports older versions, stay on the old syntax — PEP 695 has no `__future__` import equivalent.

---

## When to keep the old syntax

- **`requires-python = ">=3.8"` or older** — PEP 695 syntax is a runtime SyntaxError on 3.11 and below.
- **You're writing typing stubs (`.pyi`)** that must work for users on older Python. Stub consumers' runtime version determines what they can parse.
- **You hit a checker bug** with PEP 695 (rare in 2026 — both mypy 2.x and pyright support it well).

For everything else on 3.12+, prefer the new syntax.

---

## Checker support

- **mypy 1.5+** supports PEP 695. mypy 2.x is fully aligned.
- **pyright** has had PEP 695 support since 1.1.331 (Oct 2023).
- **basedpyright** tracks pyright.
- **Ruff** doesn't enforce a preference but its `UP` (pyupgrade) ruleset will eventually flag old-style generics when `target-version = "py312"` — set it correctly in `pyproject.toml`.

---

## Common pitfalls

❌ Writing `class Foo[T](Generic[T]):` — redundant. `Generic[T]` is implied by the inline parameter.

❌ Forward-referencing in a `TypeAlias` without quoting on the old syntax: `UserMap: TypeAlias = dict[str, User]` where `User` is below — runtime NameError. Use the new `type` statement for free lazy evaluation.

❌ Importing `TypeVar` and never using it after a partial migration. Ruff's `F401` catches this; let it.

✅ Use `type Alias = ...` aggressively — it's clearer than bare assignment and the lazy evaluation eliminates an entire class of forward-reference bugs.

---

## Related rules

- [Type Annotations Everywhere](type-annotations-everywhere.md) — when to annotate at all
- [Type checker selection](../tooling/type-checker-selection.md) — mypy / pyright / basedpyright all support PEP 695
- [Ruff lint and format](../tooling/ruff-lint-and-format.md) — `UP` rules flag legacy typing constructs

---

## References

- [PEP 695 — Type Parameter Syntax](https://peps.python.org/pep-0695/) — accepted, Python 3.12
- [Static Typing with Python](https://typing.python.org/en/latest/) — PSF-hosted type system hub
- [Python typing module docs](https://docs.python.org/3/library/typing.html) — stdlib reference

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
