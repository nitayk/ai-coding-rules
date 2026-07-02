"""Tests for arms.py — arm-profile resolution + config loading."""
from __future__ import annotations

import json

import pytest

import arms
from arms import MAT_PLUGIN_KEY


def test_default_arms_are_mat_off_and_on():
    a = arms.DEFAULT_ARMS["A"]
    b = arms.DEFAULT_ARMS["B"]
    assert a.plugin_overrides == {MAT_PLUGIN_KEY: False}   # MAT off
    assert b.plugin_overrides == {}                        # MAT on (ambient)
    assert a.inject_skills_from is None and b.inject_skills_from is None


def test_resolve_builtin_arms():
    table = arms.resolve_arms(["A", "B"])
    assert set(table) == {"A", "B"}


def test_resolve_unknown_arm_raises():
    with pytest.raises(KeyError, match="unknown arm"):
        arms.resolve_arms(["nope"])


def test_load_and_resolve_custom_arms(tmp_path):
    cfg = tmp_path / "arms.json"
    cfg.write_text(json.dumps({
        "bare": {"plugin_overrides": {MAT_PLUGIN_KEY: False}},
        "mat": {"plugin_overrides": {}},
        "aas": {"plugin_overrides": {MAT_PLUGIN_KEY: False},
                "inject_skills_from": "/some/skills"},
    }))
    table = arms.resolve_arms(["bare", "mat", "aas"], str(cfg))
    assert table["bare"].plugin_overrides == {MAT_PLUGIN_KEY: False}
    assert table["mat"].plugin_overrides == {}
    assert table["aas"].inject_skills_from == "/some/skills"
    # built-ins still resolvable alongside a custom config
    assert "A" in arms.resolve_arms(["A", "aas"], str(cfg))


def test_load_arms_rejects_non_object(tmp_path):
    bad = tmp_path / "bad.json"
    bad.write_text("[1, 2, 3]")
    with pytest.raises(ValueError):
        arms.load_arms(str(bad))
