# Context Patterns

Use `context.Context` for cancellation, deadlines, and request-scoped values. Always pass context as the first parameter.

---

## Pass Context as First Parameter

**Always accept `context.Context` as the first parameter:**

```go
// ✅ Good: Context as first parameter
func ProcessRequest(ctx context.Context, req *Request) error {
    // ...
}

func FetchUser(ctx context.Context, userID int) (*User, error) {
    // ...
}

// ❌ Bad: Context not first parameter
func ProcessRequest(req *Request, ctx context.Context) error {
    // ...
}

// ❌ Bad: No context parameter
func ProcessRequest(req *Request) error {
    // No way to cancel or timeout!
}
```

---

## Always Call Cancel Function

**Always call `cancel()` when deriving a cancellable context:**

```go
// ✅ Good: Defer cancel
func ProcessWithTimeout(ctx context.Context, timeout time.Duration) error {
    ctx, cancel := context.WithTimeout(ctx, timeout)
    defer cancel()  // Always call cancel!
    
    return doWork(ctx)
}

// ✅ Good: Cancel on early return
func ProcessWithDeadline(ctx context.Context, deadline time.Time) error {
    ctx, cancel := context.WithDeadline(ctx, deadline)
    defer cancel()
    
    if err := validate(ctx); err != nil {
        return err  // cancel() still called via defer
    }
    
    return doWork(ctx)
}

// ❌ Bad: Forgetting to call cancel
func ProcessWithTimeout(ctx context.Context, timeout time.Duration) error {
    ctx, cancel := context.WithTimeout(ctx, timeout)
    // Missing defer cancel() - leaks resources!
    return doWork(ctx)
}
```

---

## Use Timeouts for External Calls

**Set timeouts for operations that call external services:**

```go
// ✅ Good: Timeout for external call
func FetchFromAPI(ctx context.Context, url string) (*Response, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }
    
    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    return parseResponse(resp.Body)
}

// ❌ Bad: No timeout - can hang indefinitely
func FetchFromAPI(ctx context.Context, url string) (*Response, error) {
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }
    
    resp, err := http.DefaultClient.Do(req)  // No timeout!
    // ...
}
```

---

## Check Cancellation in Long-Running Tasks

**Check `ctx.Done()` in loops and long-running operations:**

```go
// ✅ Good: Check cancellation in loop
func ProcessItems(ctx context.Context, items []Item) error {
    for _, item := range items {
        // Check if context is cancelled
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
        }
        
        if err := processItem(ctx, item); err != nil {
            return err
        }
    }
    return nil
}

// ✅ Good: Using select for cancellation
func LongRunningTask(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()  // Respect cancellation
        case result := <-workChannel:
            process(result)
        }
    }
}

// ❌ Bad: Ignoring cancellation
func ProcessItems(ctx context.Context, items []Item) error {
    for _, item := range items {
        processItem(ctx, item)  // Never checks ctx.Done()!
    }
    return nil
}
```

---

## Propagate Context Through Layers

**Pass context through all layers of your application:**

```go
// ✅ Good: Context propagated through layers
func HTTPHandler(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()  // Get context from request
    
    user, err := userService.GetUser(ctx, userID)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    
    // Context passed to service layer
}

func (s *UserService) GetUser(ctx context.Context, id int) (*User, error) {
    // Context passed to repository layer
    return s.repo.FindByID(ctx, id)
}

func (r *UserRepository) FindByID(ctx context.Context, id int) (*User, error) {
    // Context used for database query
    return r.db.QueryContext(ctx, "SELECT * FROM users WHERE id = ?", id)
}

// ❌ Bad: Context not propagated
func HTTPHandler(w http.ResponseWriter, r *http.Request) {
    user, err := userService.GetUser(userID)  // No context!
    // ...
}

func (s *UserService) GetUser(id int) (*User, error) {
    return s.repo.FindByID(id)  // Context lost!
}
```

---

## Use Background or TODO for Root Contexts

**Use `context.Background()` or `context.TODO()` for root contexts:**

```go
// ✅ Good: Background for main/init
func main() {
    ctx := context.Background()
    
    // Derive contexts from background
    ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
    defer cancel()
    
    runApplication(ctx)
}

// ✅ Good: TODO when context is needed but not yet available
func NewService() *Service {
    // TODO: Replace with actual context when available
    ctx := context.TODO()
    return &Service{ctx: ctx}
}

// ❌ Bad: Passing nil context
func ProcessRequest(ctx context.Context, req *Request) error {
    if ctx == nil {
        ctx = context.Background()  // Should use TODO if unsure
    }
    // ...
}
```

---

## Distinguish Cancellation Types

