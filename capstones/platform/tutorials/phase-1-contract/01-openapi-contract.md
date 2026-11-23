---
track: capstone
level: 201
phase: 1
phase_name: contract
lesson: 01
title: "The OpenAPI contract"
time: 60 min
prerequisites: [python-101, web-101]
versions: { openapi: "3.1.1", python: "3.10+ (author run: 3.15.2)", openapi-spec-validator: "0.9.0", PyYAML: "6.0.4" }
verified: 2026-11-23 on Windows 11, Python 3.15.2, pip 26.2.2
source: capstones/platform/source/phase-1-contract/01-openapi-contract/
assets: []
---

# 01. The OpenAPI contract

## Why it matters
Before four backends, two web apps and two phone apps are built, they must agree on one thing: what the API looks like. A restaurant works the same way. The menu is printed first; the kitchen and the waiters both follow it, and nobody argues at the table. The OpenAPI file is that menu. When it is finished, every backend can be checked against it and every client can be generated from it.

## What you will build
`openapi.yaml`, a valid OpenAPI 3.1 description of the Tasks and Teams API (27 operations, 33 schemas), and a small checker script that proves the file is valid and follows the platform rules. You read the file's important parts here; the complete file is in the pack. Nothing runs against a server yet: this phase is only the contract.

## Before you start
- Python 3.10 or newer with `pip`. The author run used Python 3.15.2. Check with `python --version` (use `python3` on macOS and Linux).
- No Docker in this chapter.
- Read the [platform README](../../README.md) and the [TDD](../../TDD.md) sections 3 and 6 once, so the requirement ids (R-xx) below make sense.
- Source pack: unzip `platform-phase-1-contract.zip` and open folder `01-openapi-contract/code`. Every later phase pack contains this same file, so you may also start from a later pack.

## Steps
### Step 1. Open a terminal in the code folder and install the checker
Open a terminal in `01-openapi-contract/code`. The text before `>` (Windows) or `$` (macOS and Linux) shows the current folder; if it is wrong, use `cd` to the folder.

**Terminal (PowerShell; folder: `01-openapi-contract/code`)**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

**Terminal (macOS/Linux; folder: `01-openapi-contract/code`)**
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

A virtual environment (`.venv`) is a private folder of Python packages, so this project does not change your system Python. The prompt starts with `(.venv)` while it is active. Reading the packages file first:

**File: `code/requirements.txt`**
```text
openapi-spec-validator==0.9.0
PyYAML==6.0.4
```

`openapi-spec-validator` checks a document against the real OpenAPI 3.1 schema. `PyYAML` reads YAML. `==` pins the exact version, so the checker behaves the same for everyone. Keep the next file too, it keeps generated folders out of Git:

**File: `code/.gitignore`**
```text
.env
.deps/
.venv/
__pycache__/
```

`.env` will hold local passwords (phase 2), `.venv/` and `.deps/` hold installed packages, `__pycache__/` holds compiled Python files.

### Step 2. Read the top of the contract
Open `code/openapi.yaml`. The first 35 lines describe the API as a whole.

**File: `code/openapi.yaml` (lines 1-35)**
```yaml
openapi: 3.1.1
info:
  title: Tasks and Teams API
  version: 1.0.0
  summary: The shared contract every Code101 backend implements and every client consumes.
  description: |
    Domain: teams, members, projects, tasks, comments and an audit trail.
    Conventions (apply to every operation unless stated otherwise):

    - Version prefix `/v1`. `/health` is unversioned infrastructure.
    - Errors are RFC 9457 problem details (`application/problem+json`).
    - Lists use cursor pagination: `limit` and `cursor` in, `items` and `page.nextCursor` out.
    - Single resources carry a strong `ETag` (the quoted `version`). Updates and deletes of
      versioned resources need `If-Match`: missing gives 428, stale gives 412.
    - Creates accept an optional `Idempotency-Key` header; a replay returns the first response
      with `Idempotent-Replayed: true`.
    - Every response carries `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset`;
      a throttled request gets 429 with `Retry-After`.
  license:
    name: MIT
    identifier: MIT
servers:
  - url: http://localhost:8000
    description: Local backend (any of the four implementations, port 8000)
tags:
  - name: Platform
    description: Health and the calling user
  - name: Teams
  - name: Members
  - name: Projects
  - name: Tasks
  - name: Comments
  - name: Audit
security:
  - oidc: [tasks:read]
```

