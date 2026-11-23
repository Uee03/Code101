---
track: web
level: 301
phase: 2
phase_name: systems
lesson: 06
title: "API clients generated from OpenAPI"
time: 150 min
prerequisites: [web-201.05, web-201.07, web-301.01, web-301.02]
versions: { node: "26.13.1", npm: "11.20.0", typescript: "5.9.3", "openapi-typescript": "7.13.0", "openapi-fetch": "0.17.0", zod: "4.6.7", "@types/node": "26.6.6" }
verified: not yet run
source: source/web/301-super-hero-to-legendary/phase-2-systems/06-openapi-clients/
assets: []
---

# 06. API clients generated from OpenAPI

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- generate TypeScript types from an OpenAPI 3.1 contract and call the API through a typed client where a wrong path, parameter or body is a compile error
- validate responses at runtime with a schema and classify every outcome (ok, problem, contract violation, unexpected) instead of trusting the type
- detect drift between the contract, the generated types and your hand-written schemas at compile time and in CI
- handle versioning: additive and breaking changes, deprecation headers, and optimistic concurrency with `ETag` and `If-Match`

## Recap
1. In lesson 02 you said types cannot validate data from the network. Why not?
   <details><summary>Answer</summary>Types are erased at compile time. At runtime a response is just a string of bytes that you parsed into <code>unknown</code> data.</details>
2. In lesson 03 you tested a package as its consumer sees it. What is the equivalent for an API client?
   <details><summary>Answer</summary>Calling it against a server (or a faithful stand-in) and checking what actually arrives, not just that it compiles.</details>
3. What does `412 Precondition Failed` mean in the platform contract?
   <details><summary>Answer</summary>The <code>If-Match</code> version you sent is stale: the resource changed since you read it. A missing <code>If-Match</code> gives 428.</details>

## Why it matters
The contract between a front end and a back end is the most expensive thing to get wrong: a renamed field passes every unit test on both sides and fails in production. An OpenAPI document is that contract in machine-readable form. Generating the client's types from it removes a whole class of mistakes. But generated types describe what the server **promises**; a deployment bug, a proxy error page or a newer server can send something else. This lesson builds the layer that keeps both honest.

## What you will build
A small client for three operations of the Tasks and Teams platform contract (`listTasks`, `getTask`, `updateTask`):
1. `openapi/tasks.openapi.yaml`, a subset of the platform contract.
2. A generated `src/api/schema.d.ts` (by `openapi-typescript`; you create it by running one command).
3. A typed client (`openapi-fetch`) with middleware for the access token, a request id and deprecation warnings.
4. Zod schemas for runtime validation, checked against the generated types at compile time.
5. A scripted fake server so you can watch every outcome without a network, and a CI workflow that fails when the committed types are out of date.

## Before you start
- Lessons 01 to 05 finished (Node 26.13.1, npm 11.20.0).
- **Compiler version: TypeScript 5.9.3 in this lesson, not 7.0.2.** `openapi-typescript` 7.13.0 declares `typescript ^5.x` as a peer dependency and uses the TypeScript compiler API to produce its output. TypeScript 7.0 ships no programmatic API, so the generator cannot run on it. This is a real example of a tool pinning your toolchain: the React capstone pins 5.9.3 for the same reason. Two alternatives exist (an npm alias that installs the TypeScript 6 compatibility package under the name `typescript`, described in the TypeScript 7.0 announcement, or running the generator in a separate package with its own compiler); this lesson takes the simplest, a pinned 5.9.3, and the ADR below says why.
- Builds on Web 201 lessons [05 Generics and type-safe API clients](../../201-hero-to-super-hero/phase-2-typescript-in-depth/05-generics-and-typed-api-clients.md) (a hand-written `Result` and a validating parser) and [07 Fetching data](../../201-hero-to-super-hero/phase-3-app-patterns/07-fetching-data.md) (timeouts, load states). Here the types come from a contract instead of being written by hand.
- Time: 120 to 150 minutes. Break after step 7.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/301-super-hero-to-legendary/phase-2-systems/06-openapi-clients/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- No `package-lock.json` and no generated `schema.d.ts` are shipped: `npm install` creates the first and `npm run generate` the second. In your own repository you commit **both** (see "Failure modes").

## Steps

### Step 1. Create the project
```text
mkdir api-client-lab
cd api-client-lab
mkdir src
mkdir src/api
mkdir openapi
```
Expected result: an `api-client-lab` folder with `src/api` and `openapi` inside. Forward slashes work in Windows PowerShell and in macOS/Linux shells.

