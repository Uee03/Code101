---
track: capstone
level: 201
phase: 4
phase_name: errors
lesson: 04
title: "Problem details, 412, offline, WCAG"
time: 240 min
prerequisites: [capstone-web-react-03]
versions: { react: "19.3.1", vite: "8.3.8", typescript: "5.9.3", react_router: "8.5.2", tanstack_query: "5.108.3", node: "26.13.1", npm: "11.20.0" }
verified: not yet run
source: capstones/web-react/source/phase-4-errors/04-errors-and-accessibility/
assets: [ui/search, ui/filter, ui/plus, ui/x, ui/check-circle, ui/alert-triangle, ui/list, ui/columns, arrows/log-in, arrows/log-out, arrows/refresh-cw, users/users, cloud-network/cloud-off, time/calendar-days]
---

# 04. Problem details, 412, offline, WCAG

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

> **Current delivery status: written (not run).** Per the updated no-execution instruction, the final verification run was stopped. Do not run builds, smoke scripts, Docker startup or servers as part of this authoring session. Commands below are deferred learner instructions. Previously captured output is historical evidence from before that instruction, not verification of this written delivery. Browser-only acceptance remains manual.

## Why it matters
Two people editing a shared document must not silently erase each other. An ETag is a version label, and If-Match makes the server check the label before saving. The UI can feel immediate without pretending a failed write succeeded.

## What you will build
One problem-details parser; optimistic task and team edits with rollback; a native conflict dialog preserving the draft; conditional task reads that keep the cached value on 304; visible retry/offline/rate-limit states; a keyboard and reflow checklist. The smoke creates a temporary task, replays its key, conflicts, completes and deletes it.

Requirements: **W-23 to W-28, W-33**. Chapter numbering, phase names and screen names match the approved React/Angular plan. This is a long capstone workshop, not a 20-minute language lesson.

## Before you start
- Finish Web 101 forms, CSS layout, TypeScript, modules and fetch. Read the platform contract and Keycloak chapters. Keep [TDD.md](../../TDD.md) beside you; platform TDD section 12.1 Decision is authoritative when v1 OpenAPI omits a runtime case.
- Node 26.13.1, npm 11.20.0, Docker Desktop (Linux containers), Python for repository verification/locking. After installation close/reopen the terminal. Official references and pins: [REFERENCES.md](../../REFERENCES.md).
- Download `web-react-phase-4-errors.zip`. Windows: right-click ? Extract All; macOS: double-click; Linux: `unzip web-react-phase-4-errors.zip`. Open `04-errors-and-accessibility/code` inside the extracted phase folder. Each pack contains the **whole app**, not a patch. Do not copy node_modules or dist from another phase.
- Open PowerShell in `code` (the prompt path must end in `04-errors-and-accessibility\code`). Recover with `Set-Location 'F:\Projects\Uee03\Code101\capstones\web-react\source\phase-4-errors\04-errors-and-accessibility\code'` in this repository. macOS/Linux: `cd /path/to/Code101/capstones/web-react/source/phase-4-errors/04-errors-and-accessibility/code`. Substitute your clone location once, not the relative file names.
- Save files before running (an editor tab dot means unsaved). All text is UTF-8 without BOM; PowerShell 5.1 Set-Content -Encoding utf8 adds a BOM, so use your editor.
- Ports 5432, 8180, 8000 and 5173 must be free. Do not stop another agent's stack. Keycloak readiness timeout is **420 seconds**.
- `backend/` is a **verbatim copy** of `capstones/backend-python/source/phase-5-hardening/05-hardening/code/`. Its Compose files start Postgres, Keycloak and Python API. This is a smoke fixture, not a second implementation. Use any other conformant backend on 8000 after stopping it.

## Steps
### Step 1. Prepare the working copy and preserve the contract
The extracted pack is the fastest route. A scratch author must create the same `code` directory and every file below. Do not start Vite until all files and the contract are present. Commands are PowerShell 5.1 compatible.

Continuing? New or changed files: `scripts/smoke.ts`, `src/api/notices.ts`, `src/api/problem.ts`, `src/api/unwrap.ts`, `src/auth/auth-middleware.ts`, `src/core/connectivity.ts`, `src/hooks/action.ts`, `src/hooks/projects.ts`, `src/hooks/tasks.ts`, `src/hooks/teams.ts`, `src/main.tsx`, `src/pages/TaskDetail.tsx`, `src/router.tsx`, `src/shared/Banner.tsx`, `src/shared/ConflictDialog.tsx`, `src/shared/Notice.tsx`, `src/shared/WriteForm.tsx`. To avoid missing context, **every authored file is shown in full**, including unchanged files; there are no omitted edit regions. Or start from this phase pack.

For a scratch copy inside the repository, open a second terminal at the repository root and copy upstream bytes, never edit them:

**File: `terminal (repository root)`**
```powershell
$dest = 'capstones/web-react/source/phase-4-errors/04-errors-and-accessibility/code'
New-Item -ItemType Directory -Force "$dest/contract", "$dest/backend" | Out-Null
Copy-Item 'capstones/platform/source/phase-4-conformance/04-conformance-script/code/openapi.yaml' "$dest/contract/openapi.yaml"
Copy-Item 'capstones/backend-python/source/phase-5-hardening/05-hardening/code/*' "$dest/backend" -Recurse -Force
Copy-Item 'capstones/backend-python/source/phase-5-hardening/05-hardening/code/.env.example' "$dest/backend/.env.example"
Copy-Item 'capstones/backend-python/source/phase-5-hardening/05-hardening/code/.dockerignore' "$dest/backend/.dockerignore"
```

macOS/Linux, repository root:

**File: `terminal (repository root)`**
```bash
dest='capstones/web-react/source/phase-4-errors/04-errors-and-accessibility/code'
mkdir -p "$dest/contract" "$dest/backend"
cp capstones/platform/source/phase-4-conformance/04-conformance-script/code/openapi.yaml "$dest/contract/openapi.yaml"
cp -R capstones/backend-python/source/phase-5-hardening/05-hardening/code/. "$dest/backend/"
```

Expected result: contract/openapi.yaml and the complete backend fixture exist. Return to your `code` terminal. Do not copy a running backend's .env, build products or caches. The supplied pack excludes them.

**Disclosed text-check exclusions:** generated package-lock.json and src/api/schema.d.ts are in skip_lesson_check. The immutable upstream contract, upstream backend implementation/data/realm, and copied CC0 icon/licence files are also excluded **because they are copied, not authored here**; verify.json enumerates every path. Backend Docker/Compose/environment configurations are nevertheless shown in full below. Every authored app file, including smoke scripts, is shown. Regenerate types, never hand-edit them; recopy upstream bytes, never locally ?fix? the contract.

Create these folders in code. Existing folders are harmless; Out-Null suppresses folder-table output.

**File: `terminal (code)`**
```powershell
New-Item -ItemType Directory -Force 'scripts', 'src', 'src/api', 'src/auth', 'src/core', 'src/hooks', 'src/pages', 'src/shared' | Out-Null
```

**File: `terminal (code, macOS/Linux)`**
```bash
mkdir -p scripts src src/api src/auth src/core src/hooks src/pages src/shared
```

### Step 2. Create or replace `package.json`
In code, create the file at this path, paste the complete contents and save. Pin every dependency exactly. Scripts named predev and prebuild are npm lifecycle hooks: both regenerate types before the command they guard. Build runs the TypeScript project references before Vite emits assets; it is not a unit-test suite.

**File: `package.json`**
```json
{
  "name": "tasks-web-react",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "api:gen": "openapi-typescript contract/openapi.yaml -o src/api/schema.d.ts",
    "predev": "npm run api:gen",
    "dev": "vite",
    "prebuild": "npm run api:gen",
    "build": "tsc -b && vite build",
    "preview": "vite preview",
    "smoke": "tsx scripts/smoke.ts",
    "smoke:auth": "tsx scripts/smoke-auth.ts"
  },
  "dependencies": {
    "react": "19.3.1",
    "react-dom": "19.3.1",
    "react-router": "8.5.2",
    "@tanstack/react-query": "5.108.3",
    "openapi-fetch": "0.17.0",
    "oidc-client-ts": "3.5.0",
    "react-oidc-context": "3.3.1"
  },
  "devDependencies": {
    "@types/react": "19.3.0",
    "@types/react-dom": "19.3.0",
    "@types/node": "26.6.6",
    "@vitejs/plugin-react": "6.3.0",
    "typescript": "5.9.3",
    "vite": "8.3.8",
    "openapi-typescript": "7.13.0",
    "tsx": "4.23.15"
  }
}
```

Expected result: `package.json` is saved exactly as shown. See the configuration reading guide below.

### Step 3. Create or replace `tsconfig.json`
In code, create the file at this path, paste the complete contents and save. This solution-style file lists the browser and Node compiler projects; files is empty because the two referenced projects own their own include lists.

**File: `tsconfig.json`**
```json
{
  "files": [],
  "references": [
    {
      "path": "./tsconfig.app.json"
    },
    {
      "path": "./tsconfig.node.json"
    }
  ]
}
```

Expected result: `tsconfig.json` is saved exactly as shown. See the configuration reading guide below.

### Step 4. Create or replace `tsconfig.app.json`
In code, create the file at this path, paste the complete contents and save. Compile src as strict browser TypeScript with React JSX and Vite environment declarations. ES2022 is the browser target; Bundler resolves extensionless imports like Vite. noUncheckedIndexedAccess forces handling missing elements. noEmit leaves JavaScript emission to Vite.

**File: `tsconfig.app.json`**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": [
      "ES2022",
      "DOM",
      "DOM.Iterable"
    ],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "noEmit": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "skipLibCheck": true,
    "jsx": "react-jsx",
    "types": [
      "vite/client"
    ],
    "tsBuildInfoFile": "./node_modules/.tmp/tsconfig.app.tsbuildinfo"
  },
  "include": [
    "src"
  ]
}
```

Expected result: `tsconfig.app.json` is saved exactly as shown. See the configuration reading guide below.

### Step 5. Create or replace `tsconfig.node.json`
In code, create the file at this path, paste the complete contents and save. Compile the Vite config and Node smoke scripts with node plus vite/client declarations, because the framework-free API imports config.ts. No Node script reads environment configuration through import.meta.env; config.ts safely falls back to defaults outside Vite.

**File: `tsconfig.node.json`**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": [
      "ES2022",
      "DOM",
      "DOM.Iterable"
    ],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "noEmit": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "skipLibCheck": true,
    "types": [
      "node",
      "vite/client"
    ],
    "tsBuildInfoFile": "./node_modules/.tmp/tsconfig.node.tsbuildinfo"
  },
  "include": [
    "vite.config.ts",
    "scripts"
  ]
}
```

Expected result: `tsconfig.node.json` is saved exactly as shown. See the configuration reading guide below.

### Step 6. Create or replace `vite.config.ts`
In code, create the file at this path, paste the complete contents and save. The React plugin enables the template integration. host localhost restricts development to the local machine. port 5173 matches Keycloak and backend CORS. strictPort refuses a busy port instead of silently choosing an unregistered origin. There is deliberately no proxy: browser requests exercise real CORS.

**File: `vite.config.ts`**
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({
  plugins: [react()],
  server: { host: 'localhost', port: 5173, strictPort: true },
});
```

Expected result: `vite.config.ts` is saved exactly as shown. See the configuration reading guide below.

### Step 7. Create or replace `.env.example`
In code, create the file at this path, paste the complete contents and save. All three VITE_ values are public build-time settings, never secrets. Copy to .env only to override defaults. Restart Vite after editing .env; rebuild an image after changing build-time settings. localhost in the authority must match the token issuer exactly.

**File: `.env.example`**
```text
VITE_API_BASE_URL=http://localhost:8000
VITE_OIDC_AUTHORITY=http://localhost:8180/realms/tasksteams
VITE_OIDC_CLIENT_ID=tasks-web
```

Expected result: `.env.example` is saved exactly as shown. See the configuration reading guide below.

### Step 8. Create or replace `.gitignore`
In code, create the file at this path, paste the complete contents and save. Exclude installed packages, emitted output, local environment values, logs, generated schema declarations and incremental compiler state. The lockfile is intentionally not ignored.

**File: `.gitignore`**
```text
node_modules
dist
.env
*.log
src/api/schema.d.ts
*.tsbuildinfo
```

Expected result: `.gitignore` is saved exactly as shown. See the configuration reading guide below.

### Step 9. Create or replace `index.html`
In code, create the file at this path, paste the complete contents and save. lang supports assistive technology; UTF-8 preserves text; viewport enables phone-sized layouts. The root element is React?s only mount point. The external module entry is transformed into external hashed assets by Vite, compatible with the production CSP.

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Tasks and Teams</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

Expected result: `index.html` is saved exactly as shown. See the configuration reading guide below.

### Step 10. Create or replace `src/config.ts`
In code, create the file at this path, paste the complete contents and save. This is the only reader of import.meta.env. Nullish defaults support the Node smoke importer as well as Vite. The scope string excludes tasks:admin until an admin-only action asks for step-up.

**File: `src/config.ts`**
```typescript
const env = import.meta.env ?? {};
export const config = {
  apiBaseUrl: env.VITE_API_BASE_URL ?? 'http://localhost:8000',
  authority: env.VITE_OIDC_AUTHORITY ?? 'http://localhost:8180/realms/tasksteams',
  clientId: env.VITE_OIDC_CLIENT_ID ?? 'tasks-web',
  scopes: 'openid profile email tasks:read tasks:write',
};
```

Expected result: `src/config.ts` is saved exactly as shown. See the configuration reading guide below.

### Step 11. Create or replace `scripts/check-contract.mjs`
In code, create the file at this path, paste the complete contents and save. Hash the platform copy as bytes with SHA-256. A failure means recopy the approved baseline; never edit generated types or the contract to make a client compile.

**File: `scripts/check-contract.mjs`**
```javascript
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
const expected = 'f3a19841f551f01ef358582a1f5eba64b722d30f775201c1f5c6271d054f6ee4';
const actual = createHash('sha256').update(readFileSync('contract/openapi.yaml')).digest('hex');
if (actual !== expected) throw new Error('Contract copy differs from the platform baseline.');
console.log('contract: SHA-256 matches platform; 27 operations');
```

Expected result: `scripts/check-contract.mjs` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 12. Create or replace `scripts/smoke-auth.ts`
In code, create the file at this path, paste the complete contents and save. Use the library itself to generate the authorization URL, verify S256 and fetch the actual Keycloak login page. Check the user store is backed by memory. A fake User drives a library expiry timer locally: this proves the event can fire with automaticSilentRenew off, not that a browser refresh/sign-in has been verified.

**File: `scripts/smoke-auth.ts`**
```typescript
import { AccessTokenEvents, InMemoryWebStorage, OidcClient, User } from 'oidc-client-ts';
import { oidcSettings } from '../src/auth/oidc-config';
const { settings, memory } = oidcSettings('http://localhost:5173', new InMemoryWebStorage());
if (!(memory instanceof InMemoryWebStorage)) throw new Error('Expected memory user storage');
await settings.userStore!.set('smoke', 'memory-only');
if (memory.getItem('oidc.smoke') !== 'memory-only') throw new Error('Store was not backed by memory');
await settings.userStore!.remove('smoke');
const request = await new OidcClient(settings).createSigninRequest({
  redirect_uri: settings.redirect_uri, response_type: 'code', scope: settings.scope!,
});
const url = new URL(request.url);
if (url.searchParams.get('code_challenge_method') !== 'S256') throw new Error('PKCE missing');
const response = await fetch(url, { redirect: 'manual' });
if (response.status !== 200) throw new Error(`Login page ${response.status}`);
console.log('PKCE: S256; login page: 200; user store: memory');
// Demonstrate the library event without signing in or renewing a fake token.
const events = new AccessTokenEvents({ expiringNotificationTimeInSeconds: 1 });
let fired = false;
events.addAccessTokenExpiring(() => { fired = true; });
await events.load(new User({ access_token: 'not-a-real-token', token_type: 'Bearer',
  profile: { sub: 'smoke', iss: settings.authority, aud: settings.client_id, exp: 0, iat: 0 },
  expires_at: Math.floor(Date.now() / 1000) + 2 }));
await new Promise(resolve => setTimeout(resolve, 2100)); await events.unload();
if (!fired) throw new Error('Expiry event did not fire');
console.log('expiry event: fired without automaticSilentRenew');
```

Expected result: `scripts/smoke-auth.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 13. Create or replace `scripts/smoke.ts`
In code, create the file at this path, paste the complete contents and save. This is one smoke journey, not a suite: obtain a fake local tasks-smoke password-grant token, call the generated client and check small seed responses. Only the script uses that grant. The browser never has these credentials. Later phases add one paginated read and a temporary task conflict/replay journey; cleanup removes the whole disposable database.

