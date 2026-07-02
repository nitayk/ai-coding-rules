# Structured logging with `log/slog`

Go 1.21 added `log/slog` to the standard library. For new code, prefer it over
third-party loggers (`zap`, `logrus`, `zerolog`) unless you have a measured reason
not to — stdlib means one less dependency, one less version bump to chase, and
handlers compose cleanly with `context.Context`.

Source: [Structured Logging with slog (Go Blog, Aug 2023)](https://go.dev/blog/slog).

---

## Pick a handler and a destination at process startup

Configure the handler **once** in `main` (or a tiny `logging` package called
from `main`). Don't let library code pick the handler — that's the caller's job.

```go
// ✅ Good: configure once, set as default
func main() {
    h := slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
        Level:     slog.LevelInfo,
        AddSource: false, // turn on only when debugging
    })
    slog.SetDefault(slog.New(h))

    slog.Info("service starting", "port", 8080)
    run()
}

// ❌ Bad: library picks the handler
package userrepo

func init() {
    slog.SetDefault(slog.New(slog.NewTextHandler(os.Stdout, nil))) // not your call
}
```

**Handler choice:**
- `slog.NewJSONHandler` — production / log aggregation (Loki, Stackdriver, Datadog).
- `slog.NewTextHandler` — local dev, human-readable.
- Custom handler — only when an aggregator demands a specific schema.

---

## Use typed attributes, not `fmt.Sprintf`

The whole point of `slog` is that fields are queryable. Don't pre-format them
into the message.

```go
// ✅ Good: typed attributes
slog.Info("user fetched",
    "user_id", userID,
    "duration_ms", elapsed.Milliseconds(),
    "cache_hit", hit,
)

// ❌ Bad: fields baked into the message string
slog.Info(fmt.Sprintf("user %d fetched in %dms (cache_hit=%v)", userID, elapsed.Milliseconds(), hit))
```

For hot paths, use `slog.Attr` constructors to avoid the `any` allocation:

```go
slog.LogAttrs(ctx, slog.LevelInfo, "user fetched",
    slog.Int64("user_id", userID),
    slog.Duration("duration", elapsed),
    slog.Bool("cache_hit", hit),
)
```

---

## Bind request-scoped attributes to a child logger

Don't restate `request_id`, `tenant`, `trace_id` on every call site. Derive a
child logger once at the entry point and pass it (or stash it on `context`).

```go
// ✅ Good: scoped child logger
func handle(w http.ResponseWriter, r *http.Request) {
    log := slog.With(
        "request_id", reqID(r),
        "route", r.URL.Path,
    )
    log.Info("request received")
    if err := process(r.Context(), log); err != nil {
        log.Error("process failed", "err", err)
    }
}

// ❌ Bad: copy-paste the same attributes everywhere
slog.Info("request received", "request_id", reqID(r), "route", r.URL.Path)
slog.Info("validated",        "request_id", reqID(r), "route", r.URL.Path)
slog.Info("done",             "request_id", reqID(r), "route", r.URL.Path)
```

---

## Use levels deliberately; default is `Info`

`slog` levels are integers, so you can interpolate between named ones. In
practice, four are enough:

| Level   | Use for |
|---------|---------|
| `Debug` | Loop-internal, off in prod |
| `Info`  | Lifecycle events, request boundaries |
| `Warn`  | Recoverable problem, degraded mode |
| `Error` | Operation failed; needs human attention |

```go
// ✅ Good: switch level via flag/env at startup
lvl := slog.LevelInfo
if os.Getenv("DEBUG") == "1" {
    lvl = slog.LevelDebug
}
slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: lvl})))
```

Avoid `Fatal`/`Panic` style helpers — `slog` deliberately doesn't ship them.
Return the error and let `main` decide (see
[Go Production Patterns: Exit Only from main](../meta/go-production-patterns.md)).

---

## Don't log secrets or PII

`slog` will happily serialize whatever you hand it. Wrap sensitive types in a
`LogValuer` so attributes redact themselves:

```go
type APIKey string

func (k APIKey) LogValue() slog.Value {
    if len(k) < 6 {
        return slog.StringValue("***")
    }
    return slog.StringValue(string(k[:4]) + "…***")
}

// Now safe to log:
slog.Info("calling upstream", "api_key", key) // -> "abcd…***"
```

---

## Migration from third-party loggers

- **`zap` / `zerolog` → `slog`**: API shapes line up closely. Keep the existing
  handler at the edge (an adapter) until callers are migrated; don't try to
  flip every site in one PR.
- **`log` (stdlib) → `slog`**: `slog` does not replace `log.Printf` for tiny
  scripts. For services with > 1 logger call per request, switch.

Do **not** delete the third-party logger from `go.mod` until `grep -r` returns
zero imports — partial migrations create two log streams with different schemas.

---

## Related rules

- [Context Patterns](context-patterns.md) — pass `context.Context` so handlers can pull trace IDs.
- [Go Production Patterns](../meta/go-production-patterns.md) — handle errors once; don't log-and-return.

---

## References

- [Structured Logging with slog (Go Blog)](https://go.dev/blog/slog)
- [Package `log/slog`](https://pkg.go.dev/log/slog)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
