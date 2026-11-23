---
track: capstone
level: 201
phase: 5
phase_name: ship
lesson: 05
title: "Docker, nginx, CSP"
time: 2 h
prerequisites: [capstone-web-angular-04]
versions: { angular: "22.3.0", cli: "22.3.0", node: "26.13.1", npm: "11.20.0", typescript: "6.0.3", rxjs: "7.8.2", ng-openapi-gen: "1.1.0", angular-oauth2-oidc: "22.0.2", tsx: "4.23.15" }
verified: not yet run
source: capstones/web-angular/source/phase-5-ship/05-build-run-ship/
assets: [ui/search, ui/filter, ui/plus, ui/x, ui/check-circle, ui/alert-triangle, ui/list, ui/columns, arrows/log-in, arrows/log-out, arrows/refresh-cw, users/users, cloud-network/cloud-off, time/calendar-days]
---

# 05. Docker, nginx, CSP

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

> **Authoring status: written (not run).** Runtime verification was stopped at the user's request. The captured terminal excerpts below are historical evidence from before that pause, not a current PASS claim. Build/server/Docker commands are instructions for a future learner run; none were executed after the pause. Browser-only acceptance remains manual.


## Why it matters
Working in a dev server is not deployment. nginx must return the app for deep links, send security headers on those responses and run without root. A temporary smoke container proves these server behaviours without pretending its unregistered origin can sign in.

## What you will build
Phase 5: **Build, run and ship**. Requirements **W-29, W-31, W-32**. This pack is the whole application, not a patch. Chapter numbers and final screen names match web-react. Smoke verification proves that the environment works and code runs once; it is not browser sign-in, unit testing, linting or a WCAG audit.

## Before you start
- Finish Web 101 lessons 03, 06, 07, 10 and 11. Read platform chapters 01/03. Have Node 26.13.1, npm 11.20.0, Python 3.10+ and Docker Desktop (Linux containers) running. Node's official download supplies npm; reopen your terminal after installation. No global Angular CLI.
- Open a terminal in your Code101 clone. These Windows commands are PowerShell 5.1 compatible. Example clone: F:/Projects/Uee03/Code101; substitute yours. The path before the terminal prompt tells you the current directory. Recovery: Set-Location 'F:/Projects/Uee03/Code101'.
- Source pack: web-angular-phase-5-ship.zip. Windows: right-click, Extract All. macOS: double-click. Linux: unzip web-angular-phase-5-ship.zip. Open 05-build-run-ship/code, not the zip viewer. An extracted pack already contains the copied contract/backend fixture; repo-relative copy/lock commands below apply to the clone.
- Use **localhost** in the browser, because the issuer is http://localhost:8180/realms/tasksteams. Free 4200/8000/8180/5432; run one Tasks and Teams stack at a time. Do not stop another agent's project. Shipping smoke additionally owns 8200 temporarily.
- An editor tab dot means unsaved changes. Save each file as UTF-8 **without BOM** before running. Windows PowerShell 5.1 Set-Content -Encoding utf8 would add a BOM; use your editor.

## Steps
### Step 1. Open the phase or scaffold the workspace
Open the phase code folder below. Continuing your own previous app? Replace/create the full files below. Complete files, including unchanged ones, are repeated deliberately: there are no unlisted changed regions. Never copy earlier node_modules.

**Command: clone root -> this phase code**
```powershell
Set-Location 'F:/Projects/Uee03/Code101'
Set-Location 'capstones/web-angular/source/phase-5-ship/05-build-run-ship/code'
```
On macOS/Linux: `cd /path/to/Code101/capstones/web-angular/source/phase-5-ship/05-build-run-ship/code`. All remaining relative paths are based here unless stated otherwise.
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
Shipping configuration, line by line:
- FROM node:26-alpine AS build selects the approved builder; WORKDIR isolates the app. Copy manifests first to cache npm ci until the lockfile changes. --no-audit/--no-fund suppress unrelated install reporting, not build checks.
- COPY . . adds source/contract/config. ARG API_BASE_URL, OIDC_ISSUER, OIDC_CLIENT_ID are public inputs, not secrets. write-env.mjs merges them into JSON-shaped environment.ts, writes UTF-8 and prints no values. npm run build runs prebuild too.
- The second FROM selects the approved unprivileged nginx image. COPY config replaces the server config; COPY --from copies only browser output. USER 101 is explicit; EXPOSE documents 8080. HEALTHCHECK waits 5s, probes every 5s with a 3s timeout, fails after 12 failures and exits 1 if wget fails.
- nginx listen/server_name/root/index choose port, host matching, static root and index. add_header uses always for errors too. CSP: self by default/scripts/fonts, inline styles only for Angular, local/data images, only API/issuer connections, no framing/foreign base/form action/plugins. nosniff/no-referrer/DENY provide extra protection.
- /healthz avoids log noise and returns ok. expires -1 on index.html forces revalidation. The js/css regex targets hashed build files, sets one-year expiry and returns 404 for missing bundles rather than index.html. The final location tries a real file/directory then index.html. Security headers remain inherited.
- .dockerignore omits node_modules/dist/.angular/.git/logs/smoke-backend/local .env. None belongs in the browser image.
- Docker Hub now marks the approved nginxinc repository archived. The requested tag resolved; no unapproved substitution was made. Review migration to nginx/nginx-unprivileged before a real release.

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

**File: `.dockerignore`**
```text
node_modules
dist
.angular
.git
*.log
smoke-backend
.env
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

**File: `Dockerfile`**
```dockerfile
FROM node:26-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
ARG API_BASE_URL
ARG OIDC_ISSUER
ARG OIDC_CLIENT_ID
RUN node scripts/write-env.mjs && npm run build
FROM nginxinc/nginx-unprivileged:1.30-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/web-angular/browser /usr/share/nginx/html
USER 101
EXPOSE 8080
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=12 CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
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

