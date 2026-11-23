#!/usr/bin/env python3
"""Check that openapi.yaml is a valid OpenAPI 3.1 document and follows the platform rules."""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
DEPS = HERE / ".deps"  # optional folder: the lab verifier installs the packages here
if DEPS.is_dir():
    sys.path.insert(0, str(DEPS))

try:
    import yaml
    from openapi_spec_validator import validate
except ImportError:
    sys.exit("Missing packages. Run: pip install -r requirements.txt")

METHODS = {"get", "put", "post", "delete", "patch", "options", "head"}


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "openapi.yaml"
    spec = yaml.safe_load(path.read_text(encoding="utf-8"))
    try:
        validate(spec)
    except Exception as exc:  # the validator raises many types; keep the first line, without the dumped document
        print(f"INVALID: {type(exc).__name__}: {str(exc).splitlines()[0].split(' within {')[0][:200]}")
        return 1

    problems = []
    seen_ids = set()
    count = 0
    for url, item in spec["paths"].items():
        for method, op in item.items():
            if method not in METHODS:
                continue
            count += 1
            op_id = op.get("operationId")
            if not op_id or op_id in seen_ids:
                problems.append(f"{method.upper()} {url}: missing or duplicate operationId")
            seen_ids.add(op_id)
            if "x-access" not in op:
                problems.append(f"{method.upper()} {url}: missing x-access")
            if method in {"patch", "put", "post", "delete"} and not any(c.startswith("4") for c in map(str, op["responses"])):
                problems.append(f"{method.upper()} {url}: no 4xx response documented")
    if problems:
        print("\n".join(problems))
        return 1
    print(f"OpenAPI {spec['openapi']} valid: {count} operations, {len(spec['components']['schemas'])} schemas")
    return 0


if __name__ == "__main__":
    sys.exit(main())
