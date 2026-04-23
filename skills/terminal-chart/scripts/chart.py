#!/usr/bin/env python3
"""
Terminal chart renderer with ANSI colors and theme-aware brightness.

Usage:
    python chart.py [options] < data.json
    echo '<json>' | python chart.py [options]

Input: JSON object with keys:
    title       (str)     Chart title
    subtitle    (str)     Optional subtitle
    type        (str)     "bar" (default), "sparkline", "heatmap", "table"
    data        (list)    List of row objects (see chart type docs)
    columns     (list)    Column definitions for table type
    value_key   (str)     Key in data for bar values (default: "value")
    label_key   (str)     Key in data for labels (default: "label")
    detail_keys (list)    Additional keys to show as columns beside the bar
    sort        (str)     "desc" (default), "asc", "none"
    limit       (int)     Max rows to show (default: 30)
    summary     (list)    Optional summary lines shown below chart
    value_format(str)     "auto" (default), "number", "money", "percent", "bytes"
    bar_width   (int)     Bar width in characters (default: 40)

Options:
    --theme dark|light|auto   Force theme (default: auto-detect)
    --no-color                Disable colors
    --compact                 Reduce vertical spacing
"""

import json
import subprocess
import sys
import argparse
import os
from collections import defaultdict


# ── Theme detection ──────────────────────────────────────────────────────────

def detect_theme():
    """Auto-detect dark/light terminal theme."""
    # Check environment override
    env = os.environ.get("TERMINAL_THEME", "").lower()
    if env in ("dark", "light"):
        return env

    # macOS: check system appearance
    try:
        result = subprocess.run(
            ["defaults", "read", "-g", "AppleInterfaceStyle"],
            capture_output=True, text=True, timeout=2
        )
        if result.returncode == 0 and "Dark" in result.stdout:
            return "dark"
        return "light"
    except Exception:
        pass

    # Default to dark (most common for terminals)
    return "dark"


# ── Color palettes ───────────────────────────────────────────────────────────

RST  = "\033[0m"
DIM  = "\033[2m"

PALETTES = {
    "dark": {
        "title":    "\033[1;38;5;147m",
        "border":   "\033[38;5;240m",
        "label":    "\033[38;5;252m",
        "header":   "\033[1;38;5;75m",
        "accent":   "\033[38;5;220m",
        "subtle":   "\033[38;5;243m",
        "gradient": [
            "\033[38;5;196m", "\033[38;5;208m", "\033[38;5;214m",
            "\033[38;5;220m", "\033[38;5;154m", "\033[38;5;114m",
            "\033[38;5;79m",  "\033[38;5;75m",  "\033[38;5;69m",
            "\033[38;5;63m",
        ],
        "heatmap": [
            "\033[48;5;232m", "\033[48;5;233m", "\033[48;5;234m",
            "\033[48;5;52m",  "\033[48;5;88m",  "\033[48;5;124m",
            "\033[48;5;160m", "\033[48;5;196m", "\033[48;5;208m",
            "\033[48;5;220m",
        ],
    },
    "light": {
        "title":    "\033[1;38;5;55m",
        "border":   "\033[38;5;249m",
        "label":    "\033[38;5;236m",
        "header":   "\033[1;38;5;25m",
        "accent":   "\033[38;5;130m",
        "subtle":   "\033[38;5;245m",
        "gradient": [
            "\033[38;5;160m", "\033[38;5;166m", "\033[38;5;172m",
            "\033[38;5;136m", "\033[38;5;64m",  "\033[38;5;28m",
            "\033[38;5;30m",  "\033[38;5;25m",  "\033[38;5;54m",
            "\033[38;5;90m",
        ],
        "heatmap": [
            "\033[48;5;255m", "\033[48;5;254m", "\033[48;5;253m",
            "\033[48;5;224m", "\033[48;5;217m", "\033[48;5;210m",
            "\033[48;5;203m", "\033[48;5;196m", "\033[48;5;160m",
            "\033[48;5;124m",
        ],
    },
}


