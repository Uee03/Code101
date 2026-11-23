"""Exercise: print how many operations each tag has, in the order the tags are declared."""
import sys
from pathlib import Path

import yaml

HTTP_METHODS = {"get", "put", "post", "delete", "patch"}
spec = yaml.safe_load(Path(sys.argv[1]).read_text(encoding="utf-8"))

counts = {tag["name"]: 0 for tag in spec["tags"]}
for item in spec["paths"].values():
    for method, operation in item.items():
        if method in HTTP_METHODS:
            for tag in operation["tags"]:
                counts[tag] += 1
for tag, count in counts.items():
    print(f"{tag}: {count}")