### Step 2. Write package.json and tsconfig.json
**File: `package.json`**
```json
{
  "name": "web301-06-openapi-clients",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "generate": "openapi-typescript openapi/tasks.openapi.yaml -o src/api/schema.d.ts",
    "typecheck": "npm run generate && tsc --noEmit",
    "build": "npm run generate && tsc",
    "start": "node dist/demo.js"
  },
  "engines": {
    "node": ">=26.13.1",
    "npm": ">=11.20.0"
  },
  "dependencies": {
    "openapi-fetch": "0.17.0",
    "zod": "4.6.7"
  },
  "devDependencies": {
    "@types/node": "26.6.6",
    "openapi-typescript": "7.13.0",
    "typescript": "5.9.3"
  }
}
```
- `generate` runs the generator CLI: input is the contract, `-o` is the output file. `build` and `typecheck` always regenerate first, so a stale generated file cannot hide a contract change.
- `openapi-fetch` and `zod` are **runtime** dependencies (they ship to browsers); `openapi-typescript` is a **development** dependency (it only runs at build time and its output is plain types, which are erased).

**File: `tsconfig.json`**
```json
{
  "compilerOptions": {
    "target": "ES2023",
    "lib": ["ES2023", "DOM"],
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "rootDir": "src",
    "outDir": "dist",
    "types": ["node"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "noEmitOnError": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*.ts"]
}
```
Compared with lesson 01: `lib` adds `DOM`, so `Request`, `Response` and `crypto` have the same types in Node and in a browser, which is where this client will run. **`exactOptionalPropertyTypes` is deliberately off.** Zod writes an optional field as `detail?: string | undefined` while the generator writes `detail?: string`; with the flag on, TypeScript treats those as different types and the drift check below reports a difference that is not real. You can turn the flag on if you also pass the generator's own `--exact-optional-property-types` option; treat the two settings as a pair.

Install:
```text
npm install --no-audit --no-fund
```
Expected result: `node_modules` and `package-lock.json`. If npm reports a peer dependency conflict (`ERESOLVE`) mentioning `typescript`, you installed a TypeScript version outside the generator's range: use exactly `5.9.3`.

### Step 3. Write the contract
**File: `openapi/tasks.openapi.yaml`**
```yaml
openapi: 3.1.0
info:
  title: Tasks API (a subset of the Tasks and Teams platform contract)
  version: 1.0.0
servers:
  - url: http://localhost:8000
paths:
  /v1/projects/{projectId}/tasks:
    parameters:
      - $ref: '#/components/parameters/ProjectId'
    get:
      operationId: listTasks
      summary: Tasks of a project
      parameters:
        - name: status
          in: query
          schema:
            $ref: '#/components/schemas/TaskStatus'
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 25
      responses:
        '200':
          description: A page of tasks
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TaskPage'
        '502':
          $ref: '#/components/responses/Problem'
  /v1/tasks/{taskId}:
    parameters:
      - $ref: '#/components/parameters/TaskId'
    get:
      operationId: getTask
      summary: One task
      responses:
        '200':
          description: The task
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Task'
        '404':
          $ref: '#/components/responses/Problem'
    patch:
      operationId: updateTask
      summary: Change some fields of a task
      parameters:
        - name: If-Match
          in: header
          required: true
          description: The ETag of the version you last read.
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/TaskUpdate'
      responses:
        '200':
          description: The updated task
          headers:
            ETag:
              $ref: '#/components/headers/ETag'
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Task'
        '412':
          $ref: '#/components/responses/Problem'
        '428':
          $ref: '#/components/responses/Problem'
components:
  parameters:
    ProjectId:
      name: projectId
      in: path
      required: true
      schema:
        type: string
        format: uuid
    TaskId:
      name: taskId
      in: path
      required: true
      schema:
        type: string
        format: uuid
  headers:
    ETag:
      description: The strong version tag of the resource.
      schema:
        type: string
  responses:
    Problem:
      description: An error described as RFC 9457 problem details.
      content:
        application/problem+json:
          schema:
            $ref: '#/components/schemas/Problem'
  schemas:
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
        id: { type: string, format: uuid }
        projectId: { type: string, format: uuid }
        title: { type: string, minLength: 1, maxLength: 200 }
        description: { type: string, maxLength: 10000 }
        status: { $ref: '#/components/schemas/TaskStatus' }
        priority: { $ref: '#/components/schemas/TaskPriority' }
        assigneeId: { type: [string, 'null'], format: uuid }
        dueDate: { type: [string, 'null'], format: date }
        completedAt: { type: [string, 'null'], format: date-time }
        createdBy: { type: string, format: uuid }
        version: { type: integer, minimum: 1 }
        createdAt: { type: string, format: date-time }
        updatedAt: { type: string, format: date-time }
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
    TaskPage:
      type: object
      required: [items, nextCursor]
      properties:
        items:
          type: array
          items:
            $ref: '#/components/schemas/Task'
        nextCursor: { type: [string, 'null'] }
    Problem:
      type: object
      required: [type, title, status]
      properties:
        type: { type: string }
        title: { type: string }
        status: { type: integer, minimum: 400, maximum: 599 }
        detail: { type: string }
        instance: { type: string }
        traceId: { type: string }
        code: { type: string }
```
This is a subset of the platform contract in `capstones/platform` (three operations instead of 27), kept small so you can read all of it. What to notice:
- `operationId` values (`listTasks`, `getTask`, `updateTask`) are the stable names tools use; changing one is a breaking change for generated clients.
- `type: [string, 'null']` is the OpenAPI 3.1 way to say "string or null" (3.0 used `nullable: true`). The generator turns it into `string | null`.
- `required` lists fields that are always present. A field **not** listed is optional in the generated type.
- Responses are reused with `$ref`: `Problem` appears under `application/problem+json`, the media type for RFC 9457 error bodies.
- `If-Match` is a **required header parameter** on `PATCH`, so the generated client refuses to compile a call that omits it.