# ── Formatting helpers ───────────────────────────────────────────────────────

BLOCKS = [" ", "\u258f", "\u258e", "\u258d", "\u258c", "\u258b", "\u258a", "\u2589", "\u2588"]

def fmt_value(val, fmt="auto"):
    """Format a numeric value for display."""
    if val is None:
        return "—"
    if isinstance(val, str):
        return val

    if fmt == "auto":
        fmt = "number"

    if fmt == "money":
        if abs(val) >= 1_000_000_000:
            return f"${val/1_000_000_000:.1f}B"
        if abs(val) >= 999_500:
            return f"${val/1_000_000:.1f}M"
        if abs(val) >= 1_000:
            return f"${val/1_000:,.0f}K"
        return f"${val:,.2f}"

    if fmt == "percent":
        return f"{val:.1f}%"

    if fmt == "bytes":
        for unit in ["B", "KB", "MB", "GB", "TB"]:
            if abs(val) < 1024:
                return f"{val:.1f}{unit}"
            val /= 1024
        return f"{val:.1f}PB"

    # number (auto)
    if abs(val) >= 1_000_000_000:
        return f"{val/1_000_000_000:.1f}B"
    if abs(val) >= 999_500:
        return f"{val/1_000_000:.1f}M"
    if abs(val) >= 1_000:
        return f"{val/1_000:,.0f}K"
    if isinstance(val, float):
        return f"{val:,.2f}"
    return f"{val:,}"


def gradient_color(idx, total, palette):
    """Pick a gradient color based on rank position."""
    g = palette["gradient"]
    bucket = int((idx / max(total - 1, 1)) * (len(g) - 1))
    return g[bucket]


def heatmap_color(val, min_val, max_val, palette):
    """Pick a heatmap background color based on value intensity."""
    h = palette["heatmap"]
    if max_val == min_val:
        return h[0]
    ratio = (val - min_val) / (max_val - min_val)
    bucket = int(ratio * (len(h) - 1))
    return h[bucket]


def build_bar(val, max_val, width):
    """Build a fractional bar string."""
    if max_val == 0:
        return " " * width
    exact = (val / max_val) * width
    full = int(exact)
    frac = exact - full
    partial_idx = int(frac * 8)
    bar = "\u2588" * full + BLOCKS[partial_idx]
    return bar.ljust(width)


def W(s):
    sys.stdout.write(s)


# ── Chart renderers ──────────────────────────────────────────────────────────

