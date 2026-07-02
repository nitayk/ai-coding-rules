"""Scatter-plot data + rendering.

`plot_points` is a PURE function (no matplotlib) returning one marker dict per
(arm × model). `render` draws the scatter and is the ONLY place matplotlib is
imported — lazily, inside the function — so this module imports and all plot-DATA
tests run on an interpreter without matplotlib installed.

To actually render the PNG: `pip install matplotlib`.
"""
from __future__ import annotations

from models import ArmModelStats


def plot_points(stats: list[ArmModelStats]) -> list[dict]:
    """One marker per (arm × model): x=$/task, y=resolution, ex/ey = ±1σ half-widths."""
    return [
        {
            "label": s.label,
            "x": s.mean_cost_per_task,
            "y": s.resolution_rate,
            "ex": s.cost_stdev,
            "ey": s.resolution_stdev,
        }
        for s in stats
    ]


def render(points: list[dict], out_path: str) -> str:
    """Render the scatter with an axis-aligned ±1σ ellipse per point; save PNG.

    The ellipse is axis-aligned (no covariance, no rotation): width = 2·ex,
    height = 2·ey, centered at (x, y). matplotlib is imported lazily here.
    """
    try:
        import matplotlib

        matplotlib.use("Agg")  # headless: no display required
        import matplotlib.pyplot as plt
        from matplotlib.patches import Ellipse
    except ImportError as e:  # pragma: no cover - exercised only without matplotlib
        raise ImportError(
            "rendering the PNG requires matplotlib; install it with "
            "`pip install matplotlib` (it is intentionally NOT a hard dependency)"
        ) from e

    fig, ax = plt.subplots(figsize=(7, 5))
    for p in points:
        ax.scatter([p["x"]], [p["y"]], s=40, zorder=3)
        ax.annotate(p["label"], (p["x"], p["y"]),
                    textcoords="offset points", xytext=(6, 6), fontsize=8)
        ax.add_patch(
            Ellipse(
                (p["x"], p["y"]),
                width=2 * p["ex"],
                height=2 * p["ey"],
                alpha=0.18,
                zorder=1,
            )
        )
    ax.set_xlabel("$ per task")
    ax.set_ylabel("resolution rate")
    ax.set_title("harness-bench: resolution vs cost (±1σ)")
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    fig.savefig(out_path, dpi=120)
    plt.close(fig)
    return out_path