**File: `scripts/smoke.ts`**
```typescript
import { authTransport, isApiUrl } from '../src/auth/auth-middleware';
import { bindTokenGate } from '../src/auth/token-gate';
import { ApiProblem, parseProblem } from '../src/api/problem';
import { versioned } from '../src/api/unwrap';
import { makeClient } from '../src/api/client';
import type { Schemas } from '../src/api/types';
import { unwrap } from '../src/api/unwrap';
const base = process.env.API_BASE_URL ?? 'http://localhost:8000';
const issuer = process.env.KEYCLOAK_URL ?? 'http://localhost:8180';
const tokenResponse = await fetch(`${issuer}/realms/tasksteams/protocol/openid-connect/token`, {
  method: 'POST', body: new URLSearchParams({ grant_type: 'password', client_id: 'tasks-smoke',
    username: 'alice', password: process.env.SMOKE_ALICE_PASSWORD ?? 'alice-local-fake',
    scope: 'openid tasks:read tasks:write tasks:admin' }),
});
if (!tokenResponse.ok) throw new Error(`Token endpoint ${tokenResponse.status}`);
const token = (await tokenResponse.json()).access_token as string;
bindTokenGate({ read: async () => ({ access_token: token }), refresh: async () => null, failed: async () => {} });
const transport = authTransport(base);
const boundary = authTransport(base, async input => {
  const request = new Request(input);
  if (request.headers.has('Authorization')) throw new Error('Token escaped API boundary');
  return new Response('not sent to a real host');
});
await boundary(new Request('https://not-an-api.invalid/', { headers: { Authorization: 'discard-me' } }));
if (isApiUrl('https://not-an-api.invalid/', base)) throw new Error('Foreign URL accepted');
console.log('foreign host: no bearer header (local transport stand-in)');
const api = makeClient(base, transport);
const health = unwrap(await api.GET('/health'));
const me = unwrap(await api.GET('/v1/me'));
if (health.status !== 'ok' || me.username !== 'alice' || !me.roles.includes('admin')) throw new Error('Unexpected seed');
console.log(`health: ${health.status}`);
console.log(`me: ${me.username} (${me.roles.join(', ')})`);
const missing = await makeClient(base).GET('/v1/me');
console.log(`without token: ${missing.response.status}`);
if (missing.response.status !== 401) throw new Error('Expected 401');

let cursor: string | undefined;
let count = 0;
do {
  const page: Schemas['TeamPage'] = unwrap(await api.GET('/v1/teams', { params: { query: { limit: 1, cursor } } }));
  count += page.items.length; cursor = page.page.nextCursor ?? undefined;
} while (cursor);
if (count !== 2) throw new Error('Unexpected team count');
console.log(`teams: ${count}`);
const team = unwrap(await api.GET('/v1/teams', { params: { query: { q: 'Platform' } } })).items[0]!;
const project = unwrap(await api.GET('/v1/teams/{teamId}/projects', { params: { path: { teamId: team.id } } })).items.find(p => p.key === 'PLAT')!;
count = 0; cursor = undefined;
do {
  const page: Schemas['TaskPage'] = unwrap(await api.GET('/v1/projects/{projectId}/tasks', { params: { path: { projectId: project.id }, query: { limit: 2, cursor } } }));
  count += page.items.length; cursor = page.page.nextCursor ?? undefined;
} while (cursor);
if (count < 3) throw new Error('Expected paginated tasks');
console.log(`tasks: ${count}; nextCursor: null`);

const key = crypto.randomUUID();
const options = { body: { title: 'React smoke task', description: '' }, params: { path: { projectId: project.id }, header: { 'Idempotency-Key': key } } };
const created = versioned(await api.POST('/v1/projects/{projectId}/tasks', options));
const replay = await api.POST('/v1/projects/{projectId}/tasks', options);
if (replay.response.headers.get('Idempotent-Replayed') !== 'true' || unwrap(replay).id !== created.value.id) throw new Error('Replay failed');
console.log('Idempotent-Replayed: true');
const taskId = created.value.id;
const changed = versioned(await api.PATCH('/v1/tasks/{taskId}', { body: { title: 'React smoke saved' }, params: { path: { taskId }, header: { 'If-Match': created.etag } } }));
const stale = await api.PATCH('/v1/tasks/{taskId}', { body: { title: 'Stale edit' }, params: { path: { taskId }, header: { 'If-Match': created.etag } } });
try { unwrap(stale); throw new Error('Expected 412'); }
catch (error) { if (!(error instanceof ApiProblem) || error.status !== 412) throw error; console.log(`412 ${error.type.split('/').pop()}`); console.log(error.message); }
const absent = await api.GET('/v1/tasks/{taskId}', { params: { path: { taskId: '00000000-0000-4000-8000-000000000000' } } });
const notFound = parseProblem(absent.response, absent.error);
if (notFound.status !== 404 || !notFound.traceId) throw new Error('Expected problem 404');
console.log(`404 ${notFound.type.split('/').pop()}`); console.log(notFound.message);
const invalid = await api.POST('/v1/projects/{projectId}/tasks', { body: { title: '', description: '' }, params: { path: { projectId: project.id } } });
const validation = parseProblem(invalid.response, invalid.error);
if (validation.status !== 422 || !validation.errors?.some(field => field.pointer === '/title')) throw new Error('Expected pointer /title');
console.log(`422 ${validation.type.split('/').pop()}; pointer: /title`); console.log(validation.message);
const canned = parseProblem(Response.json({ title: 'Too many requests', status: 429 }, { status: 429,
  headers: { 'Content-Type': 'application/problem+json', 'Retry-After': '1' } }), { title: 'Too many requests' });
if (canned.retryAfter !== 1) throw new Error('Retry-After parser failed');
console.log('canned 429 Retry-After: 1');
const cached = await api.GET('/v1/tasks/{taskId}', { params: { path: { taskId }, header: { 'If-None-Match': changed.etag } } });
if (cached.response.status !== 304 || versioned(cached, changed).etag !== changed.etag) throw new Error('Expected 304');
console.log('304 kept cached task');
const done = unwrap(await api.POST('/v1/tasks/{taskId}/complete', { params: { path: { taskId }, header: { 'If-Match': changed.etag } } }));
if (done.status !== 'done' || !done.completedAt) throw new Error('Complete failed');
console.log('complete: done; completedAt: present');
unwrap(await api.DELETE('/v1/tasks/{taskId}', { params: { path: { taskId } } }));

await import('./smoke-auth');
```

Expected result: `scripts/smoke.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 14. Create or replace `src/api/client.ts`
In code, create the file at this path, paste the complete contents and save. createClient<paths> checks literal paths, parameters and bodies. makeClient allows the Node smoke to reuse the same client with its own transport; the browser instance uses the token boundary. Nothing here imports React.

**File: `src/api/client.ts`**
```typescript
import createClient from 'openapi-fetch';
import type { paths } from './schema';
import { config } from '../config';
import { authTransport } from '../auth/auth-middleware';
export const makeClient = (baseUrl: string, transport: typeof fetch = fetch) =>
  createClient<paths>({ baseUrl, fetch: transport });
export const api = makeClient(config.apiBaseUrl, authTransport(config.apiBaseUrl));
```

Expected result: `src/api/client.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 15. Create or replace `src/api/notices.ts`
In code, create the file at this path, paste the complete contents and save. An EventTarget bridges framework-free transport notices to React. Keep the current immutable snapshot outside render so useSyncExternalStore can compare stable identities. No token, header or response body is logged.

**File: `src/api/notices.ts`**
```typescript
export const apiEvents = new EventTarget();
let notice = { message: '', until: 0 };
export function notify(message: string, seconds = 0) {
  notice = { message, until: seconds ? Date.now() + seconds * 1000 : 0 };
  apiEvents.dispatchEvent(new Event('notice'));
}
export const getNotice = () => notice;
```

Expected result: `src/api/notices.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 16. Create or replace `src/api/problem.ts`
In code, create the file at this path, paste the complete contents and save. Represent RFC 9457 fields as an Error subclass without rendering raw JSON or stacks. Accept structured fields only from application/problem+json, take status from the HTTP response, and read Retry-After with the case-insensitive Headers API. A validation pointer such as /title names the form field.

**File: `src/api/problem.ts`**
```typescript
export class ApiProblem extends Error {
  type = 'about:blank'; title = 'Request failed'; status = 0; detail?: string; instance?: string;
  traceId?: string; code?: string; errors?: { pointer: string; detail: string }[]; retryAfter?: number;
  constructor(values: Partial<ApiProblem>) {
    super(values.detail ?? values.title ?? 'Request failed'); Object.assign(this, values); this.name = 'ApiProblem';
  }
}
export function parseProblem(response: Response, body: unknown): ApiProblem {
  const fields = response.headers.get('Content-Type')?.includes('application/problem+json') && body && typeof body === 'object'
    ? body as Partial<ApiProblem> : {};
  const retry = Number(response.headers.get('Retry-After'));
  return new ApiProblem({ ...fields, status: response.status,
    title: fields.title ?? `Request failed (${response.status})`,
    retryAfter: response.headers.has('Retry-After') && Number.isFinite(retry) ? Math.max(0, retry) : undefined });
}
```

Expected result: `src/api/problem.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 17. Create or replace `src/api/types.ts`
In code, create the file at this path, paste the complete contents and save. Re-export aliases from generated components instead of maintaining handwritten entity copies. Versioned pairs a DTO with the exact quoted response ETag, not a reconstructed integer.

**File: `src/api/types.ts`**
```typescript
import type { components } from './schema';
export type Schemas = components['schemas'];
export type Team = Schemas['Team'];
export type Project = Schemas['Project'];
export type Task = Schemas['Task'];
export type Versioned<T> = { value: T; etag: string };
```

Expected result: `src/api/types.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 18. Create or replace `src/api/unwrap.ts`
In code, create the file at this path, paste the complete contents and save. openapi-fetch returns data, error and the native Response. Throwing a parsed failure makes Query and form code share one error channel. Check 304 before response.ok, because 304 has no new body. versioned preserves the exact ETag header value; a missing exposed ETag is a configuration error.

**File: `src/api/unwrap.ts`**
```typescript
import type { Versioned } from './types';
import { parseProblem } from './problem';
export function unwrap<T>(result: { data?: T; error?: unknown; response: Response }, cached?: T): T {
  if (result.response.status === 304 && cached !== undefined) return cached;
  if (!result.response.ok) throw parseProblem(result.response, result.error);
  return result.data as T;
}
export function versioned<T>(result: { data?: T; error?: unknown; response: Response }, cached?: Versioned<T>): Versioned<T> {
  if (result.response.status === 304 && cached) return cached;
  const value = unwrap(result); const etag = result.response.headers.get('ETag');
  if (!etag) throw new Error('The API did not expose ETag.');
  return { value, etag };
}
```

Expected result: `src/api/unwrap.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 19. Create or replace `src/auth/RequireAdmin.tsx`
In code, create the file at this path, paste the complete contents and save. Read roles and scopes from getMe, not decoded token claims. A member sees the access panel. An admin lacking tasks:admin makes one prompt=none step-up request through the existing SSO session. A transient marker prevents an endless redirect if the scope was not granted.

**File: `src/auth/RequireAdmin.tsx`**
```tsx
import { useEffect, useRef } from 'react';
import { Outlet, useLocation } from 'react-router';
import { useAuth } from 'react-oidc-context';
import { useMe } from '../hooks/me';
import { config } from '../config';
export function RequireAdmin() {
  const me = useMe(); const auth = useAuth(); const location = useLocation(); const started = useRef(false);
  const admin = me.data?.roles.includes('admin'); const scoped = me.data?.scopes.includes('tasks:admin');
  useEffect(() => {
    if (admin && scoped) sessionStorage.removeItem('ts.stepup');
    if (admin && !scoped && !started.current && !sessionStorage.getItem('ts.stepup')) {
      started.current = true; sessionStorage.setItem('ts.stepup', '1');
      void auth.signinRedirect({ scope: `${config.scopes} tasks:admin`, prompt: 'none',
        state: { returnTo: location.pathname + location.search } });
    }
  }, [admin, scoped, auth, location.pathname, location.search]);
  if (me.isPending) return <p role="status">Checking access</p>;
  if (me.error) return <p role="alert">{me.error.message}</p>;
  if (!admin || !scoped) return <section><h1>You do not have access</h1><p>Admin role and tasks:admin scope are required.</p></section>;
  return <Outlet />;
}
```

Expected result: `src/auth/RequireAdmin.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 20. Create or replace `src/auth/RequireAuth.tsx`
In code, create the file at this path, paste the complete contents and save. Wait while the OIDC library is working, then either render Outlet or replace the route with Login. Include the original path and query so sign-in can restore it. A guard improves navigation; it cannot grant API permissions.

**File: `src/auth/RequireAuth.tsx`**
```tsx
import { Navigate, Outlet, useLocation } from 'react-router';
import { useAuth } from 'react-oidc-context';
export function RequireAuth() {
  const auth = useAuth(); const location = useLocation();
  if (auth.isLoading || auth.activeNavigator) return <p role="status">Signing you in</p>;
  return auth.isAuthenticated ? <Outlet />
    : <Navigate replace to={`/login?returnUrl=${encodeURIComponent(location.pathname + location.search)}`} />;
}
```

Expected result: `src/auth/RequireAuth.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 21. Create or replace `src/auth/auth-middleware.ts`
In code, create the file at this path, paste the complete contents and save. Compare parsed origins and the configured API path boundary before attaching a bearer header; never use startsWith on the whole URL. Clone Request before fetch consumes its body. A 401 gets exactly one renew and retry, never recursive middleware. Phase 4 owns the single GET-only 429 retry here, so Query must not also retry 429.

**File: `src/auth/auth-middleware.ts`**
```typescript
import { apiEvents, notify } from '../api/notices';
import { endSession, getAccessToken, renew } from './token-gate';
export function isApiUrl(url: string, base: string) {
  const target = new URL(url); const allowed = new URL(base);
  const prefix = allowed.pathname.replace(/\/$/, '');
  return target.origin === allowed.origin && (target.pathname === prefix || target.pathname.startsWith(`${prefix}/`));
}
export function authTransport(base: string, transport: typeof fetch = fetch): typeof fetch {
  return async (input, init) => {
    const request = new Request(input, init);
    if (!isApiUrl(request.url, base)) {
      request.headers.delete('Authorization');
      return transport(request);
    }
    const token = await getAccessToken();
    if (token) request.headers.set('Authorization', `Bearer ${token}`);
    const retry = request.clone(); const rateRetry = request.clone();
    let response: Response;
    try { response = await transport(request); }
    catch (error) { apiEvents.dispatchEvent(new Event('network-error')); throw error; }
    if (response.status === 401) {
      try {
        retry.headers.set('Authorization', `Bearer ${await renew()}`);
        response = await transport(retry);
      } catch { await endSession(); return response; }
      if (response.status === 401) await endSession();
    }
    if (response.status === 429) {
      const seconds = Math.max(0, Number(response.headers.get('Retry-After')) || 1);
      notify('Too many requests', seconds);
      if (request.method === 'GET') {
        await new Promise(resolve => setTimeout(resolve, seconds * 1000));
        const current = await getAccessToken();
        if (current) rateRetry.headers.set('Authorization', `Bearer ${current}`);
        response = await transport(rateRetry);
      }
    } else if (request.url !== `${base}/health` && response.headers.get('RateLimit-Remaining') === '0') {
      notify('Request budget exhausted. Wait before your next action.');
    }
    return response;
  };
}
```

Expected result: `src/auth/auth-middleware.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 22. Create or replace `src/auth/oidc-config.ts`
In code, create the file at this path, paste the complete contents and save. Separate userStore (tokens in InMemoryWebStorage) from stateStore (transient PKCE verifier/state in sessionStorage). response_type code and disablePKCE false enable code plus S256. automaticSilentRenew and monitorSession stay off: no hidden iframe and no competing refresh loop. An expiry event 60 seconds before expiration feeds our shared renew gate.

**File: `src/auth/oidc-config.ts`**
```typescript
import { InMemoryWebStorage, WebStorageStateStore, type UserManagerSettings } from 'oidc-client-ts';
import { config } from '../config';
export function oidcSettings(origin: string, transient: Storage) {
  const memory = new InMemoryWebStorage();
  const settings: UserManagerSettings = {
    authority: config.authority, client_id: config.clientId,
    redirect_uri: `${origin}/auth/callback`, post_logout_redirect_uri: `${origin}/login`,
    response_type: 'code', scope: config.scopes, disablePKCE: false,
    automaticSilentRenew: false, monitorSession: false,
    accessTokenExpiringNotificationTimeInSeconds: 60,
    userStore: new WebStorageStateStore({ store: memory }),
    stateStore: new WebStorageStateStore({ store: transient }),
  };
  return { settings, memory };
}
```

Expected result: `src/auth/oidc-config.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 23. Create or replace `src/auth/safe-route.ts`
In code, create the file at this path, paste the complete contents and save. Reject absolute URLs, protocol-relative // URLs, backslashes and control characters. A return route must stay inside this origin; otherwise navigation falls back to /. This prevents turning the login callback into an open redirect.

**File: `src/auth/safe-route.ts`**
```typescript
export function safeRoute(value: unknown): string {
  return typeof value === 'string' && value.startsWith('/') && !value.startsWith('//')
    && !value.includes('\\') && !/[\r\n]/.test(value) ? value : '/';
}
```

