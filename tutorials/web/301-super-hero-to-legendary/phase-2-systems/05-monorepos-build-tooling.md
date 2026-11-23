---
track: web
level: 301
phase: 2
phase_name: systems
lesson: 05
title: "Monorepos and build tooling"
time: 150 min
prerequisites: [web-201.06, web-301.03, web-301.04]
versions: { node: "26.13.1", npm: "11.20.0", typescript: "7.0.2", "@types/node": "26.6.6", "actions/checkout": "v7", "actions/setup-node": "v7", "actions/upload-artifact": "v7", "actions/download-artifact": "v8" }
verified: not yet run
source: source/web/301-super-hero-to-legendary/phase-2-systems/05-monorepos-build-tooling/
assets: []
---

# 05. Monorepos and build tooling

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- set up an npm workspaces monorepo with three packages and explain how workspace linking, hoisting and phantom dependencies work
- configure TypeScript project references so `tsc --build` compiles only what changed, in dependency order
- write a CI workflow that installs reproducibly, builds once and tests the build output, with least-privilege permissions
- decide whether a cache, an affected-only build or a build tool such as Nx or Turborepo pays off, using measurements you take yourself

## Recap
1. In lesson 03 you imported your own package by name through `exports`. What made that work?
   <details><summary>Answer</summary>The <code>exports</code> map plus the package's own name: Node and TypeScript allow a package to refer to itself, and resolve through the map.</details>
2. In lesson 04 the tokens package produced CSS and TypeScript names. Which tier of token may a UI component use?
   <details><summary>Answer</summary>Semantic and component tokens, never primitives.</details>
3. What does `npm ci` do differently from `npm install`?
   <details><summary>Answer</summary>It installs exactly what the lockfile says, deletes any existing <code>node_modules</code> first and fails if the lockfile and <code>package.json</code> disagree. It never rewrites the lockfile.</details>

## Why it matters
Once a design system, a UI package and two applications exist, copying code between repositories stops working: a fix lands in one copy and not in the others. A monorepo (one repository, many packages) makes a change in the tokens package and its three consumers one reviewable commit. The price is tooling: builds must know the dependency order, CI must not rebuild the world for a typo, and a cache that is wrong is worse than no cache. This lesson builds the smallest honest version and measures where the time goes.

## What you will build
A repository with three workspaces: `@code101/tokens` (names of tokens), `@code101/ui` (buttons that use them) and `@code101/web` (an app that renders them), tied together with npm workspaces and TypeScript project references; a script that lists which workspaces a change affects; and a GitHub Actions workflow (build once, test the build output).

```mermaid
flowchart LR
  tokens["@code101/tokens"] --> ui["@code101/ui"]
  ui --> web["@code101/web"]
```

## Before you start
- **Prerequisites:** [Web 201 lesson 06, modules, Vite and the dev workflow](../../201-hero-to-super-hero/phase-2-typescript-in-depth/06-modules-vite-and-dev-workflow.md); Web 301 lessons [03, library-quality TypeScript](../phase-1-type-level-typescript/03-library-quality-typescript.md) and [04, design systems and tokens](04-design-systems-tokens.md).
- Lessons 01 to 04 finished (Node 26.13.1, npm 11.20.0, TypeScript 7.0.2) and Git installed (`git --version`).
- Time: 120 to 150 minutes. Break after step 8.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/301-super-hero-to-legendary/phase-2-systems/05-monorepos-build-tooling/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- No `package-lock.json` is shipped. `npm install` creates it; commit it in your own repository, because CI uses `npm ci`, which requires it.
- Folder rule for this lesson: every command runs in the **repository root** (the folder that contains the root `package.json`) unless a step says otherwise.

## Steps

