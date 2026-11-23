---
track: capstone
level: 101
phase: 0
phase_name: primers
lesson: 02
title: "HTTP and REST"
time: 45 min
prerequisites: [01-git-and-github]
versions: { python: "3.10 or newer (only runs the stand-in API)", curl: "any version that ships with Windows 10/11, macOS or Linux" }
verified: not yet run
source: capstones/platform/source/phase-0-primers/02-http-and-rest/
assets: []
---

# 02. HTTP and REST

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- name the parts of an HTTP request and response (method, URL, headers, body, status code);
- choose the right method and status code for an action on a task;
- explain what makes an API "REST" and read the paths of the Tasks and Teams API;
- send your first requests with `curl` and with PowerShell's `Invoke-RestMethod`, and read the answers, including an error.

## Recap
From lesson 01:
1. What does `git commit` do? <details><summary>Answer</summary>It saves a snapshot of the staged changes with a caption.</details>
2. Which file holds the real passwords, and is it committed? <details><summary>Answer</summary>`.env`; it is never committed. `.env.example` (fake values) is.</details>

## Why it matters
Picture a restaurant. You (the **client**) give the waiter an order slip: what you want and for which table. The kitchen (the **server**) cooks and the waiter brings back a plate plus a receipt that says whether it worked ("served", "sold out", "you are not allowed in the VIP room"). **HTTP** is that order-slip-and-receipt agreement for the web. Every browser page, every phone app and every backend of this capstone speaks it, so you must be able to read it. **REST** is a set of habits for naming the things on the menu so that every API feels the same.

## What you will build
You will start a tiny stand-in for the Tasks and Teams API on port 8000 (a short Python file, because no real backend exists until a backend capstone) and send it five requests: health, a task without a token (an error), a task with a token, a new task, and an invalid new task (another error). You do each one with `curl` and with PowerShell.

## Before you start
- Python 3.10 or newer (`python --version`; use `python3` on macOS and Linux). Python only runs the stand-in server; you write no Python here.
- `curl`: on Windows 10 and 11 the program is `curl.exe`. Check with `curl.exe --version`. **In Windows PowerShell 5.1 the word `curl` alone is a different command (an alias), so always type `curl.exe` on Windows.** On macOS and Linux type `curl`.
- Two terminal windows. Window A runs the server, window B sends requests.
- Port 8000 free (stop any other backend first).
- Time: about 45 minutes.
- Source pack (optional): every file is shown in full here; the finished files are in https://github.com/Uee03/Code101 under `capstones/platform/source/phase-0-primers/02-http-and-rest/`.

## The ideas first
### The parts of a request and a response
A **request** has four parts, a **response** has three:

| Part | In a request | In a response |
|------|--------------|---------------|
| First line | **Method** and **URL**, for example `GET /health` | **Status code**, for example `200 OK` |
| Headers | `Name: value` lines that describe the message, for example `Authorization: Bearer ...` | `Name: value` lines, for example `Content-Type: application/json` |
| Body | Optional data you send (JSON) | The data you get back (JSON) |

A **URL** is the address. `http://127.0.0.1:8000/v1/tasks/7a50...0003?limit=5` has these pieces:

| Piece | Example | Meaning |
|-------|---------|---------|
| scheme | `http` | The protocol. Real systems use `https` (encrypted). |
| host | `127.0.0.1` (also `localhost`) | Which computer: your own. |
| port | `8000` | Which program on that computer: the platform backend. |
| path | `/v1/tasks/7a50...0003` | Which thing. |
| query | `?limit=5` | Optional filters after `?`. |

### Methods (what you want to do)
| Method | Meaning | Platform example | Safe to repeat? |
|--------|---------|------------------|-----------------|
| `GET` | Read | `GET /v1/tasks/{taskId}` | yes |
| `POST` | Create, or run an action | `POST /v1/projects/{projectId}/tasks` | no: two posts make two tasks |
| `PUT` | Replace, or create at a known address | `PUT /v1/teams/{teamId}/members/{userId}` | yes |
| `PATCH` | Change some fields | `PATCH /v1/tasks/{taskId}` | usually |
| `DELETE` | Remove | `DELETE /v1/tasks/{taskId}` | yes (the second call just says 404) |

### Status codes (what happened)
The first digit tells the story: **2xx** worked, **3xx** look elsewhere or nothing changed, **4xx** *you* made a mistake, **5xx** the *server* failed.

