"""Exercise 4: check a Dockerfile for the four rules of chapter 04 (solution).

Run:  python check_dockerfile.py            (checks ../../code/Dockerfile)
      python check_dockerfile.py path/to/Dockerfile
"""
import sys
from pathlib import Path


def instructions(text):
    """The instruction lines (FROM, USER, ...) without comments and blank lines."""
    return [line.strip() for line in text.splitlines() if line.strip() and not line.strip().startswith("#")]


def pinned_images(lines):
    images = [line.split()[1] for line in lines if line.upper().startswith("FROM ")]
    return bool(images) and all(":" in image and not image.endswith(":latest") for image in images)


def multi_stage(lines):
    return sum(1 for line in lines if line.upper().startswith("FROM ")) >= 2


def non_root_user(lines):
    users = [line.split(None, 1)[1].split(":")[0] for line in lines if line.upper().startswith("USER ")]
    return bool(users) and users[-1] not in ("root", "0")


def has_healthcheck(lines):
    return any(line.upper().startswith("HEALTHCHECK") for line in lines)


CHECKS = [
    ("pinned base images", pinned_images),
    ("multi-stage build", multi_stage),
    ("runs as a non-root user", non_root_user),
    ("has a health check", has_healthcheck),
]

if __name__ == "__main__":
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[2] / "code" / "Dockerfile"
    lines = instructions(path.read_text(encoding="utf-8"))
    passed = 0
    for name, check in CHECKS:
        ok = check(lines)
        passed += ok
        print(("PASS" if ok else "FAIL"), name)
    print(f"{passed} of {len(CHECKS)} checks passed")
