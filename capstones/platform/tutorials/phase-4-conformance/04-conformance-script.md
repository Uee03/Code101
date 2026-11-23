---
track: capstone
level: 201
phase: 4
phase_name: conformance
lesson: 04
title: "The conformance script"
time: 75 min
prerequisites: [python-101, capstone-platform-03]
versions: { python: "3.10+ (author run: 3.15.2)", keycloak_image: "quay.io/keycloak/keycloak:26.8.2", postgres_image: "17-alpine" }
verified: 2026-11-23 on Windows 11, Python 3.15.2, Docker CLI/Engine 29.9.3, Compose 5.7.0 (infrastructure checks only, no backend exists yet)
source: capstones/platform/source/phase-4-conformance/04-conformance-script/
assets: []
---

# 04. The conformance script

## Why it matters
Every restaurant in a city passes the same health inspection: the inspector uses one checklist, whether the kitchen cooks pizza or sushi. The conformance script is that checklist. Four backends in four languages will each run it, and a client may be pointed at any of them only because they all passed the same list.

## What you will build
`scripts/conformance.py`, a script that uses only the Python standard library and runs 18 ordered checks: 4 on the infrastructure (Keycloak and Postgres, runnable today) and 14 on the API (health, me, create team, create project, create task with `Idempotency-Key`, ETag, `If-Match`, 412, cursor pagination, 401, 403, problem details, audit log and cleanup). The 14 API checks need a backend; you read them now and run them in each backend capstone. Today you run the first four with `--infra-only`.

## Before you start
- Chapter 03 done or its pack unzipped. This chapter's `code` folder holds the whole platform project (contract, database, Keycloak, Compose); the new file is `scripts/conformance.py`. Everything else is unchanged from earlier chapters.
- Docker running; host ports 5432 and 8180 free.
- Python 3.10+.
- Source pack: unzip `platform-phase-4-conformance.zip`, open `04-conformance-script/code`.

## Steps
### Step 1. Compare with chapter 03
The new script keeps everything from chapter 03 and adds the following. The unchanged parts are the settings, `claims_of`, the four infrastructure checks and `run`.

| What | Chapter 03 | Chapter 04 |
|------|-----------|------------|
| HTTP helper | `http_post_form`, `http_get_json` | one `call()` that returns a `Response` object (status, headers, text, `.json`) for any method, with JSON or form bodies, and returns 4xx and 5xx answers instead of raising |
| Tokens | `token_for` fetched a token each time | `token_for` keeps tokens in the dictionary `tokens`, so the 14 API checks get one token per user |
| Sharing results | none | the dictionary `ctx` passes ids and ETags from one check to the next; `need()` fails a check with a clear message when an earlier check did not run |
| Assertions | `assert` only | `expect(res, status)` and `expect_problem(res, status)` also check the RFC 9457 shape |
| `--infra-only` | accepted, no effect | skips the API checks |
| Setting | none | `BASE_URL` (default `http://127.0.0.1:8000`) |

