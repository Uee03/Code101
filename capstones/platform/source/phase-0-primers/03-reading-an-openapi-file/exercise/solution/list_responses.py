"""Exercise: list the response codes and the security of every operation."""
import sys
from pathlib import Path

import yaml

HTTP_METHODS = {"get", "put", "post", "delete", "patch"}
spec = yaml.safe_load(Path(sys.argv[1]).read_text(encoding="utf-8"))

for url, item in spec["paths"].items():
    for method, operation in item.items():
        if method in HTTP_METHODS:
            codes = list(operation["responses"])
            print(f"{method.upper()} {url}: {', '.join(codes)}")
            security = operation.get("security", spec["security"])
            if not security:
                print("  security: no token needed")
            else:
                print("  security: scope " + ", ".join(security[0]["oidc"]))
