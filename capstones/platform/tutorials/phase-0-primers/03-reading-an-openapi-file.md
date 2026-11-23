---
track: capstone
level: 101
phase: 0
phase_name: primers
lesson: 03
title: "Reading an OpenAPI file"
time: 45 min
prerequisites: [01-git-and-github, 02-http-and-rest]
versions: { openapi: "3.1.1", python: "3.10 or newer", PyYAML: "6.0.4" }
verified: not yet run
source: capstones/platform/source/phase-0-primers/03-reading-an-openapi-file/
assets: []
---

# 03. Reading an OpenAPI file

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- explain what OpenAPI is and name its main sections (`info`, `servers`, `security`, `paths`, `components`);
- read an operation: its path, method, parameters, request body, responses and security;
- follow a `$ref` to the schema, response or parameter it points to;
- explain how tools use the file: documentation pages and generated client code.

## Recap
From lessons 01 and 02:
1. Which status code means "you are not signed in", and which means "signed in but not allowed"? <details><summary>Answer</summary>401 and 403.</details>
2. What does a path like `/v1/tasks/{taskId}/complete` with `POST` mean? <details><summary>Answer</summary>An action on one task, sent with `POST` because it changes data.</details>
3. Which command stops Git from committing `.env`? <details><summary>Answer</summary>A line `.env` in `.gitignore`.</details>

## Why it matters
A restaurant prints its menu before the kitchen cooks anything. The waiters read the menu to know what they may offer, and the cooks read it to know what to prepare. **OpenAPI** is the menu of an API: one text file that lists every address (path), every action (method), what you must send and what you get back, including every error. In the Tasks and Teams platform, four backends are written to that file and four client apps are built from it, so when you can read it, you can read all of them.

## What you will build
You will read an excerpt of the platform's real contract (about 160 lines, copied from the platform's `openapi.yaml`), then run a short Python script that prints the operations of the file. You change nothing in the contract; the goal is reading skill.

## Before you start
- Python 3.10 or newer and `pip` (`python --version`; use `python3` on macOS and Linux). A terminal and a text editor.
- Time: about 45 minutes.
- Source pack (optional): every file is shown in full here; the finished files are in https://github.com/Uee03/Code101 under `capstones/platform/source/phase-0-primers/03-reading-an-openapi-file/`. The complete contract is `capstones/platform/source/phase-1-contract/01-openapi-contract/code/openapi.yaml` (27 operations).

## The ideas first
### What OpenAPI is
**OpenAPI** is a standard format (version 3.1.1 here) for describing an HTTP API, written in **YAML** (or JSON). A file in this format is machine readable, so tools can use it:

| Tool kind | What it does with the file |
|-----------|----------------------------|
| Documentation viewers (Swagger UI, Scalar, Redoc) | Turn the file into a web page where each operation can be read and often tried. |
| Validators | Check that the file itself is correct (lesson 01 of phase 1 runs one). |
| Conformance tests | Send requests to a backend and compare the answers with the file (phase 4). |
| Code generators | Write client code (types and one method per operation) for Angular, React, Flutter or Kotlin. |

The platform is built **contract first**: the file was written before any backend, and every backend must match it.

### A five-minute YAML guide
| You see | It means |
|---------|----------|
| `name: value` | A key and its value. |
| two spaces of indentation | The line belongs to the line above it. **Only spaces, never tabs.** |
| `- item` | One entry of a list. |
| `[a, b]` and `{ x: 1, y: 2 }` | A list and a mapping written on one line. |
| `'200':` | A key that is text. The quotes stop YAML from reading it as the number 200. |
| `description: \|` followed by indented lines | A block of text that keeps its line breaks. |
| `# text` | A comment. |

### The sections of an OpenAPI file
| Section | Question it answers |
|---------|---------------------|
| `openapi` | Which version of the OpenAPI language is this? |
| `info` | What is this API called, and which version of the contract is it? |
| `servers` | At which base address do I find it? |
| `security` | Which sign-in is needed by default? |
| `paths` | Which addresses exist, and what can I do at each one? |
| `components` | The reusable pieces: security schemes, parameters, headers, responses and **schemas** (the shapes of JSON). |