def render_bar(spec, palette, no_color, compact, theme="dark"):
    """Render a horizontal bar chart."""
    data = spec["data"]
    value_key = spec.get("value_key", "value")
    label_key = spec.get("label_key", "label")
    detail_keys = spec.get("detail_keys", [])
    value_format = spec.get("value_format", "auto")
    bar_width = spec.get("bar_width", 40)
    sort = spec.get("sort", "desc")
    limit = spec.get("limit", 30)

    # Sort
    if sort == "desc":
        data = sorted(data, key=lambda r: r.get(value_key, 0) or 0, reverse=True)
    elif sort == "asc":
        data = sorted(data, key=lambda r: r.get(value_key, 0) or 0)
    data = data[:limit]

    if not data:
        W("  (no data)\n")
        return

    max_val = max(r.get(value_key, 0) or 0 for r in data)

    # Compute column widths
    labels = [str(r.get(label_key, "")) for r in data]
    label_w = max(len(l) for l in labels)
    val_strs = [fmt_value(r.get(value_key, 0), value_format) for r in data]
    val_w = max(len(v) for v in val_strs)

    detail_cols = []
    for dk in detail_keys:
        key = dk if isinstance(dk, str) else dk.get("key", "")
        name = dk if isinstance(dk, str) else dk.get("name", key)
        dfmt = "auto" if isinstance(dk, str) else dk.get("format", "auto")
        strs = [fmt_value(r.get(key), dfmt) for r in data]
        col_w = max(max(len(s) for s in strs), len(name))
        detail_cols.append({"key": key, "name": name, "format": dfmt, "strs": strs, "width": col_w})

    p = palette
    c = not no_color
    sep_w = label_w + 2 + val_w + sum(2 + dc['width'] for dc in detail_cols) + 2 + bar_width

    # Header
    hdr = f"{'':>{label_w}}  {'Value':>{val_w}}"
    for dc in detail_cols:
        hdr += f"  {dc['name']:>{dc['width']}}"
    hdr += f"  {'Distribution':<{bar_width}}"
    if not compact:
        W(f"  {p['header'] if c else ''}{hdr}{RST if c else ''}\n")
        W(f"  {p['border'] if c else ''}{'─' * sep_w}{RST if c else ''}\n")

    for i, row in enumerate(data):
        label = labels[i]
        val_str = val_strs[i]
        color = gradient_color(i, len(data), p) if c else ""
        bar = build_bar(row.get(value_key, 0) or 0, max_val, bar_width)

        line = f"  {p['label'] if c else ''}{label:>{label_w}}{RST if c else ''}"
        line += f"  {p['accent'] if c else ''}{val_str:>{val_w}}{RST if c else ''}"
        for dc in detail_cols:
            line += f"  {p['subtle'] if c else ''}{dc['strs'][i]:>{dc['width']}}{RST if c else ''}"
        line += f"  {color}{bar}{RST if c else ''}"
        W(line + "\n")

    if not compact:
        W(f"  {p['border'] if c else ''}{'─' * sep_w}{RST if c else ''}\n")


def render_heatmap(spec, palette, no_color, compact, theme="dark"):
    """Render a text-based heatmap grid."""
    data = spec["data"]
    row_key = spec.get("row_key", "row")
    col_key = spec.get("col_key", "col")
    value_key = spec.get("value_key", "value")
    value_format = spec.get("value_format", "auto")

    p = palette
    c = not no_color

    # Build grid
    rows_order = []
    cols_order = []
    grid = {}
    for d in data:
        r, co, v = d.get(row_key, ""), d.get(col_key, ""), d.get(value_key, 0)
        if r not in rows_order:
            rows_order.append(r)
        if co not in cols_order:
            cols_order.append(co)
        grid[(r, co)] = v

    all_vals = [v for v in grid.values() if v is not None]
    min_val = min(all_vals) if all_vals else 0
    max_val = max(all_vals) if all_vals else 0

    row_w = max(len(str(r)) for r in rows_order) if rows_order else 3
    col_w = max(max(len(str(co)) for co in cols_order), 6) if cols_order else 6

    # Column headers
    hdr = f"{'':>{row_w}}"
    for co in cols_order:
        hdr += f"  {str(co):>{col_w}}"
    W(f"  {p['header'] if c else ''}{hdr}{RST if c else ''}\n")

    for r in rows_order:
        line = f"  {p['label'] if c else ''}{str(r):>{row_w}}{RST if c else ''}"
        for co in cols_order:
            v = grid.get((r, co))
            val_str = fmt_value(v, value_format)
            bg = heatmap_color(v or 0, min_val, max_val, p) if c and v is not None else ""
            fg = ("\033[38;5;232m" if theme == "light" else "\033[38;5;231m") if c else ""
            line += f"  {bg}{fg}{val_str:>{col_w}}{RST if c else ''}"
        W(line + "\n")