### Step 4. Generate the types
```text
npm run generate
```
Expected result: a file `src/api/schema.d.ts` appears. I cannot print its exact content before running the generator, but its documented shape is an `export interface paths` (one entry per URL path, with the HTTP methods inside), an `export interface components` (with `schemas`, `responses`, `parameters`, `headers`), and an `export interface operations`. An **excerpt of the kind of output to expect** (names follow your contract; spacing and comments may differ):
```ts
export interface paths {
    "/v1/tasks/{taskId}": {
        get: operations["getTask"];
        patch: operations["updateTask"];
    };
}
export interface components {
    schemas: {
        TaskStatus: "todo" | "in_progress" | "blocked" | "done" | "cancelled";
        Task: {
            id: string;
            title: string;
            assigneeId: string | null;
            version: number;
        };
    };
}
```
Open the generated file once and read its first screen; you will recognise your contract. **Never edit it by hand**: the next generation overwrites it. In a real repository, commit it (reviewers see exactly how a contract change alters the types) and add a CI check that regenerating produces no difference (step 8).

### Step 5. Write the runtime schemas and the drift check
**File: `src/api/compat.ts`**
```ts
// Mutual assignability: the two types describe the same set of values.
export type Assignable<A, B> = [A] extends [B] ? ([B] extends [A] ? true : false) : false;
export type Expect<T extends true> = T;
```
**File: `src/api/schemas.ts`**
```ts
import { z } from 'zod';
import type { Assignable, Expect } from './compat.js';
import type { components } from './schema.js';

export const TaskStatusSchema = z.enum(['todo', 'in_progress', 'blocked', 'done', 'cancelled']);
export const TaskPrioritySchema = z.enum(['low', 'medium', 'high', 'urgent']);

export const TaskSchema = z.object({
  id: z.uuid(),
  projectId: z.uuid(),
  title: z.string().min(1).max(200),
  description: z.string().max(10000),
  status: TaskStatusSchema,
  priority: TaskPrioritySchema,
  assigneeId: z.uuid().nullable(),
  dueDate: z.iso.date().nullable(),
  completedAt: z.iso.datetime().nullable(),
  createdBy: z.uuid(),
  version: z.number().int().min(1),
  createdAt: z.iso.datetime(),
  updatedAt: z.iso.datetime(),
});

export const TaskPageSchema = z.object({
  items: z.array(TaskSchema),
  nextCursor: z.string().nullable(),
});

export const ProblemSchema = z.object({
  type: z.string(),
  title: z.string(),
  status: z.number().int(),
  detail: z.string().optional(),
  instance: z.string().optional(),
  traceId: z.string().optional(),
  code: z.string().optional(),
});

export type Task = components['schemas']['Task'];
export type TaskUpdate = components['schemas']['TaskUpdate'];
export type Problem = components['schemas']['Problem'];

// Drift detection: if the contract changes and these hand-written schemas do not, this file stops compiling.
export type SchemaDriftChecks = [
  Expect<Assignable<z.infer<typeof TaskSchema>, Task>>,
  Expect<Assignable<z.infer<typeof TaskPageSchema>, components['schemas']['TaskPage']>>,
  Expect<Assignable<z.infer<typeof ProblemSchema>, Problem>>,
];
```
Why write schemas by hand when the generator already knows the contract? Because the generator emits **types only**, and types are erased. A runtime check needs runtime code. The hand-written schemas are the second copy of the contract, and a second copy drifts, so `SchemaDriftChecks` makes the compiler compare the two copies: add a required field to `Task` in the YAML, regenerate, and this file stops compiling until the Zod schema has the field too. The trade-offs of this design are in the ADR below.

Details worth knowing: in Zod 4, `z.uuid()`, `z.iso.date()` and `z.iso.datetime()` are top-level validators (the older `z.string().uuid()` style is deprecated). `z.uuid()` checks the RFC 9562 version and variant bits, so a made-up id such as `11111111-1111-1111-1111-111111111111` is **rejected**; the demo uses well-formed version 4 ids.

