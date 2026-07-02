# Structured Logging with structlog

For new Python services, default to [structlog](https://www.structlog.org/en/stable/) (v25.x). It produces key-value structured output, integrates cleanly with stdlib `logging`, and supports `contextvars`-based per-request binding that works correctly in async code. The output is JSON-by-default in production, human-readable in development.

Source: [structlog docs](https://www.structlog.org/en/stable/).

---

## Why not stdlib logging alone?

Stdlib `logging` is fine for human-readable lines. It is painful for:

- Key-value structured output (you end up f-stringing JSON by hand)
- Per-request context (manual `LoggerAdapter` per call site)
- Async correlation (logger state leaks across tasks)
- Test assertions (parsing formatted strings)

structlog solves all four. It can either replace stdlib entirely or wrap it (so existing `logging.getLogger(__name__)` calls still flow through structlog's processors).

---

## Minimum production config

```python
# ✅ Good: structlog wired for JSON in prod, console in dev
import logging
import sys
import structlog

def configure_logging(env: str = "prod", level: str = "INFO") -> None:
    timestamper = structlog.processors.TimeStamper(fmt="iso", utc=True)

    shared_processors = [
        structlog.contextvars.merge_contextvars,    # per-request bound vars
        structlog.processors.add_log_level,
        timestamper,
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ]

    if env == "prod":
        renderer = structlog.processors.JSONRenderer()
    else:
        renderer = structlog.dev.ConsoleRenderer(colors=sys.stderr.isatty())

    structlog.configure(
        processors=shared_processors + [renderer],
        wrapper_class=structlog.make_filtering_bound_logger(
            getattr(logging, level.upper())
        ),
        logger_factory=structlog.PrintLoggerFactory(),
        cache_logger_on_first_use=True,
    )

configure_logging(env="prod", level="INFO")
log = structlog.get_logger()
log.info("service_started", port=8000, version="1.2.3")
# {"event":"service_started","port":8000,"version":"1.2.3","level":"info","timestamp":"2026-05-27T..."}
```

Key choices:

- **`JSONRenderer` in prod, `ConsoleRenderer` in dev** — same processor chain, different last step.
- **`merge_contextvars` first** — surfaces request-bound context on every line.
- **UTC timestamps in ISO format** — Loki/Grafana parse natively.
- **`cache_logger_on_first_use=True`** — fast; safe because config is process-global.

---

## Per-request context binding (the killer feature)

Use `contextvars` so bound values flow into every log line within a request, including from libraries you don't control — and are async-task-safe.

```python
# ✅ Good: bind once per request, every downstream log line gets it
import uuid
import structlog
from fastapi import FastAPI, Request

log = structlog.get_logger()
app = FastAPI()

@app.middleware("http")
async def bind_request_context(request: Request, call_next):
    structlog.contextvars.clear_contextvars()
    structlog.contextvars.bind_contextvars(
        request_id=request.headers.get("x-request-id", str(uuid.uuid4())),
        method=request.method,
        path=request.url.path,
    )
    response = await call_next(request)
    log.info("request_completed", status_code=response.status_code)
    return response

# In any downstream code — no need to thread the logger:
async def some_handler():
    log.info("processing")
    # Output includes request_id, method, path automatically.
```

❌ Don't use `log.bind(request_id=...)` returning a new logger and threading it everywhere — that's tedious and breaks when third-party code logs.

✅ `bind_contextvars` makes the context process-wide-but-task-local, which is what you actually want under asyncio.

---

## Event naming — snake_case, verb_object

Log "events," not sentences. The first positional arg becomes the `event` key — make it greppable.

```python
# ✅ Good: short, machine-parseable event names; structured fields
log.info("user_created", user_id=user.id, email=user.email)
log.warning("rate_limit_hit", user_id=user.id, limit=100, window_s=60)
log.error("db_query_failed", query="select_user", duration_ms=2300, exc_info=True)

# ❌ Bad: human-formatted strings — defeats structured logging
log.info(f"Created user {user.id} with email {user.email}")
log.warning(f"User {user.id} hit rate limit (100/min)")
```

`event=user_created` + `user_id=...` is a Loki/ES query in 5 seconds. The f-string version requires a regex.

---

## Wrap stdlib loggers (interop)

To avoid silencing library logs that use `logging.getLogger(...)`, route them through structlog's processor chain:

```python
# ✅ Good: stdlib logging flows through structlog processors
import logging
import structlog

structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.JSONRenderer(),
    ],
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
)

# Configure stdlib root logger to delegate to structlog's processor chain
logging.basicConfig(format="%(message)s", level=logging.INFO)
```

Now `logging.getLogger("sqlalchemy.engine").info(...)` produces JSON with timestamp/level/logger fields — the same shape as your direct `structlog` calls.

---

## Exceptions

```python
# ✅ Good: structlog renders the traceback as a structured field
try:
    do_thing()
except Exception:
    log.exception("do_thing_failed", thing_id=42)
# {"event":"do_thing_failed","thing_id":42,"exception":"Traceback (most recent..."}

# ✅ Good: explicit exc_info for non-current exceptions
log.error("download_failed", url=url, exc_info=err)
```

`log.exception(...)` is the equivalent of stdlib — it auto-captures `sys.exc_info()`. The processor chain serializes the traceback (one line in prod JSON, formatted in console).

---

## What NOT to log

- Secrets (passwords, tokens, API keys, full credit-card numbers). Add a redaction processor or — better — never pass them to the logger.
- Full HTTP request bodies on large endpoints — log size + a hash, not the payload.
- DEBUG-level lines in production hot paths. The cost is real even when filtered (string formatting still runs unless you use lazy `%s` or structlog's filtering wrapper).
- One log per item in a loop over 100k items. Log a summary; sample if you need a trace.

---

## Common pitfalls

❌ Calling `structlog.configure()` from library code. Only the application entry point should configure. Libraries call `structlog.get_logger(__name__)`.

❌ Using `log.bind(...)` (returns a new logger) and forgetting to pass it down — context vanishes. Use `bind_contextvars` instead.

❌ Mixing f-strings into the event name (`log.info(f"created {x}")`). The event name is the index key; keep it static.

❌ Forgetting `clear_contextvars()` at the start of each request — stale binds from a previous request leak into the next when the same worker thread/task is reused.

✅ For Grafana/Loki: keep your event names as low-cardinality labels and put per-event details (IDs, durations) as fields — not labels. Loki's index is label-based.

---

## Related rules

- [Python Production Patterns](../meta/python-production-patterns.md) — production setup
- [FastAPI + Pydantic v2](../web/fastapi-pydantic-v2.md) — middleware example for request binding
- [Async Patterns](../language/async-patterns.md) — `contextvars` is what makes async-safe binding work

---

## References

- [structlog documentation](https://www.structlog.org/en/stable/) — v25.x current
- [structlog: contextvars](https://www.structlog.org/en/stable/contextvars.html) — async-safe binding
- [structlog: standard library integration](https://www.structlog.org/en/stable/standard-library.html)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
