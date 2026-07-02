"""Tests for judges.py — the three deterministic graders + AND semantics."""
from __future__ import annotations

from models import Judge, TaskSpec
import judges


def _fake_runner(returncode: int):
    """A subprocess.run-like callable that never shells out."""
    def run(cmd, **kwargs):
        class R:
            pass
        r = R()
        r.returncode = returncode
        r.stdout = ""
        r.stderr = ""
        return r
    return run


def test_grep_grader_hit(tmp_path):
    f = tmp_path / "src.ts"
    f.write_text("export function redactSecrets(s) { return s; }\n")
    j = Judge(type="grep", pattern="function redactSecrets", files=[str(f)])
    assert judges.run_judge(j, str(tmp_path)) is True


def test_grep_grader_miss(tmp_path):
    f = tmp_path / "src.ts"
    f.write_text("export function other() {}\n")
    j = Judge(type="grep", pattern="function redactSecrets", files=[str(f)])
    assert judges.run_judge(j, str(tmp_path)) is False


def test_grep_grader_relative_files(tmp_path):
    (tmp_path / "a.txt").write_text("hello world\n")
    j = Judge(type="grep", pattern="world", files=["a.txt"])
    assert judges.run_judge(j, str(tmp_path)) is True


def test_grep_grader_confined_to_workdir(tmp_path):
    # a secret OUTSIDE the workdir must not be readable via absolute path or `..`
    outside = tmp_path / "secret.txt"
    outside.write_text("TOPSECRET\n")
    workdir = tmp_path / "repo"
    workdir.mkdir()
    abs_escape = Judge(type="grep", pattern="TOPSECRET", files=[str(outside)])
    dotdot_escape = Judge(type="grep", pattern="TOPSECRET", files=["../secret.txt"])
    assert judges.run_judge(abs_escape, str(workdir)) is False
    assert judges.run_judge(dotdot_escape, str(workdir)) is False


def test_pytest_grader_pass():
    j = Judge(type="pytest", command="pytest -q")
    assert judges.run_judge(j, ".", runner=_fake_runner(0)) is True


def test_pytest_grader_fail():
    j = Judge(type="pytest", command="pytest -q")
    assert judges.run_judge(j, ".", runner=_fake_runner(1)) is False


def test_build_grader_pass():
    j = Judge(type="build", command="npm run build")
    assert judges.run_judge(j, ".", runner=_fake_runner(0)) is True


def test_build_grader_fail():
    j = Judge(type="build", command="npm run build")
    assert judges.run_judge(j, ".", runner=_fake_runner(2)) is False


def test_judge_run_ands_all(tmp_path):
    f = tmp_path / "src.ts"
    f.write_text("function redactSecrets() {}\n")
    task = TaskSpec(
        name="t", repo="r", base_commit="c", prompt="p",
        judges=[
            Judge(type="build", command="npm run build"),
            Judge(type="grep", pattern="function redactSecrets", files=[str(f)]),
        ],
    )
    # build passes (fake exit 0) AND grep hits -> True
    assert judges.judge_run(task, str(tmp_path), runner=_fake_runner(0)) is True
    # build fails (fake exit 1) -> overall False even though grep would hit
    assert judges.judge_run(task, str(tmp_path), runner=_fake_runner(1)) is False
