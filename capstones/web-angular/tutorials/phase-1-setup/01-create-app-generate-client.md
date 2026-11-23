---
track: capstone
level: 201
phase: 1
phase_name: setup
lesson: 01
title: "Create the app, generate the client"
time: 3 h
prerequisites: [web-101, capstone-platform-01, capstone-platform-03]
versions: { angular: "22.3.0", cli: "22.3.0", node: "26.13.1", npm: "11.20.0", typescript: "6.0.3", rxjs: "7.8.2", ng-openapi-gen: "1.1.0", angular-oauth2-oidc: "22.0.2", tsx: "4.23.15" }
verified: not yet run
source: capstones/web-angular/source/phase-1-setup/01-create-app-generate-client/
assets: []
---

# 01. Create the app, generate the client

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

> **Authoring status: written (not run).** Runtime verification was stopped at the user's request. The captured terminal excerpts below are historical evidence from before that pause, not a current PASS claim. Build/server/Docker commands are instructions for a future learner run; none were executed after the pause. Browser-only acceptance remains manual.


## Why it matters
A generated client is like a translator printed from the same dictionary the server uses. You learn the boundary before adding screens: the platform owns the contract, while this application owns presentation. Changing backends must not require rewriting HTTP calls.

## What you will build
Phase 1: **Setup and generated client**. Requirements **W-01 to W-05**. This pack is the whole application, not a patch. Chapter numbers and final screen names match web-react. Smoke verification proves that the environment works and code runs once; it is not browser sign-in, unit testing, linting or a WCAG audit.

## Before you start
- Finish Web 101 lessons 03, 06, 07, 10 and 11. Read platform chapters 01/03. Have Node 26.13.1, npm 11.20.0, Python 3.10+ and Docker Desktop (Linux containers) running. Node's official download supplies npm; reopen your terminal after installation. No global Angular CLI.
- Open a terminal in your Code101 clone. These Windows commands are PowerShell 5.1 compatible. Example clone: F:/Projects/Uee03/Code101; substitute yours. The path before the terminal prompt tells you the current directory. Recovery: Set-Location 'F:/Projects/Uee03/Code101'.
- Source pack: web-angular-phase-1-setup.zip. Windows: right-click, Extract All. macOS: double-click. Linux: unzip web-angular-phase-1-setup.zip. Open 01-create-app-generate-client/code, not the zip viewer. An extracted pack already contains the copied contract/backend fixture; repo-relative copy/lock commands below apply to the clone.
- Use **localhost** in the browser, because the issuer is http://localhost:8180/realms/tasksteams. Free 4200/8000/8180/5432; run one Tasks and Teams stack at a time. Do not stop another agent's project. Shipping smoke additionally owns 8200 temporarily.
- An editor tab dot means unsaved changes. Save each file as UTF-8 **without BOM** before running. Windows PowerShell 5.1 Set-Content -Encoding utf8 would add a BOM; use your editor.

## Steps
### Step 1. Open the phase or scaffold the workspace
For a finished pack open code and continue to Step 2. To author from scratch, run from the clone root (npx downloads this exact CLI, never globally):

**Command: clone root, new workspace only**
```powershell
$env:NG_CLI_ANALYTICS='false'
npx --yes -p @angular/cli@22.3.0 ng new web-angular --directory capstones/web-angular/source/phase-1-setup/01-create-app-generate-client/code --routing --style=css --ssr=false --skip-git --skip-tests --skip-install --package-manager=npm --defaults
```
The captured scaffold created angular.json, package.json, tsconfig.json, tsconfig.app.json, src/main.ts, src/index.html and default App. From the newly created code folder delete only these demo/editor files before replacing the workspace below:

**Command: new code folder only**
```powershell
Set-Location 'capstones/web-angular/source/phase-1-setup/01-create-app-generate-client/code'
Remove-Item README.md,.prettierrc,.editorconfig,tsconfig.spec.json,public/favicon.ico,src/app/app.html,src/app/app.css -ErrorAction SilentlyContinue
Remove-Item .vscode -Recurse -Force -ErrorAction SilentlyContinue
```
macOS/Linux: same npx command (omit $env line or prefix NG_CLI_ANALYTICS=false); deletion is `rm -rf README.md .prettierrc .editorconfig tsconfig.spec.json public/favicon.ico src/app/app.html src/app/app.css .vscode`. Angular 22 requires TypeScript 6.0.x even though Web 101 used 7.0.2; do not copy that compiler pin.

**Command: clone root -> this phase code**
```powershell
Set-Location 'F:/Projects/Uee03/Code101'
Set-Location 'capstones/web-angular/source/phase-1-setup/01-create-app-generate-client/code'
```
On macOS/Linux: `cd /path/to/Code101/capstones/web-angular/source/phase-1-setup/01-create-app-generate-client/code`. All remaining relative paths are based here unless stated otherwise.
### Step 2. Copy immutable inputs, not another implementation
From code recover the clone root and copy the upstream fixture. Skip copying only when these exact bytes already came from the phase zip.

