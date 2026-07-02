---
name: harness-bench
description: >
  Measure whether an agent HARNESS / skills layer earns its tokens — hold the model
  and task fixed, vary only the layer (e.g. MAT plugin on/off, or a skill library
  injected vs not), across two or more models, and produce a resolution-vs-cost scatter
  (pass@best-of, tokens/task, $/task, run-to-run ±1σ). Use when asked to benchmark a
  harness/skills/plugin layer model-agnostically, quantify its token-efficiency or
  quality parity, or compare "with vs without" a skills layer. Built for the
  harness-infra eval question (AQ-66), modelled on GitHub's harness-isolation method.
  Do NOT use to benchmark a single model's raw capability (that's a model eval, not a
  harness eval) or for app-runtime performance profiling.
---

# harness-bench — a minimal harness-infra eval harness

> Claude-Code-specific by design — it benchmarks the Claude Code harness (`claude -p`,
> plugin/skill toggles).

Measures the value of a **layer that sits on top of Claude Code** (the MAT plugin, a
skill library, hooks, MCP) by holding **model + task** fixed and toggling **only the
layer**, across ≥2 models. Output: one **resolution-vs-cost scatter** — y = best-of
resolution rate, x = $/task, one marker per (arm × model) with a ±1σ run-to-run band.

> The live agent path is **gated** (`HARNESS_BENCH_LIVE=1`) and **spends real money**
> (one `claude -p` session per arm×model×task×run). The `demo` path is free.

## STEP 1 — always run the doctor first (dependency check)

```bash
python3.12 bench.py doctor
```

It reports, per tier, what's present and **the exact command to install anything
missing**. Tiers:
- **demo** (python ≥ 3.10, `pyyaml`) — required for the no-cost dry-run + tests.
- **live** (`claude` CLI on PATH, `HARNESS_BENCH_LIVE=1`) — required for a real burn.
- **plot** (`matplotlib`, optional) — only to render the PNG; the table prints without it.

**If `doctor` shows a MISS, surface its `fix:` line to the user and offer to run it**
before proceeding — don't silently fail. `matplotlib` is best installed in a throwaway
venv (`python3.12 -m venv .venv && .venv/bin/pip install matplotlib`) since system
Python is often PEP-668 externally-managed.

## STEP 2 — see it work with zero cost

```bash
python3.12 bench.py demo            # seeded fixtures -> marker table, no agents/network/$
```

## STEP 3 — define a real comparison

- **Tasks** (`example_tasks/*.yaml`, or any `--tasks <dir>`): `name`, `repo` (clonable URL or local path), `base_commit`
  (7–40 hex), `prompt`, and deterministic `judges` (pytest / build / grep). The judge
  must FAIL at `base_commit` and PASS once the task is done.
- **Arms** (`--arms-config arms.json`): each arm is `{plugin_overrides, inject_skills_from}`.
  - To turn a plugin **off**, set its key explicitly **false** (`enabledPlugins` MERGES
    per-key — an empty `{}` disables nothing). Built-ins: `A`=MAT off, `B`=MAT on.
  - `inject_skills_from` copies a SKILL.md library into the clone's `.claude/skills/`
    (project-scope) — use it to test a skill set that is NOT installed as a plugin.

  Example `arms.json`:
  ```json
  {
    "bare": {"plugin_overrides": {"mobile-agent-toolkit@mobile-agent-toolkit": false}},
    "mat":  {"plugin_overrides": {}},
    "aas":  {"plugin_overrides": {"mobile-agent-toolkit@mobile-agent-toolkit": false},
             "inject_skills_from": "/abs/path/to/skill-library"}
  }
  ```

## STEP 4 — run the burn (real $) + plot

```bash
HARNESS_BENCH_LIVE=1 python3.12 bench.py run \
  --tasks ./tasks --arms bare,mat,aas --arms-config arms.json \
  --models claude-sonnet-4-6,claude-haiku-4-5 --runs 3 --out results.json
python3.12 bench.py aggregate results.json          # marker table
python3.12 bench.py plot results.json --out out.png # needs matplotlib
```

Always smoke first (1 task × all arms × 1 run) to validate the toggle and calibrate
difficulty before the full N-session burn.

## What it measures honestly (read before trusting a result)

- Cost is taken from Claude's authoritative `total_cost_usd` (recomputing from
  input/output tokens is ~1000× low — cache tokens dominate spend).
- **Headroom caveat:** modern models one-shot well-specified *self-contained* tasks, so
  resolution saturates at 1.0 and the bench then only measures the layer's **overhead**,
  not its value. To measure value, use **real-repo tasks with failure headroom** (clone
  a real codebase, mine a historical bug + the test that proves its fix, base the task
  on the parent commit).

## Layout

`bench.py` (CLI: doctor/demo/run/aggregate/plot) · `arms.py` `models.py` `tasks.py`
`judges.py` `tokens.py` `aggregate.py` `plot.py` `runners.py` · `tests/` (run
`python3.12 -m pytest -q`) · `fixtures/` (seeded demo data).

<!-- Cross-platform: see AGENTS.md in the repository root for deployment details. -->
