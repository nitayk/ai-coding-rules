# Java Concurrency and Locking

Use the right lock for the scenario. Prevent deadlocks. Minimize contention. Prefer `java.util.concurrent` over manual locking.

---

## Choose the Right Lock

**Decision framework:**

| Scenario | Use | Reason |
|----------|-----|--------|
| Simple, low-contention (platform threads) | `synchronized` | Simplest, JVM-optimized |
| Code that may run on **virtual threads** with blocking inside the critical section | `ReentrantLock` | `synchronized` pins the virtual thread to its carrier — see [virtual-threads.md § Pinning hazards](virtual-threads.md) |
| Need tryLock, fairness, conditions | `ReentrantLock` | Advanced features |
| Read-heavy, few writers | `StampedLock` or `ReentrantReadWriteLock` | Higher throughput |
| Simple counters/flags | `AtomicInteger`, `AtomicLong` | Lock-free, minimal overhead |

```java
// ✅ Good: synchronized for simple cases
public class SimpleCounter {
    private int count;
    
    public synchronized void increment() {
        count++;
    }
    
    public synchronized int getCount() {
        return count;
    }
}

// ✅ Good: ReentrantLock when you need tryLock or conditions
public class ResourcePool {
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition notFull = lock.newCondition();
    
    public boolean tryAcquire(long timeout, TimeUnit unit) throws InterruptedException {
        if (lock.tryLock(timeout, unit)) {
            try {
                return doAcquire();
            } finally {
                lock.unlock();
            }
        }
        return false;
    }
}

// ✅ Good: StampedLock for read-heavy workloads
public class ConfigCache {
    private final StampedLock lock = new StampedLock();
    private Map<String, Config> config = new HashMap<>();
    
    public Config get(String key) {
        long stamp = lock.readLock();
        try {
            return config.get(key);
        } finally {
            lock.unlockRead(stamp);
        }
    }
    
    public void put(String key, Config value) {
        long stamp = lock.writeLock();
        try {
            config = new HashMap<>(config);
            config.put(key, value);
        } finally {
            lock.unlockWrite(stamp);
        }
    }
}
```

---

## Always Use try-finally with Explicit Locks

**Critical:** `ReentrantLock` and `StampedLock` do not auto-release. Use try-finally to ensure unlock on all paths.

```java
// ✅ Good: try-finally ensures unlock
ReentrantLock lock = new ReentrantLock();
lock.lock();
try {
    // critical section
} finally {
    lock.unlock();
}

// ❌ Bad: Early return or exception leaves lock held (deadlock)
lock.lock();
if (condition) {
    return;  // DEADLOCK: lock never released
}
lock.unlock();
```

---

## Prefer java.util.concurrent Over Manual Locking

**Use thread-safe collections and utilities instead of wrapping with locks:**

```java
// ✅ Good: ConcurrentHashMap for concurrent maps
private final Map<String, User> cache = new ConcurrentHashMap<>();

// ✅ Good: AtomicInteger for simple counters
private final AtomicInteger counter = new AtomicInteger(0);

// ❌ Bad: Hashtable (legacy, coarse locking)
private final Map<String, User> cache = new Hashtable<>();

// ❌ Bad: synchronized HashMap when ConcurrentHashMap fits
private final Map<String, User> cache = Collections.synchronizedMap(new HashMap<>());
```

---

## Minimize Critical Section Duration

**Hold locks only as long as necessary.** Never do I/O, network calls, or expensive computation while holding a lock.

```java
// ✅ Good: Copy under lock, process outside
public Result getAndProcess(String key) {
    Data data;
    lock.lock();
    try {
        data = cache.get(key);
    } finally {
        lock.unlock();
    }
    return expensiveProcessing(data);  // Outside lock
}

// ❌ Bad: I/O inside critical section
lock.lock();
try {
    data = cache.get(key);
    result = callExternalAPI(data);  // Blocking I/O while holding lock!
} finally {
    lock.unlock();
}
```

---

## Establish Consistent Lock Ordering

**Acquiring locks in different orders causes deadlock.** Use a canonical order (e.g., by ID).

```java
// ✅ Good: Canonical order to prevent deadlock
public void transfer(int fromId, int toId, int amount) {
    if (fromId > toId) {
        int tmp = fromId;
        fromId = toId;
        toId = tmp;
    }
    Account from = getAccount(fromId);
    Account to = getAccount(toId);
    synchronized (from) {
        synchronized (to) {
            from.debit(amount);
            to.credit(amount);
        }
    }
}

// ❌ Bad: Different order in different code paths → deadlock risk
```

---

## Use volatile for Visibility-Only Scenarios

**`volatile` ensures visibility across threads but not atomicity.** Use for flags or single-writer scenarios.

```java
// ✅ Good: volatile for shutdown flag
private volatile boolean shutdown = false;

public void run() {
    while (!shutdown) {
        doWork();
    }
}

// ❌ Bad: volatile for compound operations (not atomic)
private volatile int count;
count++;  // Race condition! Use AtomicInteger
```

---

## Encapsulate Shared State

**Protect all access through methods that handle locking.** Never expose unlocked mutable state.

```java
// ✅ Good: Encapsulated access
public class SafeCounter {
    private final ReentrantLock lock = new ReentrantLock();
    private int value;
    
    public void increment() {
        lock.lock();
        try {
            value++;
        } finally {
            lock.unlock();
        }
    }
    
    public int getValue() {
        lock.lock();
        try {
            return value;
        } finally {
            lock.unlock();
        }
    }
}

// ❌ Bad: Exposing mutable field
public class BadCounter {
    public int value;  // Callers can bypass synchronization
}
```

---

## Related Rules

**Java-Specific:**
- [Virtual Threads](virtual-threads.md) - Pinning hazards (synchronized blocks pin carriers)
- [Parallel Processing](parallel-processing.md) - CompletableFuture, ExecutorService, virtual threads
- [Modern Java Patterns](modern-java-patterns.md) - Immutability, virtual threads

**Universal:**
- [Generic Performance Principles](../../../generic/performance/core-principles.md) - Minimize contention

---

## References

- [Java Concurrency in Practice - Brian Goetz et al. (2006)](https://jcip.net/) — fundamentals (memory model, happens-before, immutability); predates virtual threads — pair with JEP 444 for modern concurrency
- [java.util.concurrent API](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/package-summary.html)
- [JEP 444: Virtual Threads (Final, JDK 21)](https://openjdk.org/jeps/444) — pinning section

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