Expected result: `src/auth/safe-route.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 24. Create or replace `src/auth/token-gate.ts`
In code, create the file at this path, paste the complete contents and save. Expose callbacks instead of importing React into the client. A module-level flight promise is shared by the expiry event and the 401 path, then cleared in finally. Refresh rotation makes this single-flight rule important: two simultaneous uses of one refresh token can revoke the session.

**File: `src/auth/token-gate.ts`**
```typescript
type UserToken = { access_token: string; expired?: boolean };
let read: () => Promise<UserToken | null> = async () => null;
let refresh: () => Promise<UserToken | null> = async () => null;
let failed: () => Promise<void> = async () => {};
let flight: Promise<string> | undefined;
export function bindTokenGate(callbacks: { read: typeof read; refresh: typeof refresh; failed: typeof failed }) {
  read = callbacks.read; refresh = callbacks.refresh; failed = callbacks.failed;
}
export async function renew(): Promise<string> {
  if (!flight) {
    flight = refresh().then(user => {
      if (!user || user.expired) throw new Error('Please sign in again.');
      return user.access_token;
    }).catch(async error => { await failed(); throw error; }).finally(() => { flight = undefined; });
  }
  return flight;
}
export async function getAccessToken() {
  const user = await read();
  return user?.expired ? renew() : user?.access_token;
}
export async function endSession() { await failed(); }
```

Expected result: `src/auth/token-gate.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 25. Create or replace `src/auth/user-manager.ts`
In code, create the file at this path, paste the complete contents and save. Create one UserManager outside the render tree. The library processes redirects; onSigninCallback keeps only a validated return route and replaces the history entry containing code and state. ts.hint is the non-secret value 1, not a token. Sign-out keeps id_token_hint only long enough to end the Keycloak session, clears memory and deletes hint flags.

**File: `src/auth/user-manager.ts`**
```typescript
import { UserManager, type User } from 'oidc-client-ts';
import { oidcSettings } from './oidc-config';
import { bindTokenGate, renew } from './token-gate';
import { safeRoute } from './safe-route';
export const manager = new UserManager(oidcSettings(window.location.origin, window.sessionStorage).settings);
export let callbackReturn = '/';
export function onSigninCallback(user?: User) {
  callbackReturn = safeRoute((user?.state as { returnTo?: string } | undefined)?.returnTo);
  localStorage.setItem('ts.hint', '1');
  history.replaceState({}, document.title, callbackReturn);
}
bindTokenGate({
  read: () => manager.getUser(), refresh: () => manager.signinSilent(),
  failed: async () => {
    await manager.removeUser(); localStorage.removeItem('ts.hint');
    const returnTo = safeRoute(location.pathname + location.search);
    history.replaceState({}, '', `/login?returnUrl=${encodeURIComponent(returnTo)}`);
    window.dispatchEvent(new PopStateEvent('popstate'));
  },
});
manager.events.addAccessTokenExpiring(() => { void renew().catch(() => {}); });
export async function signOut() {
  const user = await manager.getUser();
  await manager.removeUser(); localStorage.removeItem('ts.hint'); sessionStorage.removeItem('ts.stepup');
  await manager.signoutRedirect({ id_token_hint: user?.id_token });
}
```

Expected result: `src/auth/user-manager.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 26. Create or replace `src/core/connectivity.ts`
In code, create the file at this path, paste the complete contents and save. Subscribe to onlineManager with useSyncExternalStore rather than copying external state into an effect. Phase 4 also marks failed requests offline and offers a way to resume. Browser online means a network interface exists, not proof the API is healthy; use Try again after checking the connection.

**File: `src/core/connectivity.ts`**
```typescript
import { useSyncExternalStore } from 'react';
import { onlineManager } from '@tanstack/react-query';
import { apiEvents } from '../api/notices';
onlineManager.setEventListener(setOnline => {
  const online = () => setOnline(true); const offline = () => setOnline(false);
  window.addEventListener('online', online); window.addEventListener('offline', offline);
  apiEvents.addEventListener('network-error', offline);
  return () => {
    window.removeEventListener('online', online); window.removeEventListener('offline', offline);
    apiEvents.removeEventListener('network-error', offline);
  };
});
export function useOnline() {
  return useSyncExternalStore(onlineManager.subscribe.bind(onlineManager), () => onlineManager.isOnline(), () => true);
}
export function tryOnline() { onlineManager.setOnline(navigator.onLine); }
```

Expected result: `src/core/connectivity.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 27. Create or replace `src/core/toast.tsx`
In code, create the file at this path, paste the complete contents and save. Keep one polite success region mounted from boot. Context provides only the setter; server entities stay in Query. A status message does not steal focus or interrupt typing.

**File: `src/core/toast.tsx`**
```tsx
import { createContext, useContext, useState, type ReactNode } from 'react';
const ToastContext = createContext<(text: string) => void>(() => {});
export const useToast = () => useContext(ToastContext);
export function ToastProvider({ children }: { children: ReactNode }) {
  const [message, setMessage] = useState('');
  return <ToastContext value={setMessage}>{children}<p className="toast" role="status" aria-live="polite">{message}</p></ToastContext>;
}
```

Expected result: `src/core/toast.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 28. Create or replace `src/core/use-title-focus.ts`
In code, create the file at this path, paste the complete contents and save. After navigation set the document title and focus the h1, which has tabIndex=-1. Including the location key handles navigation between two objects on the same screen. The effect synchronizes with browser APIs, not duplicated business state.

**File: `src/core/use-title-focus.ts`**
```typescript
import { useLocation } from 'react-router';
import { useEffect } from 'react';
export function useTitleFocus(title: string) {
  const location = useLocation();
  useEffect(() => {
    document.title = `${title} | Tasks and Teams`;
    document.querySelector<HTMLHeadingElement>('h1')?.focus();
  }, [title, location.key]);
}
```

Expected result: `src/core/use-title-focus.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 29. Create or replace `src/hooks/action.ts`
In code, create the file at this path, paste the complete contents and save. Mutations never retry arbitrary writes. Success announces Saved and invalidates server-state queries. In phase 4 only a create carrying its original key may retry once after a TypeError network failure; the same variables preserve both body and Idempotency-Key.

**File: `src/hooks/action.ts`**
```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useToast } from '../core/toast';
export function useAction<T>(action: (variables: T) => Promise<unknown>) {
  const cache = useQueryClient(); const toast = useToast();
  return useMutation({ mutationFn: async (variables: T) => {
    try { return await action(variables); }
    catch (error) {
      // A create alone may retry once after a network failure, using the same body and key.
      if (error instanceof TypeError && variables && typeof variables === 'object' && 'key' in variables) return action(variables);
      throw error;
    }
  }, retry: false,
    onSuccess: async () => { toast('Saved.'); await cache.invalidateQueries(); },
  });
}
```

