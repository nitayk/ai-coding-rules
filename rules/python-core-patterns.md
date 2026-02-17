---
paths: "**/*.py"
---

# Python Core Patterns

## Triggers

**APPLY WHEN**: Writing or editing Python code.
**SKIP WHEN**: Reading-only or config files.

## Core Directive

Use type hints. Prefer Optional/Result over exceptions for expected failures. Avoid mutable defaults and bare except.

## Team-Specific Patterns

### Error Handling

**Preferred:** Exception for truly exceptional cases. `Optional[T]` for potentially missing values. Context managers for resources.
**Avoid:** Exception for normal flow control (e.g., `try/except` in `is_valid_email` returning bool).

### Mutable Default Arguments

**Avoid:**
```python
def add_item(item: str, items: List[str] = []):  # Shared across calls!
```

**Preferred:**
```python
def add_item(item: str, items: Optional[List[str]] = None) -> List[str]:
    if items is None:
        items = []
```

### Bare Exceptions

**Avoid:** `except:` (catches KeyboardInterrupt, SystemExit)
**Preferred:** `except (ValueError, TypeError) as e:`

### Modifying Lists While Iterating

**Avoid:** `for x in lst: lst.remove(x)` (skips elements)
**Preferred:** `lst = [x for x in lst if condition]` or iterate over `lst[:]`

### Type Hints and TypedDict

**Preferred:** Full type hints on public APIs. TypedDict for structured dicts. Dataclasses for data structures.
**Avoid:** Untyped `dict` parameters when structure is known.

## Anti-Patterns

- Do not use `isinstance` chains for type dispatch; use overloads or separate functions
- Do not load entire files into memory when streaming; use generators
- Use `enumerate` and `zip` instead of `range(len())`
