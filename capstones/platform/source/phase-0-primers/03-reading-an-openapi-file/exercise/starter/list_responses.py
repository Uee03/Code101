"""Exercise: list the response codes and the security of every operation."""
import sys
from pathlib import Path

import yaml

HTTP_METHODS = {"get", "put", "post", "delete", "patch"}
spec = yaml.safe_load(Path(sys.argv[1]).read_text(encoding="utf-8"))

for url, item in spec["paths"].items():
    for method, operation in item.items():
        if method in HTTP_METHODS:
            codes = []  # TODO rung 1: put the keys of operation["responses"] here
            print(f"{method.upper()} {url}: {', '.join(codes)}")
            # TODO rung 2: print "  security: no token needed" when the security list is empty,
            # otherwise "  security: scope " followed by the scopes.
            # Use operation.get("security", spec["security"]) so the top-level default applies.