| Code | Name | Meaning in the Tasks and Teams API |
|------|------|------------------------------------|
| 200 | OK | Read or change succeeded; the body has the result. |
| 201 | Created | A new thing exists; the `Location` header says where. |
| 204 | No Content | Deleted; there is no body. |
| 304 | Not Modified | Your saved copy is still current (you sent `If-None-Match`). |
| 400 | Bad Request | The request itself is broken, for example invalid JSON. |
| 401 | Unauthorized | No valid token. (The name is historical: it means "not signed in".) |
| 403 | Forbidden | Signed in, but not allowed. |
| 404 | Not Found | No such thing, or you may not know it exists. |
| 409 | Conflict | The action clashes with the current state, for example a duplicate name. |
| 412 | Precondition Failed | Your `If-Match` version is stale: someone else changed it first. |
| 422 | Unprocessable Content | The JSON is fine but a field is wrong, for example an empty title. |
| 428 | Precondition Required | You must send `If-Match`. |
| 429 | Too Many Requests | Slow down; `Retry-After` says for how many seconds. |
| 503 | Service Unavailable | A dependency such as the database is down. |

The words after the number differ slightly between servers and Python versions; the **number** is what programs check.

### Headers you will meet
| Header | Direction | Meaning |
|--------|-----------|---------|
| `Content-Type` | both | The format of the body, for example `application/json`. Errors use `application/problem+json`. |
| `Accept` | request | The formats you can read. |
| `Authorization` | request | `Bearer <token>`: who you are (lesson 04). |
| `ETag` | response | A version label of one thing, for example `"1"`. |
| `If-Match` | request | "Only change it if its version is still this." |
| `Location` | response | The address of the thing just created. |
| `Retry-After` | response | Seconds to wait before trying again. |

### JSON
**JSON** is the text format for bodies. It has objects `{ "name": value }`, lists `[ ... ]`, strings in double quotes, numbers, `true`, `false` and `null` (meaning "nothing here", for example a task with no assignee). Keys and strings **must** use double quotes, and there is no comma after the last item.

```json
{"title": "Configure Keycloak", "priority": "urgent", "assigneeId": null}
```

### REST in five habits
**REST** is a style for naming things. The platform follows it like this:
1. **Nouns, not verbs.** The path names a *resource* (a thing): `/v1/tasks/{taskId}`, not `/getTask`. The method is the verb.
2. **Plural collections, then an id.** `/v1/teams` is the list; `/v1/teams/{teamId}` is one team.
3. **Nesting shows ownership.** `/v1/teams/{teamId}/projects` are the projects of one team; `/v1/projects/{projectId}/tasks` are the tasks of one project. Once a thing has its own id, it also has a short top-level address: `/v1/tasks/{taskId}`.
4. **Actions that are not plain changes become a sub-resource with POST.** `POST /v1/tasks/{taskId}/complete` marks a task done (it runs a stored procedure on the database side).
5. **Version in the path.** `/v1/...` lets a future `/v2/...` live next to it. `/health` is infrastructure and has no version.

## Steps
### Step 1. Save the stand-in API
Create a folder `http-primer`. Inside it create the file `mock_api.py` with exactly this content. It answers like the real API for a handful of requests and accepts **any** bearer token (the real backends check the token, lesson 04).

