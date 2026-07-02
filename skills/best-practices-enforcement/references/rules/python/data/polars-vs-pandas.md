# Polars vs pandas

[Polars](https://docs.pola.rs/) is a Rust-core dataframe library with a Python API. It is faster, multi-threaded by default, and supports lazy execution and larger-than-memory workloads via `scan_*` + `collect`. Pandas remains the right choice when ecosystem interop (sklearn, statsmodels, plotting) dominates the workload. Don't pick blindly — match the tool to the workload.

---

## Decision matrix

| Workload signal | Pick |
|---|---|
| New ETL / aggregation pipeline, > 1 GB data | **Polars** |
| Larger-than-memory data (need to stream from Parquet/CSV) | **Polars** (`pl.scan_parquet` + `.collect(streaming=True)`) |
| Need multi-threaded execution out of the box | **Polars** |
| Heavy use of sklearn / statsmodels / xgboost (DataFrame in, model out) | **pandas** |
| Plotting via matplotlib / seaborn directly off the frame | **pandas** (or convert with `.to_pandas()` at the boundary) |
| Existing pandas codebase with no perf issue | **pandas** (don't churn) |
| Need GroupBy-Apply with arbitrary Python UDFs | **pandas** (Polars UDFs work but defeat its perf model) |

Rule of thumb: **Polars for the pipeline, pandas at the ML boundary.** Many UADS DS workflows look like `scan -> filter -> agg -> join -> to_pandas() -> sklearn`.

---

## Polars eager vs lazy

```python
# Good: eager — pandas-like, immediate execution
import polars as pl

df = pl.read_parquet("events.parquet")
agg = df.filter(pl.col("country") == "US").group_by("user_id").agg(
    pl.col("revenue").sum().alias("total_revenue"),
    pl.len().alias("event_count"),
)
```

```python
# Good: lazy — Polars optimizes the whole pipeline before executing
lazy_df = pl.scan_parquet("events.parquet")    # no read yet
agg = (
    lazy_df
    .filter(pl.col("country") == "US")          # pushed into the Parquet reader
    .group_by("user_id")
    .agg(
        pl.col("revenue").sum().alias("total_revenue"),
        pl.len().alias("event_count"),
    )
    .collect(streaming=True)                    # execute, stream chunks
)
```

Use **lazy + `scan_*`** when:

- Data is on disk (Parquet, CSV, IPC) and you only need a subset
- Filters/projections can be pushed down to the scanner (Polars does this automatically)
- Data is larger than memory — `collect(streaming=True)` processes in chunks

Use **eager** when:

- Interactive analysis in a notebook
- Data is already in memory or trivially small
- You're prototyping a transformation

---

## Idiomatic translation

```python
# pandas
import pandas as pd
df = pd.read_parquet("events.parquet")
df["revenue_usd"] = df["revenue"] * df["fx_rate"]
top = (
    df[df["country"] == "US"]
      .groupby("user_id", as_index=False)
      .agg(total=("revenue_usd", "sum"))
      .sort_values("total", ascending=False)
      .head(100)
)
```

```python
# Polars
import polars as pl
df = pl.read_parquet("events.parquet")
top = (
    df.with_columns((pl.col("revenue") * pl.col("fx_rate")).alias("revenue_usd"))
      .filter(pl.col("country") == "US")
      .group_by("user_id")
      .agg(pl.col("revenue_usd").sum().alias("total"))
      .sort("total", descending=True)
      .head(100)
)
```

Differences worth internalizing:

- Polars uses `pl.col("x")` expressions; pandas uses string indexers and Python operators.
- `group_by(...).agg(...)` returns columns directly named in the aggregation; no `as_index=False` dance.
- `with_columns([...])` is the additive equivalent of `df["x"] = ...`; doesn't mutate.
- All Polars DataFrame methods return a new frame — there is no `inplace=` (and there shouldn't be in pandas either, see the data-handling rule).

---

## Interop at boundaries

```python
# Good: cross the boundary at the smallest data shape
pandas_df = polars_df.to_pandas()           # for sklearn / matplotlib
polars_df = pl.from_pandas(pandas_df)       # the other direction

# Good: zero-copy via Arrow for large frames
arrow_table = polars_df.to_arrow()
pandas_df = arrow_table.to_pandas(types_mapper=pd.ArrowDtype)
```

Convert as late as possible. If sklearn expects pandas, do filtering and aggregation in Polars first, then `.to_pandas()` on the small result frame.

---

## When NOT to pick Polars

- **You'd write 20 Python UDFs.** Polars UDFs work via `.map_elements()` but break out of Rust into Python per row, losing most of the speed. If the logic can't be expressed as Polars expressions, pandas (or even raw NumPy) may be simpler.
- **Plotting and stats libraries** are the consumer. matplotlib/seaborn/statsmodels expect pandas; converting back and forth on every cell is friction.
- **Existing pandas codebase with no perf issue.** Don't refactor for novelty. The migration cost is real.
- **You need exotic pandas features** (MultiIndex with named levels, `pd.eval`, complex pivot/melt patterns). Polars covers 95% but the edges differ.

---

## When Polars is clearly correct

- ETL between Parquet / Iceberg / CSV with filter + aggregate pipelines
- Frames > 1 GB on a single machine
- Larger-than-memory streaming reads (Polars 1.x streaming engine)
- CI / batch jobs where wall-clock time and memory matter
- Net-new pipelines with no pandas legacy

---

## Common pitfalls

❌ Calling `.collect()` early in a lazy chain "just to inspect" — defeats the optimizer. Use `.head().collect()` or `.fetch(n)` instead.

❌ Mixing Polars Series with pandas Series in the same function — type errors are silent until aggregation runs.

❌ Treating `pl.col("x")` like a pandas Series. It's a lazy expression — methods on it return more expressions, not values.

✅ Read `pl.scan_*` documentation when working with Parquet/CSV at scale — predicate and projection pushdown is where most of the speedup comes from.

---

## Related rules

- [Data Handling](data-handling.md) — Pandas-side patterns (vectorization, dtypes, chaining)
- [Profiling and Optimization](../performance/profiling-and-optimization.md) — measure before choosing

---

## References

- [Polars User Guide](https://docs.pola.rs/) — official docs, Rust core + Python API
- [Polars Python API Reference](https://docs.pola.rs/api/python/stable/reference/) — canonical Python surface
- [Polars Lazy API](https://docs.pola.rs/user-guide/concepts/lazy-vs-eager/) — when and why

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
