# Go Performance Optimization

Profile first, then optimize based on measurements. Use Go's profiling tools and understand escape analysis.

---

## Profile Before Optimizing

**Always profile to find actual bottlenecks:**

```go
// ✅ Good: Use pprof for profiling
import (
    _ "net/http/pprof"
    "net/http"
)

func main() {
    // Enable pprof endpoints
    go func() {
        log.Println(http.ListenAndServe("localhost:6060", nil))
    }()
    
    // Your application code
    runApplication()
}

// Profile with: go tool pprof http://localhost:6060/debug/pprof/profile
// Or: go tool pprof http://localhost:6060/debug/pprof/heap

// ❌ Bad: Optimizing without profiling
func processData(data []Item) {
    // Optimized this, but it's not the bottleneck!
    for i := range data {
        data[i].Process()
    }
}
```

---

## Preallocate Slice Capacity

**Preallocate slices when size is known:**

```go
// ✅ Good: Preallocate capacity
func processItems(items []Item) []Result {
    results := make([]Result, 0, len(items))  // Preallocate capacity
    for _, item := range items {
        results = append(results, processItem(item))
    }
    return results
}

// ✅ Good: Preallocate with known size
func createBatch(size int) []Item {
    batch := make([]Item, 0, size)  // Capacity known
    // ...
    return batch
}

// ❌ Bad: Growing slice repeatedly
func processItems(items []Item) []Result {
    var results []Result  // Starts with capacity 0
    for _, item := range items {
        results = append(results, processItem(item))  // May reallocate!
    }
    return results
}
```

---

## Understand Escape Analysis

**Check escape analysis to understand allocations:**

```go
// ✅ Good: Check escape analysis
// Run: go build -gcflags="-m -m" main.go

// Stack-allocated (good)
func processLocal() int {
    x := 42  // Stays on stack
    return x
}

// Heap-allocated (understand why)
func returnPointer() *int {
    x := 42
    return &x  // Escapes to heap - necessary
}

// ✅ Good: Return by value when possible
type Point struct {
    X, Y int
}

func createPoint(x, y int) Point {  // Returns value, stays on stack
    return Point{X: x, Y: y}
}

// ❌ Bad: Unnecessary pointer
func createPoint(x, y int) *Point {  // Unnecessary heap allocation
    return &Point{X: x, Y: y}
}
```

---

## Avoid Unnecessary Interface Conversions

**Use concrete types or generics instead of interfaces:**

```go
// ✅ Good: Concrete type (Go 1.18+ generics)
func processItems[T any](items []T, fn func(T) T) []T {
    results := make([]T, 0, len(items))
    for _, item := range items {
        results = append(results, fn(item))
    }
    return results
}

// ✅ Good: Concrete type when type is known
func processUsers(users []User) []ProcessedUser {
    results := make([]ProcessedUser, 0, len(users))
    for _, user := range users {
        results = append(results, processUser(user))
    }
    return results
}

// ❌ Bad: Interface conversion forces heap allocation
func processItems(items []interface{}) []interface{} {
    results := make([]interface{}, 0, len(items))
    for _, item := range items {
        results = append(results, processItem(item))  // Heap allocation
    }
    return results
}
```

---

## Use sync.Pool for High-Frequency Temporary Objects

**Use `sync.Pool` for objects with high allocation churn:**

```go
// ✅ Good: sync.Pool for temporary buffers
var bufferPool = sync.Pool{
    New: func() interface{} {
        return make([]byte, 0, 1024)
    },
}

func processRequest(data []byte) []byte {
    buf := bufferPool.Get().([]byte)
    defer bufferPool.Put(buf)
    
    buf = buf[:0]  // Reset length
    // Use buffer
    buf = append(buf, data...)
    return buf
}

// ❌ Bad: Allocating buffer every time
func processRequest(data []byte) []byte {
    buf := make([]byte, 0, 1024)  // New allocation every call
    buf = append(buf, data...)
    return buf
}
```

---

## Minimize Pointer Usage

**Return values instead of pointers when possible:**

```go
// ✅ Good: Return by value (small structs)
type Config struct {
    Host string
    Port int
}

func getConfig() Config {  // Stays on stack
    return Config{Host: "localhost", Port: 8080}
}

// ✅ Good: Pointer only when needed
func getConfig() *Config {  // Only if Config is large or needs mutation
    return &Config{Host: "localhost", Port: 8080}
}

// ❌ Bad: Unnecessary pointer for small struct
func getConfig() *Config {  // Unnecessary heap allocation
    return &Config{Host: "localhost", Port: 8080}
}
```

