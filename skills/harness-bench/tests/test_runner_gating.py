"""Tests for runners.py — live gating + deterministic seeded replay."""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from models import ArmProfile, RunRecord, TaskSpec
from runners import ClaudeCodeRunner, SeededRunner, MAT_PLUGIN_KEY


def test_arm_a_disables_mat_plugin_explicitly():
    # ARM A must set the MAT plugin key to FALSE (an empty map is a no-op that
    # disables nothing — enabledPlugins merges per-key). ARM B passes no override.
    r = ClaudeCodeRunner()
    a_args = r._settings_args("A")
    assert a_args[0] == "--settings"
    settings = json.loads(a_args[1])
    assert settings["enabledPlugins"][MAT_PLUGIN_KEY] is False
    assert r._settings_args("B") == []


def test_custom_arm_settings_from_profile():
    # a runner built with custom arm profiles emits each arm's plugin_overrides
    arms = {
        "bare": ArmProfile("bare", {MAT_PLUGIN_KEY: False}),
        "mat": ArmProfile("mat", {}),
        "aas": ArmProfile("aas", {MAT_PLUGIN_KEY: False}, inject_skills_from="/x"),
    }
    r = ClaudeCodeRunner(arms=arms)
    assert json.loads(r._settings_args("bare")[1])["enabledPlugins"][MAT_PLUGIN_KEY] is False
    assert r._settings_args("mat") == []
    assert json.loads(r._settings_args("aas")[1])["enabledPlugins"][MAT_PLUGIN_KEY] is False


def test_inject_skills_copies_packages(tmp_path):
    # build a fake skill library: two packages each with a SKILL.md
    src = tmp_path / "lib"
    for name in ("debug-workflow", "tdd-workflow"):
        (src / name).mkdir(parents=True)
        (src / name / "SKILL.md").write_text(f"# {name}\n")
    (src / "not-a-dir.txt").write_text("ignored")
    workdir = tmp_path / "clone"
    workdir.mkdir()
    n = ClaudeCodeRunner._inject_skills(str(workdir), str(src))
    assert n == 2
    assert (workdir / ".claude" / "skills" / "debug-workflow" / "SKILL.md").exists()
    assert (workdir / ".claude" / "skills" / "tdd-workflow" / "SKILL.md").exists()

FIXTURES = Path(__file__).resolve().parent.parent / "fixtures"


def test_claude_runner_refuses_without_gate(monkeypatch):
    monkeypatch.delenv("HARNESS_BENCH_LIVE", raising=False)
    runner = ClaudeCodeRunner()
    task = TaskSpec(name="t", repo="r", base_commit="c", prompt="p", judges=[])
    with pytest.raises(RuntimeError, match="gated"):
        runner.run(task, arm="A", model="claude-opus-4-8")


def test_claude_runner_gate_via_env_does_not_raise_gate_error(monkeypatch):
    # With the gate set, run() must get PAST the gate check. Stub subprocess.run so
    # the test proves the gate opened WITHOUT forking git/claude — the stub raises a
    # sentinel as soon as the first subprocess (git clone) would have run.
    monkeypatch.setenv("HARNESS_BENCH_LIVE", "1")

    def _sentinel(*a, **k):
        raise RuntimeError("SENTINEL_past_gate")

    monkeypatch.setattr("runners.subprocess.run", _sentinel)
    runner = ClaudeCodeRunner()
    task = TaskSpec(name="t", repo="r", base_commit="c", prompt="p", judges=[])
    with pytest.raises(RuntimeError, match="SENTINEL_past_gate"):
        runner.run(task, arm="A", model="claude-opus-4-8")


def test_seeded_runner_replays_fixture_deterministically():
    raw = json.loads((FIXTURES / "seeded_results.json").read_text())
    records = [RunRecord(**r) for r in raw]
    runner = SeededRunner(records)
    task = TaskSpec(name="kafka_detector_fix", repo="r", base_commit="c",
                    prompt="p", judges=[])
    r0 = runner.run(task, arm="A", model="claude-opus-4-8")
    assert isinstance(r0, RunRecord)
    assert r0.arm == "A"
    assert r0.model == "claude-opus-4-8"
    assert r0.task == "kafka_detector_fix"
    # replay is deterministic: a second full pass returns identical records
    again = runner.run(task, arm="A", model="claude-opus-4-8")
    assert (again.arm, again.model, again.task) == (r0.arm, r0.model, r0.task)
