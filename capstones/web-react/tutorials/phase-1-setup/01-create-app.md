---
track: capstone
level: 201
phase: 1
phase_name: setup
lesson: 01
title: "Create the app, generate the client"
time: 180 min
prerequisites: [web-101, capstone-platform-01]
versions: { react: "19.3.1", vite: "8.3.8", typescript: "5.9.3", react_router: "8.5.2", tanstack_query: "5.108.3", node: "26.13.1", npm: "11.20.0" }
verified: not yet run
source: capstones/web-react/source/phase-1-setup/01-create-app/
assets: []
---

# 01. Create the app, generate the client

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

> **Current delivery status: written (not run).** Per the updated no-execution instruction, the final verification run was stopped. Do not run builds, smoke scripts, Docker startup or servers as part of this authoring session. Commands below are deferred learner instructions. Previously captured output is historical evidence from before that instruction, not verification of this written delivery. Browser-only acceptance remains manual.

## Why it matters
A generated client is like a labelled connector: the plug only fits the socket described by the contract. TypeScript catches a misspelled path or missing body field before a learner clicks anything. The OpenAPI document belongs to the platform, not to this app.

## What you will build
A Vite react-ts application on localhost:5173, a byte-identical platform contract, generated schema types, one typed HTTP client, and a Node smoke script that signs in only through tasks-smoke. The first screen says Tasks and Teams, Generated client ready, and API: ok when the backend is up.

Requirements: **W-01 to W-05**. Chapter numbering, phase names and screen names match the approved React/Angular plan. This is a long capstone workshop, not a 20-minute language lesson.

## Before you start
- Finish Web 101 forms, CSS layout, TypeScript, modules and fetch. Read the platform contract and Keycloak chapters. Keep [TDD.md](../../TDD.md) beside you; platform TDD section 12.1 Decision is authoritative when v1 OpenAPI omits a runtime case.
- Node 26.13.1, npm 11.20.0, Docker Desktop (Linux containers), Python for repository verification/locking. After installation close/reopen the terminal. Official references and pins: [REFERENCES.md](../../REFERENCES.md).
- Download `web-react-phase-1-setup.zip`. Windows: right-click ? Extract All; macOS: double-click; Linux: `unzip web-react-phase-1-setup.zip`. Open `01-create-app/code` inside the extracted phase folder. Each pack contains the **whole app**, not a patch. Do not copy node_modules or dist from another phase.
- Open PowerShell in `code` (the prompt path must end in `01-create-app\code`). Recover with `Set-Location 'F:\Projects\Uee03\Code101\capstones\web-react\source\phase-1-setup\01-create-app\code'` in this repository. macOS/Linux: `cd /path/to/Code101/capstones/web-react/source/phase-1-setup/01-create-app/code`. Substitute your clone location once, not the relative file names.
- Save files before running (an editor tab dot means unsaved). All text is UTF-8 without BOM; PowerShell 5.1 Set-Content -Encoding utf8 adds a BOM, so use your editor.
- Ports 5432, 8180, 8000 and 5173 must be free. Do not stop another agent's stack. Keycloak readiness timeout is **420 seconds**.
- `backend/` is a **verbatim copy** of `capstones/backend-python/source/phase-5-hardening/05-hardening/code/`. Its Compose files start Postgres, Keycloak and Python API. This is a smoke fixture, not a second implementation. Use any other conformant backend on 8000 after stopping it.

## Steps
### Step 1. Prepare the working copy and preserve the contract
The extracted pack is the fastest route. A scratch author must create the same `code` directory and every file below. Do not start Vite until all files and the contract are present. Commands are PowerShell 5.1 compatible.

To reproduce the initial scaffold, run in an empty `01-create-app` folder, not an existing code folder:

**File: `terminal (01-create-app)`**
```powershell
npm create vite@9.3.4 code -- --template react-ts --no-interactive
```

The real run printed `create-vite v9.3.4` and `Done. Now run:` followed by `cd code`, `npm install`, `npm run dev`. Enter code. Delete the template-only source/public, ESLint config and template README, then create the complete files below. No lint command belongs here. We pin Vite 8.3.8 rather than retaining scaffold ranges.

