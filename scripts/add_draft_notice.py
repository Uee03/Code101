#!/usr/bin/env python3
"""Add (or remove) the 'Draft: written but not yet run' notice in lessons whose front matter says `verified: not yet run`.

Usage:
    python scripts/add_draft_notice.py            # add the notice where missing (all lessons under tutorials/ and capstones/)
    python scripts/add_draft_notice.py --remove   # remove the notice from lessons whose front matter now has a real verified date

The notice goes directly under the first H1 title. Idempotent.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NOTICE = (
    "> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official "
    "documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it."
)
MARK = "Draft: written but not yet run"


def lesson_files():
    for base in (ROOT / "tutorials", ROOT / "capstones"):
        if base.exists():
            for p in base.rglob("*.md"):
                if re.match(r"\d\d-", p.name) and "source" not in p.parts and "_practice" not in p.parts:
                    yield p


def main() -> int:
    remove = "--remove" in sys.argv
    changed = 0
    for p in lesson_files():
        text = p.read_text(encoding="utf-8")
        fm = re.match(r"---\r?\n(.*?)\r?\n---", text, re.S)
        if not fm:
            continue
        unverified = re.search(r"^verified:\s*not yet run", fm.group(1), re.M) is not None
        has = MARK in text
        nl = "\r\n" if "\r\n" in text else "\n"
        if remove and has and not unverified:
            new = re.sub(r"\n?> \*\*Draft: written but not yet run\.\*\*[^\n]*\n?", "\n", text, count=1)
        elif not remove and unverified and not has:
            m = re.search(r"^# .*$", text[fm.end():], re.M)
            if not m:
                continue
            pos = fm.end() + m.end()
            new = text[:pos] + nl + nl + NOTICE + text[pos:]
        else:
            continue
        p.write_text(new, encoding="utf-8", newline="")
        changed += 1
    print(f"{'removed from' if remove else 'added to'} {changed} lesson(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
