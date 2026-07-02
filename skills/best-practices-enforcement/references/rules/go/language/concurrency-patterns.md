# Concurrency Patterns

Use goroutines and channels effectively. Manage goroutine lifecycles, prevent leaks, and coordinate work properly.

---

## Use Worker Pools to Limit Concurrency

**Use worker pools to control the number of concurrent goroutines:**

```go
// ✅ Good: Worker pool pattern
func ProcessJobs(jobs []Job, numWorkers int) []Result {
    jobsChan := make(chan Job, len(jobs))
    resultsChan := make(chan Result, len(jobs))
    
    // Start workers
    var wg sync.WaitGroup
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for job := range jobsChan {
                result := processJob(job)
                resultsChan <- result
            }
        }()
    }
    
    // Send jobs
    go func() {
        defer close(jobsChan)
        for _, job := range jobs {
            jobsChan <- job
        }
    }()
    
    // Collect results
    go func() {
        wg.Wait()
        close(resultsChan)
    }()
    
    // Gather results
    var results []Result
    for result := range resultsChan {
        results = append(results, result)
    }
    
    return results
}

// ❌ Bad: Unbounded goroutines
func ProcessJobs(jobs []Job) []Result {
    var results []Result
    for _, job := range jobs {
        go func(j Job) {
            results = append(results, processJob(j))  // Race condition!
        }(job)
    }
    // No synchronization, race conditions!
    return results
}
```

---

## Use errgroup for Coordinated Tasks

**Use `errgroup` when tasks are related and should fail together:**

```go
// ✅ Good: errgroup for coordinated tasks
import "golang.org/x/sync/errgroup"

func FetchUserData(ctx context.Context, userID int) (*UserData, error) {
    g, ctx := errgroup.WithContext(ctx)
    
    var profile *Profile
    var settings *Settings
    
    g.Go(func() error {
        var err error
        profile, err = fetchProfile(ctx, userID)
        return err
    })
    
    g.Go(func() error {
        var err error
        settings, err = fetchSettings(ctx, userID)
        return err
    })
    
    if err := g.Wait(); err != nil {
        return nil, err  // First error cancels others
    }
    
    return &UserData{Profile: profile, Settings: settings}, nil
}

// ❌ Bad: Manual goroutine management
func FetchUserData(ctx context.Context, userID int) (*UserData, error) {
    var profile *Profile
    var settings *Settings
    var profileErr, settingsErr error
    
    go func() {
        profile, profileErr = fetchProfile(ctx, userID)
    }()
    
    go func() {
        settings, settingsErr = fetchSettings(ctx, userID)
    }()
    
    // How to wait? How to handle errors? Complex!
    return &UserData{Profile: profile, Settings: settings}, nil
}
```

---

## Use errgroup.SetLimit for Bounded Concurrency

**Use `SetLimit` to combine errgroup with concurrency limits:**

```go
// ✅ Good: errgroup with concurrency limit
func ProcessManyItems(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(10)  // Max 10 concurrent goroutines
    
    for _, item := range items {
        item := item  // Capture loop variable
        g.Go(func() error {
            return processItem(ctx, item)
        })
    }
    
    return g.Wait()  // Waits for all, returns first error
}

// ❌ Bad: Unbounded concurrency
func ProcessManyItems(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)
    // No limit - can spawn thousands of goroutines!
    
    for _, item := range items {
        item := item
        g.Go(func() error {
            return processItem(ctx, item)
        })
    }
    
    return g.Wait()
}
```

---

## Close Channels Properly

**Close channels from the sender side, never from receiver:**

```go
// ✅ Good: Sender closes channel
func Producer(items []Item) <-chan Item {
    ch := make(chan Item)
    go func() {
        defer close(ch)  // Sender closes
        for _, item := range items {
            ch <- item
        }
    }()
    return ch
}

func Consumer(ch <-chan Item) {
    for item := range ch {
        process(item)
    }
    // Channel closed, loop exits
}

// ❌ Bad: Receiver closing channel
func Producer(items []Item) <-chan Item {
    ch := make(chan Item)
    go func() {
        for _, item := range items {
            ch <- item
        }
        // Should close here, not in receiver!
    }()
    return ch
}

func Consumer(ch <-chan Item) {
    for item := range ch {
        process(item)
    }
    close(ch)  // Panic! Only sender should close
}
```

---

## Use Select for Multiplexing

**Use `select` to wait on multiple channels:**

