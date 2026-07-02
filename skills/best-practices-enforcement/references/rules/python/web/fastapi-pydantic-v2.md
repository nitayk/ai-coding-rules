# FastAPI with Pydantic v2

FastAPI is Pydantic v2-native (and has been since FastAPI 0.100+). The current canonical patterns differ from older tutorials in three ways: `Annotated[...]` for dependencies, `lifespan` instead of `@app.on_event`, and Pydantic v2 method names throughout. Source: [FastAPI Pydantic v2 migration guide](https://fastapi.tiangolo.com/how-to/migrate-from-pydantic-v1-to-pydantic-v2/).

---

## Use Annotated for Dependencies and Params

`Annotated[T, ...]` is the recommended signature shape — it works correctly with type checkers, avoids the "default value as marker" hack, and lets you alias common deps.

```python
# ❌ Bad: legacy default-value style
from fastapi import FastAPI, Depends, Query

@app.get("/items/")
def list_items(
    q: str | None = Query(None, max_length=50),
    db: Session = Depends(get_db),
):
    ...
```

```python
# ✅ Good: Annotated — type checker sees the real type
from typing import Annotated
from fastapi import FastAPI, Depends, Query

@app.get("/items/")
def list_items(
    q: Annotated[str | None, Query(max_length=50)] = None,
    db: Annotated[Session, Depends(get_db)],
):
    ...

# ✅ Good: alias commonly-used deps once, reuse everywhere
DbSession = Annotated[Session, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]

@app.get("/me")
def me(user: CurrentUser) -> UserOut:
    return UserOut.model_validate(user)
```

The aliased-dep pattern (`DbSession`, `CurrentUser`) is the single biggest readability win in FastAPI 0.110+ codebases. Adopt it.

---

## Lifespan instead of @app.on_event

`@app.on_event("startup")` and `@app.on_event("shutdown")` are deprecated. Use a `lifespan` async context manager:

```python
# ❌ Bad: deprecated event handlers
@app.on_event("startup")
async def startup():
    app.state.db = await create_pool()

@app.on_event("shutdown")
async def shutdown():
    await app.state.db.close()
```

```python
# ✅ Good: lifespan context manager
from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup
    app.state.db = await create_pool()
    yield
    # shutdown
    await app.state.db.close()

app = FastAPI(lifespan=lifespan)
```

`lifespan` is testable (you can call it directly in tests), composable (yield + asyncio.gather multiple resources), and handles exceptions correctly during startup — `on_event` doesn't.

---

## Request and Response Models

Always declare an explicit `response_model` (or annotate the return type — FastAPI uses it for serialization + OpenAPI). Use separate models for input vs output to avoid leaking fields like hashed passwords.

```python
# ✅ Good: separate input/output models, Pydantic v2 syntax
from pydantic import BaseModel, ConfigDict, EmailStr, Field

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=12)
    full_name: str

class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)  # was orm_mode in v1
    id: int
    email: EmailStr
    full_name: str
    # NO password field — never serialize secrets

@app.post("/users", response_model=UserOut, status_code=201)
async def create_user(payload: UserCreate, db: DbSession) -> UserOut:
    user = await users_service.create(db, payload)
    return UserOut.model_validate(user)
```

Notes:

- `from_attributes=True` (v2 name) replaces v1's `orm_mode = True` — enables building the model from an ORM object via attribute access.
- `model_validate(user)` is the v2 equivalent of `UserOut.from_orm(user)`.
- Returning `UserOut` (vs `User`) is what prevents accidental field leaks.

---

## Validation errors are not free

Pydantic v2 raises `ValidationError` with detailed errors; FastAPI returns 422 with a standard body. Customize when you need stable error contracts:

```python
# ✅ Good: shape your own 422 body
from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "error": "validation_failed",
            "details": [
                {"field": ".".join(map(str, e["loc"])), "msg": e["msg"]}
                for e in exc.errors()
            ],
        },
    )
```

---

## Async vs sync route handlers

| Handler body | Declare as |
|---|---|
| Calls `await` on any I/O (asyncpg, httpx, aioredis) | `async def` |
| Calls blocking I/O (psycopg2, requests, sync ORM) | **`def`** — FastAPI runs it in a thread pool |
| Pure CPU work | `def` (so the event loop is not blocked) |

❌ Don't write `async def` and then call `requests.get(...)` — you've blocked the event loop. Either switch to `httpx.AsyncClient` or make the handler `def`.

```python
# ❌ Bad: async def with blocking call — kills the event loop
@app.get("/proxy")
async def proxy(url: str):
    return requests.get(url).json()

# ✅ Good: native async I/O
@app.get("/proxy")
async def proxy(url: str, client: Annotated[httpx.AsyncClient, Depends(get_client)]):
    resp = await client.get(url)
    return resp.json()
```

---

## Settings via pydantic-settings

In v2, `BaseSettings` lives in the **separate `pydantic-settings`** package:

```python
# ✅ Good: pydantic-settings + dependency injection
from functools import lru_cache
from typing import Annotated
from fastapi import Depends
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    db_url: str
    log_level: str = "INFO"

@lru_cache
def get_settings() -> Settings:
    return Settings()

SettingsDep = Annotated[Settings, Depends(get_settings)]

@app.get("/health")
def health(settings: SettingsDep) -> dict:
    return {"log_level": settings.log_level}
```

`@lru_cache` on the factory makes `Settings()` a singleton per process, so env parsing happens once.

---

## Common pitfalls

❌ Using `Depends(get_db)` as a default value in 2025+ code. Use `Annotated[Session, Depends(get_db)]` instead.

❌ `@app.on_event("startup")` in new code — deprecated since 0.93, replaced by `lifespan`.

❌ Returning a SQLAlchemy model directly from a route without a `response_model` — leaks every column, including secrets.

❌ Forgetting `from_attributes=True` on response models that wrap ORM objects — you'll get attribute-access errors.

✅ Run `mypy` or `pyright` on FastAPI code — `Annotated` deps + Pydantic v2 give type checkers enough information to catch most route-signature bugs at lint time.

---

## Related rules

- [Pydantic v2 Migration](../data/pydantic-v2-migration.md) — covers the v1→v2 model API shift
- [Type Annotations Everywhere](../language/type-annotations-everywhere.md) — Annotated[] is a typing concept
- [Async Patterns](../language/async-patterns.md) — async/await fundamentals
- [Structured Logging (structlog)](../observability/structured-logging-structlog.md) — pair with FastAPI request middleware

---

## References

- [FastAPI documentation](https://fastapi.tiangolo.com/) — official
- [FastAPI: Migrate from Pydantic v1 to v2](https://fastapi.tiangolo.com/how-to/migrate-from-pydantic-v1-to-pydantic-v2/)
- [FastAPI: Lifespan Events](https://fastapi.tiangolo.com/advanced/events/)
- [FastAPI: Dependencies with Annotated](https://fastapi.tiangolo.com/tutorial/dependencies/)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
