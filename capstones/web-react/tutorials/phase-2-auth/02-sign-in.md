---
track: capstone
level: 201
phase: 2
phase_name: auth
lesson: 02
title: "Sign in with Keycloak"
time: 300 min
prerequisites: [capstone-web-react-01]
versions: { react: "19.3.1", vite: "8.3.8", typescript: "5.9.3", react_router: "8.5.2", tanstack_query: "5.108.3", node: "26.13.1", npm: "11.20.0" }
verified: not yet run
source: capstones/web-react/source/phase-2-auth/02-sign-in/
assets: []
---

# 02. Sign in with Keycloak

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

> **Current delivery status: written (not run).** Per the updated no-execution instruction, the final verification run was stopped. Do not run builds, smoke scripts, Docker startup or servers as part of this authoring session. Commands below are deferred learner instructions. Previously captured output is historical evidence from before that instruction, not verification of this written delivery. Browser-only acceptance remains manual.

## Why it matters
A login redirect is like collecting a ticket from a staffed desk; the app never asks for the password itself. PKCE ties the ticket to the browser that requested it. Memory-only tokens reduce persistence after an injected script, but do not make an active XSS attack harmless.

## What you will build
Login, Callback, Dashboard, Audit log and Not found route modules; RequireAuth and RequireAdmin; in-memory OIDC users; single-flight refresh; a same-origin API token boundary. The smoke checks the actual Keycloak login page but does not type into it.

Requirements: **W-06 to W-12**. Chapter numbering, phase names and screen names match the approved React/Angular plan. This is a long capstone workshop, not a 20-minute language lesson.

## Before you start
- Finish Web 101 forms, CSS layout, TypeScript, modules and fetch. Read the platform contract and Keycloak chapters. Keep [TDD.md](../../TDD.md) beside you; platform TDD section 12.1 Decision is authoritative when v1 OpenAPI omits a runtime case.
- Node 26.13.1, npm 11.20.0, Docker Desktop (Linux containers), Python for repository verification/locking. After installation close/reopen the terminal. Official references and pins: [REFERENCES.md](../../REFERENCES.md).
- Download `web-react-phase-2-auth.zip`. Windows: right-click ? Extract All; macOS: double-click; Linux: `unzip web-react-phase-2-auth.zip`. Open `02-sign-in/code` inside the extracted phase folder. Each pack contains the **whole app**, not a patch. Do not copy node_modules or dist from another phase.
- Open PowerShell in `code` (the prompt path must end in `02-sign-in\code`). Recover with `Set-Location 'F:\Projects\Uee03\Code101\capstones\web-react\source\phase-2-auth\02-sign-in\code'` in this repository. macOS/Linux: `cd /path/to/Code101/capstones/web-react/source/phase-2-auth/02-sign-in/code`. Substitute your clone location once, not the relative file names.
- Save files before running (an editor tab dot means unsaved). All text is UTF-8 without BOM; PowerShell 5.1 Set-Content -Encoding utf8 adds a BOM, so use your editor.
- Ports 5432, 8180, 8000 and 5173 must be free. Do not stop another agent's stack. Keycloak readiness timeout is **420 seconds**.
- `backend/` is a **verbatim copy** of `capstones/backend-python/source/phase-5-hardening/05-hardening/code/`. Its Compose files start Postgres, Keycloak and Python API. This is a smoke fixture, not a second implementation. Use any other conformant backend on 8000 after stopping it.

## Steps
### Step 1. Prepare the working copy and preserve the contract
The extracted pack is the fastest route. A scratch author must create the same `code` directory and every file below. Do not start Vite until all files and the contract are present. Commands are PowerShell 5.1 compatible.

