"""List, per phase, which code files are new, changed or identical to the previous phase."""
import filecmp
import json
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent / "source"
phases = [
    ("phase-1-skeleton", "01-skeleton"),
    ("phase-2-data", "02-data"),
    ("phase-3-identity", "03-identity"),
    ("phase-4-run-and-ship", "04-run-and-ship"),
    ("phase-5-hardening", "05-hardening"),
]
PLATFORM = {"db/schema.sql", "db/seed.sql", "keycloak/realm-tasksteams.json", "scripts/conformance.py"}


def files(code: Path) -> set[str]:
    return {p.relative_to(code).as_posix() for p in code.rglob("*") if p.is_file() and "__pycache__" not in p.parts}


prev = None
result = {}
for phase, lesson in phases:
    code = root / phase / lesson / "code"
    current = files(code)
    new, changed, same = [], [], []
    for rel in sorted(current):
        if rel in PLATFORM:
            same.append(rel)
        elif prev is None or rel not in files(prev):
            new.append(rel)
        elif filecmp.cmp(code / rel, prev / rel, shallow=False):
            same.append(rel)
        else:
            changed.append(rel)
    removed = sorted(files(prev) - current) if prev else []
    result[phase] = {"new": new, "changed": changed, "same": same, "removed": removed}
    prev = code
if len(sys.argv) > 1 and sys.argv[1] == "skips":
    print(json.dumps({p: ["code/" + f for f in r["same"]] for p, r in result.items()}, indent=2))
else:
    for phase, r in result.items():
        print(phase)
        for key in ("new", "changed", "removed"):
            print(f"  {key}: {r[key]}")
        print(f"  same: {len(r['same'])}")