**File: `nginx.conf`**
```nginx
server {
    listen 8080;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self' http://localhost:8000 http://localhost:8180; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header X-Frame-Options "DENY" always;
    location = /healthz { access_log off; return 200 "ok\n"; }
    location = /index.html { expires -1; }
    location ~* \.(?:js|css)$ { expires 1y; try_files $uri =404; }
    location / { try_files $uri $uri/ /index.html; }
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
    "smoke": "tsx scripts/smoke.ts",
    "smoke:auth": "tsx scripts/check-auth.ts"
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
  "apiBaseUrl": "http://localhost:8000",
  "issuer": "http://localhost:8180/realms/tasksteams",
  "clientId": "tasks-web",
  "scopes": "openid profile email tasks:read tasks:write"
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
import { ApplicationConfig, inject, provideAppInitializer } from '@angular/core';
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { provideRouter, TitleStrategy } from '@angular/router';
import { OAuthStorage, provideOAuthClient } from 'angular-oauth2-oidc';
import { ApiConfiguration } from './api/api-configuration';
import { environment } from '../environments/environment';
import { AuthService } from './auth/auth.service';
import { SplitStorage } from './auth/split-storage';
import { authInterceptor } from './http/auth.interceptor';
import { TitleFocus } from './core/title-focus';
import { problemInterceptor } from './http/problem.interceptor';
import { retryAfterInterceptor } from './http/retry-after.interceptor';
import { routes } from './app.routes';
export const appConfig: ApplicationConfig = {
  providers: [provideHttpClient(withFetch(), withInterceptors([problemInterceptor, authInterceptor, retryAfterInterceptor])), provideRouter(routes), { provide: TitleStrategy, useClass: TitleFocus },
    provideOAuthClient(), { provide: OAuthStorage, useExisting: SplitStorage },
    { provide: ApiConfiguration, useValue: { rootUrl: environment.apiBaseUrl } },
    provideAppInitializer(() => inject(AuthService).boot())],
};
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `src/app/app.routes.ts`**
```typescript
import { Routes } from '@angular/router';
import { authGuard, adminGuard } from './auth/guards';
export const routes: Routes = [
  { path: 'login', title: 'Login', loadComponent: () => import('./features/login/login').then(m => m.Login) },
  { path: 'auth/callback', title: 'Callback', loadComponent: () => import('./features/callback/callback').then(m => m.Callback) },
  { path: '', title: 'Dashboard', canActivate: [authGuard], loadComponent: () => import('./features/dashboard/dashboard').then(m => m.Dashboard) },
  { path: 'admin/audit', title: 'Audit log', canActivate: [authGuard, adminGuard], loadComponent: () => import('./features/audit/audit').then(m => m.Audit) },
  { path: 'teams', title: 'Teams', canActivate: [authGuard], loadComponent: () => import('./features/teams/teams').then(m => m.Teams) },
  { path: 'teams/:teamId', title: 'Team detail', canActivate: [authGuard], loadComponent: () => import('./features/team-detail/team-detail').then(m => m.TeamDetail) },
  { path: 'teams/:teamId/projects', title: 'Projects', canActivate: [authGuard], loadComponent: () => import('./features/projects/projects').then(m => m.Projects) },
  { path: 'projects/:projectId', title: 'Tasks', canActivate: [authGuard], loadComponent: () => import('./features/tasks/tasks').then(m => m.Tasks) },
  { path: 'tasks/:taskId', title: 'Task detail', canActivate: [authGuard], loadComponent: () => import('./features/task-detail/task-detail').then(m => m.TaskDetail) },
  { path: 'forbidden', title: 'You do not have access', loadComponent: () => import('./features/forbidden/forbidden').then(m => m.Forbidden) },
  { path: '**', title: 'Not found', loadComponent: () => import('./features/not-found/not-found').then(m => m.NotFound) },
];
```

Complete file, not a patch. Configuration fields are explained in the reading guide.

**File: `src/app/app.ts`**
```typescript
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { Router, RouterLink, RouterOutlet } from '@angular/router';
import { AuthService } from './auth/auth.service';
import { Actions } from './core/actions';
import { Notice } from './core/notice';
import { Icon } from './shared/icon';
import { Feedback } from './shared/feedback';
@Component({ selector: 'app-root', imports: [RouterLink, RouterOutlet, Icon, Feedback], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<a class="skip-link" href="#content">Skip to content</a>
    <header><a routerLink="/">Tasks and Teams</a><nav aria-label="Main">
      @if (auth.signedIn()) {
        <a routerLink="/">Dashboard</a><a routerLink="/teams"><app-icon name="users/users" />Teams</a>
        @if (auth.isAdmin()) { <a routerLink="/admin/audit">Audit log</a> }
      }
    </nav><details><summary>Account</summary>
      @if (auth.signedIn()) { <p>{{ auth.user()?.displayName }}</p><button (click)="auth.signOut()"><app-icon name="arrows/log-out" />Sign out</button> }
      @else { <a routerLink="/login"><app-icon name="arrows/log-in" />Sign in</a> }
    </details></header>
    <main id="content" tabindex="-1"><app-feedback (retry)="retry()" /><router-outlet /></main>` })
export class App {
  protected readonly auth = inject(AuthService);
  private readonly actions = inject(Actions);
  protected retry(): void { void this.actions.retry(); }
}
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
:root { color-scheme: light dark; font: 1rem/1.6 system-ui, sans-serif; --surface: #ffffff; --ink: #172033; --line: #5b6779; --accent: #134a9c; }
@media (prefers-color-scheme: dark) { :root { --surface: #101927; --ink: #f0f3f9; --line: #acb8cc; --accent: #a7cbff; } }
* { box-sizing: border-box; }
html { scroll-padding-top: 7rem; }
body { margin: 0; color: var(--ink); background: var(--surface); }
header { display: flex; flex-wrap: wrap; align-items: center; gap: 1rem; padding: 1rem; border-bottom: 1px solid var(--line); background: var(--surface); }
nav { display: flex; flex-wrap: wrap; gap: 1rem; }
main { max-width: 76rem; margin: auto; padding: 1rem; }
a { color: var(--accent); overflow-wrap: anywhere; }
button, input, select, textarea, summary { font: inherit; min-height: 2rem; }
button, summary { cursor: pointer; }
button, input, select, textarea { color: var(--ink); background: var(--surface); border: 1px solid var(--line); border-radius: .25rem; padding: .4rem; max-width: 100%; }
button { margin: .25rem; }
button:disabled { opacity: .65; cursor: not-allowed; }
a, button { min-width: 24px; min-height: 24px; }
form { display: grid; gap: .4rem; max-width: 36rem; padding-block: 1rem; }
textarea { min-height: 6rem; }
:focus-visible { outline: 3px solid var(--accent); outline-offset: 3px; }
.skip-link { position: absolute; top: -5rem; left: .5rem; background: var(--surface); padding: .5rem; z-index: 5; }
.skip-link:focus { top: .5rem; }
.icon { display: inline-block; vertical-align: middle; width: 1.25rem; height: 1.25rem; margin-right: .4rem; background-color: currentColor; }
.board { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 12rem), 1fr)); gap: .75rem; }
article, aside, [role="alert"] { border: 2px solid var(--line); border-radius: .25rem; padding: .75rem; margin-block: .5rem; overflow-wrap: anywhere; }
dialog { color: var(--ink); background: var(--surface); border: 2px solid var(--line); max-width: min(42rem, 95vw); max-height: 90vh; overflow: auto; }
dialog::backdrop { background: rgb(0 0 0 / .6); }
.table-scroll { max-width: 100%; overflow-x: auto; }
table { border-collapse: collapse; } th, td { padding: .5rem; border: 1px solid var(--line); text-align: left; overflow-wrap: anywhere; }
@media (forced-colors: active) { .icon { background: CanvasText; } }
```
Expected result: the named files exist under code, saved with the exact contents shown. No program must be running while you create them.

### Step 5. Identity and HTTP boundary
Create the concrete parent directories (silent on success), then create/replace every named file below in your editor. Save after each file; do not type the markdown fences.

**Command: code folder, parent directories**
```powershell
New-Item -ItemType Directory -Force 'src/app/auth','src/app/http' | Out-Null
```

**Command: code folder, macOS/Linux**
```bash
mkdir -p src/app/auth src/app/http
```

Keep authentication/authorization boundary logic here, not in presentation components. This is the complete file.

**File: `src/app/auth/auth.config.ts`**
```typescript
import { AuthConfig } from 'angular-oauth2-oidc';
import { environment } from '../../environments/environment';
export const storageRules = 'Tokens: memory only; nonce and PKCE_verifier: sessionStorage; ts.hint: non-secret localStorage flag';
export function authConfig(origin: string, admin = false): AuthConfig {
  return {
    issuer: environment.issuer,
    clientId: environment.clientId,
    redirectUri: origin + '/auth/callback',
    postLogoutRedirectUri: origin + '/login',
    responseType: 'code',
    scope: environment.scopes + (admin ? ' tasks:admin' : ''),
    requireHttps: 'remoteOnly',
    strictDiscoveryDocumentValidation: true,
    disablePKCE: false,
    timeoutFactor: 0.75,
    showDebugInformation: false,
    clearHashAfterLogin: true,
  };
}
export function safeReturn(value: string | null | undefined): string {
  return value?.startsWith('/') && !value.startsWith('//') && !/[\\\r\n]/.test(value) ? value : '/';
}
export function isApiUrl(value: string): boolean {
  const target = new URL(value, environment.apiBaseUrl);
  const base = new URL(environment.apiBaseUrl);
  const path = base.pathname.replace(/\/$/, '');
  return target.origin === base.origin && (target.pathname === path || target.pathname.startsWith(path + '/'));
}
```

Keep authentication/authorization boundary logic here, not in presentation components. This is the complete file.

**File: `src/app/auth/auth.service.ts`**
```typescript
import { computed, inject, Injectable, signal } from '@angular/core';
import { Router } from '@angular/router';
import { OAuthService } from 'angular-oauth2-oidc';
import { Api } from '../api/api';
import { Me } from '../api/models/me';
import { getMe } from '../api/fn/platform/get-me';
import { SplitStorage } from './split-storage';
import { authConfig, safeReturn } from './auth.config';
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly oauth = inject(OAuthService);
  private readonly storage = inject(SplitStorage);
  private readonly api = inject(Api);
  private readonly router = inject(Router);
  readonly user = signal<Me | null>(null);
  readonly error = signal('');
  readonly roles = computed(() => this.user()?.roles ?? []);
  readonly scopes = computed(() => this.user()?.scopes ?? []);
  readonly isAdmin = computed(() => this.roles().includes('admin'));
  private renewal: Promise<void> | null = null;
  private loadingMe = false;
  token(): string { return this.oauth.getAccessToken(); }
  signedIn(): boolean { return this.oauth.hasValidAccessToken(); }
  hasScope(scope: string): boolean { return this.scopes().includes(scope); }
  isLead(teamId: string): boolean {
    return this.isAdmin() || !!this.user()?.teams.some(t => t.teamId === teamId && t.role === 'lead');
  }
  async boot(): Promise<void> {
    this.oauth.configure(authConfig(location.origin, sessionStorage.getItem('ts.adminStep') === '1'));
    this.oauth.events.subscribe(event => {
      if (event.type === 'token_expires' && 'info' in event && event.info === 'access_token') {
        void this.renew().catch(() => this.expired());
      }
    });
    try {
      await this.oauth.loadDiscoveryDocument();
      if (location.pathname === '/auth/callback') {
        const callbackError = new URLSearchParams(location.search).get('error');
        if (callbackError) throw new Error(callbackError);
        await this.oauth.tryLoginCodeFlow();
        if (!this.signedIn()) throw new Error('Sign-in did not return an access token');
        await this.loadMe();
        localStorage.setItem('ts.hint', '1');
      } else if (localStorage.getItem('ts.hint') === '1' && !this.signedIn()) {
        await this.signIn(location.pathname + location.search, false, true);
      }
    } catch (error) {
      this.error.set(error instanceof Error ? error.message : 'Sign-in failed. Try again.');
      localStorage.removeItem('ts.hint');
    } finally {
      if (location.pathname === '/auth/callback') {
        history.replaceState(null, '', '/auth/callback');
        sessionStorage.removeItem('ts.adminStep');
      }
    }
  }
  async loadMe(): Promise<void> {
    this.loadingMe = true;
    try { this.user.set(await this.api.invoke(getMe)); }
    finally { this.loadingMe = false; }
  }
  async signIn(returnUrl = '/', admin = false, silent = false): Promise<void> {
    sessionStorage.setItem('ts.return', safeReturn(returnUrl));
    if (admin) sessionStorage.setItem('ts.adminStep', '1');
    this.oauth.scope = authConfig(location.origin, admin).scope!;
    this.oauth.initCodeFlow('', silent ? { prompt: 'none' } : {});
  }
  async finish(): Promise<void> {
    const target = safeReturn(sessionStorage.getItem('ts.return'));
    sessionStorage.removeItem('ts.return');
    await this.router.navigateByUrl(this.signedIn() ? target : '/login', { replaceUrl: true });
  }
  renew(): Promise<void> {
    if (!this.renewal) {
      this.renewal = this.oauth.refreshToken().then(() => undefined).finally(() => { this.renewal = null; });
    }
    return this.renewal;
  }
  expired(): void {
    this.oauth.logOut(true);
    this.storage.clear();
    this.user.set(null);
    localStorage.removeItem('ts.hint');
    void this.router.navigate(['/login'], { queryParams: { returnUrl: safeReturn(this.router.url) } });
  }
  signOut(): void {
    localStorage.removeItem('ts.hint');
    this.user.set(null);
    // The library reads id_token_hint before clearing its token entries.
    this.oauth.logOut();
    this.storage.clear();
  }
}
```

Keep authentication/authorization boundary logic here, not in presentation components. This is the complete file.

**File: `src/app/auth/guards.ts`**
```typescript
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';
import { safeReturn } from './auth.config';
export const authGuard: CanActivateFn = (_route, state) => {
  const auth = inject(AuthService);
  return auth.signedIn() || inject(Router).createUrlTree(['/login'], { queryParams: { returnUrl: safeReturn(state.url) } });
};
export const adminGuard: CanActivateFn = async (_route, state) => {
  const auth = inject(AuthService);
  if (!auth.isAdmin()) return inject(Router).createUrlTree(['/forbidden']);
  if (!auth.hasScope('tasks:admin')) { await auth.signIn(state.url, true, true); return false; }
  return true;
};
```

Keep authentication/authorization boundary logic here, not in presentation components. This is the complete file.

**File: `src/app/auth/split-storage.ts`**
```typescript
import { Injectable } from '@angular/core';
import { OAuthStorage } from 'angular-oauth2-oidc';
export const transientKeys = new Set(['nonce', 'PKCE_verifier']);
@Injectable({ providedIn: 'root' })
export class SplitStorage implements OAuthStorage {
  private readonly memory = new Map<string, string>();
  getItem(key: string): string | null {
    return transientKeys.has(key) ? sessionStorage.getItem(key) : this.memory.get(key) ?? null;
  }
  setItem(key: string, value: string): void {
    if (transientKeys.has(key)) sessionStorage.setItem(key, value);
    else this.memory.set(key, value);
  }
  removeItem(key: string): void {
    if (transientKeys.has(key)) sessionStorage.removeItem(key);
    else this.memory.delete(key);
  }
  clear(): void {
    this.memory.clear();
    transientKeys.forEach(key => sessionStorage.removeItem(key));
  }
}
```

One cross-cutting HTTP policy; interceptor ordering is explained in How it works.

**File: `src/app/http/auth.interceptor.ts`**
```typescript
import { inject } from '@angular/core';
import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { catchError, from, switchMap, throwError } from 'rxjs';
import { AuthService } from '../auth/auth.service';
import { isApiUrl } from '../auth/auth.config';
export const authInterceptor: HttpInterceptorFn = (request, next) => {
  if (!isApiUrl(request.url)) return next(request);
  const auth = inject(AuthService);
  const originalToken = auth.token();
  const attach = () => auth.token() ? request.clone({ setHeaders: { Authorization: `Bearer ${auth.token()}` } }) : request;
  return next(attach()).pipe(catchError(error => {
    if (!(error instanceof HttpErrorResponse) || error.status !== 401) return throwError(() => error);
    const renewal = auth.token() !== originalToken ? Promise.resolve() : auth.renew().catch(renewError => {
      auth.expired(); throw renewError;
    });
    return from(renewal).pipe(switchMap(() => next(attach())), catchError(retryError => {
      if (retryError instanceof HttpErrorResponse && retryError.status === 401) auth.expired();
      return throwError(() => retryError);
    }));
  }));
};
```

One cross-cutting HTTP policy; interceptor ordering is explained in How it works.

**File: `src/app/http/problem.interceptor.ts`**
```typescript
import { inject } from '@angular/core';
import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { catchError, throwError } from 'rxjs';
import { isApiUrl } from '../auth/auth.config';
import { Connectivity } from '../core/connectivity';
import { parseProblem } from './problem';
export const problemInterceptor: HttpInterceptorFn = (request, next) => {
  if (!isApiUrl(request.url)) return next(request);
  const connection = inject(Connectivity);
  return next(request).pipe(catchError(error => {
    if (!(error instanceof HttpErrorResponse) || error.status === 304) return throwError(() => error);
    if (error.status === 0) connection.failed();
    const problemBody = error.headers.get('Content-Type')?.includes('application/problem+json') ? error.error : null;
    return throwError(() => parseProblem(error.status, problemBody, error.headers));
  }));
};
```

One cross-cutting HTTP policy; interceptor ordering is explained in How it works.

**File: `src/app/http/problem.ts`**
```typescript
export interface ApiProblem {
  type: string;
  title: string;
  status: number;
  detail?: string;
  instance?: string;
  traceId?: string;
  code?: string;
  errors?: { pointer: string; detail: string }[];
  retryAfter?: number;
}
export function parseProblem(status: number, body: unknown, headers: { get(name: string): string | null }): ApiProblem {
  const data = body && typeof body === 'object' ? body as Record<string, unknown> : {};
  const text = (key: string) => typeof data[key] === 'string' ? data[key] as string : undefined;
  const retry = headers.get('Retry-After');
  const seconds = retry === null ? undefined : /^\d+$/.test(retry) ? Number(retry) : Math.max(0, Math.ceil((Date.parse(retry) - Date.now()) / 1000));
  return {
    type: text('type') ?? 'about:blank', title: text('title') ?? 'Request failed', status,
    detail: text('detail') ?? (status === 0 ? 'Cannot reach the API. Check your connection, then try again.' : 'The request could not be completed.'),
    instance: text('instance'), traceId: text('traceId'), code: text('code'),
    errors: Array.isArray(data['errors']) ? data['errors'].filter((item): item is { pointer: string; detail: string } =>
      !!item && typeof item.pointer === 'string' && typeof item.detail === 'string') : undefined,
    retryAfter: Number.isFinite(seconds) ? seconds : undefined,
  };
}
export function fieldName(pointer: string): string | null {
  if (!pointer.startsWith('/') || pointer.slice(1).includes('/')) return null;
  return pointer.slice(1).replace(/~1/g, '/').replace(/~0/g, '~');
}
```

One cross-cutting HTTP policy; interceptor ordering is explained in How it works.

**File: `src/app/http/retry-after.interceptor.ts`**
```typescript
import { inject } from '@angular/core';
import { HttpErrorResponse, HttpInterceptorFn, HttpResponse } from '@angular/common/http';
import { catchError, finalize, switchMap, tap, throwError, timer } from 'rxjs';
import { isApiUrl } from '../auth/auth.config';
import { Notice } from '../core/notice';
import { parseProblem } from './problem';
export const retryAfterInterceptor: HttpInterceptorFn = (request, next) => {
  if (!isApiUrl(request.url)) return next(request);
  const notice = inject(Notice);
  return next(request).pipe(tap(response => {
    if (response instanceof HttpResponse && new URL(request.url).pathname !== '/health' && response.headers.get('RateLimit-Remaining') === '0') {
      notice.quota.set('Request budget exhausted. Wait before your next action.');
    }
  }), catchError(error => {
    if (!(error instanceof HttpErrorResponse) || error.status !== 429) return throwError(() => error);
    const seconds = parseProblem(429, error.error, error.headers).retryAfter ?? 1;
    if (request.method !== 'GET') return throwError(() => error);
    notice.countdown.set(seconds);
    const clock = setInterval(() => notice.countdown.update(n => Math.max(0, n - 1)), 1000);
    return timer(seconds * 1000).pipe(switchMap(() => next(request)), finalize(() => {
      clearInterval(clock); notice.countdown.set(0);
    }));
  }));
};
```
Expected result: the named files exist under code, saved with the exact contents shown. No program must be running while you create them.

### Step 6. State and shared presentation
Create the concrete parent directories (silent on success), then create/replace every named file below in your editor. Save after each file; do not type the markdown fences.

**Command: code folder, parent directories**
```powershell
New-Item -ItemType Directory -Force 'src/app/core','src/app/shared' | Out-Null
```

**Command: code folder, macOS/Linux**
```bash
mkdir -p src/app/core src/app/shared
```

Shared client state/lifecycle logic. Signals notify a zoneless app; asynchronous failures remain visible.

**File: `src/app/core/actions.ts`**
```typescript
import { inject, Injectable } from '@angular/core';
import { Connectivity } from './connectivity';
import { Notice } from './notice';
@Injectable({ providedIn: 'root' })
export class Actions {
  private readonly notice = inject(Notice);
  private readonly connection = inject(Connectivity);
  private lastRead?: () => Promise<unknown>;
  async run(work: () => Promise<unknown>, write = false): Promise<boolean> {
    if (!write) this.lastRead = work;
    this.notice.error.set(null);
    if (write && !this.connection.online()) { this.notice.fail({ status: 0 }); return false; }
    try { await work(); if (write) this.notice.success('Saved'); return true; }
    catch (error) { this.notice.fail(error); return false; }
  }
  async retry(): Promise<void> {
    this.connection.retry();
    if (this.lastRead) await this.run(this.lastRead);
  }
}
```

Shared client state/lifecycle logic. Signals notify a zoneless app; asynchronous failures remain visible.

**File: `src/app/core/connectivity.ts`**
```typescript
import { inject, Injectable, signal, DestroyRef } from '@angular/core';
import { fromEvent, merge } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
@Injectable({ providedIn: 'root' })
export class Connectivity {
  readonly online = signal(navigator.onLine);
  constructor() {
    merge(fromEvent(window, 'online'), fromEvent(window, 'offline')).pipe(takeUntilDestroyed(inject(DestroyRef)))
      .subscribe(() => this.online.set(navigator.onLine));
  }
  failed(): void { this.online.set(false); }
  retry(): void { this.online.set(navigator.onLine); }
}
```

Shared client state/lifecycle logic. Signals notify a zoneless app; asynchronous failures remain visible.

**File: `src/app/core/notice.ts`**
```typescript
import { afterNextRender, inject, Injectable, Injector, signal } from '@angular/core';
import { ApiProblem, parseProblem } from '../http/problem';
@Injectable({ providedIn: 'root' })
export class Notice {
  private readonly injector = inject(Injector);
  activeForm: object | null = null;
  readonly error = signal<ApiProblem | null>(null);
  readonly toast = signal('');
  readonly countdown = signal(0);
  readonly quota = signal('');
  fail(error: unknown): void {
    const value = error as Partial<ApiProblem>;
    this.error.set(value.type && typeof value.status === 'number' ? value as ApiProblem : parseProblem(0, null, { get: () => null }));
    if (value.code === 'last_lead') this.error.update(p => p && ({ ...p, detail: 'Keep at least one lead on the team. Promote another member first.' }));
    afterNextRender(() => document.getElementById('error-summary')?.focus(), { injector: this.injector });
  }
  success(message: string): void { this.error.set(null); this.toast.set(message); }
}
```

Shared client state/lifecycle logic. Signals notify a zoneless app; asynchronous failures remain visible.

**File: `src/app/core/state.ts`**
```typescript
import { signal } from '@angular/core';
export interface Versioned<T> { value: T; etag: string; }
export interface ListState<T> {
  items: T[];
  nextCursor: string | null;
  status: 'idle' | 'loading' | 'loadingMore' | 'error';
  error?: unknown;
}
export class CursorList<T> {
  readonly state = signal<ListState<T>>({ items: [], nextCursor: null, status: 'idle' });
  private loader?: (cursor?: string) => Promise<{ items: T[]; page: { nextCursor: string | null } }>;
  private generation = 0;
  async load(loader: NonNullable<CursorList<T>['loader']>): Promise<void> {
    this.loader = loader;
    this.generation++;
    this.state.set({ items: [], nextCursor: null, status: 'loading' });
    await this.fetch(false);
  }
  async more(): Promise<void> {
    if (!this.state().nextCursor || this.state().status === 'loadingMore') return;
    this.state.update(s => ({ ...s, status: 'loadingMore' }));
    await this.fetch(true);
  }
  private async fetch(append: boolean): Promise<void> {
    const generation = this.generation;
    try {
      const page = await this.loader!(append ? this.state().nextCursor! : undefined);
      if (generation !== this.generation) return;
      this.state.update(s => ({ items: append ? [...s.items, ...page.items] : page.items,
        nextCursor: page.page.nextCursor, status: 'idle' }));
    } catch (error) {
      if (append && (error as { status?: number }).status === 400) { await this.load(this.loader!); return; }
      if (generation === this.generation) this.state.update(s => ({ ...s, status: 'error', error }));
      throw error;
    }
  }
}
export class Creation {
  private pending?: { json: string; key: string };
  async send<T, R>(body: T, submit: (key: string, body: T) => Promise<R>): Promise<R> {
    const json = JSON.stringify(body);
    if (!this.pending || this.pending.json !== json) this.pending = { json, key: crypto.randomUUID() };
    const result = await submit(this.pending.key, body);
    this.pending = undefined;
    return result;
  }
}
export function etag<T>(response: { body: T; headers: { get(name: string): string | null } }): Versioned<T> {
  const value = response.headers.get('ETag');
  if (!value) throw new Error('Missing ETag. Check backend CORS Expose-Headers.');
  return { value: response.body, etag: value };
}
```

Shared client state/lifecycle logic. Signals notify a zoneless app; asynchronous failures remain visible.

**File: `src/app/core/title-focus.ts`**
```typescript
import { afterNextRender, inject, Injectable, Injector } from '@angular/core';
import { TitleStrategy, RouterStateSnapshot } from '@angular/router';
import { Title } from '@angular/platform-browser';
@Injectable({ providedIn: 'root' })
export class TitleFocus extends TitleStrategy {
  private readonly title = inject(Title);
  private readonly injector = inject(Injector);
  override updateTitle(snapshot: RouterStateSnapshot): void {
    this.title.setTitle(`${this.buildTitle(snapshot) ?? 'Tasks and Teams'} | Tasks and Teams`);
    afterNextRender(() => document.querySelector<HTMLElement>('main h1')?.focus(), { injector: this.injector });
  }
}
```

A shared presentation primitive: no feature imports or direct API requests.

**File: `src/app/shared/confirm-dialog.ts`**
```typescript
import { ChangeDetectionStrategy, Component, ElementRef, viewChild } from '@angular/core';
@Component({ selector: 'app-confirm-dialog', changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<dialog #dialog aria-labelledby="confirm-title" (cancel)="finish(false)">
    <h2 id="confirm-title">Delete this item?</h2><p>This cannot be undone.</p>
    <button autofocus (click)="finish(false)">Cancel</button><button (click)="finish(true)">Delete</button>
  </dialog>` })