**Command: code folder, upstream copies**
```powershell
$repo = (Resolve-Path '../../../../../..').Path
$backend = Join-Path $repo 'capstones/backend-python/source/phase-5-hardening/05-hardening/code'
New-Item -ItemType Directory -Force contract,smoke-backend | Out-Null
Copy-Item (Join-Path $repo 'capstones/platform/source/phase-4-conformance/04-conformance-script/code/openapi.yaml') contract/openapi.yaml
'app','db','keycloak','Dockerfile','.dockerignore','.env.example','requirements.txt','docker-compose.yml','docker-compose.override.yml' | ForEach-Object { Copy-Item (Join-Path $backend $_) smoke-backend -Recurse -Force }
```

**Command: code folder, macOS/Linux**
```bash
repo=$(cd ../../../../../.. && pwd)
backend="$repo/capstones/backend-python/source/phase-5-hardening/05-hardening/code"
mkdir -p contract smoke-backend
cp "$repo/capstones/platform/source/phase-4-conformance/04-conformance-script/code/openapi.yaml" contract/openapi.yaml
for name in app db keycloak Dockerfile .dockerignore .env.example requirements.txt docker-compose.yml docker-compose.override.yml; do cp -R "$backend/$name" smoke-backend/; done
```
Never fix a generator warning by editing the contract. Reproduce its hash below; compare both copies with Get-FileHash, sha256sum on Linux or shasum -a 256 on macOS.

**Command: code folder, all OS shells**
```powershell
python -c "from pathlib import Path; import hashlib; print(hashlib.sha256(Path('contract/openapi.yaml').read_bytes()).hexdigest())"
```

**Captured SHA-256**
```text
f3a19841f551f01ef358582a1f5eba64b722d30f775201c1f5c6271d054f6ee4
```
The copied contract, package-lock.json and generated src/app/api files are explicitly in **skip_lesson_check**: they are large inputs/generated files, not handwritten snippets. Copy the contract exactly as above. Regenerate the lockfile with `npm install --package-lock-only --no-audit --no-fund` after writing the manifest below. Captured regeneration output:

**Captured output (excerpt)**
```text

up to date in 2s
```
After writing files below: npm ci installs the lock, npm run api:gen regenerates the client. prebuild/prestart regenerate automatically too. Generated API code is git-ignored and not shipped; contract and lockfile ARE shipped. Its operation-count output appears in the real build capture.
Configuration reading guide (all configuration is shown in full below):

