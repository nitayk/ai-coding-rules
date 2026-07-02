# `testing/synctest` for time-dependent tests

Go 1.24 added the experimental `testing/synctest` package: a fake clock and a
"bubble" of goroutines whose scheduling the test can wait on deterministically.
It replaces the flaky `time.Sleep(50 * time.Millisecond)` pattern with
something the test framework actually controls.

Source: [Go 1.24 release notes](https://go.dev/doc/go1.24).

---

## When to reach for `synctest`

Use it when the code under test does any of:

- waits on `time.After` / `time.NewTimer` / `time.Tick`
- has retry backoff
- has `context.WithTimeout` / `WithDeadline`
- coordinates multiple goroutines via channels and you need to assert what
  happens "after they've all blocked"

Don't use it for tests that have nothing to do with time — it's not free,
and a regular `_test.go` is simpler.

> **Heads-up:** `testing/synctest` is **experimental** in 1.24 — gate it with
> the `GOEXPERIMENT=synctest` env var or check the release notes for your Go
> version. The API may shift before it stabilizes.

---

## Replace `time.Sleep` polling

```go
// ✅ Good: synctest controls time
func TestRetry(t *testing.T) {
    synctest.Run(func() {
        client := newClient()
        var got error
        done := make(chan struct{})
        go func() {
            got = client.CallWithRetry(ctx) // retries with backoff internally
            close(done)
        }()

        synctest.Wait()                  // wait until all goroutines block
        time.Sleep(5 * time.Second)      // virtual time — instant
        synctest.Wait()
        <-done
        if got != nil { t.Fatalf("CallWithRetry: %v", got) }
    })
}

// ❌ Bad: real sleep, real flakiness
func TestRetry(t *testing.T) {
    go func() { client.CallWithRetry(ctx) }()
    time.Sleep(6 * time.Second)          // hope this is enough
    // ... assertions race the goroutine
}
```

Inside `synctest.Run`, `time.Sleep`, `time.NewTimer`, `time.After`, and
`context.WithTimeout` all run on the fake clock. A 5-second sleep returns
immediately as far as wall-clock is concerned; from the code's perspective,
five seconds passed.

---

## `synctest.Wait()` is the synchronization primitive

`Wait` blocks until **every goroutine in the bubble is durably blocked** — on
a channel send/recv, mutex, or the fake clock. That's the moment you know
"nothing else is going to happen until time advances or input arrives", and
that's when assertions are safe.

```go
// ✅ Good: assert after the system has quiesced
synctest.Wait()
if got := metrics.RetryCount.Load(); got != 3 {
    t.Fatalf("retries: got %d want 3", got)
}
```

Calling `Wait` while the system is *still actively progressing* will deadlock
the test — `synctest` raises a clear panic when that happens, which is the
diagnostic you want.

---

## One bubble per test, not per goroutine

`synctest.Run(fn)` creates the bubble. Everything spawned by `fn`
(transitively) is in it. Don't try to nest bubbles or share goroutines across
bubbles — that's outside the API contract.

```go
// ✅ Good
func TestX(t *testing.T) {
    synctest.Run(func() {
        // spawn helpers here — all in the same bubble
    })
}

// ❌ Bad: external goroutine isn't bubbled
go realClock()
synctest.Run(func() {
    // realClock can't be coordinated from here
})
```

---

## What `synctest` does NOT mock

- **Real I/O** — files, sockets, syscalls still run on wall time. Combine with
  `httptest` for HTTP-level mocking, or hide I/O behind an interface (see
  [Mocking and Integration](mocking-and-integration.md)).
- **`runtime.Gosched` / `time.Now()` outside the bubble** — only code launched
  inside `synctest.Run` sees the fake clock.
- **Pre-1.24 behavior** — older Go releases don't have it. For repos that
  still need to compile on 1.23, gate the test file with a build constraint
  (`//go:build go1.24`).

---

## Pair with `t.Context()` (Go 1.24)

Go 1.24 also added `t.Context()`, which cancels when the test ends. Combine
the two so a fake-clock timeout still wires through proper cancellation.

```go
func TestDeadline(t *testing.T) {
    synctest.Run(func() {
        ctx, cancel := context.WithTimeout(t.Context(), 2*time.Second)
        defer cancel()
        // ...code under test uses ctx...
    })
}
```

---

## Related rules

- [Mocking and Integration](mocking-and-integration.md) — interfaces for time/I/O when `synctest` isn't enough.
- [Table-Driven Tests](table-driven-tests.md) — structure remains the same; `synctest.Run` wraps the case body.
- [Concurrency Patterns](../language/concurrency-patterns.md) — what the code under test should look like.

---

## References

- [Go 1.24 release notes](https://go.dev/doc/go1.24)
- [Package `testing/synctest`](https://pkg.go.dev/testing/synctest)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