**File: `terminal (code)`**
```powershell
Remove-Item -Recurse -Force src, public
Get-ChildItem -File eslint.config.*, README.md | Remove-Item
```

For a scratch copy inside the repository, open a second terminal at the repository root and copy upstream bytes, never edit them:

**File: `terminal (repository root)`**
```powershell
$dest = 'capstones/web-react/source/phase-1-setup/01-create-app/code'
New-Item -ItemType Directory -Force "$dest/contract", "$dest/backend" | Out-Null
Copy-Item 'capstones/platform/source/phase-4-conformance/04-conformance-script/code/openapi.yaml' "$dest/contract/openapi.yaml"
Copy-Item 'capstones/backend-python/source/phase-5-hardening/05-hardening/code/*' "$dest/backend" -Recurse -Force
Copy-Item 'capstones/backend-python/source/phase-5-hardening/05-hardening/code/.env.example' "$dest/backend/.env.example"
Copy-Item 'capstones/backend-python/source/phase-5-hardening/05-hardening/code/.dockerignore' "$dest/backend/.dockerignore"
```

macOS/Linux, repository root:

**File: `terminal (repository root)`**
```bash
dest='capstones/web-react/source/phase-1-setup/01-create-app/code'
mkdir -p "$dest/contract" "$dest/backend"
cp capstones/platform/source/phase-4-conformance/04-conformance-script/code/openapi.yaml "$dest/contract/openapi.yaml"
cp -R capstones/backend-python/source/phase-5-hardening/05-hardening/code/. "$dest/backend/"
```

Expected result: contract/openapi.yaml and the complete backend fixture exist. Return to your `code` terminal. Do not copy a running backend's .env, build products or caches. The supplied pack excludes them.

**Disclosed text-check exclusions:** generated package-lock.json and src/api/schema.d.ts are in skip_lesson_check. The immutable upstream contract, upstream backend implementation/data/realm, and copied CC0 icon/licence files are also excluded **because they are copied, not authored here**; verify.json enumerates every path. Backend Docker/Compose/environment configurations are nevertheless shown in full below. Every authored app file, including smoke scripts, is shown. Regenerate types, never hand-edit them; recopy upstream bytes, never locally ?fix? the contract.

Create these folders in code. Existing folders are harmless; Out-Null suppresses folder-table output.

**File: `terminal (code)`**
```powershell
New-Item -ItemType Directory -Force 'scripts', 'src', 'src/api' | Out-Null
```

**File: `terminal (code, macOS/Linux)`**
```bash
mkdir -p scripts src src/api
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

### Step 12. Create or replace `scripts/probe-dev.mjs`
In code, create the file at this path, paste the complete contents and save. Fetch the actual dev index once and require 200. This is not a browser rendering or accessibility check.

**File: `scripts/probe-dev.mjs`**
```javascript
const response = await fetch('http://localhost:5173/');
if (response.status !== 200) throw new Error('Dev server failed');
console.log('dev: 200 on localhost:5173');
```

Expected result: `scripts/probe-dev.mjs` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 13. Create or replace `scripts/smoke.ts`
In code, create the file at this path, paste the complete contents and save. This is one smoke journey, not a suite: obtain a fake local tasks-smoke password-grant token, call the generated client and check small seed responses. Only the script uses that grant. The browser never has these credentials. Later phases add one paginated read and a temporary task conflict/replay journey; cleanup removes the whole disposable database.

**File: `scripts/smoke.ts`**
```typescript
import { makeClient } from '../src/api/client';
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
const transport: typeof fetch = (input, init) => {
  const request = new Request(input, init);
  if (new URL(request.url).origin === new URL(base).origin) request.headers.set('Authorization', `Bearer ${token}`);
  return fetch(request);
};
const api = makeClient(base, transport);
const health = unwrap(await api.GET('/health'));
const me = unwrap(await api.GET('/v1/me'));
if (health.status !== 'ok' || me.username !== 'alice' || !me.roles.includes('admin')) throw new Error('Unexpected seed');
console.log(`health: ${health.status}`);
console.log(`me: ${me.username} (${me.roles.join(', ')})`);
const missing = await makeClient(base).GET('/v1/me');
console.log(`without token: ${missing.response.status}`);
if (missing.response.status !== 401) throw new Error('Expected 401');
```

Expected result: `scripts/smoke.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 14. Create or replace `src/api/client.ts`
In code, create the file at this path, paste the complete contents and save. createClient<paths> checks literal paths, parameters and bodies. makeClient allows the Node smoke to reuse the same client with its own transport; the browser instance uses the token boundary. Nothing here imports React.

