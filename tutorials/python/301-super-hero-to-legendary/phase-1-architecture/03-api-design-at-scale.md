---
track: python
level: 301
phase: 1
phase_name: architecture
lesson: '03'
title: "API design at scale: versioning, pagination, idempotency and contract tests"
time: "90 min"
prerequisites: [301.1.02, 201.3.08, 201.4.11]
versions: { python: "3.14 or newer", fastapi: "0.165.0", uvicorn: "0.54.0", pydantic: "2.14.4", httpx: "0.28.1" }
verified: not yet run
source: source/python/301-super-hero-to-legendary/phase-1-architecture/03-api-design-at-scale/
assets: []
---

# 03. API design at scale: versioning, pagination, idempotency and contract tests

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Choose a versioning and deprecation strategy and state what counts as a breaking change.
- Implement cursor (keyset) pagination with an opaque cursor and a capped page size, and explain when offset pagination is still acceptable.
- Make a `POST` safe to retry with an `Idempotency-Key`, including the "same key, different body" case.
- Write contract tests that fail when a change would break an existing consumer.

## Recap
1. Lesson 02: where did the rule "at most three open tasks" live, and why not in the handler?
   <details><summary>Answer</summary>In the `Project` aggregate, so every caller gets it. A handler would duplicate it per endpoint.</details>
2. Python 201 lesson 08: what is the difference between a request DTO and an entity?
   <details><summary>Answer</summary>The DTO is the wire contract validated at the edge; the entity is the internal model. They change for different reasons.</details>
3. Python 201 lesson 11: why is `TestClient` a good fit for unit-testing an API?
   <details><summary>Answer</summary>It runs the ASGI app in-process, so requests exercise routing, validation and serialisation without a network or server process.</details>

## Why it matters
An API is a promise made to people whose code you cannot edit. The first year hides every mistake: one client, one team, one deploy. At scale you get slow clients, retrying proxies, mobile apps three versions old and partners with quarterly release cycles. Four decisions then decide whether you can still change the service: how you version, how you page, whether a retry is safe, and how you know you did not break someone. This lesson makes each decision small enough to test.

## What you will build
A FastAPI service created by a `create_app()` factory, with an in-memory store seeded with seven tasks:

| Endpoint | Behaviour |
|---|---|
| `GET /v1/tasks?limit=&cursor=` | Cursor-paginated list. Task has `done: bool`. Marked deprecated with `Sunset` and `Link` headers. |
| `POST /v1/tasks` | Create. Requires `Idempotency-Key`. A retry with the same key and body returns the first result. |
| `GET /v2/tasks?limit=&cursor=` | The same list, but the task has `status: "open" or "done"` instead of `done` (a breaking change, therefore a new version). |

Errors use RFC 9457 problem details (`application/problem+json`), the format the capstone backend uses. Tests cover behaviour and a consumer contract read from the generated OpenAPI document.

## Before you start
- **Prerequisites:** [Python 301 lesson 02, domain modeling and SOLID](02-domain-modeling-and-solid.md); Python 201 lessons [08, your first FastAPI service](../../201-hero-to-super-hero/phase-3-apis-and-data/08-your-first-fastapi-service.md) and [11, testing and the notes API](../../201-hero-to-super-hero/phase-4-quality/11-testing-and-notes-api.md).
- Time: 90 min, with two sittings: stop after Step 7 (the server session), continue with tests and the exercise.
- Python **3.14 or newer**; Windows `py -3.14`, macOS and Linux `python3.14`. A network connection for `pip install` once.
- `curl`: on Windows PowerShell type `curl.exe` (plain `curl` is an alias for `Invoke-WebRequest` and behaves differently).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/python/301-super-hero-to-legendary/phase-1-architecture/03-api-design-at-scale/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`).
- The pins below are a teaching snapshot. Direct dependencies are pinned, transitive ones are not locked; resolve a lock file (`uv lock` or `pip-compile`) before deploying anything.

## Steps
### Step 1. Create the workspace and the environment
**PowerShell - folder: anywhere**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/python301/lesson03" -Force | Out-Null
Set-Location "$HOME/code101/python301/lesson03"
py -3.14 -m venv .venv
code .
```

