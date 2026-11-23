#!/usr/bin/env python3
"""Verify Code101 lessons: run each lesson's verify.json in a clean temp copy.

Usage:
    python scripts/verify_labs.py                 # every lesson under source/
    python scripts/verify_labs.py python          # only paths containing "python"
    python scripts/verify_labs.py source/python/101-zero-to-hero/phase-1-foundations/01-hello-python

verify.json (in each lesson folder):
{
  "requires": ["python"],                      # tools that must be on PATH; missing => UNVERIFIED, not FAIL
  "steps": [
    {"name": "run", "cwd": "code", "cmd": "{python} main.py",
     "stdin": "Ada\\n", "expect_exit": 0,
     "expect_stdout": "exact text",            # optional, compared after normalising newlines/trailing spaces
     "expect_contains": ["fragment"],          # optional
     "bg": true, "wait": 3,                    # optional: start in the background (servers), wait N seconds, killed at the end
     "retries": 20, "retry_delay": 1}          # optional: repeat until the step passes (health checks)
  ],
  "cleanup": [                                 # ALWAYS run after the steps, even when a step fails (Docker down, etc.)
    {"name": "stop", "cmd": "docker compose -p {project} down -v --remove-orphans", "cwd": "code"}
  ],
  "skip_lesson_check": ["code/data.csv"]       # files not expected verbatim in the lesson text
  "exclusive": "tasksteams"                    # optional: named cross-process lock; labs sharing host ports (8000, 8180, 5432) must use the same name
}

Placeholders: {python} = the interpreter running this script; {project} = a throwaway Docker Compose project name
(code101-verify-<lesson>). Verification is a smoke test: run the code once with small input; do not run test suites.
Docker labs must be temporary: start under `-p {project}` and remove everything in `cleanup`.

Checks per lesson:
  1. every step runs in a temp copy and meets its expectations
  2. every expect_stdout / expect_contains text appears in the lesson markdown (the "Expected output" is real)
  3. every non-blank line of every text file in code/ appears in the lesson markdown (text matches code)
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "source"
CAPSTONES = ROOT / "capstones"
TEXT_EXT = {".py", ".cs", ".c", ".h", ".cpp", ".hpp", ".go", ".rs", ".ts", ".tsx", ".js", ".html", ".css",
            ".sql", ".dart", ".kt", ".yml", ".yaml", ".toml", ".txt", ".md", ".json", ".sh", ".ps1", ".csproj", ".env", ".example",
            ".mod", ".sum", ".conf", ".dockerignore", ".gitignore", ".xml", ".props", ".sln", ".slnx",
            ".proto", ".mmd", ".drawio", ".kts", ".gradle", ".properties", ".ini", ".cfg", ".lock", ".tf", ".service", ".mjs", ".cjs", ".vue", ".scss", ".gitattributes"}
TEXT_NAMES = {"Dockerfile", "Makefile", "Caddyfile", ".gitignore", ".dockerignore", ".editorconfig", ".gitattributes", ".env.example", "Jenkinsfile", "Containerfile"}
IGNORE_DIRS = {"__pycache__", "node_modules", "bin", "obj", ".venv", ".pytest_cache", ".mypy_cache", "target", ".angular"}
STATIC_ONLY = False


def refresh_windows_path() -> None:
    """Reload PATH from the registry so tools installed after this terminal opened are found."""
    if os.name != "nt":
        return
    try:
        import winreg
        parts = []
        for hive, sub in ((winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment"),
                          (winreg.HKEY_CURRENT_USER, "Environment")):
            with winreg.OpenKey(hive, sub) as key:
                value, _ = winreg.QueryValueEx(key, "Path")
                parts.append(os.path.expandvars(value))
        os.environ["PATH"] = ";".join(parts + [os.environ.get("PATH", "")])
    except OSError:
        pass


def norm(text: str) -> str:
    return "\n".join(line.rstrip() for line in text.replace("\r\n", "\n").split("\n")).strip("\n")


def find_lessons(filters: list[str]) -> list[Path]:
    found = []
    for base in (SOURCE, CAPSTONES):
        if base.exists():
            found += [p.parent for p in base.rglob("verify.json")]
    out = []
    for lesson in sorted(found):
        rel = lesson.relative_to(ROOT).as_posix()
        if not filters or any(f.replace("\\", "/").strip("/") in rel for f in filters):
            out.append(lesson)
    return out


def lesson_markdown(lesson: Path) -> Path | None:
    """source/<track>/<lvl>/<phase>/<NN-slug>  ->  tutorials/<track>/<lvl>/<phase>/<NN-slug>.md"""
    rel = lesson.relative_to(ROOT)
    parts = rel.parts
    if parts[0] == "source":
        md = ROOT / "tutorials" / Path(*parts[1:-1]) / (parts[-1] + ".md")
        return md if md.exists() else None
    if parts[0] == "capstones":  # capstones/Cxx/source/<phase>/<NN-slug> -> capstones/Cxx/tutorials/<phase>/<NN-slug>.md
        try:
            i = parts.index("source")
        except ValueError:
            return None
        md = ROOT.joinpath(*parts[:i], "tutorials", *parts[i + 1:-1], parts[-1] + ".md")
        return md if md.exists() else None
    return None


def copy_clean(lesson: Path, dest: Path) -> None:
    def ignore(_dir: str, names: list[str]) -> set[str]:
        return {n for n in names if n in IGNORE_DIRS}
    shutil.copytree(lesson, dest, ignore=ignore)


def project_name(workdir: Path) -> str:
    return "code101-verify-" + re.sub(r"[^a-z0-9-]", "-", workdir.name.lower())[:40]


def kill_tree(proc: subprocess.Popen) -> None:
    if proc.poll() is not None:
        return
    if os.name == "nt":
        subprocess.run(["taskkill", "/PID", str(proc.pid), "/T", "/F"], capture_output=True)
    else:
        proc.kill()


def run_step_once(step: dict, workdir: Path, background: list[subprocess.Popen]) -> list[str]:
    errors: list[str] = []
    cmd = step["cmd"].replace("{python}", f'"{sys.executable}"').replace("{project}", project_name(workdir))
    cwd = workdir / step.get("cwd", ".")
    env = dict(os.environ, PYTHONIOENCODING="utf-8", PYTHONUTF8="1", NO_COLOR="1")
    name = step.get("name", cmd)
    if step.get("bg"):
        proc = subprocess.Popen(cmd, cwd=cwd, shell=True, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                stdin=subprocess.DEVNULL)
        background.append(proc)
        time.sleep(step.get("wait", 2))
        return [f"{name}: background process exited early with code {proc.returncode}"] if proc.poll() is not None else []
    try:
        proc = subprocess.run(cmd, cwd=cwd, shell=True, input=step.get("stdin", ""), capture_output=True,
                              text=True, encoding="utf-8", errors="replace", timeout=step.get("timeout", 180), env=env)
    except subprocess.TimeoutExpired:
        return [f"{name}: timed out"]
    out = norm(proc.stdout)
    expected_exit = step.get("expect_exit", 0)
    if proc.returncode != expected_exit:
        errors.append(f"{name}: exit {proc.returncode}, expected {expected_exit}\n--- stdout\n{out}\n--- stderr\n{norm(proc.stderr)}")
    if "expect_stdout" in step and out != norm(step["expect_stdout"]):
        errors.append(f"{name}: stdout differs\n--- expected\n{norm(step['expect_stdout'])}\n--- actual\n{out}")
    for frag in step.get("expect_contains", []):
        if frag not in out:
            errors.append(f"{name}: output missing {frag!r}")
    return errors


def run_step(step: dict, workdir: Path, background: list[subprocess.Popen]) -> list[str]:
    attempts = max(1, step.get("retries", 1))
    errors: list[str] = []
    for attempt in range(attempts):
        errors = run_step_once(step, workdir, background)
        if not errors:
            return []
        if attempt + 1 < attempts:
            time.sleep(step.get("retry_delay", 1))
    return errors


def check_lesson_text(lesson: Path, spec: dict, steps: list[dict]) -> list[str]:
    md_path = lesson_markdown(lesson)
    if md_path is None:
        return ["no matching lesson markdown found under tutorials/"]
    md = norm(md_path.read_text(encoding="utf-8")).replace("\r", "")
    md_lines = {line.strip() for line in md.split("\n")}
    errors: list[str] = []
    for step in steps:
        if "expect_stdout" in step and norm(step["expect_stdout"]) not in md:
            errors.append(f"lesson text does not contain the expected output of step {step.get('name')!r}")
        for frag in step.get("expect_contains", []):
            if frag not in md:
                errors.append(f"lesson text does not contain expected fragment {frag!r}")
    skip = {s.replace("\\", "/") for s in spec.get("skip_lesson_check", [])}
    code_dir = lesson / "code"
    if code_dir.exists():
        for f in sorted(code_dir.rglob("*")):
            rel = f.relative_to(lesson).as_posix()
            if not f.is_file() or rel in skip or IGNORE_DIRS & set(f.parts):
                continue
            if f.suffix.lower() not in TEXT_EXT and f.name not in TEXT_NAMES:
                continue
            missing = [ln.strip() for ln in f.read_text(encoding="utf-8", errors="replace").splitlines()
                       if ln.strip() and ln.strip() not in md_lines]
            if missing:
                errors.append(f"{rel}: {len(missing)} line(s) not in lesson text, first: {missing[0]!r}")
    return errors


def verify(lesson: Path) -> tuple[str, list[str]]:
    spec = json.loads((lesson / "verify.json").read_text(encoding="utf-8"))
    if STATIC_ONLY:
        # No execution: only check that lesson text contains the code files and expected outputs.
        errors = check_lesson_text(lesson, spec, spec.get("steps", []))
        return ("FAIL" if errors else "STATIC"), errors
    for tool in spec.get("requires", []):
        if tool != "python" and shutil.which(tool) is None:
            return "UNVERIFIED", [f"tool not installed: {tool}"]
    exclusive = spec.get("exclusive")
    if exclusive:
        from stack_lock import stack_lock
        with stack_lock(exclusive):
            return _verify_locked(lesson, spec)
    return _verify_locked(lesson, spec)


def _verify_locked(lesson: Path, spec: dict) -> tuple[str, list[str]]:
    errors: list[str] = []
    background: list[subprocess.Popen] = []
    with tempfile.TemporaryDirectory(prefix="code101-") as tmp:
        work = Path(tmp) / lesson.name
        copy_clean(lesson, work)
        try:
            for step in spec["steps"]:
                errors += run_step(step, work, background)
        finally:
            for proc in background:
                kill_tree(proc)
            for step in spec.get("cleanup", []):
                cleanup_errors = run_step(step, work, background)
                if cleanup_errors:
                    errors += [f"CLEANUP FAILED: {e}" for e in cleanup_errors]
    errors += check_lesson_text(lesson, spec, spec["steps"])
    return ("FAIL" if errors else "PASS"), errors


def main() -> int:
    global STATIC_ONLY
    refresh_windows_path()
    args = [a for a in sys.argv[1:] if a != "--static"]
    STATIC_ONLY = "--static" in sys.argv[1:]
    lessons = find_lessons(args)
    if not lessons:
        print("no lessons with verify.json found")
        return 1
    counts = {"PASS": 0, "STATIC": 0, "FAIL": 0, "UNVERIFIED": 0}
    for lesson in lessons:
        status, errors = verify(lesson)
        counts[status] += 1
        print(f"[{status:10}] {lesson.relative_to(ROOT).as_posix()}")
        for e in errors:
            print("    - " + e.replace("\n", "\n      "))
    print(f"\n{counts['PASS']} passed, {counts['STATIC']} static-checked (not run), {counts['FAIL']} failed, {counts['UNVERIFIED']} unverified (missing tools)")
    return 1 if counts["FAIL"] else 0


if __name__ == "__main__":
    sys.exit(main())
