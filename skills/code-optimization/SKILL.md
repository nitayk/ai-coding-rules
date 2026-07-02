---
name: code-optimization
description: "Use when optimizing code for measured performance, memory, or efficiency problems with a concrete target (latency budget, memory ceiling, throughput floor). Do NOT use for general cleanup (use /code-cleanup or /code-simplification), structural refactoring (handle as a separate refactoring task), or speculative optimization without a profile."
last-reviewed: 2026-05-20
---

# Code Optimization

Optimize code for measured performance, memory usage, or algorithmic efficiency. **Profile-driven, never speculative.**

## When to use

**APPLY WHEN** all of:
- The change is motivated by a measured problem (slow request, memory blow-up, CPU pegged) or a stated budget (P99 < 200 ms, RSS < 1 GB)
- A profile or benchmark exists or you can produce one before changing anything
- The hot spot is identified — you can name the function/loop/query that dominates

**SKIP WHEN** any of:
- General cleanup → use `/code-cleanup`
- Reuse / DRY / clarity → use `/code-simplification` (auto-applies fixes; CC's built-in `/code-review` — formerly `/simplify` — now only reports correctness bugs)
- Structural refactoring (move code between modules/services) → handle as a separate refactoring task
- "I think this might be slow" without measurement → run `/benchmark` first to establish baseline; come back here only if the number is bad

## Anti-patterns (refuse these)

- **Optimizing without a profile.** Premature optimization wastes time and adds complexity. The first step is always *measure*. If the user asks for optimization with no profile, run `/benchmark` to establish a baseline before any code change.
- **Optimizing the wrong thing.** ~80% of runtime is usually in ~20% of code. Optimizing a function that runs 0.1% of the time is noise. Read the profile, find the dominant cost, focus there.
- **Single-run "improvement" claims.** Performance claims need before/after numbers from at least 3 runs each (or 1 well-controlled benchmark). One-shot timings are noise.
- **Removing safety for speed.** Don't remove bounds checks, validation, or error handling unless the profile proves they dominate AND the user explicitly accepts the risk.

## Workflow

### Step 1 — Measure baseline

Pick the right tool for the language:

| Language | CPU profile | Memory profile | Benchmark |
|---|---|---|---|
| Go | `go test -cpuprofile`, `pprof` | `go test -memprofile`, `pprof` | `go test -bench=. -benchmem` |
| Python | `py-spy record`, `cProfile`, `pyinstrument` | `tracemalloc`, `memray` | `pytest-benchmark`, `timeit` |
| Node / TypeScript | `clinic.js doctor`, `--inspect --cpu-prof` | `clinic.js heapprofiler`, `--heap-prof` | `vitest bench`, `benchmark.js` |
| Rust | `cargo flamegraph`, `perf` | `heaptrack`, `dhat` | `cargo bench` (criterion) |
| Java / Kotlin | `async-profiler`, JFR | `JFR`, `jmap`+MAT | JMH |
| Scala | `async-profiler`, JFR | `JFR`, `jmap`+MAT | JMH, `sbt-jmh` |
| Browser JS | Chrome DevTools Performance tab | DevTools Memory tab | Chrome DevTools, `web-vitals` |

Save the baseline. If `/benchmark` skill exists in this environment, use it for repeatable measurement.

### Step 2 — Identify the hot spot

Read the profile. Look for:
- Functions with the highest **self time** (CPU)
- Allocations in tight loops (memory)
- Repeated work that could be cached or hoisted
- Unnecessary IO inside loops (DB query in a `for`, file read per iteration)

Name the dominant cost in one sentence. If you can't name it, your profile isn't granular enough — re-run with finer-grained instrumentation.

### Step 3 — Apply ONE targeted change

Common high-leverage patterns:
- **Hoist** loop-invariant work out of the loop
- **Batch** N+1 IO into one call (DB IN-clause, fetch-many API)
- **Cache** repeated pure computation (memoization, but mind correctness)
- **Replace** O(n²) with O(n log n) or O(n) (sort+linear-scan, hash map)
- **Avoid** allocation in hot loops (pre-size, reuse buffers, pool)
- **Lazy** what's only sometimes needed

One change at a time. Re-measure after each — multiple changes at once and you can't attribute the win.

### Step 4 — Verify with measurement

Run the same benchmark from Step 1. Report **before / after / delta** (e.g. `P99: 230 ms → 95 ms (-58%)`). If the delta isn't material (< 10% on the metric you care about), revert and try a different angle — small wins aren't worth the complexity.

### Step 5 — Document the change

In the PR or commit message, include:
- The metric optimized (P99 latency, peak RSS, etc.)
- Before/after numbers
- The profile method (so future readers can re-measure)
- What got more complex as a tradeoff (readability, maintenance)

## Example

**Bad:** "Made the request handler faster."

**Good:**
> P99 of `/api/feed` reduced from 230 ms → 95 ms (-58%) under 100 RPS load.
> Profile (py-spy, 60 s window) showed `recommend_users()` dominating at 78% self-time, all in a per-user `User.objects.get(...)` inside a loop.
> Changed to `User.objects.in_bulk([...])` — single query, batched.
> Tradeoff: ~12 lines added, plus a `len(users) == 0` guard.

## Pair with

- `/benchmark` — for establishing baselines and measuring regression
- `/agent-token-optimization` — for *agent / LLM* spend optimization (different problem from runtime perf)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