**File: `mock_api.py`**
```python
"""A tiny stand-in for the Tasks and Teams API. Standard library only. Practice use only."""
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PROJECT_ID = "9a000000-0000-4000-8000-000000000001"
TASK_ID = "7a500000-0000-4000-8000-000000000003"
NEW_TASK_ID = "7a500000-0000-4000-8000-0000000000aa"
TASK = {
    "id": TASK_ID,
    "projectId": PROJECT_ID,
    "title": "Configure Keycloak",
    "description": "Realm, clients, roles and users.",
    "status": "in_progress",
    "priority": "urgent",
    "assigneeId": "ca401000-0000-4000-8000-000000000003",
    "dueDate": "2027-02-05",
    "completedAt": None,
    "createdBy": "a11ce000-0000-4000-8000-000000000001",
    "version": 1,
    "createdAt": "2026-11-23T08:00:00Z",
    "updatedAt": "2026-11-23T08:00:00Z",
}


class Handler(BaseHTTPRequestHandler):
    def send(self, status, body, content_type="application/json", extra=None):
        data = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        for name, value in (extra or {}).items():
            self.send_header(name, value)
        self.end_headers()
        self.wfile.write(data)

    def problem(self, status, title, detail):
        self.send(status, {
            "type": "https://code101.example/problems/" + title.lower().replace(" ", "-"),
            "title": title,
            "status": status,
            "detail": detail,
            "instance": self.path,
        }, "application/problem+json")

    def signed_in(self):
        return self.headers.get("Authorization", "").startswith("Bearer ")

    def do_GET(self):
        if self.path == "/health":
            self.send(200, {"status": "ok", "version": "1.0.0", "database": "up"})
        elif self.path.startswith("/v1/tasks/"):
            if not self.signed_in():
                self.problem(401, "Unauthorized", "A bearer access token is required.")
            elif self.path == "/v1/tasks/" + TASK_ID:
                self.send(200, TASK, extra={"ETag": '"1"'})
            else:
                self.problem(404, "Not Found", "No such task.")
        else:
            self.problem(404, "Not Found", "No such path.")

    def do_POST(self):
        if self.path != "/v1/projects/" + PROJECT_ID + "/tasks":
            self.problem(404, "Not Found", "No such path.")
            return
        if not self.signed_in():
            self.problem(401, "Unauthorized", "A bearer access token is required.")
            return
        length = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            self.problem(400, "Bad Request", "The body is not valid JSON.")
            return
        title = body.get("title") if isinstance(body, dict) else None
        if not isinstance(title, str) or not 1 <= len(title) <= 200:
            self.problem(422, "Validation failed", "The title must be 1 to 200 characters.")
            return
        created = dict(
            TASK,
            id=NEW_TASK_ID,
            title=title,
            description=body.get("description", ""),
            status="todo",
            priority=body.get("priority", "medium"),
            assigneeId=None,
            dueDate=None,
        )
        self.send(201, created, extra={
            "Location": "http://localhost:8000/v1/tasks/" + NEW_TASK_ID,
            "ETag": '"1"',
        })


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 8000), Handler)
    print("Stand-in API on http://localhost:8000 (press Ctrl+C to stop)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("Stopped")
```

What it does, in the order a request meets it:

| Lines | Meaning |
|-------|---------|
| `PROJECT_ID`, `TASK_ID`, `TASK` | The ids and the task from the platform's seed data (task "Configure Keycloak" in project PLAT). The field names are the ones of the `Task` schema in the contract. `None` becomes JSON `null`. |
| `class Handler` | One object answers one request. `do_GET` runs for `GET`, `do_POST` for `POST`. |
| `send` | Builds a response: the status line, the `Content-Type` and `Content-Length` headers, extra headers (`ETag`, `Location`) and the JSON body. |
| `problem` | An error body in the **problem details** shape (`type`, `title`, `status`, `detail`, `instance`), sent as `application/problem+json`. |
| `signed_in` | True when the `Authorization` header starts with `Bearer `. The stand-in does not look at the token itself. |
| `do_GET` | `/health` gives 200. A path under `/v1/tasks/` needs a token (401), then answers 200 for the known id and 404 for any other id. |
| `do_POST` | Only `/v1/projects/<PROJECT_ID>/tasks` exists (404 otherwise). It needs a token (401), valid JSON (400) and a title of 1 to 200 characters (422), then answers 201 with `Location` and `ETag`. |
| last block | Listens on `127.0.0.1:8000` until you press Ctrl+C. |

### Step 2. Start the server (window A)
**Terminal A (folder: `http-primer`)**
```powershell
python mock_api.py
```
Expected output (the program now keeps running, so the prompt does not come back):
```text
Stand-in API on http://localhost:8000 (press Ctrl+C to stop)
```
Leave window A open. Every request you send later adds one log line here, such as `127.0.0.1 - - [23/Nov/2026 15:30:12] "GET /health HTTP/1.1" 200 -` (date and time are yours).

### Step 3. Your first request: health (window B)
Open window B in the same folder.

**Terminal B (folder: `http-primer`)**
```powershell
curl.exe -i http://127.0.0.1:8000/health
```
`-i` prints the response headers too. **Predict first:** which status code and which body do you expect? The path `/health` is handled by the first branch of `do_GET`: 200 and `{"status": "ok", ...}`. Expected output (your `Server` and `Date` lines show your Python version and the current time):
```text
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.x.y
Date: <current date and time> GMT
Content-Type: application/json
Content-Length: 54

{"status": "ok", "version": "1.0.0", "database": "up"}
```
The first line is the **status line** (this tiny server says `HTTP/1.0`; real ones say `HTTP/1.1` or `HTTP/2`). Then the headers, then an empty line, then the **body**. Without `-i`, curl prints only the body. Use `-s` (silent) to hide the progress bar when you pipe or copy output:
```powershell
curl.exe -s http://127.0.0.1:8000/health
```
```text
{"status": "ok", "version": "1.0.0", "database": "up"}
```
The same call in PowerShell. `Invoke-RestMethod` sends the request, reads the JSON and returns an **object**, so you can use `.status` and `.database` like properties:

