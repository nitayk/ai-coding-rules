"""Tests for preflight.py — dependency checks + readiness gates."""
from __future__ import annotations

import preflight
from preflight import Check


def test_preflight_reports_core_deps():
    checks = preflight.preflight()
    names = {c.name for c in checks}
    assert "python >= 3.10" in names
    assert "pyyaml" in names
    assert "matplotlib" in names
    assert "claude CLI" in names
    # every check carries a fix hint for when it's missing
    assert all(c.fix for c in checks)


def test_demo_ready_true_when_demo_tier_ok():
    checks = [
        Check("python >= 3.10", "demo", True, "", "x"),
        Check("pyyaml", "demo", True, "", "x"),
        Check("claude CLI", "live", False, "", "x"),   # live missing must not block demo
        Check("matplotlib", "plot", False, "", "x"),   # plot missing must not block demo
    ]
    assert preflight.demo_ready(checks) is True
    assert preflight.live_ready(checks) is False        # live dep missing


def test_demo_not_ready_when_demo_dep_missing():
    checks = [
        Check("python >= 3.10", "demo", True, "", "x"),
        Check("pyyaml", "demo", False, "", "pip install pyyaml"),
    ]
    assert preflight.demo_ready(checks) is False


def test_live_ready_requires_demo_and_live():
    checks = [
        Check("python >= 3.10", "demo", True, "", "x"),
        Check("pyyaml", "demo", True, "", "x"),
        Check("claude CLI", "live", True, "", "x"),
        Check("HARNESS_BENCH_LIVE=1", "live", True, "", "x"),
    ]
    assert preflight.live_ready(checks) is True
