"""Dependency preflight — what harness-bench needs, what's missing, how to fix it.

Tiers:
  demo  — required to run the no-cost dry-run (`bench.py demo`) and the test suite.
  live  — additionally required for a real (paid) burn (`bench.py run`).
  plot  — optional, only to render the PNG scatter (`bench.py plot`).

`cmd_doctor` (in bench.py) prints these and tells the operator exactly what to install.
"""
from __future__ import annotations

import importlib.util
import os
import shutil
import sys
from dataclasses import dataclass


@dataclass
class Check:
    name: str
    tier: str       # "demo" | "live" | "plot"
    ok: bool
    detail: str
    fix: str        # how to satisfy it when missing


def _has_module(mod: str) -> bool:
    try:
        return importlib.util.find_spec(mod) is not None
    except (ImportError, ValueError):
        return False


def preflight() -> list[Check]:
    """Inspect the environment and return one Check per dependency."""
    py_ok = sys.version_info >= (3, 10)
    return [
        Check("python >= 3.10", "demo", py_ok, f"running {sys.version.split()[0]}",
              "run with python3.12, e.g. `python3.12 bench.py demo`"),
        Check("pyyaml", "demo", _has_module("yaml"), "parses YAML task specs",
              "pip install pyyaml  (or: python3.12 -m pip install pyyaml)"),
        Check("matplotlib", "plot", _has_module("matplotlib"),
              "renders the PNG scatter (optional)",
              "pip install matplotlib — plotting only; demo/run print a table without it"),
        Check("claude CLI", "live", shutil.which("claude") is not None,
              shutil.which("claude") or "not on PATH",
              "install Claude Code — needed only for live burns, not for demo"),
        Check("HARNESS_BENCH_LIVE=1", "live", os.environ.get("HARNESS_BENCH_LIVE") == "1",
              "gate that permits real (paid) agent runs",
              "export HARNESS_BENCH_LIVE=1 before `bench.py run` (real $ spend)"),
    ]


def demo_ready(checks: list[Check]) -> bool:
    """True if the no-cost dry-run + tests can run."""
    return all(c.ok for c in checks if c.tier == "demo")


def live_ready(checks: list[Check]) -> bool:
    """True if a real burn can run (demo deps + claude CLI + the gate)."""
    return demo_ready(checks) and all(c.ok for c in checks if c.tier == "live")
