from pathlib import Path
import json

files = list(Path("app/schemas").rglob("1.json"))
assert len(files) == 1
schema = json.loads(files[0].read_text(encoding="utf-8"))["database"]
assert schema["version"] == 1
names = sorted(entity["tableName"] for entity in schema["entities"])
assert names == ["account", "comments", "outbox", "projects", "tasks", "teams"]
print("Room schema v1 exported: " + ", ".join(names) + ".")
