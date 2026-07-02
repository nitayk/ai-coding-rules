"""Agent runners.

`AgentRunner` is the ABC every runner implements: `run(task, arm, model) -> RunRecord`.

- `ClaudeCodeRunner` is the LIVE path. It is GATED: it refuses to run unless the
  operator explicitly opts in (`HARNESS_BENCH_LIVE=1` env or `allow_live=True`). It
  clones/worktrees the task repo at `base_commit`, invokes `claude -p` with the
  arm-appropriate config (ARM A = MAT layer OFF, ARM B = MAT layer ON), parses the
  JSON usage, runs the judges, and returns a RunRecord. This path is NOT exercised by
  the test suite — it just needs to be correct, clearly structured, and gated.

- `SeededRunner` replays pre-recorded RunRecords from a fixtures list (used by
  `--dry-run` / the `demo` subcommand and by tests). Deterministic.

ARM TOGGLE MECHANISM (verified live, see AQ-66 notes). Each arm is an ArmProfile:
  - plugin_overrides -> `--settings '{"enabledPlugins": {<key>: <bool>}}'`. NOTE:
    enabledPlugins MERGES per-key, so an empty `{}` is a NO-OP — to turn a plugin OFF
    you must set its key explicitly False (verified: arm then reports zero of that
    plugin's skills and still authenticates; an isolated CLAUDE_CONFIG_DIR was rejected
    because credentials live in the user config / macOS Keychain). Other plugins are
    left untouched = the controlled baseline.
  - inject_skills_from -> copies that dir's skill packages into the cloned repo's
    .claude/skills/ before the run, so a tool-agnostic SKILL.md library that is NOT
    installed as a plugin (e.g. ai-agent-skills) can be tested project-scoped.
  Example arms: `mat` (MAT on, ambient) vs `bare` (MAT off) vs `aas` (MAT off +
  ai-agent-skills injected). Built-in A=MAT-off / B=MAT-on (see arms.DEFAULT_ARMS).
"""
from __future__ import annotations

import abc
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from models import ArmProfile, RunRecord, TaskSpec
from tokens import cost_from_blob, parse_usage
from arms import DEFAULT_ARMS, MAT_PLUGIN_KEY  # noqa: F401 (MAT_PLUGIN_KEY re-exported)
import judges as judges_mod


class AgentRunner(abc.ABC):
    @abc.abstractmethod
    def run(self, task: TaskSpec, arm: str, model: str) -> RunRecord:
        ...