export class ConfirmDialog {
  private readonly dialog = viewChild.required<ElementRef<HTMLDialogElement>>('dialog');
  private resolve?: (value: boolean) => void;
  ask(): Promise<boolean> { this.dialog().nativeElement.showModal(); return new Promise(resolve => { this.resolve = resolve; }); }
  protected finish(value: boolean): void { this.dialog().nativeElement.close(); this.resolve?.(value); }
}
```

A shared presentation primitive: no feature imports or direct API requests.

**File: `src/app/shared/conflict-dialog.ts`**
```typescript
import { ChangeDetectionStrategy, Component, ElementRef, input, output, viewChild } from '@angular/core';
import { JsonPipe } from '@angular/common';
import { Task, TaskUpdate } from '../api/models';
import { Icon } from './icon';
@Component({ selector: 'app-conflict-dialog', imports: [JsonPipe, Icon], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<dialog #dialog aria-labelledby="conflict-title" (cancel)="close.emit()">
    <h2 id="conflict-title"><app-icon name="ui/alert-triangle" />Someone saved first</h2>
    <h3>Server version</h3><pre>{{ server() | json }}</pre><h3>Your changes</h3><pre>{{ local() | json }}</pre>
    <button autofocus (click)="choose.emit('server')">Use the server version</button>
    <button (click)="choose.emit('apply')">Apply my changes on top</button><button (click)="close.emit()">Keep editing</button>
  </dialog>` })
export class ConflictDialog {
  readonly server = input<Task | null>(null);
  readonly local = input<TaskUpdate | null>(null);
  readonly choose = output<'server' | 'apply'>();
  readonly close = output<void>();
  private readonly dialog = viewChild.required<ElementRef<HTMLDialogElement>>('dialog');
  open(): void { if (!this.dialog().nativeElement.open) this.dialog().nativeElement.showModal(); }
  dismiss(): void { this.dialog().nativeElement.close(); }
}
```

A shared presentation primitive: no feature imports or direct API requests.

**File: `src/app/shared/feedback.ts`**
```typescript
import { ChangeDetectionStrategy, Component, inject, output } from '@angular/core';
import { Notice } from '../core/notice';
import { Connectivity } from '../core/connectivity';
import { Icon } from './icon';
@Component({ selector: 'app-feedback', imports: [Icon], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `@if (!connection.online()) { <aside role="status"><app-icon name="cloud-network/cloud-off" /> Offline. Writes are disabled.</aside> }
    @if (notice.quota()) { <p role="status">{{ notice.quota() }}</p> }
    @if (notice.countdown()) { <p role="status">Too many requests, retrying in {{ notice.countdown() }} s</p> }
    @if (notice.error(); as error) {
      <section id="error-summary" tabindex="-1" role="alert">
        <h2>{{ error.status === 403 ? 'You do not have access' : error.status === 404 ? 'Not found' : 'Request failed' }}</h2>
        <p>{{ error.detail }}</p>@if (error.status === 429) { <p>Wait {{ error.retryAfter ?? 1 }} seconds before submitting again. Writes are never retried automatically.</p> }
        @if (error.traceId) { <p>Support trace: {{ error.traceId }}</p> }
        @for (field of error.errors ?? []; track field.pointer) { <p>{{ field.pointer }}: {{ field.detail }}</p> }
        @if (error.status !== 403 && error.status !== 404) { <button (click)="retry.emit()"><app-icon name="arrows/refresh-cw" />Try again</button> }
        <button aria-label="Dismiss error" (click)="notice.error.set(null)"><app-icon name="ui/x" /></button>
      </section>
    }
    <p role="status" aria-live="polite"><app-icon name="ui/check-circle" />{{ notice.toast() }}</p>` })
export class Feedback {
  protected readonly notice = inject(Notice);
  protected readonly connection = inject(Connectivity);
  readonly retry = output<void>();
}
```

A shared presentation primitive: no feature imports or direct API requests.

**File: `src/app/shared/field-errors.ts`**
```typescript
import { Directive, effect, ElementRef, HostListener, inject, Renderer2 } from '@angular/core';
import { FormGroupDirective } from '@angular/forms';
import { Notice } from '../core/notice';
import { fieldName } from '../http/problem';
@Directive({ selector: 'form[formGroup][appFieldErrors]' })
export class FieldErrors {
  private readonly form = inject(FormGroupDirective);
  private readonly element = inject<ElementRef<HTMLFormElement>>(ElementRef);
  private readonly renderer = inject(Renderer2);
  private readonly notice = inject(Notice);
  private readonly identity = {};
  @HostListener('submit') onSubmit(): void { this.notice.activeForm = this.identity; }
  constructor() {
    effect(() => {
      const problem = this.notice.error();
      if (this.notice.activeForm !== this.identity) return;
      if (problem?.status === 409) {
        let summary = this.element.nativeElement.querySelector<HTMLElement>('[data-api-conflict]');
        if (!summary) {
          summary = this.renderer.createElement('p') as HTMLElement;
          this.renderer.setAttribute(summary, 'data-api-conflict', '');
          this.renderer.setAttribute(summary, 'role', 'alert');
          this.renderer.appendChild(this.element.nativeElement, summary);
        }
        this.renderer.setProperty(summary, 'textContent', problem.detail ?? problem.title);
      }
      for (const error of problem?.errors ?? []) {
        const name = fieldName(error.pointer);
        if (!name || !this.form.form?.get(name)) continue;
        const input = Array.from(this.element.nativeElement.querySelectorAll<HTMLElement>('[formcontrolname]'))
          .find(node => node.getAttribute('formcontrolname') === name);
        if (!input) continue;
        const id = input.id + '-api-error';
        let message = this.element.nativeElement.querySelector<HTMLElement>('#' + id);
        if (!message) {
          message = this.renderer.createElement('p') as HTMLElement;
          this.renderer.setAttribute(message, 'id', id);
          this.renderer.appendChild(input.parentElement, message);
        }
        this.renderer.setProperty(message, 'textContent', error.detail);
        const described = new Set((input.getAttribute('aria-describedby') ?? '').split(' ').filter(Boolean));
        described.add(id);
        this.renderer.setAttribute(input, 'aria-describedby', [...described].join(' '));
        this.renderer.setAttribute(input, 'aria-invalid', 'true');
        // Clear server errors on the next input, not by erasing the user's draft.
        const stop = this.renderer.listen(input, 'input', () => {
          this.renderer.removeAttribute(input, 'aria-invalid');
          this.renderer.setProperty(message, 'textContent', ''); stop();
        });
      }
    });
  }
}
```

A shared presentation primitive: no feature imports or direct API requests.

**File: `src/app/shared/icon.ts`**
```typescript
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
@Component({ selector: 'app-icon', changeDetection: ChangeDetectionStrategy.OnPush,
  host: { 'aria-hidden': 'true' },
  template: `<span class="icon" [style.mask]="'url(/icons/' + name() + '.svg) center / contain no-repeat'"></span>` })
export class Icon { readonly name = input.required<string>(); }
```
Expected result: the named files exist under code, saved with the exact contents shown. No program must be running while you create them.

### Step 7. Feature screens and stores
Create the concrete parent directories (silent on success), then create/replace every named file below in your editor. Save after each file; do not type the markdown fences.

**Command: code folder, parent directories**
```powershell
New-Item -ItemType Directory -Force 'src/app/features/audit','src/app/features/callback','src/app/features/dashboard','src/app/features/forbidden','src/app/features/login','src/app/features/not-found','src/app/features/projects','src/app/features/task-detail','src/app/features/tasks','src/app/features/team-detail','src/app/features/teams' | Out-Null
```

**Command: code folder, macOS/Linux**
```bash
mkdir -p src/app/features/audit src/app/features/callback src/app/features/dashboard src/app/features/forbidden src/app/features/login src/app/features/not-found src/app/features/projects src/app/features/task-detail src/app/features/tasks src/app/features/team-detail src/app/features/teams
```

This store owns server data and typed generated operations; the page below never constructs an HttpClient request.

**File: `src/app/features/audit/audit.store.ts`**
```typescript
import { inject, Injectable } from '@angular/core';
import { Api } from '../../api/api';
import { listAuditLog } from '../../api/functions';
import { AuditEntry } from '../../api/models';
import { ListAuditLog$Params } from '../../api/fn/audit/list-audit-log';
import { CursorList } from '../../core/state';
@Injectable({ providedIn: 'root' })
export class AuditStore extends CursorList<AuditEntry> {
  private readonly api = inject(Api);
  loadAudit(filter: ListAuditLog$Params): Promise<void> { return this.load(cursor => this.api.invoke(listAuditLog, { ...filter, limit: 25, cursor })); }
}
```

This standalone OnPush page presents the named screen. Labels and concrete route bindings are part of the implementation, not omitted scaffolding.

**File: `src/app/features/audit/audit.ts`**
```typescript
import { FieldErrors } from '../../shared/field-errors';
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AUDIT_ENTITY_TYPE } from '../../api/models/audit-entity-type-array';
import { Actions } from '../../core/actions';
import { AuditStore } from './audit.store';
@Component({ selector: 'app-audit', imports: [FieldErrors, ReactiveFormsModule], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Audit log</h1><form appFieldErrors [formGroup]="form" (ngSubmit)="filterUrl()">
    <label for="audit-entity">Entity type</label><select id="audit-entity" formControlName="entityType"><option value="">All</option>@for (entity of entities; track entity) { <option [value]="entity">{{ entity }}</option> }</select>
    <label for="audit-actor">Actor UUID</label><input id="audit-actor" formControlName="actorId">
    <label for="audit-from">From (inclusive UTC)</label><input id="audit-from" type="datetime-local" formControlName="from">
    <label for="audit-to">To (exclusive UTC)</label><input id="audit-to" type="datetime-local" formControlName="to"><button>Apply filters</button></form>
    <div class="table-scroll"><table><caption>Changes recorded by the API</caption><thead><tr><th scope="col">When</th><th scope="col">Actor</th><th scope="col">Action</th><th scope="col">Entity</th></tr></thead><tbody>
      @for (entry of store.state().items; track entry.id) { <tr><td>{{ date(entry.occurredAt) }}</td><td>{{ entry.actorId ?? 'System' }}</td><td>{{ entry.action }}</td><td>{{ entry.entityType }} {{ entry.entityId }}</td></tr> }
    </tbody></table></div><button [disabled]="!store.state().nextCursor" (click)="more()">Load more audit entries</button>` })
export class Audit {
  protected readonly store = inject(AuditStore);
  protected readonly entities = AUDIT_ENTITY_TYPE;
  private readonly actions = inject(Actions);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  protected readonly form = inject(FormBuilder).nonNullable.group({ entityType: '', actorId: '', from: '', to: '' });
  constructor() { this.route.queryParamMap.pipe(takeUntilDestroyed()).subscribe(params => {
    const entityType = AUDIT_ENTITY_TYPE.find(value => value === params.get('entityType'));
    const actorId = params.get('actorId') || undefined;
    const from = params.get('from') || undefined; const to = params.get('to') || undefined;
    this.form.setValue({ entityType: entityType ?? '', actorId: actorId ?? '', from: from?.replace(/Z$/, '') ?? '', to: to?.replace(/Z$/, '') ?? '' });
    void this.actions.run(() => this.store.loadAudit({ entityType, actorId, from, to }));
  }); }
  protected filterUrl(): void { const values = this.form.getRawValue(); void this.router.navigate([], { relativeTo: this.route, queryParams: { ...values, from: values.from ? values.from + 'Z' : null, to: values.to ? values.to + 'Z' : null } }); }
  protected more(): void { void this.actions.run(() => this.store.more()); }
  protected date(value: string): string { return new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value)); }
}
```

This standalone OnPush page presents the named screen. Labels and concrete route bindings are part of the implementation, not omitted scaffolding.

**File: `src/app/features/callback/callback.ts`**
```typescript
import { ChangeDetectionStrategy, Component, inject, OnInit } from '@angular/core';
import { AuthService } from '../../auth/auth.service';
@Component({ selector: 'app-callback', changeDetection: ChangeDetectionStrategy.OnPush,
  template: '<h1 tabindex="-1">Callback</h1><p role="status">Signing you in</p>' })
