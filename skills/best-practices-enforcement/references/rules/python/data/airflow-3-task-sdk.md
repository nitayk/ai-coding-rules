# Airflow 3: TaskFlow + Task SDK

Apache Airflow 3 (current stable: 3.2.1) makes the `@task` decorator (TaskFlow API, now packaged as the **Task SDK**) the recommended authoring model. Explicit operator instantiation is still supported for legacy DAGs and for the few operators TaskFlow doesn't cover, but new code should default to `@task`. Source: [Airflow docs](https://airflow.apache.org/docs/apache-airflow/stable/).

---

## TaskFlow style — the default

```python
# ✅ Good: Airflow 3 TaskFlow / Task SDK
from datetime import datetime
from airflow.decorators import dag, task

@dag(
    dag_id="user_etl",
    schedule="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["etl", "users"],
)
def user_etl():
    @task
    def extract(execution_date: str) -> list[dict]:
        return fetch_users_since(execution_date)

    @task
    def transform(users: list[dict]) -> list[dict]:
        return [normalize(u) for u in users]

    @task
    def load(users: list[dict]) -> int:
        return bulk_insert("dwh.users", users)

    # Python call syntax = task dependency graph
    raw = extract("{{ ds }}")
    clean = transform(raw)
    load(clean)

user_etl()
```

Wins over the operator-instantiation style:

- Return values become XComs automatically; downstream args become dependencies.
- The DAG reads as a normal Python function. Reviewers don't need to map `>>` operators in their heads.
- Type annotations carry through — your linter and type checker see them.
- No string-keyed XCom pulls (`ti.xcom_pull(task_ids="extract")`).

---

## Operator instantiation — when it's still right

Use the old style when:

- You're calling a non-Python operator (`SparkSubmitOperator`, `KubernetesPodOperator`, `BashOperator`).
- A provider hasn't shipped a TaskFlow-style wrapper yet.
- You need a sensor with custom poke logic that doesn't fit `@task.sensor`.

```python
# ✅ Good: operator instantiation when needed (KubernetesPodOperator)
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator

train = KubernetesPodOperator(
    task_id="train_model",
    name="train-model",
    image="us-central1-docker.pkg.dev/.../trainer:latest",
    cmds=["python", "-m", "trainer"],
    do_xcom_push=False,
)
```

Mixing styles in one DAG is fine — wire them with `>>` or by referencing the task object:

```python
@dag(...)
def hybrid():
    raw = extract()           # TaskFlow
    raw >> train              # depend the operator on it
```

---

## XCom: prefer return values, don't push manually

```python
# ❌ Bad: manual xcom_push / xcom_pull
def extract(**context):
    rows = fetch()
    context["ti"].xcom_push(key="rows", value=rows)

def transform(**context):
    rows = context["ti"].xcom_pull(task_ids="extract", key="rows")
    ...
```

```python
# ✅ Good: return values become XComs; args resolve them
@task
def extract() -> list[dict]:
    return fetch()

@task
def transform(rows: list[dict]) -> list[dict]:
    return [normalize(r) for r in rows]

transform(extract())
```

For large payloads, configure a **custom XCom backend** (S3, GCS) instead of stuffing megabytes into the metadata DB. Don't pass DataFrames through default XCom.

---

## Dynamic Task Mapping

For fan-out over a variable-length input, use `.expand()`:

```python
# ✅ Good: map over a list — N parallel task instances
@task
def list_partitions() -> list[str]:
    return list_s3_partitions("s3://bucket/events/")

@task
def process(partition: str) -> int:
    return process_partition(partition)

process.expand(partition=list_partitions())
```

This replaces the Airflow 2 pattern of generating tasks in a Python `for` loop at DAG-parse time — which was fragile, hard to read, and recomputed at every scheduler heartbeat.

---

## Asset-aware scheduling (Airflow 3)

Airflow 3 generalizes Datasets into **Assets**. Use them for cross-DAG scheduling instead of `ExternalTaskSensor`:

```python
# ✅ Good: producer DAG emits an Asset
from airflow.sdk import Asset

users_asset = Asset("s3://dwh/users/{{ ds }}")

@dag(schedule="@daily", start_date=datetime(2026, 1, 1))
def user_etl():
    @task(outlets=[users_asset])
    def load() -> None:
        write_users()

# ✅ Good: consumer DAG schedules on the Asset
@dag(schedule=[users_asset], start_date=datetime(2026, 1, 1))
def user_aggregation():
    @task
    def aggregate() -> None: ...
```

The consumer fires when the producer marks the Asset updated — no sensor polling, no cross-DAG hard-coded knowledge of schedules.

---

## DAG file hygiene

- One DAG per file when DAGs are independent. Multiple `@dag()`-decorated functions per file is allowed but confuses some tools.
- `catchup=False` by default — only set `True` when you genuinely want backfill on first deploy.
- `start_date` is a constant — never `datetime.now()`. Use a fixed date in the past.
- Tag every DAG (`tags=["team", "domain"]`) so UI filtering works.
- Keep DAG modules import-light. The scheduler parses every file on every heartbeat; heavy imports at module top will slow the whole instance.

---

## Common pitfalls

❌ Calling APIs / DB queries at DAG file top level. Airflow re-imports DAG files constantly — every import becomes a fired query.

❌ Using `xcom_pull` after the upstream task switched to TaskFlow returns — the implicit return-value XCom has key `return_value`, not the legacy custom key.

❌ Catching exceptions inside a `@task` and returning `None` — downstream tasks see `None` and fail mysteriously. Let the task fail; Airflow's retry/alert handles it.

❌ Forgetting `catchup=False` and shipping a DAG with `start_date=2020-01-01` — six years of backfill kick off on deploy.

✅ For very large payloads (DataFrames, files), persist to object storage in the task and pass a path through XCom — don't push the data itself.

---

## Related rules

- [Polars vs pandas](polars-vs-pandas.md) — choosing the dataframe engine for ETL bodies
- [Data Handling](data-handling.md) — Pydantic validation at DAG boundaries
- [Type Annotations Everywhere](../language/type-annotations-everywhere.md) — `@task` carries type info through XCom

---

## References

- [Apache Airflow 3.x documentation](https://airflow.apache.org/docs/apache-airflow/stable/) — current 3.2.1
- [Airflow: TaskFlow API tutorial](https://airflow.apache.org/docs/apache-airflow/stable/tutorial/taskflow.html)
- [Airflow: Dynamic Task Mapping](https://airflow.apache.org/docs/apache-airflow/stable/authoring-and-scheduling/dynamic-task-mapping.html)
- [Airflow: Assets](https://airflow.apache.org/docs/apache-airflow/stable/authoring-and-scheduling/assets.html)

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