Inside `paths`, each address holds **operations**, one per method (`get`, `post`, ...). An operation lists its `parameters`, an optional `requestBody` and its `responses`. A **schema** describes JSON: its `type`, which fields are `required`, limits such as `maxLength`. A **`$ref`** is a pointer: `'#/components/schemas/Task'` means "start at the top of this file, go to `components`, then `schemas`, then `Task`". It avoids writing the same definition twice.

## Steps
### Step 1. Create the folder and the first part of the file
Create a folder `openapi-primer`. Inside it create `mini-openapi.yaml`. You type it in parts (Steps 1 to 5); every part is a continuation of the previous one, and the whole file is a valid OpenAPI document. Begin with the top of the file:

**File: `mini-openapi.yaml` (part 1: the top)**
```yaml
openapi: 3.1.1
info:
  title: Tasks and Teams API
  version: 1.0.0
  summary: The shared contract every Code101 backend implements and every client consumes.
servers:
  - url: http://localhost:8000
    description: Local backend (any of the four implementations, port 8000)
security:
  - oidc: [tasks:read]
```
Reading it:

| Lines | Meaning |
|-------|---------|
| `openapi: 3.1.1` | The language version. 3.1 supports full JSON Schema, which allows `type: [string, 'null']` later. |
| `info` | Name and contract version. Change `version` whenever the contract changes. |
| `servers` | The base URL: `http://localhost:8000`, the port from lesson 02. All four backends use it. |
| `security: - oidc: [tasks:read]` | The **default** for every operation: sign in with the scheme named `oidc` and hold the scope `tasks:read`. A *scope* is a permission label on the token (lesson 04). `oidc` is defined in `components` below. |

### Step 2. Read the `/health` operation
Continue the file directly below (no blank line needed):

**File: `mini-openapi.yaml` (part 2: the health path)**
```yaml
paths:
  /health:
    get:
      operationId: getHealth
      tags: [Platform]
      summary: Liveness and database check
      security: []
      x-access: public
      responses:
        '200':
          description: The service and its database are reachable.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Health' }
        '503':
          description: The database is not reachable.
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Health' }
```
| Line | Meaning |
|------|---------|
| `paths:` and `/health:` | The address `GET /health` from lesson 02. |
| `get:` | The method. One path can have several (`get`, `post`, ...). |
| `operationId: getHealth` | A unique name. Code generators turn it into a method name, so it never changes once published. |
| `tags: [Platform]` | A group label for documentation pages and generated classes. |
| `summary` | One line of human description. |
| `security: []` | An **empty** list overrides the default from Step 1: this operation needs **no token**. That is why you could call `/health` without `Authorization`. |
| `x-access: public` | A custom field of the platform (names starting `x-` are allowed) that says who may call: here everybody. |
| `responses` | Every status the operation can return. Keys are quoted text. |
| `content: application/json: schema:` | The body is JSON with the shape `Health`. The `$ref` points to `components/schemas/Health` (Step 5). |

**Predict:** how many different statuses can `GET /health` return? Two: 200 and 503.

### Step 3. Read an operation with a path parameter: get a task
**File: `mini-openapi.yaml` (part 3: one task)**
```yaml
  /v1/tasks/{taskId}:
    parameters:
      - { $ref: '#/components/parameters/TaskId' }
    get:
      operationId: getTask
      tags: [Tasks]
      summary: One task; send If-None-Match to get 304 when unchanged
      x-access: team-member-or-admin
      parameters:
        - name: If-None-Match
          in: header
          schema: { type: string }
      responses:
        '200':
          description: The task.
          headers:
            ETag: { $ref: '#/components/headers/ETag' }
          content:
            application/json:
              schema: { $ref: '#/components/schemas/Task' }
        '304':
          description: The ETag still matches; no body.
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
```
| Line | Meaning |
|------|---------|
| `/v1/tasks/{taskId}:` | A **path template**. `{taskId}` is a placeholder that the caller replaces with a real id. |
| `parameters: - { $ref: ... TaskId }` (at path level) | Every operation under this path takes the parameter `TaskId`, defined once in `components`. |
| `x-access: team-member-or-admin` | Only a member of the task's team, or an admin, may read it. No `security:` line, so the default (`tasks:read`) applies. |
| `parameters: - name: If-None-Match, in: header` | An optional **header parameter**. `in:` is `path`, `query`, `header` or `cookie`. Sending the last `ETag` back lets the server answer 304. |
| `'200'` with `headers: ETag` | A success carries the version label in an `ETag` response header, and a JSON body shaped like `Task`. |
| `'304'` | No body: your saved copy is current. |
| `'401'`, `'403'`, `'404'` with `$ref` | The three standard errors are defined once under `components/responses` and reused by every operation. |