### Step 2. Write part 1: settings and helpers
**File: `code/scripts/conformance.py` (part 1)**
```python
#!/usr/bin/env python3
"""Platform conformance script. Standard library only.

  python scripts/conformance.py --infra-only      Keycloak tokens and Postgres reachability
  python scripts/conformance.py                   the above, then the API checks against BASE_URL

Every backend must pass the same checks, in this order. Exit code 0 means all passed.
"""
import argparse
import base64
import json
import os
import socket
import struct
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid

BASE_URL = os.environ.get("BASE_URL", "http://127.0.0.1:8000").rstrip("/")
KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL", "http://127.0.0.1:8180")
ISSUER = os.environ.get("TOKEN_ISSUER", "http://localhost:8180/realms/tasksteams")
REALM = os.environ.get("KEYCLOAK_REALM", "tasksteams")
POSTGRES_HOST = os.environ.get("POSTGRES_HOST", "127.0.0.1")
POSTGRES_PORT = int(os.environ.get("POSTGRES_PORT", "5432"))
SMOKE_CLIENT = "tasks-smoke"
PASSWORDS = {
    "alice": os.environ.get("SMOKE_ALICE_PASSWORD", "alice-local-fake"),
    "bob": os.environ.get("SMOKE_BOB_PASSWORD", "bob-local-fake"),
}
ALICE_ID = "a11ce000-0000-4000-8000-000000000001"

tokens = {}  # username -> access token, filled on first use
ctx = {}     # ids and ETags passed from one check to the next


class Response:
    def __init__(self, status, headers, raw):
        self.status = status
        self.headers = headers
        self.text = raw.decode("utf-8", errors="replace")

    @property
    def json(self):
        return json.loads(self.text)


def call(method, url, token=None, body=None, form=None, headers=None):
    hdrs = {"Accept": "application/json"}
    data = None
    if token:
        hdrs["Authorization"] = f"Bearer {token}"
    if body is not None:
        data = json.dumps(body).encode()
        hdrs["Content-Type"] = "application/json"
    if form is not None:
        data = urllib.parse.urlencode(form).encode()
        hdrs["Content-Type"] = "application/x-www-form-urlencoded"
    hdrs.update(headers or {})
    request = urllib.request.Request(url, data=data, headers=hdrs, method=method)
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return Response(response.status, response.headers, response.read())
    except urllib.error.HTTPError as err:  # 4xx and 5xx (and 304) arrive here
        return Response(err.code, err.headers, err.read())


def api(method, path, who="alice", **kwargs):
    token = None if who is None else token_for(who)
    return call(method, BASE_URL + path, token=token, **kwargs)


def token_for(username):
    if username not in tokens:
        res = call("POST", f"{KEYCLOAK_URL}/realms/{REALM}/protocol/openid-connect/token", form={
            "grant_type": "password",
            "client_id": SMOKE_CLIENT,
            "username": username,
            "password": PASSWORDS[username],
            "scope": "openid tasks:read tasks:write tasks:admin",
        })
        assert res.status == 200, f"token endpoint answered {res.status}: {res.text[:200]}"
        tokens[username] = res.json["access_token"]
    return tokens[username]


def claims_of(token):
    payload = token.split(".")[1]
    return json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))


def expect(res, status):
    assert res.status == status, f"expected HTTP {status}, got {res.status}: {res.text[:200]}"


def expect_problem(res, status):
    expect(res, status)
    content_type = res.headers.get("Content-Type", "")
    assert content_type.startswith("application/problem+json"), f"Content-Type is {content_type!r}"
    body = res.json
    for field in ("type", "title", "status"):
        assert field in body, f"problem has no {field!r}: {body}"
    assert body["status"] == status, f"problem status {body['status']} differs from HTTP {status}"
    return body


def need(key):
    assert key in ctx, f"needs the result of an earlier check ({key})"
    return ctx[key]
```

How it works:
- The docstring is what `--help` prints. Keep it accurate when you add checks.
- Settings come from environment variables, so a backend capstone runs `BASE_URL=http://127.0.0.1:8000 python scripts/conformance.py` without editing the file. `.rstrip("/")` prevents a double slash in URLs.
- `Response` wraps what came back. The Python standard library raises an exception for 4xx and 5xx answers; `call` catches `HTTPError` and returns it as a normal `Response`, because checks want to inspect error answers (a 404 is often the expected result).
- `call` builds the request: the `Accept` header, a bearer token, and either a JSON body (`body=`) or a form body (`form=`). `hdrs.update(headers or {})` comes last so a check can override a header, for example `Content-Type: application/merge-patch+json`.
- `api` is `call` for our backend: it prefixes `BASE_URL`, and `who="alice"` picks whose token to send (`who=None` sends none).
- `token_for` caches tokens, so 14 checks cause 2 logins, not 14.
- `expect_problem` is the RFC 9457 test: the right status, the media type `application/problem+json`, the three required members `type`, `title` and `status`, and the `status` member equal to the HTTP status.
- `need` turns "check 7 failed because check 3 failed" into a readable message instead of a `KeyError`.

### Step 3. Write part 2: infrastructure checks
These four are the checks from chapter 03, now using `call`.

