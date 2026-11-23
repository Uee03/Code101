#!/usr/bin/env python3
"""Cross-process named lock so labs that use the same host ports never run at the same time.

Usage as a command wrapper (waits up to 45 minutes for the lock, then runs the command and releases the lock):
    python scripts/stack_lock.py tasksteams -- docker compose -p x up -d

Used by scripts/verify_labs.py when verify.json has "exclusive": "<name>".
The lock is a directory in the system temp folder; a lock older than 90 minutes, or whose owner process is gone, is treated as stale.
"""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import time
from contextlib import contextmanager
from pathlib import Path

STALE_SECONDS = 90 * 60


def _pid_alive(pid: int) -> bool:
    try:
        if os.name == "nt":
            out = subprocess.run(["tasklist", "/FI", f"PID eq {pid}", "/NH"], capture_output=True, text=True).stdout
            return str(pid) in out
        os.kill(pid, 0)
        return True
    except (OSError, ValueError):
        return False


@contextmanager
def stack_lock(name: str, timeout: float = 45 * 60):
    lock = Path(tempfile.gettempdir()) / f"code101-lock-{name}"
    deadline = time.time() + timeout
    announced = False
    while True:
        try:
            lock.mkdir()
            (lock / "owner").write_text(f"{os.getpid()}\n{time.time()}\n", encoding="utf-8")
            break
        except FileExistsError:
            try:
                pid_text, ts_text = (lock / "owner").read_text(encoding="utf-8").split()[:2]
                stale = time.time() - float(ts_text) > STALE_SECONDS or not _pid_alive(int(pid_text))
            except (OSError, ValueError):
                stale = time.time() - lock.stat().st_mtime > 30
            if stale:
                for f in lock.glob("*"):
                    f.unlink(missing_ok=True)
                try:
                    lock.rmdir()
                except OSError:
                    pass
                continue
            if time.time() > deadline:
                raise TimeoutError(f"could not get lock {name!r} within {timeout:.0f}s")
            if not announced:
                print(f"waiting for lock {name!r} (another run uses the same ports)...", flush=True)
                announced = True
            time.sleep(3)
    try:
        yield
    finally:
        for f in lock.glob("*"):
            f.unlink(missing_ok=True)
        try:
            lock.rmdir()
        except OSError:
            pass


def main() -> int:
    if len(sys.argv) < 4 or sys.argv[2] != "--":
        print(__doc__)
        return 2
    with stack_lock(sys.argv[1]):
        return subprocess.call(sys.argv[3:], shell=False)


if __name__ == "__main__":
    sys.exit(main())