**File: `src/api/client.ts`**
```typescript
import createClient from 'openapi-fetch';
import type { paths } from './schema';
import { config } from '../config';
export const makeClient = (baseUrl: string, transport: typeof fetch = fetch) =>
  createClient<paths>({ baseUrl, fetch: transport });
export const api = makeClient(config.apiBaseUrl);
```

Expected result: `src/api/client.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 15. Create or replace `src/api/types.ts`
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

### Step 16. Create or replace `src/api/unwrap.ts`
In code, create the file at this path, paste the complete contents and save. openapi-fetch returns data, error and the native Response. Throwing a parsed failure makes Query and form code share one error channel. Check 304 before response.ok, because 304 has no new body. versioned preserves the exact ETag header value; a missing exposed ETag is a configuration error.

**File: `src/api/unwrap.ts`**
```typescript
import type { Versioned } from './types';
export function unwrap<T>(result: { data?: T; error?: unknown; response: Response }): T {
  if (!result.response.ok) throw new Error(`API ${result.response.status}`);
  return result.data as T;
}
export function versioned<T>(result: { data?: T; error?: unknown; response: Response }): Versioned<T> {
  const value = unwrap(result);
  const etag = result.response.headers.get('ETag');
  if (!etag) throw new Error('The API did not expose ETag.');
  return { value, etag };
}
```

Expected result: `src/api/unwrap.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 17. Create or replace `src/main.tsx`
In code, create the file at this path, paste the complete contents and save. Create one QueryClient and one root. StrictMode deliberately repeats development lifecycle checks; callbacks and boot redirects must tolerate that. Providers make auth, server state and the toast setter available without passing them through every component. Clearing the cache on user change prevents another identity seeing a previous caller?s data.

**File: `src/main.tsx`**
```tsx
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query';
import { api } from './api/client';
import { unwrap } from './api/unwrap';
import './styles.css';
function App() {
  const health = useQuery({ queryKey: ['health'], queryFn: async () => unwrap(await api.GET('/health')), retry: false });
  return <main><h1>Tasks and Teams</h1><p>Generated client ready.</p>
    <p role="status">API: {health.data?.status ?? (health.error ? health.error.message : 'checking')}</p>
    {health.error && <button onClick={() => void health.refetch()}>Try again</button>}
  </main>;
}
const queryClient = new QueryClient();
createRoot(document.getElementById('root')!).render(
  <StrictMode><QueryClientProvider client={queryClient}><App /></QueryClientProvider></StrictMode>,
);
```

