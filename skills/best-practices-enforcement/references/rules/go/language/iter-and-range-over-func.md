# `iter` and range-over-func (Go 1.23+)

Go 1.23 introduced the `iter` package and `range`-over-function support. This
unlocks composable iteration without allocating a slice, and it's how the new
stdlib `slices`/`maps` iterator helpers (`slices.All`, `maps.Keys`, etc.) are
shaped.

Source: [Go 1.23 release notes](https://go.dev/doc/go1.23) ·
[`iter` package](https://pkg.go.dev/iter).

---

## When to return `iter.Seq` instead of `[]T`

Use an iterator when **any** of these is true:

- The caller may stop early (early-return, found-match, error abort).
- The sequence may be large or unbounded (DB cursor, file scan, paginated API).
- Producing each element is expensive and you want laziness.

Otherwise — small, fully-consumed sequences — return a slice. Slices are
cheaper to consume and easier to test.

```go
// ✅ Good: iterator for a large/streamed source
func (r *Repo) AllUsers(ctx context.Context) iter.Seq2[*User, error] {
    return func(yield func(*User, error) bool) {
        rows, err := r.db.QueryContext(ctx, "SELECT id, name FROM users")
        if err != nil {
            yield(nil, err)
            return
        }
        defer rows.Close()
        for rows.Next() {
            var u User
            if err := rows.Scan(&u.ID, &u.Name); err != nil {
                if !yield(nil, err) {
                    return
                }
                continue
            }
            if !yield(&u, nil) {
                return // caller broke out — stop scanning
            }
        }
    }
}

// caller
for u, err := range repo.AllUsers(ctx) {
    if err != nil { return err }
    if u.ID == target { return u, nil } // early exit closes the rows
}
```

```go
// ❌ Bad: materializing into a slice when the caller stops at the first hit
func (r *Repo) AllUsers(ctx context.Context) ([]*User, error) {
    // builds a 10k-row slice the caller will scan once and discard
}
```

---

## `iter.Seq` vs `iter.Seq2`

- `iter.Seq[T]` — single value per step. Use for "just data" streams.
- `iter.Seq2[K, V]` — pair per step. Use for `(value, error)`, `(index, value)`,
  `(key, value)`.

The `(value, error)` shape is the idiomatic way to surface per-element errors
from a stream — better than a shared `err` field on the iterator struct.

```go
// ✅ Good: error rides alongside each element
func Lines(r io.Reader) iter.Seq2[string, error] { ... }

// ❌ Bad: stateful iterator with a separate Err() method
//        (mirrors bufio.Scanner — fine for stdlib, but harder to compose)
```

---

## Always respect the `yield` return value

`yield` returns `false` when the caller has stopped iterating (`break`,
`return`, `panic`). Your iterator function **must** stop pushing values and
clean up — closing rows, files, channels.

```go
// ✅ Good: stop on yield == false; clean up via defer
func scan(rd io.Reader) iter.Seq[string] {
    return func(yield func(string) bool) {
        sc := bufio.NewScanner(rd)
        for sc.Scan() {
            if !yield(sc.Text()) {
                return
            }
        }
    }
}

// ❌ Bad: ignore the return — leaks effort, possibly resources
return func(yield func(string) bool) {
    for sc.Scan() {
        yield(sc.Text()) // keeps scanning even after caller breaks
    }
}
```

---

## Push vs pull: `iter.Pull` when you need to advance manually

`range`-over-func is *push-style*: the producer drives. When you need
*pull-style* (merge two streams, peek ahead, interleave), use `iter.Pull` /
`iter.Pull2`.

```go
// ✅ Good: merging two sorted streams needs pull
next1, stop1 := iter.Pull(streamA)
defer stop1()
next2, stop2 := iter.Pull(streamB)
defer stop2()

a, okA := next1()
b, okB := next2()
for okA && okB {
    if a <= b { emit(a); a, okA = next1() } else { emit(b); b, okB = next2() }
}
```

**Always `defer stop()`** — it tells the producer to clean up if you stop early.

---

## Use the stdlib `slices` / `maps` iterator helpers

Go 1.23 added iterator versions of the common helpers. Prefer them over hand-written loops.

```go
// ✅ Good
for v := range slices.Values(s)      { ... }
for i, v := range slices.All(s)      { ... }
for k := range maps.Keys(m)          { ... }
for k, v := range maps.All(m)        { ... }

// Collect an iterator into a slice/map:
out := slices.Collect(it)
mp  := maps.Collect(it2)
```

---

## Don't ship iterators across goroutine boundaries

An `iter.Seq` is conceptually a coroutine — the producer runs on the caller's
goroutine each time `yield` is invoked. Sending one over a channel or capturing
one in another goroutine is almost always wrong; use a channel for that pattern
instead.

---

## Related rules

- [Concurrency Patterns](concurrency-patterns.md) — for cross-goroutine streams, use channels, not iterators.
- [Context Patterns](context-patterns.md) — iterators backed by I/O should accept `ctx` from the caller.

---

## References

- [Go 1.23 release notes](https://go.dev/doc/go1.23)
- [Package `iter`](https://pkg.go.dev/iter)
- [Package `slices` — iterator helpers](https://pkg.go.dev/slices)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