**Terminal B (PowerShell)**
```powershell
Invoke-RestMethod -Uri http://127.0.0.1:8000/health
```
```text
status version database
------ ------- --------
ok     1.0.0   up
```
On macOS and Linux, `curl -s http://127.0.0.1:8000/health` is the equivalent; `Invoke-RestMethod` exists only in PowerShell.

### Step 4. A request that fails: no token
**Terminal B**
```powershell
curl.exe -i http://127.0.0.1:8000/v1/tasks/7a500000-0000-4000-8000-000000000003
```
**Predict:** the path starts with `/v1/tasks/` and there is no `Authorization` header, so `signed_in()` is false. Expected output (the `Server`, `Date` and `Content-Length` lines are left out here):
```text
HTTP/1.0 401 Unauthorized
Content-Type: application/problem+json

{"type": "https://code101.example/problems/unauthorized", "title": "Unauthorized", "status": 401, "detail": "A bearer access token is required.", "instance": "/v1/tasks/7a500000-0000-4000-8000-000000000003"}
```
Read the error like a receipt: the **code** (401) says the class of problem, `Content-Type: application/problem+json` says the body is a standard error, `title` is the same for every 401, `detail` explains this one, and `instance` is the path that failed. The domain `code101.example` is reserved for examples and never opens a page.

### Step 5. Send a token and read a task
`-H` adds a header. `Bearer practice` means "the token is the word practice"; the stand-in accepts any token.

**Terminal B**
```powershell
curl.exe -i -H "Authorization: Bearer practice" http://127.0.0.1:8000/v1/tasks/7a500000-0000-4000-8000-000000000003
```
Expected output (without `Server`, `Date` and `Content-Length`):
```text
HTTP/1.0 200 OK
Content-Type: application/json
ETag: "1"

{"id": "7a500000-0000-4000-8000-000000000003", "projectId": "9a000000-0000-4000-8000-000000000001", "title": "Configure Keycloak", "description": "Realm, clients, roles and users.", "status": "in_progress", "priority": "urgent", "assigneeId": "ca401000-0000-4000-8000-000000000003", "dueDate": "2027-02-05", "completedAt": null, "createdBy": "a11ce000-0000-4000-8000-000000000001", "version": 1, "createdAt": "2026-11-23T08:00:00Z", "updatedAt": "2026-11-23T08:00:00Z"}
```
The `ETag: "1"` header is the version of this task (the `version` field in quotes). Later, `PATCH` will send it back in `If-Match`. The same call in PowerShell, keeping only three fields so the output is short:

**Terminal B (PowerShell)**
```powershell
$headers = @{ Authorization = "Bearer practice" }
Invoke-RestMethod -Uri http://127.0.0.1:8000/v1/tasks/7a500000-0000-4000-8000-000000000003 -Headers $headers | Select-Object title, status, priority
```
```text
title              status      priority
-----              ------      --------
Configure Keycloak in_progress urgent
```
`@{ Name = value }` is a PowerShell hashtable; `-Headers` turns it into request headers. `Select-Object` keeps the named properties.

Ask for a task that does not exist (the last digit is changed to 9). **Predict:** the token is fine, so not 401; the id is unknown, so 404:
```powershell
curl.exe -i -H "Authorization: Bearer practice" http://127.0.0.1:8000/v1/tasks/7a500000-0000-4000-8000-000000000009
```
```text
HTTP/1.0 404 Not Found
Content-Type: application/problem+json

{"type": "https://code101.example/problems/not-found", "title": "Not Found", "status": 404, "detail": "No such task.", "instance": "/v1/tasks/7a500000-0000-4000-8000-000000000009"}
```

### Step 6. Create a task with POST
A `POST` carries a body. Save two small JSON files next to `mock_api.py`.

**File: `new-task.json`**
```json
{"title": "Write the primer lessons", "priority": "high"}
```
**File: `bad-task.json`**
```json
{"title": ""}
```
Why files? Quotes inside a command line are handled differently by PowerShell, cmd and bash; `--data "@file"` reads the body from a file and avoids the trouble. Send the good one:

**Terminal B**
```powershell
curl.exe -i -X POST -H "Authorization: Bearer practice" -H "Content-Type: application/json" --data "@new-task.json" http://127.0.0.1:8000/v1/projects/9a000000-0000-4000-8000-000000000001/tasks
```
`-X POST` sets the method. `Content-Type: application/json` tells the server how to read the body. **Predict:** token present, JSON valid, title has 24 characters, so 201 with a `Location`. Expected output (without `Server`, `Date` and `Content-Length`):
```text
HTTP/1.0 201 Created
Content-Type: application/json
Location: http://localhost:8000/v1/tasks/7a500000-0000-4000-8000-0000000000aa
ETag: "1"

{"id": "7a500000-0000-4000-8000-0000000000aa", "projectId": "9a000000-0000-4000-8000-000000000001", "title": "Write the primer lessons", "description": "", "status": "todo", "priority": "high", "assigneeId": null, "dueDate": null, "completedAt": null, "createdBy": "a11ce000-0000-4000-8000-000000000001", "version": 1, "createdAt": "2026-11-23T08:00:00Z", "updatedAt": "2026-11-23T08:00:00Z"}
```
The server chose `status: todo` and `version: 1`; you only sent the title and the priority. The stand-in does not save anything: a real backend would store the task and give it a new id each time. Now the invalid one:

**Terminal B**
```powershell
curl.exe -i -X POST -H "Authorization: Bearer practice" -H "Content-Type: application/json" --data "@bad-task.json" http://127.0.0.1:8000/v1/projects/9a000000-0000-4000-8000-000000000001/tasks
```
The JSON is valid, but an empty title breaks the rule (1 to 200 characters), so **422**. Expected output (without `Server`, `Date` and `Content-Length`; the words after `422` may read `Unprocessable Entity` or `Unprocessable Content`, depending on your Python version):
```text
HTTP/1.0 422 Unprocessable Content
Content-Type: application/problem+json

{"type": "https://code101.example/problems/validation-failed", "title": "Validation failed", "status": 422, "detail": "The title must be 1 to 200 characters.", "instance": "/v1/projects/9a000000-0000-4000-8000-000000000001/tasks"}
```
The same create in PowerShell. `ConvertTo-Json` turns a hashtable into JSON text:

**Terminal B (PowerShell)**
```powershell
$body = @{ title = "Write the primer lessons"; priority = "high" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8000/v1/projects/9a000000-0000-4000-8000-000000000001/tasks -Headers $headers -ContentType "application/json" -Body $body | Select-Object id, title, status, priority
```
```text
id                                   title                    status priority
--                                   -----                    ------ --------
7a500000-0000-4000-8000-0000000000aa Write the primer lessons todo   high
```
**What does PowerShell do with an error?** `Invoke-RestMethod` *throws* on 4xx and 5xx instead of returning the body. Try the unauthenticated call (no `-Headers`):
```powershell
Invoke-RestMethod -Uri http://127.0.0.1:8000/v1/tasks/7a500000-0000-4000-8000-000000000003
```
In Windows PowerShell 5.1 the typical message is `Invoke-RestMethod : The remote server returned an error: (401) Unauthorized.`; in PowerShell 7 it reads `Response status code does not indicate success: 401 (Unauthorized).` To *see* the problem body, use `curl.exe -i` as above.

### Step 7. Stop the server
Go to window A and press **Ctrl+C**. It prints `Stopped`. This frees port 8000 for a real backend later; **the real backends need a real token** from Keycloak, which is lesson 04.

## Run it
Run the whole set again quickly and check each status code against the table in "The ideas first":

| Request | Expected status |
|---------|-----------------|
| `GET /health` | 200 |
| `GET /v1/tasks/7a50...0003` without a token | 401 |
| the same with `Authorization: Bearer practice` | 200 |
| the same with the last digit changed to `9` | 404 |
| `POST .../tasks` with `new-task.json` | 201 |
| `POST .../tasks` with `bad-task.json` | 422 |

## How it works
- **Stateless.** Each request carries everything the server needs (the token, the path, the body). The server remembers nothing between two requests. That is why headers such as `Authorization` repeat on every call.
- **Content negotiation, in small.** `Content-Type` says what you send, `Accept` says what you want back. The platform speaks JSON everywhere and `application/problem+json` for errors.
- **Why 401 and 403 differ.** 401: the server does not know who you are. 403: it knows, and says no. Mixing them up is one of the most common API bugs.
- **Why 404 can hide things.** For a team you do not belong to, the platform answers 404, so a stranger cannot even learn that the team exists.
- **Misconception to drop:** "a 200 means success." The *code* is the success signal; some bad APIs send 200 with `{"error": ...}` in the body. The platform never does.