**Check `ctx.Err()` to distinguish cancellation reasons:**

```go
// ✅ Good: Handle different cancellation types
func ProcessWithTimeout(ctx context.Context) error {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    
    err := doWork(ctx)
    if err != nil {
        if errors.Is(err, context.DeadlineExceeded) {
            logger.Warn("Operation timed out")
            return fmt.Errorf("operation exceeded deadline: %w", err)
        }
        if errors.Is(err, context.Canceled) {
            logger.Info("Operation was cancelled")
            return fmt.Errorf("operation cancelled: %w", err)
        }
        return err
    }
    
    return nil
}

// ❌ Bad: Treating all cancellations the same
func ProcessWithTimeout(ctx context.Context) error {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    
    err := doWork(ctx)
    if err != nil {
        return err  // Doesn't distinguish timeout vs cancellation
    }
    return nil
}
```

---

## Avoid Storing Context in Structs

**Don't store context in struct fields - pass it explicitly:**

```go
// ✅ Good: Context passed as parameter
type Service struct {
    repo *Repository
}

func (s *Service) Process(ctx context.Context, data Data) error {
    return s.repo.Save(ctx, data)
}

// ❌ Bad: Context stored in struct
type Service struct {
    ctx  context.Context  // Don't store context!
    repo *Repository
}

func (s *Service) Process(data Data) error {
    return s.repo.Save(s.ctx, data)  // Context may be cancelled/stale
}
```

---

## Detach Context Without Cancellation (Go 1.21+)

**Use `context.WithoutCancel` when you need values from a parent context but want the child to outlive cancellation** — e.g. background cleanup, audit log writes, telemetry flush after a request completes.

```go
// ✅ Good: keep request-scoped values, drop cancellation
func handle(ctx context.Context, req *Request) error {
    if err := process(ctx, req); err != nil {
        return err
    }
    // Fire-and-forget audit write that must NOT be cancelled
    // when the request's ctx is done. Keep trace_id / request_id.
    go writeAudit(context.WithoutCancel(ctx), req)
    return nil
}

// ❌ Bad: detaching by passing Background drops trace_id, tenant, etc.
go writeAudit(context.Background(), req)
```

---

## Schedule Cleanup with context.AfterFunc (Go 1.21+)

**Use `context.AfterFunc` to register a callback that runs when the context is cancelled.** Avoids spinning a goroutine just to wait on `<-ctx.Done()`.

```go
// ✅ Good: cancellation-driven cleanup without a watcher goroutine
func openSession(ctx context.Context) *Session {
    s := newSession()
    stop := context.AfterFunc(ctx, func() {
        s.close() // runs on cancellation
    })
    s.cancel = stop // call stop() if you close the session early to avoid the AfterFunc firing
    return s
}

// ❌ Bad: dedicated goroutine to watch ctx.Done
func openSession(ctx context.Context) *Session {
    s := newSession()
    go func() {
        <-ctx.Done()
        s.close()
    }()
    return s
}
```

The returned `stop` function unregisters the callback — call it when you complete cleanup another way, so it doesn't double-run.

---

## Use context.Value Sparingly

**Only use `context.Value` for request-scoped metadata, not business data:**

```go
// ✅ Good: Request-scoped metadata
type contextKey string

const requestIDKey contextKey = "request_id"

func WithRequestID(ctx context.Context, id string) context.Context {
    return context.WithValue(ctx, requestIDKey, id)
}

func GetRequestID(ctx context.Context) string {
    id, _ := ctx.Value(requestIDKey).(string)
    return id
}

// Usage
func HTTPHandler(w http.ResponseWriter, r *http.Request) {
    ctx := WithRequestID(r.Context(), generateID())
    processRequest(ctx)
}

// ❌ Bad: Using context for business data
func WithUser(ctx context.Context, user *User) context.Context {
    return context.WithValue(ctx, "user", user)  // Too large, not request-scoped
}

func ProcessOrder(ctx context.Context, orderID int) error {
    user := ctx.Value("user").(*User)  // Should be parameter!
    // ...
}
```

---

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../../../generic/code-quality/core-principles.md) - Universal principles (separation of concerns, explicit error handling)

**Go-Specific:**
- [Idiomatic Error Handling](idiomatic-error-handling.md) - Error handling patterns
- [Concurrency Patterns](concurrency-patterns.md) - Using context with goroutines

---

## References

- [Go Blog: Context](https://go.dev/blog/context)
- [Package context](https://pkg.go.dev/context) — see `WithoutCancel`, `AfterFunc`, `WithDeadlineCause`, `WithTimeoutCause` (Go 1.21+)
- [Go 1.21 release notes](https://go.dev/doc/go1.21)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
