"""Tests for tasks.py — YAML task spec loading + validation."""
from __future__ import annotations

from pathlib import Path

import pytest

import tasks as tasks_mod

TASKS_DIR = Path(__file__).resolve().parent.parent / "example_tasks"


def test_load_all_shipped_tasks():
    specs = tasks_mod.load_tasks(TASKS_DIR)
    names = {s.name for s in specs}
    assert names == {
        "codegraph_detector_fix",
        "typed_config_bugfix",
        "small_refactor",
    }


def test_loaded_task_fields():
    spec = tasks_mod.load_task(TASKS_DIR / "small_refactor.yaml")
    assert spec.name == "small_refactor"
    assert spec.repo
    assert spec.base_commit
    assert spec.prompt.strip()
    # small_refactor has a build judge AND a grep judge
    types = [j.type for j in spec.judges]
    assert "build" in types and "grep" in types
    grep = next(j for j in spec.judges if j.type == "grep")
    assert grep.pattern == "function redactSecrets"
    assert grep.files


def test_malformed_spec_raises_valueerror(tmp_path):
    bad = tmp_path / "bad.yaml"
    bad.write_text("name: nope\n")  # missing repo, base_commit, prompt, judges
    with pytest.raises(ValueError):
        tasks_mod.load_task(bad)


def test_unknown_judge_type_raises_valueerror(tmp_path):
    bad = tmp_path / "bad2.yaml"
    bad.write_text(
        "name: x\nrepo: https://x/y\nbase_commit: abc1234\nprompt: p\n"
        "judges:\n  - type: telepathy\n"
    )
    with pytest.raises(ValueError, match="unknown judge type"):
        tasks_mod.load_task(bad)


def test_invalid_repo_raises_valueerror(tmp_path):
    bad = tmp_path / "bad_repo.yaml"
    bad.write_text(
        "name: x\nrepo: -upload-pack=evil\nbase_commit: abc1234\nprompt: p\n"
        "judges:\n  - type: build\n    command: make\n"
    )
    with pytest.raises(ValueError, match="repo"):
        tasks_mod.load_task(bad)


def test_invalid_base_commit_raises_valueerror(tmp_path):
    bad = tmp_path / "bad_commit.yaml"
    bad.write_text(
        "name: x\nrepo: https://x/y\nbase_commit: -b evilbranch\nprompt: p\n"
        "judges:\n  - type: build\n    command: make\n"
    )
    with pytest.raises(ValueError, match="base_commit"):
        tasks_mod.load_task(bad)