### Step 6. Write the client
**File: `src/api/client.ts`**
```ts
import createClient, { type Middleware } from 'openapi-fetch';
import type { paths } from './schema.js';

export type FetchLike = (input: Request | URL | string) => Promise<Response>;

export interface ClientOptions {
  baseUrl: string;
  getToken: () => string | undefined;
  fetch?: FetchLike;
  onDeprecation?: (message: string) => void;
}

// The Sunset header is an HTTP date (RFC 8594). Show it as a plain date, or say it is unknown.
export function describeSunset(header: string | null): string {
  if (header === null) {
    return 'not announced';
  }
  const time = Date.parse(header);
  return Number.isNaN(time) ? 'unknown' : new Date(time).toISOString().slice(0, 10);
}

export function createTasksClient(options: ClientOptions) {
  const client = createClient<paths>({ baseUrl: options.baseUrl, fetch: options.fetch });

  const middleware: Middleware = {
    onRequest({ request }) {
      const token = options.getToken();
      if (token !== undefined) {
        request.headers.set('Authorization', `Bearer ${token}`);
      }
      request.headers.set('X-Request-Id', crypto.randomUUID());
      return request;
    },
    onResponse({ response }) {
      // A server announces retirement with the Deprecation and Sunset headers; surface it early.
      if (response.headers.has('Deprecation')) {
        options.onDeprecation?.(
          `Deprecated API in use. Sunset: ${describeSunset(response.headers.get('Sunset'))}`,
        );
      }
      return response;
    },
  };

  client.use(middleware);
  return client;
}

export type TasksClient = ReturnType<typeof createTasksClient>;
```
How it works:
- `createClient<paths>` gives an object whose `GET`, `PATCH` and so on accept **only** the paths that exist for that method, with the parameters the contract demands. A typo in `'/v1/tasks/{taskId}'` is a compile error.
- The access token comes from a **callback** (`getToken`) rather than a value, so it is read at request time and a refreshed token is picked up without recreating the client. Where that token is stored is a security decision (lesson 08).
- The `X-Request-Id` header gives each request an id that the server can log, so one failing user request can be found in the back-end logs.
- The `onResponse` hook watches for the `Deprecation` header and prints the date from `Sunset`. A client that says "this endpoint disappears on 31 October" months ahead is a deprecation policy that works.
- `fetch` is injectable. In production you pass nothing and the global `fetch` is used; here the demo passes a scripted stand-in so no network is needed. The same seam is how you test the client.

**File: `src/api/tasks.ts`**
```ts
import type { z } from 'zod';
import type { TasksClient } from './client.js';
import { ProblemSchema, TaskPageSchema, TaskSchema, type Problem, type Task, type TaskUpdate } from './schemas.js';

export type ApiResult<T> =
  | { kind: 'ok'; value: T; etag: string | undefined }
  | { kind: 'problem'; problem: Problem }
  | { kind: 'contract-violation'; paths: string[] }
  | { kind: 'unexpected'; status: number };

// The one place that decides what a response means. Types say what the contract promises;
// the schema checks what actually arrived.
function interpret<T>(response: Response, data: unknown, error: unknown, schema: z.ZodType<T>): ApiResult<T> {
  if (response.ok) {
    const parsed = schema.safeParse(data);
    if (parsed.success) {
      return { kind: 'ok', value: parsed.data, etag: response.headers.get('ETag') ?? undefined };
    }
    return { kind: 'contract-violation', paths: parsed.error.issues.map((issue) => issue.path.join('.')) };
  }
  const problem = ProblemSchema.safeParse(error);
  return problem.success ? { kind: 'problem', problem: problem.data } : { kind: 'unexpected', status: response.status };
}

export async function getTask(client: TasksClient, taskId: string): Promise<ApiResult<Task>> {
  const { data, error, response } = await client.GET('/v1/tasks/{taskId}', {
    params: { path: { taskId } },
  });
  return interpret(response, data, error, TaskSchema);
}

export async function updateTask(
  client: TasksClient,
  taskId: string,
  etag: string,
  changes: TaskUpdate,
): Promise<ApiResult<Task>> {
  const { data, error, response } = await client.PATCH('/v1/tasks/{taskId}', {
    params: { path: { taskId }, header: { 'If-Match': etag } },
    body: changes,
  });
  return interpret(response, data, error, TaskSchema);
}

export async function listTasks(
  client: TasksClient,
  projectId: string,
  query: { status?: Task['status']; limit?: number } = {},
): Promise<ApiResult<z.infer<typeof TaskPageSchema>>> {
  const { data, error, response } = await client.GET('/v1/projects/{projectId}/tasks', {
    params: { path: { projectId }, query },
  });
  return interpret(response, data, error, TaskPageSchema);
}
```
The four-way `ApiResult` is the point of the file. Most clients return "data or throw" and lose information; this one separates:
- **ok**: a 2xx response that matches the schema, with the `ETag` you need for the next update.
- **problem**: the server said no, in the documented error shape (`problem.status`, `title`, optional `code`). The UI can show `title` and decide on `code`.
- **contract-violation**: a 2xx response that is *not* what the contract promised. This is a bug (server, proxy or a newer version), and it must be reported to telemetry, not shown to the user as a crash.
- **unexpected**: anything else, such as an HTML error page from a gateway.

Notice how few lines it takes to make an unlisted case impossible: callers `switch` on `kind` and lesson 02's exhaustive check applies.

