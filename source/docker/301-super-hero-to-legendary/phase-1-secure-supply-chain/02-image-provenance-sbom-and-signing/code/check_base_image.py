"""Check image references against a base-image policy (format and allow list only)."""
import json
import re
import sys

DIGEST = re.compile(r"sha256:[0-9a-f]{64}")


def split_reference(reference):
    name, _, digest = reference.partition("@")
    last_part = name.rsplit("/", 1)[-1]
    tag = ""
    if ":" in last_part:
        name, _, tag = name.rpartition(":")
    return name, tag, digest


def check(reference, policy):
    name, tag, digest = split_reference(reference)
    problems = []
    if name not in policy["allowed_repositories"]:
        problems.append(f"repository {name} is not on the allow list")
    if tag in policy["forbidden_tags"] or (not tag and not digest):
        problems.append("mutable tag (latest or no tag)")
    if policy["require_digest"] and not DIGEST.fullmatch(digest):
        problems.append("no sha256 digest pin")
    return problems


def main():
    if len(sys.argv) != 3:
        print("usage: python check_base_image.py <policy.json> <references.txt>")
        return 2
    with open(sys.argv[1], encoding="utf-8") as handle:
        policy = json.load(handle)
    failed = 0
    with open(sys.argv[2], encoding="utf-8") as handle:
        for line in handle:
            reference = line.strip()
            if not reference or reference.startswith("#"):
                continue
            problems = check(reference, policy)
            print(("FAIL " if problems else "PASS ") + reference)
            for problem in problems:
                print("  - " + problem)
            failed += bool(problems)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
