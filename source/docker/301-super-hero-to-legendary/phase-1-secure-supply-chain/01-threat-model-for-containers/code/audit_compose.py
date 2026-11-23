"""Tiny line-based Compose audit: a teaching lint, not a YAML parser."""
import re
import sys

FORBIDDEN = [
    ("C1", r"^\s*privileged:\s*true", "privileged container disables most isolation"),
    ("C2", r"/var/run/docker\.sock", "Docker socket mounted: root-equivalent control of the host engine"),
    ("C3", r"""^\s*network_mode:\s*["']?host""", "host network mode removes network isolation"),
    ("C4", r"""^\s*pid:\s*["']?host""", "host PID namespace shares the host process list"),
    ("C5", r"^\s*image:\s*([^:@\s]+|\S+:latest)\s*$", "image has no tag or uses latest (mutable)"),
    ("C6", r"""^\s*-\s*["']?(0\.0\.0\.0:)?\d+:\d+["']?\s*$""", "port published on every interface"),
    ("C7", r"^\s*-?\s*[A-Z_]*(PASSWORD|SECRET|TOKEN)\s*[=:]\s*[^\s$]\S*", "secret value written in the file"),
    ("C8", r"seccomp[=:]\s*unconfined", "seccomp filtering switched off"),
    ("C9", r"^\s*cap_add:", "extra Linux capabilities added: justify each one"),
]

REQUIRED = [
    ("R1", r"^\s*user:\s*\S+", "no user: key, so the process may run as root"),
    ("R2", r"^\s*read_only:\s*true", "no read_only: true, so the root filesystem is writable"),
    ("R3", r"^\s*cap_drop:", "no cap_drop, so default capabilities are kept"),
    ("R4", r"no-new-privileges:\s*true", "no no-new-privileges option"),
]


def audit(path):
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    findings = []
    for number, line in enumerate(lines, start=1):
        if line.lstrip().startswith("#"):
            continue
        for rule_id, pattern, message in FORBIDDEN:
            if re.search(pattern, line):
                findings.append(f"{path}:{number}: [{rule_id}] {message}")
    text = "\n".join(line for line in lines if not line.lstrip().startswith("#"))
    for rule_id, pattern, message in REQUIRED:
        if not re.search(pattern, text, re.MULTILINE):
            findings.append(f"{path}: [{rule_id}] {message}")
    return findings


def main():
    if len(sys.argv) != 2:
        print("usage: python audit_compose.py <compose-file>")
        return 2
    findings = audit(sys.argv[1])
    for finding in findings:
        print(finding)
    if findings:
        print(f"{len(findings)} finding(s)")
        return 1
    print(f"{sys.argv[1]}: no findings")
    return 0


if __name__ == "__main__":
    sys.exit(main())