**File: `code/scripts/conformance.py` (part 2)**
```python
# Infrastructure checks ------------------------------------------------------

def check_discovery():
    res = call("GET", f"{KEYCLOAK_URL}/realms/{REALM}/.well-known/openid-configuration")
    expect(res, 200)
    assert res.json["issuer"] == ISSUER, f"issuer is {res.json['issuer']}, expected {ISSUER}"
    assert "S256" in res.json["code_challenge_methods_supported"], "PKCE S256 is not offered"
    return "issuer matches, PKCE S256 offered"


def check_alice_token():
    claims = claims_of(token_for("alice"))
    assert claims["iss"] == ISSUER, f"iss is {claims['iss']}"
    audience = claims["aud"] if isinstance(claims["aud"], list) else [claims["aud"]]  # aud may be a string or a list
    assert "tasks-api" in audience, f"aud is {claims['aud']}"
    assert claims["sub"] == ALICE_ID, f"sub is {claims['sub']}"
    assert "admin" in claims["realm_access"]["roles"], "role admin missing"
    assert {"tasks:read", "tasks:write", "tasks:admin"} <= set(claims["scope"].split()), "scopes missing"
    return "iss, aud tasks-api, sub, role admin, three scopes"


def check_bob_token():
    roles = claims_of(token_for("bob"))["realm_access"]["roles"]
    assert "member" in roles and "admin" not in roles, f"roles are {roles}"
    return "role member only"


def check_postgres():
    with socket.create_connection((POSTGRES_HOST, POSTGRES_PORT), timeout=5) as sock:
        sock.sendall(struct.pack("!ii", 8, 80877103))  # the Postgres SSLRequest message
        answer = sock.recv(1)
    assert answer in (b"S", b"N"), f"unexpected reply {answer!r}"
    return f"{POSTGRES_HOST}:{POSTGRES_PORT} answers the Postgres protocol"
```

Each check returns a short sentence for the report and raises `AssertionError` (through `assert`) when something is wrong. Every other exception (a refused connection, bad JSON) counts as a failure too, thanks to `run` in part 5.

### Step 4. Write part 3: the first API checks
These run in order and hand data forward through `ctx`.

**File: `code/scripts/conformance.py` (part 3)**
```python
# API checks -----------------------------------------------------------------

def check_health():
    res = api("GET", "/health", who=None)
    expect(res, 200)
    assert res.json["status"] == "ok", f"status is {res.json['status']}"
    return "200, status ok, no token needed"


def check_me():
    res = api("GET", "/v1/me")
    expect(res, 200)
    me = res.json
    assert me["id"] == ALICE_ID and me["username"] == "alice", f"unexpected user {me['id']}"
    assert "admin" in me["roles"], f"roles are {me['roles']}"
    for name in ("RateLimit-Limit", "RateLimit-Remaining", "RateLimit-Reset"):
        assert res.headers.get(name, "").isdigit(), f"header {name} missing or not a number"
    return "alice is admin, RateLimit headers present"


def check_create_team():
    name = f"Conformance {uuid.uuid4().hex[:8]}"
    res = api("POST", "/v1/teams", body={"name": name, "description": "Created by the conformance script"},
              headers={"Idempotency-Key": str(uuid.uuid4())})
    expect(res, 201)
    team = res.json
    assert res.headers.get("Location", "").endswith(f"/v1/teams/{team['id']}"), "Location header does not point at the team"
    assert res.headers.get("ETag") == f'"{team["version"]}"', "ETag is not the quoted version"
    assert team["name"] == name and team["version"] == 1, f"unexpected team {team}"
    ctx["team"] = team["id"]
    return f"201, Location and ETag set, team {team['id']}"


def check_create_project():
    res = api("POST", f"/v1/teams/{need('team')}/projects",
              body={"key": "CNF", "name": "Conformance project"}, headers={"Idempotency-Key": str(uuid.uuid4())})
    expect(res, 201)
    ctx["project"] = res.json["id"]
    return f"201, project {ctx['project']}"


def check_create_task_idempotent():
    path = f"/v1/projects/{need('project')}/tasks"
    body = {"title": "First task", "priority": "high", "dueDate": "2027-06-30"}
    headers = {"Idempotency-Key": str(uuid.uuid4())}
    first = api("POST", path, body=body, headers=headers)
    expect(first, 201)
    assert first.json["status"] == "todo" and first.json["priority"] == "high", f"unexpected task {first.json}"
    replay = api("POST", path, body=body, headers=headers)
    expect(replay, 201)
    assert replay.json["id"] == first.json["id"], "the replay created a second task"
    assert replay.headers.get("Idempotent-Replayed") == "true", "replay lacks Idempotent-Replayed: true"
    expect_problem(api("POST", path, body={"title": "Another body"}, headers=headers), 422)
    ctx["task"] = first.json["id"]
    return "created once, replay returned the same task, other body gave 422"


def check_get_task_etag():
    res = api("GET", f"/v1/tasks/{need('task')}")
    expect(res, 200)
    etag = res.headers.get("ETag")
    assert etag == f'"{res.json["version"]}"', f"ETag {etag} is not the quoted version"
    cached = api("GET", f"/v1/tasks/{need('task')}", headers={"If-None-Match": etag})
    expect(cached, 304)
    ctx["etag"], ctx["version"] = etag, res.json["version"]
    return f"ETag {etag}, If-None-Match gave 304"
```