Continuing? New or changed files: `scripts/smoke-auth.ts`, `scripts/smoke.ts`, `src/api/client.ts`, `src/auth/RequireAdmin.tsx`, `src/auth/RequireAuth.tsx`, `src/auth/auth-middleware.ts`, `src/auth/oidc-config.ts`, `src/auth/safe-route.ts`, `src/auth/token-gate.ts`, `src/auth/user-manager.ts`, `src/hooks/me.ts`, `src/main.tsx`, `src/pages/Audit.tsx`, `src/pages/Callback.tsx`, `src/pages/Dashboard.tsx`, `src/pages/Login.tsx`, `src/pages/NotFound.tsx`, `src/router.tsx`. To avoid missing context, **every authored file is shown in full**, including unchanged files; there are no omitted edit regions. Or start from this phase pack.

For a scratch copy inside the repository, open a second terminal at the repository root and copy upstream bytes, never edit them:

**File: `terminal (repository root)`**
```powershell
$dest = 'capstones/web-react/source/phase-2-auth/02-sign-in/code'
New-Item -ItemType Directory -Force "$dest/contract", "$dest/backend" | Out-Null
Copy-Item 'capstones/platform/source/phase-4-conformance/04-conformance-script/code/openapi.yaml' "$dest/contract/openapi.yaml"
Copy-Item 'capstones/backend-python/source/phase-5-hardening/05-hardening/code/*' "$dest/backend" -Recurse -Force
Copy-Item 'capstones/backend-python/source/phase-5-hardening/05-hardening/code/.env.example' "$dest/backend/.env.example"
Copy-Item 'capstones/backend-python/source/phase-5-hardening/05-hardening/code/.dockerignore' "$dest/backend/.dockerignore"
```

macOS/Linux, repository root:

**File: `terminal (repository root)`**
```bash
dest='capstones/web-react/source/phase-2-auth/02-sign-in/code'
mkdir -p "$dest/contract" "$dest/backend"
cp capstones/platform/source/phase-4-conformance/04-conformance-script/code/openapi.yaml "$dest/contract/openapi.yaml"
cp -R capstones/backend-python/source/phase-5-hardening/05-hardening/code/. "$dest/backend/"
```

Expected result: contract/openapi.yaml and the complete backend fixture exist. Return to your `code` terminal. Do not copy a running backend's .env, build products or caches. The supplied pack excludes them.

**Disclosed text-check exclusions:** generated package-lock.json and src/api/schema.d.ts are in skip_lesson_check. The immutable upstream contract, upstream backend implementation/data/realm, and copied CC0 icon/licence files are also excluded **because they are copied, not authored here**; verify.json enumerates every path. Backend Docker/Compose/environment configurations are nevertheless shown in full below. Every authored app file, including smoke scripts, is shown. Regenerate types, never hand-edit them; recopy upstream bytes, never locally ?fix? the contract.

Create these folders in code. Existing folders are harmless; Out-Null suppresses folder-table output.

**File: `terminal (code)`**
```powershell
New-Item -ItemType Directory -Force 'scripts', 'src', 'src/api', 'src/auth', 'src/hooks', 'src/pages' | Out-Null
```

**File: `terminal (code, macOS/Linux)`**
```bash
mkdir -p scripts src src/api src/auth src/hooks src/pages
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

### Step 17. Create or replace `src/auth/RequireAdmin.tsx`
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

### Step 18. Create or replace `src/auth/RequireAuth.tsx`
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

### Step 19. Create or replace `src/auth/auth-middleware.ts`
In code, create the file at this path, paste the complete contents and save. Compare parsed origins and the configured API path boundary before attaching a bearer header; never use startsWith on the whole URL. Clone Request before fetch consumes its body. A 401 gets exactly one renew and retry, never recursive middleware. Phase 4 owns the single GET-only 429 retry here, so Query must not also retry 429.

**File: `src/auth/auth-middleware.ts`**
```typescript
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
    const retry = request.clone();
    let response = await transport(request);
    if (response.status === 401) {
      try {
        retry.headers.set('Authorization', `Bearer ${await renew()}`);
        response = await transport(retry);
      } catch { await endSession(); return response; }
      if (response.status === 401) await endSession();
    }
    return response;
  };
}
```

Expected result: `src/auth/auth-middleware.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 20. Create or replace `src/auth/oidc-config.ts`
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

