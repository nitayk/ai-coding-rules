"""Tests for tokens.py — usage parsing, pricing, and cost math."""
from __future__ import annotations

import json
from pathlib import Path

import pytest

import tokens

FIXTURES = Path(__file__).resolve().parent.parent / "fixtures"


def test_parse_usage_from_sample_blob():
    blob = json.loads((FIXTURES / "sample_claude_output.json").read_text())
    in_tok, out_tok = tokens.parse_usage(blob)
    assert in_tok == 18234
    assert out_tok == 4096


def test_parse_usage_missing_usage_returns_zeros():
    assert tokens.parse_usage({}) == (0, 0)
    assert tokens.parse_usage({"usage": None}) == (0, 0)
    assert tokens.parse_usage({"usage": {"input_tokens": None}}) == (0, 0)


def test_cost_for_opus():
    # placeholder rates: opus = ($15/1M in, $75/1M out)
    cost = tokens.cost_for("claude-opus-4-8", 1_000_000, 1_000_000)
    assert cost == pytest.approx(15.0 + 75.0)


def test_cost_for_sonnet():
    # placeholder rates: sonnet = ($3/1M in, $15/1M out)
    cost = tokens.cost_for("claude-sonnet-4-6", 2_000_000, 1_000_000)
    assert cost == pytest.approx(6.0 + 15.0)


def test_cost_for_unknown_model_raises_keyerror():
    with pytest.raises(KeyError):
        tokens.cost_for("gpt-9", 1000, 1000)


def test_cost_from_blob_prefers_total_cost_usd():
    # the authoritative number wins, even when it dwarfs the input/output-only
    # estimate (real spend is dominated by cache tokens cost_for cannot see)
    blob = {"total_cost_usd": 0.0746,
            "usage": {"input_tokens": 3, "output_tokens": 4}}
    assert tokens.cost_from_blob(blob, "claude-sonnet-4-6") == pytest.approx(0.0746)


def test_cost_from_blob_falls_back_when_missing():
    # no total_cost_usd -> fall back to the placeholder input/output estimate
    blob = {"usage": {"input_tokens": 1_000_000, "output_tokens": 1_000_000}}
    assert tokens.cost_from_blob(blob, "claude-opus-4-8") == pytest.approx(90.0)
