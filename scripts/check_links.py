#!/usr/bin/env python3
"""Check the URLs listed in docs/LINKS.md.

Usage:
    python scripts/check_links.py                 # all URLs in docs/LINKS.md
    python scripts/check_links.py --track python  # only table rows mentioning "python" (case-insensitive)

A 403 usually means the site blocks scripts; open it in a browser before deciding it is dead.
"""
from __future__ import annotations

import re
import sys
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

LINKS = Path(__file__).resolve().parent.parent / "docs" / "LINKS.md"
HEADERS = {"User-Agent": "Mozilla/5.0 (Code101 link checker)"}


def check(url: str) -> tuple[str, str]:
    for method in ("HEAD", "GET"):
        try:
            req = urllib.request.Request(url, headers=HEADERS, method=method)
            with urllib.request.urlopen(req, timeout=12) as r:
                return url, str(r.status)
        except urllib.error.HTTPError as e:
            if method == "HEAD" and e.code in (403, 404, 405):
                continue
            return url, str(e.code)
        except Exception as e:  # noqa: BLE001 - report any network failure
            return url, type(e).__name__
    return url, "unknown"


def main() -> int:
    track = sys.argv[sys.argv.index("--track") + 1].lower() if "--track" in sys.argv else None
    urls: list[str] = []
    for line in LINKS.read_text(encoding="utf-8").splitlines():
        if line.startswith("|") and (track is None or track in line.lower()):
            urls += re.findall(r"https?://[^\s|)]+", line)
    urls = sorted(set(urls))
    with ThreadPoolExecutor(8) as pool:
        results = list(pool.map(check, urls))
    bad = [(u, s) for u, s in results if s != "200"]
    for u, s in bad:
        print(f"{s:>12}  {u}")
    print(f"{len(urls)} checked, {len(urls) - len(bad)} ok, {len(bad)} not 200")
    return 0


if __name__ == "__main__":
    sys.exit(main())