| Setting | Meaning; effect of changing it |
|---|---|
| package name/version/private | Local identity; private prevents accidental publication. Exact dependencies and lockfile pin the toolchain. |
| api:gen/prebuild/prestart/build/start/smoke | Generation before compile/serve; local ng builds/serves and tsx runs the Node scenario. Removing hooks risks a stale client. |
| angular $schema/version/cli | CLI schema format, workspace version, npm selection, analytics disabled. |
| newProjectRoot/projectType/root/sourceRoot/prefix | Additional projects folder, application kind, workspace/source roots and selector prefix. Move paths only with their files. |
| schematics skipTests | Do not generate .spec.ts boilerplate; no test target/suite/linter is used. |
| builder/browser/tsConfig/assets/styles | Application builder, main entry, compiler options, public-folder glob and global CSS. **/* copies icon subdirectories. |
| production budgets/outputHashing | Raw-size warning/error thresholds and hashed output names. Raw-size budgets are NOT gzip measurements; see captured Estimated transfer size. |
| development optimization/extractLicenses/sourceMap/fileReplacements | Debug output and development environment replacement. Production remains optimized. |
| serve builder/buildTarget/defaultConfiguration | Dev-server builder and matching configuration; npm start explicitly binds localhost:4200. |
| compileOnSave/compilerOptions | Builds run through CLI, not an editor save. noImplicitOverride demands override; noPropertyAccessFromIndexSignature demands bracket access; noImplicitReturns/noFallthroughCasesInSwitch catch missing control-flow branches. |
| skipLibCheck/isolatedModules/experimentalDecorators/importHelpers | Skip library declaration checking, independently transpile modules, enable Angular decorators, share helpers via tslib. |
| target/module | ES2022 language target and preserved modules for the bundler. Do not change these to hide a peer-version mismatch. |
| angularCompilerOptions/files/references | No legacy i18n IDs; validate injectable parameters and input access. Root files [] references the app compiler project. |
| tsconfig.app extends/types/include/exclude | Inherit root flags; no ambient Node browser globals; include src TypeScript; exclude spec files. Scripts run separately in tsx. |
| generator input/output/apiService/promises/services | Immutable contract -> src/app/api; Api service; Promises; no per-tag wrappers. $schema enables editor validation. |
| environment apiBaseUrl/issuer/clientId/scopes | Public compile-time API origin, exact issuer, public tasks-web id and base scopes, not credentials. The dev replacement starts with identical defaults. |
| .gitignore | Omit dependencies, build/cache, generated api, local .env and logs; keep package-lock.json. |

### Borrowed smoke backend configuration
These files are verbatim from backend-python's final phase, not another API implementation. All configs are repeated so nothing is hidden. Python/database/realm implementation files are inherited dependencies already taught in their capstones; they are explicitly listed in skip_lesson_check, not newly authored code. Do not edit them.

| Directive group | Meaning; effect of changing it |
|---|---|
| .env POSTGRES_*, KEYCLOAK_ADMIN*, KEYCLOAK_PORT, TASKS_NETWORK | Fake local DB/admin credentials, bootstrap admin and public port/issuer, shared network name. Never use these in production. |
| TASKS_APP_PASSWORD/DATABASE_URL | Limited database-role password and host development URL; Compose overrides the host with db. |
| TOKEN_ISSUER/TOKEN_AUDIENCE/JWKS_URL/TOKEN_LEEWAY_SECONDS | Exact iss, allowed aud, signing keys, clock skew. Container JWKS uses keycloak:8080, not localhost. |
| LOG_LEVEL/PUBLIC_BASE_URL/ENABLE_DOCS | Log verbosity, public API URL and docs toggle; container docs are disabled by the override. |
| RATE_LIMIT_*/MAX_BODY_BYTES/CORS_ORIGINS/ENABLE_HSTS | Request budgets/window, 1 MiB cap, exact 4200/5173 origins, local HTTP HSTS off. Broader CORS cannot fix a wrong issuer. |
| db image/environment/ports/volumes | Pinned Postgres, .env variables, loopback-only publish; pg_data stores data and schema/seed/scripts are read-only bind mounts. |
| db healthcheck | pg_isready uses container variables ($$ escapes Compose substitution), 3s interval/timeout, 30 retries, 5s grace. |
| keycloak image/command/environment | Pinned Keycloak, start-dev and first-import realm, public hostname/dynamic backchannel/management health. start-dev is not production. |
| keycloak ports/volumes/healthcheck | Loopback 8180 -> 8080, read-only realm, bash TCP management probe on 9000. 5s interval/timeout, 60 retries, 30s grace accommodate first boot. |
| networks/pg_data | Both services join explicitly named tasksteams-net; the project owns its volume. The tasksteams lock prevents collision. |
| override api build/environment/depends_on/ports/networks/restart | Build copied Dockerfile, limited DB/internal JWKS settings, wait for db, loopback 8000, shared network, restart until removed. All settings are visible in full below. |
| read_only/tmpfs/cap_drop/security_opt/pids_limit/mem_limit/cpus | Read-only filesystem, writable /tmp, no Linux capabilities, no privilege escalation, 200-process/256 MiB/1 CPU limits. Removing them weakens isolation. |
| Python Dockerfile syntax/FROM/ENV/RUN/COPY | BuildKit syntax; pinned builder/runtime; no pip cache/version check; wheel-only virtualenv; copy only it and app code to runtime. |
| runtime user/WORKDIR/EXPOSE/HEALTHCHECK/CMD | UID/GID 10001, /srv, documented 8000, HTTP probe and uvicorn bound inside the container. Host exposure belongs to Compose. |
| copied .dockerignore/requirements.txt | Exclude local env, database/realm/scripts/build metadata from the API build context. Exact Python pins belong to the fixture, not this web lesson. |

### Step 3. Workspace and public environment
Create the concrete parent directories (silent on success), then create/replace every named file below in your editor. Save after each file; do not type the markdown fences.

**Command: code folder, parent directories**
```powershell
New-Item -ItemType Directory -Force 'src/environments' | Out-Null
```

