"""Data model for harness-bench.

Plain dataclasses shared across the parse / judge / aggregate / plot layers, kept
free of logic-heavy methods so they stay trivially serializable to/from JSON. The
only behavior here is light derivation (token totals, a stable label).
"""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class Judge:
    """One deterministic grader.

    type: "pytest" | "grep" | "build".
      - pytest / build: `command` is a shell command; pass iff exit 0.
      - grep: pass iff `pattern` (a regex) is found in any of `files`.
    """

    type: str
    command: str | None = None        # pytest / build
    pattern: str | None = None        # grep
    files: list[str] = field(default_factory=list)  # grep


@dataclass
class ArmProfile:
    """One benchmark arm = a Claude Code configuration to hold against the others.

    plugin_overrides: enabledPlugins entries to force (key -> bool) via --settings,
      e.g. {"mobile-agent-toolkit@mobile-agent-toolkit": False} for a MAT-off arm.
      Empty = use ambient config unchanged.
    inject_skills_from: optional path whose immediate subdirectories (skill packages
      with a SKILL.md) are copied into the cloned repo's .claude/skills/ before the
      run — the mechanism for testing a tool-agnostic SKILL.md library (e.g.
      ai-agent-skills) that is not installed as a plugin.
    """

    name: str
    plugin_overrides: dict[str, bool] = field(default_factory=dict)
    inject_skills_from: str | None = None


@dataclass
class TaskSpec:
    """A single benchmark task, pinned to a base commit, with its judges."""

    name: str
    repo: str
    base_commit: str
    prompt: str
    judges: list[Judge] = field(default_factory=list)


@dataclass
class RunRecord:
    """The outcome of one (arm × model × task × run_idx) execution."""

    arm: str
    model: str
    task: str
    run_idx: int
    passed: bool
    input_tokens: int
    output_tokens: int
    cost_usd: float
    error: str | None = None

    @property
    def total_tokens(self) -> int:
        return self.input_tokens + self.output_tokens


@dataclass
class ArmModelStats:
    """Aggregated stats for one (arm × model) cell — one marker on the scatter."""

    arm: str
    model: str
    n_runs: int
    n_tasks: int
    resolution_rate: float
    resolution_stdev: float
    mean_tokens_per_task: float
    tokens_stdev: float
    mean_cost_per_task: float
    cost_stdev: float

    @property
    def label(self) -> str:
        return f"{self.arm}/{self.model}"
