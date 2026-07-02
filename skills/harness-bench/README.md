# harness-bench

A **minimal harness-infra eval harness**. It measures the value of the **MAT/skills
layer** by holding the model and task fixed and toggling only the layer:

- **ARM A** — bare Claude Code (no MAT plugin, no project skills/hooks).
- **ARM B** — the MAT layer ON (the `mobile-agent-toolkit` plugin + the repo's
  skills/hooks/rules as a real developer gets them).

It runs each **(arm × model × task)** N times, judges every run with **deterministic
graders**, and produces one scatter plot: **y = resolution rate, x = $/task**, one
marker per arm×model wrapped in an **axis-aligned ±1σ ellipse**.

**Locked scope:** ≥2 **Anthropic** models inside Claude Code (e.g. `claude-opus-4-8`
vs `claude-sonnet-4-6`) — **NOT** cross-vendor (that is the separate cross-model
review bench). The question this answers is "what does *our config layer* add,
independent of which model is underneath" — not "which agent/vendor is best".

Background + rationale: `research/investigations/2026-06-26-aq66-harness-infra-eval-harness-design.md`.

## The no-cost dry run (start here)

The whole parse → judge → aggregate → plot-data pipeline is pure and runs with **zero
live agent runs, no network, and no matplotlib**. The `demo` subcommand replays a
hand-authored fixture of 2 arms × 2 models × 3 tasks × 5 runs (60 records) through the
real aggregation and prints the marker table:

```bash
python3.12 bench.py demo          # or: python3.12 bench.py --dry-run
```

Expected: ARM B sits **up-and-left** of ARM A (higher resolution, lower $/task) on
**both** models — the model-agnostic "the harness earns its tokens" shape.

## Running the real burn (later)

The live path is **gated** — it refuses to spawn agents unless you explicitly opt in:

```bash
export HARNESS_BENCH_LIVE=1        # the gate (or pass --allow-live)
python3.12 bench.py run \
  --tasks tasks \
  --arms A,B \
  --models claude-opus-4-8,claude-sonnet-4-6 \
  --runs 5 \
  --out results_live.json

python3.12 bench.py aggregate results_live.json --out stats.json
pip install matplotlib             # only needed to render the PNG
python3.12 bench.py plot stats.json --out harness_bench.png
```

Without the gate, `run` raises `RuntimeError("live runs are gated; set HARNESS_BENCH_LIVE=1")`.

### The arm-toggle mechanism (what defines each arm)

The single isolation control is: **same base harness (Claude Code) + same model +
same task; vary only the layer under test.** Each arm is an `ArmProfile` (see
`models.py`), resolved from the built-ins plus an optional `--arms-config` JSON:

- **`plugin_overrides`** → emitted as `claude -p --settings '{"enabledPlugins": {<key>: <bool>}}'`.
  **Critical:** `enabledPlugins` MERGES per-key, so to turn a plugin **off** you must
  set its key explicitly `false` — an empty `{}` is a no-op that disables nothing
  (verified live; this was a real bug, see commit history). Other plugins are left
  untouched = the controlled baseline.
- **`inject_skills_from`** → after clone/checkout, the runner first removes any
  committed `.claude/` in the clone (so the baseline carries no stray project skills),
  then copies that path's skill packages into the clone's `.claude/skills/`. This is how
  a tool-agnostic SKILL.md library that is **not** installed as a plugin (e.g.
  ai-agent-skills) is tested project-scoped.

Built-in arms: **A** = MAT off (`{MAT_KEY: false}`), **B** = MAT on (ambient, no
override). Example custom arms (`--arms-config`): `bare` (MAT off), `mat` (MAT on),
`aas` (MAT off + ai-agent-skills injected).

Each run clones the task repo, checks out the pinned `base_commit` into an isolated
temp dir, applies the arm profile, runs the agent, parses `--output-format json` usage
→ tokens + authoritative `total_cost_usd`, then runs the task's judges (`judge_run` =
ALL judges pass). Per-run errors are isolated so one failure never aborts the matrix.

> **Token accounting caveat (carry forward from the design note):** RTK token-rewriting
> *is* part of ARM B and will deflate its shell-token count — that's a real harness win,
> not a measurement artifact. Document it; don't scrub it.

## Tasks

Tasks are YAML specs in `example_tasks/` with deterministic judges (`pytest` | `grep` |
`build`). Three are shipped as illustrative-but-real-shaped examples (a parser/detector
fix, a typed-config bugfix, a build+grep refactor). Each pins a `base_commit`.
A weak grader makes the whole plot meaningless — deterministic judges first.

## Files

| File | Role |
|---|---|
| `models.py` | dataclasses: `TaskSpec`, `Judge`, `RunRecord`, `ArmModelStats` |
| `tasks.py` | load + validate YAML task specs |
| `tokens.py` | usage parsing + **operator-editable placeholder** pricing + cost math |
| `judges.py` | the 3 deterministic graders + AND semantics (injectable `runner`) |
| `runners.py` | `AgentRunner` ABC, gated `ClaudeCodeRunner` (live), `SeededRunner` (replay) |
| `aggregate.py` | `run_matrix` + `aggregate` (best-of-then-mean resolution, ±1σ bands) |
| `plot.py` | pure `plot_points` + lazy-matplotlib `render` |
| `bench.py` | argparse CLI: `run` / `aggregate` / `plot` / `demo` (+ `--dry-run`) |

## Tests

```bash
python3.12 -m pytest -q
```

All tests run green with **no live `claude`, no network, no matplotlib**. The pricing
rates in `tokens.PRICING` are **placeholders** — replace them with the real published
rates before trusting any `$/task` number.