**Command: code folder, macOS/Linux**
```bash
mkdir -p src/environments
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `.gitignore`**
```text
node_modules/
dist/
.angular/
src/app/api/
.env
*.log
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `angular.json`**
```jsonc
{
  "$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "cli": {
    "packageManager": "npm",
    "analytics": false
  },
  "newProjectRoot": "projects",
  "projects": {
    "web-angular": {
      "projectType": "application",
      "schematics": {
        "@schematics/angular:class": {
          "skipTests": true
        },
        "@schematics/angular:component": {
          "skipTests": true
        },
        "@schematics/angular:directive": {
          "skipTests": true
        },
        "@schematics/angular:guard": {
          "skipTests": true
        },
        "@schematics/angular:interceptor": {
          "skipTests": true
        },
        "@schematics/angular:pipe": {
          "skipTests": true
        },
        "@schematics/angular:resolver": {
          "skipTests": true
        },
        "@schematics/angular:service": {
          "skipTests": true
        }
      },
      "root": "",
      "sourceRoot": "src",
      "prefix": "app",
      "architect": {
        "build": {
          "builder": "@angular/build:application",
          "options": {
            "browser": "src/main.ts",
            "tsConfig": "tsconfig.app.json",
            "assets": [
              {
                "glob": "**/*",
                "input": "public"
              }
            ],
            "styles": [
              "src/styles.css"
            ]
          },
          "configurations": {
            "production": {
              "budgets": [
                {
                  "type": "initial",
                  "maximumWarning": "500kB",
                  "maximumError": "1MB"
                },
                {
                  "type": "anyComponentStyle",
                  "maximumWarning": "4kB",
                  "maximumError": "8kB"
                }
              ],
              "outputHashing": "all"
            },
            "development": {
              "optimization": false,
              "extractLicenses": false,
              "sourceMap": true,
              "fileReplacements": [
                {
                  "replace": "src/environments/environment.ts",
                  "with": "src/environments/environment.development.ts"
                }
              ]
            }
          },
          "defaultConfiguration": "production"
        },
        "serve": {
          "builder": "@angular/build:dev-server",
          "configurations": {
            "production": {
              "buildTarget": "web-angular:build:production"
            },
            "development": {
              "buildTarget": "web-angular:build:development"
            }
          },
          "defaultConfiguration": "development"
        }
      }
    }
  }
}
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `ng-openapi-gen.json`**
```jsonc
{
  "$schema": "./node_modules/ng-openapi-gen/ng-openapi-gen-schema.json",
  "input": "contract/openapi.yaml",
  "output": "src/app/api",
  "apiService": "Api",
  "promises": true,
  "services": false
}
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `package.json`**
```jsonc
{
  "name": "web-angular",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "api:gen": "ng-openapi-gen && node scripts/generated-summary.mjs",
    "prebuild": "npm run api:gen",
    "build": "ng build",
    "prestart": "npm run api:gen",
    "start": "ng serve --host localhost --port 4200",
    "smoke": "tsx scripts/smoke.ts"
  },
  "dependencies": {
    "@angular/common": "22.3.0",
    "@angular/compiler": "22.3.0",
    "@angular/core": "22.3.0",
    "@angular/forms": "22.3.0",
    "@angular/platform-browser": "22.3.0",
    "@angular/router": "22.3.0",
    "angular-oauth2-oidc": "22.0.2",
    "rxjs": "7.8.2",
    "tslib": "2.8.1"
  },
  "devDependencies": {
    "@angular/build": "22.3.0",
    "@angular/cli": "22.3.0",
    "@angular/compiler-cli": "22.3.0",
    "ng-openapi-gen": "1.1.0",
    "tsx": "4.23.15",
    "typescript": "6.0.3"
  }
}
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `src/environments/environment.development.ts`**
```typescript
export const environment = {
  apiBaseUrl: 'http://localhost:8000',
  issuer: 'http://localhost:8180/realms/tasksteams',
  clientId: 'tasks-web',
  scopes: 'openid profile email tasks:read tasks:write',
};
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `src/environments/environment.ts`**
```typescript
export const environment = {
  apiBaseUrl: 'http://localhost:8000',
  issuer: 'http://localhost:8180/realms/tasksteams',
  clientId: 'tasks-web',
  scopes: 'openid profile email tasks:read tasks:write',
};
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `tsconfig.app.json`**
```jsonc
/* To learn more about Typescript configuration file: https://www.typescriptlang.org/docs/handbook/tsconfig-json.html. */
/* To learn more about Angular compiler options: https://angular.dev/reference/configs/angular-compiler-options. */
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "types": []
  },
  "include": [
    "src/**/*.ts"
  ],
  "exclude": [
    "src/**/*.spec.ts"
  ]
}
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `tsconfig.json`**
```jsonc
/* To learn more about Typescript configuration file: https://www.typescriptlang.org/docs/handbook/tsconfig-json.html. */
/* To learn more about Angular compiler options: https://angular.dev/reference/configs/angular-compiler-options. */
{
  "compileOnSave": false,
  "compilerOptions": {
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "skipLibCheck": true,
    "isolatedModules": true,
    "experimentalDecorators": true,
    "importHelpers": true,
    "target": "ES2022",
    "module": "preserve"
  },
  "angularCompilerOptions": {
    "enableI18nLegacyMessageIdFormat": false,
    "strictInjectionParameters": true,
    "strictInputAccessModifiers": true
  },
  "files": [],
  "references": [
    {
      "path": "./tsconfig.app.json"
    }
  ]
}
```
Expected result: the named files exist under code, saved with the exact contents shown. No program must be running while you create them.

### Step 4. Bootstrap and application wiring
Create the concrete parent directories (silent on success), then create/replace every named file below in your editor. Save after each file; do not type the markdown fences.

**Command: code folder, parent directories**
```powershell
New-Item -ItemType Directory -Force 'src','src/app' | Out-Null
```

