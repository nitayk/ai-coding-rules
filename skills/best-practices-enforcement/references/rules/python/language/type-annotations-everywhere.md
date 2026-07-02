# Type Annotations Everywhere

Use type annotations on all functions, variables, and class attributes to enable static type checking and improve code correctness. On Python 3.12+, prefer the native PEP 695 generic syntax (`def first[T](items: list[T]) -> T:`, `type Alias = ...`) over `typing.TypeVar` / `Generic[T]` / `TypeAlias` — see `language/modern-type-syntax-3-12.md`. For checker selection (mypy vs pyright vs basedpyright), see `tooling/type-checker-selection.md`.

---

## Annotate Function Signatures

**Always annotate function parameters and return types:**

```python
# Good: Fully annotated function
def calculate_total(items: list[Item]) -> float:
    return sum(item.price for item in items)

# Bad: No type annotations
def calculate_total(items):
    return sum(item.price for item in items)
```

**Benefits:**
- Static type checkers (mypy, pyright) catch type errors
- Better IDE autocomplete and navigation
- Self-documenting code

---

## Annotate Variables

**Annotate variables when type isn't obvious from context:**

```python
# Good: Explicit type annotation (use | None for Python 3.10+)
user_id: int | None = get_user_id()
if user_id is not None:
    process_user(user_id)

# Good: Built-in generics for complex types
config: dict[str, list[str]] = {
    "allowed_hosts": ["example.com", "test.com"]
}

# Bad: No annotation, type unclear
user_id = get_user_id()  # What type is this?
```

---

## Use Generic Types

**Use generic types for collections. Prefer built-in generics (Python 3.9+) and PEP 695 native syntax (Python 3.12+):**

```python
# Good: Built-in generics (Python 3.9+)
def process_users(users: list[User]) -> list[ProcessedUser]:
    return [process_user(u) for u in users]

def get_user_by_email(email: str) -> User | None:
    return db.find_user(email)

# Good: type statement for aliases (Python 3.12+, PEP 695)
type UserId = int
type UserMap = dict[str, User]

# Good: PEP 695 inline generics (Python 3.12+) — no module-level TypeVar
def first[T](items: list[T]) -> T:
    return items[0]

class Stack[T]:
    def __init__(self) -> None:
        self._items: list[T] = []

# Acceptable: typing.TypeVar for codebases targeting Python ≤ 3.11
from typing import TypeVar
T = TypeVar("T")
def first_legacy(items: list[T]) -> T:
    return items[0]

# Bad: Untyped parameters
def process_users(users):  # What's in the list?
    return [process_user(u) for u in users]
```

---

## Annotate Class Attributes

**Annotate class attributes with their types:**

```python
# Good: Annotated class attributes (avoid mutable defaults)
from dataclasses import dataclass

@dataclass
class User:
    name: str
    email: str
    age: int | None = None
    preferences: dict[str, str] | None = None

# Bad: No type annotations
class User:
    def __init__(self, name, email, age=None):
        self.name = name
        self.email = email
        self.age = age  # What type is age?
```

---

## Use Type Aliases for Complex Types

**Create type aliases for frequently used complex types. Prefer `type` statement (Python 3.12+):**

```python
# Good: type statement (Python 3.12+)
type UserId = int
type UserDict = dict[str, str]
type Coordinates = tuple[float, float]

def find_user(user_id: UserId) -> User | None:
    return db.find(user_id)

def process_coordinates(coords: Coordinates) -> float:
    lat, lon = coords
    return calculate_distance(lat, lon)

# Good: Traditional alias (Python 3.9-3.11)
UserId = int
Coordinates = tuple[float, float]

# Bad: Complex types inline
def process_coordinates(coords: tuple[float, float]) -> float:
    # Less clear what the tuple represents
    lat, lon = coords
    return calculate_distance(lat, lon)
```

---

## Configure Type Checkers

**Pick one checker per repo and pin it in `pyproject.toml`. The three serious options in 2025-2026:**

- **mypy** — reference checker (mypy 2.x), best plugin ecosystem (SQLAlchemy, Pydantic, Django).
- **pyright** — Microsoft's checker; powers Pylance in VSCode; fast and incremental.
- **basedpyright** — community fork of pyright with Pylance features unlocked outside VSCode, stricter defaults, baseline support, PyPI install (no Node).

See `tooling/type-checker-selection.md` for the full decision matrix. Don't run two checkers in CI — they will disagree on edges (Self, protocol variance, overload resolution) and the noise is unfixable.

```toml
# Good: mypy in pyproject.toml
[tool.mypy]
python_version = "3.13"
strict = true            # turns on the full strict bundle for new code
warn_return_any = true
warn_unreachable = true
```

```toml
# Good: pyright / basedpyright in pyproject.toml
[tool.pyright]            # same key works for basedpyright
pythonVersion = "3.13"
typeCheckingMode = "strict"
```

**Run type checker in CI:**

```yaml
# Good: Type checking in CI (pick one)
- run: uv run mypy src/         # or: pyright / basedpyright
```

---

## Gradual Typing Migration

**Add types incrementally, starting with public APIs:**

```python
# Good: Start with public API
def public_api_function(user_id: int) -> User:
    """Public API - fully typed."""
    return _internal_helper(user_id)

# Internal function can be untyped initially
def _internal_helper(user_id):  # Will add types later
    return db.find(user_id)

# Bad: No types anywhere
def public_api_function(user_id):
    return db.find(user_id)
```

---

## Use TypedDict for Structured Data

**Use TypedDict for dictionary structures:**

```python
# Good: TypedDict for structured data
from typing import TypedDict

class UserDict(TypedDict):
    name: str
    email: str
    age: int

def create_user(data: UserDict) -> User:
    return User(**data)

# Bad: Plain dict without structure
def create_user(data: dict) -> User:
    return User(**data)  # No type checking of dict keys
```

---

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../../../generic/code-quality/core-principles.md) - Universal principles (make illegal states unrepresentable, type safety)

**Python-Specific:**
- [Error Handling Patterns](error-handling-patterns.md) - Error types and exceptions
- [Advanced Features](advanced-features.md) - More Python type features

---

## References

- [Static Typing with Python (typing.python.org)](https://typing.python.org/en/latest/) — canonical PSF-hosted type-system hub
- [PEP 695 — Type Parameter Syntax](https://peps.python.org/pep-0695/) — native generic syntax in Python 3.12+
- [Python Typing Documentation](https://docs.python.org/3/library/typing.html) — stdlib reference
- [mypy documentation](https://mypy.readthedocs.io/en/stable/) — reference checker
- [pyright documentation](https://microsoft.github.io/pyright/) — Microsoft's checker
- [basedpyright documentation](https://docs.basedpyright.com/latest/) — pyright fork with stricter defaults
- [Hudson River Trading: Building Robust Codebases with Type Annotations](https://www.hudsonrivertrading.com/hrtbeat/building-robust-codebases-with-pythons-type-annotations/)
- [Meta: Typed Python Survey 2024](https://engineering.fb.com/2024/12/09/developer-tools/typed-python-2024-survey-meta/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