def render_sparkline(spec, palette, no_color, compact, theme="dark"):
    """Render a sparkline trend chart: one row per series with an inline sparkline."""
    data = spec["data"]
    series_key = spec.get("series_key", "series")
    time_key = spec.get("time_key", "time")
    value_key = spec.get("value_key", "value")
    value_format = spec.get("value_format", "auto")
    sort = spec.get("sort", "desc")
    limit = spec.get("limit", 30)

    SPARKS = "\u2581\u2582\u2583\u2584\u2585\u2586\u2587\u2588"

    p = palette
    c = not no_color

    # Group data by series
    series_data = defaultdict(list)
    for r in data:
        series_data[r.get(series_key, "")].append(
            (r.get(time_key, ""), r.get(value_key, 0) or 0)
        )
    for s in series_data:
        series_data[s].sort(key=lambda x: x[0])

    # Compute totals and rank
    series_totals = {s: sum(v for _, v in vals) for s, vals in series_data.items()}
    if sort == "desc":
        ranked = sorted(series_totals.keys(), key=lambda s: -series_totals[s])
    elif sort == "asc":
        ranked = sorted(series_totals.keys(), key=lambda s: series_totals[s])
    else:
        ranked = list(series_data.keys())
    ranked = ranked[:limit]

    if not ranked:
        W("  (no data)\n")
        return

    # Build sparkline string
    def sparkline(values, color):
        mn, mx = min(values), max(values)
        rng = mx - mn if mx != mn else 1
        chars = "".join(
            SPARKS[int((v - mn) / rng * (len(SPARKS) - 1))] for v in values
        )
        return f"{color}{chars}{RST if c else ''}"

    # Compute column widths
    label_w = max(len(str(s)) for s in ranked)
    total_strs = {s: fmt_value(series_totals[s], value_format) for s in ranked}
    total_w = max(len(v) for v in total_strs.values())
    avg_strs = {s: fmt_value(series_totals[s] / len(series_data[s]), value_format) for s in ranked}
    avg_w = max(max(len(v) for v in avg_strs.values()), 7)
    min_strs = {s: fmt_value(min(v for _, v in series_data[s]), value_format) for s in ranked}
    min_w = max(max(len(v) for v in min_strs.values()), 3)
    max_strs = {s: fmt_value(max(v for _, v in series_data[s]), value_format) for s in ranked}
    max_w = max(max(len(v) for v in max_strs.values()), 3)

    # Time range labels
    all_times = sorted(set(r.get(time_key, "") for r in data))
    t_start = str(all_times[0]) if all_times else ""
    t_end = str(all_times[-1]) if all_times else ""
    # Shorten if they look like dates (YYYY-MM-DD → MM-DD)
    if len(t_start) == 10 and t_start[4] == "-":
        t_start = t_start[5:]
    if len(t_end) == 10 and t_end[4] == "-":
        t_end = t_end[5:]

    spark_width = len(all_times)

    # Header
    if not compact:
        hdr = f"{'':>{label_w}}  {'Total':>{total_w}}  {'Avg':>{avg_w}}  {'Min':>{min_w}}  {'Max':>{max_w}}  {t_start}{'Trend':^{max(spark_width - len(t_start) - len(t_end), 0)}}{t_end}"
        W(f"  {p['header'] if c else ''}{hdr}{RST if c else ''}\n")
        sep_w = label_w + 2 + total_w + 2 + avg_w + 2 + min_w + 2 + max_w + 2 + spark_width + len(t_start) + len(t_end)
        W(f"  {p['border'] if c else ''}{'─' * sep_w}{RST if c else ''}\n")

    for i, s in enumerate(ranked):
        vals = [v for _, v in series_data[s]]
        color = gradient_color(i, len(ranked), p) if c else ""
        spark = sparkline(vals, color)

        line = f"  {p['label'] if c else ''}{str(s):>{label_w}}{RST if c else ''}"
        line += f"  {p['accent'] if c else ''}{total_strs[s]:>{total_w}}{RST if c else ''}"
        line += f"  {p['subtle'] if c else ''}{avg_strs[s]:>{avg_w}}{RST if c else ''}"
        line += f"  {p['subtle'] if c else ''}{min_strs[s]:>{min_w}}{RST if c else ''}"
        line += f"  {p['subtle'] if c else ''}{max_strs[s]:>{max_w}}{RST if c else ''}"
        line += f"  {spark}"
        W(line + "\n")

    if not compact:
        sep_w = label_w + 2 + total_w + 2 + avg_w + 2 + min_w + 2 + max_w + 2 + spark_width + len(t_start) + len(t_end)
        W(f"  {p['border'] if c else ''}{'─' * sep_w}{RST if c else ''}\n")


