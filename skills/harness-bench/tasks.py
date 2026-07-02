"""Load + validate YAML task specs into TaskSpec / Judge dataclasses."""
from __future__ import annotations

import re
from pathlib import Path

import yaml

from models import Judge, TaskSpec

_VALID_JUDGE_TYPES = {"pytest", "grep", "build"}
_REQUIRED_TASK_FIELDS = ("name", "repo", "base_commit", "prompt", "judges")
# base_commit must pin a real commit: a 7-40 char hex SHA. This also rejects
# git-flag injection (a value like "-b evil") before it reaches `git checkout`.
_SHA_RE = re.compile(r"[0-9a-fA-F]{7,40}")
_REPO_PREFIXES = ("https://", "http://", "git@", "/", "./", "../", "~")


def _parse_judge(raw: dict, *, task_name: str) -> Judge:
    if not isinstance(raw, dict) or "type" not in raw:
        raise ValueError(f"task {task_name!r}: each judge must be a mapping with a 'type'")
    jtype = raw["type"]
    if jtype not in _VALID_JUDGE_TYPES:
        raise ValueError(
            f"task {task_name!r}: unknown judge type {jtype!r} "
            f"(valid: {', '.join(sorted(_VALID_JUDGE_TYPES))})"
        )
    if jtype in ("pytest", "build") and not raw.get("command"):
        raise ValueError(f"task {task_name!r}: {jtype} judge requires a 'command'")
    if jtype == "grep" and (not raw.get("pattern") or not raw.get("files")):
        raise ValueError(f"task {task_name!r}: grep judge requires 'pattern' and 'files'")
    return Judge(
        type=jtype,
        command=raw.get("command"),
        pattern=raw.get("pattern"),
        files=list(raw.get("files") or []),
    )


def load_task(path: str | Path) -> TaskSpec:
    """Parse one YAML task spec. Raises ValueError on a malformed spec."""
    path = Path(path)
    data = yaml.safe_load(path.read_text())
    if not isinstance(data, dict):
        raise ValueError(f"{path}: task spec must be a YAML mapping")
    # Presence check, not truthiness: a base_commit like "0000…" parses as int 0
    # (falsy) but is a legitimate value, so require the KEY with a non-empty value.
    missing = [
        f for f in _REQUIRED_TASK_FIELDS
        if f not in data or data[f] is None or data[f] == ""
    ]
    if missing:
        raise ValueError(f"{path}: missing required field(s): {', '.join(missing)}")
    if not isinstance(data["judges"], list):
        raise ValueError(f"{path}: 'judges' must be a list")
    repo = str(data["repo"])
    if not repo.startswith(_REPO_PREFIXES):
        raise ValueError(
            f"{path}: 'repo' must be an https/http/git@ URL or a local path "
            f"(got {repo!r})"
        )
    base_commit = str(data["base_commit"])
    if not _SHA_RE.fullmatch(base_commit):
        raise ValueError(
            f"{path}: 'base_commit' must be a 7-40 char hex SHA (got {base_commit!r})"
        )
    judges = [_parse_judge(j, task_name=data["name"]) for j in data["judges"]]
    return TaskSpec(
        name=data["name"],
        repo=repo,
        base_commit=base_commit,
        prompt=data["prompt"],
        judges=judges,
    )


def load_tasks(dir_path: str | Path) -> list[TaskSpec]:
    """Load every *.yaml / *.yml task spec in a directory, sorted by filename."""
    dir_path = Path(dir_path)
    files = sorted(p for p in dir_path.iterdir() if p.suffix in (".yaml", ".yml"))
    return [load_task(p) for p in files]