### Step 7. Write the fake server and the demo
**File: `src/fake-server.ts`**
```ts
import type { FetchLike } from './api/client.js';

export const TASK_ID = '3f2b1c5e-8a41-4d3b-9c6e-1a2b3c4d5e6f';
export const PROJECT_ID = '0b6d7a52-4c1e-4f0a-8d33-5e9f2c7a1b40';
const USER_ID = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

export const TASK = {
  id: TASK_ID,
  projectId: PROJECT_ID,
  title: 'Write the ADR',
  description: '',
  status: 'todo',
  priority: 'high',
  assigneeId: null,
  dueDate: '2026-12-01',
  completedAt: null,
  createdBy: USER_ID,
  version: 3,
  createdAt: '2026-11-20T09:30:00Z',
  updatedAt: '2026-11-21T10:00:00Z',
};

export const PROBLEM_JSON = 'application/problem+json';

export interface Scripted {
  status: number;
  body: unknown;
  contentType?: string;
  headers?: Record<string, string>;
}

// A fetch replacement that answers from a list, in order, and records each request. No network is used.
export function scriptedFetch(queue: Scripted[], calls: string[]): FetchLike {
  return async (input) => {
    const request = input instanceof Request ? input : new Request(input);
    calls.push(
      `${request.method} ${new URL(request.url).pathname} auth=${request.headers.get('Authorization') ?? 'none'}`,
    );
    const next = queue.shift();
    if (next === undefined) {
      throw new Error('No scripted response left');
    }
    const body = typeof next.body === 'string' ? next.body : JSON.stringify(next.body);
    return new Response(body, {
      status: next.status,
      headers: { 'Content-Type': next.contentType ?? 'application/json', ...next.headers },
    });
  };
}
```
**File: `src/demo.ts`**
```ts
import { createTasksClient } from './api/client.js';
import { getTask, listTasks, updateTask, type ApiResult } from './api/tasks.js';
import { PROBLEM_JSON, PROJECT_ID, scriptedFetch, TASK, TASK_ID, type Scripted } from './fake-server.js';

// Responses the fake server will give, in order.
const queue: Scripted[] = [
  { status: 200, body: TASK, headers: { ETag: '"3"', Deprecation: 'true', Sunset: 'Sun, 31 Oct 2027 00:00:00 GMT' } },
  { status: 200, body: { ...TASK, priority: 'critical' } },
  { status: 404, contentType: PROBLEM_JSON, body: { type: 'urn:problem:not-found', title: 'Task not found', status: 404 } },
  { status: 412, contentType: PROBLEM_JSON, body: { type: 'urn:problem:conflict', title: 'Version conflict', status: 412, code: 'version_conflict' } },
  { status: 200, body: { items: [TASK], nextCursor: null } },
  { status: 502, contentType: 'text/plain', body: 'Bad Gateway' },
];

const calls: string[] = [];

const client = createTasksClient({
  baseUrl: 'http://localhost:8000',
  getToken: () => 'demo-token',
  fetch: scriptedFetch(queue, calls),
  onDeprecation: (message) => console.log(`WARN ${message}`),
});

function describeResult(result: ApiResult<unknown>): string {
  switch (result.kind) {
    case 'ok': {
      const value = result.value as { title?: string; version?: number; items?: unknown[] };
      return value.items !== undefined
        ? `ok ${value.items.length} task(s)`
        : `ok ${value.title} (etag ${result.etag}, version ${value.version})`;
    }
    case 'problem':
      return `problem ${result.problem.status} ${result.problem.title}${result.problem.code ? ` (${result.problem.code})` : ''}`;
    case 'contract-violation':
      return `contract violation at ${result.paths.join(', ')}`;
    case 'unexpected':
      return `unexpected status ${result.status}`;
  }
}

console.log(describeResult(await getTask(client, TASK_ID)));
console.log(describeResult(await getTask(client, TASK_ID)));
console.log(describeResult(await getTask(client, TASK_ID)));
console.log(describeResult(await updateTask(client, TASK_ID, '"2"', { title: 'New title' })));
console.log(describeResult(await listTasks(client, PROJECT_ID, { limit: 10 })));
console.log(describeResult(await listTasks(client, PROJECT_ID)));
console.log('requests:');
for (const call of calls) {
  console.log(call);
}
```
The six scripted responses are the six situations a real client meets: a good response (with a deprecation notice), a response with a **value the contract does not allow** (`priority: 'critical'`), a documented 404, a documented 412 conflict, a good list, and a gateway error with a plain-text body.

## Run it
**Predict first:**
1. Which of the six calls prints `contract violation`, and at which path?
2. In which order do the `WARN` line and the first `ok` line appear, and why?
3. What is the `auth=` part of the last request line?

