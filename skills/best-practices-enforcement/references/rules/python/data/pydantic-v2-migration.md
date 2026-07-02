# Pydantic v1 → v2 Migration

Pydantic v2 (current v2.13.x) has been the production line since 2023; v1 is in maintenance only. New code should be v2-native. This rule maps the breaking changes you'll hit when porting v1 code or reviewing PRs that still use v1 idioms. The canonical reference is the [Pydantic v2 migration guide](https://pydantic.dev/docs/validation/latest/get-started/migration/).

---

## Method rename cheatsheet

| Pydantic v1 | Pydantic v2 |
|---|---|
| `model.dict()` | `model.model_dump()` |
| `model.json()` | `model.model_dump_json()` |
| `Model.parse_obj(d)` | `Model.model_validate(d)` |
| `Model.parse_raw(s)` | `Model.model_validate_json(s)` |
| `model.copy()` | `model.model_copy()` |
| `Model.schema()` | `Model.model_json_schema()` |
| `Model.construct(**d)` | `Model.model_construct(**d)` |
| `Model.__fields__` | `Model.model_fields` |

v1 method names still exist on v2 models as deprecation shims — they emit warnings. Treat the warning as a CI failure; don't ship code that relies on the shim.

---

## Validators

```python
# ❌ Bad: v1 @validator with `values` dict and pre/always kwargs
from pydantic import BaseModel, validator

class User(BaseModel):
    name: str
    email: str

    @validator("email", pre=True, always=True)
    def lowercase_email(cls, v, values):
        return v.lower()

    @validator("name")
    def name_matches_email(cls, v, values):
        if "email" in values and v.lower() not in values["email"]:
            raise ValueError("name must appear in email")
        return v
```

```python
# ✅ Good: v2 @field_validator + @model_validator
from pydantic import BaseModel, field_validator, model_validator

class User(BaseModel):
    name: str
    email: str

    @field_validator("email", mode="before")
    @classmethod
    def lowercase_email(cls, v: str) -> str:
        return v.lower()

    @model_validator(mode="after")
    def name_matches_email(self) -> "User":
        if self.name.lower() not in self.email:
            raise ValueError("name must appear in email")
        return self
```

Key shifts:

- `@field_validator` for single-field; `@model_validator` for cross-field.
- `pre=True` → `mode="before"`. `always=True` is gone (always runs in v2).
- v1's `values` dict is replaced: `mode="after"` validators receive the fully-constructed `self`; `mode="before"` receive raw input.
- `@classmethod` is required on `@field_validator` — Pydantic enforces it.

---

## Config → model_config

```python
# ❌ Bad: v1 inner Config class
class User(BaseModel):
    name: str

    class Config:
        allow_population_by_field_name = True
        orm_mode = True
        extra = "forbid"
```

```python
# ✅ Good: v2 model_config dict (or ConfigDict)
from pydantic import BaseModel, ConfigDict

class User(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,    # renamed from allow_population_by_field_name
        from_attributes=True,     # renamed from orm_mode
        extra="forbid",
    )
    name: str
```

Renamed config keys (most common):

- `allow_population_by_field_name` → `populate_by_name`
- `orm_mode` → `from_attributes`
- `allow_mutation = False` → `frozen = True`
- `schema_extra` → `json_schema_extra`
- `validate_all` → removed; v2 always validates all fields

---

## Settings moved to its own package

In v1, `BaseSettings` lived in `pydantic`. In v2 it lives in the **separate `pydantic-settings`** package — installed and imported independently.

```python
# ❌ Bad: v1 import path (no longer works in v2)
from pydantic import BaseSettings

# ✅ Good: v2 — install pydantic-settings, import from there
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    db_url: str
    log_level: str = "INFO"
```

```toml
# pyproject.toml
dependencies = [
    "pydantic>=2",
    "pydantic-settings>=2",   # explicit — it's no longer bundled
]
```

---

## Field defaults and Field()

```python
# ✅ Good: v2 Field — constraints moved into Field()
from pydantic import BaseModel, Field
from typing import Annotated

class Item(BaseModel):
    # min_items / max_items renamed to min_length / max_length
    tags: list[str] = Field(default_factory=list, max_length=10)
    # constraints work for numeric fields too
    quantity: Annotated[int, Field(ge=0, le=1000)]
```

Renamed constraint kwargs:

- `min_items` / `max_items` → `min_length` / `max_length`
- `regex` → `pattern`
- `const=X` is gone — use `Literal[X]` from `typing`

---

## Strict mode and coercion

v2 splits validation into "lax" (default, coerces "1" → 1) and "strict" (rejects mismatched types). Opt into strict at the field, model, or call site:

```python
from pydantic import BaseModel, Field

class StrictUser(BaseModel):
    model_config = ConfigDict(strict=True)
    id: int
    name: str

# Or per-field:
class Mixed(BaseModel):
    id: int = Field(strict=True)
    name: str                          # still lax — accepts coercion
```

For incoming JSON from untrusted sources, prefer `strict=True` at the model level — it catches type confusion bugs that v1 silently coerced through.

---

## TypeAdapter replaces parse_obj_as

```python
# ❌ Bad: v1
from pydantic import parse_obj_as
users = parse_obj_as(list[User], raw_data)

# ✅ Good: v2 TypeAdapter
from pydantic import TypeAdapter
users = TypeAdapter(list[User]).validate_python(raw_data)
```

`TypeAdapter` is reusable — instantiate once at module level and reuse across calls for non-trivial speedups.

---

## Common pitfalls

❌ Mixing v1 and v2 validators on the same model class. v2 will accept `@validator` (with a deprecation warning) but the `values` semantics are subtly different.

❌ Importing `BaseSettings` from `pydantic` in v2 — silently works as a class shim in some intermediate versions, then breaks.

❌ Leaving `class Config` alongside `model_config`. v2 prefers `model_config`; mixing causes confusing override behavior.

✅ Run `bump-pydantic` (Pydantic's own codemod) for mechanical renames — it handles 80% of a v1 codebase. Hand-review validators and Config classes.

✅ Enable `PydanticDeprecatedSince20` warnings as errors in tests during the migration window:

```python
# conftest.py
import warnings
from pydantic import PydanticDeprecatedSince20
warnings.filterwarnings("error", category=PydanticDeprecatedSince20)
```

---

## Related rules

- [Data Handling](data-handling.md) — Pandas + Pydantic patterns
- [FastAPI + Pydantic v2](../web/fastapi-pydantic-v2.md) — FastAPI is v2-native; see web/ rules
- [Type Annotations Everywhere](../language/type-annotations-everywhere.md) — Pydantic models lean on annotations

---

## References

- [Pydantic v2 Migration Guide](https://pydantic.dev/docs/validation/latest/get-started/migration/) — canonical migration doc
- [Pydantic v2 docs](https://pydantic.dev/docs/validation/latest/get-started/) — v2.13.x current
- [pydantic-settings](https://docs.pydantic.dev/latest/concepts/pydantic_settings/) — separated settings package
- [bump-pydantic codemod](https://github.com/pydantic/bump-pydantic) — automated v1→v2 rewrite

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