### Step 21. Create or replace `src/auth/safe-route.ts`
In code, create the file at this path, paste the complete contents and save. Reject absolute URLs, protocol-relative // URLs, backslashes and control characters. A return route must stay inside this origin; otherwise navigation falls back to /. This prevents turning the login callback into an open redirect.

**File: `src/auth/safe-route.ts`**
```typescript
export function safeRoute(value: unknown): string {
  return typeof value === 'string' && value.startsWith('/') && !value.startsWith('//')
    && !value.includes('\\') && !/[\r\n]/.test(value) ? value : '/';
}
```

Expected result: `src/auth/safe-route.ts` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 22. Create or replace `src/auth/token-gate.ts`
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

### Step 23. Create or replace `src/auth/user-manager.ts`
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

### Step 24. Create or replace `src/hooks/me.ts`
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

### Step 25. Create or replace `src/main.tsx`
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
import './styles.css';
const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
manager.events.addUserUnloaded(() => queryClient.clear());
manager.events.addUserLoaded(() => { queryClient.clear(); });
createRoot(document.getElementById('root')!).render(
  <StrictMode><AuthProvider userManager={manager} onSigninCallback={onSigninCallback}>
    <QueryClientProvider client={queryClient}><RouterProvider router={router} /></QueryClientProvider>
  </AuthProvider></StrictMode>,
);
```

Expected result: `src/main.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 26. Create or replace `src/pages/Audit.tsx`
In code, create the file at this path, paste the complete contents and save. Guard before mounting the audit query. Filters for entity type, actor and date range produce new cursor keys. Render escaped text, semantic table headers and locally formatted instants; wide tables scroll inside their own wrapper rather than the whole page.

**File: `src/pages/Audit.tsx`**
```tsx
import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { unwrap } from '../api/unwrap';
export function Component() {
  const audit = useQuery({ queryKey: ['audit'], queryFn: async () => unwrap(await api.GET('/v1/audit-log')), retry: false });
  return <section><h1>Audit log</h1>{audit.error && <p role="alert">{audit.error.message}</p>}
    <ul>{audit.data?.items.map(entry => <li key={entry.id}>{entry.action} {entry.entityType}</li>)}</ul>
  </section>;
}
```

Expected result: `src/pages/Audit.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 27. Create or replace `src/pages/Callback.tsx`
In code, create the file at this path, paste the complete contents and save. Show Signing you in while AuthProvider exchanges the code. Success navigates to the already-sanitized saved route. Failure removes the callback payload from history and offers Return to Login; never echo a token.

**File: `src/pages/Callback.tsx`**
```tsx
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
  return <section><h1>Callback</h1>{auth.error
    ? <><p role="alert">{auth.error.message}</p><Link to="/login">Return to Login</Link></>
    : <p role="status">Signing you in</p>}</section>;
}
```

Expected result: `src/pages/Callback.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 28. Create or replace `src/pages/Dashboard.tsx`
In code, create the file at this path, paste the complete contents and save. Show caller, roles and scopes from me, memberships from me.teams, visible teams from listTeams and a health chip from getHealth. Separate query keys keep a public health failure from replacing authenticated user state.

**File: `src/pages/Dashboard.tsx`**
```tsx
import { useMe } from '../hooks/me';
export function Component() {
  const me = useMe();
  return <section><h1>Dashboard</h1><p role="status">{me.data ? `Hello, ${me.data.displayName}` : 'Loading caller'}</p>
    {me.error && <p role="alert">{me.error.message}</p>}
    <p>Roles: {me.data?.roles.join(', ')}</p><p>Scopes: {me.data?.scopes.join(', ')}</p>
  </section>;
}
```

