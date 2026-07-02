"""Run the (arm × model × task × run) matrix and aggregate into per-cell stats.

Resolution metric: "best-of per task, then mean across tasks" — a task counts as
resolved if ANY of its N runs passed (best-of), and the cell's resolution rate is
the mean of those per-task best-of indicators across the cell's tasks.

The ±1σ resolution band is the RUN-TO-RUN stdev of per-run resolution: for each
run index i, per-run resolution = mean over the cell's tasks of (passed in run i);
the band is the population stdev across those per-run resolutions. This measures
the reproducibility of the plotted statistic (how much the cell's resolution varies
between independent runs) — matching GitHub's "±1σ run-to-run spread" — rather than
the dispersion of per-task pass-rates (a different quantity that would mislabel the
error bar on the best-of marker).
"""
from __future__ import annotations

import statistics
from collections import defaultdict
from typing import TYPE_CHECKING

from models import ArmModelStats, RunRecord, TaskSpec

if TYPE_CHECKING:
    from runners import AgentRunner


def run_matrix(
    runner: "AgentRunner",
    tasks: list[TaskSpec],
    arms: list[str],
    models: list[str],
    n_runs: int,
) -> list[RunRecord]:
    """Loop arm × model × task × run, collecting RunRecords.

    Per-run errors are isolated: one failing run becomes an error RunRecord (passed
    False) instead of aborting the whole matrix.
    """
    records: list[RunRecord] = []
    for arm in arms:
        for model in models:
            for task in tasks:
                for run_idx in range(n_runs):
                    try:
                        rec = runner.run(task, arm=arm, model=model)
                    except Exception as e:  # isolate: one bad run must not kill the matrix
                        rec = RunRecord(
                            arm=arm, model=model, task=getattr(task, "name", str(task)),
                            run_idx=run_idx, passed=False, input_tokens=0,
                            output_tokens=0, cost_usd=0.0, error=repr(e),
                        )
                    records.append(rec)
    return records


def _pstdev(values: list[float]) -> float:
    """Population stdev, guarded: n < 2 -> 0.0 (no spread from a single sample)."""
    return statistics.pstdev(values) if len(values) > 1 else 0.0


def aggregate(records: list[RunRecord]) -> list[ArmModelStats]:
    """Group by (arm, model) and compute resolution / token / cost stats."""
    # cells[(arm, model)][task] -> list[RunRecord]
    cells: dict[tuple[str, str], dict[str, list[RunRecord]]] = defaultdict(
        lambda: defaultdict(list)
    )
    for r in records:
        cells[(r.arm, r.model)][r.task].append(r)

    out: list[ArmModelStats] = []
    for (arm, model), by_task in sorted(cells.items()):
        # best-of resolution per task, then mean across tasks (the plotted marker)
        per_task_resolved = [
            1.0 if any(r.passed for r in runs) else 0.0 for runs in by_task.values()
        ]
        # run-to-run resolution for the ±1σ band: per run index i, the mean over the
        # cell's tasks of (passed in run i); the band is the spread across these.
        by_run: dict[int, list[RunRecord]] = defaultdict(list)
        for runs in by_task.values():
            for r in runs:
                by_run[r.run_idx].append(r)
        per_run_resolution = [
            statistics.mean(1.0 if r.passed else 0.0 for r in run_recs)
            for _, run_recs in sorted(by_run.items())
        ]
        # per-task mean tokens / cost (averaged across that task's runs), then mean
        per_task_tokens = [
            statistics.mean(r.total_tokens for r in runs) for runs in by_task.values()
        ]
        per_task_cost = [
            statistics.mean(r.cost_usd for r in runs) for runs in by_task.values()
        ]
        all_runs = [r for runs in by_task.values() for r in runs]

        out.append(
            ArmModelStats(
                arm=arm,
                model=model,
                n_runs=len(all_runs),
                n_tasks=len(by_task),
                resolution_rate=statistics.mean(per_task_resolved),
                resolution_stdev=_pstdev(per_run_resolution),
                mean_tokens_per_task=statistics.mean(per_task_tokens),
                tokens_stdev=_pstdev(per_task_tokens),
                mean_cost_per_task=round(statistics.mean(per_task_cost), 6),
                cost_stdev=round(_pstdev(per_task_cost), 6),
            )
        )
    return out
