"""Deterministic graders: pytest, grep, build.

The subprocess-invoking graders (pytest/build) accept an injectable `runner`
(default `subprocess.run`) so tests pass a fake and never shell out. The grep
grader reads files directly (no shell), so it is naturally testable on a tmp dir.

TRUST MODEL: judge `command` strings come from operator-authored task specs and are
executed (via `shlex.split` + `subprocess.run`, `shell=False` — no shell injection,
but arbitrary processes by design). Only run task specs you trust. The grep grader
confines its file reads to the working directory (no absolute-path / `..` escape).
"""
from __future__ import annotations

import re
import shlex
import subprocess
from pathlib import Path
from typing import Callable

from models import Judge, TaskSpec

Runner = Callable[..., "subprocess.CompletedProcess"]


def _run_command(command: str, workdir: str, runner: Runner) -> bool:
    """Pass iff the command exits 0. cwd = workdir."""
    proc = runner(shlex.split(command), cwd=workdir, capture_output=True, text=True)
    return proc.returncode == 0


def _grep(judge: Judge, workdir: str) -> bool:
    """Pass iff the regex pattern is found in ANY listed file (read directly)."""
    pattern = re.compile(judge.pattern)
    base = Path(workdir).resolve()
    for rel in judge.files:
        # confine reads to the workdir: reject absolute paths and `..` escapes so a
        # task spec cannot grep /etc/passwd or ../../secrets.
        resolved = (base / rel).resolve()
        if base != resolved and base not in resolved.parents:
            continue
        try:
            text = resolved.read_text()
        except (FileNotFoundError, OSError):
            continue
        if pattern.search(text):
            return True
    return False


def run_judge(judge: Judge, workdir: str, runner: Runner | None = None) -> bool:
    """Evaluate a single judge against a working directory."""
    runner = runner or subprocess.run
    if judge.type == "grep":
        return _grep(judge, workdir)
    if judge.type in ("pytest", "build"):
        return _run_command(judge.command, workdir, runner)
    raise ValueError(f"unknown judge type: {judge.type!r}")


def judge_run(task: TaskSpec, workdir: str, runner: Runner | None = None) -> bool:
    """A run passes iff ALL of the task's judges pass (AND semantics)."""
    return all(run_judge(j, workdir, runner) for j in task.judges)
