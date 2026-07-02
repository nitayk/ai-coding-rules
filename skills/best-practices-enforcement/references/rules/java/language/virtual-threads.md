# Virtual threads (Java 21+)

Virtual threads went **GA in JDK 21** via [JEP 444](https://openjdk.org/jeps/444). They are JVM-scheduled, lightweight (~hundreds of bytes), and intended to replace platform-thread pools for **I/O-bound** workloads. They are **not** a CPU-parallelism primitive — for CPU-bound work, keep using a bounded pool sized to the number of cores.

This file focuses on adoption decisions and pinning hazards. For broader async composition (CompletableFuture, parallel streams, backpressure), see [parallel-processing.md](parallel-processing.md).

---

## When to use virtual threads

| Workload | Use | Reason |
|----------|-----|--------|
| I/O-bound (DB, HTTP, RPC, file) | `Executors.newVirtualThreadPerTaskExecutor()` | Cheap to block; one task per thread is fine |
| CPU-bound (compute, hashing, parsing) | Bounded `ForkJoinPool` or `newFixedThreadPool(cores)` | Virtual threads do not add CPU parallelism |
| Short-lived fan-out (per-request) | Virtual thread per task | No pool sizing required |
| Long-lived background loops | Single platform thread or scheduler | Virtual threads are not meant to be pooled |

✅ Good: virtual thread per task for I/O fan-out

```java
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    List<Future<User>> futures = ids.stream()
        .map(id -> executor.submit(() -> repository.findById(id)))  // blocking JDBC call
        .toList();
    return futures.stream().map(Future::get).toList();
}
```

❌ Bad: pooling virtual threads defeats the purpose

```java
// Don't bound virtual threads — they're already cheap.
ExecutorService vt = Executors.newFixedThreadPool(200, Thread.ofVirtual().factory());
```

❌ Bad: virtual threads for CPU-bound work

```java
// Doesn't help; virtual threads multiplex onto a small carrier pool.
items.stream()
    .map(item -> Thread.ofVirtual().start(() -> hashAndEncrypt(item)))
    .forEach(Thread::join);
```

---

## Pinning hazards

A virtual thread is **pinned** to its carrier (platform) thread when it cannot be unmounted during a blocking operation. While pinned, the carrier is unavailable for other virtual threads, which can starve throughput and cause the JVM to spawn extra carriers.

Per [JEP 444](https://openjdk.org/jeps/444), the two pinning sources to know are:

1. **`synchronized` blocks/methods that perform blocking operations** — the monitor is held on the carrier.
2. **Native frames (JNI)** — the JVM cannot unmount a virtual thread with a native frame on the stack.

### Fix: replace `synchronized` with `ReentrantLock` on hot blocking paths

✅ Good

```java
private final ReentrantLock lock = new ReentrantLock();

public Response handle(Request r) {
    lock.lock();
    try {
        return blockingRemoteCall(r);   // unmounts cleanly — no pin
    } finally {
        lock.unlock();
    }
}
```

❌ Bad

```java
public synchronized Response handle(Request r) {
    return blockingRemoteCall(r);       // pins the carrier for the whole call
}
```

### Detect pinning

- Run with `-Djdk.tracePinnedThreads=full` (or `=short`) — JDK 21 logs every pin with a stack trace.
- For continuous prod observation, capture **JFR** `jdk.VirtualThreadPinned` events (see [jfr-observability.md](../meta/jfr-observability.md)).
- Don't guess — the trace tells you the exact frame.

---

## Don't share thread-locals widely

Virtual threads can exist by the millions; a `ThreadLocal` value held per thread can blow up heap usage. Prefer:

- **Scoped values** (`ScopedValue`, preview/incubator on recent JDKs) for per-task immutable context.
- Explicit parameters or context objects passed through the call chain.
- If you must use `ThreadLocal`, ensure values are small and cleared on task completion.

❌ Bad: heavy per-thread cache

```java
private static final ThreadLocal<byte[]> SCRATCH = ThreadLocal.withInitial(() -> new byte[1 << 20]);  // 1 MiB × N threads
```

---

## Don't size connection pools to "max virtual threads"

JDBC/HTTP connection pools are still the real bottleneck. With virtual threads, **many more threads will queue for a connection** — size pools to downstream capacity, not to thread count. Add a `Semaphore` or use the pool's bounded queue to apply backpressure (see [parallel-processing.md § Implement Backpressure](parallel-processing.md)).

---

## Related rules

- [Parallel processing](parallel-processing.md) — CompletableFuture, executor shutdown, backpressure
- [Concurrency and locking](concurrency-locking.md) — `synchronized` vs `ReentrantLock` (pin-aware)
- [JFR observability](../meta/jfr-observability.md) — capturing `jdk.VirtualThreadPinned`
- [Modern Java patterns](modern-java-patterns.md) — broader Java 17+ overview

---

## References

- [JEP 444: Virtual Threads (Final, JDK 21)](https://openjdk.org/jeps/444) — normative spec, pinning section
- [dev.java/learn — Virtual Threads](https://dev.java/learn/) — Oracle tutorial

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
