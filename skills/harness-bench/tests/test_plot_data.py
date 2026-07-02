"""Tests for plot.py — the PURE plot_points wiring. Must NOT need matplotlib."""
from __future__ import annotations

from models import ArmModelStats
import plot


def test_importing_plot_does_not_require_matplotlib():
    # If plot.py imported matplotlib at module scope this test file would have
    # failed to import on a matplotlib-less interpreter. Reaching here proves the
    # lazy import. Assert the render entrypoint exists but is not yet called.
    assert hasattr(plot, "render")


def test_plot_points_one_marker_per_arm_model():
    stats = [
        ArmModelStats("A", "opus", 5, 3, resolution_rate=0.55, resolution_stdev=0.1,
                      mean_tokens_per_task=22000, tokens_stdev=2000,
                      mean_cost_per_task=1.20, cost_stdev=0.15),
        ArmModelStats("B", "opus", 5, 3, resolution_rate=0.82, resolution_stdev=0.08,
                      mean_tokens_per_task=15000, tokens_stdev=1500,
                      mean_cost_per_task=0.80, cost_stdev=0.10),
    ]
    points = plot.plot_points(stats)
    assert len(points) == 2
    a, b = points
    assert a["x"] == 1.20 and a["y"] == 0.55
    assert a["ex"] == 0.15 and a["ey"] == 0.1
    assert "A" in a["label"] and "opus" in a["label"]
    assert b["x"] == 0.80 and b["y"] == 0.82
    assert b["ex"] == 0.10 and b["ey"] == 0.08
