"""Arm profiles — the configurations a burn holds against each other.

Each arm is an `ArmProfile` (see models.py): plugin on/off overrides plus an optional
skill-injection path. The built-in A/B arms preserve the original MAT-off / MAT-on
comparison; richer arms (bare / mat / aas / …) come from a JSON `--arms-config`.

JSON shape (arms-config):
    {
      "bare": {"plugin_overrides": {"mobile-agent-toolkit@mobile-agent-toolkit": false}},
      "mat":  {"plugin_overrides": {}},
      "aas":  {"plugin_overrides": {"mobile-agent-toolkit@mobile-agent-toolkit": false},
               "inject_skills_from": "/abs/path/to/skill-set"}
    }
"""
from __future__ import annotations

import json
import os
from pathlib import Path

from models import ArmProfile

# The MAT plugin key as it appears in settings.json `enabledPlugins`.
MAT_PLUGIN_KEY = os.environ.get(
    "HARNESS_BENCH_MAT_PLUGIN", "mobile-agent-toolkit@mobile-agent-toolkit"
)

# Built-in arms: the original MAT-off (A) vs MAT-on (B) comparison.
DEFAULT_ARMS: dict[str, ArmProfile] = {
    "A": ArmProfile("A", {MAT_PLUGIN_KEY: False}),
    "B": ArmProfile("B", {}),
}


def load_arms(path: str | Path) -> dict[str, ArmProfile]:
    """Parse an arms-config JSON file into name -> ArmProfile. Raises ValueError."""
    raw = json.loads(Path(path).read_text())
    if not isinstance(raw, dict):
        raise ValueError(f"{path}: arms-config must be a JSON object")
    out: dict[str, ArmProfile] = {}
    for name, spec in raw.items():
        if not isinstance(spec, dict):
            raise ValueError(f"{path}: arm {name!r} must be an object")
        out[name] = ArmProfile(
            name=name,
            plugin_overrides=dict(spec.get("plugin_overrides", {})),
            inject_skills_from=spec.get("inject_skills_from"),
        )
    return out


def resolve_arms(
    names: list[str], config_path: str | Path | None = None
) -> dict[str, ArmProfile]:
    """Return the ArmProfile for each requested name, merging defaults + config.

    Config entries override built-ins of the same name. Unknown names raise KeyError.
    """
    table: dict[str, ArmProfile] = dict(DEFAULT_ARMS)
    if config_path:
        table.update(load_arms(config_path))
    missing = [n for n in names if n not in table]
    if missing:
        raise KeyError(
            f"unknown arm(s): {', '.join(missing)} "
            f"(known: {', '.join(sorted(table))}; pass --arms-config to define more)"
        )
    return {n: table[n] for n in names}