**Command: code folder, macOS/Linux**
```bash
mkdir -p src src/app
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `src/app/app.config.ts`**
```typescript
import { ApplicationConfig } from '@angular/core';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { provideRouter } from '@angular/router';
import { ApiConfiguration } from './api/api-configuration';
import { environment } from '../environments/environment';
import { routes } from './app.routes';
export const appConfig: ApplicationConfig = {
  providers: [provideHttpClient(withFetch()), provideRouter(routes),
    { provide: ApiConfiguration, useValue: { rootUrl: environment.apiBaseUrl } }],
};
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `src/app/app.routes.ts`**
```typescript
import { Routes } from '@angular/router';

export const routes: Routes = [];
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `src/app/app.ts`**
```typescript
import { ChangeDetectionStrategy, Component } from '@angular/core';
@Component({
  selector: 'app-root',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: '<main><h1>Tasks and Teams</h1><p>Generated client ready. Chapter 02 adds sign-in.</p></main>',
})
export class App {}
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `src/index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Tasks and Teams</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body><app-root></app-root></body>
</html>
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `src/main.ts`**
```typescript
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';

bootstrapApplication(App, appConfig)
  .catch((err) => console.error(err));
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `src/styles.css`**
```css
body { font: 1rem/1.6 system-ui, sans-serif; margin: 2rem; }
```
Expected result: the named files exist under code, saved with the exact contents shown. No program must be running while you create them.

### Step 5. Executable smoke/build helpers
Create the concrete parent directories (silent on success), then create/replace every named file below in your editor. Save after each file; do not type the markdown fences.

**Command: code folder, parent directories**
```powershell
New-Item -ItemType Directory -Force 'scripts' | Out-Null
```

**Command: code folder, macOS/Linux**
```bash
mkdir -p scripts
```

This executable helper belongs outside browser src. One smoke scenario or build task, never a unit suite.

**File: `scripts/generated-summary.mjs`**
```javascript
import { readFileSync } from 'node:fs';
const contract = readFileSync('contract/openapi.yaml', 'utf8');
console.log(`Generated ${[...contract.matchAll(/operationId:/g)].length} operations: getHealth, getMe, listTasks`);
```

This executable helper belongs outside browser src. One smoke scenario or build task, never a unit suite.

**File: `scripts/node-client.ts`**
```typescript
import '@angular/compiler';
import { createEnvironmentInjector, EnvironmentInjector, Injector, provideZonelessChangeDetection, ɵINJECTOR_SCOPE } from '@angular/core';
import { HttpClient, provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { Api } from '../src/app/api/api';
import { environment } from '../src/environments/environment';
export function nodeClient(token = '') {
  const injector = createEnvironmentInjector([
    { provide: ɵINJECTOR_SCOPE, useValue: 'root' },
    provideZonelessChangeDetection(),
    provideHttpClient(withFetch(), withInterceptors([(request, next) => {
      const target = new URL(request.url);
      const base = new URL(environment.apiBaseUrl);
      const allowed = target.origin === base.origin &&
        (target.pathname === base.pathname || target.pathname.startsWith(base.pathname.replace(/\/$/, '') + '/'));
      return next(allowed && token ? request.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : request);
    }])),
  ], Injector.NULL as EnvironmentInjector);
  const api = new Api({ rootUrl: environment.apiBaseUrl }, injector.get(HttpClient));
  return { api, close: () => injector.destroy() };
}
```

This executable helper belongs outside browser src. One smoke scenario or build task, never a unit suite.

**File: `scripts/node-spike.ts`**
```typescript
import { nodeClient } from './node-client';
const client = nodeClient();
console.log('Node HttpClient injector: ready');
client.close();
```

This executable helper belongs outside browser src. One smoke scenario or build task, never a unit suite.

**File: `scripts/smoke.ts`**
```typescript
import '@angular/compiler';
import { HttpErrorResponse } from '@angular/common/http';
import { nodeClient } from './node-client';
import { environment } from '../src/environments/environment';
import { getHealth } from '../src/app/api/fn/platform/get-health';
import { getMe } from '../src/app/api/fn/platform/get-me';
async function main() {
  const anonymous = nodeClient();
  try { await anonymous.api.invoke(getMe); throw new Error('Expected anonymous 401'); }
  catch (error) {
    if (!(error instanceof HttpErrorResponse) || error.status !== 401) throw error;
    console.log(`Anonymous request: ${error.status} ${error.error.title}`);
    console.log(`Anonymous detail: ${error.error.detail}`);
  } finally { anonymous.close(); }
  const discovery = await fetch(environment.issuer + '/.well-known/openid-configuration').then(r => r.json());
  const response = await fetch(discovery.token_endpoint, {
    method: 'POST', body: new URLSearchParams({ client_id: 'tasks-smoke', grant_type: 'password',
      username: 'alice', password: process.env['SMOKE_ALICE_PASSWORD'] ?? 'alice-local-fake',
      scope: 'openid profile email tasks:read tasks:write tasks:admin' }),
  });
  if (!response.ok) throw new Error(`Smoke token request: ${response.status}`);
  const { access_token } = await response.json();
  const client = nodeClient(access_token);
  try {
    const health = await client.api.invoke(getHealth);
    const me = await client.api.invoke(getMe);
    console.log(`health: ${health.status}`);
    console.log(`me: ${me.username} (${me.roles.join(', ')})`);
  } finally { client.close(); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
```
Expected result: the named files exist under code, saved with the exact contents shown. No program must be running while you create them.