export class Callback implements OnInit {
  private readonly auth = inject(AuthService);
  ngOnInit(): void { void this.auth.finish(); }
}
```

This store owns server data and typed generated operations; the page below never constructs an HttpClient request.

**File: `src/app/features/dashboard/dashboard.store.ts`**
```typescript
import { inject, Injectable, signal } from '@angular/core';
import { Api } from '../../api/api';
import { getHealth } from '../../api/functions';
import { AuthService } from '../../auth/auth.service';
@Injectable({ providedIn: 'root' })
export class DashboardStore {
  private readonly api = inject(Api);
  private readonly auth = inject(AuthService);
  readonly health = signal('checking');
  async load(): Promise<void> { await this.auth.loadMe(); this.health.set((await this.api.invoke(getHealth)).status); }
}
```

This standalone OnPush page presents the named screen. Labels and concrete route bindings are part of the implementation, not omitted scaffolding.

**File: `src/app/features/dashboard/dashboard.ts`**
```typescript
import { ChangeDetectionStrategy, Component, inject, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../auth/auth.service';
import { Actions } from '../../core/actions';
import { DashboardStore } from './dashboard.store';
@Component({ selector: 'app-dashboard', imports: [RouterLink], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Dashboard</h1><p>Hello, {{ auth.user()?.displayName }}</p>
    <p>Roles: {{ auth.roles().join(', ') }}</p><p>Scopes: {{ auth.scopes().join(', ') }}</p>
    <p role="status">API: {{ store.health() }}</p><h2>My teams</h2><ul>
    @for (team of auth.user()?.teams ?? []; track team.teamId) {
      <li><a [routerLink]="['/teams', team.teamId]">{{ team.name }}</a> ({{ team.role }})</li>
    }</ul>` })
export class Dashboard implements OnInit {
  protected readonly auth = inject(AuthService);
  protected readonly store = inject(DashboardStore);
  private readonly actions = inject(Actions);
  ngOnInit(): void { void this.actions.run(() => this.store.load()); }
}
```

This standalone OnPush page presents the named screen. Labels and concrete route bindings are part of the implementation, not omitted scaffolding.

**File: `src/app/features/forbidden/forbidden.ts`**
```typescript
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';
@Component({ selector: 'app-forbidden', imports: [RouterLink], changeDetection: ChangeDetectionStrategy.OnPush,
  template: '<h1 tabindex="-1">You do not have access</h1><p>An administrator is required.</p><a routerLink="/">Go home</a>' })
export class Forbidden {}
```

This standalone OnPush page presents the named screen. Labels and concrete route bindings are part of the implementation, not omitted scaffolding.

**File: `src/app/features/login/login.ts`**
```typescript
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { AuthService } from '../../auth/auth.service';
import { safeReturn } from '../../auth/auth.config';
@Component({ selector: 'app-login', changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Login</h1><p>Use your Tasks and Teams account on the Keycloak page.</p>
    @if (auth.error()) { <p role="alert">{{ auth.error() }}</p> }
    <button type="button" (click)="signIn()">Sign in</button>` })
export class Login {
  protected readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  protected signIn(): void {
    void this.auth.signIn(safeReturn(this.route.snapshot.queryParamMap.get('returnUrl')));
  }
}
```

This standalone OnPush page presents the named screen. Labels and concrete route bindings are part of the implementation, not omitted scaffolding.

**File: `src/app/features/not-found/not-found.ts`**
```typescript
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';
@Component({ selector: 'app-not-found', imports: [RouterLink], changeDetection: ChangeDetectionStrategy.OnPush,
  template: '<h1 tabindex="-1">Not found</h1><p>This page is not available.</p><a routerLink="/">Go home</a>' })
export class NotFound {}
```

This store owns server data and typed generated operations; the page below never constructs an HttpClient request.

**File: `src/app/features/projects/projects.store.ts`**
```typescript
import { inject, Injectable } from '@angular/core';
import { Api } from '../../api/api';
import { createProject, deleteProject, getProject, listProjects, updateProject } from '../../api/functions';
import { Project, ProjectCreate } from '../../api/models';
import { Creation, CursorList, etag } from '../../core/state';
@Injectable({ providedIn: 'root' })
export class ProjectsStore extends CursorList<Project> {
  private readonly api = inject(Api);
  private readonly creation = new Creation();
  loadProjects(teamId: string, archived: boolean): Promise<void> { return this.load(cursor => this.api.invoke(listProjects, { teamId, archived, limit: 25, cursor })); }
  create(teamId: string, body: ProjectCreate): Promise<Project> { return this.creation.send(body, (key, body) => this.api.invoke(createProject, { teamId, 'Idempotency-Key': key, body })); }
  remove(projectId: string): Promise<void> { return this.api.invoke(deleteProject, { projectId }); }
  async archive(projectId: string, archived: boolean): Promise<void> {
    const snapshot = this.state();
    this.state.update(s => ({ ...s, items: s.items.map(p => p.id === projectId ? { ...p, archived } : p) }));
    try {
      const current = etag(await this.api.invoke$Response(getProject, { projectId }));
      await this.api.invoke(updateProject, { projectId, 'If-Match': current.etag, body: { archived } });
    } catch (error) { this.state.set(snapshot); throw error; }
  }
}
```

This standalone OnPush page presents the named screen. Labels and concrete route bindings are part of the implementation, not omitted scaffolding.

**File: `src/app/features/projects/projects.ts`**
```typescript
import { ConfirmDialog } from '../../shared/confirm-dialog';
import { FieldErrors } from '../../shared/field-errors';
import { ChangeDetectionStrategy, Component, inject, viewChild } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { combineLatest } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AuthService } from '../../auth/auth.service';
import { Actions } from '../../core/actions';
import { Connectivity } from '../../core/connectivity';
import { ProjectsStore } from './projects.store';
@Component({ selector: 'app-projects', imports: [FieldErrors, ReactiveFormsModule, RouterLink, ConfirmDialog], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Projects</h1><button (click)="toggle()">{{ archived ? 'Show active' : 'Show archived' }}</button>
    @if (auth.isLead(teamId)) { <h2>Create project</h2><form appFieldErrors [formGroup]="form" (ngSubmit)="create()">
      <label for="project-key">Key (2-10 uppercase letters or digits, first a letter)</label><input id="project-key" formControlName="key" required pattern="[A-Z][A-Z0-9]{1,9}" aria-describedby="key-help">
      <p id="key-help">Example: PLAT. Keys are unique within the team.</p><label for="project-name">Name</label><input id="project-name" formControlName="name" required maxlength="120">
      <label for="project-description">Description</label><textarea id="project-description" formControlName="description" maxlength="2000"></textarea>
      <button [disabled]="form.invalid || !connection.online()">Create project</button></form> }
    <ul>@for (project of store.state().items; track project.id) { <li><a [routerLink]="['/projects', project.id]">{{ project.key }}: {{ project.name }}</a>
      @if (auth.isLead(teamId)) { <button [disabled]="!connection.online()" (click)="archive(project.id, !project.archived)">{{ project.archived ? 'Restore' : 'Archive' }}</button><button [disabled]="!connection.online()" (click)="remove(project.id)">Delete project</button> }</li> }</ul>
    <button [disabled]="!store.state().nextCursor" (click)="more()">Load more projects</button><app-confirm-dialog />` })
export class Projects {
  protected readonly store = inject(ProjectsStore);
  protected readonly auth = inject(AuthService);
  protected readonly connection = inject(Connectivity);
  private readonly actions = inject(Actions);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly confirm = viewChild.required(ConfirmDialog);
  protected teamId = '';
  protected archived = false;
  protected readonly form = inject(FormBuilder).nonNullable.group({ key: ['', [Validators.required, Validators.pattern(/^[A-Z][A-Z0-9]{1,9}$/)]], name: ['', Validators.required], description: '' });
  constructor() { combineLatest([this.route.paramMap, this.route.queryParamMap]).pipe(takeUntilDestroyed()).subscribe(([path, query]) => {
    this.teamId = path.get('teamId')!; this.archived = query.get('archived') === 'true'; this.reload();
  }); }
  private reload(): void { void this.actions.run(() => this.store.loadProjects(this.teamId, this.archived)); }
  protected toggle(): void { void this.router.navigate([], { relativeTo: this.route, queryParams: { archived: !this.archived } }); }
  protected async create(): Promise<void> { if (this.form.valid && await this.actions.run(() => this.store.create(this.teamId, this.form.getRawValue()), true)) { this.form.reset(); this.reload(); } }
  protected async archive(id: string, value: boolean): Promise<void> { if (await this.actions.run(() => this.store.archive(id, value), true)) this.reload(); }
  protected async remove(id: string): Promise<void> { if (await this.confirm().ask() && await this.actions.run(() => this.store.remove(id), true)) this.reload(); }
  protected more(): void { void this.actions.run(() => this.store.more()); }
}
```

This store owns server data and typed generated operations; the page below never constructs an HttpClient request.

**File: `src/app/features/task-detail/task-detail.store.ts`**
```typescript
import { inject, Injectable, signal } from '@angular/core';
import { Api } from '../../api/api';
import { getTask, getProject, updateTask, completeTask, reassignTask, deleteTask, listComments, createComment, deleteComment, listMembers } from '../../api/functions';
import { Comment, Member, Task, TaskUpdate } from '../../api/models';
import { ApiProblem } from '../../http/problem';
import { StrictHttpResponse } from '../../api/strict-http-response';
import { Creation, CursorList, etag, Versioned } from '../../core/state';
@Injectable({ providedIn: 'root' })
export class TaskDetailStore {
  private readonly api = inject(Api);
  private readonly creation = new Creation();
  readonly task = signal<Versioned<Task> | null>(null);
  readonly teamId = signal('');
  readonly comments = new CursorList<Comment>();
  readonly members = new CursorList<Member>();
  readonly saving = signal(false);
  readonly conflict = signal<{ server: Task; local: TaskUpdate } | null>(null);
  async load(id: string): Promise<void> {
    this.task.set(null);
    this.task.set(etag(await this.api.invoke$Response(getTask, { taskId: id })));
    const project = await this.api.invoke(getProject, { projectId: this.task()!.value.projectId });
    this.teamId.set(project.teamId);
    await this.members.load(cursor => this.api.invoke(listMembers, { teamId: project.teamId, limit: 25, cursor }));
    await this.comments.load(cursor => this.api.invoke(listComments, { taskId: id, limit: 25, cursor }));
  }
  save(body: TaskUpdate): Promise<void> {
    const old = this.task()!;
    return this.optimistic(body, () => this.api.invoke$Response(updateTask, { taskId: old.value.id, 'If-Match': old.etag, body }));
  }
  private async optimistic(body: TaskUpdate, change: () => Promise<StrictHttpResponse<Task>>): Promise<void> {
    const old = this.task()!;
    this.saving.set(true);
    this.task.set({ value: { ...old.value, ...body } as Task, etag: old.etag });
    try {
      this.task.set(etag(await change()));
      this.conflict.set(null);
    } catch (error) {
      this.task.set(old);
      if ((error as ApiProblem).status === 412) {
        const server = await this.api.invoke(getTask, { taskId: old.value.id });
        this.conflict.set({ server, local: { ...body } });
      }
      throw error;
    } finally { this.saving.set(false); }
  }
  async resolve(choice: 'server' | 'apply'): Promise<void> {
    const local = this.conflict()!.local;
    this.task.set(etag(await this.api.invoke$Response(getTask, { taskId: this.task()!.value.id })));
    if (choice === 'apply') await this.save(local);
    this.conflict.set(null);
  }
  async revalidate(): Promise<void> {
    const old = this.task();
    if (!old || this.saving() || this.conflict()) return;
    try { this.task.set(etag(await this.api.invoke$Response(getTask, { taskId: old.value.id, 'If-None-Match': old.etag }))); }
    catch (error) { if ((error as { status?: number }).status !== 304) throw error; }
  }
  async complete(): Promise<void> {
    const old = this.task()!;
    await this.optimistic({ status: 'done' }, () => this.api.invoke$Response(completeTask, { taskId: old.value.id, 'If-Match': old.etag }));
  }
  async reassign(assigneeId: string | null): Promise<void> {
    const old = this.task()!;
    await this.optimistic({ assigneeId }, () => this.api.invoke$Response(reassignTask, { taskId: old.value.id, 'If-Match': old.etag, body: { assigneeId } }));
  }
  remove(): Promise<void> { return this.api.invoke(deleteTask, { taskId: this.task()!.value.id, 'If-Match': this.task()!.etag }); }
  async comment(body: string): Promise<void> {
    const taskId = this.task()!.value.id;
    await this.creation.send({ body }, (key, body) => this.api.invoke(createComment, { taskId, 'Idempotency-Key': key, body }));
    await this.comments.load(cursor => this.api.invoke(listComments, { taskId, limit: 25, cursor }));
    while (this.comments.state().nextCursor) await this.comments.more();
  }
  async removeComment(commentId: string): Promise<void> {
    await this.api.invoke(deleteComment, { commentId });
    this.comments.state.update(s => ({ ...s, items: s.items.filter(c => c.id !== commentId) }));
  }
}
```

This standalone OnPush page presents the named screen. Labels and concrete route bindings are part of the implementation, not omitted scaffolding.

**File: `src/app/features/task-detail/task-detail.ts`**
```typescript
import { FieldErrors } from '../../shared/field-errors';
import { ChangeDetectionStrategy, Component, effect, inject, viewChild } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { TaskPriority, TaskStatus, TaskUpdate } from '../../api/models';
import { TASK_PRIORITY } from '../../api/models/task-priority-array';
import { TASK_STATUS } from '../../api/models/task-status-array';
import { AuthService } from '../../auth/auth.service';
import { Actions } from '../../core/actions';
import { Connectivity } from '../../core/connectivity';
import { ConfirmDialog } from '../../shared/confirm-dialog';
import { Icon } from '../../shared/icon';
import { ConflictDialog } from '../../shared/conflict-dialog';
import { fromEvent } from 'rxjs';
import { TaskDetailStore } from './task-detail.store';
@Component({ selector: 'app-task-detail', imports: [FieldErrors, ReactiveFormsModule, RouterLink, ConfirmDialog, Icon, ConflictDialog], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Task detail</h1>@if (store.task(); as entry) {
    <h2>{{ entry.value.title }}</h2><p>{{ entry.value.description }}</p><p>{{ entry.value.status }} / {{ entry.value.priority }}</p>
    <p>Completed at: {{ date(entry.value.completedAt) }}</p><a [routerLink]="['/projects', entry.value.projectId]">Back to Tasks</a>
    <form appFieldErrors [formGroup]="form" (ngSubmit)="save()">
      <label for="edit-title">Title</label><input id="edit-title" formControlName="title" required maxlength="200">
      <label for="edit-description">Description</label><textarea id="edit-description" formControlName="description" maxlength="10000"></textarea>
      <label for="edit-status">Status</label><select id="edit-status" formControlName="status">@for (status of statuses; track status) { <option [value]="status">{{ status }}</option> }</select>
      <label for="edit-priority">Priority</label><select id="edit-priority" formControlName="priority">@for (priority of priorities; track priority) { <option [value]="priority">{{ priority }}</option> }</select>
      <label for="edit-due">Due date (empty clears it)</label><input id="edit-due" type="date" formControlName="dueDate">
      <button [disabled]="form.invalid || store.saving() || !connection.online()">Save changed fields</button></form>
    <button [disabled]="!connection.online() || store.saving() || entry.value.status === 'done'" (click)="complete()"><app-icon name="ui/check-circle" />Complete task</button>
    @if (auth.isLead(store.teamId())) {
      <form appFieldErrors [formGroup]="assignment" (ngSubmit)="reassign()"><label for="reassign">Assignee</label><select id="reassign" formControlName="assigneeId"><option value="">Unassigned</option>
        @for (member of store.members.state().items; track member.userId) { <option [value]="member.userId">{{ member.displayName }}</option> }</select>
        <button [disabled]="!connection.online()">Reassign task</button></form><button [disabled]="!store.members.state().nextCursor" (click)="moreMembers()">Load more assignees</button>
      <button [disabled]="!connection.online()" (click)="remove()">Delete task</button>
    }
    <h2>Comments</h2><ol>@for (comment of store.comments.state().items; track comment.id) {
      <li><p>{{ comment.body }}</p><p>By {{ comment.author.displayName }} at {{ date(comment.createdAt) }}</p>
      @if (comment.author.id === auth.user()?.id || auth.isLead(store.teamId())) { <button [disabled]="!connection.online()" (click)="removeComment(comment.id)">Delete comment</button> }</li>
    }</ol><button [disabled]="!store.comments.state().nextCursor" (click)="moreComments()">Load more comments</button>
    <form appFieldErrors [formGroup]="commentForm" (ngSubmit)="comment()"><label for="comment">New comment</label><textarea id="comment" formControlName="body" required maxlength="2000"></textarea>
      <button [disabled]="commentForm.invalid || !connection.online()">Add comment</button></form>
  }<app-confirm-dialog /><app-conflict-dialog [server]="store.conflict()?.server ?? null" [local]="store.conflict()?.local ?? null" (choose)="resolve($event)" (close)="cancelConflict()" />` })