**Predict:** which status codes can `GET /v1/tasks/{taskId}` return? Count the keys under `responses`: five (200, 304, 401, 403, 404). Notice that 422 is absent: a `GET` has no body to validate.

### Step 4. Read the components
The first half of `components` holds the security scheme, the parameter and two headers:

**File: `mini-openapi.yaml` (part 4: components, scheme, parameter, headers)**
```yaml
components:
  securitySchemes:
    oidc:
      type: openIdConnect
      description: |
        Keycloak realm `tasksteams`. Web and mobile clients use the authorization code flow with PKCE (S256).
        The API only validates the bearer access token: issuer, audience `tasks-api`, expiry and signature.
        Scopes limit what the client may do; the realm role (`admin`, `member`) limits what the user may do.
      openIdConnectUrl: http://localhost:8180/realms/tasksteams/.well-known/openid-configuration
  parameters:
    TaskId:
      name: taskId
      in: path
      required: true
      schema: { type: string, format: uuid }
  headers:
    ETag:
      description: Strong validator, the quoted resource `version`, for example `"3"`.
      schema: { type: string }
    WWWAuthenticate:
      description: The Bearer challenge, for example `Bearer realm="tasksteams"`.
      schema: { type: string }
```
| Piece | Meaning |
|-------|---------|
| `securitySchemes: oidc` | The definition behind the name `oidc` used in `security`. `type: openIdConnect` means "sign in through an OpenID Connect server"; `openIdConnectUrl` is its discovery address: port 8180, realm `tasksteams` (lesson 04). |
| `parameters: TaskId` | A path parameter. A **path** parameter is always `required: true`. `format: uuid` says the text is a UUID such as `7a500000-0000-4000-8000-000000000003`. |
| `headers: ETag` | The description of a response header, reused wherever an operation returns a version label. |

### Step 5. Read the shared responses and the schemas
The error responses reuse one error shape, `Problem`, the problem details body you saw in lesson 02:

**File: `mini-openapi.yaml` (part 5: components, responses)**
```yaml
  responses:
    Unauthorized:
      description: Missing, expired or invalid bearer token.
      headers:
        WWW-Authenticate: { $ref: '#/components/headers/WWWAuthenticate' }
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
          examples:
            noToken:
              value:
                type: https://code101.example/problems/unauthorized
                title: Unauthorized
                status: 401
                detail: A bearer access token is required.
                instance: /v1/me
                traceId: 4bf92f3577b34da6a3ce929d0e0e4736
    Forbidden:
      description: The token is valid but the role, scope or team membership does not allow this.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
          examples:
            notAdmin:
              value:
                type: https://code101.example/problems/forbidden
                title: Forbidden
                status: 403
                detail: The admin role is required.
                instance: /v1/audit-log
                traceId: 4bf92f3577b34da6a3ce929d0e0e4736
    NotFound:
      description: The resource does not exist, or the caller may not know that it exists.
      content:
        application/problem+json:
          schema: { $ref: '#/components/schemas/Problem' }
```
Each response says what the caller sees: a description, extra headers (`WWW-Authenticate` tells the client how to sign in), the `Content-Type` (`application/problem+json`) with its schema, and an **example** body. Examples are for humans and for mock servers; they are not rules.

The schemas are the shapes of JSON:

**File: `mini-openapi.yaml` (part 6: components, schemas)**
```yaml
  schemas:
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
    Health:
      type: object
      required: [status]
      properties:
        status: { type: string, enum: [ok, degraded] }
        version: { type: string, examples: ['1.0.0'] }
        database: { type: string, enum: [up, down] }
    TaskStatus:
      type: string
      enum: [todo, in_progress, blocked, done, cancelled]
    TaskPriority:
      type: string
      enum: [low, medium, high, urgent]
    Task:
      type: object
      required: [id, projectId, title, description, status, priority, assigneeId, dueDate, completedAt, createdBy, version, createdAt, updatedAt]
      properties:
        id: { type: string, format: uuid, readOnly: true }
        projectId: { type: string, format: uuid, readOnly: true }
        title: { type: string, minLength: 1, maxLength: 200 }
        description: { type: string, maxLength: 10000 }
        status: { $ref: '#/components/schemas/TaskStatus' }
        priority: { $ref: '#/components/schemas/TaskPriority' }
        assigneeId: { type: [string, 'null'], format: uuid }
        dueDate: { type: [string, 'null'], format: date }
        completedAt: { type: [string, 'null'], format: date-time, readOnly: true }
        createdBy: { type: string, format: uuid, readOnly: true }
        version: { type: integer, minimum: 1, readOnly: true }
        createdAt: { type: string, format: date-time, readOnly: true }
        updatedAt: { type: string, format: date-time, readOnly: true }
```
How to read a schema:

| Keyword | Meaning |
|---------|---------|
| `type: object` | JSON with named fields. Other types: `string`, `integer`, `boolean`, `array`. |
| `required: [...]` | The fields that must be present. In `Problem`, only `type`, `title` and `status`; `detail` may be left out. |
| `properties` | One entry per field with its own type and limits. |
| `enum: [ok, degraded]` | Only these values are allowed. `TaskStatus` lists the five task states. |
| `minLength`, `maxLength`, `minimum`, `maximum` | Limits. A title longer than 200 characters is a 422 (lesson 02). |
| `format: uuid`, `date`, `date-time` | The text must look like a UUID, a date `2027-02-05` or a time stamp. |
| `type: [string, 'null']` | "A string, or null". This is how a task can have **no** assignee: `"assigneeId": null`. |
| `readOnly: true` | The server sets it; clients do not send it (`id`, `version`, `createdAt`). |
| `$ref` to `TaskStatus` | The field `status` uses the shared enum, so the five words are written once. |

Compare `Task` with the JSON from lesson 02 (`"title": "Configure Keycloak"`, `"completedAt": null`): every key there is a property here, and every key in `required` was in that body.

Your file is complete. It has 160 lines; your editor may show a slightly different count if you add blank lines.

### Step 6. Print the operations with a script
Reading by eye is good for learning; a script is good for large files (the full platform contract has 27 operations). Create `requirements.txt` and `list_operations.py` in the same folder.

**File: `requirements.txt`**
```text
PyYAML==6.0.4
```
`PyYAML` reads YAML files; `==` pins the exact version so everybody gets the same behavior.

**File: `list_operations.py`**
```python
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
```
How it works, in running order:
1. `yaml.safe_load` reads the file into Python dictionaries and lists. `safe_load` never builds unexpected objects, so it is safe for files you did not write.
2. The first `print` shows the title, the contract version and the OpenAPI version from the top of the file.
3. `spec["paths"].items()` gives each path and its content. `item.items()` gives each key under the path: `parameters` (not an operation) and the methods. The `HTTP_METHODS` filter keeps only methods.
4. `{method.upper():6}` writes the method in capitals, padded to 6 characters so the paths line up.

### Step 7. Run it
Create a virtual environment (a private folder of Python packages, so your system Python stays clean), install, and run:

