import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Finding:
    check: str
    ok: bool
    detail: str


VERSION_PATTERN = re.compile(r'__version__\s*=\s*"([^"]+)"')


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def check_dockerfile(text: str) -> list[Finding]:
    stages = set(re.findall(r"^FROM\s+.*?\bAS\s+(\S+)", text, re.MULTILINE | re.IGNORECASE))
    images = re.findall(r"^FROM\s+(?:--\S+\s+)?(\S+)", text, re.MULTILINE)
    unpinned = [
        image for image in images if image not in stages and (":" not in image or image.endswith(":latest"))
    ]
    return [
        Finding(
            "base image is pinned",
            bool(images) and not unpinned,
            "pin a version tag, not latest: " + ", ".join(unpinned),
        ),
        Finding(
            "runs as a non-root user",
            bool(re.search(r"^USER\s+(?!root\b)\S+", text, re.MULTILINE)),
            "add a USER line that is not root",
        ),
        Finding(
            "has a HEALTHCHECK",
            bool(re.search(r"^HEALTHCHECK\b", text, re.MULTILINE)),
            "add a HEALTHCHECK instruction",
        ),
    ]


def check_project(root: Path) -> list[Finding]:
    match = VERSION_PATTERN.search(read_text(root / "src" / "taskservice" / "__init__.py"))
    version = match.group(1) if match else ""
    requirements = [
        line.strip()
        for line in read_text(root / "requirements.txt").splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]
    dockerfile = read_text(root / "Dockerfile")
    findings = [
        Finding(
            "version is MAJOR.MINOR.PATCH",
            bool(re.fullmatch(r"\d+\.\d+\.\d+", version)),
            'set __version__ = "1.2.3" in src/taskservice/__init__.py',
        ),
        Finding(
            "CHANGELOG has an entry for this version",
            bool(version) and f"## [{version}]" in read_text(root / "CHANGELOG.md"),
            "add a '## [x.y.z]' heading to CHANGELOG.md",
        ),
        Finding(
            "requirements are pinned with ==",
            bool(requirements) and all("==" in line for line in requirements),
            "pin every line, for example fastapi==0.165.0",
        ),
    ]
    findings += check_dockerfile(dockerfile)
    findings += [
        Finding(
            ".dockerignore keeps .env out of the image",
            ".env" in read_text(root / ".dockerignore"),
            "create .dockerignore listing .env",
        ),
        Finding(
            "no .env file in the project",
            not (root / ".env").exists(),
            "remove .env from the project and add it to .gitignore",
        ),
        Finding(
            "CI workflow exists",
            (root / ".github" / "workflows" / "ci.yml").exists(),
            "add .github/workflows/ci.yml",
        ),
    ]
    return findings


def main(argv: list[str]) -> int:
    root = Path(argv[1]) if len(argv) > 1 else Path(".")
    findings = check_project(root)
    for finding in findings:
        status = "PASS" if finding.ok else "FAIL"
        suffix = "" if finding.ok else f": {finding.detail}"
        print(f"{status}  {finding.check}{suffix}")
    failed = sum(1 for finding in findings if not finding.ok)
    print(f"{len(findings) - failed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