export class TaskDetail {
  protected readonly store = inject(TaskDetailStore);
  protected readonly auth = inject(AuthService);
  protected readonly connection = inject(Connectivity);
  private readonly actions = inject(Actions);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly conflictDialog = viewChild.required(ConflictDialog);
  private readonly confirm = viewChild.required(ConfirmDialog);
  private readonly fb = inject(FormBuilder).nonNullable;
  protected readonly statuses = TASK_STATUS;
  protected readonly priorities = TASK_PRIORITY;
  protected readonly form = this.fb.group({ title: ['', Validators.required], description: '', status: this.fb.control<TaskStatus>('todo'), priority: this.fb.control<TaskPriority>('medium'), dueDate: '' });
  protected readonly assignment = this.fb.group({ assigneeId: '' });
  protected readonly commentForm = this.fb.group({ body: ['', Validators.required] });
  constructor() {
    effect(() => { if (this.store.conflict()) this.conflictDialog().open(); });
    fromEvent(window, 'focus').pipe(takeUntilDestroyed()).subscribe(() => {
      if (!this.form.dirty) void this.actions.run(async () => { await this.store.revalidate(); if (this.store.task()) this.resetDraft(); });
    });
    this.route.paramMap.pipe(takeUntilDestroyed()).subscribe(params => {
    void this.actions.run(async () => { await this.store.load(params.get('taskId')!); this.resetDraft(); });
  }); }
  protected resetDraft(): void {
    const value = this.store.task()!.value;
    this.form.reset({ title: value.title, description: value.description, status: value.status, priority: value.priority, dueDate: value.dueDate ?? '' });
    this.assignment.reset({ assigneeId: value.assigneeId ?? '' });
  }
  protected async resolve(choice: 'server' | 'apply'): Promise<void> {
    if (await this.actions.run(() => this.store.resolve(choice), choice === 'apply')) { this.resetDraft(); this.conflictDialog().dismiss(); }
  }
  protected cancelConflict(): void { this.store.conflict.set(null); this.conflictDialog().dismiss(); }
  protected async save(): Promise<void> {
    if (this.form.invalid) return;
    const values = this.form.getRawValue();
    const body: TaskUpdate = {};
    for (const key of ['title', 'description', 'status', 'priority', 'dueDate'] as const) {
      if (this.form.controls[key].dirty) Object.assign(body, { [key]: key === 'dueDate' ? values[key] || null : values[key] });
    }
    if (Object.keys(body).length && await this.actions.run(() => this.store.save(body), true)) this.resetDraft();
  }
  protected async complete(): Promise<void> { if (await this.actions.run(() => this.store.complete(), true)) this.resetDraft(); }
  protected async reassign(): Promise<void> { if (await this.actions.run(() => this.store.reassign(this.assignment.getRawValue().assigneeId || null), true)) this.resetDraft(); }
  protected async remove(): Promise<void> { const projectId = this.store.task()!.value.projectId; if (await this.confirm().ask() && await this.actions.run(() => this.store.remove(), true)) await this.router.navigate(['/projects', projectId]); }
  protected async comment(): Promise<void> { if (this.commentForm.valid && await this.actions.run(() => this.store.comment(this.commentForm.getRawValue().body), true)) this.commentForm.reset(); }
  protected async removeComment(id: string): Promise<void> { if (await this.confirm().ask()) await this.actions.run(() => this.store.removeComment(id), true); }
  protected moreComments(): void { void this.actions.run(() => this.store.comments.more()); }
  protected moreMembers(): void { void this.actions.run(() => this.store.members.more()); }
  protected date(value: string | null): string { return value ? new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value)) : 'Not completed'; }
}
```

This store owns server data and typed generated operations; the page below never constructs an HttpClient request.

**File: `src/app/features/tasks/tasks.store.ts`**
```typescript
import { inject, Injectable, signal } from '@angular/core';
import { Api } from '../../api/api';
import { createTask, getProject, listMembers, listTasks, getTask, updateTask } from '../../api/functions';
import { Member, Project, Task, TaskCreate, TaskStatus } from '../../api/models';
import { ListTasks$Params } from '../../api/fn/tasks/list-tasks';
import { Creation, CursorList, etag } from '../../core/state';
export type TaskFilter = Omit<ListTasks$Params, 'projectId' | 'limit' | 'cursor'>;
@Injectable({ providedIn: 'root' })
export class TasksStore extends CursorList<Task> {
  private readonly api = inject(Api);
  private readonly creation = new Creation();
  readonly project = signal<Project | null>(null);
  readonly members = new CursorList<Member>();
  async loadTasks(projectId: string, filter: TaskFilter): Promise<void> {
    this.project.set(null);
    const project = await this.api.invoke(getProject, { projectId });
    this.project.set(project);
    await this.members.load(cursor => this.api.invoke(listMembers, { teamId: project.teamId, limit: 25, cursor }));
    await this.load(cursor => this.api.invoke(listTasks, { projectId, limit: 25, cursor, ...filter }));
  }
  create(projectId: string, body: TaskCreate): Promise<Task> {
    return this.creation.send(body, (key, body) => this.api.invoke(createTask, { projectId, 'Idempotency-Key': key, body }));
  }
  async move(taskId: string, status: TaskStatus): Promise<void> {
    const snapshot = this.state();
    this.state.update(s => ({ ...s, items: s.items.map(t => t.id === taskId ? { ...t, status } : t) }));
    try {
      const current = etag(await this.api.invoke$Response(getTask, { taskId }));
      await this.api.invoke(updateTask, { taskId, 'If-Match': current.etag, body: { status } });
    } catch (error) { this.state.set(snapshot); throw error; }
  }
}
```

This standalone OnPush page presents the named screen. Labels and concrete route bindings are part of the implementation, not omitted scaffolding.

**File: `src/app/features/tasks/tasks.ts`**
```typescript
import { FieldErrors } from '../../shared/field-errors';
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { combineLatest } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { TASK_STATUS } from '../../api/models/task-status-array';
import { TASK_PRIORITY } from '../../api/models/task-priority-array';
import { TaskPriority, TaskStatus } from '../../api/models';
import { Actions } from '../../core/actions';
import { Connectivity } from '../../core/connectivity';
import { Icon } from '../../shared/icon';
import { TasksStore, TaskFilter } from './tasks.store';
@Component({ selector: 'app-tasks', imports: [FieldErrors, ReactiveFormsModule, RouterLink, Icon], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Tasks</h1><p>{{ store.project()?.name }}</p>
    <details><summary><app-icon name="ui/filter" />Filters</summary><form appFieldErrors [formGroup]="filters" (ngSubmit)="filterUrl()">
      <label for="task-search"><app-icon name="ui/search" />Title text</label><input id="task-search" formControlName="q" maxlength="100">
      <label for="filter-status">Status (multiple allowed)</label><select id="filter-status" multiple formControlName="status">@for (status of statuses; track status) { <option [value]="status">{{ status }}</option> }</select>
      <label for="filter-priority">Priority (multiple allowed)</label><select id="filter-priority" multiple formControlName="priority">@for (priority of priorities; track priority) { <option [value]="priority">{{ priority }}</option> }</select>
      <label for="filter-assignee">Assignee</label><select id="filter-assignee" formControlName="assigneeId"><option value="">Anyone</option>@for (member of store.members.state().items; track member.userId) { <option [value]="member.userId">{{ member.displayName }}</option> }</select>
      <label for="due-after">Due on or after</label><input id="due-after" type="date" formControlName="dueAfter">
      <label for="due-before">Due on or before</label><input id="due-before" type="date" formControlName="dueBefore">
      <label for="task-sort">Sort</label><select id="task-sort" formControlName="sort"><option value="-createdAt">Newest</option><option value="createdAt">Oldest</option><option value="dueDate">Due date</option></select><button>Apply filters</button>
    </form></details>
    <button (click)="viewUrl('list')" [attr.aria-pressed]="view === 'list'"><app-icon name="ui/list" />List</button>
    <button (click)="viewUrl('board')" [attr.aria-pressed]="view === 'board'"><app-icon name="ui/columns" />Board</button>
    <h2>Create task</h2><form appFieldErrors [formGroup]="form" (ngSubmit)="create()">
      <label for="new-title">Title</label><input id="new-title" formControlName="title" required maxlength="200">
      <label for="new-description">Description</label><textarea id="new-description" formControlName="description" maxlength="10000"></textarea>
      <label for="new-priority">Priority</label><select id="new-priority" formControlName="priority">@for (priority of priorities; track priority) { <option [value]="priority">{{ priority }}</option> }</select>
      <label for="new-assignee">Assignee</label><select id="new-assignee" formControlName="assigneeId"><option value="">Unassigned</option>@for (member of store.members.state().items; track member.userId) { <option [value]="member.userId">{{ member.displayName }}</option> }</select>
      <label for="new-due"><app-icon name="time/calendar-days" />Due date</label><input id="new-due" type="date" formControlName="dueDate">
      <button [disabled]="form.invalid || !connection.online()"><app-icon name="ui/plus" />Create task (retry uses the same key)</button></form>
    <button [disabled]="!store.members.state().nextCursor" (click)="moreMembers()">Load more assignees</button>
    @if (view === 'board') { <div class="board">@for (status of statuses; track status) { <section><h2>{{ status }}</h2>
      @for (task of store.state().items; track task.id) { @if (task.status === status) { <article><a [routerLink]="['/tasks', task.id]">{{ task.title }}</a>
        <label [for]="'move-' + task.id">Move {{ task.title }} to</label><select [id]="'move-' + task.id" [value]="task.status" [disabled]="!connection.online()" (change)="move(task.id, $event)">
        @for (target of statuses; track target) { <option [value]="target">{{ target }}</option> }</select></article> } }
    </section>}</div> } @else { <ul>@for (task of store.state().items; track task.id) { <li><a [routerLink]="['/tasks', task.id]">{{ task.title }}</a> {{ task.status }} / {{ task.priority }}</li> }</ul> }
    @if (store.state().status === 'loading') { <p role="status">Loading tasks</p> }
    <button [disabled]="!store.state().nextCursor || store.state().status === 'loadingMore'" (click)="more()">Load more tasks</button>` })
export class Tasks {
  protected readonly store = inject(TasksStore);
  protected readonly connection = inject(Connectivity);
  private readonly actions = inject(Actions);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder).nonNullable;
  protected readonly statuses = TASK_STATUS;
  protected readonly priorities = TASK_PRIORITY;
  protected id = '';
  protected view = 'list';
  private query: TaskFilter = {};
  protected readonly filters = this.fb.group({ q: '', status: this.fb.control<TaskStatus[]>([]), priority: this.fb.control<TaskPriority[]>([]), assigneeId: '', dueAfter: '', dueBefore: '', sort: '-createdAt' });
  protected readonly form = this.fb.group({ title: ['', Validators.required], description: '', priority: this.fb.control<TaskPriority>('medium'), assigneeId: '', dueDate: '' });
  constructor() { combineLatest([this.route.paramMap, this.route.queryParamMap]).pipe(takeUntilDestroyed()).subscribe(([path, query]) => {
    this.id = path.get('projectId')!; this.view = query.get('view') === 'board' ? 'board' : 'list';
    const raw = { q: (query.get('q') ?? '').trim().slice(0, 100), status: query.getAll('status').filter((s): s is TaskStatus => TASK_STATUS.includes(s as TaskStatus)),
      priority: query.getAll('priority').filter((s): s is TaskPriority => TASK_PRIORITY.includes(s as TaskPriority)), assigneeId: query.get('assigneeId') ?? '', dueAfter: query.get('dueAfter') ?? '', dueBefore: query.get('dueBefore') ?? '', sort: query.get('sort') ?? '-createdAt' };
    this.filters.setValue(raw);
    this.query = { ...raw, q: raw.q || undefined, status: raw.status.length ? raw.status : undefined, priority: raw.priority.length ? raw.priority : undefined,
      assigneeId: raw.assigneeId || undefined, dueAfter: raw.dueAfter || undefined, dueBefore: raw.dueBefore || undefined, sort: raw.sort === 'dueDate' || raw.sort === 'createdAt' ? raw.sort : '-createdAt' };
    this.reload();
  }); }
  private reload(): void { void this.actions.run(() => this.store.loadTasks(this.id, this.query)); }
  protected filterUrl(): void { void this.router.navigate([], { relativeTo: this.route, queryParams: { ...this.filters.getRawValue(), view: this.view } }); }
  protected viewUrl(view: string): void { void this.router.navigate([], { relativeTo: this.route, queryParams: { view }, queryParamsHandling: 'merge' }); }
  protected async create(): Promise<void> { if (this.form.invalid) return; const body = this.form.getRawValue();
    if (await this.actions.run(() => this.store.create(this.id, { ...body, assigneeId: body.assigneeId || null, dueDate: body.dueDate || null }), true)) { this.form.reset(); this.reload(); }
  }
  protected async move(id: string, event: Event): Promise<void> { const status = (event.target as HTMLSelectElement).value as TaskStatus; if (await this.actions.run(() => this.store.move(id, status), true)) this.reload(); }
  protected more(): void { void this.actions.run(() => this.store.more()); }
  protected moreMembers(): void { void this.actions.run(() => this.store.members.more()); }
}
```

This store owns server data and typed generated operations; the page below never constructs an HttpClient request.

**File: `src/app/features/team-detail/team-detail.store.ts`**
```typescript
import { inject, Injectable, signal } from '@angular/core';
import { Api } from '../../api/api';
import { getTeam, updateTeam, listMembers, putMember, removeMember } from '../../api/functions';
import { Member, Team, TeamRole } from '../../api/models';
import { CursorList, etag, Versioned } from '../../core/state';
@Injectable({ providedIn: 'root' })
export class TeamDetailStore {
  private readonly api = inject(Api);
  readonly team = signal<Versioned<Team> | null>(null);
  readonly members = new CursorList<Member>();
  async load(id: string): Promise<void> {
    this.team.set(null);
    this.team.set(etag(await this.api.invoke$Response(getTeam, { teamId: id })));
    await this.members.load(cursor => this.api.invoke(listMembers, { teamId: id, limit: 25, cursor }));
  }
  async save(name: string, description: string): Promise<void> {
    const old = this.team()!;
    this.team.set({ value: { ...old.value, name, description }, etag: old.etag });
    try {
      this.team.set(etag(await this.api.invoke$Response(updateTeam, { teamId: old.value.id, 'If-Match': old.etag, body: { name, description } })));
    } catch (error) { this.team.set(old); throw error; }
  }
  async put(userId: string, role: TeamRole): Promise<void> {
    await this.api.invoke(putMember, { teamId: this.team()!.value.id, userId, body: { role } });
    await this.load(this.team()!.value.id);
  }
  async remove(userId: string): Promise<void> {
    await this.api.invoke(removeMember, { teamId: this.team()!.value.id, userId });
    await this.load(this.team()!.value.id);
  }
}
```

This standalone OnPush page presents the named screen. Labels and concrete route bindings are part of the implementation, not omitted scaffolding.

**File: `src/app/features/team-detail/team-detail.ts`**
```typescript
import { FieldErrors } from '../../shared/field-errors';
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AuthService } from '../../auth/auth.service';
import { Actions } from '../../core/actions';
import { Connectivity } from '../../core/connectivity';
import { TeamDetailStore } from './team-detail.store';
@Component({ selector: 'app-team-detail', imports: [FieldErrors, ReactiveFormsModule, RouterLink], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Team detail</h1>@if (store.team(); as entry) {
    <p>{{ entry.value.name }}: {{ entry.value.description }}</p><a [routerLink]="['/teams', id, 'projects']">Projects</a>
    <nav aria-label="Team sections"><button (click)="membersTab = false" [attr.aria-pressed]="!membersTab">Details</button><button (click)="membersTab = true" [attr.aria-pressed]="membersTab">Members</button></nav>
    @if (!membersTab && auth.isLead(id)) { <form appFieldErrors [formGroup]="form" (ngSubmit)="save()">
      <label for="edit-team-name">Name</label><input id="edit-team-name" formControlName="name" required maxlength="80">
      <label for="edit-team-description">Description</label><textarea id="edit-team-description" formControlName="description" maxlength="500"></textarea>
      <button [disabled]="form.invalid || !connection.online()">Save team</button></form> }
    @if (membersTab) { <h2>Members</h2><ul>@for (member of store.members.state().items; track member.userId) {
      <li>{{ member.displayName }} ({{ member.role }})
      @if (auth.isLead(id)) { <button [disabled]="!connection.online()" (click)="change(member.userId, member.role === 'lead' ? 'member' : 'lead')">Change role for {{ member.displayName }}</button>
        <button [disabled]="!connection.online()" (click)="remove(member.userId)">Remove {{ member.displayName }}</button> }</li> }</ul>
      <button [disabled]="!store.members.state().nextCursor" (click)="more()">Load more members</button>
      @if (auth.isLead(id)) { <form appFieldErrors [formGroup]="memberForm" (ngSubmit)="put()">
        <label for="member-id">Existing user UUID</label><input id="member-id" formControlName="userId" required>
        <label for="member-role">Role</label><select id="member-role" formControlName="role"><option>member</option><option>lead</option></select>
        <button [disabled]="memberForm.invalid || !connection.online()">Add or update member</button></form> }
    }
  }` })