**Terminal (PowerShell; folder: `openapi-primer`)**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python list_operations.py
```
On macOS and Linux use `python3 -m venv .venv`, `source .venv/bin/activate`, `pip install -r requirements.txt` and `python3 list_operations.py`. The prompt starts with `(.venv)` while the environment is active. The `pip` step ends with a line like `Successfully installed PyYAML-6.0.4` (other lines vary). Then:

Expected output:
```text
Tasks and Teams API 1.0.0 (OpenAPI 3.1.1)
GET    /health  getHealth  [public]
GET    /v1/tasks/{taskId}  getTask  [team-member-or-admin]
```
Two operations, matching the two `get:` blocks you read.

## Run it
Two optional ways to see the same file as a documentation page. The file contains only public example data.
- **Swagger Editor.** Open https://editor.swagger.io, choose **File, Import file**, and pick `mini-openapi.yaml`. The right-hand side shows `Platform` and `Tasks` groups with `GET /health` and `GET /v1/tasks/{taskId}`; each one expands to the parameters and responses you read. Swagger UI, Scalar and Redoc are other viewers for the same format; they show the same information in different styles.
- **The idea of generated clients.** A generator reads the same file and writes code. For the platform, each `tags:` value becomes a class and each `operationId` a method, so `getTask` with the path parameter `taskId` becomes a call such as `tasksApi.getTask(taskId)`, and the schema `Task` becomes a type with the fields you read. If a backend later renames a field, the file changes first and the clients are generated again, so a mismatch shows up as a build error instead of a bug in production. The Angular, React, Flutter and Kotlin capstones do this; the exact commands are taught there.

## How it works
- **Contract first.** The file is the single source of truth. Backends are checked against it, clients are generated from it, and the platform's design document tables are derived from it.
- **`$ref` keeps files short.** The full contract is about 1,200 lines because it defines every error, parameter and header once and points to it.
- **A scope and a role are different.** A scope (`tasks:read`) limits what the *app* may do for the user; a role (`admin`, `member`) says what the *user* may do. Both must allow an action. OpenAPI records scopes in `security`; the platform records roles in its own `x-access` field.
- **Misconception to drop:** "the file runs the API." It does not. It *describes* the API; a backend still has to be written, and a conformance script checks that it keeps the promise.

## Try it
Starter: `exercise/starter/list_responses.py`. Copy it into `openapi-primer`, keep the virtual environment active, and run it with `python list_responses.py mini-openapi.yaml`.
1. **Guided.** Fill the first `TODO` so each operation prints its response codes, in file order.
2. **Change.** Fill the second `TODO`: print `  security: no token needed` when the effective security list is empty, otherwise `  security: scope ` and the scopes. Use `operation.get("security", spec["security"])` so the default from the top of the file applies.
3. **Stretch (no single answer).** In a copy of `mini-openapi.yaml`, add a `delete:` operation for `/v1/tasks/{taskId}`. Decide which scope it needs, who may call it (`x-access`) and which statuses it can return. Run the script again.

The starter file:

**File: `exercise/starter/list_responses.py`**
```python
"""Exercise: list the response codes and the security of every operation."""
import sys
from pathlib import Path

import yaml

HTTP_METHODS = {"get", "put", "post", "delete", "patch"}
spec = yaml.safe_load(Path(sys.argv[1]).read_text(encoding="utf-8"))

for url, item in spec["paths"].items():
    for method, operation in item.items():
        if method in HTTP_METHODS:
            codes = []  # TODO rung 1: put the keys of operation["responses"] here
            print(f"{method.upper()} {url}: {', '.join(codes)}")
            # TODO rung 2: print "  security: no token needed" when the security list is empty,
            # otherwise "  security: scope " followed by the scopes.
            # Use operation.get("security", spec["security"]) so the top-level default applies.
```

<details><summary>Solution</summary>

**File: `exercise/solution/list_responses.py`**
```python
"""Exercise: list the response codes and the security of every operation."""
import sys
from pathlib import Path

import yaml

HTTP_METHODS = {"get", "put", "post", "delete", "patch"}
spec = yaml.safe_load(Path(sys.argv[1]).read_text(encoding="utf-8"))

for url, item in spec["paths"].items():
    for method, operation in item.items():
        if method in HTTP_METHODS:
            codes = list(operation["responses"])
            print(f"{method.upper()} {url}: {', '.join(codes)}")
            security = operation.get("security", spec["security"])
            if not security:
                print("  security: no token needed")
            else:
                print("  security: scope " + ", ".join(security[0]["oidc"]))
```
Expected output:
```text
GET /health: 200, 503
  security: no token needed
GET /v1/tasks/{taskId}: 200, 304, 401, 403, 404
  security: scope tasks:read