**macOS/Linux - folder: anywhere**
```bash
mkdir -p ~/code101/python301/lesson03
cd ~/code101/python301/lesson03
python3.14 -m venv .venv
code .
```
`.venv` is a private copy of Python for this lesson. The commands below call its interpreter by path, so you never need to "activate" it (on Windows that avoids the PowerShell execution-policy error when running `Activate.ps1`).

### Step 2. Pin and install the dependencies
**File: `requirements.txt`**
```text
fastapi==0.165.0
uvicorn==0.54.0
pydantic==2.14.4
httpx==0.28.1
```
`httpx` is not used by the app itself; FastAPI's `TestClient` needs it.

**PowerShell - folder: `~/code101/python301/lesson03`**
```powershell
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

**macOS/Linux - folder: `~/code101/python301/lesson03`**
```bash
.venv/bin/python -m pip install -r requirements.txt
```
Expected result: pip prints `Successfully installed` followed by the package names and versions (including transitive packages such as Starlette). Exact lines depend on what your pip resolves.

### Step 3. The application
Type this file in full. It is long, so the commentary follows the code.

**File: `app.py`**
```python
import base64
import hashlib
import json
import threading
from typing import Annotated

from fastapi import APIRouter, Depends, FastAPI, Header, Query, Request, Response
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field


class ApiError(Exception):
    def __init__(self, status: int, title: str, detail: str) -> None:
        self.status = status
        self.title = title
        self.detail = detail


class TaskIn(BaseModel):
    title: str = Field(min_length=1, max_length=80)


class TaskV1(BaseModel):
    id: int
    title: str
    done: bool


class PageV1(BaseModel):
    items: list[TaskV1]
    next_cursor: str | None


class TaskV2(BaseModel):
    id: int
    title: str
    status: str


class PageV2(BaseModel):
    items: list[TaskV2]
    next_cursor: str | None


class Store:
    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.tasks: list[dict] = [
            {"id": n, "title": f"Seed task {n}", "done": n % 2 == 0} for n in range(1, 8)
        ]
        self.replays: dict[str, tuple[str, dict]] = {}


def encode_cursor(last_id: int) -> str:
    return base64.urlsafe_b64encode(f"after:{last_id}".encode()).decode()


def decode_cursor(cursor: str | None) -> int:
    if cursor is None:
        return 0
    try:
        text = base64.urlsafe_b64decode(cursor.encode()).decode()
        prefix, _, number = text.partition(":")
        if prefix != "after":
            raise ValueError(text)
        return int(number)
    except ValueError as error:
        raise ApiError(400, "Invalid cursor", "The cursor was not issued by this API.") from error


def take_page(store: Store, limit: int, cursor: str | None) -> tuple[list[dict], str | None]:
    after = decode_cursor(cursor)
    rows = [task for task in store.tasks if task["id"] > after][: limit + 1]
    has_more = len(rows) > limit
    rows = rows[:limit]
    return rows, (encode_cursor(rows[-1]["id"]) if has_more else None)


def fingerprint(body: TaskIn) -> str:
    canonical = json.dumps(body.model_dump(), sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode()).hexdigest()


def deprecate_v1(response: Response) -> None:
    response.headers["Sunset"] = "Wed, 31 Dec 2031 23:59:59 GMT"
    response.headers["Link"] = '</v2/tasks>; rel="successor-version"'


