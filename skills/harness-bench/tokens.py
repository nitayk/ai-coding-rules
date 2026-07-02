"""Token usage parsing + cost pricing.

`parse_usage` reads the shape `claude -p --output-format json` emits: a top-level
`usage` object carrying `input_tokens` / `output_tokens` (plus cache fields we don't
bill here). Missing/None fields degrade to 0 so a partial blob never crashes a run.

NOTE: cache tokens (`cache_creation_input_tokens` / `cache_read_input_tokens`) are
deliberately EXCLUDED from cost — they are billed at different rates in reality, so
an operator wiring real published rates into PRICING should revisit this if precise
$/task accounting (vs the layer-vs-layer comparison this tool exists for) matters.

PRICING is operator-editable: the numbers below are PLACEHOLDER per-million-token
rates ($/1M input, $/1M output). Update them to the real published rates before
trusting any $/task number — they are estimates, not authoritative.
"""
from __future__ import annotations

# Operator-editable placeholder rates: (input $/1M, output $/1M).
# These are ESTIMATES — replace with the real published rates before reporting cost.
PRICING: dict[str, tuple[float, float]] = {
    "claude-opus-4-8": (15.0, 75.0),
    "claude-sonnet-4-6": (3.0, 15.0),
}


def _as_int(value) -> int:
    """Coerce a usage field to a non-negative int; None/missing/garbage -> 0."""
    try:
        if value is None:
            return 0
        return max(0, int(value))
    except (TypeError, ValueError):
        return 0


def parse_usage(claude_json: dict) -> tuple[int, int]:
    """Extract (input_tokens, output_tokens) from a `claude -p --output-format json` blob.

    Tolerant of a missing or None `usage` object and missing/None subfields.
    """
    usage = (claude_json or {}).get("usage")
    if not isinstance(usage, dict):
        return (0, 0)
    return (_as_int(usage.get("input_tokens")), _as_int(usage.get("output_tokens")))


def cost_for(model: str, in_tok: int, out_tok: int) -> float:
    """$ cost for a run given input/output token counts. Unknown model -> KeyError.

    NOTE: this uses ONLY input/output tokens against the placeholder PRICING table,
    so it EXCLUDES cache tokens — which in practice dominate real spend (a live
    `claude -p` run bills mostly on cache_creation/cache_read). Prefer
    `cost_from_blob` for live runs, which uses Claude's own authoritative number.
    """
    try:
        in_rate, out_rate = PRICING[model]
    except KeyError:
        raise KeyError(
            f"no pricing for model {model!r}; add it to tokens.PRICING "
            f"(known: {', '.join(sorted(PRICING))})"
        ) from None
    return in_tok / 1_000_000 * in_rate + out_tok / 1_000_000 * out_rate


def cost_from_blob(blob: dict, model: str) -> float:
    """Authoritative run cost from a `claude -p --output-format json` blob.

    Claude reports `total_cost_usd` (which already accounts for cache_creation /
    cache_read tokens — the bulk of real spend). Use it when present; fall back to
    the placeholder-table `cost_for` (input/output only) when it's missing.
    """
    raw = (blob or {}).get("total_cost_usd")
    if isinstance(raw, (int, float)) and raw >= 0:
        return float(raw)
    in_tok, out_tok = parse_usage(blob)
    return cost_for(model, in_tok, out_tok)