What each proves:

| Check | Requirement | What it proves | What a backend usually got wrong |
|-------|-------------|----------------|----------------------------------|
| `health` | R-02 | The service is up and `/health` needs no token. | Health behind authentication, so Docker's health check gets 401. |
| `me` | R-03, R-14 | The token is accepted; the user profile matches the token; the three `RateLimit-*` headers are whole numbers. | Headers missing, or sent as `100 requests`. |
| `create team` | R-04, R-13, R-15 | An admin creates a team: `201`, a `Location` URL ending in the new id, a strong `ETag` equal to the quoted `version`, and `version` starts at 1. | `Location` relative or missing; ETag weak (`W/"1"`). |
| `create project` | R-05 | A team lead (the creator became lead through `create_team`) can add a project; `key` is validated. | Creator not made lead. |
| `create task with Idempotency-Key` | R-06, R-13 | The same key and body twice creates one task and replays the first answer with `Idempotent-Replayed: true`; the same key with another body is a 422 problem. | The retry creates a duplicate, or replies 409 instead of replaying. |
| `get task with ETag` | R-12 | `ETag` is the quoted version, and `If-None-Match` with that value gives `304` with no body. | `304` not implemented. |

`uuid.uuid4().hex[:8]` makes the team name unique, because team names are unique in the database and the script may be run many times.