Expected result: `src/pages/Dashboard.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 29. Create or replace `src/pages/Login.tsx`
In code, create the file at this path, paste the complete contents and save. Show a real Sign in button, not username/password fields. A ref prevents duplicate boot redirects. The optional ts.hint flag requests silent SSO re-entry after reload; an error clears it and stays visible. safeRoute validates both query and callback state.

**File: `src/pages/Login.tsx`**
```tsx
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
  return <section><h1>Login</h1><p>Sign in with the Tasks and Teams Keycloak realm.</p>
    {auth.error && <p role="alert">{auth.error.message}</p>}
    <button disabled={auth.isLoading || !!auth.activeNavigator} onClick={() => {
      localStorage.removeItem('ts.hint'); void auth.signinRedirect({ state: { returnTo } });
    }}>Sign in</button><p><Link to="/">Home</Link></p>
  </section>;
}
```

Expected result: `src/pages/Login.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 30. Create or replace `src/pages/NotFound.tsx`
In code, create the file at this path, paste the complete contents and save. Use neutral wording and a Home link. A missing page and an inaccessible API object should never turn into an existence oracle.

**File: `src/pages/NotFound.tsx`**
```tsx
import { Link } from 'react-router';
export function Component() {
  return <section><h1>Not found</h1><p>This page is not available.</p><Link to="/">Home</Link></section>;
}
```