def render_table(spec, palette, no_color, compact, theme="dark"):
    """Render a colored table."""
    data = spec["data"]
    columns = spec.get("columns", [])
    p = palette
    c = not no_color

    if not columns and data:
        columns = [{"key": k, "name": k} for k in data[0].keys()]

    # Compute column widths
    col_meta = []
    for col in columns:
        key = col if isinstance(col, str) else col.get("key", "")
        name = col if isinstance(col, str) else col.get("name", key)
        cfmt = "auto" if isinstance(col, str) else col.get("format", "auto")
        strs = [fmt_value(r.get(key), cfmt) for r in data]
        w = max(max((len(s) for s in strs), default=0), len(name))
        col_meta.append({"key": key, "name": name, "format": cfmt, "strs": strs, "width": w})

    # Header
    if not compact:
        hdr = "  "
        for cm in col_meta:
            hdr += f"{cm['name']:>{cm['width']}}  "
        W(f"  {p['header'] if c else ''}{hdr}{RST if c else ''}\n")
        sep = "  " + "  ".join("─" * cm['width'] for cm in col_meta)
        W(f"  {p['border'] if c else ''}{sep}{RST if c else ''}\n")

    for i, row in enumerate(data):
        line = "  "
        for cm in col_meta:
            line += f"{p['label'] if c else ''}{cm['strs'][i]:>{cm['width']}}{RST if c else ''}  "
        W(line + "\n")


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Terminal chart renderer")
    parser.add_argument("--theme", choices=["dark", "light", "auto"], default="auto")
    parser.add_argument("--no-color", action="store_true")
    parser.add_argument("--compact", action="store_true")
    args = parser.parse_args()

    theme = args.theme if args.theme != "auto" else detect_theme()
    palette = PALETTES[theme]
    no_color = args.no_color

    try:
        spec = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        sys.stderr.write(f"Error: invalid JSON input — {e}\n")
        sys.exit(1)
    chart_type = spec.get("type", "bar")
    title = spec.get("title", "")
    subtitle = spec.get("subtitle", "")
    summary = spec.get("summary", [])
    c = not no_color

    # Title block
    if title:
        W("\n")
        tw = max(len(title), len(subtitle)) + 8
        tw = max(tw, 50)
        W(f"  {palette['title'] if c else ''}{'═' * tw}{RST if c else ''}\n")
        W(f"  {palette['title'] if c else ''}  {title:<{tw-4}}  {RST if c else ''}\n")
        if subtitle:
            W(f"  {palette['subtle'] if c else ''}  {subtitle:<{tw-4}}  {RST if c else ''}\n")
        W(f"  {palette['title'] if c else ''}{'═' * tw}{RST if c else ''}\n")
        W("\n")

    # Render chart
    renderers = {
        "bar": render_bar,
        "sparkline": render_sparkline,
        "heatmap": render_heatmap,
        "table": render_table,
    }
    renderer = renderers.get(chart_type, render_bar)
    renderer(spec, palette, no_color, args.compact, theme=theme)

    # Summary
    if summary:
        W("\n")
        W(f"  {palette['header'] if c else ''}Summary{RST if c else ''}\n")
        W(f"  {palette['border'] if c else ''}{'─' * 50}{RST if c else ''}\n")
        for line in summary:
            W(f"  {palette['label'] if c else ''}{line}{RST if c else ''}\n")

    # Theme tag
    if not args.compact:
        W("\n")
        tag = "dark" if theme == "dark" else "light"
        W(f"  {DIM if c else ''}theme: {tag}{RST if c else ''}\n\n")


if __name__ == "__main__":
    main()
