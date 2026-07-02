# JVM observability with JFR

Java Flight Recorder (JFR) is the JVM's built-in event-recording system. It runs inside the VM with **single-digit-percent overhead** (often <1%) on standard profiles, captures hundreds of event types (GC, allocation, lock contention, I/O, virtual-thread pinning, JIT, class loading, custom application events), and is **always-on capable** in production. Open-sourced in JDK 11; ships with every modern OpenJDK build.

This is a meta/production observability rule. For application-level metrics/logging conventions, see your APM / OTel setup — JFR complements those by exposing the **JVM internals** that no application metric can see.

---

## When to reach for JFR

| Symptom | JFR helps because |
|---|---|
| p99 latency spikes you can't trace | JFR records lock contention, GC pauses, safe-point time, allocation outliers |
| OOM or steadily growing heap | JFR captures TLAB allocation outliers and old-gen promotions per stack |
| Virtual threads not scaling as expected | JFR's `jdk.VirtualThreadPinned` event names the pinning frame ([virtual-threads.md](../language/virtual-threads.md)) |
| GC tuning decisions | JFR replaces `-Xlog:gc*` log parsing — structured events you can query |
| "Just-in-case" production capture | Continuous mode rolls a small file you can dump after an incident |

---

## Continuous (always-on) recording

The recommended production setup is a **continuous recording** with a small rolling buffer. When something goes wrong, you dump the buffer and have minutes-to-hours of pre-incident JVM detail.

```bash
java \
  -XX:StartFlightRecording=name=cont,maxage=2h,maxsize=256m,settings=profile \
  -XX:FlightRecorderOptions=stackdepth=128 \
  -jar app.jar
```

- `settings=profile` is the heavier default profile; `settings=default` is the always-on lower-overhead one. Start with `default`, escalate to `profile` for active investigation.
- `maxage=2h,maxsize=256m` rolls a 2-hour / 256-MiB sliding window. Tune to your container limits.
- `stackdepth=128` keeps stacks deep enough that the offending frame is captured.

Dump the current buffer on demand:

```bash
jcmd <pid> JFR.dump name=cont filename=/tmp/dump.jfr
```

---

## On-demand recording (incident response)

If you didn't enable continuous recording, you can start one at runtime:

```bash
jcmd <pid> JFR.start name=incident duration=120s settings=profile filename=/tmp/incident.jfr
```

This runs for 2 minutes, dumps the file, and stops — useful when you've already noticed the symptom and want a focused capture without restarting the JVM.

---

## Analyzing recordings

- **[JDK Mission Control (JMC)](https://www.oracle.com/java/technologies/jdk-mission-control.html)** — official desktop analyzer. Read recordings, view automated analyses ("Heap Live Set Trend", "Latencies", "Lock Instances"), drill into events. Free.
- **`jfr` CLI** (ships with the JDK) — `jfr summary file.jfr`, `jfr print --events jdk.GarbageCollection file.jfr`. Scriptable for CI/CD checks.
- **Async-profiler `--jfr`** output is JFR-compatible and integrates the same way.

---

## High-value event categories

| Event(s) | What it tells you |
|---|---|
| `jdk.GCPhasePause`, `jdk.GarbageCollection` | GC pause durations, frequencies, causes |
| `jdk.ObjectAllocationInNewTLAB`, `jdk.ObjectAllocationOutsideTLAB` | Allocation hot spots with stack traces |
| `jdk.JavaMonitorEnter`, `jdk.JavaMonitorWait` | Lock contention, who waited where |
| `jdk.ThreadPark`, `jdk.ThreadSleep` | Voluntary blocking patterns |
| `jdk.VirtualThreadPinned` | Pinning of virtual threads to carriers (see [virtual-threads.md](../language/virtual-threads.md)) |
| `jdk.FileRead`, `jdk.SocketRead` | Slow I/O calls (above the configured threshold) |
| `jdk.SafepointBegin` | Time spent at JVM safepoints (often the hidden cost) |
| `jdk.ClassLoad` | Class-loading spikes during startup or hot redeploy |
| `jdk.CPULoad` | JVM CPU time vs system CPU time |

---

## Custom application events

JFR isn't just for the JVM — you can register your own typed events for first-class observability.

```java
@Name("com.example.OrderProcessed")
@Label("Order Processed")
@Category("Application")
public class OrderProcessedEvent extends Event {
    @Label("Order ID")  String orderId;
    @Label("Amount")    double amount;
    @Label("Latency Ms") long latencyMs;
}

void process(Order o) {
    var event = new OrderProcessedEvent();
    event.begin();
    try {
        doWork(o);
    } finally {
        event.orderId = o.id();
        event.amount  = o.total();
        event.latencyMs = event.commit() ? 0 : 0; // commit() writes the event
    }
}
```

Custom events show up alongside JVM events in JMC, so you can correlate a slow `OrderProcessed` with the `GarbageCollection` or `JavaMonitorEnter` event that overlapped it.

---

## When NOT to use JFR

- **Sub-second microbenchmarks** — use JMH instead; JFR is for production observation, not nanosecond timing.
- **Distributed tracing across services** — JFR is JVM-local; pair it with OpenTelemetry for cross-service traces.
- **As an APM replacement** — JFR has no aggregation, no dashboards, no alerting on its own. It's the data source; you still need a viewer or pipeline.

---

## Related rules

- [Virtual threads](../language/virtual-threads.md) — `jdk.VirtualThreadPinned` event for pin diagnosis
- [Production patterns](java-production-patterns.md) — resource and exception conventions

---

## References

- [JDK Flight Recorder (Oracle)](https://docs.oracle.com/en/java/javase/21/jfapi/) — programming guide
- [dev.java/learn — JVM monitoring](https://dev.java/learn/) — JFR introduction
- [JDK Mission Control](https://www.oracle.com/java/technologies/jdk-mission-control.html) — official analyzer

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
