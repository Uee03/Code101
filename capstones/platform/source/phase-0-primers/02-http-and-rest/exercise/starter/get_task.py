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
    print(response.status)  # TODO: print the title of the task on the next line

# Rung 2: GET a task id that does not exist. urlopen raises HTTPError for 4xx.
missing = urllib.request.Request(f"{BASE}/v1/tasks/{TASK_ID[:-1]}9", headers=HEADERS)
try:
    urllib.request.urlopen(missing)
except urllib.error.HTTPError as err:
    problem = json.loads(err.read())
    pass  # TODO: print the status code and the problem title, for example: 404 Not Found

# Rung 3 (stretch): POST a new task, then print the status and the Location header.
# Hint: urllib.request.Request(url, data=..., headers=..., method="POST") needs bytes in data
# and a Content-Type header with the value application/json.