Expected result: `src/pages/NotFound.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 31. Create or replace `src/router.tsx`
In code, create the file at this path, paste the complete contents and save. Create the data router once outside React state. Layout routes put guards around their children. lazy imports return named Component exports, so screens are split into separate chunks. The shell supplies landmarks and the first-tab-stop skip link; API permission checks remain authoritative.

**File: `src/router.tsx`**
```tsx
import { createBrowserRouter, Link, Outlet } from 'react-router';
import { RequireAuth } from './auth/RequireAuth';
import { RequireAdmin } from './auth/RequireAdmin';
import { signOut } from './auth/user-manager';
function Shell() {
  return <><header><nav aria-label="Main"><Link to="/">Dashboard</Link> <Link to="/admin/audit">Audit log</Link>
    <button onClick={() => void signOut()}>Sign out</button></nav></header><main><Outlet /></main></>;
}
export const router = createBrowserRouter([
  { element: <Shell />, children: [
    { path: '/login', lazy: () => import('./pages/Login') },
    { path: '/auth/callback', lazy: () => import('./pages/Callback') },
    { element: <RequireAuth />, children: [
      { index: true, lazy: () => import('./pages/Dashboard') },
      { element: <RequireAdmin />, children: [{ path: '/admin/audit', lazy: () => import('./pages/Audit') }] },
    ] },
    { path: '*', lazy: () => import('./pages/NotFound') },
  ] },
]);
```

Expected result: `src/router.tsx` is saved exactly as shown. Imports resolve after generation/install; finish all files before running.

### Step 32. Create or replace `src/styles.css`
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

### Step 33. Inspect the copied `backend/.dockerignore`
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

### Step 34. Inspect the copied `backend/.env.example`
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

### Step 35. Inspect the copied `backend/Dockerfile`
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

### Step 36. Inspect the copied `backend/docker-compose.override.yml`
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

### Step 37. Inspect the copied `backend/docker-compose.yml`
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

### Step 38. Inspect the copied `backend/requirements.txt`
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

### Step 39. Install, generate and build
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
🚀 contract/openapi.yaml → src/api/schema.d.ts [58.5ms]

> tasks-web-react@1.0.0 build
> tsc -b && vite build

vite v8.3.8 building client environment for production...
transforming...
✓ 164 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                        0.49 kB │ gzip:   0.30 kB
dist/assets/index-By3pcq50.css         0.28 kB │ gzip:   0.22 kB
dist/assets/NotFound-ChvAS9hD.js       0.30 kB │ gzip:   0.22 kB
dist/assets/Audit-DWYjrBvS.js          0.48 kB │ gzip:   0.33 kB
dist/assets/Dashboard-C3NB4q_V.js      0.50 kB │ gzip:   0.30 kB
dist/assets/Callback-BRmEN_E9.js       0.66 kB │ gzip:   0.40 kB
dist/assets/Login-DBxxeYJB.js          1.01 kB │ gzip:   0.56 kB
dist/assets/jsx-runtime-DyZJNswf.js    8.78 kB │ gzip:   3.33 kB
dist/assets/index-lmiLPcPB.js        424.95 kB │ gzip: 129.26 kB

✓ built in 228ms
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

Inside the locked shell change to `capstones/web-react/source/phase-2-auth/02-sign-in/code` (or extracted code). --env-file uses fake local fixture settings without creating .env. Run:

**File: `terminal (code)`**
```powershell
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-2 up -d --build --wait --wait-timeout 420
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-2 ps
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-2 logs --tail 3 api
npm run smoke
```

Real captured stack status (age/status durations differ):

**File: `terminal output (stack status)`**
```text
NAME                                IMAGE                              COMMAND                  SERVICE    CREATED          STATUS                    PORTS
code101-react-author-2-api-1        code101-react-author-2-api         "uvicorn app.main:ap…"   api        30 seconds ago   Up 24 seconds (healthy)   127.0.0.1:8000->8000/tcp
code101-react-author-2-db-1         postgres:17-alpine                 "docker-entrypoint.s…"   db         30 seconds ago   Up 29 seconds (healthy)   127.0.0.1:5432->5432/tcp
code101-react-author-2-keycloak-1   quay.io/keycloak/keycloak:26.8.2   "/opt/keycloak/bin/k…"   keycloak   30 seconds ago   Up 29 seconds (healthy)   127.0.0.1:8180->8080/tcp
```

Real API log excerpt (timestamps/trace ids differ; no tokens):

**File: `terminal output (API logs)`**
```text
api-1  | {"time": "2026-11-23T10:28:27.665+00:00", "level": "INFO", "logger": "tasksteams.access", "message": "request", "traceId": "f0945683c80c4fe28c0f4c276f727724", "method": "GET", "path": "/v1/me", "status": 200, "durationMs": 44.9, "userId": "a11ce000-0000-4000-8000-000000000001"}
api-1  | {"time": "2026-11-23T10:28:27.669+00:00", "level": "WARNING", "logger": "tasksteams.security", "message": "request refused", "traceId": "396dfe25cc5e4105a9b812954784db08", "event": "refused", "status": 401, "method": "GET", "path": "/v1/me", "userId": null, "detail": "A bearer access token is required."}
api-1  | {"time": "2026-11-23T10:28:27.669+00:00", "level": "INFO", "logger": "tasksteams.access", "message": "request", "traceId": "396dfe25cc5e4105a9b812954784db08", "method": "GET", "path": "/v1/me", "status": 401, "durationMs": 1.7, "userId": null}
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

### Always stop and remove the lab
If Vite is running press **Ctrl+C** first. In the same locked code folder run these even if smoke failed:

**File: `terminal (code)`**
```powershell
docker compose --env-file backend/.env.example -f backend/docker-compose.yml -f backend/docker-compose.override.yml -p code101-react-author-2 down -v --remove-orphans
docker image rm code101-react-author-2-api
docker ps -a
docker volume ls
docker network ls
```

Captured cleanup removes containers, lab volume/network and explicitly untags the built API image:

**File: `terminal output (stack cleanup)`**
```text
Container code101-react-author-2-api-1 Stopping 
 Container code101-react-author-2-keycloak-1 Stopping 
 Container code101-react-author-2-api-1 Stopped 
 Container code101-react-author-2-api-1 Removing 
 Container code101-react-author-2-api-1 Removed 
 Container code101-react-author-2-db-1 Stopping 
 Container code101-react-author-2-db-1 Stopped 
 Container code101-react-author-2-db-1 Removing 
 Container code101-react-author-2-db-1 Removed 
 Container code101-react-author-2-keycloak-1 Stopped 
 Container code101-react-author-2-keycloak-1 Removing 
 Container code101-react-author-2-keycloak-1 Removed 
 Network tasksteams-net Removing 
 Volume code101-react-author-2_pg_data Removing 
 Volume code101-react-author-2_pg_data Removed 
 Network tasksteams-net Removed
```