class ClaudeCodeRunner(AgentRunner):
    """Live runner — shells `claude -p` per (arm × model × task). GATED by default."""

    def __init__(self, allow_live: bool = False, timeout: int = 7200,
                 arms: dict[str, ArmProfile] | None = None):
        # gate: explicit ctor opt-in OR HARNESS_BENCH_LIVE=1 in the environment
        self.allow_live = allow_live or os.environ.get("HARNESS_BENCH_LIVE") == "1"
        self.timeout = timeout
        self.arms = arms or DEFAULT_ARMS
        self._run_counter: dict[tuple[str, str, str], int] = {}

    # -- arm config ---------------------------------------------------------------
    def _settings_args(self, arm: str) -> list[str]:
        """`--settings` args for an arm's plugin_overrides (empty if none).

        enabledPlugins merges per-key, so to turn a plugin OFF the override value
        must be explicitly False (an empty map disables nothing). See module docstring.
        """
        overrides = self.arms[arm].plugin_overrides
        if overrides:
            return ["--settings", json.dumps({"enabledPlugins": overrides})]
        return []

    @staticmethod
    def _inject_skills(workdir: str, src: str) -> int:
        """Copy each skill package (immediate subdir) under `src` into
        `<workdir>/.claude/skills/`. Returns the count copied. Idempotent per name."""
        dest = Path(workdir) / ".claude" / "skills"
        dest.mkdir(parents=True, exist_ok=True)
        n = 0
        for pkg in sorted(Path(src).iterdir()):
            if pkg.is_dir() and not pkg.is_symlink():  # immediate real subdirs only
                shutil.copytree(pkg, dest / pkg.name, dirs_exist_ok=True)
                n += 1
        return n

    def run(self, task: TaskSpec, arm: str, model: str) -> RunRecord:
        if not self.allow_live:
            raise RuntimeError("live runs are gated; set HARNESS_BENCH_LIVE=1")

        profile = self.arms[arm]
        workdir = tempfile.mkdtemp(prefix=f"hbench-{task.name}-{arm}-")
        try:
            # 1. clone + checkout the pinned base commit into the isolated workdir
            subprocess.run(["git", "clone", task.repo, workdir], check=True,
                           capture_output=True, text=True, timeout=self.timeout)
            subprocess.run(["git", "-C", workdir, "checkout", task.base_commit],
                           check=True, capture_output=True, text=True)

            # 1b. neutralize any committed project skills/settings in the clone so the
            #     arm's project-scope skills come ONLY from injection (keeps the bare
            #     baseline clean — this replaces the old empty-CLAUDE_PROJECT_DIR trick;
            #     user-scope plugins like MAT are unaffected, they're toggled via --settings).
            clone_claude = Path(workdir) / ".claude"
            if clone_claude.exists():
                shutil.rmtree(clone_claude, ignore_errors=True)
            # then inject this arm's skill library (e.g. ai-agent-skills), if any
            if profile.inject_skills_from:
                self._inject_skills(workdir, profile.inject_skills_from)

            # 2. invoke claude -p with the arm-appropriate config
            env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}
            env.pop("CLAUDE_CODE_ENTRYPOINT", None)
            cmd = (
                ["claude", "-p", task.prompt, "--output-format", "json",
                 "--model", model]
                + self._settings_args(arm)
            )
            proc = subprocess.run(cmd, cwd=workdir, capture_output=True, text=True,
                                  env=env, timeout=self.timeout)
            blob = json.loads(proc.stdout) if proc.stdout.strip() else {}

            # 3. usage -> tokens (input/output) + authoritative cost from the blob
            #    (total_cost_usd already includes the cache tokens that dominate spend)
            in_tok, out_tok = parse_usage(blob)
            cost = cost_from_blob(blob, model)

            # 4. judge the resulting working tree
            passed = judges_mod.judge_run(task, workdir)

            return RunRecord(
                arm=arm, model=model, task=task.name, run_idx=self._next_idx(task, arm, model),
                passed=passed, input_tokens=in_tok, output_tokens=out_tok,
                cost_usd=cost, error=None,
            )
        finally:
            shutil.rmtree(workdir, ignore_errors=True)

    def _next_idx(self, task, arm, model) -> int:
        key = (arm, model, task.name)
        idx = self._run_counter.get(key, 0)
        self._run_counter[key] = idx + 1
        return idx


class SeededRunner(AgentRunner):
    """Replays pre-recorded RunRecords. Deterministic; never spawns a process."""

    def __init__(self, records: list[RunRecord]):
        # index by (arm, model, task) -> queue of records, consumed in order then
        # cycled, so repeated calls for the same cell replay the recorded runs.
        self._by_cell: dict[tuple[str, str, str], list[RunRecord]] = {}
        for r in records:
            self._by_cell.setdefault((r.arm, r.model, r.task), []).append(r)
        self._cursor: dict[tuple[str, str, str], int] = {}

    def run(self, task: TaskSpec, arm: str, model: str) -> RunRecord:
        key = (arm, model, task.name)
        bucket = self._by_cell.get(key)
        if not bucket:
            raise KeyError(f"no seeded records for {key}")
        i = self._cursor.get(key, 0)
        rec = bucket[i % len(bucket)]
        self._cursor[key] = i + 1
        return rec