```text
npm run build
npm start
```
Expected output (not yet run):
```text
WARN Deprecated API in use. Sunset: 2027-10-31
ok Write the ADR (etag "3", version 3)
contract violation at priority
problem 404 Task not found
problem 412 Version conflict (version_conflict)
ok 1 task(s)
unexpected status 502
requests:
GET /v1/tasks/3f2b1c5e-8a41-4d3b-9c6e-1a2b3c4d5e6f auth=Bearer demo-token
GET /v1/tasks/3f2b1c5e-8a41-4d3b-9c6e-1a2b3c4d5e6f auth=Bearer demo-token
GET /v1/tasks/3f2b1c5e-8a41-4d3b-9c6e-1a2b3c4d5e6f auth=Bearer demo-token
PATCH /v1/tasks/3f2b1c5e-8a41-4d3b-9c6e-1a2b3c4d5e6f auth=Bearer demo-token
GET /v1/projects/0b6d7a52-4c1e-4f0a-8d33-5e9f2c7a1b40/tasks auth=Bearer demo-token
GET /v1/projects/0b6d7a52-4c1e-4f0a-8d33-5e9f2c7a1b40/tasks auth=Bearer demo-token
```
Answers: (1) the second call, at path `priority`; (2) `WARN` first, because the middleware runs while the first request is being processed and the result is printed after the call returns; (3) `auth=Bearer demo-token`: the middleware adds the header to every request, including the failing ones.

**Break it on purpose.** (a) In `demo.ts` change `getTask(client, TASK_ID)` to `getTask(client, 42)` and read the compile error (a number is not a string). (b) Change the path `'/v1/tasks/{taskId}'` in `tasks.ts` to `'/v1/task/{taskId}'` and read the error; the typical message says the argument is not assignable to the union of known paths. (c) Delete `header: { 'If-Match': etag }` from `updateTask`: the compiler now says a required property is missing. Undo each change.

### Step 8. Write the CI check for generated code (do this after you have run the demo)
**File: `.github/workflows/contract.yml`**
```yaml
name: contract

on:
  pull_request:
    paths:
      - 'openapi/**'
      - 'src/api/**'
      - 'package.json'

permissions:
  contents: read

jobs:
  generated-types-are-current:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false

      - uses: actions/setup-node@v7
        with:
          node-version: '26.13.1'
          cache: npm

      - run: npm ci --ignore-scripts

      - name: Regenerate the types from the contract
        run: npm run generate

      - name: Fail if the committed types are out of date
        run: git diff --exit-code -- src/api/schema.d.ts

      - name: Type-check the hand-written schemas against the generated types
        run: npx tsc --noEmit
```
Create the folder `.github/workflows` first. Line by line: it runs only when the contract, the client code or `package.json` change (`paths`), has read-only permissions, regenerates the types, **fails if the regenerated file differs from the committed one** (`git diff --exit-code` exits with 1 when there is a difference), and finally type-checks everything, which includes the drift check from step 5. The result: nobody can change the YAML without the generated file, and nobody can change the generated file without the YAML.

## How it works
1. **Contract to types.** `openapi-typescript` parses the YAML and writes `paths`, `components` and `operations` as TypeScript interfaces. Types only: no runtime code.
2. **Types to calls.** `openapi-fetch` is generic over `paths`. Its `GET`, `PATCH` and so on use mapped and conditional types (lessons 01 and 02) to compute the allowed parameters and body, and the types of `data` and `error`, from `paths`.
3. **Calls to results.** `interpret` turns what actually arrived into one of four outcomes.
4. **Guardrails.** The drift check, the regeneration check in CI and the middleware keep the layers honest.

**Common misconception:** "The client is type-safe, so the response is trusted." The *code* you write is checked against the contract. The *data* is not. If the server sends `priority: 'critical'`, the type still says `'low' | 'medium' | 'high' | 'urgent'`; only the runtime schema notices.

**Why this, not that (ADR style)**

