# Java Parallel Processing

Use the right concurrency primitive for the workload. Prefer virtual threads for I/O-bound work. Always shut down executors.

---

## Prefer Virtual Threads for I/O-Bound Work (Java 21+)

**Virtual threads are cheap; use them for I/O-bound operations instead of platform thread pools.** Virtual threads went **GA in JDK 21** via [JEP 444](https://openjdk.org/jeps/444). See [virtual-threads.md](virtual-threads.md) for adoption decisions and pinning hazards (the most common gotcha: `synchronized` blocks pin the carrier thread).

```java
// ✅ Good: Virtual threads for I/O (database, HTTP, file)
try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
    List<CompletableFuture<User>> futures = ids.stream()
        .map(id -> CompletableFuture.supplyAsync(
            () -> repository.findById(id),
            executor))
        .toList();
    
    return CompletableFuture.allOf(futures.toArray(CompletableFuture[]::new))
        .thenApply(v -> futures.stream()
            .map(CompletableFuture::join)
            .toList())
        .join();
}

// ❌ Bad: Large fixed pool for I/O (wastes platform threads)
ExecutorService executor = Executors.newFixedThreadPool(200);  // Platform threads are expensive
```

---

## Use Bounded Thread Pools for CPU-Bound Work

**For CPU-bound work, limit threads to ~number of cores.** Unbounded threads cause contention.

```java
// ✅ Good: Bounded pool for CPU-bound work
int cores = Runtime.getRuntime().availableProcessors();
ExecutorService executor = Executors.newFixedThreadPool(cores);

// ✅ Good: Custom pool with queue and rejection policy
ThreadPoolExecutor executor = new ThreadPoolExecutor(
    cores, cores * 2,
    60, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(1000),
    new ThreadPoolExecutor.CallerRunsPolicy());

// ❌ Bad: Unbounded pool for CPU work
ExecutorService executor = Executors.newCachedThreadPool();  // Can spawn thousands
```

---

## Always Shut Down ExecutorService

**Executors hold non-daemon threads; the JVM will not exit until they are shut down.**

```java
// ✅ Good: try-with-resources (Java 19+) or explicit shutdown
try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
    executor.submit(() -> doWork());
}

// ✅ Good: Explicit shutdown with timeout
ExecutorService executor = Executors.newFixedThreadPool(4);
try {
    executor.submit(() -> doWork());
} finally {
    executor.shutdown();
    if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
        executor.shutdownNow();
    }
}

// ❌ Bad: Executor never shut down (thread leak, JVM hangs on exit)
ExecutorService executor = Executors.newFixedThreadPool(4);
executor.submit(() -> doWork());
// executor never shut down
```

---

## Use CompletableFuture for Async Composition

**Compose async operations with `thenApply`, `thenCompose`, `exceptionally`.** Avoid blocking in async chains.

```java
// ✅ Good: Async composition
CompletableFuture<User> loadUser(String id) {
    return CompletableFuture.supplyAsync(() -> repository.findById(id), executor)
        .thenApply(Optional::orElseThrow)
        .exceptionally(ex -> {
            logger.error("Failed to load user " + id, ex);
            throw new CompletionException(ex);
        });
}

CompletableFuture<Order> loadUserAndOrder(String userId, String orderId) {
    return loadUser(userId)
        .thenCompose(user -> loadOrder(orderId)
            .thenApply(order -> new OrderWithUser(order, user)));
}

// ❌ Bad: Blocking inside async chain
return CompletableFuture.supplyAsync(() -> {
    User user = repository.findById(id).join();  // Blocking!
    return process(user);
}, executor);
```

---

## Use Parallel Streams Carefully

**Parallel streams use the common ForkJoinPool.** Use only for CPU-bound, independent work. Avoid for I/O.

```java
// ✅ Good: CPU-bound, independent work
List<Result> results = items.parallelStream()
    .map(this::expensiveComputation)
    .toList();

// ⚠️ Caution: Parallel stream shares common pool - can starve other code
// For controlled parallelism, use custom pool:
ForkJoinPool customPool = new ForkJoinPool(4);
List<Result> results = customPool.submit(() ->
    items.parallelStream().map(this::expensiveComputation).toList()
).join();

// ❌ Bad: I/O in parallel stream (blocks common pool)
items.parallelStream()
    .map(id -> httpClient.get(id))  // I/O blocks ForkJoinPool threads
    .toList();
```

---

## Implement Backpressure for Unbounded Work

**Unbounded async work can exhaust memory or overwhelm downstream.** Use semaphores, bounded queues, or limits.

```java
// ✅ Good: Semaphore to limit concurrent tasks
Semaphore limit = new Semaphore(10);

CompletableFuture<Void> processWithLimit(Item item) {
    return CompletableFuture.runAsync(() -> {
        try {
            limit.acquire();
            try {
                process(item);
            } finally {
                limit.release();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new CompletionException(e);
        }
    }, executor);
}

// ❌ Bad: Unbounded submission
for (Item item : items) {
    executor.submit(() -> process(item));  // Can overwhelm system
}
```

---

## Don't Fire-and-Forget Without Tracking

**Track async work for shutdown and error propagation.** Use `CompletableFuture` or `ExecutorService` that you control.

```java
// ✅ Good: Track futures for shutdown
List<CompletableFuture<Void>> futures = items.stream()
    .map(item -> CompletableFuture.runAsync(() -> process(item), executor))
    .toList();
CompletableFuture.allOf(futures.toArray(CompletableFuture[]::new)).join();

// ❌ Bad: Fire-and-forget with no way to wait or cancel
for (Item item : items) {
    executor.submit(() -> process(item));
}
// No way to know when done or shutdown
```

---

## Structured Concurrency is Still Incubator — Don't Adopt in Production Yet

[JEP 480: Structured Concurrency](https://openjdk.org/jeps/480) remains an **incubator** feature (as of Java 23/24, still incubator at the time of writing). The API surface (`StructuredTaskScope`, etc.) is still subject to change between releases. Track it, prototype against it, but **do not put it on the production critical path** until it goes Final — your code will break across JDK upgrades.

In the meantime, `CompletableFuture` + virtual threads cover the common cases. Once structured concurrency is Final, prefer it for fan-out tasks that should share a lifetime and cancellation scope.

---

## Related Rules

**Java-Specific:**
- [Virtual Threads](virtual-threads.md) - Adoption decisions, pinning hazards
- [Concurrency and Locking](concurrency-locking.md) - synchronized, ReentrantLock, thread-safe collections
- [Modern Java Patterns](modern-java-patterns.md) - Virtual threads, streams

**Universal:**
- [Generic Performance Principles](../../../generic/performance/core-principles.md) - Bounded concurrency

---

## References

- [JEP 444: Virtual Threads (Final, JDK 21)](https://openjdk.org/jeps/444)
- [JEP 480: Structured Concurrency (Incubator)](https://openjdk.org/jeps/480) — still incubator; track before adopting
- [CompletableFuture (Java Docs)](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/CompletableFuture.html)
- [ExecutorService (Java Docs)](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/ExecutorService.html)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
