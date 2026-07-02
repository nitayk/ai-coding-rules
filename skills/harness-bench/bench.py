#!/usr/bin/env python3
"""harness-bench — a minimal harness-infra eval harness.

Measures the value of the MAT/skills *layer* by holding model + task fixed and
toggling only the layer: ARM A = bare Claude Code (no MAT plugin/skills/hooks),
ARM B = MAT layer ON. It runs each (arm × model × task) N times, judges every run
with DETERMINISTIC graders, and produces one scatter plot (y = resolution rate,
x = $/task, one marker per arm×model with an axis-aligned ±1σ ellipse).

"≥2 models" means ≥2 ANTHROPIC models inside Claude Code (e.g. claude-opus-4-8 vs
claude-sonnet-4-6) — NOT cross-vendor (that is the separate cross-model review bench).

The live agent-running path is GATED (HARNESS_BENCH_LIVE=1). Everything else —
parse, judge, aggregate, plot-data — is pure and runs without spawning agents,
network, or matplotlib. See the AQ-66 design note + DESIGN.md.

Subcommands:
  run        live matrix -> results JSON (refuses unless HARNESS_BENCH_LIVE=1)
  aggregate  results JSON -> stats table + stats JSON
  plot       stats-or-results JSON -> PNG (needs matplotlib)
  demo       seeded fixtures -> aggregate -> marker table (zero live runs, no matplotlib)
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict
from pathlib import Path

import aggregate as aggregate_mod
import arms as arms_mod
import plot as plot_mod
import preflight as preflight_mod
import tasks as tasks_mod
from models import RunRecord
from runners import ClaudeCodeRunner, SeededRunner

HERE = Path(__file__).resolve().parent
DEFAULT_FIXTURE = HERE / "fixtures" / "seeded_results.json"
DEFAULT_TASKS = HERE / "example_tasks"


# ── helpers ──────────────────────────────────────────────────────────────────
def _load_records(path: str | Path) -> list[RunRecord]:
    raw = json.loads(Path(path).read_text())
    return [RunRecord(**r) for r in raw]


def _print_marker_table(points: list[dict]) -> None:
    print(f"{'arm/model':<32} {'$/task':>10} {'resolution':>11} "
          f"{'±$ (1σ)':>10} {'±res (1σ)':>10}")
    print("-" * 76)
    for p in points:
        print(f"{p['label']:<32} {p['x']:>10.4f} {p['y']:>11.3f} "
              f"{p['ex']:>10.4f} {p['ey']:>10.3f}")


# ── subcommands ──────────────────────────────────────────────────────────────
def cmd_doctor(args: argparse.Namespace) -> int:
    """Preflight: report dependency status + how to install anything missing."""
    checks = preflight_mod.preflight()
    sym = {True: "ok ", False: "MISS"}
    print(f"{'dep':<22}{'tier':<7}{'status':<6}detail")
    print("-" * 72)
    for c in checks:
        print(f"{c.name:<22}{c.tier:<7}{sym[c.ok]:<6}{c.detail}")
        if not c.ok:
            print(f"    -> fix: {c.fix}")
    demo = preflight_mod.demo_ready(checks)
    live = preflight_mod.live_ready(checks)
    print()
    print(f"demo / tests : {'READY' if demo else 'NOT READY (see demo-tier fixes above)'}")
    print(f"live burn    : {'READY' if live else 'not ready (live-tier above; demo still works)'}")
    print("plot PNG     : " + ("available" if any(c.name == 'matplotlib' and c.ok for c in checks)
                                else "needs matplotlib (optional; table prints without it)"))
    return 0 if demo else 1


def cmd_run(args: argparse.Namespace) -> int:
    arm_names = args.arms.split(",")
    arm_table = arms_mod.resolve_arms(arm_names, args.arms_config)
    runner = ClaudeCodeRunner(allow_live=args.allow_live, arms=arm_table)  # gated in run()
    specs = tasks_mod.load_tasks(args.tasks)
    models = args.models.split(",")
    records = aggregate_mod.run_matrix(runner, specs, arm_names, models, args.runs)
    Path(args.out).write_text(json.dumps([asdict(r) for r in records], indent=2))
    print(f"wrote {len(records)} run records -> {args.out}")
    return 0


def cmd_aggregate(args: argparse.Namespace) -> int:
    records = _load_records(args.results)
    stats = aggregate_mod.aggregate(records)
    points = plot_mod.plot_points(stats)
    _print_marker_table(points)
    if args.out:
        Path(args.out).write_text(json.dumps([asdict(s) for s in stats], indent=2))
        print(f"\nwrote stats -> {args.out}")
    return 0


def _stats_from_any(path: str | Path) -> list:
    """Accept either a results JSON (list of run records) or a stats JSON."""
    raw = json.loads(Path(path).read_text())
    if raw and "resolution_rate" in raw[0]:
        from models import ArmModelStats
        return [ArmModelStats(**s) for s in raw]
    return aggregate_mod.aggregate([RunRecord(**r) for r in raw])


def cmd_plot(args: argparse.Namespace) -> int:
    stats = _stats_from_any(args.input)
    points = plot_mod.plot_points(stats)
    plot_mod.render(points, args.out)
    print(f"wrote plot -> {args.out}")
    return 0


def cmd_demo(args: argparse.Namespace) -> int:
    """Seeded fixtures -> aggregate -> marker table. Zero live runs, no matplotlib."""
    records = _load_records(args.fixture)
    specs = tasks_mod.load_tasks(DEFAULT_TASKS)
    runner = SeededRunner(records)
    arms = sorted({r.arm for r in records})
    models = sorted({r.model for r in records})
    n_runs = max(r.run_idx for r in records) + 1
    replayed = aggregate_mod.run_matrix(runner, specs, arms, models, n_runs)
    stats = aggregate_mod.aggregate(replayed)
    points = plot_mod.plot_points(stats)
    print(f"demo: {len(replayed)} seeded runs over {arms} arms x {models} models "
          f"x {len(specs)} tasks x {n_runs} runs\n")
    _print_marker_table(points)
    if args.out:
        try:
            plot_mod.render(points, args.out)
            print(f"\nwrote plot -> {args.out}")
        except ImportError as e:
            print(f"\n(skipped PNG: {e})", file=sys.stderr)
    return 0


# ── CLI ──────────────────────────────────────────────────────────────────────
def build_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(prog="harness-bench", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true",
                    help="alias for the `demo` subcommand (seeded, no live runs)")
    sub = ap.add_subparsers(dest="command")

    p_doctor = sub.add_parser("doctor", help="check dependencies + how to install missing ones")
    p_doctor.set_defaults(func=cmd_doctor)

    p_run = sub.add_parser("run", help="live matrix (GATED: HARNESS_BENCH_LIVE=1)")
    p_run.add_argument("--tasks", default=str(DEFAULT_TASKS))
    p_run.add_argument("--arms", default="A,B",
                       help="comma-separated arm names (built-in A=MAT-off,B=MAT-on; "
                            "others via --arms-config)")
    p_run.add_argument("--arms-config", default=None,
                       help="JSON file defining arm profiles (plugin_overrides / "
                            "inject_skills_from) beyond the built-in A/B")
    p_run.add_argument("--models", default="claude-opus-4-8,claude-sonnet-4-6")
    p_run.add_argument("--runs", type=int, default=5)
    p_run.add_argument("--allow-live", action="store_true",
                       help="ctor opt-in to live runs (HARNESS_BENCH_LIVE=1 also works)")
    p_run.add_argument("--out", default="results_live.json")
    p_run.set_defaults(func=cmd_run)

    p_agg = sub.add_parser("aggregate", help="results JSON -> stats table / JSON")
    p_agg.add_argument("results")
    p_agg.add_argument("--out", default=None, help="optional stats JSON output path")
    p_agg.set_defaults(func=cmd_aggregate)

    p_plot = sub.add_parser("plot", help="stats-or-results JSON -> PNG (needs matplotlib)")
    p_plot.add_argument("input")
    p_plot.add_argument("--out", default="harness_bench.png")
    p_plot.set_defaults(func=cmd_plot)

    p_demo = sub.add_parser("demo", help="seeded fixtures -> marker table (no live, no mpl)")
    p_demo.add_argument("--fixture", default=str(DEFAULT_FIXTURE))
    p_demo.add_argument("--out", default=None, help="optional PNG path (needs matplotlib)")
    p_demo.set_defaults(func=cmd_demo)
    return ap


def main(argv: list[str] | None = None) -> int:
    ap = build_parser()
    args = ap.parse_args(argv)
    if args.dry_run or args.command is None:
        # default / --dry-run -> demo with fixture defaults
        demo_ns = argparse.Namespace(fixture=str(DEFAULT_FIXTURE), out=None)
        return cmd_demo(demo_ns)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