def create_app() -> FastAPI:
    store = Store()
    app = FastAPI(title="Tasks API", docs_url=None, redoc_url=None)

    @app.exception_handler(ApiError)
    async def handle_api_error(_: Request, error: ApiError) -> JSONResponse:
        body = {"type": "about:blank", "title": error.title, "status": error.status, "detail": error.detail}
        return JSONResponse(body, status_code=error.status, media_type="application/problem+json")

    v1 = APIRouter(prefix="/v1", dependencies=[Depends(deprecate_v1)])
    v2 = APIRouter(prefix="/v2")

    @v1.get("/tasks", response_model=PageV1)
    def list_v1(limit: Annotated[int, Query(ge=1, le=100)] = 3, cursor: str | None = None) -> dict:
        rows, next_cursor = take_page(store, limit, cursor)
        return {"items": rows, "next_cursor": next_cursor}

    @v2.get("/tasks", response_model=PageV2)
    def list_v2(limit: Annotated[int, Query(ge=1, le=100)] = 3, cursor: str | None = None) -> dict:
        rows, next_cursor = take_page(store, limit, cursor)
        items = [
            {"id": row["id"], "title": row["title"], "status": "done" if row["done"] else "open"}
            for row in rows
        ]
        return {"items": items, "next_cursor": next_cursor}

    @v1.post("/tasks", response_model=TaskV1, status_code=201)
    def create_v1(
        body: TaskIn,
        response: Response,
        idempotency_key: Annotated[str, Header(min_length=8, max_length=64)],
    ) -> dict:
        digest = fingerprint(body)
        with store.lock:
            replay = store.replays.get(idempotency_key)
            if replay is not None:
                stored_digest, stored_task = replay
                if stored_digest != digest:
                    raise ApiError(
                        422,
                        "Idempotency key reused",
                        "This Idempotency-Key was used with a different request body.",
                    )
                response.headers["Idempotent-Replay"] = "true"
                return stored_task
            task = {"id": len(store.tasks) + 1, "title": body.title, "done": False}
            store.tasks.append(task)
            store.replays[idempotency_key] = (digest, task)
            return task

    app.include_router(v1)
    app.include_router(v2)
    return app
```
- **`create_app()` is a factory**, not a module-level `app`. Each test builds a fresh app with a fresh store, so tests do not depend on order. In production you run `uvicorn app:create_app --factory`.
- **Cursor pagination (keyset).** The page query is "tasks with `id` greater than the last one you saw, limit + 1". Fetching one extra row tells us whether another page exists without a second `COUNT` query. The cursor is Base64 text that the client must treat as opaque, so you can change its content later (add a sort key, sign it) without breaking clients.
- **`Query(ge=1, le=100)`** caps the page size. An API without a cap lets one client ask for a million rows.
- **Idempotency.** The key is a header. The service stores the fingerprint of the request body next to the first response. Same key and same fingerprint: return the stored task and add `Idempotent-Replay: true`. Same key and a different fingerprint: it is a client bug, so refuse with 422 rather than guess.
- **`threading.Lock`** makes "look up the key, then create" atomic. FastAPI runs sync handlers in a thread pool, so two requests with the same key can truly race. The lock only works inside one process; see "When not to use this".
- **Versioning.** `v1` and `v2` are separate routers over the same store. `v1` carries the `deprecate_v1` dependency, which adds `Sunset` (the date after which the version may stop working, RFC 8594) and `Link: ...; rel="successor-version"`. The date is an example you choose per product, not a platform rule.
- **Errors** are RFC 9457 problem details. FastAPI's own validation errors keep FastAPI's default 422 shape; a production service maps those into the same format.

### Step 4. A request body file
**File: `request.json`**
```json
{"title": "Pay invoice"}
```
Saving the body in a file avoids shell quoting differences between PowerShell and bash.

### Step 5. Predict, then start the server
Predict: with seven seeded tasks and `limit=3`, how many pages are there, and what does the last page's `next_cursor` contain?

**PowerShell - folder: `~/code101/python301/lesson03`**
```powershell
& .\.venv\Scripts\python.exe -m uvicorn app:create_app --factory --host 127.0.0.1 --port 8000
```

**macOS/Linux - folder: `~/code101/python301/lesson03`**
```bash
.venv/bin/python -m uvicorn app:create_app --factory --host 127.0.0.1 --port 8000
```
Expected result: Uvicorn prints lines containing `Application startup complete.` and `Uvicorn running on http://127.0.0.1:8000`. `127.0.0.1` makes the service reachable only from your own machine. Leave this terminal running and open a second terminal in the same folder for the next steps.

### Step 6. Walk the pages
**PowerShell - folder: `~/code101/python301/lesson03` (second terminal)**
```powershell
curl.exe -s "http://127.0.0.1:8000/v1/tasks?limit=3"
```