### Step 5. Write part 4: the remaining API checks
**File: `code/scripts/conformance.py` (part 4)**
```python
def check_update_if_match():
    res = api("PATCH", f"/v1/tasks/{need('task')}", body={"status": "in_progress", "assigneeId": ALICE_ID},
              headers={"If-Match": need("etag"), "Content-Type": "application/merge-patch+json"})
    expect(res, 200)
    task = res.json
    assert task["status"] == "in_progress" and task["assigneeId"] == ALICE_ID, f"unexpected task {task}"
    assert task["version"] == ctx["version"] + 1, f"version is {task['version']}"
    assert res.headers.get("ETag") == f'"{task["version"]}"', "new ETag is not the new version"
    return f"200, version {ctx['version']} -> {task['version']}"


def check_stale_if_match():
    path = f"/v1/tasks/{need('task')}"
    stale = api("PATCH", path, body={"title": "Too late"},
                headers={"If-Match": need("etag"), "Content-Type": "application/merge-patch+json"})
    expect_problem(stale, 412)
    missing = api("PATCH", path, body={"title": "No precondition"}, headers={"Content-Type": "application/merge-patch+json"})
    expect_problem(missing, 428)
    return "stale If-Match gave 412, missing If-Match gave 428"


def check_cursor_pagination():
    path = f"/v1/projects/{need('project')}/tasks"
    for title in ("Second task", "Third task"):
        expect(api("POST", path, body={"title": title}), 201)
    first = api("GET", f"{path}?limit=2&sort=createdAt")
    expect(first, 200)
    page_one = first.json
    assert len(page_one["items"]) == 2 and page_one["page"]["nextCursor"], f"unexpected first page {page_one['page']}"
    cursor = urllib.parse.quote(page_one["page"]["nextCursor"])
    second = api("GET", f"{path}?limit=2&sort=createdAt&cursor={cursor}")
    expect(second, 200)
    page_two = second.json
    assert len(page_two["items"]) == 1 and page_two["page"]["nextCursor"] is None, f"unexpected second page {page_two['page']}"
    ids = {item["id"] for item in page_one["items"] + page_two["items"]}
    assert len(ids) == 3, "the pages overlap or miss a task"
    return "2 + 1 tasks, no overlap, last page has nextCursor null"


def check_no_token():
    res = api("GET", "/v1/me", who=None)
    expect_problem(res, 401)
    assert res.headers.get("WWW-Authenticate", "").startswith("Bearer"), "WWW-Authenticate is not a Bearer challenge"
    return "401 problem details with a Bearer challenge"


def check_member_forbidden():
    expect_problem(api("GET", "/v1/audit-log", who="bob"), 403)
    expect_problem(api("POST", "/v1/teams", who="bob", body={"name": "Not allowed"}), 403)
    return "bob (member) gets 403 on the audit log and on creating a team"


def check_problem_shape():
    invalid = expect_problem(api("POST", "/v1/teams", body={"name": ""}), 422)
    pointers = [error.get("pointer") for error in invalid.get("errors", [])]
    assert "/name" in pointers, f"errors do not point at /name: {invalid.get('errors')}"
    missing = expect_problem(api("GET", f"/v1/tasks/{uuid.uuid4()}"), 404)
    assert missing["type"].startswith("http"), f"type is not a URI: {missing['type']}"
    return "422 with errors[/name], 404 with type, title and status"


def check_audit_log():
    res = api("GET", f"/v1/audit-log?entityType=task&entityId={need('task')}&limit=20")
    expect(res, 200)
    actions = {item["action"] for item in res.json["items"]}
    assert {"create", "update"} <= actions, f"audit actions are {actions}"
    creates = [item for item in res.json["items"] if item["action"] == "create"]
    assert creates[0]["actorId"] == ALICE_ID, "the create entry does not name alice"
    return "task create and update are in the audit trail"


def check_cleanup():
    team = need("team")
    expect(api("DELETE", f"/v1/teams/{team}"), 204)
    expect_problem(api("GET", f"/v1/teams/{team}"), 404)
    return "team deleted, then 404"
```

| Check | Requirement | What it proves | What a backend usually got wrong |
|-------|-------------|----------------|----------------------------------|
| `update with If-Match` | R-06, R-12 | A merge patch with the current ETag succeeds, changes status and assignee, raises `version` by exactly 1 and returns the new ETag. | Ignoring `If-Match`; version not bumped by the trigger. |
| `stale If-Match gives 412` | R-09, R-12 | The ETag from before the update is rejected with 412, a missing header with 428, both as problem details. | Returning 409 or 400, or accepting the stale value. |
| `cursor pagination` | R-10 | `limit=2` gives 2 items and a cursor; the cursor gives the last 1 item and `nextCursor: null`; no overlap. The cursor is URL-quoted because it may contain `=`. | Offset paging, a cursor that repeats the last row, or a missing null. |
| `401 without token` | R-09, R-20 | No token means 401 in problem details with `WWW-Authenticate: Bearer`. | HTML error page or a redirect to a login page. |
| `403 for member on admin route` | R-20 | Bob has a valid token with the `tasks:admin` scope but not the role `admin`, and still gets 403, both for reading the audit log and creating a team. This is the proof that the API checks the **role**, not just the scope. | Checking scopes only. |
| `problem details shape` | R-09 | A validation error is 422 with `errors[].pointer` equal to `/name`; an unknown id is a 404 problem whose `type` is a URI. | Plain text or framework-specific error JSON. |
| `audit log` | R-08 | The database triggers recorded the task's create and update with alice as actor, and the admin endpoint exposes them. | The API forgot `set_config('app.current_user_id', ...)`, so `actorId` is null. |
| `cleanup` | R-04 | An admin can delete the team; the team is gone afterwards; cascades work. | Delete not cascading. |

