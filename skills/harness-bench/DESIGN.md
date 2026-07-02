# harness-bench — design decisions

Full rationale lives in the AQ-66 design note:
`research/investigations/2026-06-26-aq66-harness-infra-eval-harness-design.md`.

This file records only the implementation decisions locked for this build.

## What it is

GitHub's Copilot-harness eval methodology, adapted: hold **model + task** fixed, vary
only the **MAT/skills layer** (ARM A bare vs ARM B MAT-on), across **≥2 Anthropic
models** inside Claude Code. Output: one σ resolution-vs-cost scatter. It is NOT a
cross-vendor bench (that's the separate cross-model review bench) and NOT a
`mobile-agent-toolkit` plugin edit (those get overwritten on update) — it is an
own-tool under `research/tools/`, same pattern as `skillopt-mini`.

## Locked decisions

- **No numpy.** All mean/stdev via stdlib `statistics`. Stdev is **population** stdev
  (`statistics.pstdev`) guarded so n < 2 → 0.0 (a single sample has no spread).
- **Lazy matplotlib.** `matplotlib` is imported only inside `plot.render`, so the
  module imports and every plot-DATA test (`plot_points`) runs on an interpreter
  without matplotlib. Missing matplotlib at render time → a clear `ImportError`
  telling the operator to `pip install matplotlib`. It is **not** a hard dependency.
- **±1σ ellipse is axis-aligned.** width = 2·stdev(cost), height = 2·stdev(resolution),
  centered at (mean_cost, mean_resolution). No covariance, no rotation.
- **Resolution = "best-of per task, then mean across tasks."** A task counts resolved
  if ANY of its N runs passed (best-of, per GitHub's protocol); the cell's resolution
  rate (the plotted marker) is the mean of those per-task indicators. The ±1σ
  resolution band is the **run-to-run** stdev of per-run resolution (for each run index
  i, the mean over tasks of "passed in run i"), so the ellipse half-height measures the
  reproducibility of the plotted statistic — GitHub's "±1σ run-to-run spread" — not the
  dispersion of per-task pass-rates (a different quantity that would mislabel the bar).
- **Live runs are gated.** `ClaudeCodeRunner` refuses unless `HARNESS_BENCH_LIVE=1`
  (env) or `allow_live=True` (ctor). Everything else — parse, judge, aggregate,
  plot-data — is pure and unit-tested without spawning agents or touching the network.
- **Judges are deterministic** (`pytest` | `grep` | `build`), ANDed. The subprocess
  graders take an injectable `runner` so tests use a fake and never shell out; the
  grep grader reads files directly. A weak grader caps the whole plot's meaning, so
  deterministic-first is a hard rule (model-judges only with FP discipline, later).
- **Pricing is operator-editable placeholder rates** in `tokens.PRICING` ($/1M in,
  $/1M out), clearly commented as estimates. Replace before reporting any `$` number.

## Deliberately deferred (not v1)

- Per-component attribution (arm C — toggle a single skill). v1 proves "the layer
  helps", not "which skill helps".
- A model-judge tier (would require the cross-model review bench's FP-penalized
  grading discipline).
- Growing the task set beyond the 3 illustrative specs.

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
