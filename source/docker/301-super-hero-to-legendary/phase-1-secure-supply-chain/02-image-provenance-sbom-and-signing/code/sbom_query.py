"""List packages in an SPDX JSON SBOM whose names contain any search word."""
import json
import sys


def main():
    if len(sys.argv) < 3:
        print("usage: python sbom_query.py <sbom.json> <word> [word ...]")
        return 2
    with open(sys.argv[1], encoding="utf-8") as handle:
        document = json.load(handle)
    packages = document.get("packages", [])
    words = [word.lower() for word in sys.argv[2:]]
    print(f"{len(packages)} packages in {sys.argv[1]}")
    hits = 0
    for package in sorted(packages, key=lambda item: item.get("name", "")):
        name = package.get("name", "")
        if any(word in name.lower() for word in words):
            print(f"  {name} {package.get('versionInfo', '(no version)')}")
            hits += 1
    return 0 if hits else 1


if __name__ == "__main__":
    sys.exit(main())