### Step 6. Write part 5: the runner
**File: `code/scripts/conformance.py` (part 5)**
```python
def run(name, check):
    try:
        detail = check()
    except Exception as exc:  # a failed check is reported, the others still run
        print(f"FAIL  {name}: {exc}")
        return False
    print(f"PASS  {name} ({detail})")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--infra-only", action="store_true", help="skip the API checks (no backend needed)")
    args = parser.parse_args()
    checks = [
        ("keycloak discovery", check_discovery),
        ("token for alice", check_alice_token),
        ("token for bob", check_bob_token),
        ("postgres reachable", check_postgres),
    ]
    if not args.infra_only:
        checks += [
            ("health", check_health),
            ("me", check_me),
            ("create team", check_create_team),
            ("create project", check_create_project),
            ("create task with Idempotency-Key", check_create_task_idempotent),
            ("get task with ETag", check_get_task_etag),
            ("update with If-Match", check_update_if_match),
            ("stale If-Match gives 412", check_stale_if_match),
            ("cursor pagination", check_cursor_pagination),
            ("401 without token", check_no_token),
            ("403 for member on admin route", check_member_forbidden),
            ("problem details shape", check_problem_shape),
            ("audit log", check_audit_log),
            ("cleanup", check_cleanup),
        ]
    results = [run(name, check) for name, check in checks]
    print(f"{sum(results)} passed, {len(results) - sum(results)} failed")
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
```

The order of the list **is** the contract: checks later in the list depend on earlier ones. `RawDescriptionHelpFormatter` keeps the docstring's line breaks in `--help`. The exit code makes the script usable in CI.

#### The `.gitignore` of this chapter (unchanged from chapter 01)
The conformance script reads your `.env`, so keep it out of Git. The `.gitignore` is the same as in chapter 01, shown again so you can check your copy.

<details>
<summary><code>code/.gitignore</code> (same as chapter 01)</summary>

**File: `code/.gitignore`**
```text
.env
.deps/
.venv/
__pycache__/
```

- `.env`: your local settings and passwords. Never commit it; `.env.example` is the committed template.
- `.deps/`: packages installed next to the scripts; downloaded again on any machine.
- `.venv/`: the Python virtual environment; never shared through Git.
- `__pycache__/`: compiled Python files that Python recreates on its own.

`.git` itself is never listed: Git does not track its own folder.
</details>

## Run it
**Terminal (PowerShell; folder: `04-conformance-script/code`)**
```powershell
Copy-Item .env.example .env
docker compose -p platform up -d --wait
python scripts/conformance.py --help
python scripts/conformance.py --infra-only
```
On macOS and Linux use `cp .env.example .env` and `python3`. The `--help` output starts with:
```text
usage: conformance.py [-h] [--infra-only]
```
and lists the option `--infra-only  skip the API checks (no backend needed)`. Expected output of the infrastructure checks:
```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
4 passed, 0 failed
```

In a backend capstone, once its API listens on port 8000, you run the full list (no flag) and expect `18 passed, 0 failed`; the API checks cannot pass today because no backend exists yet:
```powershell
python scripts/conformance.py
```
Point it at another address with `BASE_URL`: PowerShell `$env:BASE_URL = "http://127.0.0.1:8000"`, macOS and Linux `BASE_URL=http://127.0.0.1:8000 python3 scripts/conformance.py`. Stop the stack when you are done:
```powershell
docker compose -p platform down -v --remove-orphans
```

## How it works
- **Black-box on purpose.** The script knows only HTTP, the contract and the seed users. It cannot tell whether the backend is Python or Rust, so passing proves the contract, not an implementation.
- **Ordered, stateful checks.** A realistic flow (create a team, then a project, then tasks) tests relationships; independent checks would miss them. The price is that one early failure causes later `needs the result of an earlier check` failures, which is why `need()` words the message clearly.
- **Smoke, not a test suite.** Eighteen checks prove "the contract works once". Each backend capstone still has its own unit and integration tests, and its verification only runs this script once.
- **Why the password grant is acceptable here.** It is used by a script in a local lab against fake users. Apps use PKCE (chapter 03).
- **Terms.** *Idempotent*: repeating the request has the same effect as sending it once. *Conformance*: matching a specification. *Black-box test*: tests behaviour without looking at the code. *Smoke test*: the quickest check that the whole thing works.