```go
// ✅ Good: Select for multiple channels
func ProcessWithTimeout(ctx context.Context, ch <-chan Item) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case item, ok := <-ch:
            if !ok {
                return nil  // Channel closed
            }
            if err := processItem(ctx, item); err != nil {
                return err
            }
        }
    }
}

// ✅ Good: Select with default for non-blocking
func TryReceive(ch <-chan Item) (*Item, bool) {
    select {
    case item := <-ch:
        return &item, true
    default:
        return nil, false  // Non-blocking
    }
}

// ❌ Bad: Blocking on single channel
func Process(ctx context.Context, ch <-chan Item) error {
    for item := range ch {
        // No way to check ctx.Done()!
        if err := processItem(ctx, item); err != nil {
            return err
        }
    }
    return nil
}
```

---

## Prevent Goroutine Leaks

**Always provide a way for goroutines to exit:**

```go
// ✅ Good: Context cancellation prevents leaks
func LongRunningTask(ctx context.Context) error {
    ticker := time.NewTicker(1 * time.Second)
    defer ticker.Stop()
    
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()  // Exit on cancellation
        case <-ticker.C:
            doWork()
        }
    }
}

// ✅ Good: Done channel for shutdown
func Worker(jobs <-chan Job, done <-chan struct{}) {
    for {
        select {
        case <-done:
            return  // Exit signal
        case job := <-jobs:
            processJob(job)
        }
    }
}

// ❌ Bad: No way to stop goroutine
func LongRunningTask() {
    for {
        doWork()  // Runs forever, can't be stopped!
        time.Sleep(1 * time.Second)
    }
}
```

---

## Capture Loop Variables Correctly

**Go 1.22+ scopes loop variables per-iteration** ([Go 1.22 release notes](https://go.dev/doc/go1.22#language)) — the classic "all goroutines see the last item" bug is gone for modules whose `go.mod` declares `go 1.22` or later. For older modules, keep the manual `item := item` shadow.

```go
// ✅ Good: Go 1.22+ — loop variable is per-iteration
func ProcessItems(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)

    for _, item := range items {
        g.Go(func() error {
            return processItem(ctx, item)  // safe on Go 1.22+
        })
    }

    return g.Wait()
}

// ✅ Good (still): explicit shadow — required on Go < 1.22, harmless on 1.22+
for _, item := range items {
    item := item
    g.Go(func() error { return processItem(ctx, item) })
}

// ❌ Bad on Go < 1.22: closure captures the iteration variable
for _, item := range items {
    g.Go(func() error {
        return processItem(ctx, item)  // all goroutines may see the last item
    })
}
```

**Check your `go.mod`** — the new semantics only kick in when the module's `go` directive is ≥ `1.22`. A 1.22+ toolchain compiling a `go 1.21` module preserves the old behavior for backward compatibility.

---

## Use sync.WaitGroup for Simple Coordination

**Use `WaitGroup` when you just need to wait for goroutines:**

```go
// ✅ Good: WaitGroup for simple coordination
func ProcessBatch(items []Item) {
    var wg sync.WaitGroup
    
    for _, item := range items {
        wg.Add(1)
        go func(i Item) {
            defer wg.Done()
            processItem(i)
        }(item)
    }
    
    wg.Wait()  // Wait for all goroutines
    fmt.Println("All items processed")
}

// ❌ Bad: Sleep-based coordination
func ProcessBatch(items []Item) {
    for _, item := range items {
        go processItem(item)
    }
    time.Sleep(5 * time.Second)  // How long? Unreliable!
    fmt.Println("All items processed")
}
```

---

## Implement Backpressure for Unbounded Work

**Assume unbounded goroutines will eventually fail under load.** Use `errgroup.SetLimit`, worker pools, or semaphores.

```go
// ✅ Good: Bounded concurrency with errgroup
func ProcessMany(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(100)  // Max 100 concurrent goroutines
    for _, item := range items {
        item := item
        g.Go(func() error { return processItem(ctx, item) })
    }
    return g.Wait()
}
```

**Production tip:** Treat context cancellation as control flow. Propagate context to all outbound calls. Use deadlines as budgets across downstream work.

---

## Related Rules

**Universal Principles:**
- [Generic Performance Principles](../../../../generic/performance/core-principles.md) - Universal performance principles (batching, resource management)

**Go-Specific:**
- [Context Patterns](context-patterns.md) - Using context with concurrency
- [Mutex and Locking](mutex-and-locking.md) - sync.Mutex, RWMutex, when to use channels vs mutex
- [Idiomatic Error Handling](idiomatic-error-handling.md) - Error handling in concurrent code

---

## References

- [Go Blog: Pipelines](https://go.dev/blog/pipelines)
- [Go Blog: Advanced Go Concurrency Patterns](https://go.dev/blog/advanced-go-concurrency-patterns)
- [Package sync](https://pkg.go.dev/sync)
- [golang.org/x/sync/errgroup](https://pkg.go.dev/golang.org/x/sync/errgroup)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
