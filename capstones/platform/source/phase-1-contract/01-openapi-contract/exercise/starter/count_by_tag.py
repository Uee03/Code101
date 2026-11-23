"""Exercise: print how many operations each tag has, in the order the tags are declared."""
import sys
from pathlib import Path

import yaml

HTTP_METHODS = {"get", "put", "post", "delete", "patch"}
spec = yaml.safe_load(Path(sys.argv[1]).read_text(encoding="utf-8"))

# TODO 1: build a dictionary with every tag name from spec["tags"] and the number 0
# TODO 2: loop over spec["paths"].values(), then over each path item; skip keys that are not in HTTP_METHODS
# TODO 3: add 1 for every tag listed in operation["tags"]
# TODO 4: print one line per tag, for example "Teams: 5"
