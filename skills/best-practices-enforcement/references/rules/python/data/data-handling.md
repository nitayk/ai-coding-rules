# Data Handling Best Practices

Guidelines for efficient data processing with **pandas** or **Polars**, and robust validation with **Pydantic v2**.

Two dataframe tracks coexist in modern Python work:

- **pandas** — mature ecosystem, sklearn / statsmodels / plotting interop.
- **Polars** — Rust core, multi-threaded, lazy execution, larger-than-memory via `scan_*` + `collect`.

Pick per workload. See `data/polars-vs-pandas.md` for the decision matrix and idiomatic translations. For the Pydantic v1 → v2 migration (validators, config, settings split), see `data/pydantic-v2-migration.md`.

## Pandas Optimization

### Vectorization
Avoid iterating over rows. Use vectorized operations which are implemented in C.

```python
import pandas as pd
import numpy as np

# ❌ BAD: Iterating rows
for index, row in df.iterrows():
    df.at[index, 'c'] = row['a'] + row['b']

# ✅ GOOD: Vectorized operation
df['c'] = df['a'] + df['b']
```

### Chaining (Method Chaining)
Use method chaining for cleaner, more readable pipelines.

```python
# ✅ GOOD: Method chaining
result = (
    df.query("age > 18")
    .assign(status="adult")
    .groupby("city")
    .agg({"salary": "mean"})
)
```

### Memory Management
Use explicit dtypes to save memory (e.g., `category` for strings with few unique values).

```python
# ✅ GOOD: Using category dtype
df['status'] = df['status'].astype('category')
```

---

## Polars Track (Pandas Alternative)

For new ETL pipelines, frames > 1 GB, or larger-than-memory workloads, prefer **Polars** over pandas. Polars uses lazy execution + pushdown optimization and multi-threads by default.

### Lazy scan + collect

```python
# ✅ GOOD: scan_parquet + filter pushdown + streaming collect
import polars as pl

agg = (
    pl.scan_parquet("s3://bucket/events/*.parquet")
      .filter(pl.col("country") == "US")
      .group_by("user_id")
      .agg(
          pl.col("revenue").sum().alias("total_revenue"),
          pl.len().alias("event_count"),
      )
      .collect(streaming=True)         # processes in chunks; > memory OK
)
```

### Eager API — pandas-like

```python
# ✅ GOOD: eager for interactive / small frames
df = pl.read_parquet("events.parquet")
top = (
    df.with_columns((pl.col("revenue") * pl.col("fx_rate")).alias("revenue_usd"))
      .filter(pl.col("country") == "US")
      .sort("revenue_usd", descending=True)
      .head(100)
)
```

### Cross the boundary at the smallest data shape

```python
# ✅ GOOD: Polars for ETL, pandas at the sklearn boundary
small_pd = (
    pl.scan_parquet("events.parquet")
      .filter(...)
      .group_by(...).agg(...)
      .collect()
      .to_pandas()                     # convert AFTER aggregation, not before
)
model.fit(small_pd[features], small_pd["label"])
```

See `data/polars-vs-pandas.md` for the full decision matrix and when *not* to pick Polars.

---

## Pydantic Models

Use Pydantic for robust data validation and settings management.

### Model Definition (V2 Style)

```python
from pydantic import BaseModel, Field, EmailStr, field_validator

class User(BaseModel):
    id: int
    name: str = Field(..., min_length=2)
    email: EmailStr
    age: int = Field(gt=0, lt=150)

    @field_validator('name')
    @classmethod
    def name_must_be_capitalized(cls, v: str) -> str:
        if not v[0].isupper():
            raise ValueError('Name must start with capital letter')
        return v
```

### Settings Management
Use `BaseSettings` from the **separate `pydantic-settings`** package (split out of core Pydantic in v2 — install explicitly).

```python
# pyproject.toml: dependencies = ["pydantic>=2", "pydantic-settings>=2"]
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    app_name: str = "My App"
    db_url: str

settings = Settings()
# Access via settings.db_url
```

### Serialization
Use `model_dump()` and `model_dump_json()` (V2) instead of `dict()` and `json()`.

```python
user = User(id=1, name="John", email="john@example.com", age=30)
data = user.model_dump()
json_data = user.model_dump_json()
```

### Validating arbitrary types with TypeAdapter

Pydantic v2's `TypeAdapter` replaces v1's `parse_obj_as` and is reusable across calls:

```python
from pydantic import TypeAdapter

users_adapter = TypeAdapter(list[User])     # build once, reuse
users = users_adapter.validate_python(raw_data)
```

### Strict mode for untrusted input

```python
# ✅ GOOD: reject silent coercion for external input
class StrictUser(BaseModel):
    model_config = ConfigDict(strict=True)
    id: int                                   # "42" no longer becomes 42
    name: str
```

For the full v1 → v2 mapping (`@validator` → `@field_validator`, `Config` → `model_config`, `parse_obj` → `model_validate`), see `data/pydantic-v2-migration.md`.

---

## Related Rules

**Universal Principles:**
- [Generic Code Quality Principles](../../../../generic/code-quality/core-principles.md) - Universal principles (make illegal states unrepresentable, type safety)
- [Generic Performance Principles](../../../../generic/performance/core-principles.md) - Universal performance principles (vectorization, batching)

**Python-Specific:**
- [Polars vs pandas](polars-vs-pandas.md) — choose the right dataframe engine per workload
- [Pydantic v2 Migration](pydantic-v2-migration.md) — v1 → v2 method/config rename cheatsheet
- [Airflow 3 Task SDK](airflow-3-task-sdk.md) — pandas/Polars at the ETL boundary

---

## References

- [Polars User Guide](https://docs.pola.rs/) — official Rust-core dataframe docs
- [Pydantic v2 docs](https://pydantic.dev/docs/validation/latest/get-started/) — current v2.13.x
- [pydantic-settings](https://docs.pydantic.dev/latest/concepts/pydantic_settings/) — separated settings package
- [pandas Documentation](https://pandas.pydata.org/docs/) — pandas reference

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