```
`list(operation["responses"])` lists the keys (the status codes) in file order. `operation.get("security", spec["security"])` returns the operation's own list when it has one (the empty list for `/health` counts as "has one") and the top-level default otherwise. `security[0]["oidc"]` is the list of scopes of the first requirement.

One possible answer for the stretch rung: paste this block directly above the line `components:` in your copy (it belongs under `/v1/tasks/{taskId}:`, at the same indentation as `get:`):

**File: `exercise/solution/delete-task.yaml`**
```yaml
    delete:
      operationId: deleteTask
      tags: [Tasks]
      summary: Delete a task and its comments
      x-access: team-lead-or-admin
      security:
        - oidc: [tasks:write]
      responses:
        '204':
          description: Deleted.
        '401': { $ref: '#/components/responses/Unauthorized' }
        '403': { $ref: '#/components/responses/Forbidden' }
        '404': { $ref: '#/components/responses/NotFound' }
```
The script then adds two lines:
```text
DELETE /v1/tasks/{taskId}: 204, 401, 403, 404
  security: scope tasks:write
```
Reasons: deleting changes data, so it needs the write scope; only a team lead or an admin may do it; success is 204 with no body. The platform's real operation also requires an `If-Match` header and documents 412, which this mini file leaves out.

</details>

## Check yourself
1. Where in the file do you find the shape of the JSON returned by `GET /v1/tasks/{taskId}`? <details><summary>Answer</summary>Under `responses`, `'200'`, `content`, `application/json`, `schema`: a `$ref` to `#/components/schemas/Task`.</details>
2. `/health` has `security: []` but the file also has a top-level `security`. What happens? <details><summary>Answer</summary>The empty list on the operation overrides the default, so `/health` needs no token.</details>
3. What does `type: [string, 'null']` allow? <details><summary>Answer</summary>A text value or `null`; for example a task without an assignee has `"assigneeId": null`.</details>
4. **Predict:** you add `'429': { $ref: '#/components/responses/TooManyRequests' }` to an operation but never define `TooManyRequests` under `components/responses`. What does a validator report? <details><summary>Answer</summary>A broken reference: the pointer leads nowhere. The phase 1 checker prints a message of the form `PointerToNowhere`.</details>
5. Why is `operationId` never renamed after release? <details><summary>Answer</summary>Generated client methods are named after it, so a rename breaks every client's code.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `yaml.scanner.ScannerError` mentioning a tab character | A tab was used for indentation. | Use spaces only, two per level. |
| `KeyError: 'x-access'` from the script | An operation lacks the `x-access` line (or it is misspelled). | Add `x-access:` to the operation. |
| `ModuleNotFoundError: No module named 'yaml'` | The virtual environment is not active or `pip install` did not run. | Activate `.venv` (the prompt shows `(.venv)`) and run `pip install -r requirements.txt`. |
| Response codes look like numbers and the script fails on `', '.join` | A code was written without quotes (`200:` instead of `'200':`). | Quote status codes: `'200':`. |
| The file is valid YAML but a tool says it is not OpenAPI | A section is misspelled (`path:` instead of `paths:`) or indentation is wrong. | Compare the top-level keys with the table in "The sections of an OpenAPI file". |

(The error texts above are typical; the wording varies by library version.)

## Best practice
Read an operation from the outside in: path and method, then who may call it, then what you must send, then every response. Treat the contract as the source of truth and never guess a field name that the file does not contain. Source: [OpenAPI Specification v3.1.1](https://spec.openapis.org/oas/v3.1.1.html) and [Learn OpenAPI](https://learn.openapis.org/).

## Going further
- The full platform contract: `capstones/platform/source/phase-1-contract/01-openapi-contract/code/openapi.yaml`, explained in chapter [01 The OpenAPI contract](../phase-1-contract/01-openapi-contract.md).
- Try the Swagger Editor with the full file and open an operation with a request body, such as `POST /v1/projects/{projectId}/tasks`.

## Summary
- You explained that an OpenAPI file is the machine-readable menu of an API and named its sections.
- You read the `/health` and `getTask` operations: path, method, parameters, security, responses.
- You followed `$ref` pointers to parameters, headers, error responses and schemas, and read `required`, `enum`, `format` and `type: [string, 'null']`.
- You ran a script that lists operations and extended it to show response codes and security.
- You explained how documentation viewers and client generators use the same file.

## Next lesson
04. OAuth 2, OpenID Connect and Keycloak: what the word `Bearer` in `Authorization: Bearer ...` really means, and how the token gets there.