**macOS/Linux - folder: `~/code101/python301/lesson03` (second terminal)**
```bash
curl -s "http://127.0.0.1:8000/v1/tasks?limit=3"
```
Expected output, not yet run (one line, wrapped here for reading):
```text
{"items":[{"id":1,"title":"Seed task 1","done":false},{"id":2,"title":"Seed task 2","done":true},{"id":3,"title":"Seed task 3","done":false}],"next_cursor":"YWZ0ZXI6Mw=="}
```
`YWZ0ZXI6Mw==` is the Base64 of `after:3`. Pass it back to get page two:

**PowerShell**
```powershell
curl.exe -s "http://127.0.0.1:8000/v1/tasks?limit=3&cursor=YWZ0ZXI6Mw=="
```

**macOS/Linux**
```bash
curl -s "http://127.0.0.1:8000/v1/tasks?limit=3&cursor=YWZ0ZXI6Mw=="
```
Expected: tasks 4, 5 and 6, and a cursor for `after:6`. A third call with that cursor returns task 7 and `"next_cursor":null`.

### Step 7. Create with an idempotency key, twice
**PowerShell - folder: `~/code101/python301/lesson03`**
```powershell
curl.exe -s -i -X POST http://127.0.0.1:8000/v1/tasks -H "Idempotency-Key: demo-key-0001" -H "Content-Type: application/json" --data "@request.json"
curl.exe -s -i -X POST http://127.0.0.1:8000/v1/tasks -H "Idempotency-Key: demo-key-0001" -H "Content-Type: application/json" --data "@request.json"
```

**macOS/Linux - folder: `~/code101/python301/lesson03`**
```bash
curl -s -i -X POST http://127.0.0.1:8000/v1/tasks -H "Idempotency-Key: demo-key-0001" -H "Content-Type: application/json" --data "@request.json"
curl -s -i -X POST http://127.0.0.1:8000/v1/tasks -H "Idempotency-Key: demo-key-0001" -H "Content-Type: application/json" --data "@request.json"
```
Expected, not yet run: both responses start with `HTTP/1.1 201 Created`, include the `sunset` and `link` headers and the body `{"id":8,"title":"Pay invoice","done":false}`. Only the second one has the header `idempotent-replay: true`. The task was created once. Stop the server with **Ctrl+C**.