| Decision | Chosen | Alternative | Why / when to switch |
|---|---|---|---|
| Contract source | Contract-first (YAML is the source, server and client conform to it) | Code-first (generate the YAML from server code) | Contract-first lets the front end start before the server exists and makes breaking changes visible in review. Switch to code-first only if one team owns both sides and the framework generates an accurate spec |
| Client style | Types plus a thin fetch wrapper (`openapi-fetch`) | A fully generated client class per operation (for example the Angular capstone's generated services) | Thin wrappers add almost no code to ship and no generated runtime to review. Fully generated clients give per-operation functions and framework integration. The two web capstones use one of each, so compare them |
| Runtime validation | Hand-written Zod schemas, drift-checked | Generate the schemas from the YAML | Hand-written schemas are readable, can be strict on what you rely on and tolerant on the rest, and the drift check stops divergence. Generated schemas remove the second copy but tie you to a generator and to its idea of strictness |
| Where to validate | Every response, here | Only in development, or a sample in production | Validation costs CPU and bundle size (measure both, see below). Safe default: validate always; relax for large, hot, low-risk endpoints once telemetry shows the contract is stable |
| Compiler version | TypeScript 5.9.3 pinned | TypeScript 7 plus a TypeScript 6 alias for the generator | The pin is simple and matches the capstone. The alias gives the faster compiler for everything else; it adds a package alias and an npm `overrides` entry to explain peer dependencies. Revisit when the generator supports 7 |
| Generated file | Committed to Git | Generated on every build, not committed | Committed: reviewers see the effect of a contract change, builds do not depend on the generator running. Not committed: no noisy diffs but invisible changes. Committed plus a CI regeneration check gets both |

**Versioning and compatibility: the rules**

| Change in the contract | Compatible for old clients? | What a client should do |
|---|---|---|
| New optional response field | Yes | A tolerant client ignores it; a strict (`.strict()`) schema would reject it, so choose `strict` deliberately |
| New operation | Yes | Nothing |
| New value in a response enum | **Not for strict enums** | Decide per field whether an unknown value is an error or a fallback (see failure modes) |
| New required request field | No | Needs a new version or a default on the server |
| Removed or renamed field, operation or `operationId` | No | New major version (`/v2`), with `Deprecation` and `Sunset` headers on `/v1` for a published period |
| Tighter validation (shorter maximum length) | No for callers who sent longer values | Treat as a breaking change |

Versioning styles compared: **URL** (`/v1/...`, used by the platform contract) is visible, cacheable and easy to route; **header or media type** versioning keeps URLs stable but hides the version from logs and caches. A client pins one major version in its base path and updates it on purpose. To catch accidental breaking changes before release, compare the old and new contract in CI with a contract-diff tool (for example `oasdiff`; check its documentation for the command and options you need).

**Failure modes**
- **Strict enums turn a harmless addition into an outage.** In the demo, one unknown `priority` makes the whole `getTask` a `contract-violation`. For display-only fields use a fallback (`TaskPrioritySchema.catch('low')` returns `'low'` instead of failing, which hides the problem; log it) and keep strict validation for fields your logic depends on.
- **Generated file drifts from the contract.** Someone edits the YAML and forgets to regenerate. The CI check in step 8 fails the pull request.
- **Validation cost.** A schema runs on every response. Measure it for your largest list: in DevTools, use the Performance panel and look at the time spent in your validation function for a realistic response, and use the Network panel to see response size. Zod adds to the bundle too; check the number with your bundler's report (lesson 07). Write down your measurements.
- **Server errors that are not JSON.** Gateways and proxies answer with HTML or plain text. The `unexpected` outcome and the check of the media type handle this; a client that always calls `response.json()` would throw.
- **Retries that cause duplicates.** Only retry requests that are safe to repeat (GET, and updates guarded by `If-Match`). Never auto-retry a `POST` that creates something unless the server supports idempotency keys.
- **Leaking tokens.** The `Authorization` header must go only to your own origin. The base URL is fixed in `createClient`; never build absolute URLs from server-provided values and send the token along.
- **Stale ETag.** An update with an old `If-Match` is a 412. Show the user the conflict; do not silently retry unless the change is independent (see the exercise).

**When not to generate a client**
- A tiny API with two endpoints: a handful of hand-written types may be cheaper than a generator and a CI check.
- A contract that is not kept accurate: generated types from a wrong contract give false confidence. Fix the contract process first.
- When the server team will not commit to a contract and changes shapes weekly. Add contract tests on the server first.

## Try it
Copy your project to `api-client-lab-try`. The starter is in `exercise/starter`.
1. **Guided.** Copy the starter's `src/api/retry.ts` and `src/exercise.ts` into your project. `updateWithRetry` does one attempt and gives up. Make it do what the TODOs say: on a 412, fetch the task again with `getTask`, take its new ETag, and retry up to `maxRetries` times. Expected output after `npm run build` and `node dist/exercise.js`:
```text
ok after 1 retry(ies)
PATCH /v1/tasks/3f2b1c5e-8a41-4d3b-9c6e-1a2b3c4d5e6f auth=none
GET /v1/tasks/3f2b1c5e-8a41-4d3b-9c6e-1a2b3c4d5e6f auth=none
PATCH /v1/tasks/3f2b1c5e-8a41-4d3b-9c6e-1a2b3c4d5e6f auth=none
```
2. **Change.** Make `priority` tolerant: an unknown value becomes `'medium'` and a warning is logged, while every other field stays strict. Which function should log: the schema, `interpret`, or the caller? Add a demo case that proves it.
3. **Stretch (no single answer).** Retrying a 412 blindly can overwrite someone else's change (a "lost update"). Write down which kinds of change are safe to re-apply automatically (for example, adding a label) and which need a human decision (for example, changing the title) and how your API would express that.

<details><summary>Solution</summary>

**File: `exercise/solution/src/api/retry.ts`**
```ts
import type { TasksClient } from './client.js';
import type { Task, TaskUpdate } from './schemas.js';
import { getTask, updateTask, type ApiResult } from './tasks.js';

export interface RetryOutcome {
  result: ApiResult<Task>;
  retries: number;
}

// Optimistic concurrency: a 412 means someone else changed the task after we read it.
// Re-reading and re-applying is only safe when "changes" does not depend on what the other writer did.
export async function updateWithRetry(
  client: TasksClient,
  taskId: string,
  etag: string,
  changes: TaskUpdate,
  maxRetries = 1,
): Promise<RetryOutcome> {
  let currentEtag = etag;
  for (let retries = 0; ; retries += 1) {
    const result = await updateTask(client, taskId, currentEtag, changes);
    const conflict = result.kind === 'problem' && result.problem.status === 412;
    if (!conflict || retries >= maxRetries) {
      return { result, retries };
    }
    const fresh = await getTask(client, taskId);
    if (fresh.kind !== 'ok' || fresh.etag === undefined) {
      return { result: fresh, retries };
    }
    currentEtag = fresh.etag;
  }
}
```
The loop returns the last result as soon as there is no conflict or the budget is spent, so a persistent conflict surfaces to the caller instead of looping. If the refetch itself fails (404, contract violation, network), that failure is returned as-is: hiding it behind the original 412 would send the user chasing the wrong problem. `src/exercise.ts` is the same file as in the starter. For rung 2 a good place to log is the caller of `interpret`'s result (the code that decides what to do), because the schema is a pure description and `interpret` should not have side effects; accept a callback in `createTasksClient` for reporting.

</details>

## Check yourself
1. Why does the project pin TypeScript 5.9.3 and not 7.0.2? <details><summary>Answer</summary>The generator declares a peer dependency on TypeScript 5 and calls the compiler API, which TypeScript 7.0 does not provide. A tool can pin your compiler.</details>
2. What does `SchemaDriftChecks` catch that the generator cannot? <details><summary>Answer</summary>A hand-written runtime schema that no longer matches the generated types, for example after a new required field in the contract.</details>
3. A gateway returns an HTML 502 page. Which `ApiResult` kind do you get and why? <details><summary>Answer</summary><code>unexpected</code>: the body is not valid problem details, so it cannot be the documented error shape; the status is preserved.</details>
4. Find the bug: `request.headers.set('Authorization', token)` where `token` is a plain token string. What does the server see? <details><summary>Answer</summary>No authentication scheme: the header value is just the token, and a server expecting <code>Bearer &lt;token&gt;</code> rejects it.</details>
5. When is an automatic retry after a 412 safe? <details><summary>Answer</summary>When the change is independent of what the other writer did (for example adding a label). Otherwise the user must see the conflict, or the other writer's change is lost.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `npm error ERESOLVE ... peer typescript@"^5.x"` (typical) | A TypeScript version outside 5.x | Install exactly `typescript@5.9.3` |
| `Cannot find module './schema.js' or its corresponding type declarations.` (typical) | You have not run `npm run generate` yet | Run it (`build` and `typecheck` do it for you) |
| `Argument of type '"/v1/task/{taskId}"' is not assignable to parameter of type ...` (typical shape) | A path that does not exist in the contract | Fix the spelling or add the path to the YAML and regenerate |
| `Property 'If-Match' is missing in type ...` (typical shape) | A required header parameter was not passed | Pass `header: { 'If-Match': etag }` |
| Every result is `contract-violation` at `id` | Test ids are not valid UUIDs (Zod checks version and variant) | Use real version 4 ids, like the demo |
| `Failed to parse URL from /v1/tasks/...` (typical) | `baseUrl` missing or relative in Node | Pass an absolute `baseUrl` such as `http://localhost:8000` |
| `npm.ps1 cannot be loaded` | PowerShell execution policy | Use `npm.cmd` |

## Best practice
Treat the contract as the source of truth, generate types from it, and validate data at the boundary anyway: types prove your code is consistent, schemas prove the world is. Source: OpenAPI Initiative, [OpenAPI Specification 3.1](https://spec.openapis.org/oas/v3.1.0); [openapi-typescript documentation](https://openapi-ts.dev/); IETF [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457).

## Production checklist
- [ ] The contract is reviewed like code; `operationId` values are stable.
- [ ] Generated types are committed and CI fails if regeneration changes them.
- [ ] Hand-written schemas are compared with the generated types at compile time.
- [ ] Every response is classified (ok, problem, contract violation, unexpected); contract violations are reported to telemetry.
- [ ] Enums and unions that servers may extend have an explicit tolerance policy per field.
- [ ] Tokens go only to your own origin; the token is read per request.
- [ ] Deprecation and Sunset headers are surfaced to developers and monitoring.
- [ ] Retries only for safe requests; updates use `If-Match`; conflicts are shown to users.
- [ ] You measured validation time and bundle size for your largest response (record your numbers).
- [ ] A contract-diff check runs on pull requests that change the YAML.

## Going further
- openapi-ts.dev: [openapi-fetch API](https://openapi-ts.dev/openapi-fetch/api) and the middleware documentation.
- Capstone link: the generated clients of both web capstones: [capstones/web-angular](../../../../capstones/web-angular/README.md) (generated services) and [capstones/web-react](../../../../capstones/web-react/README.md) (types plus a thin client). Add the four-way `ApiResult` to one of them as a refactoring exercise.
- MDN: [`ETag`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/ETag) and [`If-Match`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/If-Match).

## Summary
- You generated types from an OpenAPI 3.1 contract and called the API through a typed client.
- You validated responses at runtime and classified four outcomes.
- You made drift between the contract, generated types and schemas fail at compile time and in CI.
- You applied versioning rules, deprecation headers and optimistic concurrency, and listed the failure modes of each.

## Next lesson
07. Performance budgets and browser internals: measure what the user feels, and put a limit on it in CI.
