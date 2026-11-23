"""Print every operation of an OpenAPI file: method, path, operationId and who may call it."""
import sys
from pathlib import Path

import yaml

HTTP_METHODS = {"get", "put", "post", "delete", "patch"}
path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("mini-openapi.yaml")
spec = yaml.safe_load(path.read_text(encoding="utf-8"))

print(f"{spec['info']['title']} {spec['info']['version']} (OpenAPI {spec['openapi']})")
for url, item in spec["paths"].items():
    for method, operation in item.items():
        if method in HTTP_METHODS:
            print(f"{method.upper():6} {url}  {operation['operationId']}  [{operation['x-access']}]")