### Step 6. Copied fixture configuration and licence
Create the concrete parent directories (silent on success), then create/replace every named file below in your editor. Save after each file; do not type the markdown fences.

**Command: code folder, parent directories**
```powershell
New-Item -ItemType Directory -Force 'smoke-backend' | Out-Null
```

**Command: code folder, macOS/Linux**
```bash
mkdir -p smoke-backend
```

Unchanged upstream smoke fixture configuration. Keep it byte-for-byte; the reading guide explains its settings.

**File: `smoke-backend/.dockerignore`**
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

Unchanged upstream smoke fixture configuration. Keep it byte-for-byte; the reading guide explains its settings.

**File: `smoke-backend/.env.example`**
```dotenv
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

Unchanged upstream smoke fixture configuration. Keep it byte-for-byte; the reading guide explains its settings.

**File: `smoke-backend/Dockerfile`**
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

Unchanged upstream smoke fixture configuration. Keep it byte-for-byte; the reading guide explains its settings.

**File: `smoke-backend/docker-compose.override.yml`**
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

Unchanged upstream smoke fixture configuration. Keep it byte-for-byte; the reading guide explains its settings.

**File: `smoke-backend/docker-compose.yml`**
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

Unchanged upstream smoke fixture configuration. Keep it byte-for-byte; the reading guide explains its settings.

**File: `smoke-backend/requirements.txt`**
```text
fastapi==0.165.0
uvicorn==0.54.0
pydantic==2.14.4
pydantic-settings==2.16.3
SQLAlchemy==2.1.9
psycopg[binary]==3.3.9
PyJWT[crypto]==2.15.1
```
Expected result: the named files exist under code, saved with the exact contents shown. No program must be running while you create them.

### Step 7. Install, generate and build once

**Command: code folder, same on macOS/Linux**
```powershell
npm ci --no-audit --no-fund
npm run api:gen
npm run build
npx tsx scripts/node-spike.ts
```
For a scratch project without a lock, first use npm install --no-audit --no-fund, then keep the generated lock. The build runs generation again through prebuild; repeating generation does not compile twice. Captured output is verbatim; timings/absolute paths/content-hash filenames vary.

**Captured output (excerpt)**
```text

added 267 packages in 14s
```

**Captured output (excerpt)**
```text

> web-angular@1.0.0 prebuild
> npm run api:gen


> web-angular@1.0.0 api:gen
> ng-openapi-gen && node scripts/generated-summary.mjs

Using OpenAPI specification version: 3.1.1
Generation from contract/openapi.yaml finished with 33 models and 7 services.
Generated 27 operations: getHealth, getMe, listTasks

> web-angular@1.0.0 build
> ng build

> Building...
√ Building...
Initial chunk files | Names         |  Raw size | Estimated transfer size
main-HMF3OFRP.js    | main          | 210.94 kB |                57.28 kB
styles-HTGUKBVR.css | styles        |  53 bytes |                53 bytes

                    | Initial total | 211.00 kB |                57.34 kB

Application bundle generation complete. [2.025 seconds] - 2026-11-23T10:34:14.747Z

Output location: F:\Projects\Uee03\Code101\capstones\web-angular\source\phase-1-setup\01-create-app-generate-client\code\dist\web-angular
```

**Captured output (excerpt)**
```text
Node HttpClient injector: ready
```
npm 11 can report install-scripts approval warnings for native optional packages. Do not blanket-approve scripts: inspect each maintainer/package if needed on your platform. This environment built without changing policy. The generator reports overlapping JSON media-type variants; the copied contract supports both and the actual PATCH smoke succeeds.

## Run it
### Static comparison now; runtime plan paused
From the clone root, the following **static-only** command compares text with files and executes no application, build, server or Docker step. The supplied verify.json retains a future runtime plan (exclusive tasksteams, disposable project, npm ci/one build, one token/generated-client script, timeout 420 and always-cleanup); do not execute that plan while the pause remains in effect.

**Command: clone root, all five chapters**
```powershell
python scripts/verify_labs.py --static capstones/web-angular
```
**Captured static-only output (no application executed)**
```text
[STATIC    ] capstones/web-angular/source/phase-1-setup/01-create-app-generate-client
[STATIC    ] capstones/web-angular/source/phase-2-auth/02-sign-in-keycloak
[STATIC    ] capstones/web-angular/source/phase-3-screens/03-screens-stores-pagination
[STATIC    ] capstones/web-angular/source/phase-4-errors/04-problem-details-conflicts-offline-wcag
[STATIC    ] capstones/web-angular/source/phase-5-ship/05-build-run-ship

0 passed, 5 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

Current status is written (not run), as required by the runtime-verification pause. These per-phase excerpts were captured before the pause; the final clean-room run was interrupted and is not reported as PASS:

**Captured output (excerpt)**
```text
Dev server: 200
```

**Captured output (excerpt)**
```text

> web-angular@1.0.0 smoke
> tsx scripts/smoke.ts

Anonymous request: 401 Unauthorized
Anonymous detail: A bearer access token is required.
health: ok
me: alice (admin)
```
### Manual browser run with ownership and cleanup
Inside the clone hold the same lock for the **whole** session, not only startup. From clone root open a child shell:

**Command: clone root, opens locked child shell**
```powershell
python scripts/stack_lock.py tasksteams -- powershell -NoProfile
```
macOS/Linux: `python scripts/stack_lock.py tasksteams -- bash`. In that child go to this chapter code folder (full path in Before you start), then:

**Command: code folder, locked child shell**
```powershell
Copy-Item smoke-backend/.env.example smoke-backend/.env
Push-Location smoke-backend
docker compose -p angular-manual up -d --build --wait --wait-timeout 400
docker compose -p angular-manual ps
docker compose -p angular-manual logs --tail 20 keycloak api
Pop-Location
npm start
```
macOS/Linux: cp replaces Copy-Item; use `(cd smoke-backend; docker compose -p angular-manual up -d --build --wait --wait-timeout 400; docker compose -p angular-manual ps; docker compose -p angular-manual logs --tail 20 keycloak api)` then npm start. First boot may take several minutes. Expect db/keycloak/api running and healthy; Keycloak imports tasksteams, uvicorn finishes startup, and localhost:4200 serves the app. Names/timestamps vary; compare the real Compose tail below, not invented terminal text.

**Captured temporary-stack startup (tail)**
```text
 Container code101-verify-01-create-app-generate-client-keycloak-1 Created 
 Container code101-verify-01-create-app-generate-client-db-1 Created 
 Container code101-verify-01-create-app-generate-client-api-1 Creating 
 Container code101-verify-01-create-app-generate-client-api-1 Created 
 Container code101-verify-01-create-app-generate-client-keycloak-1 Starting 
 Container code101-verify-01-create-app-generate-client-db-1 Starting 
 Container code101-verify-01-create-app-generate-client-keycloak-1 Started 
 Container code101-verify-01-create-app-generate-client-db-1 Started 
 Container code101-verify-01-create-app-generate-client-db-1 Waiting 
 Container code101-verify-01-create-app-generate-client-db-1 Healthy 
 Container code101-verify-01-create-app-generate-client-api-1 Starting 
 Container code101-verify-01-create-app-generate-client-api-1 Started 
 Container code101-verify-01-create-app-generate-client-api-1 Waiting 
 Container code101-verify-01-create-app-generate-client-keycloak-1 Waiting 
 Container code101-verify-01-create-app-generate-client-db-1 Waiting 
 Container code101-verify-01-create-app-generate-client-db-1 Healthy 
 Container code101-verify-01-create-app-generate-client-api-1 Healthy 
 Container code101-verify-01-create-app-generate-client-keycloak-1 Healthy
```
Open the browser after the dev-server probe can return 200. While npm start occupies this shell, do not start a second stack. Ctrl+C stops the foreground server. Before exit releases the lock, clean up from the same code folder:

**Command: code folder after Ctrl+C, still locked**
```powershell
Push-Location smoke-backend
docker compose -p angular-manual down -v --remove-orphans
docker image rm angular-manual-api
Pop-Location
docker ps -a
docker volume ls
docker network ls
exit
```
macOS/Linux: replace Push/Pop-Location with `(cd smoke-backend; docker compose -p angular-manual down -v --remove-orphans; docker image rm angular-manual-api)`, then inventory/exit. Remove only your project. Captured cleanup uses an automated project name instead:

**Captured output (excerpt)**
```text
 Container code101-verify-01-create-app-generate-client-keycloak-1 Stopping 
 Container code101-verify-01-create-app-generate-client-api-1 Stopping 
 Container code101-verify-01-create-app-generate-client-api-1 Stopped 
 Container code101-verify-01-create-app-generate-client-api-1 Removing 
 Container code101-verify-01-create-app-generate-client-api-1 Removed 
 Container code101-verify-01-create-app-generate-client-db-1 Stopping 
 Container code101-verify-01-create-app-generate-client-db-1 Stopped 
 Container code101-verify-01-create-app-generate-client-db-1 Removing 
 Container code101-verify-01-create-app-generate-client-db-1 Removed 
 Container code101-verify-01-create-app-generate-client-keycloak-1 Stopped 
 Container code101-verify-01-create-app-generate-client-keycloak-1 Removing 
 Container code101-verify-01-create-app-generate-client-keycloak-1 Removed 
 Volume code101-verify-01-create-app-generate-client_pg_data Removing 
 Network tasksteams-net Removing 
 Volume code101-verify-01-create-app-generate-client_pg_data Removed 
 Network tasksteams-net Removed
```
Manual browser expectation: a Tasks and Teams h1 and Generated client ready. Chapter 02 adds sign-in. This phase deliberately has no login form yet.