### Step 8. The tests
**File: `test_api.py`**
```python
import unittest

from fastapi.testclient import TestClient

from app import create_app


class BehaviourTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(create_app())

    def test_walking_every_page_visits_each_task_once(self) -> None:
        seen: list[int] = []
        cursor = None
        while True:
            params = {"limit": 3}
            if cursor:
                params["cursor"] = cursor
            body = self.client.get("/v1/tasks", params=params).json()
            seen += [item["id"] for item in body["items"]]
            cursor = body["next_cursor"]
            if cursor is None:
                break
        self.assertEqual(seen, [1, 2, 3, 4, 5, 6, 7])

    def test_a_cursor_not_issued_by_us_is_a_400_problem(self) -> None:
        response = self.client.get("/v1/tasks", params={"cursor": "not-a-cursor"})
        self.assertEqual(response.status_code, 400)
        self.assertTrue(response.headers["content-type"].startswith("application/problem+json"))
        self.assertEqual(response.json()["title"], "Invalid cursor")

    def test_a_limit_above_the_maximum_is_refused(self) -> None:
        self.assertEqual(self.client.get("/v1/tasks", params={"limit": 1000}).status_code, 422)

    def test_the_same_key_and_body_create_one_task(self) -> None:
        headers = {"Idempotency-Key": "key-0001-abc"}
        first = self.client.post("/v1/tasks", json={"title": "Pay invoice"}, headers=headers)
        second = self.client.post("/v1/tasks", json={"title": "Pay invoice"}, headers=headers)
        self.assertEqual(first.status_code, 201)
        self.assertEqual(second.json(), first.json())
        self.assertNotIn("idempotent-replay", first.headers)
        self.assertEqual(second.headers["idempotent-replay"], "true")
        ids = [item["id"] for item in self.client.get("/v1/tasks", params={"limit": 100}).json()["items"]]
        self.assertEqual(len(ids), 8)

    def test_the_same_key_with_another_body_is_422(self) -> None:
        headers = {"Idempotency-Key": "key-0002-abc"}
        self.client.post("/v1/tasks", json={"title": "Pay invoice"}, headers=headers)
        again = self.client.post("/v1/tasks", json={"title": "Something else"}, headers=headers)
        self.assertEqual(again.status_code, 422)
        self.assertEqual(again.json()["title"], "Idempotency key reused")

    def test_a_create_without_a_key_is_refused(self) -> None:
        self.assertEqual(self.client.post("/v1/tasks", json={"title": "No key"}).status_code, 422)

    def test_v2_changes_the_shape_and_v1_does_not(self) -> None:
        v2 = self.client.get("/v2/tasks", params={"limit": 2}).json()["items"]
        v1 = self.client.get("/v1/tasks", params={"limit": 2}).json()["items"]
        self.assertEqual(v2[1], {"id": 2, "title": "Seed task 2", "status": "done"})
        self.assertEqual(v1[1], {"id": 2, "title": "Seed task 2", "done": True})

    def test_v1_announces_its_sunset_and_successor(self) -> None:
        response = self.client.get("/v1/tasks")
        self.assertIn("sunset", response.headers)
        self.assertIn("successor-version", response.headers["link"])


class ContractTests(unittest.TestCase):
    V1_CONSUMER_NEEDS = {"id", "title", "done"}

    def setUp(self) -> None:
        self.schema = create_app().openapi()

    def test_v1_task_keeps_the_fields_consumers_use(self) -> None:
        properties = set(self.schema["components"]["schemas"]["TaskV1"]["properties"])
        self.assertTrue(self.V1_CONSUMER_NEEDS <= properties)

    def test_v1_operations_still_exist(self) -> None:
        self.assertEqual(set(self.schema["paths"]["/v1/tasks"]), {"get", "post"})

    def test_pagination_parameters_are_documented(self) -> None:
        parameters = self.schema["paths"]["/v1/tasks"]["get"]["parameters"]
        self.assertEqual({parameter["name"] for parameter in parameters}, {"limit", "cursor"})


if __name__ == "__main__":
    unittest.main()
```
`BehaviourTests` check what the service does. `ContractTests` check what consumers rely on: field names and operations in the generated OpenAPI document. `V1_CONSUMER_NEEDS <= properties` is a subset test, so adding a field to v1 passes (additive change) and removing or renaming `done` fails.

**PowerShell - folder: `~/code101/python301/lesson03`**
```powershell
& .\.venv\Scripts\python.exe -m unittest -v
```

**macOS/Linux - folder: `~/code101/python301/lesson03`**
```bash
.venv/bin/python -m unittest -v
```
Expected output, not yet run: eleven test lines each ending in `ok`, then `Ran 11 tests in <time>s` and `OK`.

## How it works
1. **Compatibility rule.** Adding an optional field, a new endpoint or a new optional parameter is compatible. Removing or renaming a field, changing a type or a meaning, making an optional parameter required or tightening validation is breaking. `done: bool` becoming `status: str` is breaking, so it ships as `v2` while `v1` keeps working. Clients must follow the **tolerant reader** rule: ignore unknown fields.
2. **Pagination.** `id > :after ORDER BY id LIMIT :n+1` uses the primary key index and costs about the same on page 1 and page 10,000. Offset pagination (`OFFSET 100000`) makes the database walk and discard rows, and shifts when rows are inserted between requests.
3. **Idempotency.** A retry after a timeout cannot know if the first request succeeded. With a key, the server turns "at least once delivery" into "at most one effect".
4. **Contract tests** sit between unit tests and end-to-end tests. They are cheap, they run in CI, and they fail when a change breaks a documented promise.

**Misconception to correct:** "`PUT` and `DELETE` are idempotent, so I only need keys for `POST`." The HTTP *method semantics* are idempotent, but your implementation may not be (a `PUT` that appends to a list, a `DELETE` that triggers a side effect). Idempotency is a property you test, not one you inherit.

