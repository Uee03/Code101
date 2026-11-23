"""Exercise: call the stand-in API (python mock_api.py must be running) and print what comes back."""
import json
import urllib.error
import urllib.request

BASE = "http://127.0.0.1:8000"
TASK_ID = "7a500000-0000-4000-8000-000000000003"
PROJECT_ID = "9a000000-0000-4000-8000-000000000001"
HEADERS = {"Authorization": "Bearer practice"}

# Rung 1: GET the task and print the status code, then the title.
request = urllib.request.Request(f"{BASE}/v1/tasks/{TASK_ID}", headers=HEADERS)
with urllib.request.urlopen(request) as response:
    task = json.loads(response.read())
    print(response.status)
    print(task["title"])

# Rung 2: GET a task id that does not exist. urlopen raises HTTPError for 4xx.
missing = urllib.request.Request(f"{BASE}/v1/tasks/{TASK_ID[:-1]}9", headers=HEADERS)
try:
    urllib.request.urlopen(missing)
except urllib.error.HTTPError as err:
    problem = json.loads(err.read())
    print(err.code, problem["title"])

# Rung 3 (stretch): POST a new task, then print the status and the Location header.
body = json.dumps({"title": "Write the primer lessons", "priority": "high"}).encode("utf-8")
create = urllib.request.Request(
    f"{BASE}/v1/projects/{PROJECT_ID}/tasks",
    data=body,
    headers={**HEADERS, "Content-Type": "application/json"},
    method="POST",
)
with urllib.request.urlopen(create) as response:
    print(response.status, response.headers["Location"])