## How it works
main.ts bootstraps the standalone App using app.config.ts. Dependency injection supplies HttpClient and generated Api from environment.ts. api:gen translates immutable OpenAPI into typed functions/models; invoke returns a Promise, while invoke$Response retains headers. A Promise is one future result or failure. The smoke's root injector uses a private Angular marker only outside the browser. The spike succeeded here. Fallback on a future Angular break: use generated models with fetch against the same documented contract, record W-05 as a deviation and re-run it; do not silently claim generated-function verification.
New terms are defined in [GLOSSARY.md](../../GLOSSARY.md). A type is generated for each domain entity; do not maintain a second handwritten Task/Team/Comment model.

## Try it
From a fresh terminal, start at the **chapter folder**, one level above code. Choose a new exercise destination so copying cannot nest an older attempt. These commands do not start a server or touch shared ports.

**Command: clone root -> chapter folder -> personal exercise copy (PowerShell)**
```powershell
Set-Location 'F:/Projects/Uee03/Code101/capstones/web-angular/source/phase-1-setup/01-create-app-generate-client'
Copy-Item exercise/starter (Join-Path $HOME 'angular-exercise-01') -Recurse
Set-Location (Join-Path $HOME 'angular-exercise-01')
node main.mjs
```

**Command: chapter folder -> personal exercise copy (macOS/Linux)**
```bash
cp -R exercise/starter ~/angular-exercise-01
cd ~/angular-exercise-01
node main.mjs
```
Edit main.mjs in that personal copy, not the answer folder. The starter prints a TODO, not a failed unit test. The complete starter from the chapter is shown below.

**File: exercise/starter/main.mjs**
```javascript
// Print the contract operation count instead of TODO.
console.log("TODO: finish the exercise");
```

**Captured starter output**
```text
TODO: finish the exercise
```
<details><summary>Solution</summary>

Replace the exercise file with the complete answer; run node main.mjs again.

**File: exercise/solution/main.mjs**
```javascript
const operations = 27;
console.log(`Generated operations: ${operations}`);
```

**Captured solution output**
```text
Generated operations: 27
```

One small runnable example, not a unit suite.
</details>

## Check yourself
1. Why TypeScript 6.0.3 here instead of Web 101's compiler? <details><summary>Answer</summary>Angular 22 accepts >=6.0.0 <6.1.0; this project has its own pinned compiler.</details>
2. Who owns the contract and how is the client restored? <details><summary>Answer</summary>The platform owns openapi.yaml. Copy it verbatim; npm run api:gen regenerates src/app/api; prebuild/prestart do this automatically.</details>
3. When use invoke$Response rather than invoke? <details><summary>Answer</summary>When headers such as ETag or Location are needed; invoke returns only the typed body.</details>
4. Why ship the lockfile but not node_modules? <details><summary>Answer</summary>npm ci reproduces the locked dependency graph for the current machine; installed binaries/build artifacts are not portable source.</details>

## Common mistakes
These API errors were actually captured by the generated-client smoke; no token or variable trace value is printed:

**Captured real API errors**
```text
Anonymous request: 401 Unauthorized
Anonymous detail: A bearer access token is required.
```

| Symptom/error | Cause | Fix |
|---|---|---|
| Anonymous request: 401 Unauthorized; A bearer access token is required. | No bearer token. | Sign in with tasks-web in the browser; only the Node smoke uses the fake tasks-smoke password grant. Never put that grant in the SPA. |
| Build is green but an edit is absent | Unsaved tab/wrong folder. | Save all and use the exact chapter path. Guidance, not a claimed captured terminal error. |
| Sign-in fails only on nginx port 8200 | Origin intentionally unregistered. | Stop ng serve; publish 4200 for human sign-in. Do not widen platform CORS. |
| Realm edit seems ignored | Import runs only on an empty development store. | Do not edit the fixture. Remove your own temporary stack with down -v and re-create it; never remove another owner's volume. |

Only API lines above are captured errors; other rows are diagnostic guidance, not fabricated messages.

## Best practice
Keep related code in feature directories, match filenames to concepts, prefer inject and keep components focused on presentation. Stores own requests; pages own forms/labels. Source: Angular coding style guide (Tier 1) https://angular.dev/style-guide.

Use npm ci with the shipped lockfile; it refuses dependency/lock mismatches instead of silently updating. Source: npm ci (Tier 1) https://docs.npmjs.com/cli/v11/commands/npm-ci.

Use code flow/PKCE and keep bearer tokens out of persistent storage. A BFF with HttpOnly cookies is stronger when server support is available, but outside this pure SPA. Source: OAuth 2.0 Security Best Current Practice (Tier 1) https://www.rfc-editor.org/rfc/rfc9700.html and the pinned library https://github.com/manfredsteyer/angular-oauth2-oidc/tree/22.0.2.

## Next lesson
02. Sign in with Keycloak: Auth (PKCE) and token handling.