### Step 1. Create the repository
```text
mkdir monorepo-lab
cd monorepo-lab
git init
mkdir packages
mkdir apps
mkdir scripts
mkdir packages/tokens
mkdir packages/ui
mkdir apps/web
```
Forward slashes work in Windows PowerShell and in macOS/Linux shells for these commands. Then create the source folders: `packages/tokens/src`, `packages/ui/src`, `apps/web/src`, and the workflow folder `.github/workflows` (the editor's "New Folder" button is the easiest way; folders starting with a dot are hidden by default in some file managers).
Expected result: the folders above exist and `git init` printed a line starting `Initialized empty Git repository`.

### Step 2. Write the root files
**File: `package.json`**
```json
{
  "name": "code101-monorepo",
  "private": true,
  "type": "module",
  "workspaces": [
    "packages/*",
    "apps/*"
  ],
  "scripts": {
    "build": "tsc --build",
    "clean": "tsc --build --clean",
    "test": "node --test \"packages/*/dist/*.test.js\"",
    "start": "node apps/web/dist/main.js",
    "affected": "node scripts/affected.mjs",
    "ci": "npm run build && npm test"
  },
  "engines": {
    "node": ">=26.13.1",
    "npm": ">=11.20.0"
  },
  "devDependencies": {
    "@types/node": "26.6.6",
    "typescript": "7.0.2"
  }
}
```
- `"private": true` is required for the root of a workspace repository: the root is a coordination point, never published.
- `"workspaces"` lists the folders (globs) that are packages. `npm install` finds each `package.json` there and **symlinks** it into the root `node_modules`, so `node_modules/@code101/tokens` points at `packages/tokens`.
- `tsc --build` (short `tsc -b`) is the project-reference build: it reads the root `tsconfig.json`, builds each referenced project only if its inputs changed, and does it in dependency order.
- The `test` script uses Node's built-in test runner (`node --test`) on the **compiled** tests. The glob is quoted so Node, not your shell, expands it (same behaviour on Windows, macOS and Linux).
- `typescript` and `@types/node` are declared **once**, in the root, so every package compiles with the same compiler. Packages do not list them.

**File: `.npmrc`**
```text
save-exact=true
engine-strict=true
```
`save-exact` makes `npm install <pkg>` write `1.2.3` instead of `^1.2.3` (reproducible by default). `engine-strict` turns the `engines` mismatch from a warning into an error, so nobody builds with the wrong Node by accident.

**File: `.gitignore`**
```text
node_modules/
dist/
*.tsbuildinfo
```
Build output never goes into Git. The lockfile does.

**File: `tsconfig.base.json`**
```json
{
  "compilerOptions": {
    "target": "ES2023",
    "lib": ["ES2023"],
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "types": ["node"],
    "composite": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "noEmitOnError": true,
    "skipLibCheck": true
  }
}
```
This holds the options every package shares; each package extends it. `composite: true` is what makes a project referenceable: it requires `declaration`, remembers what it built in a `.tsbuildinfo` file, and enforces that every source file is listed by `include`. **It deliberately has no `rootDir` and `outDir`:** those are paths, and a path in a shared file is resolved relative to the shared file, not to the package. Each package sets its own.

**File: `tsconfig.json`**
```json
{
  "files": [],
  "references": [
    { "path": "packages/tokens" },
    { "path": "packages/ui" },
    { "path": "apps/web" }
  ]
}
```
A **solution** tsconfig: it compiles nothing itself (`"files": []`) and only lists projects. `tsc --build` at the root walks this list. The order of the list does not matter; the references inside each project define the order.

### Step 3. Write the tokens package
**File: `packages/tokens/package.json`**
```json
{
  "name": "@code101/tokens",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "default": "./dist/index.js"
    }
  }
}
```
**File: `packages/tokens/tsconfig.json`**
```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "rootDir": "src",
    "outDir": "dist"
  },
  "include": ["src/**/*.ts"]
}
```
**File: `packages/tokens/src/index.ts`**
```ts
export const tokenNames = [
  'color-surface',
  'color-text-default',
  'color-action-background',
  'color-action-text',
] as const;

export type TokenName = (typeof tokenNames)[number];

export function cssVar(name: TokenName): string {
  return `var(--${name})`;
}
```
**File: `packages/tokens/src/index.test.ts`**
```ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { cssVar, tokenNames } from './index.js';

test('cssVar wraps a token name in var()', () => {
  assert.equal(cssVar('color-surface'), 'var(--color-surface)');
});

test('token names are unique', () => {
  assert.equal(new Set(tokenNames).size, tokenNames.length);
});
```
The `exports` map points at `dist`, the *built* output: another package that imports `@code101/tokens` gets compiled code and declarations, exactly like a package from the registry. That is the honest default; the trade-off is that you must build before you run (see "Trade-offs"). In a real repository `tokenNames` would be the generated file from lesson 04.

### Step 4. Write the ui package
**File: `packages/ui/package.json`**
```json
{
  "name": "@code101/ui",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "default": "./dist/index.js"
    }
  },
  "dependencies": {
    "@code101/tokens": "*"
  }
}
```
`"@code101/tokens": "*"` says "any version", and because a workspace with that name exists, npm links the local folder instead of downloading from the registry. Declaring the dependency matters even though the import would work without it (the exercise shows why).

**File: `packages/ui/tsconfig.json`**
```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "rootDir": "src",
    "outDir": "dist"
  },
  "include": ["src/**/*.ts"],
  "references": [{ "path": "../tokens" }]
}
```
`references` is the TypeScript counterpart of the `dependencies` entry: it tells `tsc --build` that tokens must be built first, and lets the editor jump from `ui` into tokens' *source*.

**File: `packages/ui/src/index.ts`**
```ts
import { cssVar } from '@code101/tokens';

export type ButtonVariant = 'primary' | 'plain';

export function escapeHtml(text: string): string {
  return text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

export function button(label: string, variant: ButtonVariant = 'primary'): string {
  return `<button type="button" class="button button-${variant}">${escapeHtml(label)}</button>`;
}

export const buttonCss: string = [
  `.button { background: ${cssVar('color-action-background')}; color: ${cssVar('color-action-text')}; }`,
  `.button-plain { background: ${cssVar('color-surface')}; color: ${cssVar('color-text-default')}; }`,
].join('\n');
```
`escapeHtml` replaces `&` **first**; doing it last would escape the `&` of the entities it had just written. The label is escaped because it is data: text you did not write must never be concatenated into HTML unescaped (lesson 08 returns to this).

**File: `packages/ui/src/index.test.ts`**
```ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { button, buttonCss, escapeHtml } from './index.js';

test('button escapes the label', () => {
  assert.equal(
    button('<b>Hi</b>'),
    '<button type="button" class="button button-primary">&lt;b&gt;Hi&lt;/b&gt;</button>',
  );
});

test('escapeHtml handles ampersands first', () => {
  assert.equal(escapeHtml('a & b'), 'a &amp; b');
});

test('css uses tokens, never raw colours', () => {
  assert.ok(!/#[0-9a-f]{3,8}/i.test(buttonCss));
});
```

### Step 5. Write the app
**File: `apps/web/package.json`**
```json
{
  "name": "@code101/web",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "dependencies": {
    "@code101/ui": "*"
  }
}
```
**File: `apps/web/tsconfig.json`**
```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "rootDir": "src",
    "outDir": "dist"
  },
  "include": ["src/**/*.ts"],
  "references": [{ "path": "../../packages/ui" }]
}
```
**File: `apps/web/src/main.ts`**
```ts
import { button, buttonCss } from '@code101/ui';

console.log(buttonCss);
console.log(button('Save'));
console.log(button('Cancel & close', 'plain'));
```
Here the "app" prints text so the lesson needs no browser. A real app in this position would be a Vite project: its `build` script becomes `vite build`, and TypeScript only type-checks (`tsc --noEmit`), which lesson 07 sets up.

### Step 6. Install and build
```text
npm install --no-audit --no-fund
npm run build
```
Expected result: `npm install` creates `node_modules` (with `@code101/tokens`, `@code101/ui` and `@code101/web` as symlinks into your folders) and `package-lock.json`. `npm run build` prints only its script header lines. Each project gets a `dist` folder with `.js`, `.d.ts`, `.map` files and a `tsconfig.tsbuildinfo` file (typical names; the tsbuildinfo file is how the next build knows what changed).

**Take a break here if you need one.**

### Step 7. Run the tests and the app
```text
npm test
npm start
```
Expected from `npm test`: the Node test runner reports five tests (two from tokens, three from ui) with `pass 5` and `fail 0` in its summary; the exact layout depends on the reporter and your terminal, so read the numbers, not the formatting.

Expected from `npm start`:
```text
.button { background: var(--color-action-background); color: var(--color-action-text); }
.button-plain { background: var(--color-surface); color: var(--color-text-default); }
<button type="button" class="button button-primary">Save</button>
<button type="button" class="button button-plain">Cancel &amp; close</button>
```

### Step 8. Write the affected-workspaces script
**File: `scripts/affected.mjs`**
```js
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const groups = ['packages', 'apps'];
const workspaces = [];

for (const group of groups) {
  if (!existsSync(group)) {
    continue;
  }
  for (const entry of readdirSync(group, { withFileTypes: true })) {
    const manifestPath = join(group, entry.name, 'package.json');
    if (entry.isDirectory() && existsSync(manifestPath)) {
      const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
      workspaces.push({
        name: manifest.name,
        dir: `${group}/${entry.name}`,
        dependencies: Object.keys({ ...manifest.dependencies, ...manifest.devDependencies }),
      });
    }
  }
}

const changed = process.argv.slice(2).map((file) => file.replaceAll('\\', '/'));
const affected = new Set();

// A change outside every workspace (root config, lockfile) is treated as "everything".
const touchesRoot = changed.some((file) => !groups.some((group) => file.startsWith(`${group}/`)));
for (const workspace of workspaces) {
  if (touchesRoot || changed.some((file) => file.startsWith(`${workspace.dir}/`))) {
    affected.add(workspace.name);
  }
}

// Add every workspace that depends on an affected one, repeatedly, until nothing new appears.
let grew = true;
while (grew) {
  grew = false;
  for (const workspace of workspaces) {
    if (!affected.has(workspace.name) && workspace.dependencies.some((name) => affected.has(name))) {
      affected.add(workspace.name);
      grew = true;
    }
  }
}

console.log(affected.size === 0 ? 'No workspaces affected' : [...affected].sort().join('\n'));
```
The script takes the list of changed files as arguments, so it is pure and testable. The algorithm is the heart of every "affected" feature in monorepo tools: find the workspaces that own the changed files, then add everything that depends on them, until the set stops growing. It is deliberately **conservative**: a file outside all workspaces (a root config or the lockfile) marks everything affected, because a wrong "nothing changed" is worse than an unnecessary build.

Try it:
```text
npm run affected --silent -- packages/tokens/src/index.ts
```
Expected output:
```text
@code101/tokens
@code101/ui
@code101/web
```
Now one deeper in the chain, a root-level file, and no files:
```text
npm run affected --silent -- packages/ui/src/index.ts
```
Expected output:
```text
@code101/ui
@code101/web
```
```text
node scripts/affected.mjs tsconfig.base.json
```
Expected output (all three, because it is a root file):
```text
@code101/tokens
@code101/ui
@code101/web
```
```text
node scripts/affected.mjs
```
Expected output:
```text
No workspaces affected
```

### Step 9. Write the CI workflow
**File: `.github/workflows/ci.yml`**
```yaml
name: ci

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
          persist-credentials: false

      - uses: actions/setup-node@v7
        with:
          node-version: '26.13.1'
          cache: npm

      - name: Install exactly what the lockfile says, without running package scripts
        run: npm ci --ignore-scripts

      - name: Show affected workspaces (information only)
        if: github.event_name == 'pull_request'
        env:
          BASE_REF: ${{ github.base_ref }}
        run: git diff --name-only "origin/${BASE_REF}...HEAD" | xargs node scripts/affected.mjs

      - name: Build every project in dependency order
        run: npm run build

      - name: Keep the build output for the test job
        uses: actions/upload-artifact@v7
        with:
          name: build-output
          path: |
            packages/*/dist
            apps/*/dist
          retention-days: 3
          if-no-files-found: error

  test:
    needs: build
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
        with:
          persist-credentials: false

      - uses: actions/setup-node@v7
        with:
          node-version: '26.13.1'
          cache: npm

      - run: npm ci --ignore-scripts

      - uses: actions/download-artifact@v8
        with:
          name: build-output

      - name: Run the tests on the built output
        run: npm test
```
Line by line:
- `on:` runs on every pull request and on pushes to `main`.
- `permissions: contents: read` at the top gives the automatic token the **minimum** it needs. Without it, the token may have broader rights depending on repository settings. Every workflow starts here.
- `concurrency` with `cancel-in-progress` cancels the previous run for the same branch when a new push arrives, saving minutes.
- `timeout-minutes` stops a hung job from consuming your quota for six hours (the default limit).
- `actions/checkout@v7` with `persist-credentials: false` does not leave the token in `.git/config` where later steps could read it. `fetch-depth: 0` downloads full history so `git diff origin/<base>...HEAD` works (only the `build` job needs it).
- `actions/setup-node@v7` installs the exact Node and, with `cache: npm`, caches npm's **download cache** (not `node_modules`) keyed by the lockfile.
- `npm ci --ignore-scripts` installs exactly the lockfile and does not run `postinstall` scripts of dependencies, one of the main supply-chain attack paths (lesson 08).
- The "affected" step passes `github.base_ref` through an **environment variable** instead of writing `${{ github.base_ref }}` inside the shell command. Anything in `${{ }}` is pasted into the script text before the shell runs, so a value an attacker controls (a branch name, a PR title) could inject commands. Environment variables are data, not code.
- Build once, test the output: the `build` job uploads `dist`; the `test` job downloads it and runs `npm test`. Tests then check the same bytes that were built, and the expensive compile is not repeated.

### Step 10. Commit
```text
git add .
git commit -m "Monorepo with tokens, ui and web"
```
Expected result: Git prints a summary of the files committed. If Git asks who you are, set `user.name` and `user.email` once with `git config --global`. The commit includes `package-lock.json` and no `dist` or `node_modules`, thanks to `.gitignore`. Pushing to GitHub is not needed for this lesson; the workflow starts running when the repository is hosted there.

## Run it
**Predict first:**
1. After a clean build, you edit only a comment in `packages/ui/src/index.ts` and run `npm run build` again. Which projects does `tsc --build` rebuild? Which is skipped?
2. You delete `packages/ui/dist` and run `npm run build`. What happens to `apps/web`?
3. What does `npm run clean` remove?

Answers (to check against the real output of `npx tsc --build --verbose`, which prints one line per project explaining its decision): (1) `ui` is rebuilt and `tokens` is up to date and skipped. Whether `web` is rebuilt depends on whether the declaration output of `ui` changed; a comment-only change normally leaves the `.d.ts` files the same, so read the verbose lines instead of assuming; (2) `ui` is rebuilt, and `web` follows because its input changed; (3) `tsc --build --clean` deletes the build outputs of all referenced projects.

## How it works
1. **Install.** npm reads `workspaces`, creates symlinks in the root `node_modules`, and merges every package's dependencies into one lockfile. External packages are *hoisted*: installed once at the root when versions allow.
2. **Resolve.** `import '@code101/ui'` is resolved by Node's rules: look in `node_modules`, find the symlink, read `exports`, load `dist/index.js`.
3. **Build.** `tsc --build` reads the references, orders the projects topologically, skips projects whose inputs are older than their `.tsbuildinfo`, and compiles the rest. TypeScript 7 can build independent projects in parallel (`--builders`) and type-check in parallel (`--checkers`); tune them on your CI machine and keep numbers you measured.
4. **CI.** Install, build, upload, download, test.

**Common misconception:** "In a monorepo everything is always built together." Only if you let it. The whole point of references, affected analysis and caches is *not* doing work whose inputs did not change.

**Trade-offs and decisions (ADR style)**

| Decision | Chosen | Alternative | Why / when to switch |
|---|---|---|---|
| Package manager | npm workspaces | pnpm, Yarn | Zero extra install, enough for small repositories. pnpm gives stricter dependency isolation (no phantom dependencies) and a content-addressed store; consider it when installs are slow or phantom dependencies bite |
| Build order | TypeScript project references | A task runner that reads `package.json` | References give incremental builds and editor navigation for free; a task runner is needed once non-TypeScript tasks (bundling, codegen, tests) need ordering and caching too |
| Packages point at `dist` | Yes, via `exports` | Point at `src` during development (a custom condition such as `development`) | `dist` is honest and identical to what consumers get; but you must build before you run. Pointing at source gives instant feedback but hides packaging bugs, so keep one CI job that uses the built output |
| Caching | npm download cache only | Cache `dist` and `.tsbuildinfo` | See "Cache failure modes". With TypeScript 7 a full build of a small repository is quick; measure before adding a cache |
| Affected-only CI | Informational | Run only affected tests | Safe default is run everything. Turn on affected-only when full runs exceed your patience, and keep a nightly full run to catch what the graph missed |
| Versioning | Private packages, no versions | Publish with a changelog tool | Only publish packages with outside consumers; internal packages need no release process |
| Build tool | None | Nx or Turborepo (task graph, local and remote cache) | Add one when you have many packages and measure repeated work that a cache would remove. They add configuration, a dependency and, with a remote cache, a trust boundary |

**Cache failure modes**
- **Stale output.** `tsc --build` decides "up to date" by comparing file timestamps and the contents recorded in `.tsbuildinfo`. If you restore an old `dist` from a cache *after* checking out newer sources, the restored files can look newer than the sources and the build may skip work it needed to do. Use an **exact** cache key made from a hash of every input (sources, configs, lockfile) and never restore a "nearest" older cache for compiled output.
- **Cache poisoning.** A cache written by an untrusted pull request and read by a trusted build can carry malicious files into the main branch. Keep caches written by pull requests separate from caches used for releases, and never put secrets inside cached folders.
- **Cache without a measurement.** A cache adds keys, restore time and failure modes. Record the build time with and without it in your CI log before keeping it.
- **Everything depends on everything.** A root file in every project's inputs makes every change "affect everything". Keep shared configuration small and stable.

**Other failure modes**
- **Phantom dependencies.** Because packages are hoisted to the root `node_modules`, a package can `import` something it never declared and it works on your machine and breaks once packages are published or when you switch package manager. The exercise creates one on purpose.
- **Circular dependencies.** `tsc --build` reports a circular project reference. Fix it by extracting the shared part into a third package; do not suppress it.
- **Tests in `dist`.** In this lesson the compiled tests live next to the compiled code, so they would ship in a published package. For a published package, build tests with a second `tsconfig` and keep them out of `files`.
- **A lockfile conflict storm.** In a busy repository, `package-lock.json` conflicts are frequent. Resolve by re-running `npm install` after merging `package.json`, never by hand-editing the lockfile.
- **Windows path length and line endings.** Deep `node_modules` trees hit path limits on older Windows setups, and `git` may convert line endings. Keep the repository close to the drive root and configure `.gitattributes` for consistent line endings if your team mixes platforms.

**When not to use a monorepo**
- One application and one library with one team: two folders in one package is simpler.
- Packages with different owners, access rules or release cadences that cannot share one CI budget.
- A repository so large that clone and checkout time dominate; then you need sparse checkout or separate repositories.

## Try it
Copy the repository to `monorepo-lab-try` (or create a branch). The starter is `exercise/starter/packages/charts`.
1. **Guided.** Add the fourth workspace `@code101/charts`: copy the three starter files into `packages/charts/` (`package.json`, `tsconfig.json`, `src/index.ts`). Run `npm install` and `npm run build`. Does it work even though `package.json` does not declare the dependency on tokens? Then run `npm run affected --silent -- packages/tokens/src/index.ts`: is `@code101/charts` listed? Fix the three TODOs (declare the dependency, add a `references` entry, add the project to the root `tsconfig.json`) until `@code101/charts` appears in the list and a **clean** build (`npm run clean`, then `npm run build`) succeeds.
2. **Change.** Add a `test:affected` script that runs only the tests of affected workspaces. What does your script do when a root file changed? Which wrong answer is cheaper: running too many tests or too few?
3. **Stretch (no single answer).** Write a four-line ADR on whether this repository should adopt Turborepo or Nx. State what you would measure first (build time per job, repeated work, cache hit rate), and what result would make you say no.

<details><summary>Solution</summary>

For rung 1, the solution's `packages/charts` files are:

**File: `packages/charts/package.json`**
```json
{
  "name": "@code101/charts",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "default": "./dist/index.js"
    }
  },
  "dependencies": {
    "@code101/tokens": "*"
  }
}
```
**File: `packages/charts/tsconfig.json`**
```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "rootDir": "src",
    "outDir": "dist"
  },
  "include": ["src/**/*.ts"],
  "references": [{ "path": "../tokens" }]
}
```
**File: `packages/charts/src/index.ts`**
```ts
import { cssVar } from '@code101/tokens';

export function barColor(): string {
  return cssVar('color-action-background');
}
```
**File: `tsconfig.json`** (root)
```json
{
  "files": [],
  "references": [
    { "path": "packages/tokens" },
    { "path": "packages/charts" },
    { "path": "packages/ui" },
    { "path": "apps/web" }
  ]
}
```
After the fix, `npm run affected --silent -- packages/tokens/src/index.ts` should print:
```text
@code101/charts
@code101/tokens
@code101/ui
@code101/web
```
Why the starter "worked" before the fix: npm linked every workspace into the root `node_modules`, so the import resolved even without a declared dependency. What broke was everything *around* the import: the affected analysis (it reads declared dependencies) missed `charts`, and without a `references` entry a clean build could compile `charts` before `tokens` had produced its declarations and fail with a "cannot find module" error. For rung 2: when a root file changed, run everything; running too many tests wastes minutes, running too few ships a bug, so the safe error is to run too many.

</details>

## Check yourself
1. What is a phantom dependency and why does an npm workspace make it easy to create one? <details><summary>Answer</summary>An import of a package you did not declare. Workspaces hoist packages to the root <code>node_modules</code>, so the import resolves anyway; it breaks later, when the package is installed elsewhere.</details>
2. Why does the CI workflow pass `github.base_ref` through `env` instead of inlining it in the command? <details><summary>Answer</summary>Expression values are pasted into the script before the shell runs, so an attacker-controlled value could inject commands. An environment variable is read as data.</details>
3. Why is `restore-keys` (a "nearest older cache" fallback) dangerous for compiled output? <details><summary>Answer</summary>Restored files can have newer timestamps than changed sources, so the incremental build may skip a rebuild and ship stale output.</details>
4. Find the bug: a package imports `@code101/tokens` but only `@code101/ui` is listed in its `dependencies`. What does the affected script report when only tokens changed? <details><summary>Answer</summary>It misses the package unless ui is also affected through its own dependency chain; the undeclared edge is invisible to the graph, so the change can ship untested.</details>
5. Why is the "affected" step marked information only? <details><summary>Answer</summary>The graph may miss edges (undeclared or non-code dependencies). Using it to skip tests is a decision to make with a nightly full run as a safety net.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `npm error code EBADENGINE` (typical) | `engine-strict` is on and your Node is older than `engines` | Install the pinned Node version |
| `Cannot find module '@code101/ui' or its corresponding type declarations.` (typical) | `ui` is not built yet, or `npm install` was not run at the root | Run `npm install` in the root, then `npm run build` |
| `error TS6306: Referenced project ... must have setting "composite": true.` (typical) | A referenced `tsconfig.json` does not extend the base | Extend `tsconfig.base.json` or set `composite` |
| `error TS6307: File ... is not listed within the file list of project ...` (typical) | `composite` requires every file to be matched by `include` | Add the folder to `include` |
| `Unable to resolve ... node_modules` after switching branches | Stale `node_modules` or symlinks | Delete `node_modules` and run `npm ci` |
| `npm test` finds no tests | The build did not run, so there is no `dist` | Run `npm run build` first |
| `'xargs' is not recognized` when running the CI step locally on Windows | `xargs` is a Linux command; the workflow runs on Linux | Run the script with explicit file arguments, as in step 8 |
| `npm.ps1 cannot be loaded` | PowerShell execution policy | Use `npm.cmd` |

## Best practice
Make the dependency graph explicit in two places that agree: `dependencies` in `package.json` and `references` in `tsconfig.json`. Source: npm documentation, [Workspaces](https://docs.npmjs.com/cli/v11/using-npm/workspaces); TypeScript handbook, [Project References](https://www.typescriptlang.org/docs/handbook/project-references.html); GitHub Docs, [Security hardening for GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions).

## Production checklist
- [ ] Lockfile committed; CI uses `npm ci --ignore-scripts`.
- [ ] `permissions: contents: read` at the top of every workflow; extra permissions only on the job that needs them.
- [ ] No `${{ }}` expression containing user-controlled text inside a `run:` script; use `env`.
- [ ] Every workspace declares what it imports; a check (a script or lint rule) fails on undeclared imports.
- [ ] Build output is cached only with an exact key, or not at all; you measured both.
- [ ] A scheduled full build and test runs even if "affected" is used on pull requests.
- [ ] Actions are pinned (lesson 08 shows pinning by commit SHA) and updated by a bot.
- [ ] `timeout-minutes` and `concurrency` set; artifacts have a short retention.
- [ ] Packages that are published have a separate build configuration without tests.

## Going further
- TypeScript 7 flags `--builders`, `--checkers` and `--singleThreaded` are described in the TypeScript 7.0 announcement; try `npx tsc --build --verbose` first, then change one flag at a time and write down your measurements.
- Capstone link: both web capstones are single-package applications. Imagine splitting the generated API client of [capstones/web-react](../../../../capstones/web-react/README.md) into its own workspace: which files move, and which tsconfig reference does the app add?

## Summary
- You built an npm workspaces repository with three packages and explained linking, hoisting and phantom dependencies.
- You used TypeScript project references so `tsc --build` compiles in order and incrementally.
- You wrote a CI workflow with least-privilege permissions that builds once and tests the output.
- You listed the failure modes of caches and decided what to measure before adding one.

## Next lesson
06. API clients generated from OpenAPI: derive types from the contract, validate at runtime, and handle versioning.