## Try it
Starter: `exercise/starter/get_task.py`. Copy it next to `mock_api.py`, start the server in window A and run `python get_task.py` in window B.
1. **Guided.** In the first block print the status code and then the title (`Configure Keycloak`).
2. **Change.** Fill the `TODO` in the second block so a missing task prints `404 Not Found`. `urlopen` raises `HTTPError` for 4xx; the `err.code` and the body hold the details.
3. **Stretch (no single answer).** Add the `POST` that creates a task and prints the status and the `Location` header. How would you make the script stop with a clear message when the server is not running?

The starter file:

**File: `exercise/starter/get_task.py`**
```python
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
```

<details><summary>Solution</summary>

**File: `exercise/solution/get_task.py`**
```python
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
```
Expected output:
```text
200
Configure Keycloak
404 Not Found
201 http://localhost:8000/v1/tasks/7a500000-0000-4000-8000-0000000000aa
```
`TASK_ID[:-1]` drops the last character and `+ "9"` replaces it, giving an unknown id. `{**HEADERS, ...}` copies the dictionary and adds one more header. For the stretch question: wrap the first request in `try ... except urllib.error.URLError` and print "Start mock_api.py first" (connection refused raises `URLError`, which `HTTPError` is a kind of; catch `HTTPError` first when you need both).

</details>

## Check yourself
1. Which method and path would you use to read task `7a50...0003`? <details><summary>Answer</summary>`GET /v1/tasks/7a500000-0000-4000-8000-000000000003`.</details>
2. A request returns 403 with a valid token. What does that tell you? <details><summary>Answer</summary>The server knows who you are and refuses the action: your role, scope or team membership does not allow it. A missing or bad token would be 401.</details>
3. **Predict:** what status do you get for `POST` with the body `{"title": "x"` (the closing brace is missing)? <details><summary>Answer</summary>400: the JSON itself is broken. 422 is for well-formed JSON with an invalid field.</details>
4. Why is `/v1/tasks/{taskId}/complete` a `POST` and not a `GET`? <details><summary>Answer</summary>It changes data; `GET` must be safe to repeat and must not change anything.</details>
5. Which header carries the new task's address after a create? <details><summary>Answer</summary>`Location`, with status 201.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `curl: (7) Failed to connect to 127.0.0.1 port 8000` | The stand-in is not running. | Start `python mock_api.py` in window A. |
| `OSError: [Errno 98] Address already in use` or "Only one usage of each socket address" when starting | Another program (a real backend, a second copy) holds port 8000. | Stop it, or press Ctrl+C in the other window. |
| In Windows PowerShell, `curl` prints a security warning or odd output | `curl` is an alias for `Invoke-WebRequest`. | Type `curl.exe`. |
| `{"title": ...}` sent from PowerShell arrives with the quotes removed (400 Bad Request) | Windows PowerShell 5.1 strips inner double quotes from command-line arguments. | Send the body from a file with `--data "@new-task.json"`, or use `Invoke-RestMethod`. |
| `401` although you added the header | The header name or the word `Bearer ` is misspelled. | Write exactly `Authorization: Bearer practice`, with a space after `Bearer`. |
| JSON error such as `Expecting property name enclosed in double quotes` | Single quotes or a trailing comma in a JSON file. | Use double quotes only and no comma after the last item. |

(The error texts above are typical; the wording varies by tool version.)

## Best practice
Always read the status code first, then the `Content-Type`, then the body. Treat every 4xx as information, not as a crash: the problem body tells you what to fix. Source: [MDN: HTTP overview](https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview) and [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html).

## Going further
- MDN's list of status codes: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status.
- The full list of the platform's 27 operations is in step 6 of chapter [01 The OpenAPI contract](../phase-1-contract/01-openapi-contract.md). Lesson 03 teaches you to read that file.

## Summary
- You named the parts of an HTTP request and response and used the five methods and the main status codes.
- You applied five REST habits to the paths of the Tasks and Teams API.
- You called `/health`, a protected task, a create and two errors with `curl.exe` and with `Invoke-RestMethod`.
- You read a `problem+json` error and told 401, 403, 404 and 422 apart.

## Next lesson
03. Reading an OpenAPI file: the written description of the API you just called, and how to find any path, field and error in it.
