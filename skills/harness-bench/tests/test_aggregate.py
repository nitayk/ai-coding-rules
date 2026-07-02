"""Tests for aggregate.py — best-of-then-mean resolution + stdev math + grouping."""
from __future__ import annotations

import json
from pathlib import Path

from models import RunRecord
import aggregate

FIXTURES = Path(__file__).resolve().parent.parent / "fixtures"


def _load_seeded() -> list[RunRecord]:
    raw = json.loads((FIXTURES / "seeded_results.json").read_text())
    return [RunRecord(**r) for r in raw]


def test_grouping_yields_one_stats_per_arm_model():
    records = _load_seeded()
    stats = aggregate.aggregate(records)
    keys = {(s.arm, s.model) for s in stats}
    assert keys == {
        ("A", "claude-opus-4-8"),
        ("A", "claude-sonnet-4-6"),
        ("B", "claude-opus-4-8"),
        ("B", "claude-sonnet-4-6"),
    }


def test_resolution_is_best_of_then_mean():
    # 1 arm/model, 2 tasks. Task1: any pass -> 1.0. Task2: all fail -> 0.0.
    # best-of per task = [1.0, 0.0]; mean across tasks = 0.5
    recs = [
        RunRecord("A", "m", "t1", 0, False, 100, 10, 0.1),
        RunRecord("A", "m", "t1", 1, True, 100, 10, 0.1),
        RunRecord("A", "m", "t2", 0, False, 100, 10, 0.1),
        RunRecord("A", "m", "t2", 1, False, 100, 10, 0.1),
    ]
    stats = aggregate.aggregate(recs)
    assert len(stats) == 1
    assert stats[0].resolution_rate == 0.5


def test_stdev_guard_single_run_is_zero():
    # one task, one run -> pstdev over a single value must be 0, not a crash
    recs = [RunRecord("A", "m", "t1", 0, True, 100, 10, 0.5)]
    stats = aggregate.aggregate(recs)
    assert stats[0].resolution_stdev == 0.0
    assert stats[0].cost_stdev == 0.0


def test_resolution_stdev_is_run_to_run_not_per_task():
    # 3 tasks x 2 runs. Per-run resolution is identical across runs (both 2/3),
    # so the run-to-run band MUST be 0.0 — even though per-task pass-rates vary
    # ([1.0, 0.5, 0.5]) and the OLD per-task-passrate band would have been ~0.236.
    recs = [
        RunRecord("A", "m", "t1", 0, True, 100, 10, 0.1),
        RunRecord("A", "m", "t1", 1, True, 100, 10, 0.1),
        RunRecord("A", "m", "t2", 0, True, 100, 10, 0.1),
        RunRecord("A", "m", "t2", 1, False, 100, 10, 0.1),
        RunRecord("A", "m", "t3", 0, False, 100, 10, 0.1),
        RunRecord("A", "m", "t3", 1, True, 100, 10, 0.1),
    ]
    stats = aggregate.aggregate(recs)
    # run0 resolution = mean(t1=1, t2=1, t3=0) = 2/3; run1 = mean(1, 0, 1) = 2/3
    assert stats[0].resolution_stdev == 0.0
    # best-of: t1=1, t2=1, t3=1 -> resolution 1.0 (the marker is unaffected)
    assert stats[0].resolution_rate == 1.0


def test_cost_and_token_means():
    recs = [
        RunRecord("A", "m", "t1", 0, True, 100, 10, 0.20),
        RunRecord("A", "m", "t1", 1, True, 300, 30, 0.40),
    ]
    stats = aggregate.aggregate(recs)
    s = stats[0]
    # one task: mean per-task cost = mean of the per-run costs for that task
    assert s.mean_cost_per_task == 0.30
    assert s.mean_tokens_per_task == 220.0  # (110 + 330) / 2


def test_run_matrix_isolates_per_run_errors():
    from runners import SeededRunner
    records = _load_seeded()
    runner = SeededRunner(records)
    out = aggregate.run_matrix(
        runner,
        tasks=[type("T", (), {"name": "codegraph_detector_fix"})()],
        arms=["A", "B"],
        models=["claude-opus-4-8"],
        n_runs=5,
    )
    # 2 arms x 1 model x 1 task x 5 runs = 10 records, none aborted
    assert len(out) == 10