---

## Use Benchmarking

**Write benchmarks to measure performance:**

```go
// ✅ Good: Benchmark to measure performance
func BenchmarkProcessItems(b *testing.B) {
    items := make([]Item, 1000)
    for i := range items {
        items[i] = Item{ID: i}
    }
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        processItems(items)
    }
}

// Run: go test -bench=. -benchmem
// Output shows: ns/op, B/op, allocs/op

// ✅ Good: Compare implementations
func BenchmarkProcessItemsOld(b *testing.B) {
    // Old implementation
}

func BenchmarkProcessItemsNew(b *testing.B) {
    // New implementation
}
```

---

## Use Profile-Guided Optimization (PGO)

**Enable PGO for production builds:**

```go
// ✅ Good: Generate profile, then build with PGO
// 1. Run application and collect profile:
//    go tool pprof -proto -output=cpu.pb.gz http://localhost:6060/debug/pprof/profile

// 2. Build with PGO:
//    go build -pgo=cpu.pb.gz

// Or use default.pgo in package directory
// go build will automatically use default.pgo if present

// ❌ Bad: Building without PGO when profile available
// go build  // Missing -pgo flag
```

---

## Avoid Capturing Large Variables in Closures

**Pass variables as arguments instead of capturing:**

```go
// ✅ Good: Pass as argument
func processItems(items []Item) {
    for _, item := range items {
        go func(item Item) {  // Pass as argument
            processItem(item)
        }(item)
    }
}

// ❌ Bad: Capturing loop variable
func processItems(items []Item) {
    for _, item := range items {
        go func() {
            processItem(item)  // Captures item - may use wrong value!
        }()
    }
}
```

---

## Use Appropriate Map Capacity

**Preallocate map capacity when size is known:**

```go
// ✅ Good: Preallocate map capacity
func buildIndex(items []Item) map[string]Item {
    index := make(map[string]Item, len(items))  // Preallocate
    for _, item := range items {
        index[item.ID] = item
    }
    return index
}

// ❌ Bad: Map grows dynamically
func buildIndex(items []Item) map[string]Item {
    index := make(map[string]Item)  // Starts small, grows
    for _, item := range items {
        index[item.ID] = item  // May reallocate multiple times
    }
    return index
}
```

---

## Free runtime wins from recent Go releases

Some allocations and map costs got faster without you doing anything — but only if you upgrade. Track these and bump your toolchain proactively.

- **Go 1.24 (Feb 2025): Swiss Tables map implementation** — significantly faster map operations and lower memory for large maps. Just rebuild on 1.24+ ([Go 1.24 release notes](https://go.dev/doc/go1.24)).
- **Go 1.24: new internal mutex implementation** — lower contention on hot `sync.Mutex` paths.
- **Go 1.24: small-object allocator tuning** — fewer escapes for short-lived structs ([Go Blog: "Allocating on the Stack" Feb 2026](https://go.dev/blog/)).
- **Go 1.25 (Oct 2025): Green Tea Garbage Collector** — incremental GC redesign aimed at lower tail latency; opt-in initially, default later ([Go Blog: "Green Tea Garbage Collector"](https://go.dev/blog/)).

**Workflow tip:** before chasing a hand-optimization, retest on the latest toolchain — the regression you're chasing may be free to fix with a `go` directive bump.

---

## Related Rules

**Universal Principles:**
- [Generic Performance Principles](../../../../generic/performance/core-principles.md) - Universal performance principles (measure first, optimize bottlenecks, avoid premature optimization)

**Go-Specific:**
- [Concurrency Patterns](../language/concurrency-patterns.md) - Concurrency performance
- [Context Patterns](../language/context-patterns.md) - Context usage

---

## References

- [Go Profiling Guide](https://go.dev/blog/pprof)
- [Profile-Guided Optimization](https://go.dev/doc/pgo) — GA since Go 1.21
- [Go 1.24 release notes](https://go.dev/doc/go1.24) — Swiss Tables maps, mutex, runtime
- [The Go Blog](https://go.dev/blog/) — "Allocating on the Stack" (Feb 2026), "Green Tea Garbage Collector" (Oct 2025)
- [Escape Analysis](https://go.dev/doc/effective_go#allocation)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