Line by line:

| Lines | Meaning | If you change it |
|-------|---------|------------------|
| `openapi: 3.1.1` | The version of the OpenAPI language. 3.1 speaks full JSON Schema 2020-12, so `type: [string, 'null']` is legal. | `3.0.x` would reject that null syntax and use the older `nullable: true`. |
| `info` | Name, contract version (`1.0.0`) and the conventions every backend must follow. The `|` starts a block of text that keeps its line breaks. | Bump `version` when the contract changes. |
| `servers` | The base URL of a local backend. All four backends listen on port 8000, so a client switches backend without changing this. | A different port breaks the host-port table in the TDD. |
| `tags` | Groups for documentation and for generated client classes (`TeamsApi`, `TasksApi`). | Names must match the `tags:` used by operations. |
| `security` | The default: every operation needs an access token with the scope `tasks:read`. `/health` turns this off with `security: []`. | Removing it makes every endpoint public by accident. |

**Why this, not that.** OpenAPI 3.1.1 was chosen over 3.0 because of the JSON Schema alignment, and over 3.2 because the generators used by the client capstones (Angular, React, Flutter, Kotlin) support 3.1 best today. The patch level (`.1` vs `.2`) only fixes wording, so any 3.1.x tool reads this file. Source: [OpenAPI Specification versions](https://spec.openapis.org/oas/).

### Step 3. Read one operation completely: update a task
Operations live under `paths`. This is the biggest one, `PATCH /v1/tasks/{taskId}`, which uses optimistic concurrency, merge patch and problem details together.

**File: `code/openapi.yaml` (path item for tasks, abridged to the update operation)**
```yaml
  /v1/tasks/{taskId}:
    parameters:
      - { $ref: '#/components/parameters/TaskId' }
    patch:
      operationId: updateTask
      tags: [Tasks]
      summary: Change fields, status, assignee or due date (JSON Merge Patch)
      description: |
        Send only the fields to change. `null` clears `assigneeId` and `dueDate`.
        Setting `status` to `done` stamps `completedAt`; any other status clears it.
      x-access: team-member-or-admin
      security:
        - oidc: [tasks:write]
      parameters:
        - { $ref: '#/components/parameters/IfMatch' }
      requestBody:
        required: true
        content:
          application/merge-patch+json:
            schema: { $ref: '#/components/schemas/TaskUpdate' }
          application/json:
            schema: { $ref: '#/components/schemas/TaskUpdate' }
      responses:
        '200':
          description: The updated task with its new ETag.
          headers:
            ETag: { $ref: '#/components/headers/ETag' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Task' }
        '400': { $ref: '#/components/responses/BadRequest' }
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
        '412': { $ref: '#/components/responses/PreconditionFailed' }
        '422': { $ref: '#/components/responses/UnprocessableContent' }
        '428': { $ref: '#/components/responses/PreconditionRequired' }
```

| Line | What it does |
|------|--------------|
| `/v1/tasks/{taskId}:` | The URL template. `{taskId}` is a path parameter. The version prefix `/v1` is part of the path, so a future `/v2` can live beside it. |
| `parameters: - { $ref: ... }` at path level | Applies the parameter `TaskId` (a UUID) to every operation under this path. `$ref` points into `components`, so it is defined once. |
| `operationId: updateTask` | A unique name. Generators turn it into a method name (`updateTask()`), so it must stay stable. The checker rejects duplicates. |
| `x-access` | Our own extension (names starting with `x-` are allowed). It states who may call: here any team member or an admin. Backends implement it; the checker makes sure every operation states it. |
| `security: - oidc: [tasks:write]` | Overrides the default: this operation needs the scope `tasks:write`. A scope limits the client app; the role limits the user. |
| `parameters: IfMatch` | The required `If-Match` header: the client sends the ETag it last saw. |
| `requestBody` with two media types | JSON Merge Patch (RFC 7396): send only the fields that change, `null` removes a value. Plain `application/json` is accepted too, because many tools cannot send the patch media type. |
| `responses` | Every status the operation may return. `200` carries the new `ETag` header. `412` means the ETag is stale, `428` means the header is missing, `422` means a field is invalid, `403` means the role does not allow it. |

R-09 and R-12 in the TDD (problem details and optimistic concurrency) are exactly these lines.

### Step 4. Read the reusable pieces
Everything marked `$ref` is defined once in `components`. These three show the pattern.

**File: `code/openapi.yaml` (parameters, headers and one response from `components`)**
```yaml
    IfMatch:
      name: If-Match
      in: header
      required: true
      description: The `ETag` of the version being changed, quotes included, for example `"3"`.
      schema: { type: string, minLength: 3, maxLength: 20 }
```
```yaml
    ETag:
      description: Strong validator, the quoted resource `version`, for example `"3"`.
      schema: { type: string }
```
```yaml
    PreconditionFailed:
      description: The If-Match value is stale. Fetch the resource again and retry.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
          examples:
            stale:
              value:
                type: https://code101.example/problems/precondition-failed
                title: Precondition failed
                status: 412
                detail: The task changed since you read it (current version 4).
                instance: /v1/tasks/7c9e6679-7425-40de-944b-e07fc1f90ae7
                traceId: 4bf92f3577b34da6a3ce929d0e0e4736
```

`in: header` places the parameter in an HTTP header. The ETag is the row's `version` in quotes (`"3"`), so a backend needs no hashing. The example response is a real RFC 9457 body: `type` is a URI that names the problem, `title` is the same for every occurrence, `detail` explains this one, `instance` is the request path, `traceId` links to the server log. The domain `code101.example` is reserved for examples (RFC 2606) and never resolves.

### Step 5. Read the shared schemas
Schemas describe JSON bodies. Three matter most.

**File: `code/openapi.yaml` (schemas `Problem`, `PageInfo`, `TaskUpdate`)**
```yaml
    Problem:
      type: object
      description: RFC 9457 problem details with two extension members, `traceId` and `code`.
      required: [type, title, status]
      properties:
        type:
          type: string
          format: uri-reference
          description: Stable identifier of the problem type.
        title: { type: string }
        status: { type: integer, minimum: 400, maximum: 599 }
        detail: { type: string }
        instance: { type: string, description: The request path. }
        traceId: { type: string, description: Correlates with the server log. }
        code:
          type: string
          description: Optional machine-readable code, for example `last_lead`.
```
```yaml
    PageInfo:
      type: object
      required: [limit, nextCursor]
      properties:
        limit: { type: integer }
        nextCursor:
          type: [string, 'null']
          description: "`null` on the last page."
```
```yaml
    TaskUpdate:
      type: object
      additionalProperties: false
      minProperties: 1
      properties:
        title: { type: string, minLength: 1, maxLength: 200 }
        description: { type: string, maxLength: 10000 }
        status: { $ref: '#/components/schemas/TaskStatus' }
        priority: { $ref: '#/components/schemas/TaskPriority' }
        assigneeId: { type: [string, 'null'], format: uuid }
        dueDate: { type: [string, 'null'], format: date }
```

- `required` lists the members that must be present. `Problem` needs only `type`, `title` and `status`, as RFC 9457 allows.
- `type: [string, 'null']` is JSON Schema 2020-12 for "a string or null". This is how `assigneeId` can be cleared.
- `additionalProperties: false` rejects unknown fields, so a typo like `titel` becomes a 422 instead of a silent no-op. `minProperties: 1` rejects the empty patch `{}`.
- The limits (`maxLength: 200`) repeat the database `CHECK` constraints of phase 2 on purpose: the API answers a clean 422 before the database has to refuse.

### Step 6. Know the whole surface
The pack's file defines 27 operations. Each backend capstone implements this table; the checker counts them.

| Tag | Method and path | Role needed | Success |
|-----|-----------------|-------------|---------|
| Platform | `GET /health` | public | 200 |
| Platform | `GET /v1/me` | any signed-in user | 200 |
| Platform | `GET /v1/users` | any signed-in user | 200 |
| Teams | `GET /v1/teams` | any signed-in user (admins see all) | 200 |
| Teams | `POST /v1/teams` | admin | 201 |
| Teams | `GET /v1/teams/{teamId}` | team member or admin | 200 |
| Teams | `PATCH /v1/teams/{teamId}` | team lead or admin | 200 |
| Teams | `DELETE /v1/teams/{teamId}` | admin | 204 |
| Members | `GET /v1/teams/{teamId}/members` | team member or admin | 200 |
| Members | `PUT /v1/teams/{teamId}/members/{userId}` | team lead or admin | 200 or 201 |
| Members | `DELETE /v1/teams/{teamId}/members/{userId}` | team lead or admin | 204 |
| Projects | `GET /v1/teams/{teamId}/projects` | team member or admin | 200 |
| Projects | `POST /v1/teams/{teamId}/projects` | team lead or admin | 201 |
| Projects | `GET /v1/projects/{projectId}` | team member or admin | 200 |
| Projects | `PATCH /v1/projects/{projectId}` | team lead or admin | 200 |
| Projects | `DELETE /v1/projects/{projectId}` | team lead or admin | 204 |
| Tasks | `GET /v1/projects/{projectId}/tasks` | team member or admin | 200 |
| Tasks | `POST /v1/projects/{projectId}/tasks` | team member or admin | 201 |
| Tasks | `GET /v1/tasks/{taskId}` | team member or admin | 200 or 304 |
| Tasks | `PATCH /v1/tasks/{taskId}` | team member or admin | 200 |
| Tasks | `DELETE /v1/tasks/{taskId}` | team lead or admin | 204 |
| Tasks | `POST /v1/tasks/{taskId}/complete` | team member or admin | 200 |
| Tasks | `POST /v1/tasks/{taskId}/reassign` | team lead or admin | 200 |
| Comments | `GET /v1/tasks/{taskId}/comments` | team member or admin | 200 |
| Comments | `POST /v1/tasks/{taskId}/comments` | team member or admin | 201 |
| Comments | `DELETE /v1/comments/{commentId}` | author, team lead or admin | 204 |
| Audit | `GET /v1/audit-log` | admin | 200 |

The same table, with the request and response DTO names, is in the TDD section 6.

### Step 7. Write the checker
The checker proves two things: the file is valid OpenAPI 3.1, and our own rules hold (every operation has an `operationId` and an `x-access`, every write documents an error response).

**File: `code/scripts/check_openapi.py`**
```python
#!/usr/bin/env python3
"""Check that openapi.yaml is a valid OpenAPI 3.1 document and follows the platform rules."""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
DEPS = HERE / ".deps"  # optional folder: the lab verifier installs the packages here
if DEPS.is_dir():
    sys.path.insert(0, str(DEPS))

try:
    import yaml
    from openapi_spec_validator import validate
except ImportError:
    sys.exit("Missing packages. Run: pip install -r requirements.txt")

METHODS = {"get", "put", "post", "delete", "patch", "options", "head"}


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "openapi.yaml"
    spec = yaml.safe_load(path.read_text(encoding="utf-8"))
    try:
        validate(spec)
    except Exception as exc:  # the validator raises many types; keep the first line, without the dumped document
        print(f"INVALID: {type(exc).__name__}: {str(exc).splitlines()[0].split(' within {')[0][:200]}")
        return 1

    problems = []
    seen_ids = set()
    count = 0
    for url, item in spec["paths"].items():
        for method, op in item.items():
            if method not in METHODS:
                continue
            count += 1
            op_id = op.get("operationId")
            if not op_id or op_id in seen_ids:
                problems.append(f"{method.upper()} {url}: missing or duplicate operationId")
            seen_ids.add(op_id)
            if "x-access" not in op:
                problems.append(f"{method.upper()} {url}: missing x-access")
            if method in {"patch", "put", "post", "delete"} and not any(c.startswith("4") for c in map(str, op["responses"])):
                problems.append(f"{method.upper()} {url}: no 4xx response documented")
    if problems:
        print("\n".join(problems))
        return 1
    print(f"OpenAPI {spec['openapi']} valid: {count} operations, {len(spec['components']['schemas'])} schemas")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

How it works, in running order:

1. Lines 4-10 locate the code folder and add `.deps` to the import path when that folder exists. This is only for automated checks that install packages with `pip install --target .deps`. With a virtual environment you never need it.
2. The `try/except ImportError` turns a missing package into one clear sentence instead of a traceback.
3. `yaml.safe_load` turns the YAML file into Python dictionaries. `safe_load` never builds arbitrary Python objects, which makes it safe for files you did not write.
4. `validate(spec)` runs the official OpenAPI 3.1 JSON Schema and resolves every `$ref`. A broken reference raises an exception; the script prints one short line instead of the dumped document.
5. The loop visits every path item and every HTTP method (path items can also hold `parameters`, which is why `METHODS` filters). It collects problems instead of stopping at the first, so one run shows everything to fix.
6. The final line prints the version, the operation count and the schema count. Exit code `0` means success, which is how a CI job would use it.

## Run it
**Terminal (folder: `01-openapi-contract/code`, virtual environment active)**
```powershell
python scripts/check_openapi.py
```
On macOS and Linux use `python3 scripts/check_openapi.py`.

Expected output:
```text
OpenAPI 3.1.1 valid: 27 operations, 33 schemas
```

Break it on purpose to see the checker work. Make a copy named `broken.yaml`, change one `$ref: '#/components/schemas/TaskPage'` to `TaskPag`, and run `python scripts/check_openapi.py broken.yaml`:
```text
INVALID: PointerToNowhere: '/components/schemas/TaskPag' does not exist
```
Delete the line `x-access: public` from `/health` in a copy and the script reports:
```text
GET /health: missing x-access
```

## How it works
- **Contract first.** The file is the single source of truth. Backends are checked against it (phase 4), clients are generated from it, and the TDD tables are derived from it. Code-first (generate the file from backend code) gives four different files; contract-first gives one.
- **One file, many `$ref`.** A single `openapi.yaml` is the most portable form: every generator and linter reads it without a bundling step. The price is length (1,200 lines), which is why parameters, headers, responses and schemas are shared through `components`.
- **Security scheme.** `oidc` is an `openIdConnect` scheme pointing at the Keycloak discovery document (phase 3). Scopes (`tasks:read`, `tasks:write`, `tasks:admin`) are listed per operation. Roles are not part of OpenAPI, so `x-access` records them.
- **Terms.** *Operation*: one method on one path. *Schema*: the shape of a JSON body. *`$ref`*: a pointer to a shared definition. *Problem details*: the standard JSON error body. *ETag*: a version label of one resource.

## Try it
Starter: `exercise/starter/count_by_tag.py`. Copy it next to the code folder, with the virtual environment active, finish the four TODOs, and print how many operations each tag has, in tag order. Run `python count_by_tag.py ../code/openapi.yaml` (adjust the path to where you copied it).

<details><summary>Solution</summary>

**File: `exercise/solution/count_by_tag.py`**
```python
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
```

Expected output:
```text
Platform: 3
Teams: 5
Members: 3
Projects: 5
Tasks: 7
Comments: 3
Audit: 1
```

The dictionary comprehension starts every declared tag at 0, so a tag without operations would still print. `item.items()` also yields the key `parameters`, which is why the `HTTP_METHODS` filter is needed. The counts add up to the 27 operations.

</details>

## Check yourself
1. Why does `PATCH` require `If-Match` but `GET` does not? <details><summary>Answer</summary>`PATCH` changes data and the ETag proves the client saw the latest version, so two people cannot silently overwrite each other (lost update). `GET` only reads.</details>
2. What is the difference between a scope and a role? <details><summary>Answer</summary>A scope limits what the client application may do on the user's behalf; a role says what the user may do. The API needs both to be satisfied for admin operations.</details>
3. Why is `assigneeId` typed `[string, 'null']` and not just `string`? <details><summary>Answer</summary>A task can be unassigned, and a merge patch clears a value by sending `null`.</details>
4. What does `additionalProperties: false` buy you? <details><summary>Answer</summary>Unknown or misspelled fields are rejected with a 422 instead of being ignored.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Missing packages. Run: pip install -r requirements.txt` | The virtual environment is not active, or packages are not installed. | Activate `.venv` (prompt shows `(.venv)`) and run `pip install -r requirements.txt` again. |
| `INVALID: PointerToNowhere: '/components/schemas/TaskPag' does not exist` | A `$ref` names a component that is not defined (typo). | Fix the name after `components/schemas/` or add the schema. |
| `GET /health: missing x-access` | An operation lacks the `x-access` line. | Add `x-access:` with one of the documented values. |
| YAML error about indentation or a tab | YAML uses spaces only, two per level. | Replace tabs with spaces and keep the nesting shown above. |
| `python` is not found on Windows | Python is not installed or this terminal predates the install. | Install Python, close the terminal, open a new one. |

## Best practice
Treat the API description as the source of truth and validate it on every change, so clients and servers cannot drift apart. Source: [OpenAPI Specification v3.1.1](https://spec.openapis.org/oas/v3.1.1.html) and the [OpenAPI best practices](https://learn.openapis.org/best-practices.html).

## Next lesson
02. The database and stored procedures: turn the same domain into Postgres tables, constraints, triggers and two atomic stored functions, running in Docker.
