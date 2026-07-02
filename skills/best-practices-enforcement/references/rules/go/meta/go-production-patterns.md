# Go Production Patterns

Patterns for production-ready Go services. Based on Uber Go Style Guide, Google Go Best Practices, and Peter Bourgon's "Go in Production."

---

## Verify Interface Compliance at Compile Time

**Use a nil pointer assignment to verify a type implements an interface.** Catches interface drift at compile time.

```go
// ✅ Good: Compile-time interface verification
var _ http.Handler = (*MyHandler)(nil)
var _ io.Reader = (*MyReader)(nil)

// If MyHandler doesn't implement http.Handler, compile fails
```

---

## Copy Slices and Maps at API Boundaries

**Avoid unintended mutations across API boundaries.** Copy before returning or accepting.

```go
// ✅ Good: Copy at boundary
func (s *Service) GetItems() []Item {
    s.mu.RLock()
    defer s.mu.RUnlock()
    result := make([]Item, len(s.items))
    copy(result, s.items)
    return result
}

// ❌ Bad: Returning internal slice—caller can mutate
func (s *Service) GetItems() []Item {
    return s.items  // Caller can modify s.items!
}
```

---

## Handle Errors Once

**Don't log and re-wrap the same error multiple times.** Handle at the appropriate layer.

```go
// ✅ Good: Handle once, add context when wrapping
func processFile(path string) error {
    data, err := os.ReadFile(path)
    if err != nil {
        return fmt.Errorf("read %s: %w", path, err)
    }
    return process(data)
}

// ❌ Bad: Log at every layer
func processFile(path string) error {
    data, err := os.ReadFile(path)
    if err != nil {
        log.Printf("read failed: %v", err)  // Don't log here
        return err
    }
    return process(data)
}
```

---

## Don't Fire-and-Forget Goroutines

**Track goroutine lifecycle.** Use context cancellation, errgroup, or explicit shutdown channels.

```go
// ✅ Good: Goroutine with cancellation
func (s *Service) Run(ctx context.Context) error {
    g, ctx := errgroup.WithContext(ctx)
    g.Go(func() error { return s.processLoop(ctx) })
    g.Go(func() error { return s.metricsLoop(ctx) })
    return g.Wait()
}

// ❌ Bad: Fire-and-forget
func (s *Service) Start() {
    go s.processLoop()  // No way to stop, no error propagation
}
```

---

## Treat Context Cancellation as Control Flow

**Propagate context to all outbound calls and spawned goroutines.** Use deadlines as budgets.

```go
// ✅ Good: Context in all calls
func (c *Client) Fetch(ctx context.Context, url string) ([]byte, error) {
    req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
    resp, err := c.http.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    return io.ReadAll(resp.Body)
}
```

---

## Implement Backpressure for Unbounded Work

**Assume unbounded goroutines, queues, or retries will eventually fail.** Use semaphores, bounded channels, or errgroup.SetLimit.

```go
// ✅ Good: Bounded concurrency
func ProcessMany(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(100)  // Max 100 concurrent
    for _, item := range items {
        item := item
        g.Go(func() error { return process(ctx, item) })
    }
    return g.Wait()
}
```

---

## Avoid Mutable Globals and init()

**Prefer explicit setup and dependency injection.** Use `main()` or constructors.

```go
// ✅ Good: Explicit setup
func main() {
    cfg := loadConfig()
    db := connectDB(cfg.DB)
    svc := NewService(db)
    svc.Run()
}

// ❌ Bad: init() and globals
var db *sql.DB
func init() {
    db = connectDB()  // Hard to test, hidden dependencies
}
```

---

## Exit Only from main

**Use `os.Exit` only from `main`.** Libraries should return errors; let the caller decide.

```go
// ✅ Good: main handles exit
func main() {
    if err := run(); err != nil {
        fmt.Fprintf(os.Stderr, "error: %v\n", err)
        os.Exit(1)
    }
}

// ❌ Bad: Library calls os.Exit
func ParseConfig(path string) *Config {
    data, err := os.ReadFile(path)
    if err != nil {
        os.Exit(1)  // Caller can't handle!
    }
    // ...
}
```

---

## Use strconv Over fmt for String Conversion

**`strconv` is faster for numeric ↔ string conversion.**

```go
// ✅ Good: strconv
s := strconv.Itoa(42)
n, err := strconv.Atoi("42")

// ❌ Slower: fmt
s := fmt.Sprintf("%d", 42)
```

---

## Specify Container Capacity When Known

**Preallocate slices and maps to reduce allocations.**

```go
// ✅ Good: Preallocate
items := make([]Item, 0, len(input))
m := make(map[string]int, len(keys))
```

---

## Build Static Binaries for Deployment

**Use `CGO_ENABLED=0` for truly static binaries.** Strip symbols for smaller size.

```bash
CGO_ENABLED=0 go build -ldflags="-s -w" -o app .
```

---

## Default to `log/slog` for Structured Logging

**For new services on Go 1.21+, use stdlib `log/slog`.** One less dependency, one less version to chase, and JSON output composes with every log aggregator. Configure the handler once in `main` and call `slog.SetDefault`.

```go
// ✅ Good: stdlib slog, configured at startup
func main() {
    slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
        Level: slog.LevelInfo,
    })))
    slog.Info("service starting", "port", 8080)
    run()
}

// ❌ Bad: third-party logger by reflex on a new service
import "go.uber.org/zap"
// (use zap when measurement justifies it, not by default)
```

Full guidance: [slog structured logging](../language/slog-structured-logging.md).

---

## Use Environment Variables for Configuration

**Don't hardcode config.** Use `flag`, env vars, or config files.

```go
// ✅ Good: Config from env
port := os.Getenv("PORT")
if port == "" {
    port = "8080"
}
```

---

## Related Rules

**Go-Specific:**
- [Concurrency Patterns](../language/concurrency-patterns.md) - Goroutine management
- [Context Patterns](../language/context-patterns.md) - Context propagation
- [Error Handling](../language/idiomatic-error-handling.md) - Error handling once
- [slog Structured Logging](../language/slog-structured-logging.md) - Stdlib structured logging (Go 1.21+)
- [Project Layout Pragmatism](project-layout-pragmatism.md) - Don't cargo-cult the community template

**Universal:**
- [Generic Architecture Principles](../../../generic/architecture/core-principles.md) - Dependency injection

---

## References

- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)
- [Google Go Style Guide](https://google.github.io/styleguide/go/guide) — normative
- [Google Go Style Decisions](https://google.github.io/styleguide/go/decisions) — most actionable of the three Google docs
- [Google Go Best Practices](https://google.github.io/styleguide/go/best-practices)
- [Structured Logging with slog (Go Blog)](https://go.dev/blog/slog) — Go 1.21+ stdlib structured logging
- [Go 1.24 release notes](https://go.dev/doc/go1.24) — `tool` directive, `testing/synctest`, runtime updates
- [Peter Bourgon: Go in Production](https://peter.bourgon.org/go-in-production/)
- [Go Concurrency in Production](https://compile.guru/go-context-cancellation-deadlines-backpressure/)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