## Try it
Starter: `exercise/starter/check_complete_task.py`. Write a 19th check for `POST /v1/tasks/{taskId}/complete` (R-06): read the task id and its current ETag, complete the task with `If-Match`, expect 200, status `done` and a non-empty `completedAt`. Paste your function into `scripts/conformance.py` above `run`, and add `("complete task", check_complete_task)` to the list after `audit log`. It cannot pass until a backend exists, but the file must compile.

<details><summary>Solution</summary>

**File: `exercise/solution/check_complete_task.py`**
```python
"""Exercise: one more conformance check for POST /v1/tasks/{taskId}/complete.

Paste the function into scripts/conformance.py (above run()) and add
("complete task", check_complete_task) to the checks list after "audit log".
"""


def check_complete_task():
    task = need("task")
    current = api("GET", f"/v1/tasks/{task}")
    expect(current, 200)
    res = api("POST", f"/v1/tasks/{task}/complete", headers={"If-Match": current.headers["ETag"]})
    expect(res, 200)
    assert res.json["status"] == "done" and res.json["completedAt"], f"unexpected task {res.json}"
    return "task is done and has completedAt"
```

The `GET` first reads the **current** ETag, because earlier checks changed the task and the stored `etag` in `ctx` is stale. Because `cleanup` deletes the team, the new entry belongs between `audit log` and `cleanup` in the list.

</details>

## Check yourself
1. Why does `call()` catch `HTTPError` and return a `Response`? <details><summary>Answer</summary>The standard library raises for 4xx and 5xx, but most checks expect an error status, so the script needs the answer, not an exception.</details>
2. Why does the 403 check use bob and the `tasks:admin` scope? <details><summary>Answer</summary>It proves authorization looks at the role too: a token with the admin scope but without the admin role must still be refused.</details>
3. Why is the cursor passed through `urllib.parse.quote`? <details><summary>Answer</summary>A cursor is Base64 text that may contain characters like `=` that are not safe in a query string.</details>
4. What happens if `check_create_team` fails? <details><summary>Answer</summary>Later checks that call `need("team")` fail with "needs the result of an earlier check", so the first failure is the one to fix.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `git status` lists `.env`, `.venv/` or `__pycache__/` as new files, or a password appears in a commit | `.gitignore` is missing, or it was created after the files were already tracked | Create the `.gitignore` shown above; for files already tracked run `git rm --cached .env` (and `git rm -r --cached .venv`), commit, and replace any real secret that was ever committed |
| `FAIL  token for alice: 'sub'` | The realm lost its standard client scopes (see chapter 03). | Restore part 2 of the realm file and `down -v`. |
| `FAIL  keycloak discovery: Remote end closed connection without response` | Keycloak is not ready yet. | Wait for `docker compose -p platform up -d --wait` to finish. |
| `FAIL  postgres reachable: [WinError 10061] No connection could be made because the target machine actively refused it` | Postgres is not running or `POSTGRES_PORT` differs. | Start the stack; on macOS and Linux the same cause shows `Connection refused`. |
| API checks fail with `needs the result of an earlier check (team)` | `create team` failed first. | Read the first FAIL line, not the later ones. |
| `403` where `201` is expected in `create team` | The token is bob's, or the backend checks the wrong claim. | `create team` uses alice; confirm the backend reads `realm_access.roles`. |

## Best practice
Test an API against its published contract with the same script for every implementation, and keep the checks independent of any one language. Source: [OpenAPI Initiative: Learn OpenAPI](https://learn.openapis.org/) and [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/info/rfc9457).

## Next lesson
The platform capstone is complete. Next: a backend capstone (`backend-python`, `backend-dotnet`, `backend-go` or `backend-rust`) that implements this contract against the same Postgres and Keycloak, and passes `python scripts/conformance.py` with 18 checks.