Expected result: `src/hooks/action.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 30. Create or replace `src/hooks/audit.ts`
In code, create the file at this path, paste the complete contents and save. The audit list uses its own key including filters. Cursor pagination is the same opaque protocol, but the operation needs both admin role and tasks:admin scope. from and to values are instants; the form converts local entries to UTC ISO strings.

**File: `src/hooks/audit.ts`**
```typescript
import { useInfiniteQuery } from '@tanstack/react-query';
import type { operations } from '../api/schema';
import { api } from '../api/client';
import { unwrap } from '../api/unwrap';
import { keys } from './keys';
export type AuditFilter = NonNullable<operations['listAuditLog']['parameters']['query']>;
export function useAudit(filters: AuditFilter) {
  return useInfiniteQuery({ queryKey: keys.list('audit', '', filters), initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/audit-log', { signal,
      params: { query: { ...filters, limit: 25, cursor: pageParam } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
```

Expected result: `src/hooks/audit.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 31. Create or replace `src/hooks/comments.ts`
In code, create the file at this path, paste the complete contents and save. Comments are oldest first. Load more appends pages, and creating invalidates the list so a new comment appears at the end. Deletes are a separate operation and the UI checks author/lead/admin before offering the control.

**File: `src/hooks/comments.ts`**
```typescript
import { useInfiniteQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { unwrap } from '../api/unwrap';
import { keys } from './keys';
import { useAction } from './action';
export function useComments(taskId: string) {
  return useInfiniteQuery({ queryKey: keys.list('comments', taskId, {}), initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/tasks/{taskId}/comments', { signal,
      params: { path: { taskId }, query: { limit: 25, cursor: pageParam } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
export function useCreateComment(taskId: string) {
  return useAction(async ({ body, key }: { body: string; key: string }) => unwrap(await api.POST('/v1/tasks/{taskId}/comments', {
    body: { body }, params: { path: { taskId }, header: { 'Idempotency-Key': key } },
  })));
}
export function useDeleteComment() {
  return useAction(async (commentId: string) => unwrap(await api.DELETE('/v1/comments/{commentId}', { params: { path: { commentId } } })));
}
```

Expected result: `src/hooks/comments.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 32. Create or replace `src/hooks/keys.ts`
In code, create the file at this path, paste the complete contents and save. All feature keys use one factory. Area, parent id and filters identify list caches; resource area plus id identifies a detail cache. A new filter object with different values changes the key and starts a fresh cursor sequence.

**File: `src/hooks/keys.ts`**
```typescript
export const keys = {
  list: (area: string, id: string, filters: object) => [area, id, filters] as const,
  entity: (area: string, id: string) => [area, id] as const,
};
```

Expected result: `src/hooks/keys.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 33. Create or replace `src/hooks/me.ts`
In code, create the file at this path, paste the complete contents and save. getMe is the source of display name, role, scope and team-role UI decisions. Query caches it under me; auth changes clear that cache. Authentication failure is handled at the transport boundary.

**File: `src/hooks/me.ts`**
```typescript
import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { unwrap } from '../api/unwrap';
export function useMe() {
  return useQuery({ queryKey: ['me'], queryFn: async () => unwrap(await api.GET('/v1/me')), retry: false });
}
```

Expected result: `src/hooks/me.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 34. Create or replace `src/hooks/projects.ts`
In code, create the file at this path, paste the complete contents and save. Read/list projects within their team, validate creates through generated DTOs, and read the current ETag before patching archive/name changes. Phase 4 snapshots project list pages for optimistic archive/name changes and rolls them back on any failure. A lead can also delete a disposable project with confirmation. archived undefined means all, false means active only. Never rely on If-None-Match for projects: the platform backlog restricts that optimisation to tasks.

**File: `src/hooks/projects.ts`**
```typescript
import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { unwrap, versioned } from '../api/unwrap';
import type { Project, Versioned, Schemas } from '../api/types';
import { keys } from './keys';
import { useAction } from './action';
export function useProjects(teamId: string, archived: boolean | undefined) {
  return useInfiniteQuery({ queryKey: keys.list('projects', teamId, { archived }), initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/teams/{teamId}/projects', { signal,
      params: { path: { teamId }, query: { limit: 25, cursor: pageParam, archived } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
export function useProject(projectId: string) {
  return useQuery({ queryKey: keys.entity('project', projectId), enabled: !!projectId,
    queryFn: async ({ signal }) => versioned(await api.GET('/v1/projects/{projectId}', { signal, params: { path: { projectId } } })),
  });
}
export function useCreateProject(teamId: string) {
  return useAction(async ({ body, key }: { body: Schemas['ProjectCreate']; key: string }) =>
    unwrap(await api.POST('/v1/teams/{teamId}/projects', { body, params: { path: { teamId }, header: { 'Idempotency-Key': key } } })));
}
export function useUpdateProject() {
  const cache = useQueryClient();
  return useMutation({
    mutationFn: async ({ projectId, body }: { projectId: string; body: Schemas['ProjectUpdate'] }) => {
      const current = versioned(await api.GET('/v1/projects/{projectId}', { params: { path: { projectId } } }));
      return versioned(await api.PATCH('/v1/projects/{projectId}', { body,
        params: { path: { projectId }, header: { 'If-Match': current.etag } } }));
    },
    onMutate: async ({ projectId, body }) => {
      await cache.cancelQueries({ queryKey: ['projects'] });
      const snapshots = cache.getQueriesData<{ pages: Schemas['ProjectPage'][]; pageParams: unknown[] }>({ queryKey: ['projects'] });
      for (const [key, data] of snapshots) if (data) cache.setQueryData(key, {
        ...data, pages: data.pages.map(page => ({ ...page, items: page.items.map(project => project.id === projectId ? { ...project, ...body } : project) })),
      });
      return snapshots;
    },
    onError: (_error, _variables, snapshots) => { snapshots?.forEach(([key, data]) => cache.setQueryData(key, data)); },
    onSuccess: (result: Versioned<Project>) => { cache.setQueryData(keys.entity('project', result.value.id), result); },
    onSettled: () => cache.invalidateQueries({ queryKey: ['projects'] }), retry: false,
  });
}
export function useDeleteProject() {
  return useAction(async (projectId: string) => unwrap(await api.DELETE('/v1/projects/{projectId}', { params: { path: { projectId } } })));
}
```

Expected result: `src/hooks/projects.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 35. Create or replace `src/hooks/tasks.ts`
In code, create the file at this path, paste the complete contents and save. Use separate infinite list and versioned detail keys. AbortSignal lets cancellation stop a query before optimistic writes. Filters are contract types. Create, edit, complete, reassign and delete call distinct operations. Phase 4 snapshots only the edited detail and invalidates lists, while successful response ETags replace the old header. Board moves use explicit select-and-submit, never drag-only.

**File: `src/hooks/tasks.ts`**
```typescript
import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type { operations } from '../api/schema';
import { api } from '../api/client';
import { unwrap, versioned } from '../api/unwrap';
import type { Task, Versioned, Schemas } from '../api/types';
import { keys } from './keys';
import { useAction } from './action';
export type TaskFilter = NonNullable<operations['listTasks']['parameters']['query']>;
export function useTasks(projectId: string, filters: TaskFilter) {
  return useInfiniteQuery({ queryKey: keys.list('tasks', projectId, filters), initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/projects/{projectId}/tasks', { signal,
      params: { path: { projectId }, query: { ...filters, limit: 25, cursor: pageParam } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
export function useTask(taskId: string) {
  const cache = useQueryClient(); const key = keys.entity('task', taskId);
  return useQuery({ queryKey: key, enabled: !!taskId, refetchOnWindowFocus: true,
    queryFn: async ({ signal }) => {
      const current = cache.getQueryData<Versioned<Task>>(key);
      return versioned(await api.GET('/v1/tasks/{taskId}', { signal, params: { path: { taskId },
        header: { 'If-None-Match': current?.etag } } }), current);
    },
  });
}
export function useCreateTask(projectId: string) {
  return useAction(async ({ body, key }: { body: Schemas['TaskCreate']; key: string }) =>
    unwrap(await api.POST('/v1/projects/{projectId}/tasks', { body, params: { path: { projectId }, header: { 'Idempotency-Key': key } } })));
}
export function useUpdateTask(taskId: string) {
  const cache = useQueryClient(); const key = keys.entity('task', taskId);
  return useMutation({
    mutationFn: async ({ body, etag }: { body: Schemas['TaskUpdate']; etag: string }) =>
      versioned(await api.PATCH('/v1/tasks/{taskId}', { body, params: { path: { taskId }, header: { 'If-Match': etag } } })),
    onMutate: async ({ body }) => {
      await cache.cancelQueries({ queryKey: key });
      const snapshot = cache.getQueryData<Versioned<Task>>(key);
      if (snapshot) cache.setQueryData(key, { ...snapshot, value: { ...snapshot.value, ...body } });
      return snapshot;
    },
    onError: (_error, _variables, snapshot) => { if (snapshot) cache.setQueryData(key, snapshot); },
    onSuccess: result => { cache.setQueryData(key, result); },
    onSettled: () => cache.invalidateQueries({ queryKey: ['tasks'] }),
    retry: false,
  });
}
export function useCompleteTask(taskId: string) {
  return useAction(async (etag: string) => versioned(await api.POST('/v1/tasks/{taskId}/complete', {
    params: { path: { taskId }, header: { 'If-Match': etag } },
  })));
}
export function useReassignTask(taskId: string) {
  return useAction(async ({ assigneeId, etag }: { assigneeId: string | null; etag: string }) =>
    versioned(await api.POST('/v1/tasks/{taskId}/reassign', { body: { assigneeId }, params: { path: { taskId }, header: { 'If-Match': etag } } })));
}
export function useDeleteTask(taskId: string) {
  return useAction(async (etag: string) => unwrap(await api.DELETE('/v1/tasks/{taskId}', {
    params: { path: { taskId }, header: { 'If-Match': etag } },
  })));
}

export function useMoveTask() {
  return useAction(async ({ taskId, status }: { taskId: string; status: Schemas['TaskStatus'] }) => {
    const current = versioned(await api.GET('/v1/tasks/{taskId}', { params: { path: { taskId } } }));
    return versioned(await api.PATCH('/v1/tasks/{taskId}', { body: { status }, params: { path: { taskId }, header: { 'If-Match': current.etag } } }));
  });
}
```

Expected result: `src/hooks/tasks.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 36. Create or replace `src/hooks/teams.ts`
In code, create the file at this path, paste the complete contents and save. List teams and members with limit=25; copy nextCursor unchanged. Permissions derive from me. Creates carry a caller-supplied key. Edits use a response ETag and, in phase 4, cancel/snapshot/optimistically update/roll back/replace. Membership writes are explicit operations, including role change; the server enforces the last-lead rule. Deleting a team requests tasks:admin on demand.

**File: `src/hooks/teams.ts`**
```typescript
import { useAuth } from 'react-oidc-context';
import { config } from '../config';
import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { unwrap, versioned } from '../api/unwrap';
import type { Schemas, Team, Versioned } from '../api/types';
import { keys } from './keys';
import { useAction } from './action';
import { useMe } from './me';
export function useCan(teamId: string) {
  const me = useMe();
  return { admin: !!me.data?.roles.includes('admin'), lead: !!me.data?.roles.includes('admin')
    || me.data?.teams.some(team => team.teamId === teamId && team.role === 'lead') === true };
}
export function useTeams(filters: { q?: string; sort?: '-createdAt' | 'createdAt' }) {
  return useInfiniteQuery({ queryKey: keys.list('teams', '', filters), initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/teams', { signal,
      params: { query: { ...filters, limit: 25, cursor: pageParam } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
export function useTeam(teamId: string) {
  return useQuery({ queryKey: keys.entity('team', teamId), enabled: !!teamId,
    queryFn: async ({ signal }) => versioned(await api.GET('/v1/teams/{teamId}', { signal, params: { path: { teamId } } })),
  });
}
export function useMembers(teamId: string) {
  return useInfiniteQuery({ queryKey: keys.list('members', teamId, {}), enabled: !!teamId, initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/teams/{teamId}/members', { signal,
      params: { path: { teamId }, query: { limit: 25, cursor: pageParam } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
export function useCreateTeam() {
  return useAction(async ({ body, key }: { body: Schemas['TeamCreate']; key: string }) =>
    unwrap(await api.POST('/v1/teams', { body, params: { header: { 'Idempotency-Key': key } } })));
}
export function useUpdateTeam(teamId: string) {
  const cache = useQueryClient(); const key = keys.entity('team', teamId);
  return useMutation({
    mutationFn: async ({ body, etag }: { body: Schemas['TeamUpdate']; etag: string }) =>
      versioned(await api.PATCH('/v1/teams/{teamId}', { body, params: { path: { teamId }, header: { 'If-Match': etag } } })),
    onMutate: async ({ body }) => {
      await cache.cancelQueries({ queryKey: key }); const snapshot = cache.getQueryData<Versioned<Team>>(key);
      if (snapshot) cache.setQueryData(key, { ...snapshot, value: { ...snapshot.value, ...body } });
      return snapshot;
    },
    onError: (_error, _variables, snapshot) => { if (snapshot) cache.setQueryData(key, snapshot); },
    onSuccess: result => { cache.setQueryData(key, result); },
    onSettled: () => cache.invalidateQueries({ queryKey: ['teams'] }), retry: false,
  });
}
export function useDeleteTeam() {
  const me = useMe(); const auth = useAuth();
  return useAction(async (teamId: string) => {
    if (!me.data?.scopes.includes('tasks:admin')) {
      await auth.signinRedirect({ scope: `${config.scopes} tasks:admin`, prompt: 'none',
        state: { returnTo: location.pathname + location.search } });
      return;
    }
    return unwrap(await api.DELETE('/v1/teams/{teamId}', { params: { path: { teamId } } }));
  });
}
export function usePutMember(teamId: string) {
  return useAction(async ({ userId, role }: { userId: string; role: Schemas['TeamRole'] }) =>
    unwrap(await api.PUT('/v1/teams/{teamId}/members/{userId}', { body: { role }, params: { path: { teamId, userId } } })));
}
export function useRemoveMember(teamId: string) {
  return useAction(async (userId: string) => unwrap(await api.DELETE('/v1/teams/{teamId}/members/{userId}', { params: { path: { teamId, userId } } })));
}
```

Expected result: `src/hooks/teams.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 37. Create or replace `src/main.tsx`
In code, create the file at this path, paste the complete contents and save. Create one QueryClient and one root. StrictMode deliberately repeats development lifecycle checks; callbacks and boot redirects must tolerate that. Providers make auth, server state and the toast setter available without passing them through every component. Clearing the cache on user change prevents another identity seeing a previous caller?s data.

**File: `src/main.tsx`**
```tsx
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from 'react-oidc-context';
import { RouterProvider } from 'react-router/dom';
import { manager, onSigninCallback } from './auth/user-manager';
import { router } from './router';
import { ToastProvider } from './core/toast';
import { ApiProblem } from './api/problem';
import './styles.css';
const queryClient = new QueryClient({ defaultOptions: { queries: { retry: (count, error) => count < 2 && (!(error instanceof ApiProblem) || error.status >= 500) }, mutations: { retry: false } } });
manager.events.addUserUnloaded(() => queryClient.clear());
manager.events.addUserLoaded(() => { queryClient.clear(); });
createRoot(document.getElementById('root')!).render(
  <StrictMode><AuthProvider userManager={manager} onSigninCallback={onSigninCallback}>
    <QueryClientProvider client={queryClient}><ToastProvider><RouterProvider router={router} /></ToastProvider></QueryClientProvider>
  </AuthProvider></StrictMode>,
);
```

Expected result: `src/main.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 38. Create or replace `src/pages/Audit.tsx`
In code, create the file at this path, paste the complete contents and save. Guard before mounting the audit query. Filters for entity type, actor and date range produce new cursor keys. Render escaped text, semantic table headers and locally formatted instants; wide tables scroll inside their own wrapper rather than the whole page.

**File: `src/pages/Audit.tsx`**
```tsx
import { useSearchParams } from 'react-router';
import { useAudit, type AuditFilter } from '../hooks/audit';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { Field } from '../shared/WriteForm';
import { LoadMore } from '../shared/LoadMore';
export function Component() {
  const [params, setParams] = useSearchParams();
  const filters: AuditFilter = { entityType: (params.get('entityType') || undefined) as AuditFilter['entityType'],
    actorId: params.get('actorId') || undefined, from: params.get('from') || undefined, to: params.get('to') || undefined };
  const audit = useAudit(filters);
  return <Page title="Audit log"><form onSubmit={event => {
    event.preventDefault(); const next = new URLSearchParams();
    new FormData(event.currentTarget).forEach((value, key) => {
      if (value) next.set(key, key === 'from' || key === 'to' ? new Date(String(value)).toISOString() : String(value));
    }); setParams(next);
  }}><label>Entity type<select name="entityType" defaultValue={filters.entityType ?? ''}><option value="">All</option>{['team','member','project','task','comment'].map(type => <option key={type}>{type}</option>)}</select></label>
    <Field name="actorId" label="Actor UUID" value={params.get('actorId') ?? ''} maxLength={36} />
    <Field name="from" label="From (local time)" type="datetime-local" /><Field name="to" label="To (local time)" type="datetime-local" /><button>Apply filters</button>
    </form><Banner error={audit.error} retry={() => audit.refetch()} />
    <div className="table-wrap"><table><caption>Audit entries</caption><thead><tr><th scope="col">When</th><th scope="col">Action</th><th scope="col">Entity</th><th scope="col">Actor</th></tr></thead>
      <tbody>{audit.data?.pages.flatMap(page => page.items).map(entry => <tr key={entry.id}>
        <td>{new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(entry.occurredAt))}</td>
        <td>{entry.action}</td><td>{entry.entityType} {entry.entityId}</td><td>{entry.actorId ?? 'System'}</td>
      </tr>)}</tbody></table></div><LoadMore query={audit} />
  </Page>;
}
```

Expected result: `src/pages/Audit.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 39. Create or replace `src/pages/Callback.tsx`
In code, create the file at this path, paste the complete contents and save. Show Signing you in while AuthProvider exchanges the code. Success navigates to the already-sanitized saved route. Failure removes the callback payload from history and offers Return to Login; never echo a token.

**File: `src/pages/Callback.tsx`**
```tsx
import { Page } from '../shared/Page';
import { useEffect } from 'react';
import { useAuth } from 'react-oidc-context';
import { Link, useNavigate } from 'react-router';
import { callbackReturn } from '../auth/user-manager';
export function Component() {
  const auth = useAuth(); const navigate = useNavigate();
  useEffect(() => {
    if (auth.isAuthenticated) void navigate(callbackReturn, { replace: true });
    if (auth.error) { localStorage.removeItem('ts.hint'); history.replaceState({}, '', '/auth/callback'); }
  }, [auth.isAuthenticated, auth.error, navigate]);
  return <Page title="Callback">{auth.error
    ? <><p role="alert">{auth.error.message}</p><Link to="/login">Return to Login</Link></>
    : <p role="status">Signing you in</p>}</Page>;
}
```

Expected result: `src/pages/Callback.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 40. Create or replace `src/pages/Dashboard.tsx`
In code, create the file at this path, paste the complete contents and save. Show caller, roles and scopes from me, memberships from me.teams, visible teams from listTeams and a health chip from getHealth. Separate query keys keep a public health failure from replacing authenticated user state.

**File: `src/pages/Dashboard.tsx`**
```tsx
import { Link } from 'react-router';
import { useQuery } from '@tanstack/react-query';
import { useMe } from '../hooks/me';
import { useTeams } from '../hooks/teams';
import { api } from '../api/client';
import { unwrap } from '../api/unwrap';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
export function Component() {
  const me = useMe(); const teams = useTeams({});
  const health = useQuery({ queryKey: ['health'], queryFn: async () => unwrap(await api.GET('/health')) });
  return <Page title="Dashboard"><Banner error={me.error || teams.error || health.error} retry={async () => { await Promise.all([me.refetch(), teams.refetch(), health.refetch()]); }} />
    <p>Hello, {me.data?.displayName}</p><p>Roles: {me.data?.roles.join(', ')}</p><p>Scopes: {me.data?.scopes.join(', ')}</p>
    <p role="status">API: {health.data?.status ?? 'checking'}</p>
    <h2>My teams</h2><ul>{me.data?.teams.map(team => <li key={team.teamId}>
      <Link to={`/teams/${team.teamId}`}>{team.name}</Link> ({team.role})</li>)}</ul>
    <p>Visible teams on the first page: {teams.data?.pages[0]?.items.length ?? 0}</p>
  </Page>;
}
```

Expected result: `src/pages/Dashboard.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 41. Create or replace `src/pages/Login.tsx`
In code, create the file at this path, paste the complete contents and save. Show a real Sign in button, not username/password fields. A ref prevents duplicate boot redirects. The optional ts.hint flag requests silent SSO re-entry after reload; an error clears it and stays visible. safeRoute validates both query and callback state.

**File: `src/pages/Login.tsx`**
```tsx
import { Icon } from '../shared/Icon';
import { Page } from '../shared/Page';
import { useEffect, useRef } from 'react';
import { useAuth } from 'react-oidc-context';
import { Link, Navigate, useSearchParams } from 'react-router';
import { safeRoute } from '../auth/safe-route';
export function Component() {
  const auth = useAuth(); const [params] = useSearchParams(); const started = useRef(false);
  const returnTo = safeRoute(params.get('returnUrl'));
  useEffect(() => {
    if (auth.error) { localStorage.removeItem('ts.hint'); history.replaceState({}, '', '/login'); }
    if (!auth.isLoading && !auth.isAuthenticated && !auth.error && !started.current && localStorage.getItem('ts.hint')) {
      started.current = true;
      void auth.signinRedirect({ prompt: 'none', state: { returnTo } });
    }
  }, [auth, returnTo]);
  if (auth.isAuthenticated) return <Navigate replace to={returnTo} />;
  return <Page title="Login"><p>Sign in with the Tasks and Teams Keycloak realm.</p>
    {auth.error && <p role="alert">{auth.error.message}</p>}
    <button disabled={auth.isLoading || !!auth.activeNavigator} onClick={() => {
      localStorage.removeItem('ts.hint'); void auth.signinRedirect({ state: { returnTo } });
    }}><Icon name="log-in" />Sign in</button><p><Link to="/">Home</Link></p>
  </Page>;
}
```

Expected result: `src/pages/Login.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 42. Create or replace `src/pages/NotFound.tsx`
In code, create the file at this path, paste the complete contents and save. Use neutral wording and a Home link. A missing page and an inaccessible API object should never turn into an existence oracle.

**File: `src/pages/NotFound.tsx`**
```tsx
import { Page } from '../shared/Page';
import { Link } from 'react-router';
export function Component() {
  return <Page title="Not found"><p>This page is not available.</p><Link to="/">Home</Link></Page>;
}
```

Expected result: `src/pages/NotFound.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 43. Create or replace `src/pages/Projects.tsx`
In code, create the file at this path, paste the complete contents and save. Show active or all projects from the query string. Validate key with [A-Z][A-Z0-9]{1,9} before sending; the browser supplies the whole-value pattern match. Archive/restore preserves the typed ETag workflow. The server still rejects a duplicate key with 409.

**File: `src/pages/Projects.tsx`**
```tsx
import { ConfirmDialog } from '../shared/ConfirmDialog';
import { Link, useParams, useSearchParams } from 'react-router';
import { useProjects, useCreateProject, useUpdateProject, useDeleteProject } from '../hooks/projects';
import { useCan } from '../hooks/teams';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { Field, WriteForm } from '../shared/WriteForm';
import { LoadMore } from '../shared/LoadMore';
export function Component() {
  const { teamId = '' } = useParams(); const [params, setParams] = useSearchParams(); const { lead } = useCan(teamId);
  const projects = useProjects(teamId, params.get('archived') === 'all' ? undefined : false);
  const create = useCreateProject(teamId); const update = useUpdateProject(); const remove = useDeleteProject();
  return <Page title="Projects"><label><input type="checkbox" checked={params.get('archived') === 'all'}
    onChange={event => setParams({ archived: event.target.checked ? 'all' : 'active' })} />Show archived</label>
    <Banner error={projects.error} retry={() => projects.refetch()} />
    <ul>{projects.data?.pages.flatMap(page => page.items).map(project => <li key={project.id}>
      <Link to={`/projects/${project.id}`}>{project.key}: {project.name}</Link> {project.archived && '(archived)'}
      {lead && <WriteForm label={project.archived ? 'Restore and save' : 'Archive and save'} submit={values => update.mutateAsync({ projectId: project.id, body: { archived: !project.archived, name: values.name! } })}>
        <Field name="name" label="Project name" value={project.name} required maxLength={120} />
      </WriteForm>}
      {lead && <ConfirmDialog label={`Delete ${project.key}`} action={() => remove.mutateAsync(project.id)} />}
    </li>)}</ul><LoadMore query={projects} />
    {lead && <WriteForm label="Create project" submit={(values, key) => create.mutateAsync({ body: { key: values.key!, name: values.name!, description: values.description! }, key })}>
      <Field name="key" label="Key (2-10 uppercase letters or digits, starts with a letter)" required pattern="[A-Z][A-Z0-9]{1,9}" maxLength={10} />
      <Field name="name" label="Name" required maxLength={120} /><Field name="description" label="Description" maxLength={2000} />
    </WriteForm>}
  </Page>;
}
```

Expected result: `src/pages/Projects.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 44. Create or replace `src/pages/TaskDetail.tsx`
In code, create the file at this path, paste the complete contents and save. Read the task before its project and team members; dependent queries are enabled only with real ids. Draft fields do not reset on background revalidation. Phase 4 keeps the draft?s baseline ETag, computes only changed fields, rolls back failures, and makes conflict choices explicit. Complete/reassign/delete and author/lead comment actions remain distinct writes.

**File: `src/pages/TaskDetail.tsx`**
```tsx
import { useRef, useState } from 'react';
import { ApiProblem } from '../api/problem';
import { ConflictDialog } from '../shared/ConflictDialog';
import { useToast } from '../core/toast';
import { Link, useNavigate, useParams } from 'react-router';
import { useTask, useUpdateTask, useCompleteTask, useReassignTask, useDeleteTask } from '../hooks/tasks';
import { useProject } from '../hooks/projects';
import { useCan, useMembers } from '../hooks/teams';
import { useComments, useCreateComment, useDeleteComment } from '../hooks/comments';
import { useMe } from '../hooks/me';
import type { Schemas } from '../api/types';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { WriteForm, Field } from '../shared/WriteForm';
import { ConfirmDialog } from '../shared/ConfirmDialog';
import { LoadMore } from '../shared/LoadMore';
import { Icon } from '../shared/Icon';
const statuses: Schemas['TaskStatus'][] = ['todo', 'in_progress', 'blocked', 'done', 'cancelled'];
const priorities: Schemas['TaskPriority'][] = ['low', 'medium', 'high', 'urgent'];
export function Component() {
  const { taskId = '' } = useParams(); const navigate = useNavigate(); const task = useTask(taskId);
  const project = useProject(task.data?.value.projectId ?? ''); const teamId = project.data?.value.teamId ?? '';
  const { lead } = useCan(teamId); const people = useMembers(teamId); const me = useMe();
  const update = useUpdateTask(taskId); const complete = useCompleteTask(taskId); const reassign = useReassignTask(taskId); const remove = useDeleteTask(taskId);
  const comments = useComments(taskId); const add = useCreateComment(taskId); const deleteComment = useDeleteComment();
  const toast = useToast(); const baseline = useRef(task.data); const baselineId = useRef(taskId);
  const [formKey, setFormKey] = useState(0);
  const [conflict, setConflict] = useState<{ body: Schemas['TaskUpdate']; server: NonNullable<typeof task.data> }>();
  if (baselineId.current !== taskId) { baseline.current = undefined; baselineId.current = taskId; }
  if (!baseline.current && task.data) baseline.current = task.data;
  async function save(body: Schemas['TaskUpdate'], etag: string) {
    try {
      baseline.current = await update.mutateAsync({ body, etag });
      setConflict(undefined); setFormKey(key => key + 1); toast('Task saved.');
    } catch (error) {
      if (error instanceof ApiProblem && error.status === 412) {
        const current = await task.refetch();
        if (current.data) setConflict({ body, server: current.data });
      }
      throw error;
    }
  }

  return <Page title="Task detail"><Banner error={task.error || project.error || comments.error || people.error} retry={async () => { await Promise.all([task.refetch(), project.refetch(), comments.refetch(), people.refetch()]); }} />
    {task.data && <><h2>{task.data.value.title}</h2><p>{task.data.value.description}</p><p>Status: {task.data.value.status}</p>
      <p>Completed: {task.data.value.completedAt ? new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(task.data.value.completedAt)) : 'Not completed'}</p>
      <Link to={`/projects/${task.data.value.projectId}`}>Tasks</Link>
      <WriteForm key={formKey} label="Save task" submit={async values => {
        const draft: Schemas['TaskUpdate'] = { title: values.title!, description: values.description!,
          status: values.status as Schemas['TaskStatus'], priority: values.priority as Schemas['TaskPriority'],
          assigneeId: values.assigneeId || null, dueDate: values.dueDate || null };
        const body = Object.fromEntries(Object.entries(draft).filter(([key, value]) =>
          baseline.current!.value[key as keyof typeof draft] !== value)) as Schemas['TaskUpdate'];
        if (!Object.keys(body).length) { toast('No changes.'); return; }
        await save(body, baseline.current!.etag);
      }}>
        <Field name="title" label="Title" required value={baseline.current!.value.title} />
        <Field name="description" label="Description" value={baseline.current!.value.description} maxLength={10000} />
        <label>Move to<select name="status" defaultValue={baseline.current!.value.status}>{statuses.map(status => <option key={status}>{status}</option>)}</select></label>
        <label>Priority<select name="priority" defaultValue={baseline.current!.value.priority}>{priorities.map(priority => <option key={priority}>{priority}</option>)}</select></label>
        <label>Assignee<select name="assigneeId" defaultValue={baseline.current!.value.assigneeId ?? ''}><option value="">Unassigned</option>{people.data?.pages.flatMap(page => page.items).map(person => <option key={person.userId} value={person.userId}>{person.displayName}</option>)}</select></label>
        <Field name="dueDate" label="Due date" type="date" value={baseline.current!.value.dueDate ?? ''} />
      </WriteForm>
      <WriteForm label="Complete task" submit={() => complete.mutateAsync(task.data!.etag)}><Icon name="check-circle" /></WriteForm>
      {lead && <><WriteForm label="Reassign task" submit={values => reassign.mutateAsync({ assigneeId: values.assigneeId || null, etag: task.data!.etag })}>
        <label>New assignee<select name="assigneeId"><option value="">Unassigned</option>{people.data?.pages.flatMap(page => page.items).map(person => <option key={person.userId} value={person.userId}>{person.displayName}</option>)}</select></label>
      </WriteForm><ConfirmDialog label="Delete task" action={async () => { await remove.mutateAsync(task.data!.etag); await navigate(`/projects/${task.data!.value.projectId}`); }} /></>}
    </>}
    {conflict && <ConflictDialog key={conflict.server.etag} server={conflict.server.value} local={conflict.body}
      useServer={() => { baseline.current = conflict.server; setConflict(undefined); setFormKey(key => key + 1); }}
      apply={async () => {
        const current = await task.refetch();
        if (!current.data || current.error) throw current.error ?? new Error('Could not read current task.');
        await save(conflict.body, current.data.etag);
      }} />}
    <p>Assignee choices</p><LoadMore query={people} />
    <h2>Comments</h2><ul>{comments.data?.pages.flatMap(page => page.items).map(comment => <li key={comment.id}>
      <p>{comment.author.displayName}: {comment.body}</p>{(lead || comment.author.id === me.data?.id) && <ConfirmDialog label={`Delete comment by ${comment.author.displayName}`} action={() => deleteComment.mutateAsync(comment.id)} />}
    </li>)}</ul><LoadMore query={comments} />
    <WriteForm label="Add comment" submit={(values, key) => add.mutateAsync({ body: values.body!, key })}><Field name="body" label="Comment" required maxLength={2000} /></WriteForm>
  </Page>;
}
```

Expected result: `src/pages/TaskDetail.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 45. Create or replace `src/pages/Tasks.tsx`
In code, create the file at this path, paste the complete contents and save. URLSearchParams keeps repeated status/priority filters and single dates, assignee, title and sort. Empty filters are omitted; default page size is 25. Board and list share one server query; the board has explicit Move to selects. Member choices also have Load more so teams over 25 members remain usable.

**File: `src/pages/Tasks.tsx`**
```tsx
import { Link, useParams, useSearchParams } from 'react-router';
import { useTasks, useCreateTask, useMoveTask, type TaskFilter } from '../hooks/tasks';
import { useProject } from '../hooks/projects';
import { useMembers } from '../hooks/teams';
import type { Schemas } from '../api/types';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { Field, WriteForm } from '../shared/WriteForm';
import { LoadMore } from '../shared/LoadMore';
import { Icon } from '../shared/Icon';
const statuses: Schemas['TaskStatus'][] = ['todo', 'in_progress', 'blocked', 'done', 'cancelled'];
const priorities: Schemas['TaskPriority'][] = ['low', 'medium', 'high', 'urgent'];
export function Component() {
  const { projectId = '' } = useParams(); const [params, setParams] = useSearchParams(); const project = useProject(projectId);
  const members = useMembers(project.data?.value.teamId ?? '');
  const filters: TaskFilter = { status: params.getAll('status').filter((v): v is Schemas['TaskStatus'] => statuses.includes(v as Schemas['TaskStatus'])),
    priority: params.getAll('priority').filter((v): v is Schemas['TaskPriority'] => priorities.includes(v as Schemas['TaskPriority'])),
    assigneeId: params.get('assigneeId') || undefined, dueAfter: params.get('dueAfter') || undefined, dueBefore: params.get('dueBefore') || undefined,
    q: params.get('q')?.trim() || undefined, sort: params.get('sort') === 'dueDate' ? 'dueDate' : params.get('sort') === 'createdAt' ? 'createdAt' : '-createdAt' };
  const tasks = useTasks(projectId, filters); const create = useCreateTask(projectId); const move = useMoveTask(); const board = params.get('view') === 'board';
  const people = members.data?.pages.flatMap(page => page.items) ?? [];
  return <Page title="Tasks"><Banner error={project.error || tasks.error || members.error} retry={async () => { await Promise.all([project.refetch(), tasks.refetch(), members.refetch()]); }} />
    <h2>{project.data?.value.name}</h2><details><summary><Icon name="filter" />Filters</summary>
      <form key={params.toString()} onSubmit={event => {
        event.preventDefault(); const next = new URLSearchParams();
        new FormData(event.currentTarget).forEach((value, key) => { if (String(value).trim()) next.append(key, String(value).trim()); });
        next.set('view', board ? 'board' : 'list'); setParams(next);
      }}><Field name="q" label="Title contains" value={params.get('q') ?? ''} maxLength={100} />
        <fieldset><legend>Status</legend>{statuses.map(status => <label key={status}><input type="checkbox" name="status" value={status} defaultChecked={params.getAll('status').includes(status)} />{status}</label>)}</fieldset>
        <fieldset><legend>Priority</legend>{priorities.map(priority => <label key={priority}><input type="checkbox" name="priority" value={priority} defaultChecked={params.getAll('priority').includes(priority)} />{priority}</label>)}</fieldset>
        <label>Assignee<select name="assigneeId" defaultValue={params.get('assigneeId') ?? ''}><option value="">Anyone</option>{people.map(person => <option key={person.userId} value={person.userId}>{person.displayName}</option>)}</select></label>
        <Field name="dueAfter" label="Due from" type="date" value={params.get('dueAfter') ?? ''} />
        <Field name="dueBefore" label="Due through" type="date" value={params.get('dueBefore') ?? ''} />
        <label>Sort<select name="sort" defaultValue={filters.sort}><option value="-createdAt">Newest</option><option value="createdAt">Oldest</option><option value="dueDate">Due date</option></select></label><button>Apply filters</button>
      </form>
    </details><button onClick={() => { const next = new URLSearchParams(params); next.set('view', board ? 'list' : 'board'); setParams(next); }}>
      <Icon name={board ? 'list' : 'columns'} />{board ? 'List view' : 'Board view'}</button>
    <div className={board ? 'board' : 'task-list'}>{(board ? statuses : ['All']).map(status => <section key={status}>
      {board && <h2>{status}</h2>}<ul>{tasks.data?.pages.flatMap(page => page.items).filter(task => !board || task.status === status).map(task => <li key={task.id}>
        <Link to={`/tasks/${task.id}`}>{task.title}</Link> ({task.status}, {task.priority})
        {board && <WriteForm label={`Move ${task.title}`} submit={values => move.mutateAsync({ taskId: task.id, status: values.status as Schemas['TaskStatus'] })}>
          <label>Move to<select name="status" defaultValue={task.status}>{statuses.map(value => <option key={value}>{value}</option>)}</select></label>
        </WriteForm>}
        {task.dueDate && <span><Icon name="calendar-days" />{task.dueDate}</span>}
      </li>)}</ul></section>)}</div><LoadMore query={tasks} />
    <p>Assignee choices</p><LoadMore query={members} />
    {!project.data?.value.archived && <WriteForm label="Create task" submit={(values, key) => create.mutateAsync({ body: {
      title: values.title!, description: values.description!, priority: values.priority as Schemas['TaskPriority'],
      dueDate: values.dueDate || null, assigneeId: values.assigneeId || null,
    }, key })}><Field name="title" label="Title" required /><Field name="description" label="Description" maxLength={10000} />
      <label>Priority<select name="priority" defaultValue="medium">{priorities.map(priority => <option key={priority}>{priority}</option>)}</select></label>
      <label>Assignee<select name="assigneeId"><option value="">Unassigned</option>{people.map(person => <option key={person.userId} value={person.userId}>{person.displayName}</option>)}</select></label>
      <Field name="dueDate" label="Due date" type="date" />
    </WriteForm>}
  </Page>;
}
```

Expected result: `src/pages/Tasks.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 46. Create or replace `src/pages/TeamDetail.tsx`
In code, create the file at this path, paste the complete contents and save. Read the versioned team and paged members independently. A lead/admin may edit fields and use PUT member to add or change roles; removing the last lead produces the server rule error. Members see the same data without lead controls. The Projects link keeps the parent team id in the route.

**File: `src/pages/TeamDetail.tsx`**
```tsx
import { Link, useParams } from 'react-router';
import { useCan, useTeam, useMembers, useUpdateTeam, usePutMember, useRemoveMember } from '../hooks/teams';
import type { Schemas } from '../api/types';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { WriteForm, Field } from '../shared/WriteForm';
import { ConfirmDialog } from '../shared/ConfirmDialog';
import { LoadMore } from '../shared/LoadMore';
export function Component() {
  const { teamId = '' } = useParams(); const team = useTeam(teamId); const members = useMembers(teamId);
  const { lead } = useCan(teamId); const update = useUpdateTeam(teamId); const put = usePutMember(teamId); const remove = useRemoveMember(teamId);
  return <Page title="Team detail"><Banner error={team.error || members.error} retry={async () => { await Promise.all([team.refetch(), members.refetch()]); }} />
    {team.data && <><h2>{team.data.value.name}</h2><p>{team.data.value.description}</p><Link to={`/teams/${teamId}/projects`}>Projects</Link>
      {lead && <WriteForm label="Save team" submit={values => update.mutateAsync({ body: { name: values.name!, description: values.description! }, etag: team.data!.etag })}>
        <Field name="name" label="Name" value={team.data.value.name} required maxLength={80} />
        <Field name="description" label="Description" value={team.data.value.description} maxLength={500} />
      </WriteForm>}</>}
    <details open><summary>Members tab</summary><ul>{members.data?.pages.flatMap(page => page.items).map(member => <li key={member.userId}>
      {member.displayName} ({member.role}){lead && <>
        <WriteForm label={`Change role for ${member.displayName}`} submit={values => put.mutateAsync({ userId: member.userId, role: values.role as Schemas['TeamRole'] })}>
          <label>Role<select name="role" defaultValue={member.role}><option>member</option><option>lead</option></select></label></WriteForm>
        <ConfirmDialog label={`Remove ${member.displayName}`} action={() => remove.mutateAsync(member.userId)} />
      </>}</li>)}</ul><LoadMore query={members} />
      {lead && <WriteForm label="Add member" submit={values => put.mutateAsync({ userId: values.userId!, role: values.role as Schemas['TeamRole'] })}>
        <Field name="userId" label="Keycloak user UUID" required pattern="[0-9a-fA-F-]{36}" maxLength={36} />
        <label>Role<select name="role"><option>member</option><option>lead</option></select></label>
      </WriteForm>}
    </details>
  </Page>;
}
```

Expected result: `src/pages/TeamDetail.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 47. Create or replace `src/pages/Teams.tsx`
In code, create the file at this path, paste the complete contents and save. Search and sort submit into the URL; browser Back remounts the matching filter form. Render links to Team detail, opaque Load more, admin create, and confirmed admin delete. Create names are limited to the contract maximum.

**File: `src/pages/Teams.tsx`**
```tsx
import { Link, useSearchParams } from 'react-router';
import { useCan, useTeams, useCreateTeam, useDeleteTeam } from '../hooks/teams';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { Field, WriteForm } from '../shared/WriteForm';
import { ConfirmDialog } from '../shared/ConfirmDialog';
import { LoadMore } from '../shared/LoadMore';
import { Icon } from '../shared/Icon';
export function Component() {
  const [params, setParams] = useSearchParams(); const { admin } = useCan('');
  const teams = useTeams({ q: params.get('q')?.trim() || undefined, sort: params.get('sort') === 'createdAt' ? 'createdAt' : '-createdAt' });
  const create = useCreateTeam(); const remove = useDeleteTeam();
  return <Page title="Teams"><form key={params.toString()} onSubmit={event => {
    event.preventDefault(); const data = new FormData(event.currentTarget); setParams({ q: String(data.get('q')).trim(), sort: String(data.get('sort')) });
  }}><label><Icon name="search" />Search<input name="q" defaultValue={params.get('q') ?? ''} maxLength={100} /></label>
    <label>Sort<select name="sort" defaultValue={params.get('sort') ?? '-createdAt'}><option value="-createdAt">Newest</option><option value="createdAt">Oldest</option></select></label>
    <button>Search</button></form><Banner error={teams.error} retry={() => teams.refetch()} />
    <ul>{teams.data?.pages.flatMap(page => page.items).map(team => <li key={team.id}>
      <Link to={`/teams/${team.id}`}>{team.name}</Link> ({team.memberCount} members)
      {admin && <ConfirmDialog label={`Delete ${team.name}`} action={() => remove.mutateAsync(team.id)} />}</li>)}</ul>
    <LoadMore query={teams} />{admin && <WriteForm label="Create team" submit={(values, key) => create.mutateAsync({ body: { name: values.name!, description: values.description! }, key })}>
      <Field name="name" label="Team name" required maxLength={80} /><Field name="description" label="Description" maxLength={500} />
    </WriteForm>}
  </Page>;
}
```

Expected result: `src/pages/Teams.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 48. Create or replace `src/router.tsx`
In code, create the file at this path, paste the complete contents and save. Create the data router once outside React state. Layout routes put guards around their children. lazy imports return named Component exports, so screens are split into separate chunks. The shell supplies landmarks and the first-tab-stop skip link; API permission checks remain authoritative.

**File: `src/router.tsx`**
```tsx
import { Notice } from './shared/Notice';
import { createBrowserRouter, Link, Outlet } from 'react-router';
import { useAuth } from 'react-oidc-context';
import { RequireAuth } from './auth/RequireAuth';
import { RequireAdmin } from './auth/RequireAdmin';
import { signOut } from './auth/user-manager';
import { useMe } from './hooks/me';
import { Icon } from './shared/Icon';
import { useOnline, tryOnline } from './core/connectivity';
function UserMenu() {
  const me = useMe();
  return <><Link to="/teams"><Icon name="users" />Teams</Link>
    {me.data?.roles.includes('admin') && <Link to="/admin/audit">Audit log</Link>}
    <details><summary>{me.data?.displayName ?? 'User menu'}</summary>
      <button onClick={() => void signOut()}><Icon name="log-out" />Sign out</button></details></>;
}
function Shell() {
  const auth = useAuth(); const online = useOnline();
  return <><a className="skip" href="#content">Skip to content</a>
    <header><nav aria-label="Main"><Link to="/">Dashboard</Link>{auth.isAuthenticated ? <UserMenu /> : <Link to="/login">Login</Link>}</nav></header>
    {!online && <p role="alert"><Icon name="cloud-off" />You are offline. Writes are disabled. <button onClick={tryOnline}>Try again</button></p>}
    <Notice /><main id="content" tabIndex={-1}><Outlet /></main></>;
}
export const router = createBrowserRouter([
  { element: <Shell />, children: [
    { path: '/login', lazy: () => import('./pages/Login') },
    { path: '/auth/callback', lazy: () => import('./pages/Callback') },
    { element: <RequireAuth />, children: [
      { index: true, lazy: () => import('./pages/Dashboard') },
      { path: '/teams', lazy: () => import('./pages/Teams') },
      { path: '/teams/:teamId', lazy: () => import('./pages/TeamDetail') },
      { path: '/teams/:teamId/projects', lazy: () => import('./pages/Projects') },
      { path: '/projects/:projectId', lazy: () => import('./pages/Tasks') },
      { path: '/tasks/:taskId', lazy: () => import('./pages/TaskDetail') },
      { element: <RequireAdmin />, children: [{ path: '/admin/audit', lazy: () => import('./pages/Audit') }] },
    ] },
    { path: '*', lazy: () => import('./pages/NotFound') },
  ] },
]);
```

Expected result: `src/router.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 49. Create or replace `src/shared/Banner.tsx`
In code, create the file at this path, paste the complete contents and save. Every failed request has a visible route back. Phase 4 distinguishes 403 access denied from 404 not found without revealing invisible objects; shows support trace text and last_lead guidance; and offers retry only when it can help.

**File: `src/shared/Banner.tsx`**
```tsx
import { Link } from 'react-router';
import { ApiProblem } from '../api/problem';
import { tryOnline } from '../core/connectivity';
import { Icon } from './Icon';
export function Banner({ error, retry }: { error: unknown; retry?: () => unknown }) {
  if (!error) return null;
  const problem = error instanceof ApiProblem ? error : undefined;
  const terminal = problem?.status === 403 || problem?.status === 404;
  return <section role="alert"><Icon name="alert-triangle" />
    {terminal && <h2>{problem?.status === 403 ? 'You do not have access' : 'Not found'}</h2>}
    <p>{error instanceof Error ? error.message : 'Request failed.'}</p>
    {problem?.traceId && <p>Support trace: {problem.traceId}</p>}
    {problem?.code === 'last_lead' && <p>Assign another lead before removing or demoting the last lead.</p>}
    {retry && !terminal && <button onClick={() => { tryOnline(); void retry(); }}><Icon name="refresh-cw" />Try again</button>}
    <Link to="/">Home</Link>
  </section>;
}
```

Expected result: `src/shared/Banner.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 50. Create or replace `src/shared/ConfirmDialog.tsx`
In code, create the file at this path, paste the complete contents and save. A native modal dialog supplies keyboard containment and Escape. Focus starts on Cancel, the safe action. The button that opened the dialog regains focus when it closes; a failed action remains visible and does not dismiss the dialog.

**File: `src/shared/ConfirmDialog.tsx`**
```tsx
import { useRef, useState } from 'react';
import { useOnline } from '../core/connectivity';
import { Icon } from './Icon';
export function ConfirmDialog({ label, action }: { label: string; action: () => Promise<unknown> }) {
  const dialog = useRef<HTMLDialogElement>(null); const cancel = useRef<HTMLButtonElement>(null);
  const online = useOnline(); const [pending, setPending] = useState(false); const [error, setError] = useState('');
  return <><button disabled={!online || pending} onClick={() => { dialog.current?.showModal(); cancel.current?.focus(); }}>{label}</button>
    <dialog ref={dialog} aria-label={label}><p>{label}? This cannot be undone.</p><p role="alert">{error}</p>
      <button ref={cancel} onClick={() => dialog.current?.close()}><Icon name="x" />Cancel</button>
      <button disabled={!online || pending} onClick={async () => {
        setPending(true); setError('');
        try { await action(); dialog.current?.close(); } catch (failure) { setError(failure instanceof Error ? failure.message : 'Request failed.'); }
        finally { setPending(false); }
      }}>Confirm</button>
    </dialog></>;
}
```

Expected result: `src/shared/ConfirmDialog.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 51. Create or replace `src/shared/ConflictDialog.tsx`
In code, create the file at this path, paste the complete contents and save. Keep the draft outside the dialog. Show server values beside only the locally changed fields. Use server discards the draft intentionally; Apply reads again immediately before saving with the new ETag. Another 412 is still possible and reopens the decision rather than silently overwriting.

**File: `src/shared/ConflictDialog.tsx`**
```tsx
import { useEffect, useRef, useState } from 'react';
import type { Task, Schemas } from '../api/types';
import { useOnline } from '../core/connectivity';
import { Icon } from './Icon';
export function ConflictDialog({ server, local, useServer, apply }: {
  server: Task; local: Schemas['TaskUpdate']; useServer: () => void; apply: () => Promise<void>;
}) {
  const ref = useRef<HTMLDialogElement>(null); const online = useOnline(); const [error, setError] = useState(''); const [pending, setPending] = useState(false);
  useEffect(() => { const dialog = ref.current!; dialog.showModal(); return () => dialog.close(); }, []);
  return <dialog ref={ref} aria-labelledby="conflict-title"><h2 id="conflict-title"><Icon name="alert-triangle" />This task changed</h2>
    <p>Your draft is kept. Escape closes the dialog; submitting the draft again will reopen it if still stale.</p>
    <table><caption>Server and your changed fields</caption><thead><tr><th scope="col">Field</th><th scope="col">Server</th><th scope="col">Mine</th></tr></thead>
      <tbody>{Object.entries(local).map(([key, value]) => <tr key={key}><th scope="row">{key}</th>
        <td>{String(server[key as keyof Task] ?? '')}</td><td>{String(value ?? '')}</td></tr>)}</tbody></table>
    <p role="alert">{error}</p><button autoFocus onClick={useServer}>Use the server version</button>
    <button disabled={!online || pending} onClick={async () => {
      setPending(true); setError(''); try { await apply(); }
      catch (failure) { setError(failure instanceof Error ? failure.message : 'Could not apply.'); }
      finally { setPending(false); }
    }}>Apply my changes on top</button>
  </dialog>;
}
```

Expected result: `src/shared/ConflictDialog.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 52. Create or replace `src/shared/Icon.tsx`
In code, create the file at this path, paste the complete contents and save. A finite icon-name union selects a CSS mask class. The span is decorative, aria-hidden; the adjacent text labels the control. There are no inline style props, remote images or outside art.

**File: `src/shared/Icon.tsx`**
```tsx
export type IconName = 'search' | 'filter' | 'plus' | 'x' | 'check-circle' | 'alert-triangle' | 'list' | 'columns'
  | 'log-in' | 'log-out' | 'refresh-cw' | 'users' | 'cloud-off' | 'calendar-days';
export function Icon({ name }: { name: IconName }) {
  return <span className={`icon icon-${name}`} aria-hidden="true" />;
}
```

Expected result: `src/shared/Icon.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 53. Create or replace `src/shared/LoadMore.tsx`
In code, create the file at this path, paste the complete contents and save. Disable loading at the final page or while a page is pending. nextCursor null becomes undefined in getNextPageParam, which tells Query there is no next page. Cursor values are never decoded.

**File: `src/shared/LoadMore.tsx`**
```tsx
export function LoadMore({ query }: { query: { hasNextPage: boolean; isFetchingNextPage: boolean; fetchNextPage: () => Promise<unknown> } }) {
  return <button disabled={!query.hasNextPage || query.isFetchingNextPage} onClick={() => void query.fetchNextPage()}>
    {query.isFetchingNextPage ? 'Loading' : query.hasNextPage ? 'Load more' : 'End of list'}
  </button>;
}
```

Expected result: `src/shared/LoadMore.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 54. Create or replace `src/shared/Notice.tsx`
In code, create the file at this path, paste the complete contents and save. Subscribe to the transport notice and compute a visible countdown from its deadline. Only a GET will be retried automatically; writes stay manual. Timer cleanup is important under StrictMode.

**File: `src/shared/Notice.tsx`**
```tsx
import { useEffect, useState, useSyncExternalStore } from 'react';
import { apiEvents, getNotice } from '../api/notices';
export function Notice() {
  const notice = useSyncExternalStore(listener => {
    apiEvents.addEventListener('notice', listener); return () => apiEvents.removeEventListener('notice', listener);
  }, getNotice);
  const [now, setNow] = useState(Date.now());
  useEffect(() => { const id = setInterval(() => setNow(Date.now()), 1000); return () => clearInterval(id); }, []);
  const seconds = Math.max(0, Math.ceil((notice.until - now) / 1000));
  return <p role="status">{notice.message}{seconds > 0 ? `, retrying GET in ${seconds} s; writes need a manual retry` : ''}</p>;
}
```

Expected result: `src/shared/Notice.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 55. Create or replace `src/shared/Page.tsx`
In code, create the file at this path, paste the complete contents and save. Use one section and a single h1 per route, then nest content headings below it. The shared hook owns document title and route-change focus. This makes landmark and heading behaviour consistent across screens.

**File: `src/shared/Page.tsx`**
```tsx
import type { ReactNode } from 'react';
import { useTitleFocus } from '../core/use-title-focus';
export function Page({ title, children }: { title: string; children: ReactNode }) {
  useTitleFocus(title);
  return <section><h1 tabIndex={-1}>{title}</h1>{children}</section>;
}
```

Expected result: `src/shared/Page.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 56. Create or replace `src/shared/WriteForm.tsx`
In code, create the file at this path, paste the complete contents and save. Native constraints run before onSubmit. FormData reads named fields; keep entered values mounted on failure. A UUID belongs to a submit attempt, not a render: an unchanged failed attempt reuses the key, a successful submit clears it. Phase 4 focuses the summary and links invalid fields to pointer messages. Offline and pending writes are disabled.

**File: `src/shared/WriteForm.tsx`**
```tsx
import { ApiProblem } from '../api/problem';
import { useId, useRef, useState, type ReactNode } from 'react';
import { useOnline } from '../core/connectivity';
import { Icon } from './Icon';
export function Field({ name, label, value = '', required = false, maxLength = 200, type = 'text', pattern }:
  { name: string; label: string; value?: string; required?: boolean; maxLength?: number; type?: string; pattern?: string }) {
  return <label>{label}<input name={name} defaultValue={value} required={required} maxLength={maxLength} type={type} pattern={pattern} /></label>;
}
export function WriteForm({ label, children, submit }: {
  label: string; children: ReactNode; submit: (values: Record<string, string>, key: string) => Promise<unknown>;
}) {
  const summaryId = useId();
  const online = useOnline(); const [pending, setPending] = useState(false); const [error, setError] = useState('');
  const summary = useRef<HTMLParagraphElement>(null); const attempt = useRef({ body: '', key: '' });
  return <form onSubmit={async event => {
    event.preventDefault(); if (!online || pending) return;
    const form = event.currentTarget;
    form.querySelectorAll('[aria-invalid]').forEach(input => { input.removeAttribute('aria-invalid'); input.removeAttribute('aria-describedby'); });
    const values = Object.fromEntries(new FormData(form)) as Record<string, string>;
    const body = JSON.stringify(values);
    if (attempt.current.body !== body || !attempt.current.key) attempt.current = { body, key: crypto.randomUUID() };
    setPending(true); setError('');
    try { await submit(values, attempt.current.key); attempt.current.key = ''; }
    catch (failure) {
      const message = failure instanceof Error ? failure.message : 'Request failed.';
      const fields = failure instanceof ApiProblem ? failure.errors?.map(field => `${field.pointer}: ${field.detail}`).join('; ') : '';
      setError(`${message}${fields ? ` ${fields}` : ''}${failure instanceof ApiProblem && failure.traceId ? ` Support trace: ${failure.traceId}` : ''}`);
      if (failure instanceof ApiProblem) failure.errors?.forEach(field => {
        const name = field.pointer.replace(/^\//, '').split('/')[0]!;
        const input = form.elements.namedItem(name);
        if (input instanceof HTMLElement) {
          input.setAttribute('aria-invalid', 'true'); input.setAttribute('aria-describedby', summaryId);
        }
      });
      requestAnimationFrame(() => summary.current?.focus());
    }
    finally { setPending(false); }
  }}><p id={summaryId} ref={summary} tabIndex={-1} role="alert">{error}</p>{children}
    <button disabled={!online || pending}><Icon name="plus" />{pending ? 'Saving' : label}</button>
  </form>;
}
```

Expected result: `src/shared/WriteForm.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 57. Create or replace `src/styles.css`
In code, create the file at this path, paste the complete contents and save. Use class-based styles, visible 2px focus rings, sufficiently large targets, wrapping navigation and a responsive board. The skip link is visually hidden only until focused. Light/dark palettes and CSS icon masks follow currentColor; forced-colors retains icon visibility. No inline styles are needed by production CSP.

**File: `src/styles.css`**
```css
:root { font-family: system-ui, sans-serif; color: #17212b; background: #fff; }
body { margin: 0; }
main { max-width: 65rem; margin: auto; padding: 1rem; }
button, input, select, textarea { font: inherit; padding: .5rem; }
button, a { min-height: 24px; min-width: 24px; }
:focus-visible { outline: 2px solid #0759aa; outline-offset: 3px; }

html { scroll-padding-top: 6rem; }
header { position: sticky; top: 0; padding: 1rem; background: #e7f0fa; }
nav { display: flex; flex-wrap: wrap; gap: 1rem; align-items: center; }
a { color: #0759aa; display: inline-block; padding: .25rem; }
.skip { position: absolute; left: -10000px; }
.skip:focus { position: fixed; left: 0; top: 0; z-index: 10; background: white; }
label { display: block; margin: .5rem 0; }
input, textarea, select { max-width: 100%; box-sizing: border-box; }
label input:not([type=checkbox]), label select { display: block; }
form { margin: 1rem 0; padding: .75rem; border: 1px solid #66788a; }
li { margin: .75rem 0; overflow-wrap: anywhere; }
.board { display: grid; grid-template-columns: repeat(auto-fit, minmax(14rem, 1fr)); gap: 1rem; }
.board section { background: #e7f0fa; padding: .5rem; }
.table-wrap { overflow-x: auto; }
th, td { text-align: left; padding: .5rem; }
.toast { padding: .5rem 1rem; min-height: 1.5rem; }
dialog { max-width: min(90vw, 45rem); border: 2px solid #0759aa; }
.icon { display: inline-block; width: 1.25rem; height: 1.25rem; background-color: currentColor; vertical-align: middle; margin-right: .3rem; }
.icon-search { mask: url(/icons/ui/search.svg) center / contain no-repeat; }
.icon-filter { mask: url(/icons/ui/filter.svg) center / contain no-repeat; }
.icon-plus { mask: url(/icons/ui/plus.svg) center / contain no-repeat; }
.icon-x { mask: url(/icons/ui/x.svg) center / contain no-repeat; }
.icon-check-circle { mask: url(/icons/ui/check-circle.svg) center / contain no-repeat; }
.icon-alert-triangle { mask: url(/icons/ui/alert-triangle.svg) center / contain no-repeat; }
.icon-list { mask: url(/icons/ui/list.svg) center / contain no-repeat; }
.icon-columns { mask: url(/icons/ui/columns.svg) center / contain no-repeat; }
.icon-log-in { mask: url(/icons/arrows/log-in.svg) center / contain no-repeat; }
.icon-log-out { mask: url(/icons/arrows/log-out.svg) center / contain no-repeat; }
.icon-refresh-cw { mask: url(/icons/arrows/refresh-cw.svg) center / contain no-repeat; }
.icon-users { mask: url(/icons/users/users.svg) center / contain no-repeat; }
.icon-cloud-off { mask: url(/icons/cloud-network/cloud-off.svg) center / contain no-repeat; }
.icon-calendar-days { mask: url(/icons/time/calendar-days.svg) center / contain no-repeat; }
@media (prefers-color-scheme: dark) {
  :root { color: #f3f7fc; background: #101820; }
  header, .board section { background: #203040; }
  a { color: #9dccff; }
  :focus-visible { outline-color: #9dccff; }
  .skip:focus { background: #101820; }
}
@media (forced-colors: active) { .icon { background-color: CanvasText; } }
```

Expected result: `src/styles.css` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 58. Inspect the copied `backend/.dockerignore`
In code, inspect the upstream configuration. A verbatim Python backend fixture configuration; do not modify it to solve a client problem.

**File: `backend/.dockerignore`**
```text
.git
.gitignore
.venv
**/__pycache__
**/*.pyc
.env
.env.example
Dockerfile
.dockerignore
docker-compose.yml
docker-compose.override.yml
db
keycloak
scripts
requests
pyproject.toml
```

Expected result: `backend/.dockerignore` is saved exactly as shown. See the configuration reading guide below.

### Step 59. Inspect the copied `backend/.env.example`
In code, inspect the upstream configuration. A verbatim Python backend fixture configuration; do not modify it to solve a client problem.

**File: `backend/.env.example`**
```text
# Disposable local practice only. Copy to .env (Git ignores it). Never put real secrets in this file.

# Platform infrastructure (read by docker-compose.yml)
POSTGRES_DB=tasksteams
POSTGRES_USER=tasks_admin
POSTGRES_PASSWORD=tasks_admin_local_only
POSTGRES_PORT=5432
KEYCLOAK_ADMIN=kcadmin
KEYCLOAK_ADMIN_PASSWORD=kcadmin_local_only
KEYCLOAK_PORT=8180
TASKS_NETWORK=tasksteams-net

# Read by docker-compose.override.yml when the API runs in a container (the database role is created by db/schema.sql)
TASKS_APP_PASSWORD=tasks_app_local_only

# The API, when it runs on your computer with uvicorn (read by app/config.py; the container gets its own values from the override file)
DATABASE_URL=postgresql+psycopg://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams
LOG_LEVEL=INFO
PUBLIC_BASE_URL=http://localhost:8000
ENABLE_DOCS=true

# Token validation. TOKEN_ISSUER must equal the `iss` claim character for character; JWKS_URL is where the keys are fetched.
TOKEN_ISSUER=http://localhost:8180/realms/tasksteams
TOKEN_AUDIENCE=tasks-api
JWKS_URL=http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs
TOKEN_LEEWAY_SECONDS=30

# Limits and browser rules (phase 5). Requests per window and user, per window and unknown caller, window length, largest body in bytes.
RATE_LIMIT_USER=100
RATE_LIMIT_ANONYMOUS=30
RATE_LIMIT_WINDOW_SECONDS=60
MAX_BODY_BYTES=1048576
CORS_ORIGINS=http://localhost:4200,http://localhost:5173
ENABLE_HSTS=false
```

Expected result: `backend/.env.example` is saved exactly as shown. See the configuration reading guide below.

### Step 60. Inspect the copied `backend/Dockerfile`
In code, inspect the upstream configuration. A verbatim Python backend fixture configuration; do not modify it to solve a client problem.

**File: `backend/Dockerfile`**
```dockerfile
# syntax=docker/dockerfile:1

# Stage 1 (builder): create a virtual environment with every dependency. Only wheels are allowed, so no compiler is needed.
FROM python:3.14.10-slim-trixie AS builder
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1
RUN python -m venv /opt/venv
COPY requirements.txt /tmp/requirements.txt
RUN /opt/venv/bin/pip install --only-binary=:all: -r /tmp/requirements.txt

# Stage 2 (runtime): the same Python, the finished virtual environment and our code. No pip, no build tools, no cache.
FROM python:3.14.10-slim-trixie AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"
RUN groupadd --system --gid 10001 app \
 && useradd --uid 10001 --gid app --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin app
COPY --from=builder /opt/venv /opt/venv
WORKDIR /srv
COPY app ./app
USER 10001:10001
EXPOSE 8000
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=5 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-server-header"]
```

Expected result: `backend/Dockerfile` is saved exactly as shown. See the configuration reading guide below.

### Step 61. Inspect the copied `backend/docker-compose.override.yml`
In code, inspect the upstream configuration. A verbatim Python backend fixture configuration; do not modify it to solve a client problem.

**File: `backend/docker-compose.override.yml`**
```yaml
# Adds the API to the platform stack. Compose merges this file into docker-compose.yml automatically,
# so one command starts Postgres, Keycloak and the API on the same network (tasksteams-net).
services:
  api:
    build:
      context: .
    environment:
      DATABASE_URL: postgresql+psycopg://tasks_app:${TASKS_APP_PASSWORD:-tasks_app_local_only}@db:5432/${POSTGRES_DB:-tasksteams}
      TOKEN_ISSUER: http://localhost:${KEYCLOAK_PORT:-8180}/realms/tasksteams
      TOKEN_AUDIENCE: tasks-api
      JWKS_URL: http://keycloak:8080/realms/tasksteams/protocol/openid-connect/certs
      PUBLIC_BASE_URL: http://localhost:8000
      LOG_LEVEL: INFO
      ENABLE_DOCS: "false"
      RATE_LIMIT_USER: "100"
      RATE_LIMIT_ANONYMOUS: "30"
      RATE_LIMIT_WINDOW_SECONDS: "60"
      MAX_BODY_BYTES: "1048576"
      CORS_ORIGINS: http://localhost:4200,http://localhost:5173
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "127.0.0.1:8000:8000"
    networks:
      - tasksteams
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    pids_limit: 200
    mem_limit: 256m
    cpus: 1.0
```

Expected result: `backend/docker-compose.override.yml` is saved exactly as shown. See the configuration reading guide below.

### Step 62. Inspect the copied `backend/docker-compose.yml`
In code, inspect the upstream configuration. A verbatim Python backend fixture configuration; do not modify it to solve a client problem.

**File: `backend/docker-compose.yml`**
```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "127.0.0.1:${POSTGRES_PORT:-5432}:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data
      - ./db/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql:ro
      - ./db/seed.sql:/docker-entrypoint-initdb.d/02-seed.sql:ro
      - ./db:/scripts:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -h 127.0.0.1 -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 3s
      timeout: 3s
      retries: 30
      start_period: 5s
    networks:
      - tasksteams
  keycloak:
    image: quay.io/keycloak/keycloak:26.8.2
    command: ["start-dev", "--import-realm"]
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: ${KEYCLOAK_ADMIN}
      KC_BOOTSTRAP_ADMIN_PASSWORD: ${KEYCLOAK_ADMIN_PASSWORD}
      KC_HOSTNAME: http://localhost:${KEYCLOAK_PORT:-8180}
      KC_HOSTNAME_BACKCHANNEL_DYNAMIC: "true"
      KC_HEALTH_ENABLED: "true"
    ports:
      - "127.0.0.1:${KEYCLOAK_PORT:-8180}:8080"
    volumes:
      - ./keycloak/realm-tasksteams.json:/opt/keycloak/data/import/realm-tasksteams.json:ro
    healthcheck:
      test: ["CMD", "bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/9000 && printf 'GET /health/ready HTTP/1.1\\r\\nHost: localhost\\r\\nConnection: close\\r\\n\\r\\n' >&3 && grep -q UP <&3"]
      interval: 5s
      timeout: 5s
      retries: 60
      start_period: 30s
    networks:
      - tasksteams
networks:
  tasksteams:
    name: ${TASKS_NETWORK:-tasksteams-net}
volumes:
  pg_data:
```

Expected result: `backend/docker-compose.yml` is saved exactly as shown. See the configuration reading guide below.

### Step 63. Inspect the copied `backend/requirements.txt`
In code, inspect the upstream configuration. A verbatim Python backend fixture configuration; do not modify it to solve a client problem.

**File: `backend/requirements.txt`**
```text
fastapi==0.165.0
uvicorn==0.54.0
pydantic==2.14.4
pydantic-settings==2.16.3
SQLAlchemy==2.1.9
psycopg[binary]==3.3.9
PyJWT[crypto]==2.15.1
```

Expected result: `backend/requirements.txt` is saved exactly as shown. See the configuration reading guide below.

### Step 64. Copy the CC0 icons and licence
Run in the repository root. The front matter lists all art used; no outside icons or fonts are needed.

**File: `terminal (repository root)`**
```powershell
$dest = 'capstones/web-react/source/phase-4-errors/04-errors-and-accessibility/code/public/icons'
New-Item -ItemType Directory -Force $dest | Out-Null
New-Item -ItemType Directory -Force "$dest/ui" | Out-Null
Copy-Item 'assets/art/icons/ui/search.svg' "$dest/ui/search.svg"
Copy-Item 'assets/art/icons/ui/filter.svg' "$dest/ui/filter.svg"
Copy-Item 'assets/art/icons/ui/plus.svg' "$dest/ui/plus.svg"
Copy-Item 'assets/art/icons/ui/x.svg' "$dest/ui/x.svg"
Copy-Item 'assets/art/icons/ui/check-circle.svg' "$dest/ui/check-circle.svg"
Copy-Item 'assets/art/icons/ui/alert-triangle.svg' "$dest/ui/alert-triangle.svg"
Copy-Item 'assets/art/icons/ui/list.svg' "$dest/ui/list.svg"
Copy-Item 'assets/art/icons/ui/columns.svg' "$dest/ui/columns.svg"
New-Item -ItemType Directory -Force "$dest/arrows" | Out-Null
Copy-Item 'assets/art/icons/arrows/log-in.svg' "$dest/arrows/log-in.svg"
Copy-Item 'assets/art/icons/arrows/log-out.svg' "$dest/arrows/log-out.svg"
Copy-Item 'assets/art/icons/arrows/refresh-cw.svg' "$dest/arrows/refresh-cw.svg"
New-Item -ItemType Directory -Force "$dest/users" | Out-Null
Copy-Item 'assets/art/icons/users/users.svg' "$dest/users/users.svg"
New-Item -ItemType Directory -Force "$dest/cloud-network" | Out-Null
Copy-Item 'assets/art/icons/cloud-network/cloud-off.svg' "$dest/cloud-network/cloud-off.svg"
New-Item -ItemType Directory -Force "$dest/time" | Out-Null
Copy-Item 'assets/art/icons/time/calendar-days.svg' "$dest/time/calendar-days.svg"
Copy-Item assets/art/LICENSE-ICONS-CC0.txt "$dest/LICENSE-ICONS-CC0.txt"
```

macOS/Linux: use mkdir -p for the same category folders and replace each Copy-Item source destination with cp source destination. These copies are genuinely identical apart from the fourteen concrete paths above. The pack already carries the files/licence. Expected result: icons appear beside text after build; CSS masks need no inline styles.

### Configuration reading guide
- `package.json`: `private` prevents accidental npm publication; `type: module` enables ESM; exact dependency strings and the lockfile make `npm ci` reproducible. `api:gen` owns generated declarations. The project TypeScript is 5.9.3 because this generator declares peer `^5.x`; Web 101's compiler version need not match.
- Both compiler projects: `target`/`lib` select syntax and browser APIs; `module: ESNext` and `moduleResolution: Bundler` match Vite; `allowImportingTsExtensions`/`resolveJsonModule`/`isolatedModules`/`verbatimModuleSyntax` avoid ambiguous transforms; `noEmit` delegates output; `strict` and `noUncheckedIndexedAccess` keep errors visible; `skipLibCheck` avoids rechecking dependency declarations. `types` differs by runtime, `include` sets boundaries, `tsBuildInfoFile` stays in node_modules/.tmp rather than the pack.
- Vite: `plugins` enables React; `host`, `port`, `strictPort` lock the registered development origin. Removing strictPort can silently break login by moving to 5174. There is no proxy to mask CORS.
- Environment: change only the three VITE_ settings for the client. The fixture's POSTGRES_DB/USER/PASSWORD/PORT configure its database and healthcheck; KEYCLOAK_ADMIN/PASSWORD/PORT configure local Keycloak; TASKS_NETWORK is the shared tasksteams-net. TASKS_APP_PASSWORD is the restricted runtime role. DATABASE_URL, PUBLIC_BASE_URL, LOG_LEVEL and ENABLE_DOCS configure the API; TOKEN_ISSUER/AUDIENCE/JWKS_URL/LEEWAY verify bearer tokens; rate/body/CORS/HSTS settings are the backend's final-phase hardening. All fixture passwords are fake, local-only.
- Backend Compose: `services` defines db/keycloak; image pins select Postgres 17 and Keycloak 26.8.2; environment substitutions come from `--env-file`; loopback `ports` prevent LAN exposure; volumes initialise schema/seed once and import the realm; healthcheck test/interval/timeout/retries/start_period let `up --wait` wait for readiness; the named network connects services; pg_data stores this lab only. The override builds the API from backend/, supplies container database/JWKS addresses, starts after a healthy DB, binds 8000, and applies restart/read_only/tmpfs/cap_drop/security_opt/pids_limit/mem_limit/cpus restrictions. The fixed network name is why we serialize runs.
- Backend Dockerfile: build a venv from wheel-only pinned requirements in a builder, copy the venv and app into a fresh matching runtime, make uid/gid 10001, expose 8000 and run uvicorn without a server header. HEALTHCHECK reads /health. Environment disables bytecode and buffering; .dockerignore removes unrelated context. This backend is a verbatim fixture, not a second implementation taught here.

### Step 65. Install, generate and build
All commands run in code. Prefer the shipped lockfile and npm ci for exact resolutions. A scratch author without a lockfile must first run `npm install --package-lock-only --ignore-scripts`. The real initial run printed `up to date, audited 70 packages in 5s` and `found 0 vulnerabilities`; timings/advisories change. This is the regeneration path for the large generated lockfile. Ship the lockfile, not node_modules.

**File: `terminal (code)`**
```powershell
npm ci --no-audit --no-fund
npm run api:gen
node scripts/check-contract.mjs
npm run build
```

api:gen regenerates src/api/schema.d.ts; prebuild repeats generation so stale declarations cannot silently survive. Real captured generation/build output (duration and hashed filenames vary):

**File: `terminal output (build)`**
```text
> tasks-web-react@1.0.0 prebuild
> npm run api:gen


> tasks-web-react@1.0.0 api:gen
> openapi-typescript contract/openapi.yaml -o src/api/schema.d.ts

✨ openapi-typescript 7.13.0
🚀 contract/openapi.yaml → src/api/schema.d.ts [67.4ms]

> tasks-web-react@1.0.0 build
> tsc -b && vite build

vite v8.3.8 building client environment for production...
transforming...
✓ 189 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                          0.48 kB │ gzip:   0.30 kB
dist/assets/index-DBP-3QQU.css           3.43 kB │ gzip:   1.01 kB
dist/assets/NotFound-h5YtTxlZ.js         0.27 kB │ gzip:   0.21 kB
dist/assets/Page-nkutFQt_.js             0.35 kB │ gzip:   0.26 kB
dist/assets/Callback-DVr4R3fg.js         0.66 kB │ gzip:   0.41 kB
dist/assets/ConfirmDialog-DHwDbtB7.js    0.86 kB │ gzip:   0.48 kB
dist/assets/Login-DsqEg4WL.js            1.05 kB │ gzip:   0.58 kB
dist/assets/Dashboard-XNzlNwmF.js        1.09 kB │ gzip:   0.56 kB
dist/assets/projects-B8z9cYCD.js         1.67 kB │ gzip:   0.73 kB
dist/assets/Projects-ClSljCIk.js         1.74 kB │ gzip:   0.86 kB
dist/assets/Teams-DFa8oWer.js            1.76 kB │ gzip:   0.83 kB
dist/assets/LoadMore-DBbfQV4P.js         1.84 kB │ gzip:   0.98 kB
dist/assets/Banner-DIR-rTjI.js           1.94 kB │ gzip:   0.87 kB
dist/assets/tasks-CSpAUj4h.js            2.08 kB │ gzip:   0.80 kB
dist/assets/TeamDetail-U2TrKt4l.js       2.13 kB │ gzip:   0.88 kB
dist/assets/Audit-BhWRV1SE.js            2.31 kB │ gzip:   1.02 kB
dist/assets/Tasks-Dwinl_9g.js            4.66 kB │ gzip:   1.66 kB
dist/assets/teams-U2n-u2Sq.js            4.78 kB │ gzip:   1.85 kB
dist/assets/TaskDetail-6dSJQzLB.js       6.60 kB │ gzip:   2.47 kB
dist/assets/lib-D1qhtAYh.js            104.33 kB │ gzip:  34.24 kB
dist/assets/index-yEjFe3uN.js          333.76 kB │ gzip: 100.09 kB

✓ built in 304ms
```

**File: `terminal output (contract)`**
```text
contract: SHA-256 matches platform; 27 operations
```

The install emitted the real npm 11 notice `1 package has install scripts not yet covered by allowScripts:` for `esbuild@0.28.2`. Build and tsx smoke succeeded here. Review dependency scripts before approval; do not globally disable policy.

The entry bundle gzip column is below the 250 kB target; lazy screens are separate chunks. This is not a measured browser responsiveness guarantee.

## Run it
Use one stack owner at a time. Repository verification takes the tasksteams lock itself. For **manual development**, first enter a lock-owning shell from repository root; keep all shared-port start/probe/stop commands in it:

**File: `terminal (repository root)`**
```powershell
python scripts/stack_lock.py tasksteams -- powershell -NoProfile
```

macOS/Linux: `python scripts/stack_lock.py tasksteams -- bash`. Exit that inner shell only after stopping Vite and cleanup. An extracted-pack learner not sharing this repository can omit the wrapper, but must still ensure free ports. Never leave the inner shell holding a lock after the lab.

Inside the locked shell change to `capstones/web-react/source/phase-4-errors/04-errors-and-accessibility/code` (or extracted code). --env-file uses fake local fixture settings without creating .env. Run:

**File: `terminal (code)`**
```powershell
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-4 up -d --build --wait --wait-timeout 420
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-4 ps
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-4 logs --tail 3 api
npm run smoke
```

Real captured stack status (age/status durations differ):

**File: `terminal output (stack status)`**
```text
NAME                                IMAGE                              COMMAND                  SERVICE    CREATED          STATUS                    PORTS
code101-react-author-4-api-1        code101-react-author-4-api         "uvicorn app.main:ap…"   api        35 seconds ago   Up 29 seconds (healthy)   127.0.0.1:8000->8000/tcp
code101-react-author-4-db-1         postgres:17-alpine                 "docker-entrypoint.s…"   db         36 seconds ago   Up 35 seconds (healthy)   127.0.0.1:5432->5432/tcp
code101-react-author-4-keycloak-1   quay.io/keycloak/keycloak:26.8.2   "/opt/keycloak/bin/k…"   keycloak   36 seconds ago   Up 35 seconds (healthy)   127.0.0.1:8180->8080/tcp
```

Real API log excerpt (timestamps/trace ids differ; no tokens):

**File: `terminal output (API logs)`**
```text
api-1  | {"time": "2026-11-23T10:43:49.250+00:00", "level": "INFO", "logger": "tasksteams.access", "message": "request", "traceId": "c670d962d64b499081a6eecbf909bd6c", "method": "GET", "path": "/v1/tasks/e4ceee4a-b7fc-4b20-ae54-140f20ff3c5a", "status": 304, "durationMs": 5.1, "userId": "a11ce000-0000-4000-8000-000000000001"}
api-1  | {"time": "2026-11-23T10:43:49.261+00:00", "level": "INFO", "logger": "tasksteams.access", "message": "request", "traceId": "45027cf678af41a99905a46f15d9ae51", "method": "POST", "path": "/v1/tasks/e4ceee4a-b7fc-4b20-ae54-140f20ff3c5a/complete", "status": 200, "durationMs": 9.1, "userId": "a11ce000-0000-4000-8000-000000000001"}
api-1  | {"time": "2026-11-23T10:43:49.271+00:00", "level": "INFO", "logger": "tasksteams.access", "message": "request", "traceId": "653808be42b949fbb3e69764afd4389a", "method": "DELETE", "path": "/v1/tasks/e4ceee4a-b7fc-4b20-ae54-140f20ff3c5a", "status": 204, "durationMs": 8.2, "userId": "a11ce000-0000-4000-8000-000000000001"}
```

Real single smoke journey:

**File: `terminal output (smoke)`**
```text
> tasks-web-react@1.0.0 smoke
> tsx scripts/smoke.ts

foreign host: no bearer header (local transport stand-in)
health: ok
me: alice (admin)
without token: 401
teams: 2
tasks: 5; nextCursor: null
Idempotent-Replayed: true
412 precondition-failed
The task changed since you read it (current version 2).
404 not-found
The task was not found.
422 validation-error; pointer: /title
One or more fields are invalid.
canned 429 Retry-After: 1
304 kept cached task
complete: done; completedAt: present
PKCE: S256; login page: 200; user store: memory
expiry event: fired without automaticSilentRenew
```

The tasks-smoke password grant is fake-local-smoke-only, never browser code. A foreign-host transport stand-in checks bearer scoping without contacting that host. The 429 parser input is explicitly canned, not a claim that the backend budget was exhausted.

Keep the backend running for a browser walkthrough; in code run:

**File: `terminal (code)`**
```powershell
npm run dev
```

### Browser-only checklist (not automated)
1. Keep the temporary backend stack up. In `code`, run `npm run dev`, then open **http://localhost:5173**, never 127.0.0.1. No browser check in this chapter has been claimed as passed by the author.
2. Open `/admin/audit` directly in a fresh tab. Expect Login and a **Sign in** button. Click it: the address becomes localhost:8180, realm tasksteams, with Username or email and Password fields on the Keycloak page.
3. Enter fake local account **alice / alice-local-fake**. Expect the **Callback** heading and **Signing you in** briefly, then **Audit log** after one silent step-up for tasks:admin. The address and Back history must contain no `code=` or `state=`. For normal sign-in from `/`, expect **Dashboard**, alice's display name, roles and scopes.
4. Open DevTools ? Application/Storage. Tokens must be absent from localStorage and sessionStorage. localStorage may contain only the non-secret `ts.hint=1` flag from this app; sessionStorage may contain short-lived OIDC state during a redirect, never an OIDC user with access/refresh/id tokens. Do not copy tokens into screenshots or logs.
5. Keep the tab open for **six minutes**, then navigate to another API screen. Expect it still works. In Network, one refresh-token exchange should occur near expiry; two concurrent API calls must not cause parallel refreshes. The Node timer demonstration is not proof of this browser behaviour.
6. Reload a protected route. Memory is empty: expect one prompt=none round trip through the existing Keycloak SSO session, then the original route. Expired SSO should show Login with a readable login_required error, not a redirect loop.
7. Use User menu ? **Sign out**. Expect Keycloak session termination and Login. Opening `/teams` again must require sign-in; in chapter 02 the route is introduced in chapter 03, so use `/` for the same guard check here.
8. Sign in as **bob / bob-local-fake**, then type `/admin/audit`. Expect **You do not have access**, not an empty audit table and not a step-up loop. Roles/scopes are read from getMe; UI hiding never replaces server authorization.
9. To inspect an error callback without disclosing a code, cancel sign-in or let SSO expire before prompt=none. Expect an error message and a Return to Login link, and no callback payload left in history.

### Walk the matching screens manually
| Screen | Route and expected visible result | Action to try |
|---|---|---|
| Login | `/login`: heading Login, Sign in button | Sign in as alice using Keycloak, not an app password form |
| Callback | `/auth/callback`: Signing you in status, then original route | Verify address-bar and history cleanup |
| Dashboard | `/`: greeting, roles, scopes, API ok, Platform Team and Mobile Team | Follow a membership link |
| Teams | `/teams`: Search, Sort, team links, Load more or End of list | Search Platform; create a disposable team as alice; delete it with confirmation (step-up may redirect once, then confirm again) |
| Team detail | `/teams/<id>`: team fields, Projects, Members tab disclosure | Edit a disposable team; add bob by UUID, change role, remove; compare bob's hidden lead controls |
| Projects | `/teams/<id>/projects`: project key/name, Show archived | Create key RX, then try RX again to see 409; archive then show all and restore; confirm deletion only on a disposable project |
| Tasks | `/projects/<id>`: List/Board toggle, Filters, create form | Select two statuses, priority, assignee, due range, text and sort; submit; copy URL and check Back; move a card with Move to, no dragging |
| Task detail | `/tasks/<id>`: fields, completed time, comments | Edit, complete, reassign as lead, add a comment, load pages, delete own comment; delete a disposable task with confirmation |
| Audit log | `/admin/audit`: filter form and table | Filter entity, actor, from/to; check Load more, alice scope step-up, bob access panel |
| Not found | `/anything-else`: neutral Not found and Home | Return home without leaking object visibility |

A fresh database has two teams and five PLAT tasks; `getMe.teams` supplies memberships, while `listTeams` supplies visible team pages. Add a few items to a disposable team if you want to see pagination in the browser; smoke already walks small pages. For add-member practice, fake realm UUIDs are alice `a11ce000-0000-4000-8000-000000000001`, bob `b0b00000-0000-4000-8000-000000000002`, carol `ca401000-0000-4000-8000-000000000003`; verify them against the shipped backend/keycloak realm before entering them. UUID entry deliberately replaces a user-directory search screen; assignee choices come only from listMembers.

### Conflict and accessibility walkthrough (human verification still required)
1. Open one disposable task in two browser tabs. In tab A change its title and save. In tab B change the priority and save. Expect the old snapshot to be restored after the failed optimistic save, the typed draft still present, and **This task changed** showing server/local values.
2. Choose **Apply my changes on top**. The app re-reads immediately and sends the latest ETag with only locally changed fields. Expect both A's title and B's priority. Repeat and choose **Use the server version**: fields should now match the server. Escape closes the native modal without deleting the draft.
3. Enable Slow 3G in DevTools Network and save a title. The displayed title should change before the response; a rejected request must roll it back. A successful response must replace the exact ETag. Focus the tab again: task GET sends If-None-Match and a 304 keeps the object; teams/projects do not use that header.
4. In Network choose Offline. Within one second expect **You are offline. Writes are disabled.** Create/save/delete/confirm controls must be disabled and drafts retained. Go online and choose Try again. If a failed request marked the API offline while navigator.onLine was true, check the API and use Try again to resume.
5. Use only Tab, Shift+Tab, Enter, Space and Escape. The first tab stop is Skip to content. Follow each route: h1 receives focus, document title changes, focus rings stay visible and the sticky header must not cover the target. Open both dialogs: Tab stays inside; Escape closes; focus returns to the opener.
6. At **320 CSS px** width and at 400% zoom, text and controls wrap without whole-page horizontal scrolling; only the audit table may scroll in its labelled region. Test light, dark and Windows forced-colors. Check text contrast at least 4.5:1 and controls/focus at least 3:1 with a contrast tool; palette choices alone are not proof.
7. Submit an invalid value with browser constraints temporarily disabled to see a real 422. Expect the focused error summary, pointer-specific text, aria-invalid and aria-describedby on the named field. Try a duplicate project key for 409. Never remove client constraints in shipped code.
8. With a screen reader, ensure headings/landmarks/table column names are meaningful, icon spans are ignored, success appears in a polite status region and failures announce as alerts. No icon-only action relies on its picture for a name. Target sizes must remain at least 24 by 24 CSS px.
9. The Keycloak authentication screen must allow password managers and paste; no cognitive puzzle or repeated manual entry is added by this app. Drafts must survive errors and conflict decisions. This is a key-criteria WCAG 2.2 AA checklist, **not an accessibility certification**.

| Status | Behaviour and recovery |
|---|---|
| 400 / 428 | Show problem detail and trace; fix request construction (or reset an invalid cursor/filter URL), do not hide the error |
| 401 | One shared renewal and one retry, then clear memory and replace with Login plus returnUrl |
| 403 | You do not have access, no futile retry; Home remains available |
| 404 | Not found, never say that an invisible object exists |
| 409 | Keep draft and show rule/duplicate detail; last_lead needs another lead assigned first |
| 412 | Roll back, keep draft, offer the explicit conflict choices |
| 422 | Focus summary, connect errors[].pointer to named controls, display support trace |
| 429 | Countdown from Retry-After; retry only GET once, writes stay manual |
| 5xx / network | Visible error and Try again; at most two Query retries; failed transport also shows offline state |
| 413 / 405 / 415 / 503 | Follow platform section 12.1 Decision: display problem detail, 503 may include Retry-After; do not assume v1 OpenAPI enumerates every runtime error |

### Always stop and remove the lab
If Vite is running press **Ctrl+C** first. In the same locked code folder run these even if smoke failed:

**File: `terminal (code)`**
```powershell
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-4 down -v --remove-orphans
docker image rm code101-react-author-4-api
docker ps -a
docker volume ls
docker network ls
```

Captured cleanup removes containers, lab volume/network and explicitly untags the built API image:

**File: `terminal output (stack cleanup)`**
```text
Container code101-react-author-4-keycloak-1 Stopping 
 Container code101-react-author-4-api-1 Stopping 
 Container code101-react-author-4-api-1 Stopped 
 Container code101-react-author-4-api-1 Removing 
 Container code101-react-author-4-api-1 Removed 
 Container code101-react-author-4-db-1 Stopping 
 Container code101-react-author-4-db-1 Stopped 
 Container code101-react-author-4-db-1 Removing 
 Container code101-react-author-4-db-1 Removed 
 Container code101-react-author-4-keycloak-1 Stopped 
 Container code101-react-author-4-keycloak-1 Removing 
 Container code101-react-author-4-keycloak-1 Removed 
 Network tasksteams-net Removing 
 Volume code101-react-author-4_pg_data Removing 
 Volume code101-react-author-4_pg_data Removed 
 Network tasksteams-net Removed
```

**File: `terminal output (image cleanup)`**
```text
Untagged: code101-react-author-4-api:latest
Deleted: sha256:91611633f0a0ce78c167ba741dabb74b8b452e40bb446405ffe56294a0611422
```

Exit the inner shell to release the lock. Final docker ps -a, docker volume ls and docker network ls must show no resources belonging to this project. Do not delete another task?s resources. Shared base-image caches may remain.

### Repository smoke verification
From repository root, outside the manual lock shell:

**File: `terminal (repository root)`**
```powershell
python scripts/verify_labs.py capstones/web-react/source/phase-4-errors/04-errors-and-accessibility
```

The verifier installs once, builds once, starts the disposable fixture, runs one generated-client smoke, runs the small exercise solution, and always cleans up. Browser-only items are not a PASS claim.

Historical repository verifier output, captured before the no-execution update; not the current delivery status:

**File: `terminal output (repository verification)`**
```text
[PASS      ] capstones/web-react/source/phase-1-setup/01-create-app
[PASS      ] capstones/web-react/source/phase-2-auth/02-sign-in
[PASS      ] capstones/web-react/source/phase-3-screens/03-screens-and-state
[PASS      ] capstones/web-react/source/phase-4-errors/04-errors-and-accessibility
[PASS      ] capstones/web-react/source/phase-5-ship/05-build-run-ship

5 passed, 0 failed, 0 unverified (missing tools)
```

## How it works
The form compares its draft with the baseline, then the mutation cancels a racing read, takes a snapshot and updates the detail cache immediately. Error restores the snapshot. A 412 triggers a fresh read and an explicit choice; success replaces both value and quoted ETag. Conditional task reads preserve the cached pair on 304. Problem parsing, transport policy and UI rendering remain separate so Node and React use the same semantics.

## Try it
Copy exercise/starter to exercise/work so the answer does not overwrite the supplied solution. In PowerShell, lesson folder (parent of code):

**File: `terminal (lesson folder)`**
```powershell
Copy-Item exercise/starter exercise/work -Recurse
Set-Location exercise/work
node ../../code/node_modules/tsx/dist/cli.mjs run.ts
```

macOS/Linux: cp -R exercise/starter exercise/work, then cd exercise/work; the Node command is identical. Run npm ci in code first if installed packages were removed. The starter intentionally fails. Only a tiny supplied runner is used, not a test framework. Edit answer.ts using this chapter?s idea.

**File: `exercise/starter/answer.ts`**
```typescript
export const sameTag = (etag: string) => etag.replaceAll('"', '');
```

**File: `exercise/starter/run.ts`**
```typescript
import { sameTag } from './answer';
if (sameTag('"3"') !== '"3"') throw new Error('Keep the quotes.');
console.log('exercise: ETag quotes kept');
```

<details><summary>Solution</summary>

Replace answer.ts, save, rerun the same Node command.

**File: `exercise/solution/answer.ts`**
```typescript
export const sameTag = (etag: string) => etag;
```

**File: `exercise/solution/run.ts`**
```typescript
import { sameTag } from './answer';
if (sameTag('"3"') !== '"3"') throw new Error('Keep the quotes.');
console.log('exercise: ETag quotes kept');
```

Real solution output:

**File: `terminal output (exercise)`**
```text
exercise: ETag quotes kept
```

</details>

## Check yourself
1. Why keep ETag quotes?
   <details><summary>Answer</summary>If-Match must reproduce the exact strong validator, not a parsed number.</details>
2. When is rollback necessary?
   <details><summary>Answer</summary>On every failed optimistic mutation, including 412 and network failure.</details>
3. Why reread when applying over a conflict?
   <details><summary>Answer</summary>Another writer may have saved after the dialog opened; the latest ETag must be used and another 412 still handled.</details>
4. Why not use 304 as ordinary data?
   <details><summary>Answer</summary>304 is non-OK and contains no new DTO; retain the cached value and ETag.</details>

## Common mistakes
These strings are from real runs, not memory. The exercise error is deliberately triggered by the shipped starter.

| Captured symptom/error | Cause | Fix |
|---|---|---|
| `Error: Keep the quotes.` | The starter retains its intentional wrong value/function. | Apply the solution; do not weaken the runner. |
| `without token: 401` | The real anonymous /v1/me call was refused intentionally. | Sign in through tasks-web; never paste the smoke password flow into React. |
| `The task changed since you read it (current version 2).` | A stale quoted If-Match produced 412. | Preserve the draft and use the explicit conflict choices, never strip the header. |
| `The task was not found.` | Real missing-task 404; an invisible object also uses 404. | Check route/membership without inferring that a hidden object exists. |
| `One or more fields are invalid.` | Real empty-title 422 with /title pointer. | Correct the field; retain the support trace. |

## Best practice
Keep remote data in a cache and compute derived presentation during rendering, rather than maintaining duplicate copies with effects. Effects here synchronize actual browser APIs such as title/focus, timers and connectivity. Source: React, [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect) (Tier 1); React, [Build a React app from Scratch](https://react.dev/learn/build-a-react-app-from-scratch) (routing, data fetching, code splitting).

For cancel/snapshot/rollback, Source: TanStack Query, [Optimistic Updates](https://tanstack.com/query/latest/docs/framework/react/guides/optimistic-updates) (official library documentation).

## Next lesson
05. Docker, nginx, CSP: The complete application in a multi-stage image, an unprivileged nginx runtime on container port 8080, a strict CSP, a health endpoint and SPA fallback.
