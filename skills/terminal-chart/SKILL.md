---
name: terminal-chart
description: Render colored ASCII charts in the terminal. MUST use when the user asks to visualize, chart, graph, or plot data — including compound requests like "query and visualize X" or "show me spend by country". Trigger on any mention of visualize, chart, graph, plot, or "show me ... by".
---

# Terminal Chart

Renders colored ASCII charts directly in the terminal with automatic dark/light theme detection.

## Prerequisites

- Python 3.8+
- No external dependencies (uses only the standard library)

## Supported Chart Types

| Type | Description |
|------|-------------|
| `bar` | Horizontal bar chart with gradient colors and fractional-width bars |
| `sparkline` | Compact trend lines with per-series stats (total, avg, min, max) |
| `heatmap` | Grid of values with background-color intensity |
| `table` | Colored tabular display |

## How to Use

Pipe a JSON spec into `chart.py` via stdin. The script auto-detects the terminal theme (dark/light) and picks appropriate colors.

```bash
echo '<JSON>' | python skills/ads/terminal-chart/scripts/chart.py [options]
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--theme dark\|light\|auto` | `auto` | Force a theme instead of auto-detecting |
| `--no-color` | off | Strip all ANSI codes (plain ASCII) |
| `--compact` | off | Remove headers and separator lines |

### Environment

| Variable | Description |
|----------|-------------|
| `TERMINAL_THEME` | Set to `dark` or `light` to override auto-detection |

## JSON Spec Reference

The input is a single JSON object:

```json
{
  "title": "Chart Title",
  "subtitle": "Optional subtitle",
  "type": "bar",
  "data": [ ... ],
  "value_key": "value",
  "label_key": "label",
  "detail_keys": [ ... ],
  "value_format": "auto",
  "bar_width": 40,
  "sort": "desc",
  "limit": 30,
  "summary": ["Line 1", "Line 2"]
}
```

### Common Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `title` | string | `""` | Chart title shown at top |
| `subtitle` | string | `""` | Subtitle below title |
| `type` | string | `"bar"` | Chart type: `bar`, `sparkline`, `heatmap`, `table` |
| `data` | array | required | Array of row objects |
| `summary` | array | `[]` | Summary lines shown below the chart |

### Bar Chart Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `value_key` | string | `"value"` | Key in each data object for bar value |
| `label_key` | string | `"label"` | Key in each data object for row label |
| `detail_keys` | array | `[]` | Extra columns beside the bar (strings or `{"key", "name", "format"}` objects) |
| `value_format` | string | `"auto"` | Format: `auto`, `money`, `percent`, `number`, `bytes` |
| `bar_width` | int | `40` | Width of the bar in characters |
| `sort` | string | `"desc"` | Sort order: `desc`, `asc`, `none` |
| `limit` | int | `30` | Max rows to display |

### Sparkline Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `series_key` | string | `"series"` | Key for series/group name |
| `time_key` | string | `"time"` | Key for time axis (values are sorted) |
| `value_key` | string | `"value"` | Key for the metric value |
| `value_format` | string | `"auto"` | Format for stats columns |
| `sort` | string | `"desc"` | Sort series by total: `desc`, `asc`, `none` |
| `limit` | int | `30` | Max series to display |

### Heatmap Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `row_key` | string | `"row"` | Key for row axis |
| `col_key` | string | `"col"` | Key for column axis |
| `value_key` | string | `"value"` | Key for cell value |
| `value_format` | string | `"auto"` | Format for cell values |

### Table Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `columns` | array | auto | Column definitions: strings or `{"key", "name", "format"}` objects |

## Examples

### Bar Chart

```bash
echo '{
  "title": "Revenue by Country",
  "type": "bar",
  "value_key": "revenue",
  "label_key": "country",
  "value_format": "money",
  "detail_keys": [
    {"key": "impressions", "name": "Impressions", "format": "number"}
  ],
  "data": [
    {"country": "US", "revenue": 9000000, "impressions": 2800000000},
    {"country": "JP", "revenue": 838000, "impressions": 613000000},
    {"country": "CA", "revenue": 574000, "impressions": 259000000}
  ],
  "summary": ["Total: $10.4M across 3 countries"]
}' | python skills/ads/terminal-chart/scripts/chart.py
```

### Heatmap

```bash
echo '{
  "title": "Impressions by Day x Country",
  "type": "heatmap",
  "row_key": "country",
  "col_key": "day",
  "value_key": "impressions",
  "value_format": "number",
  "data": [
    {"country": "US", "day": "Mon", "impressions": 1200000},
    {"country": "US", "day": "Tue", "impressions": 1350000},
    {"country": "JP", "day": "Mon", "impressions": 800000},
    {"country": "JP", "day": "Tue", "impressions": 750000}
  ]
}' | python skills/ads/terminal-chart/scripts/chart.py
```

### Sparkline

```bash
echo '{
  "title": "DSP Spend Trend — 30 Days",
  "type": "sparkline",
  "series_key": "dsp",
  "time_key": "date",
  "value_key": "spend",
  "value_format": "money",
  "data": [
    {"dsp": "comet", "date": "2026-03-01", "spend": 5700000},
    {"dsp": "comet", "date": "2026-03-02", "spend": 6000000},
    {"dsp": "moloco", "date": "2026-03-01", "spend": 159000},
    {"dsp": "moloco", "date": "2026-03-02", "spend": 174000}
  ],
  "summary": ["Total: $11.8M"]
}' | python skills/ads/terminal-chart/scripts/chart.py
```

### Table

```bash
echo '{
  "title": "Top Games",
  "type": "table",
  "columns": [
    {"key": "game", "name": "Game"},
    {"key": "revenue", "name": "Revenue", "format": "money"},
    {"key": "dau", "name": "DAU", "format": "number"}
  ],
  "data": [
    {"game": "Game A", "revenue": 50000, "dau": 1200000},
    {"game": "Game B", "revenue": 32000, "dau": 800000}
  ]
}' | python skills/ads/terminal-chart/scripts/chart.py
```

## Workflow

When the user asks for a terminal visualization:

1. **Get the data** — if an upstream skill (e.g., `bigquery-skill`) has already produced a JSON array of row objects, use that directly as the `data` field. Otherwise, run whatever query is needed to get the data.
2. **Build the chart JSON spec:**
   - Set `data` to the JSON array from the upstream skill.
   - Choose a chart `type` based on the data shape:
     | Data Shape | Chart Type |
     | :--- | :--- |
     | One categorical + one numeric column | `bar` |
     | One categorical + one time + one numeric column | `sparkline` |
     | Two categorical + one numeric column | `heatmap` |
     | Multiple columns, no clear plot axis | `table` |
   - Map the existing column names to key fields (`label_key`, `value_key`, `series_key`, `time_key`, `row_key`, `col_key`) — do not rename them.
   - Set `value_format` (`money`, `percent`, `number`, `bytes`, or `auto`) and add a `title`.
3. **Render**: `echo '<json>' | python skills/ads/terminal-chart/scripts/chart.py`

**Important:** The chart MUST be rendered by running the script — do not attempt to print ANSI codes directly from tool output, as they will not render. Always pipe through the Python script via Bash.

<!-- Cross-platform: see AGENTS.md in the repository root for Cursor, Claude Code, and Copilot paths. -->