**File: `terminal output (image cleanup)`**
```text
Untagged: code101-react-author-2-api:latest
Deleted: sha256:2d7e5d38056ce09793fedee17e9c9c937aa4c40ba81842c199c065fade94fa01
```

Exit the inner shell to release the lock. Final docker ps -a, docker volume ls and docker network ls must show no resources belonging to this project. Do not delete another task?s resources. Shared base-image caches may remain.

### Repository smoke verification
From repository root, outside the manual lock shell:

**File: `terminal (repository root)`**
```powershell
python scripts/verify_labs.py capstones/web-react/source/phase-2-auth/02-sign-in
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
AuthProvider handles callback payloads; a single UserManager owns memory users and expiry events. The token gate serializes refresh; the transport scopes tokens to one API origin/path and retries a 401 only once. RequireAdmin reads me and requests an optional scope without treating scope as a role. A BFF with HttpOnly cookies would further reduce token exposure, but is a different server architecture.

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
export const safeReturn = (value: string) => value;
```

**File: `exercise/starter/run.ts`**
```typescript
import { safeReturn } from './answer';
if (safeReturn('//foreign.invalid') !== '/') throw new Error('Reject protocol-relative URLs.');
console.log('exercise: external return rejected');
```

<details><summary>Solution</summary>

Replace answer.ts, save, rerun the same Node command.

**File: `exercise/solution/answer.ts`**
```typescript
export const safeReturn = (value: string) => value.startsWith('/') && !value.startsWith('//') && !value.includes('\\') ? value : '/';
```

**File: `exercise/solution/run.ts`**
```typescript
import { safeReturn } from './answer';
if (safeReturn('//foreign.invalid') !== '/') throw new Error('Reject protocol-relative URLs.');
console.log('exercise: external return rejected');
```

Real solution output:

**File: `terminal output (exercise)`**
```text
exercise: external return rejected
```

</details>

## Check yourself
1. Which store contains tokens?
   <details><summary>Answer</summary>Only InMemoryWebStorage behind userStore. sessionStorage holds transient redirect state; ts.hint is a non-secret localStorage flag.</details>
2. Why single-flight refresh?
   <details><summary>Answer</summary>Refresh rotation can reject parallel use of the same refresh token. Both expiry and 401 paths share one promise.</details>
3. Does tasks:admin make bob an admin?
   <details><summary>Answer</summary>No. Effective permission is role intersected with scope; the backend still refuses bob.</details>
4. What did smoke:auth not prove?
   <details><summary>Answer</summary>A human sign-in, callback navigation, storage inspection, logout and real six-minute renewal remain manual.</details>

## Common mistakes
These strings are from real runs, not memory. The exercise error is deliberately triggered by the shipped starter.

| Captured symptom/error | Cause | Fix |
|---|---|---|
| `Error: Reject protocol-relative URLs.` | The starter retains its intentional wrong value/function. | Apply the solution; do not weaken the runner. |
| `without token: 401` | The real anonymous /v1/me call was refused intentionally. | Sign in through tasks-web; never paste the smoke password flow into React. |

## Best practice
Keep remote data in a cache and compute derived presentation during rendering, rather than maintaining duplicate copies with effects. Effects here synchronize actual browser APIs such as title/focus, timers and connectivity. Source: React, [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect) (Tier 1); React, [Build a React app from Scratch](https://react.dev/learn/build-a-react-app-from-scratch) (routing, data fetching, code splitting).

## Next lesson
03. Screens, queries and pagination: The same ten screens as web-angular: Login, Callback, Dashboard, Teams, Team detail, Projects, Tasks, Task detail, Audit log, Not found.