## Decision record (ADR-003)
| | |
|---|---|
| **Context** | Public clients (a web app, two mobile apps and partners) will outlive any single server release. |
| **Decision** | Major version in the path (`/v1`, `/v2`). Cursor pagination with a maximum `limit` of 100. `Idempotency-Key` required on non-natural-idempotent creates. Deprecation announced with `Sunset` and `Link` headers at least one release cycle ahead. |
| **Consequences** | Easy to route, cache and log by version; two versions to maintain until the sunset date. Clients cannot jump to page N. Idempotency needs durable storage and a retention policy. |
| **Alternatives rejected** | Version in a header or media type (cleaner URLs, but invisible in logs, harder to try in a browser and to cache). Offset pagination (random access, but slow and unstable on large or busy tables). No versioning with "never break" (works for one team that controls every client, nobody else). |

## When not to use this
- **Path versions for an internal API with one consumer you release with.** Deploy both together and change the contract in one commit. Versions are for clients you cannot synchronise.
- **Cursor pagination when users must jump to page 40** or you need a total count for a small, stable dataset. Offset is acceptable below a few thousand rows if you measure it.
- **The in-memory idempotency store in this lesson in production.** It disappears on restart, is per process (a second worker has its own copy) and never expires. Use a database table with a unique constraint on `(user_id, key)`, store the response, and expire entries. The capstone does this: see [chapter 02](https://github.com/Uee03/Code101/blob/main/capstones/backend-python/tutorials/phase-2-data/02-data.md).
- **Scope your keys.** A key that is not scoped by the authenticated user lets one user replay or read another user's stored response.
- **Contract tests as a replacement for consumer tests.** A subset check on the OpenAPI document proves the schema, not the behaviour. For many independent consumers consider consumer-driven contract tools; for one team a schema diff in CI may be enough.

## What to measure
- Latency at the 95th percentile for a first page and a deep page, for your real table, using `EXPLAIN (ANALYZE)` on the exact query. Compare keyset against offset on your data instead of trusting a rule of thumb.
- Share of traffic per API version in the access logs before you set a sunset date. Retire a version only when its traffic is at an agreed level, and tell the remaining callers directly.
- The rate of `Idempotent-Replay` responses. A sudden rise means a client is retrying aggressively or a network path is failing.
- Rate of 4xx per version after each release: a change that was supposed to be compatible but raised 400/422 for an existing client is a breaking change you found in production.

## Production checklist for this pattern
- [ ] A written definition of "breaking change", checked by a schema diff or contract test in CI.
- [ ] Every list endpoint has a default and a maximum page size and a stable sort that includes a unique tie-breaker.
- [ ] Cursors are opaque, and invalid cursors give a 400 problem response, never a 500.
- [ ] Idempotency keys are scoped per user, stored durably with the response, and expire.
- [ ] Concurrent same-key requests are serialised by a database constraint, not by a process-local lock.
- [ ] Deprecations announced with headers and in release notes; usage per version is visible on a dashboard.
- [ ] Error responses share one format (RFC 9457) and never leak stack traces.
- [ ] Rate limits answer 429 with `Retry-After` (the capstone's hardening chapter shows the headers).

## Try it
Starter: `exercise/starter/exercise.py`. Copy the `starter` folder itself and rename the copy `try03`, then work in `try03`.
1. **Guided:** implement `decide`. It receives the dictionary of keys already seen and returns one of three decisions, exactly the logic inside `create_v1`, without HTTP.
2. **Change:** extend the app so that `POST /v1/tasks` stores the key together with the user name from an `X-Demo-User` header and refuses (409) when the same key is used by a different user. Add one test. Explain why the key must not be the only part of the lookup.
3. **Stretch (no single answer):** support a `fields=` query parameter on the list endpoint. Decide: is adding it a breaking change for v1? What happens to your contract test? Write down how you would keep the generated OpenAPI document stable.

**File: `exercise/starter/exercise.py`**
```python
from enum import Enum


class Decision(Enum):
    EXECUTE = "execute"
    REPLAY = "replay"
    CONFLICT = "conflict"


def decide(stored: dict[str, str], key: str, fingerprint: str) -> Decision:
    # TODO 1: a key we have never seen means EXECUTE
    # TODO 2: a known key with the same fingerprint means REPLAY
    # TODO 3: a known key with a different fingerprint means CONFLICT
    raise NotImplementedError


if __name__ == "__main__":
    stored: dict[str, str] = {}
    for key, fingerprint in [("k1", "aaa"), ("k1", "aaa"), ("k1", "bbb"), ("k2", "bbb")]:
        decision = decide(stored, key, fingerprint)
        print(key, fingerprint, decision.value)
        if decision is Decision.EXECUTE:
            stored[key] = fingerprint
```
Expected output once complete:
```text
k1 aaa execute
k1 aaa replay
k1 bbb conflict
k2 bbb execute
```

<details><summary>Solution</summary>

**File: `exercise/solution/exercise.py`** (only `decide` differs)
```python
def decide(stored: dict[str, str], key: str, fingerprint: str) -> Decision:
    if key not in stored:
        return Decision.EXECUTE
    if stored[key] == fingerprint:
        return Decision.REPLAY
    return Decision.CONFLICT
```
The function is pure: it returns a decision and the caller performs the effect. That separation is why it is easy to test and why the real handler can wrap the lookup and the insert in one database transaction.

</details>

## Check yourself
1. Seven tasks, `limit=3`: how many requests walk the whole list, and why does the service fetch `limit + 1` rows?
   <details><summary>Answer</summary>Three requests (3, 3, 1). The extra row reveals whether a next page exists without a separate count query.</details>
2. Which of these is a breaking change to `v1`: adding a `created_at` field to `TaskV1`, renaming `done` to `completed`, adding an optional `?q=` filter?
   <details><summary>Answer</summary>Only the rename. The other two are additive. The contract test would fail on the rename.</details>
3. A client times out on `POST /v1/tasks`, then retries with the same key and body. What does the server return, and why is that safe?
   <details><summary>Answer</summary>The originally created task with 201 and `Idempotent-Replay: true`. No second task is created.</details>
4. Predict: two requests with the same key but different titles arrive. What is the response?
   <details><summary>Answer</summary>422 with the title `Idempotency key reused`.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `curl: (7) Failed to connect to 127.0.0.1 port 8000` (typical message) | The server is not running or runs in the other terminal that was closed | Start Uvicorn again (Step 5) |
| The PowerShell command prints a web page object or `Invoke-WebRequest` errors | You typed `curl` instead of `curl.exe` | Use `curl.exe` |
| `ERROR:    Error loading ASGI app. Attribute "create_app" not found in module "app".` (typical message) | Wrong folder, or the file was not saved | Save `app.py`, run from `lesson03` |
| `Could not import module "app".` (typical message) | The terminal is not in `lesson03` | `cd ~/code101/python301/lesson03` |
| POST returns 422 with a validation error mentioning `idempotency-key` | The header is missing or shorter than 8 characters | Send `Idempotency-Key: demo-key-0001` |
| `ModuleNotFoundError: No module named 'fastapi'` | You ran `python` instead of the `.venv` interpreter | Use `.venv/bin/python` or `.\.venv\Scripts\python.exe` |
| `RuntimeError: The starlette.testclient module requires the httpx package to be installed.` (typical message) | `httpx` is not installed | Re-run Step 2 |

## Best practice
Version by consumer compatibility, bound every list, and make every retried write idempotent. Source: FastAPI, path operation parameters and response models https://fastapi.tiangolo.com/tutorial/response-model/ ; RFC 9457 Problem Details https://www.rfc-editor.org/rfc/rfc9457 ; RFC 8594 The Sunset HTTP Header Field https://www.rfc-editor.org/rfc/rfc8594

## Going further
- The capstone applies all four decisions against a real database: cursors, filters, ETag with `If-Match`, idempotency and problem details in [chapter 02](https://github.com/Uee03/Code101/blob/main/capstones/backend-python/tutorials/phase-2-data/02-data.md), and the contract itself in the platform's OpenAPI file.
- Read the FastAPI guide to testing and to OpenAPI generation: https://fastapi.tiangolo.com/tutorial/testing/

## Summary
- You separated compatible from breaking changes and shipped the breaking one as `v2` with deprecation headers on `v1`.
- You implemented opaque cursor pagination with a capped page size.
- You made a `POST` retry-safe with an idempotency key, including the conflicting-body case, and listed what the in-memory version cannot do.
- You wrote behaviour tests and consumer-contract tests against the generated OpenAPI document.

## Next lesson
04. Concurrency models: the GIL, threads, processes, asyncio and free-threaded builds: what changes and what does not.