export class TeamDetail {
  protected readonly store = inject(TeamDetailStore);
  protected readonly auth = inject(AuthService);
  protected readonly connection = inject(Connectivity);
  private readonly actions = inject(Actions);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(FormBuilder).nonNullable;
  protected id = '';
  protected membersTab = false;
  protected readonly form = this.fb.group({ name: ['', Validators.required], description: '' });
  protected readonly memberForm = this.fb.group({ userId: ['', Validators.required], role: 'member' });
  constructor() { this.route.paramMap.pipe(takeUntilDestroyed()).subscribe(params => {
    this.id = params.get('teamId')!;
    void this.actions.run(async () => { await this.store.load(this.id); this.form.setValue({ name: this.store.team()!.value.name, description: this.store.team()!.value.description }); });
  }); }
  protected save(): void { if (this.form.valid) { const v = this.form.getRawValue(); void this.actions.run(() => this.store.save(v.name, v.description), true); } }
  protected put(): void { if (this.memberForm.valid) { const v = this.memberForm.getRawValue(); this.change(v.userId, v.role === 'lead' ? 'lead' : 'member'); } }
  protected change(id: string, role: 'lead' | 'member'): void { void this.actions.run(() => this.store.put(id, role), true); }
  protected remove(id: string): void { void this.actions.run(() => this.store.remove(id), true); }
  protected more(): void { void this.actions.run(() => this.store.members.more()); }
}
```

This store owns server data and typed generated operations; the page below never constructs an HttpClient request.

**File: `src/app/features/teams/teams.store.ts`**
```typescript
import { inject, Injectable } from '@angular/core';
import { Api } from '../../api/api';
import { createTeam, deleteTeam, listTeams } from '../../api/functions';
import { Team } from '../../api/models';
import { Creation, CursorList } from '../../core/state';
@Injectable({ providedIn: 'root' })
export class TeamsStore extends CursorList<Team> {
  private readonly api = inject(Api);
  private readonly creation = new Creation();
  loadTeams(q = '', sort: '-createdAt' | 'createdAt' = '-createdAt'): Promise<void> {
    return this.load(cursor => this.api.invoke(listTeams, { q: q.trim() || undefined, sort, limit: 25, cursor }));
  }
  create(name: string, description: string): Promise<Team> {
    return this.creation.send({ name, description }, (key, body) => this.api.invoke(createTeam, { 'Idempotency-Key': key, body }));
  }
  remove(teamId: string): Promise<void> { return this.api.invoke(deleteTeam, { teamId }); }
}
```

This standalone OnPush page presents the named screen. Labels and concrete route bindings are part of the implementation, not omitted scaffolding.

**File: `src/app/features/teams/teams.ts`**
```typescript
import { FieldErrors } from '../../shared/field-errors';
import { ChangeDetectionStrategy, Component, inject, OnInit, viewChild } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AuthService } from '../../auth/auth.service';
import { Actions } from '../../core/actions';
import { Connectivity } from '../../core/connectivity';
import { Icon } from '../../shared/icon';
import { ConfirmDialog } from '../../shared/confirm-dialog';
import { TeamsStore } from './teams.store';
@Component({ selector: 'app-teams', imports: [FieldErrors, ReactiveFormsModule, RouterLink, Icon, ConfirmDialog], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Teams</h1>
    <form appFieldErrors [formGroup]="filter" (ngSubmit)="filterUrl()"><label for="team-search"><app-icon name="ui/search" />Search teams</label>
      <input id="team-search" formControlName="q" maxlength="100"><label for="team-sort">Sort</label>
      <select id="team-sort" formControlName="sort"><option value="-createdAt">Newest</option><option value="createdAt">Oldest</option></select><button>Search</button></form>
    @if (auth.isAdmin()) { <h2>Create team</h2><form appFieldErrors [formGroup]="form" (ngSubmit)="create()">
      <label for="team-name">Name</label><input id="team-name" formControlName="name" required maxlength="80">
      <label for="team-description">Description</label><textarea id="team-description" formControlName="description" maxlength="500"></textarea>
      <button [disabled]="form.invalid || !connection.online()"><app-icon name="ui/plus" />Create team</button></form> }
    <ul>@for (team of store.state().items; track team.id) { <li><a [routerLink]="['/teams', team.id]">{{ team.name }}</a>
      @if (auth.isAdmin()) { <button [disabled]="!connection.online()" (click)="remove(team.id)">Delete {{ team.name }}</button> }</li> }</ul>
    @if (store.state().status === 'loading') { <p role="status">Loading teams</p> }
    <button [disabled]="!store.state().nextCursor || store.state().status === 'loadingMore'" (click)="more()">Load more teams</button><app-confirm-dialog />` })
export class Teams implements OnInit {
  protected readonly auth = inject(AuthService);
  protected readonly store = inject(TeamsStore);
  protected readonly connection = inject(Connectivity);
  private readonly actions = inject(Actions);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly confirm = viewChild.required(ConfirmDialog);
  private readonly fb = inject(FormBuilder).nonNullable;
  protected readonly filter = this.fb.group({ q: '', sort: '-createdAt' });
  protected readonly form = this.fb.group({ name: ['', [Validators.required, Validators.maxLength(80)]], description: '' });
  constructor() {
    this.route.queryParamMap.pipe(takeUntilDestroyed()).subscribe(params => {
      this.filter.setValue({ q: params.get('q') ?? '', sort: params.get('sort') === 'createdAt' ? 'createdAt' : '-createdAt' });
      this.reload();
    });
  }
  ngOnInit(): void { }
  private reload(): void { const { q, sort } = this.filter.getRawValue(); void this.actions.run(() => this.store.loadTeams(q, sort === 'createdAt' ? sort : '-createdAt')); }
  protected filterUrl(): void { void this.router.navigate([], { relativeTo: this.route, queryParams: this.filter.getRawValue() }); }
  protected async create(): Promise<void> { if (this.form.invalid) return; const { name, description } = this.form.getRawValue(); if (await this.actions.run(() => this.store.create(name, description), true)) { this.form.reset(); this.reload(); } }
  protected async remove(id: string): Promise<void> { if (!this.auth.hasScope('tasks:admin')) { await this.auth.signIn(this.router.url, true, true); return; } if (await this.confirm().ask() && await this.actions.run(() => this.store.remove(id), true)) this.reload(); }
  protected more(): void { void this.actions.run(() => this.store.more()); }
}
```
Expected result: the named files exist under code, saved with the exact contents shown. No program must be running while you create them.

### Step 8. Executable smoke/build helpers
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

**File: `scripts/check-auth.ts`**
```typescript
import { authSmoke } from './smoke-auth';
authSmoke().catch(error => { console.error(error.message); process.exitCode = 1; });
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
import { createEnvironmentInjector, EnvironmentInjector, Injector, Provider, EnvironmentProviders, provideZonelessChangeDetection, ɵINJECTOR_SCOPE } from '@angular/core';
import { HttpClient, provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { Api } from '../src/app/api/api';
import { environment } from '../src/environments/environment';
export function nodeClient(token = '', extra: (Provider | EnvironmentProviders)[] = []) {
  const injector = createEnvironmentInjector([
    ...extra,
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
  return { api, injector, close: () => injector.destroy() };
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

**File: `scripts/probe-static.mjs`**
```javascript
const base = process.argv[2] ?? 'http://127.0.0.1:8200';
for (const path of ['/', '/teams']) {
  const response = await fetch(base + path);
  if (!response.ok || !(await response.text()).includes('<app-root>')) throw new Error('SPA fallback failed');
  const csp = response.headers.get('Content-Security-Policy');
  if (!csp?.includes("script-src 'self'")) throw new Error('CSP missing');
  console.log(`${path}: ${response.status}`);
  console.log(`Content-Security-Policy: ${csp}`);
}
```

This executable helper belongs outside browser src. One smoke scenario or build task, never a unit suite.

**File: `scripts/smoke-auth.ts`**
```typescript
import { nodeClient } from './node-client';
import { DOCUMENT } from '@angular/common';
import { OAuthService, OAuthStorage, provideOAuthClient } from 'angular-oauth2-oidc';
import { authConfig, isApiUrl, safeReturn, storageRules } from '../src/app/auth/auth.config';
import { SplitStorage } from '../src/app/auth/split-storage';
export async function authSmoke() {
  const values = new Map<string, string>();
  Object.assign(globalThis, { self: globalThis, sessionStorage: {
    getItem: (key: string) => values.get(key) ?? null,
    setItem: (key: string, value: string) => values.set(key, value),
    removeItem: (key: string) => values.delete(key),
  } });
  const storage = new SplitStorage();
  const client = nodeClient('', [provideOAuthClient(), { provide: OAuthStorage, useValue: storage },
    { provide: DOCUMENT, useValue: { getElementById: () => null } }]);
  try {
    const oauth = client.injector.get(OAuthService);
    let open: (url: string) => void = () => {};
    oauth.configure({ ...authConfig('http://localhost:4200'), openUri: url => open(url) });
    await oauth.loadDiscoveryDocument();
    const url = new URL(await new Promise<string>(resolve => { open = resolve; oauth.initCodeFlow(); }));
    if (url.searchParams.get('code_challenge_method') !== 'S256') throw new Error('Missing S256');
    const response = await fetch(url);
    if (response.status !== 200 || !(await response.text()).includes('username')) throw new Error('Login page missing');
    storage.setItem('access_token', 'stand-in');
    if (values.has('access_token') || !values.has('PKCE_verifier')) throw new Error('Storage routing failed');
    if (isApiUrl('https://example.invalid/v1/me') || safeReturn('//evil.invalid') !== '/') throw new Error('URL boundary failed');
    console.log('authorization: code_challenge_method=S256; login page: 200');
    console.log(storageRules);
    console.log('Bearer host boundary and returnUrl: checked');
    storage.clear();
  } finally { client.close(); }
}
```

This executable helper belongs outside browser src. One smoke scenario or build task, never a unit suite.

**File: `scripts/smoke-errors.ts`**
```typescript
import { Api } from '../src/app/api/api';
import { createTeam, createProject, createTask, updateTask, getTask, deleteTeam } from '../src/app/api/functions';
import { parseProblem } from '../src/app/http/problem';
import { HttpErrorResponse } from '@angular/common/http';
export async function errorsSmoke(api: Api): Promise<void> {
  const team = await api.invoke(createTeam, { 'Idempotency-Key': crypto.randomUUID(), body: { name: `Angular smoke ${crypto.randomUUID()}` } });
  try {
    const project = await api.invoke(createProject, { teamId: team.id, 'Idempotency-Key': crypto.randomUUID(), body: { key: 'ANG', name: 'Smoke' } });
    const request = { projectId: project.id, 'Idempotency-Key': crypto.randomUUID(), body: { title: 'Compare ETags' } };
    const first = await api.invoke$Response(createTask, request);
    const replay = await api.invoke$Response(createTask, request);
    if (replay.body.id !== first.body.id || replay.headers.get('Idempotent-Replayed') !== 'true') throw new Error('Replay mismatch');
    console.log('Idempotent-Replayed: true');
    const taskId = first.body.id;
    const tag = first.headers.get('ETag')!;
    await api.invoke(updateTask, { taskId, 'If-Match': tag, body: { title: 'Saved by another tab' } });
    for (const [label, expected, call] of [
      ['412', 412, () => api.invoke(updateTask, { taskId, 'If-Match': tag, body: { title: 'Stale draft' } })],
      ['404', 404, () => api.invoke(getTask, { taskId: crypto.randomUUID() })],
      ['422', 422, () => api.invoke(createTask, { projectId: project.id, 'Idempotency-Key': crypto.randomUUID(), body: { title: '' } })],
    ] as const) {
      try { await call(); throw new Error(`Expected ${expected}`); }
      catch (error) {
        if (!(error instanceof HttpErrorResponse) || error.status !== expected) throw error;
        const problem = parseProblem(error.status, error.error, error.headers);
        console.log(`${label} ${problem.type.split('/').pop()}`);
        console.log(`detail: ${problem.detail}`);
        if (expected === 422) console.log(`field: ${problem.errors?.[0]?.pointer}`);
      }
    }
    // One canned response demonstrates parsing; it does not pretend Keycloak lacks a scope.
    const problem = parseProblem(429, { title: 'Too many requests' }, new Headers({ 'Retry-After': '2' }));
    console.log(`429 canned Retry-After: ${problem.retryAfter}`);
  } finally { await api.invoke(deleteTeam, { teamId: team.id }); }
}
```

This executable helper belongs outside browser src. One smoke scenario or build task, never a unit suite.

**File: `scripts/smoke.ts`**
```typescript
import '@angular/compiler';
import { authSmoke } from './smoke-auth';
import { HttpErrorResponse } from '@angular/common/http';
import { nodeClient } from './node-client';
import { environment } from '../src/environments/environment';
import { errorsSmoke } from './smoke-errors';
import { listTeams, listTasks } from '../src/app/api/functions';
import { getHealth } from '../src/app/api/fn/platform/get-health';
import { getMe } from '../src/app/api/fn/platform/get-me';
async function main() {
  await authSmoke();
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
    let cursor: string | undefined;
    let teams = 0;
    do {
      const page = await client.api.invoke(listTeams, { limit: 1, cursor });
      teams += page.items.length; cursor = page.page.nextCursor ?? undefined;
    } while (cursor);
    console.log(`teams: ${teams}`);
    let tasks = 0;
    do {
      const page = await client.api.invoke(listTasks, { projectId: '9a000000-0000-4000-8000-000000000001', limit: 2, cursor });
      console.log(`tasks page: ${page.items.length}`);
      tasks += page.items.length; cursor = page.page.nextCursor ?? undefined;
    } while (cursor);
    console.log(`tasks: ${tasks}; nextCursor: null`);
    await errorsSmoke(client.api);
  } finally { client.close(); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
```

This executable helper belongs outside browser src. One smoke scenario or build task, never a unit suite.

**File: `scripts/write-env.mjs`**
```javascript
import { readFileSync, writeFileSync } from 'node:fs';
const file = 'src/environments/environment.ts';
const current = JSON.parse(readFileSync(file, 'utf8').replace('export const environment = ', '').replace(/;\s*$/, ''));
for (const [key, variable] of Object.entries({ apiBaseUrl: 'API_BASE_URL', issuer: 'OIDC_ISSUER', clientId: 'OIDC_CLIENT_ID' })) {
  if (process.env[variable]) current[key] = process.env[variable];
}
writeFileSync(file, 'export const environment = ' + JSON.stringify(current, null, 2) + ';\n');
console.log('Public build configuration written (no secrets)');
```
Expected result: the named files exist under code, saved with the exact contents shown. No program must be running while you create them.

### Step 9. Copied fixture configuration and licence
Create the concrete parent directories (silent on success), then create/replace every named file below in your editor. Save after each file; do not type the markdown fences.

**Command: code folder, parent directories**
```powershell
New-Item -ItemType Directory -Force 'public/icons','smoke-backend' | Out-Null
```

**Command: code folder, macOS/Linux**
```bash
mkdir -p public/icons smoke-backend
```

Keep the original licence next to copied icons. No external art is used.

**File: `public/icons/LICENSE-ICONS-CC0.txt`**
```text
Creative Commons Legal Code

CC0 1.0 Universal

The person who associated a work with this deed has dedicated the work to the
public domain by waiving all of his or her rights to the work worldwide under
copyright law, including all related and neighboring rights, to the extent
allowed by law.

You can copy, modify, distribute and perform the work, even for commercial
purposes, all without asking permission.

For the full legal text, see: https://creativecommons.org/publicdomain/zero/1.0/legalcode
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

### Step 10. Copy the licensed icons and use their names
The Icon component renders an aria-hidden mask; screen controls provide accessible text. Run from code, using repo from Step 2:

**Command: code folder, fourteen CC0 icons**
```powershell
$icons = @('ui/search','ui/filter','ui/plus','ui/x','ui/check-circle','ui/alert-triangle','ui/list','ui/columns','arrows/log-in','arrows/log-out','arrows/refresh-cw','users/users','cloud-network/cloud-off','time/calendar-days')
foreach ($icon in $icons) {
  $destination = Join-Path 'public/icons' ($icon + '.svg')
  New-Item -ItemType Directory -Force (Split-Path $destination) | Out-Null
  Copy-Item (Join-Path $repo ('assets/art/icons/' + $icon + '.svg')) $destination
}
Copy-Item (Join-Path $repo 'assets/art/LICENSE-ICONS-CC0.txt') public/icons/LICENSE-ICONS-CC0.txt
```

**Command: code folder, macOS/Linux**
```bash
for icon in ui/search ui/filter ui/plus ui/x ui/check-circle ui/alert-triangle ui/list ui/columns arrows/log-in arrows/log-out arrows/refresh-cw users/users cloud-network/cloud-off time/calendar-days; do
  mkdir -p "public/icons/$(dirname "$icon")"
  cp "$repo/assets/art/icons/$icon.svg" "public/icons/$icon.svg"
done
cp "$repo/assets/art/LICENSE-ICONS-CC0.txt" public/icons/
```
Expected: fourteen SVGs in those category subfolders and the licence above. x dismisses errors; search/filter/list/columns identify controls; users identifies Teams; calendar-days marks dates; log-in/log-out identify account actions; refresh-cw retries reads; check-circle marks completion; cloud-off marks offline; alert-triangle marks conflicts (introduced in chapter 04). No external art.

### Step 11. Install, generate and build once

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

added 267 packages in 10s
```

**Captured output (excerpt)**
```text

> web-angular@1.0.0 prebuild
> npm run api:gen


> web-angular@1.0.0 api:gen
> ng-openapi-gen && node scripts/generated-summary.mjs

Using OpenAPI specification version: 3.1.1
Wrote src\app\api\api-configuration.ts
Wrote src\app\api\api.ts
Wrote src\app\api\fn\audit\list-audit-log.ts
Wrote src\app\api\fn\comments\create-comment.ts
Wrote src\app\api\fn\comments\delete-comment.ts
Wrote src\app\api\fn\comments\list-comments.ts
Wrote src\app\api\fn\members\list-members.ts
Wrote src\app\api\fn\members\put-member.ts
Wrote src\app\api\fn\members\remove-member.ts
Wrote src\app\api\fn\platform\get-health.ts
Wrote src\app\api\fn\platform\get-me.ts
Wrote src\app\api\fn\platform\list-users.ts
Wrote src\app\api\fn\projects\create-project.ts
Wrote src\app\api\fn\projects\delete-project.ts
Wrote src\app\api\fn\projects\get-project.ts
Wrote src\app\api\fn\projects\list-projects.ts
Wrote src\app\api\fn\projects\update-project.ts
Wrote src\app\api\fn\tasks\complete-task.ts
Wrote src\app\api\fn\tasks\create-task.ts
Wrote src\app\api\fn\tasks\delete-task.ts
Wrote src\app\api\fn\tasks\get-task.ts
Wrote src\app\api\fn\tasks\list-tasks.ts
Wrote src\app\api\fn\tasks\reassign-task.ts
Wrote src\app\api\fn\tasks\update-task.ts
Wrote src\app\api\fn\teams\create-team.ts
Wrote src\app\api\fn\teams\delete-team.ts
Wrote src\app\api\fn\teams\get-team.ts
Wrote src\app\api\fn\teams\list-teams.ts
Wrote src\app\api\fn\teams\update-team.ts
Wrote src\app\api\functions.ts
Wrote src\app\api\models\audit-entity-type-array.ts
Wrote src\app\api\models\audit-entity-type.ts
Wrote src\app\api\models\audit-entry.ts
Wrote src\app\api\models\audit-page.ts
Wrote src\app\api\models\comment-create.ts
Wrote src\app\api\models\comment-page.ts
Wrote src\app\api\models\comment.ts
Wrote src\app\api\models\health.ts
Wrote src\app\api\models\me.ts
Wrote src\app\api\models\member-page.ts
Wrote src\app\api\models\member-put.ts
Wrote src\app\api\models\member.ts
Wrote src\app\api\models\page-info.ts
Wrote src\app\api\models\problem.ts
Wrote src\app\api\models\project-create.ts
Wrote src\app\api\models\project-page.ts
Wrote src\app\api\models\project-update.ts
Wrote src\app\api\models\project.ts
Wrote src\app\api\models\reassign-request.ts
Wrote src\app\api\models\role-array.ts
Wrote src\app\api\models\role.ts
Wrote src\app\api\models\task-create.ts
Wrote src\app\api\models\task-page.ts
Wrote src\app\api\models\task-priority-array.ts
Wrote src\app\api\models\task-priority.ts
Wrote src\app\api\models\task-status-array.ts
Wrote src\app\api\models\task-status.ts
Wrote src\app\api\models\task-update.ts
Wrote src\app\api\models\task.ts
Wrote src\app\api\models\team-create.ts
Wrote src\app\api\models\team-page.ts
Wrote src\app\api\models\team-role-array.ts
Wrote src\app\api\models\team-role.ts
Wrote src\app\api\models\team-update.ts
Wrote src\app\api\models\team.ts
Wrote src\app\api\models\user-page.ts
Wrote src\app\api\models\user-summary.ts
Wrote src\app\api\models\validation-problem.ts
Wrote src\app\api\models.ts
Wrote src\app\api\request-builder.ts
Wrote src\app\api\strict-http-response.ts
Generation from contract/openapi.yaml finished with 33 models and 7 services.
Generated 27 operations: getHealth, getMe, listTasks

> web-angular@1.0.0 build
> ng build

> Building...
√ Building...
Initial chunk files | Names         |  Raw size | Estimated transfer size
main-UEQPHT5K.js    | main          | 335.84 kB |                88.50 kB
styles-BBWXR33N.css | styles        |   2.01 kB |               690 bytes

                    | Initial total | 337.85 kB |                89.19 kB

Lazy chunk files    | Names         |  Raw size | Estimated transfer size
chunk-DSCtEIko.js   | -             |  50.35 kB |                11.09 kB
chunk-uFF8xY7K.js   | task-detail   |  12.24 kB |                 3.70 kB
chunk-C1g1EKHd.js   | tasks         |  10.09 kB |                 3.15 kB
chunk-B7IpYyQB.js   | -             |   8.17 kB |               934 bytes
chunk-DlIwNRC2.js   | team-detail   |   5.89 kB |                 1.98 kB
chunk-D_IRdEa_.js   | projects      |   5.03 kB |                 2.00 kB
chunk-D5leE8vx.js   | teams         |   4.91 kB |                 1.94 kB
chunk-DKyrc_ff.js   | audit         |   3.74 kB |                 1.60 kB
chunk-BWqngmWu.js   | dashboard     |   1.50 kB |               771 bytes
chunk-DPvW5CaT.js   | -             |   1.01 kB |                 1.01 kB
chunk-C8FqoJim.js   | login         | 850 bytes |               850 bytes
chunk-BVYFQ1Nq.js   | forbidden     | 471 bytes |               471 bytes
chunk-CKebP_wF.js   | not-found     | 455 bytes |               455 bytes
chunk-3dAD0Lhq.js   | callback      | 439 bytes |               439 bytes
chunk-BkVZxGs6.js   | -             | 119 bytes |               119 bytes

Application bundle generation complete. [3.478 seconds] - 2026-11-23T10:36:43.129Z

Output location: F:\Projects\Uee03\Code101\capstones\web-angular\source\phase-5-ship\05-build-run-ship\code\dist\web-angular
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

authorization: code_challenge_method=S256; login page: 200
Tokens: memory only; nonce and PKCE_verifier: sessionStorage; ts.hint: non-secret localStorage flag
Bearer host boundary and returnUrl: checked
Anonymous request: 401 Unauthorized
Anonymous detail: A bearer access token is required.
health: ok
me: alice (admin)
teams: 2
tasks page: 2
tasks page: 2
tasks page: 1
tasks: 5; nextCursor: null
Idempotent-Replayed: true
412 precondition-failed
detail: The task changed since you read it (current version 2).
404 not-found
detail: The task was not found.
422 validation-error
detail: One or more fields are invalid.
field: /title
429 canned Retry-After: 2
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
 Container code101-verify-05-build-run-ship-keycloak-1 Created 
 Container code101-verify-05-build-run-ship-db-1 Created 
 Container code101-verify-05-build-run-ship-api-1 Creating 
 Container code101-verify-05-build-run-ship-api-1 Created 
 Container code101-verify-05-build-run-ship-keycloak-1 Starting 
 Container code101-verify-05-build-run-ship-db-1 Starting 
 Container code101-verify-05-build-run-ship-keycloak-1 Started 
 Container code101-verify-05-build-run-ship-db-1 Started 
 Container code101-verify-05-build-run-ship-db-1 Waiting 
 Container code101-verify-05-build-run-ship-db-1 Healthy 
 Container code101-verify-05-build-run-ship-api-1 Starting 
 Container code101-verify-05-build-run-ship-api-1 Started 
 Container code101-verify-05-build-run-ship-db-1 Waiting 
 Container code101-verify-05-build-run-ship-keycloak-1 Waiting 
 Container code101-verify-05-build-run-ship-api-1 Waiting 
 Container code101-verify-05-build-run-ship-db-1 Healthy 
 Container code101-verify-05-build-run-ship-api-1 Healthy 
 Container code101-verify-05-build-run-ship-keycloak-1 Healthy
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
 Container code101-verify-05-build-run-ship-api-1 Stopping 
 Container code101-verify-05-build-run-ship-keycloak-1 Stopping 
 Container code101-verify-05-build-run-ship-api-1 Stopped 
 Container code101-verify-05-build-run-ship-api-1 Removing 
 Container code101-verify-05-build-run-ship-api-1 Removed 
 Container code101-verify-05-build-run-ship-db-1 Stopping 
 Container code101-verify-05-build-run-ship-db-1 Stopped 
 Container code101-verify-05-build-run-ship-db-1 Removing 
 Container code101-verify-05-build-run-ship-db-1 Removed 
 Container code101-verify-05-build-run-ship-keycloak-1 Stopped 
 Container code101-verify-05-build-run-ship-keycloak-1 Removing 
 Container code101-verify-05-build-run-ship-keycloak-1 Removed 
 Volume code101-verify-05-build-run-ship_pg_data Removing 
 Network tasksteams-net Removing 
 Volume code101-verify-05-build-run-ship_pg_data Removed 
 Network tasksteams-net Removed
```
### Human sign-in acceptance (not automated)
1. With the temporary stack/npm start running, open **http://localhost:4200/login**, never 127.0.0.1. Expect Login and Sign in. Tab to the button, then Enter.
2. Expect localhost:8180, realm tasksteams, username/password fields and a Sign In button. Enter alice / alice-local-fake (local fake account only); the SPA never asks for this password.
3. Expect Callback, Signing you in briefly, then Dashboard and alice's name. No code= or state= may remain in the address bar/current history entry. Failed callback error values appear on Login.
4. In DevTools Application/Storage inspect **key names without copying token values**: no localStorage/sessionStorage key contains token. Only nonce/PKCE_verifier redirect proof may be in sessionStorage; ts.hint=1 is a non-secret localStorage re-entry hint. Tokens belong only to the in-memory Map.
5. Reload a protected route: prompt=none SSO should restore it. Expired SSO instead clears the hint and returns to Login, without a loop. A returnUrl beginning // or containing a backslash must not leave the app.
6. Leave the tab open for six minutes and call the API again. Observe one refresh exchange near 75% of the five-minute lifetime; concurrent calls must not rotate a token twice. This timing/rotation behaviour is code-reviewed but NOT browser-verified here.
7. Open /admin/audit as alice: request tasks:admin through the existing SSO session. Phase 2 has a guard-only Dashboard placeholder; from chapter 03 this is Audit log. As bob / bob-local-fake, expect You do not have access, even if a token has the scope.
8. Press Sign out. Expect Keycloak end-session navigation and /login. Visiting a protected route must go to Login. The library clears memory; Keycloak must no longer silently return an authenticated session.

Security clarification: access/refresh tokens never enter browser storage, logs or URLs. The W-11-required OIDC logout **ID-token hint** is a narrow exception to W-08's literal no-token-in-URL wording; it goes only to the discovered issuer end-session endpoint. See CONTRACT-NOTES.md. No token is printed by the smoke scripts.
### Human screen acceptance (not claimed from the build)
| Screen | Route | What to see / do |
|---|---|---|
| Login | /login | Sign in button; identity failure as text. |
| Callback | /auth/callback | Signing you in, then replace navigation without code/state. |
| Dashboard | / | Greeting, roles, scopes, API ok, alice's Platform Team / Mobile Team links. |
| Teams | /teams | Search, sort, Load more teams; admin create/delete. Delete first obtains tasks:admin when absent, then needs another explicit confirmation. |
| Team detail | /teams/7ea00000-0000-4000-8000-000000000001 | Details/Members buttons; alice can edit, add an existing user UUID, change role, remove. bob cannot see lead controls. |
| Projects | /teams/7ea00000-0000-4000-8000-000000000001/projects | PLAT/DOCS, active/archived toggle, lead create/archive/restore/delete. A duplicate key shows 409 and keeps input. |
| Tasks | /projects/9a000000-0000-4000-8000-000000000001 | Five seed tasks; list/board buttons, disclosure filters, assignees from members, cursor continuation. Board movement uses a select, never dragging. |
| Task detail | /tasks/7a500000-0000-4000-8000-000000000003 | Configure Keycloak editor, complete, lead reassign/delete, two initial comments. After complete: done and completedAt. |
| Audit log | /admin/audit | alice obtains tasks:admin through SSO; entity/actor/from/to filters, load more. bob gets You do not have access. |
| Not found | /this-route-does-not-exist | Public Not found and home link; missing/invisible API objects say Not found, never that a private object exists. |

Walk through: create a temporary team as alice, add bob's existing UUID b0b00000-0000-4000-8000-000000000002, create a project with key DEMO, add a task and comment, complete/reassign it, and inspect Audit log. Try a duplicate DEMO key before deleting your temporary team. Filters must survive copying the URL and Back/Forward. Use Load more assignees/members/comments if a cursor is present; never invent cursor values. The smoke's limit=2 intentionally exercises continuation even though UI lists use limit=25.
### Human accessibility/conflict checklist
Complete on every screen, not just Dashboard:
- [ ] First Tab reaches Skip to content; activating it reaches main. Each navigation changes title and focuses h1 after render. Menu/filter disclosure works with Enter/Space; the header does not obscure focus.
- [ ] At 320 CSS px and 400% zoom, forms/cards reflow without horizontal page scrolling; the audit table has its own two-dimensional scroll region. Check light/dark/forced-colour modes. Measure text contrast >=4.5:1 and controls/focus >=3:1; build success is not a contrast measurement.
- [ ] Icons are decorative aria-hidden masks beside text. Dismiss error has an aria-label. All controls have labels, visible focus, >=24px targets and text errors, not colour alone.
- [ ] Open each native dialog: safe initial focus, focus stays inside, Esc closes, focus returns to opener. Keep editing/failed save preserves entered values.
- [ ] In two tabs open the same Task detail. Keep a draft in B. Save a different title in A, then save B: expect optimistic title then rollback and Someone saved first. Compare Server version/Your changes. Use the server version re-reads/discards explicitly; Apply my changes on top re-reads and sends only the local patch with the fresh ETag. Another conflict must not auto-loop a write.
- [ ] DevTools Network Offline: banner within one second, write buttons disable, Actions refuses writes, draft stays. Restore Online and Try again: re-fetch a GET, not a replayed POST. API-down/CORS failures also produce guidance.
- [ ] Screen reader announces success status/error alert. A 422 summary gets focus and JSON-Pointer fields have aria-describedby text; a 409 remains beside the submitted form. No cognitive task or blocked password paste is added to Keycloak.
- [ ] Focus pristine Task detail after another tab changes it: request If-None-Match on task only; 304 keeps data. A dirty draft intentionally skips revalidation.

WCAG mapping: structure/icons 1.1.1/1.3.1; contrast/reflow 1.4.3/1.4.10/1.4.11; keyboard 2.1.1/2.1.2; skip/focus 2.4.1/2.4.3/2.4.7/2.4.11; selects/targets 2.5.7/2.5.8; errors/retained drafts/authentication 3.3.1/3.3.3/3.3.7/3.3.8; names/status 4.1.2/4.1.3. This checklist is not WCAG certification.
### Production smoke, inside the locked child shell
After Ctrl+C stops ng serve and **before the backend cleanup/exit above**, run from code:

**Command: code folder, locked production smoke**
```powershell
docker build -t angular-manual-web .
docker run -d --name angular-manual-web -p 127.0.0.1:8200:8080 angular-manual-web
node scripts/probe-static.mjs
curl.exe -I http://localhost:8200/
curl.exe -I http://localhost:8200/teams
docker inspect angular-manual-web --format "user={{.Config.User}} health={{.State.Health.Status}}"
docker logs angular-manual-web
docker rm -f angular-manual-web
docker image rm angular-manual-web
```
macOS/Linux uses curl rather than curl.exe. Wait for healthy (five-second health interval). The Node probe obtains status/headers and checks the deep-link body, not browser sign-in. Real results:

**Captured output (excerpt)**
```text
/: 200
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self' http://localhost:8000 http://localhost:8180; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'
/teams: 200
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self' http://localhost:8000 http://localhost:8180; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'
```

**Captured output (excerpt)**
```text
user=101 health=healthy
```
For real **manual sign-in**, publish 127.0.0.1:4200:8080 instead of 8200 after ng serve stops. Open localhost:4200 and repeat the human sign-in checklist. Origin 8200 is deliberately absent from realm/CORS, so no successful login is claimed there. Remove container/image, clean the backend as above, then exit the lock shell. No deployment is left running.

## How it works
The Node stage installs the lockfile, writes public build-time settings and runs generation/build. Runtime receives only browser files. nginx runs as UID 101 on container 8080. Exact /index.html disables caching; hashed JS/CSS can be cached for a year; /teams falls back to index.html. Security headers stay at server scope; locations use expires rather than another add_header, avoiding accidental loss of inherited headers. style-src unsafe-inline is the documented Angular style exception; scripts stay self-only. Changing backend/issuer hosts needs a rebuild AND connect-src changes. 8200 is static smoke only; full sign-in needs origin 4200 after stopping the dev server.
| Status | Behaviour |
|---|---|
| 400 / 428 | Detail/trace banner: bad client request or missing precondition. A bad continuation cursor resets its list once. |
| 401 | One shared renewal/one retry; second 401 or renewal failure clears memory and goes to Login with a safe return route. |
| 403 / 404 | You do not have access / Not found panel, no retry disclosing private objects. |
| 409 | Keep form/draft, display detail beside it; last_lead explains promoting another lead first. |
| 412 | Snapshot rollback, fetch server values, conflict dialog with two explicit choices. |
| 422 | Focus summary, associate errors[].pointer with fields, keep values. |
| 429 | GET countdown from Retry-After, retry once; writes explain the wait and need another submit. |
| 405 / 413 / 415 / 5xx including 503 | Visible problem/banner with way back or Try again. No blanket write retry, even if 503 includes Retry-After. |
| network | Offline/error banner; disable writes; Try again re-fetches after connectivity returns. |
New terms are defined in [GLOSSARY.md](../../GLOSSARY.md). A type is generated for each domain entity; do not maintain a second handwritten Task/Team/Comment model.

## Try it
From a fresh terminal, start at the **chapter folder**, one level above code. Choose a new exercise destination so copying cannot nest an older attempt. These commands do not start a server or touch shared ports.

**Command: clone root -> chapter folder -> personal exercise copy (PowerShell)**
```powershell
Set-Location 'F:/Projects/Uee03/Code101/capstones/web-angular/source/phase-5-ship/05-build-run-ship'
Copy-Item exercise/starter (Join-Path $HOME 'angular-exercise-05') -Recurse
Set-Location (Join-Path $HOME 'angular-exercise-05')
node main.mjs
```

**Command: chapter folder -> personal exercise copy (macOS/Linux)**
```bash
cp -R exercise/starter ~/angular-exercise-05
cd ~/angular-exercise-05
node main.mjs
```
Edit main.mjs in that personal copy, not the answer folder. The starter prints a TODO, not a failed unit test. The complete starter from the chapter is shown below.

**File: exercise/starter/main.mjs**
```javascript
// Check a deployment path, without pretending that 8200 permits sign-in.
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
const path = '/teams';
console.log(`${path}: SPA fallback required; sign-in origin: 4200`);
```

**Captured solution output**
```text
/teams: SPA fallback required; sign-in origin: 4200
```

One small runnable example, not a unit suite.
</details>

## Check yourself
1. Why does /teams return index.html? <details><summary>Answer</summary>It is a client route rather than a static file; nginx SPA fallback lets Angular select the screen.</details>
2. Why is 8200 not a valid sign-in test? <details><summary>Answer</summary>Only 4200/5173 are registered redirect/CORS origins. Stop ng serve and publish nginx on 4200 for the human test.</details>
3. Why not add cache add_header directives inside each location? <details><summary>Answer</summary>A location-level add_header can replace inherited security headers. expires changes caching without losing server-level CSP.</details>
4. What must cleanup remove? <details><summary>Answer</summary>Your dev server, production/backend containers, project volume/network, and both images built for the run, but never another owner's resources.</details>

## Common mistakes
These API errors were actually captured by the generated-client smoke; no token or variable trace value is printed:

**Captured real API errors**
```text
Anonymous request: 401 Unauthorized
Anonymous detail: A bearer access token is required.
412 precondition-failed
detail: The task changed since you read it (current version 2).
404 not-found
detail: The task was not found.
422 validation-error
detail: One or more fields are invalid.
field: /title
```

| Symptom/error | Cause | Fix |
|---|---|---|
| Anonymous request: 401 Unauthorized; A bearer access token is required. | No bearer token. | Sign in with tasks-web in the browser; only the Node smoke uses the fake tasks-smoke password grant. Never put that grant in the SPA. |
| The task changed since you read it (current version 2). | Stale If-Match. | Use the conflict choices; never strip quotes or silently retry. |
| One or more fields are invalid.; /title | Real 422 from intentionally empty title. | Keep form values, show summary and field message. Native validation prevents many such requests. |
| Build is green but an edit is absent | Unsaved tab/wrong folder. | Save all and use the exact chapter path. Guidance, not a claimed captured terminal error. |
| Sign-in fails only on nginx port 8200 | Origin intentionally unregistered. | Stop ng serve; publish 4200 for human sign-in. Do not widen platform CORS. |
| Realm edit seems ignored | Import runs only on an empty development store. | Do not edit the fixture. Remove your own temporary stack with down -v and re-create it; never remove another owner's volume. |

Only API lines above are captured errors; other rows are diagnostic guidance, not fabricated messages.

## Best practice
Keep related code in feature directories, match filenames to concepts, prefer inject and keep components focused on presentation. Stores own requests; pages own forms/labels. Source: Angular coding style guide (Tier 1) https://angular.dev/style-guide.

Use npm ci with the shipped lockfile; it refuses dependency/lock mismatches instead of silently updating. Source: npm ci (Tier 1) https://docs.npmjs.com/cli/v11/commands/npm-ci.

Use code flow/PKCE and keep bearer tokens out of persistent storage. A BFF with HttpOnly cookies is stronger when server support is available, but outside this pure SPA. Source: OAuth 2.0 Security Best Current Practice (Tier 1) https://www.rfc-editor.org/rfc/rfc9700.html and the pinned library https://github.com/manfredsteyer/angular-oauth2-oidc/tree/22.0.2.
Accessible recovery must preserve input/keyboard focus, not merely add ARIA. Source: WCAG 2.2 (Tier 1) https://www.w3.org/TR/WCAG22/.

## Next lesson
None. Complete human acceptance, review CONTRACT-NOTES.md and compare web-react. Before real release manually review npm audit --omit=dev (advice, not the verifier), replace local HTTP/fake credentials in the owning deployment and approve a maintained nginx pin.
