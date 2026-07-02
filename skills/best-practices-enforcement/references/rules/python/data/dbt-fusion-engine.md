# dbt: Fusion Engine vs Core

dbt Labs' Rust-based **Fusion engine** is the recommended path for new dbt work in 2026. dbt Core (the Python implementation) remains maintained and is fine for existing pipelines, but Fusion ships the static analysis, faster parse, and LSP integration the project is investing in going forward. Source: [dbt docs](https://docs.getdbt.com/docs/introduction).

---

## When to pick which

| Situation | Pick |
|---|---|
| New dbt project starting in 2026 | **Fusion** |
| Editor LSP support for SQL models (jump-to-definition, lint) | **Fusion** |
| Static SQL analysis in CI before runs | **Fusion** |
| Existing dbt Core project, no perf/UX issue | **Core** (don't churn) |
| Provider/adapter not yet supported by Fusion | **Core** |
| Heavy use of Python models / specific Core-only adapters | **Core** |

Fusion is additive — it doesn't deprecate Core. The migration cost from Core to Fusion is low (same `dbt_project.yml`, same Jinja, same model SQL) but the gain depends on whether your workflow is bottlenecked on parse time and IDE feedback.

---

## What Fusion gives you that Core doesn't

- **Native SQL parser** — understands SQL semantically, not just as a Jinja template. Surfaces column-level errors before warehouse round-trips.
- **Language Server (LSP)** — jump-to-definition across `ref()` and `source()`, hover for column types, in-editor lint.
- **Faster `dbt parse` and `dbt compile`** — Rust core vs Python interpreter overhead.
- **Better incremental compile** — only re-parse what changed.

What stays the same: model files, `dbt_project.yml`, profiles, macros, packages, tests, the manifest schema.

---

## Project layout (works for both engines)

```
my_dbt_project/
├── dbt_project.yml
├── profiles.yml             # often in ~/.dbt/profiles.yml
├── models/
│   ├── staging/
│   │   ├── _sources.yml
│   │   └── stg_users.sql
│   ├── intermediate/
│   │   └── int_user_events.sql
│   └── marts/
│       ├── _schema.yml
│       └── fct_user_revenue.sql
├── macros/
├── tests/
└── seeds/
```

Standard three-layer model layout (`staging` → `intermediate` → `marts`) — both engines parse it identically.

---

## Model patterns that hold across engines

```sql
-- ✅ Good: staging model, one source per file, snake_case rename
-- models/staging/stg_users.sql
{{ config(materialized='view') }}

select
    id           as user_id,
    email,
    created_at   as signed_up_at,
    country_code as country
from {{ source('raw', 'users') }}
where deleted_at is null
```

```sql
-- ✅ Good: incremental mart with unique key
-- models/marts/fct_events.sql
{{ config(
    materialized='incremental',
    unique_key='event_id',
    on_schema_change='append_new_columns'
) }}

select
    e.event_id,
    e.user_id,
    e.event_type,
    e.event_ts,
    u.country
from {{ ref('stg_events') }} e
left join {{ ref('stg_users') }} u using (user_id)
{% if is_incremental() %}
where e.event_ts > (select coalesce(max(event_ts), '1970-01-01') from {{ this }})
{% endif %}
```

- Use `ref()` for project-internal references, `source()` for raw tables. Never hardcode `database.schema.table`.
- `is_incremental()` guards the `where` clause so the initial full run still works.
- Set `unique_key` on incremental models or risk silent duplicates.

---

## Tests in `_schema.yml`

```yaml
# ✅ Good: declarative tests live next to the model
version: 2

models:
  - name: stg_users
    description: "One row per user, deduplicated against raw."
    columns:
      - name: user_id
        description: "Stable internal user ID."
        tests:
          - not_null
          - unique
      - name: email
        tests:
          - not_null
      - name: country
        tests:
          - accepted_values:
              values: ["US", "GB", "DE", "FR", "JP"]
              quote: true
```

Built-in tests (`not_null`, `unique`, `accepted_values`, `relationships`) cover ~80% of needs. For more, use `dbt-utils` or write a custom singular test under `tests/`.

---

## CI patterns

```yaml
# Good: GitHub Actions for a dbt project
- run: dbt deps
- run: dbt parse                    # fastest — catches Jinja and ref errors
- run: dbt compile --select state:modified+ --defer --state ./prod-manifest
- run: dbt build --select state:modified+ --defer --state ./prod-manifest
```

- `dbt parse` is the cheapest gate — run it on every PR.
- `state:modified+` with `--defer` runs only changed models and their downstream, using prod manifest for unchanged upstream.
- `dbt build` runs `run` + `test` in dependency order — prefer it over `dbt run && dbt test`.

Under Fusion, `dbt parse` includes column-level static checks; under Core, it only checks Jinja/ref resolution.

---

## Common pitfalls

❌ Hardcoding `database.schema.table` instead of `ref()` / `source()`. Breaks dev/prod isolation and makes lineage incomplete.

❌ Setting `materialized='table'` on every model. Use `view` for staging, `incremental` for large marts, `table` only when scan cost matters.

❌ Incremental models without `unique_key` — silent duplicates accumulate.

❌ Putting tests as ad-hoc `where` clauses in models. Use `_schema.yml` tests so failures show up in the CI dashboard.

❌ Mixing dbt Core and Fusion in the same project on the same CI run. Pick one engine per project; the manifest format and parse semantics differ in edge cases.

✅ Pin the dbt version in your project: `[require-dbt-version]` in `dbt_project.yml` or `requires-dbt-version:`. Floating versions cause silent macro behavior changes.

---

## Related rules

- [Airflow 3 Task SDK](airflow-3-task-sdk.md) — dbt is usually invoked from an Airflow `@task` or `DbtCloudRunJobOperator`
- [Data Handling](data-handling.md) — pandas/Polars at the Python side of the pipeline

---

## References

- [dbt Introduction](https://docs.getdbt.com/docs/introduction) — official; explains Fusion vs Core
- [dbt Project structure best practices](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview)
- [dbt Incremental models](https://docs.getdbt.com/docs/build/incremental-models)
- [dbt Testing](https://docs.getdbt.com/docs/build/data-tests)

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