Expected result: `src/main.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 18. Create or replace `src/styles.css`
In code, create the file at this path, paste the complete contents and save. Use class-based styles, visible 2px focus rings, sufficiently large targets, wrapping navigation and a responsive board. The skip link is visually hidden only until focused. Light/dark palettes and CSS icon masks follow currentColor; forced-colors retains icon visibility. No inline styles are needed by production CSP.

**File: `src/styles.css`**
```css
:root { font-family: system-ui, sans-serif; color: #17212b; background: #fff; }
body { margin: 0; }
main { max-width: 65rem; margin: auto; padding: 1rem; }
button, input, select, textarea { font: inherit; padding: .5rem; }
button, a { min-height: 24px; min-width: 24px; }
:focus-visible { outline: 2px solid #0759aa; outline-offset: 3px; }
```

Expected result: `src/styles.css` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 19. Inspect the copied `backend/.dockerignore`
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

### Step 20. Inspect the copied `backend/.env.example`
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

### Step 21. Inspect the copied `backend/Dockerfile`
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

### Step 22. Inspect the copied `backend/docker-compose.override.yml`
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

### Step 23. Inspect the copied `backend/docker-compose.yml`
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

### Step 24. Inspect the copied `backend/requirements.txt`
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

### Configuration reading guide
- `package.json`: `private` prevents accidental npm publication; `type: module` enables ESM; exact dependency strings and the lockfile make `npm ci` reproducible. `api:gen` owns generated declarations. The project TypeScript is 5.9.3 because this generator declares peer `^5.x`; Web 101's compiler version need not match.
- Both compiler projects: `target`/`lib` select syntax and browser APIs; `module: ESNext` and `moduleResolution: Bundler` match Vite; `allowImportingTsExtensions`/`resolveJsonModule`/`isolatedModules`/`verbatimModuleSyntax` avoid ambiguous transforms; `noEmit` delegates output; `strict` and `noUncheckedIndexedAccess` keep errors visible; `skipLibCheck` avoids rechecking dependency declarations. `types` differs by runtime, `include` sets boundaries, `tsBuildInfoFile` stays in node_modules/.tmp rather than the pack.
- Vite: `plugins` enables React; `host`, `port`, `strictPort` lock the registered development origin. Removing strictPort can silently break login by moving to 5174. There is no proxy to mask CORS.
- Environment: change only the three VITE_ settings for the client. The fixture's POSTGRES_DB/USER/PASSWORD/PORT configure its database and healthcheck; KEYCLOAK_ADMIN/PASSWORD/PORT configure local Keycloak; TASKS_NETWORK is the shared tasksteams-net. TASKS_APP_PASSWORD is the restricted runtime role. DATABASE_URL, PUBLIC_BASE_URL, LOG_LEVEL and ENABLE_DOCS configure the API; TOKEN_ISSUER/AUDIENCE/JWKS_URL/LEEWAY verify bearer tokens; rate/body/CORS/HSTS settings are the backend's final-phase hardening. All fixture passwords are fake, local-only.
- Backend Compose: `services` defines db/keycloak; image pins select Postgres 17 and Keycloak 26.8.2; environment substitutions come from `--env-file`; loopback `ports` prevent LAN exposure; volumes initialise schema/seed once and import the realm; healthcheck test/interval/timeout/retries/start_period let `up --wait` wait for readiness; the named network connects services; pg_data stores this lab only. The override builds the API from backend/, supplies container database/JWKS addresses, starts after a healthy DB, binds 8000, and applies restart/read_only/tmpfs/cap_drop/security_opt/pids_limit/mem_limit/cpus restrictions. The fixed network name is why we serialize runs.
- Backend Dockerfile: build a venv from wheel-only pinned requirements in a builder, copy the venv and app into a fresh matching runtime, make uid/gid 10001, expose 8000 and run uvicorn without a server header. HEALTHCHECK reads /health. Environment disables bytecode and buffering; .dockerignore removes unrelated context. This backend is a verbatim fixture, not a second implementation taught here.

### Step 25. Install, generate and build
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
🚀 contract/openapi.yaml → src/api/schema.d.ts [64.9ms]

> tasks-web-react@1.0.0 build
> tsc -b && vite build

vite v8.3.8 building client environment for production...
transforming...
✓ 64 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                   0.41 kB │ gzip:  0.27 kB
dist/assets/index-By3pcq50.css    0.28 kB │ gzip:  0.22 kB
dist/assets/index-BculUafV.js   260.46 kB │ gzip: 81.10 kB

✓ built in 184ms
```

**File: `terminal output (contract)`**
```text
contract: SHA-256 matches platform; 27 operations
```

The install emitted the real npm 11 notice `1 package has install scripts not yet covered by allowScripts:` for `esbuild@0.28.2`. Build and tsx smoke succeeded here. Review dependency scripts before approval; do not globally disable policy.

## Run it
Use one stack owner at a time. Repository verification takes the tasksteams lock itself. For **manual development**, first enter a lock-owning shell from repository root; keep all shared-port start/probe/stop commands in it:

**File: `terminal (repository root)`**
```powershell
python scripts/stack_lock.py tasksteams -- powershell -NoProfile
```

macOS/Linux: `python scripts/stack_lock.py tasksteams -- bash`. Exit that inner shell only after stopping Vite and cleanup. An extracted-pack learner not sharing this repository can omit the wrapper, but must still ensure free ports. Never leave the inner shell holding a lock after the lab.

Inside the locked shell change to `capstones/web-react/source/phase-1-setup/01-create-app/code` (or extracted code). --env-file uses fake local fixture settings without creating .env. Run:

**File: `terminal (code)`**
```powershell
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-1 up -d --build --wait --wait-timeout 420
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-1 ps
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-1 logs --tail 3 api
npm run smoke
```

Real captured stack status (age/status durations differ):

**File: `terminal output (stack status)`**
```text
NAME                                IMAGE                              COMMAND                  SERVICE    CREATED          STATUS                    PORTS
code101-react-author-1-api-1        code101-react-author-1-api         "uvicorn app.main:ap…"   api        27 seconds ago   Up 21 seconds (healthy)   127.0.0.1:8000->8000/tcp
code101-react-author-1-db-1         postgres:17-alpine                 "docker-entrypoint.s…"   db         27 seconds ago   Up 26 seconds (healthy)   127.0.0.1:5432->5432/tcp
code101-react-author-1-keycloak-1   quay.io/keycloak/keycloak:26.8.2   "/opt/keycloak/bin/k…"   keycloak   27 seconds ago   Up 26 seconds (healthy)   127.0.0.1:8180->8080/tcp
```

Real API log excerpt (timestamps/trace ids differ; no tokens):

**File: `terminal output (API logs)`**
```text
api-1  | {"time": "2026-11-23T10:27:41.438+00:00", "level": "INFO", "logger": "tasksteams.access", "message": "request", "traceId": "6c6e4fc30a4e4976a4a4f00d5fc6ed35", "method": "GET", "path": "/v1/me", "status": 200, "durationMs": 41.9, "userId": "a11ce000-0000-4000-8000-000000000001"}
api-1  | {"time": "2026-11-23T10:27:41.442+00:00", "level": "WARNING", "logger": "tasksteams.security", "message": "request refused", "traceId": "3b4d8bc1fcb243c3a90d95b8ca4a0ea2", "event": "refused", "status": 401, "method": "GET", "path": "/v1/me", "userId": null, "detail": "A bearer access token is required."}
api-1  | {"time": "2026-11-23T10:27:41.442+00:00", "level": "INFO", "logger": "tasksteams.access", "message": "request", "traceId": "3b4d8bc1fcb243c3a90d95b8ca4a0ea2", "method": "GET", "path": "/v1/me", "status": 401, "durationMs": 1.8, "userId": null}
```

Real single smoke journey:

**File: `terminal output (smoke)`**
```text
> tasks-web-react@1.0.0 smoke
> tsx scripts/smoke.ts

health: ok
me: alice (admin)
without token: 401
```

Only this Node script uses the fake password grant. Browser sign-in comes in chapter 02; do not paste credentials into a page.

Keep the backend running for a browser walkthrough; in code run:

**File: `terminal (code)`**
```powershell
npm run dev
```

The actual dev probe printed:

**File: `terminal output (dev response)`**
```text
dev: 200 on localhost:5173
```

Open http://localhost:5173. Expect Tasks and Teams, Generated client ready and API: ok. This visual description remains manual; only HTTP 200 was automated.

### Always stop and remove the lab
If Vite is running press **Ctrl+C** first. In the same locked code folder run these even if smoke failed:

**File: `terminal (code)`**
```powershell
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-1 down -v --remove-orphans
docker image rm code101-react-author-1-api
docker ps -a
docker volume ls
docker network ls
```

Captured cleanup removes containers, lab volume/network and explicitly untags the built API image:

**File: `terminal output (stack cleanup)`**
```text
Container code101-react-author-1-api-1 Stopping 
 Container code101-react-author-1-keycloak-1 Stopping 
 Container code101-react-author-1-api-1 Stopped 
 Container code101-react-author-1-api-1 Removing 
 Container code101-react-author-1-api-1 Removed 
 Container code101-react-author-1-db-1 Stopping 
 Container code101-react-author-1-db-1 Stopped 
 Container code101-react-author-1-db-1 Removing 
 Container code101-react-author-1-db-1 Removed 
 Container code101-react-author-1-keycloak-1 Stopped 
 Container code101-react-author-1-keycloak-1 Removing 
 Container code101-react-author-1-keycloak-1 Removed 
 Volume code101-react-author-1_pg_data Removing 
 Network tasksteams-net Removing 
 Volume code101-react-author-1_pg_data Removed 
 Network tasksteams-net Removed
```

**File: `terminal output (image cleanup)`**
```text
Untagged: code101-react-author-1-api:latest
Deleted: sha256:2b03daa30f608e7566cb2eaa4530edda5d79f14cb4d3f17bc04ee4e7b83d96ea
```

Exit the inner shell to release the lock. Final docker ps -a, docker volume ls and docker network ls must show no resources belonging to this project. Do not delete another task?s resources. Shared base-image caches may remain.

### Repository smoke verification
From repository root, outside the manual lock shell:

**File: `terminal (repository root)`**
```powershell
python scripts/verify_labs.py capstones/web-react/source/phase-1-setup/01-create-app
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
Boot loads main.tsx, creates Query state and asks the typed client for /health. Node smoke imports the same framework-free client and wrapper, gets a tasks-smoke token and reads /v1/me. Type parameters disappear at runtime: generation gives compile-time checks, not response validation. SHA-256 compares the contract bytes, including line endings.

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
export const pageSize = 100;
```

**File: `exercise/starter/run.ts`**
```typescript
import { pageSize } from './answer';
if (pageSize !== 25) throw new Error('Use the API default page size, 25.');
console.log('exercise: page size 25');
```

<details><summary>Solution</summary>

Replace answer.ts, save, rerun the same Node command.

**File: `exercise/solution/answer.ts`**
```typescript
export const pageSize = 25;
```

**File: `exercise/solution/run.ts`**
```typescript
import { pageSize } from './answer';
if (pageSize !== 25) throw new Error('Use the API default page size, 25.');
console.log('exercise: page size 25');
```

Real solution output:

**File: `terminal output (exercise)`**
```text
exercise: page size 25
```

</details>

## Check yourself
1. Why keep a contract copy?
   <details><summary>Answer</summary>The platform owns its bytes; a local immutable copy makes offline generation and Docker builds reproducible.</details>
2. Why TypeScript 5.9 instead of Web 101?s compiler?
   <details><summary>Answer</summary>The pinned generator declares peer ^5.x. The language ideas transfer; dependency compatibility chooses this project compiler.</details>
3. Does a typed client validate live JSON?
   <details><summary>Answer</summary>No. It checks calls at compile time. The server validates input and the client still handles HTTP failures.</details>

## Common mistakes
These strings are from real runs, not memory. The exercise error is deliberately triggered by the shipped starter.

| Captured symptom/error | Cause | Fix |
|---|---|---|
| `Error: Use the API default page size, 25.` | The starter retains its intentional wrong value/function. | Apply the solution; do not weaken the runner. |
| `src/config.ts(1,25): error TS2339: Property 'env' does not exist on type 'ImportMeta'.` | The Node compiler followed client ? config without Vite environment declarations. | Keep vite/client in tsconfig.node.json as well as the browser project. |

## Best practice
Keep remote data in a cache and compute derived presentation during rendering, rather than maintaining duplicate copies with effects. Effects here synchronize actual browser APIs such as title/focus, timers and connectivity. Source: React, [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect) (Tier 1); React, [Build a React app from Scratch](https://react.dev/learn/build-a-react-app-from-scratch) (routing, data fetching, code splitting).

## Next lesson
02. Sign in with Keycloak: Login, Callback, Dashboard, Audit log and Not found route modules; RequireAuth and RequireAdmin; in-memory OIDC users; single-flight refresh; a same-origin API token boundary.
