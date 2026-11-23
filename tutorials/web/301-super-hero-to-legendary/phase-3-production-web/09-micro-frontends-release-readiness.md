---
track: web
level: 301
phase: 3
phase_name: production-web
lesson: 09
title: "Micro-frontends, release strategy and a production readiness checklist"
time: 180 min
prerequisites: [web-301.02, web-301.07, web-301.08]
versions: { node: "26.13.1", npm: "11.20.0", typescript: "7.0.2", "@types/node": "26.6.6", "actions/checkout": "v7.0.1", "actions/setup-node": "v7.1.0", "actions/upload-artifact": "v7.0.2" }
verified: not yet run
source: source/web/301-super-hero-to-legendary/phase-3-production-web/09-micro-frontends-release-readiness/
assets: []
---

# 09. Micro-frontends, release strategy and a production readiness checklist

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- decide whether micro-frontends fit a team structure, and name what you pay for them (contracts, duplication, failure isolation)
- write a remote loader with a timeout, a contract check and a typed failure result, and rehearse each failure without a network
- run a staged release with a sticky percentage flag, a kill switch and a rollback that works, and explain the stop conditions
- review a release against a production readiness checklist, separate what a machine can check from what a person must judge, and defend a "block" decision

## Recap
1. In lesson 06 a response that did not match the schema became a `contract-violation`, not a crash. What is the same idea for a remote that fails to load?
   <details><summary>Answer</summary>A typed failure result and a fallback: the shell must keep working when a part fails, and must know why it failed.</details>
2. In lesson 07 you set a budget that failed the build. What can go wrong when a budget is "fixed" by raising it?
   <details><summary>Answer</summary>The check passes because the limit moved, not because the page improved. A limit change is a decision that needs an owner and a reason.</details>
3. In lesson 08 what did report-only mode give you before enforcement?
   <details><summary>Answer</summary>Evidence of what would break, with nothing blocked: a safe way to learn before you commit.</details>

## Why it matters
The hardest problems of a large web product are not technical. They are about teams that need to ship independently without breaking each other, and about releases that must be reversible. Micro-frontends and progressive delivery are two answers to those problems, and both have a cost that is easy to underestimate. A release is also a decision made by people under time pressure; a checklist is how you make that decision with the evidence in front of you and the same questions every time.

## What you will build
1. A **remote loader** with a manifest contract, a timeout and typed failures, rehearsed against five scenarios without a browser.
2. A **rollout module**: a sticky, percentage-based flag with an allow list and a kill switch.
3. A **release readiness checker**: a report schema, 15 automated checks (11 blockers, 4 warnings), and a command that exits with failure when the release is not ready.
4. The **human checklist** (`PRODUCTION-READINESS.md`) and a **release workflow** with stages.
5. A **review exercise**: you will review a realistic, flawed pull request before you read the answer key.

## Before you start
- Lessons 01 to 08 finished (Node 26.13.1, npm 11.20.0, TypeScript 7.0.2).
- Builds on Web 201 lesson [12 Testing with Vitest and the task board](../../201-hero-to-super-hero/phase-4-quality-and-ship/12-testing-and-task-board-project.md) (a shipped application and its Docker and nginx delivery). This lesson is about shipping *parts* of an application independently and shipping them safely.
- Time: 150 to 180 minutes, two sittings. Break after step 7. The review exercise alone is 45 to 60 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/301-super-hero-to-legendary/phase-3-production-web/09-micro-frontends-release-readiness/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- No `package-lock.json` is shipped; `npm install` creates it.
- The loader is written to be browser-ready (`Target` can be an `HTMLElement`) but is rehearsed in Node with fake remotes. Wiring it to a real bundler build of two applications is the capstone-level exercise at the end.

## Steps

### Step 1. Create the project
```text
mkdir release-lab
cd release-lab
mkdir src
mkdir data
```

### Step 2. Write package.json and tsconfig.json
**File: `package.json`**
```json
{
  "name": "web301-09-micro-frontends-release",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "tsc",
    "demo": "tsc && node dist/demo.js",
    "check": "tsc && node dist/check-release.js data/release-candidate.json"
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
**File: `tsconfig.json`** (identical to lesson 01, step 3)
```json
{
  "compilerOptions": {
    "target": "ES2023",
    "lib": ["ES2023"],
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "rootDir": "src",
    "outDir": "dist",
    "types": ["node"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
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
```text
npm install --no-audit --no-fund
```

### Step 3. Decide: do you need micro-frontends? (ADR)
A **micro-frontend** is a part of a web application that is built, deployed and owned by a different team, and assembled into one page or one site at build time, at the edge or in the browser. Before you write code, write the decision.

| Integration approach | How it works | Strong points | Weak points |
|---|---|---|---|
| **Packages in a monorepo** (lesson 05) | Teams ship libraries; one application build assembles them | Simple, one bundle, shared types, easy refactors | One release train: a team cannot ship alone |
| **Runtime ES modules** (this lesson) | The shell `import()`s each remote's module at run time from a manifest | Independent deploys, no special tooling | You own the contract, versioning, loading and failure handling |
| **Module Federation** (bundler feature) | The bundler shares dependencies and exposes modules across builds | Shared libraries between remotes, mature tooling | Tied to a bundler and its versions; version skew of shared packages is your problem |
| **iframes** | Each part is a separate document | Strongest isolation of scripts, styles, crashes and security origin | Hard to size, navigate, share state and make accessible; extra cost per frame |
| **Web Components** (custom elements) | Each part registers an element; the shell uses the tag | Framework-neutral contract; style isolation with Shadow DOM | Server rendering and form participation need care; a global registry means name clashes |
| **Server or edge composition** | The server stitches HTML fragments before sending | Fast first paint, little client JavaScript | Interactive parts still need a client strategy; harder local development |

**Decision record for the Tasks and Teams web client (an example to adapt):**
- *Context:* one team owns the web client today; the capstones are a single application each.
- *Decision:* **do not adopt micro-frontends yet.** Stay with packages in one repository (lesson 05).
- *Consequences:* one release train and one bundle; refactors are cheap; a second team can still contribute through packages.
- *We would revisit if:* three or more teams need to deploy their screens on independent schedules, **and** the cost of coordinating one release has been measured (days lost per month), **and** a design system (lesson 04) and a shared contract already exist.

**When not to use micro-frontends:** fewer than three autonomous teams; a shared release cadence anyway; a tight performance budget (each remote can duplicate frameworks and add requests, and your INP and bundle budget from lesson 07 pay for it); no design system (users will see different products glued together); no one who owns the cross-cutting concerns (routing, authentication, error handling, observability).

### Step 4. Write the contract and the loader
**File: `src/contract.ts`**
```ts
// The agreement between the shell (host) and a remote. Change it with the same care as a public API.
export const HOST_CONTRACT = 2;

export interface HostContext {
  teamId: string;
  navigate: (path: string) => void;
}

export type Unmount = () => void;

// Target is the thing a remote draws into: an HTMLElement in a browser, a plain object in tests.
export interface RemoteModule<Target> {
  mount: (target: Target, context: HostContext) => Unmount;
}

export interface RemoteEntry {
  name: string;
  url: string;
  contract: number;
}
```
Design decisions in a few lines:
- The remote receives **what it needs** (`teamId`, a `navigate` function), not the shell's internals, and not a token (lesson 08: a global token is readable by every script).
- `mount` returns an `Unmount` function. A remote that cannot be cleanly removed leaks listeners, timers and memory every time the user navigates. Cleanup is part of the contract.
- `contract` is an integer **major version** of this interface. The shell and a remote must agree on it; the manifest says which one a remote speaks.
- `Target` is generic so the same contract works with a DOM element and with a test double.

**File: `src/loader.ts`**
```ts
import type { RemoteEntry, RemoteModule } from './contract.js';

export type Importer = (url: string) => Promise<unknown>;

export type LoadFailure = 'timeout' | 'import-error' | 'contract-mismatch' | 'invalid-module';

export type LoadResult<Target> =
  | { status: 'loaded'; module: RemoteModule<Target> }
  | { status: 'failed'; reason: LoadFailure; detail: string };

export interface LoadOptions {
  timeoutMs: number;
  hostContract: number;
}

function failed<Target>(reason: LoadFailure, detail: string): LoadResult<Target> {
  return { status: 'failed', reason, detail };
}

function isRemoteModule<Target>(value: unknown): value is RemoteModule<Target> {
  return typeof value === 'object' && value !== null && typeof (value as { mount?: unknown }).mount === 'function';
}

// In a browser the importer is (url) => import(url). Here it is injected, so every failure can be rehearsed.
export async function loadRemote<Target>(
  entry: RemoteEntry,
  importer: Importer,
  options: LoadOptions,
): Promise<LoadResult<Target>> {
  // Cheap check first: do not even download a remote that speaks another contract.
  if (entry.contract !== options.hostContract) {
    return failed('contract-mismatch', `remote speaks contract ${entry.contract}, host needs ${options.hostContract}`);
  }

  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<'timeout'>((resolve) => {
    timer = setTimeout(() => resolve('timeout'), options.timeoutMs);
  });

  try {
    const outcome = await Promise.race([importer(entry.url), timeout]);
    if (outcome === 'timeout') {
      return failed('timeout', `no answer within ${options.timeoutMs} ms`);
    }
    if (!isRemoteModule<Target>(outcome)) {
      return failed('invalid-module', 'mount is not a function');
    }
    return { status: 'loaded', module: outcome };
  } catch (error) {
    return failed('import-error', error instanceof Error ? error.message : String(error));
  } finally {
    clearTimeout(timer);
  }
}
```
How it works:
- The **importer is injected**. In a browser you pass `(url) => import(url)`; in tests you pass fakes. A loader that calls `import()` directly can only be tested in a browser.
- The result is a **union with a reason**, never a thrown exception. The shell's code is a `switch` on `status` and `reason` (the exhaustive pattern from lesson 02), and each reason can have its own user-facing message and its own metric.
- The timeout is a race. `import()` cannot be cancelled; after the timeout fires the pending promise keeps running, and if it resolves later nothing uses it. `clearTimeout` in `finally` stops the timer from keeping the process alive after a successful load.
- A module namespace object is checked at **runtime** (`isRemoteModule`): a remote deployed by another team is data from outside your build, exactly like the API responses of lesson 06.

### Step 5. Write the rollout module
**File: `src/rollout.ts`**
```ts
export interface FlagConfig {
  name: string;
  percent: number;
  killSwitch: boolean;
  allowList: readonly string[];
}

// FNV-1a, 32 bit: small, fast and identical on every platform. It spreads users; it is not a security hash.
export function hash32(text: string): number {
  let hash = 0x811c9dc5;
  for (let index = 0; index < text.length; index += 1) {
    hash ^= text.charCodeAt(index);
    hash = Math.imul(hash, 0x01000193);
  }
  return hash >>> 0;
}

// The flag name is part of the key, so a user who is early for one flag is not early for all of them.
export function bucketOf(userId: string, flagName: string): number {
  return hash32(`${flagName}:${userId}`) % 100;
}

export function isEnabled(flag: FlagConfig, userId: string): boolean {
  if (!Number.isInteger(flag.percent) || flag.percent < 0 || flag.percent > 100) {
    throw new RangeError(`percent must be a whole number from 0 to 100, got ${flag.percent}`);
  }
  if (flag.killSwitch) {
    return false;
  }
  if (flag.allowList.includes(userId)) {
    return true;
  }
  return bucketOf(userId, flag.name) < flag.percent;
}
```
Properties that matter in production, and how this code gets them:
- **Sticky.** The same user always lands in the same bucket (the bucket depends only on the flag name and the user id), so a user does not see the new board on one request and the old one on the next.
- **Monotonic ramp.** A user enabled at 10 percent is also enabled at 20 percent, because enabling means `bucket < percent`. Raising the percentage only ever adds users.
- **Independent flags.** Including the flag name in the hash means a different set of users is "early" for each flag; otherwise the same unlucky 5 percent would test every new feature.
- **Kill switch before everything.** An emergency off switch wins over the allow list. It must work without a deployment: in production the flag configuration comes from a service or a file that can be changed in seconds, not from this code.
- **Validation.** A percentage of `150` or `1.5` is a configuration bug; the function fails loudly instead of guessing.
- `hash32` is **not** cryptographic. Do not use it to protect anything; it only spreads users evenly. If the user id is guessable, a user can guess their own bucket: flags are not an access control mechanism.

### Step 6. Write the demo and run it
**File: `src/demo.ts`**
```ts
import type { HostContext, RemoteEntry, RemoteModule } from './contract.js';
import { HOST_CONTRACT } from './contract.js';
import { loadRemote, type Importer } from './loader.js';
import { isEnabled, type FlagConfig } from './rollout.js';

interface FakeTarget {
  text: string;
}

const tasksModule: RemoteModule<FakeTarget> = {
  mount(target: FakeTarget, context: HostContext) {
    target.text = `Tasks board for team ${context.teamId}`;
    return () => {
      target.text = '';
    };
  },
};

const importer: Importer = async (url) => {
  switch (url) {
    case '/remotes/tasks.js':
      return tasksModule;
    case '/remotes/reports.js':
      return new Promise<never>(() => {});
    case '/remotes/search.js':
      throw new Error('network down');
    case '/remotes/profile.js':
      return { mount: 'not a function' };
    default:
      throw new Error(`unexpected url ${url}`);
  }
};

const entries: RemoteEntry[] = [
  { name: 'tasks', url: '/remotes/tasks.js', contract: 2 },
  { name: 'billing', url: '/remotes/billing.js', contract: 1 },
  { name: 'reports', url: '/remotes/reports.js', contract: 2 },
  { name: 'search', url: '/remotes/search.js', contract: 2 },
  { name: 'profile', url: '/remotes/profile.js', contract: 2 },
];

const options = { timeoutMs: 50, hostContract: HOST_CONTRACT };

for (const entry of entries) {
  const result = await loadRemote<FakeTarget>(entry, importer, options);
  if (result.status === 'loaded') {
    const target: FakeTarget = { text: '' };
    const unmount = result.module.mount(target, { teamId: 'core', navigate: () => {} });
    console.log(`${entry.name}: loaded`);
    console.log(`mounted: ${target.text}`);
    unmount();
    console.log(`unmounted: ${target.text === ''}`);
  } else {
    console.log(`${entry.name}: failed ${result.reason} (${result.detail})`);
  }
}

const users = Array.from({ length: 1000 }, (_, index) => `user-${index}`);
const flag = (percent: number, extra: Partial<FlagConfig> = {}): FlagConfig => ({
  name: 'board-v2',
  percent,
  killSwitch: false,
  allowList: [],
  ...extra,
});
const count = (config: FlagConfig): number => users.filter((user) => isEnabled(config, user)).length;

console.log(`rollout 0%: ${count(flag(0))} of 1000`);
console.log(`rollout 100%: ${count(flag(100))} of 1000`);
console.log(`rollout 50% within tolerance: ${Math.abs(count(flag(50)) - 500) <= 150}`);
console.log(`sticky: ${isEnabled(flag(30), 'user-7') === isEnabled(flag(30), 'user-7')}`);
console.log(`ramp is a subset: ${users.every((user) => !isEnabled(flag(10), user) || isEnabled(flag(20), user))}`);
console.log(`kill switch: ${count(flag(100, { killSwitch: true }))} of 1000`);
console.log(`allow list at 0%: ${isEnabled(flag(0, { allowList: ['user-7'] }), 'user-7')}`);
```
**Predict first:** which of the five remotes load? What will the `reports` remote's failure say, and how long does the demo wait for it? What do you expect for 50 percent: exactly 500?
```text
npm run demo --silent
```
Expected output (not yet run):
```text
tasks: loaded
mounted: Tasks board for team core
unmounted: true
billing: failed contract-mismatch (remote speaks contract 1, host needs 2)
reports: failed timeout (no answer within 50 ms)
search: failed import-error (network down)
profile: failed invalid-module (mount is not a function)
rollout 0%: 0 of 1000
rollout 100%: 1000 of 1000
rollout 50% within tolerance: true
sticky: true
ramp is a subset: true
kill switch: 0 of 1000
allow list at 0%: true
```
Answers: only `tasks` loads; `reports` fails after 50 milliseconds, the timeout you set; the 50 percent count is *about* 500, not exactly: the test allows 150 either way, because a hash spreads users evenly in the long run, not perfectly in any sample. The 0 and 100 percent lines are exact by construction. The percent-of-1000 numbers for other percentages are yours to count if you want them.

**Take a break here if you need one.**

### Step 7. Write the release readiness checker
The rollout module decides *who* sees a change. The checker decides *whether the change may ship at all*.

**File: `src/report.ts`**
```ts
export interface ReleaseReport {
  version: string;
  changes: { breakingApi: boolean; migrations: boolean; featureFlagged: boolean };
  quality: { typecheck: boolean; unitTestsPassed: boolean; e2eSmokePassed: boolean; budgetsPassed: boolean };
  security: {
    auditHighFindings: number;
    cspReportOnlyViolationsLast7d: number;
    secretsScanPassed: boolean;
    actionsPinned: boolean;
  };
  accessibility: { axeCriticalIssues: number; keyboardPathVerified: boolean };
  operations: {
    rollbackPlan: boolean;
    rollbackTestedWithinDays: number | null;
    dashboardLink: string | null;
    onCallAcknowledged: boolean;
    canaryPercent: number;
  };
  documentation: { changelogEntry: boolean; adrLinked: boolean };
}

type Kind = 'string' | 'boolean' | 'number' | 'number|null' | 'string|null';
interface Shape {
  [key: string]: Kind | Shape;
}

// The report arrives from a pipeline: treat it as untrusted data and check every field before use.
const SHAPE: Shape = {
  version: 'string',
  changes: { breakingApi: 'boolean', migrations: 'boolean', featureFlagged: 'boolean' },
  quality: { typecheck: 'boolean', unitTestsPassed: 'boolean', e2eSmokePassed: 'boolean', budgetsPassed: 'boolean' },
  security: {
    auditHighFindings: 'number',
    cspReportOnlyViolationsLast7d: 'number',
    secretsScanPassed: 'boolean',
    actionsPinned: 'boolean',
  },
  accessibility: { axeCriticalIssues: 'number', keyboardPathVerified: 'boolean' },
  operations: {
    rollbackPlan: 'boolean',
    rollbackTestedWithinDays: 'number|null',
    dashboardLink: 'string|null',
    onCallAcknowledged: 'boolean',
    canaryPercent: 'number',
  },
  documentation: { changelogEntry: 'boolean', adrLinked: 'boolean' },
};

function matches(kind: Kind, value: unknown): boolean {
  switch (kind) {
    case 'string':
      return typeof value === 'string';
    case 'boolean':
      return typeof value === 'boolean';
    case 'number':
      return typeof value === 'number' && Number.isFinite(value);
    case 'number|null':
      return value === null || (typeof value === 'number' && Number.isFinite(value));
    case 'string|null':
      return value === null || typeof value === 'string';
  }
}

function check(shape: Shape, value: unknown, path: string, problems: string[]): void {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    problems.push(`${path === '' ? 'report' : path} must be an object`);
    return;
  }
  const record = value as Record<string, unknown>;
  for (const [key, expected] of Object.entries(shape)) {
    const childPath = path === '' ? key : `${path}.${key}`;
    if (typeof expected === 'string') {
      if (!matches(expected, record[key])) {
        problems.push(`${childPath} must be ${expected}`);
      }
    } else {
      check(expected, record[key], childPath, problems);
    }
  }
}

export function parseReport(text: string): ReleaseReport {
  let data: unknown;
  try {
    data = JSON.parse(text);
  } catch {
    throw new Error('Release report is not valid JSON');
  }
  const problems: string[] = [];
  check(SHAPE, data, '', problems);
  if (problems.length > 0) {
    throw new Error(`Invalid release report:\n- ${problems.join('\n- ')}`);
  }
  return data as ReleaseReport;
}
```
The report is a plain JSON file your pipeline writes from facts it can know: test results, audit counts, a link, an acknowledgement. The **type** says what the checks need; the **shape table** validates the file at runtime (the second copy of the contract again, and this time small enough to keep by hand). A missing field produces an error that names the field, instead of `undefined` silently counting as "not failing".

**File: `src/readiness.ts`**
```ts
import type { ReleaseReport } from './report.js';

export type Severity = 'blocker' | 'warning';

export interface Check {
  id: string;
  severity: Severity;
  title: string;
  passes: (report: ReleaseReport) => boolean;
}

// Automated checks are the floor, not the ceiling: PRODUCTION-READINESS.md lists what people still review.
export const CHECKS: readonly Check[] = [
  {
    id: 'quality.tests',
    severity: 'blocker',
    title: 'Type check, unit tests and end-to-end smoke tests pass',
    passes: (r) => r.quality.typecheck && r.quality.unitTestsPassed && r.quality.e2eSmokePassed,
  },
  { id: 'quality.budgets', severity: 'blocker', title: 'Performance budgets pass', passes: (r) => r.quality.budgetsPassed },
  {
    id: 'security.audit',
    severity: 'blocker',
    title: 'No high or critical dependency findings',
    passes: (r) => r.security.auditHighFindings === 0,
  },
  { id: 'security.secrets', severity: 'blocker', title: 'Secret scan is clean', passes: (r) => r.security.secretsScanPassed },
  {
    id: 'security.actions-pinned',
    severity: 'warning',
    title: 'CI actions are pinned to commit SHAs',
    passes: (r) => r.security.actionsPinned,
  },
  {
    id: 'security.csp-reports',
    severity: 'warning',
    title: 'No report-only CSP violations in the last 7 days',
    passes: (r) => r.security.cspReportOnlyViolationsLast7d === 0,
  },
  {
    id: 'a11y.axe',
    severity: 'blocker',
    title: 'No critical automated accessibility issues',
    passes: (r) => r.accessibility.axeCriticalIssues === 0,
  },
  {
    id: 'a11y.keyboard',
    severity: 'blocker',
    title: 'The main task works with the keyboard alone',
    passes: (r) => r.accessibility.keyboardPathVerified,
  },
  { id: 'ops.rollback-plan', severity: 'blocker', title: 'A rollback plan exists', passes: (r) => r.operations.rollbackPlan },
  {
    id: 'ops.rollback-tested',
    severity: 'warning',
    title: 'Rollback was tested in the last 90 days',
    passes: (r) => r.operations.rollbackTestedWithinDays !== null && r.operations.rollbackTestedWithinDays <= 90,
  },
  { id: 'ops.dashboard', severity: 'blocker', title: 'A dashboard link is attached', passes: (r) => r.operations.dashboardLink !== null },
  { id: 'ops.oncall', severity: 'blocker', title: 'On-call acknowledged the release', passes: (r) => r.operations.onCallAcknowledged },
  {
    id: 'ops.canary',
    severity: 'blocker',
    title: 'Unflagged changes start at 10 percent or less',
    passes: (r) => r.changes.featureFlagged || (r.operations.canaryPercent >= 1 && r.operations.canaryPercent <= 10),
  },
  {
    id: 'docs.breaking-adr',
    severity: 'blocker',
    title: 'Breaking API changes link a decision record',
    passes: (r) => !r.changes.breakingApi || r.documentation.adrLinked,
  },
  { id: 'docs.changelog', severity: 'warning', title: 'A changelog entry exists', passes: (r) => r.documentation.changelogEntry },
];

export interface Finding {
  check: Check;
  passed: boolean;
}

export function evaluate(report: ReleaseReport): Finding[] {
  return CHECKS.map((check) => ({ check, passed: check.passes(report) }));
}

export interface Summary {
  lines: string[];
  blockers: number;
  warnings: number;
  ready: boolean;
}

export function summarize(findings: readonly Finding[], version: string): Summary {
  const lines = findings.map(({ check, passed }) => {
    const status = passed ? 'PASS' : check.severity === 'blocker' ? 'FAIL' : 'WARN';
    return `${status} ${check.id}: ${check.title}`;
  });
  const blockers = findings.filter((finding) => !finding.passed && finding.check.severity === 'blocker').length;
  const warnings = findings.filter((finding) => !finding.passed && finding.check.severity === 'warning').length;
  const ready = blockers === 0;
  lines.push(`${blockers} blocker(s) failing, ${warnings} warning(s). ${ready ? 'Ready' : 'NOT ready'} to release ${version}`);
  return { lines, blockers, warnings, ready };
}
```
Design notes: each check is **data** (an id, a severity, a sentence and a function), so adding a check is one entry and the output stays uniform. A blocker stops the release; a warning is recorded and discussed. The checks read facts the report supplies; they do not run tests themselves. That separation matters: the checker is fast, deterministic and the same on a laptop and in CI.

**File: `src/check-release.ts`**
```ts
import { readFileSync } from 'node:fs';
import { evaluate, summarize } from './readiness.js';
import { parseReport } from './report.js';

const file = process.argv[2];
if (file === undefined) {
  console.error('Usage: node dist/check-release.js <report.json>');
  process.exit(2);
}

const report = parseReport(readFileSync(file, 'utf8'));
const summary = summarize(evaluate(report), report.version);
console.log(summary.lines.join('\n'));
process.exitCode = summary.ready ? 0 : 1;
```
**File: `data/release-candidate.json`**
```json
{
  "version": "2026.11.3",
  "changes": { "breakingApi": false, "migrations": true, "featureFlagged": true },
  "quality": { "typecheck": true, "unitTestsPassed": true, "e2eSmokePassed": true, "budgetsPassed": true },
  "security": {
    "auditHighFindings": 1,
    "cspReportOnlyViolationsLast7d": 0,
    "secretsScanPassed": true,
    "actionsPinned": true
  },
  "accessibility": { "axeCriticalIssues": 0, "keyboardPathVerified": true },
  "operations": {
    "rollbackPlan": true,
    "rollbackTestedWithinDays": null,
    "dashboardLink": "https://dashboards.example.test/d/web-release",
    "onCallAcknowledged": true,
    "canaryPercent": 5
  },
  "documentation": { "changelogEntry": true, "adrLinked": false }
}
```
```text
npm run check --silent
```
Expected output (not yet run), and the command exits with code 1:
```text
PASS quality.tests: Type check, unit tests and end-to-end smoke tests pass
PASS quality.budgets: Performance budgets pass
FAIL security.audit: No high or critical dependency findings
PASS security.secrets: Secret scan is clean
PASS security.actions-pinned: CI actions are pinned to commit SHAs
PASS security.csp-reports: No report-only CSP violations in the last 7 days
PASS a11y.axe: No critical automated accessibility issues
PASS a11y.keyboard: The main task works with the keyboard alone
PASS ops.rollback-plan: A rollback plan exists
WARN ops.rollback-tested: Rollback was tested in the last 90 days
PASS ops.dashboard: A dashboard link is attached
PASS ops.oncall: On-call acknowledged the release
PASS ops.canary: Unflagged changes start at 10 percent or less
PASS docs.breaking-adr: Breaking API changes link a decision record
PASS docs.changelog: A changelog entry exists
1 blocker(s) failing, 1 warning(s). NOT ready to release 2026.11.3
```
Change `"auditHighFindings": 1` to `0` and run it again: the `FAIL` line becomes `PASS`, the last line reads `0 blocker(s) failing, 1 warning(s). Ready to release 2026.11.3` and the exit code is 0. Note what did **not** block the release: a warning about an untested rollback. Is that the right call? That is a policy decision your team should make explicitly: if you think it should block, change its severity and write down why.

### Step 8. Write the human checklist
**File: `PRODUCTION-READINESS.md`**
```markdown
# Production readiness review

Use this list in the release review. The automated checks in `src/readiness.ts` are the floor;
this list is what people still decide. A blocker is a reason not to ship. Write the evidence next to each answer
(a link, a number you measured, a name), never just "yes".

## Reliability
- [ ] Blocker: every dependency of this release (services, remotes, third-party scripts) has a timeout and a visible fallback.
- [ ] Blocker: a failed remote or API call shows the user a useful message and does not blank the page.
- [ ] A load or soak test covered the new code path, or you wrote down why it did not need one.
- [ ] Retries are limited and only for safe requests; there is a circuit breaker or a budget for repeated failures.

## Performance
- [ ] Blocker: size budgets pass; any raised limit has a reviewed reason and an owner.
- [ ] INP, LCP and CLS from field data were checked for the pages this release touches (your own numbers, with the percentile).
- [ ] No new third-party script without a loading strategy and an owner.

## Security
- [ ] Blocker: no new `unsafe-inline` or `unsafe-eval`, no new wildcard in the CSP; report-only results reviewed.
- [ ] Blocker: tokens are not placed on globals, in URLs, in logs or in storage that scripts can read without a decision record.
- [ ] New dependencies were reviewed by name: exact version, maintainers, install scripts, licence.
- [ ] CORS, redirects and `postMessage` handlers were reviewed if the release touches them.

## Accessibility
- [ ] Blocker: the main task was completed with the keyboard alone and with a screen reader, by a person.
- [ ] Focus is managed when content appears, moves or is removed (dialogs, remotes, route changes).
- [ ] Colour contrast of new tokens is checked per theme; reduced motion and forced colours were tried.

## Data and compatibility
- [ ] Blocker: database changes are backward compatible with the previous release (expand first, contract later).
- [ ] Old browser tabs that still run the previous build keep working against the new server for the overlap period.
- [ ] Hashed static files of the previous release stay available long enough for open tabs.

## Rollout
- [ ] Blocker: a rollback plan exists, names who decides, and was rehearsed for this kind of change.
- [ ] Blocker: the change is behind a flag or starts with a small share of traffic, with a kill switch.
- [ ] The stop conditions are numbers decided before the release (error rate, INP percentile, support tickets).
- [ ] Not released on a Friday afternoon, before a holiday, or when the people who can fix it are away.

## Observability and ownership
- [ ] Blocker: a dashboard shows the stop conditions for this release, and the link is in the release record.
- [ ] Errors from remotes and from the new code are tagged with the release version.
- [ ] On-call acknowledged the release and knows the rollback steps.
- [ ] Support has the user-facing notes and a way to tell which release a user is on.

## Documentation
- [ ] Blocker for breaking changes: a decision record (ADR) explains the trade-off and the migration path.
- [ ] The changelog says what changed for users and for integrators, and what to do about it.
```
What a *machine* cannot do, and this list therefore asks a *person* to do: judge whether a rollback plan would actually work, whether a fallback is useful, whether a keyboard path is usable, whether a stop condition is the right one. The checklist is also a teaching tool: when a review finds a problem the list did not name, **add it to the list** (and to `readiness.ts` if a machine can check it). A checklist that never changes is not being used.

**Release strategy in one table**

| Technique | What it gives you | Cost or trap |
|---|---|---|
| **Trunk-based development** with small changes | Fewer merge surprises, smaller releases | Needs flags for unfinished work and a fast, trusted pipeline |
| **Feature flags** (this lesson's `rollout.ts`) | Decouple deploy from release; instant off switch | Flag debt: remove a flag when the rollout is done; test both states |
| **Canary / progressive delivery** | A small, real audience finds problems first | Needs good metrics and a decision rule, or it is theatre |
| **Blue-green** | Two full environments; switch traffic | Double the infrastructure; database changes still have to work for both versions |
| **Roll back vs roll forward** | Rollback restores the known state; a forward fix removes the cause | Rollback is only possible if data and API changes were backward compatible |
| **Expand then contract** for data | Old and new code both work during the overlap | Takes at least two releases; people shortcut it, and rollback stops working |
| **Hashed static files, `index.html` not cached** | New builds are picked up; old tabs keep their old files | Keep the previous release's files for a while, or open tabs will fail to load lazy chunks |

### Step 9. Write the release workflow
**File: `.github/workflows/release.yml`**
```yaml
name: release

on:
  workflow_dispatch:
    inputs:
      canary_percent:
        description: Share of traffic for the first stage (1 to 10 for a change that is not behind a flag)
        required: true
        default: '5'

permissions:
  contents: read

concurrency:
  group: release
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false

      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version: '26.13.1'
          cache: npm

      - run: npm ci --ignore-scripts

      - name: Build
        run: npm run build

      - name: Keep the build that every later stage will use
        uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2
        with:
          name: release-build
          path: dist
          if-no-files-found: error
          retention-days: 14

  readiness:
    needs: build
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false

      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version: '26.13.1'
          cache: npm

      - run: npm ci --ignore-scripts

      - run: npm run build

      # The sample report has a failing blocker on purpose. Your pipeline would generate this file.
      - name: Evaluate the release report
        run: node dist/check-release.js data/release-candidate.json

  canary:
    needs: [build, readiness]
    runs-on: ubuntu-latest
    timeout-minutes: 30
    environment: canary
    env:
      CANARY_PERCENT: ${{ inputs.canary_percent }}
      RELEASE_SHA: ${{ github.sha }}
    steps:
      - name: Deploy to the canary stage
        run: echo "Deploy $RELEASE_SHA to $CANARY_PERCENT percent of traffic with your platform's CLI here"

      - name: Watch the stop conditions
        run: echo "Compare error rate and INP percentile with the baseline for the agreed time; fail this job to stop the release"

  production:
    needs: canary
    runs-on: ubuntu-latest
    timeout-minutes: 30
    environment: production
    env:
      RELEASE_SHA: ${{ github.sha }}
    steps:
      - name: Promote to everyone
        run: echo "Raise $RELEASE_SHA to 100 percent in steps, then keep the previous build for rollback"
```
This is an **outline**: the two deployment steps print a message because the real command depends on your platform (a CDN, a container service, a static host), and I have not invented one. Everything around them is real:
- `workflow_dispatch`: a person starts a release on purpose. Input values are passed through `env` (lesson 05) and never into the script text.
- `concurrency` with `cancel-in-progress: false`: two releases never run at once, and a running release is never cancelled halfway by a newer one.
- `needs`: build once; the readiness checker must pass before any traffic moves.
- `environment: canary` and `environment: production`: GitHub environments can require **reviewers** and restrict who may deploy, set in the repository settings, not in this file. Configure a required reviewer on `production`: that is the human gate between "canary looks fine" and "everyone gets it".
- Every action is pinned to a commit SHA (lesson 08), with the version in a comment.
- The `canary` job's second step is where **stop conditions** live. Decide them before the release: a number for error rate, a percentile for INP from your own baseline (lesson 07), a count of support tickets. Fail the job when the condition is crossed, and the release does not reach `production`.

## Run it
Run both commands once more and read the output as a reviewer would:
```text
npm run demo --silent
npm run check --silent
```
**Predict first:** if the shell loaded the `reports` remote with `timeoutMs: 5000` instead of 50, what changes for the user and what stays the same? If the `board-v2` flag is at 100 percent and someone sets `killSwitch: true`, how many users see board v2 after the next configuration refresh?

Answers: for the user, a failing remote would leave a blank region for five seconds instead of a fraction of a second before the fallback appears, so the timeout is a user-experience decision, not just a technical one; pick it from the remote's measured load time and the page's INP budget. After the kill switch, **none**: the kill switch overrides the percentage and the allow list. "After the next configuration refresh" is the part to check: a flag service with a ten-minute cache would keep serving board v2 for ten minutes, so the refresh interval is part of your incident response time.

## How it works
1. **Composition.** The shell reads a list of remotes, loads each through `loadRemote` (contract check, import, timeout, validation), mounts it with a small context and keeps the `Unmount` function.
2. **Failure containment.** Every failure is a value (`LoadResult`), so one failing remote renders a fallback in its own region and the rest of the page continues.
3. **Progressive delivery.** The flag controls who gets the new code; the readiness checker and the human list control whether it may start; the workflow controls the order; stop conditions control whether it continues.
4. **Evidence.** Each decision leaves a record: a report, a checklist with links, a workflow run, an ADR.

**Common misconception:** "Micro-frontends give independent deployments, so teams no longer need to coordinate." They remove one kind of coordination (a shared release train) and create others: the contract between shell and remotes, shared dependency versions, design consistency, routing ownership, performance budgets that span all parts. The coordination moves; it does not disappear.

**Failure modes of micro-frontends**
- **Version skew.** The shell expects contract 2 and a remote deploys contract 3. The manifest's `contract` field and the early mismatch check turn this into a visible, handled failure. Support the previous contract version for an overlap period.
- **Duplicated dependencies.** Each remote bundles its own copy of a framework: several hundred kilobytes more JavaScript and more main-thread work, which hurts your INP and size budgets (lesson 07). Share dependencies deliberately (Module Federation, import maps) or use framework-neutral parts (Web Components), and measure.
- **Style collisions and inconsistency.** Global CSS from one remote leaks into another. Use the design tokens (lesson 04) as the shared language, and isolate styles (Shadow DOM, CSS layers, or a naming convention enforced by tooling).
- **Authentication and secrets.** Passing a token to remotes through a global makes every remote part of your trusted code. Pass capabilities (a function that makes API calls), not credentials, and review remotes like dependencies.
- **Supply chain at runtime.** A remote loaded from another origin runs with your page's privileges. Pin the origin in the CSP, consider integrity metadata (an import map `integrity` section or subresource integrity for static scripts; check MDN for current browser support), and treat the remote's deploy pipeline as part of your attack surface.
- **Observability gaps.** An error in a remote must carry the remote's name and version. Without that, support cannot tell whose bug it is.
- **Routing and state.** Who owns the URL? Who owns user state? Decide it once, in the contract, not in each remote.
- **Fallbacks that nobody sees.** A fallback that silently hides a broken remote is a bug that lasts. Count fallbacks as a metric and alert on a rise.

**Failure modes of releases**
- **A rollback that does not work** because a migration dropped a column the old code needs. Rehearse rollback for each kind of change, and use expand and contract for data.
- **A canary without a decision rule.** Looking at a dashboard is not a stop condition. Write the numbers down first.
- **Flag debt.** Dozens of flags nobody dares to remove, in combinations nobody tests. Every flag has an owner and a removal date.
- **The overlap period nobody planned.** Old tabs, cached files and mobile clients run old code against your new server for days or weeks. Compatibility is a duration, not a moment.
- **Friday releases and absent people.** The cheapest reliability measure is not releasing when nobody can respond.

**When not to use this machinery:** a product with a handful of users and one developer needs a flag, a rollback step and a short checklist, not a release workflow with environments. Add structure when the cost of a bad release (users, money, trust) exceeds the cost of the process.

## Try it
This exercise is a review, the skill that matters most at this level. Copy `exercise/starter/review` and `exercise/starter/data` into your project.
1. **Guided (review first, no tools).** Read `review/PR-4217.md` as a reviewer. In `review/findings-template.md`, list everything you would raise: quote the pull request, give a severity, say who is hurt and how, propose a fix, and say whether an automated check could catch it. Set yourself a time limit of 30 minutes and list at least seven findings before you continue. Then run the checker on the machine-readable version of the same release:
```text
npm run build
node dist/check-release.js data/release-candidate-2.json
```
Compare what the checker reports with your list: which of your findings did it find, and which were invisible to it?
2. **Change.** The pull request raised a performance budget "to make CI green", and no automated check noticed. Design (do not necessarily implement) a check that would: what data does the pipeline need to provide, in which field of the report, and which severity is right? Then write the new check as an entry in `CHECKS` and extend the report type, the shape table and the sample data.
3. **Stretch (no single answer).** Write a four-line ADR: "Should the Tasks and Teams web client adopt micro-frontends?" Use the template from step 3. Name the measurement that would change your mind.

<details><summary>Solution</summary>

`exercise/solution/review/findings.md` has one possible answer with ten findings, their severity, who is affected, fixes and which automated check (if any) catches each. Do your own review before reading it. The checker's output for the second report (the command exits with code 1) is:
```text
PASS quality.tests: Type check, unit tests and end-to-end smoke tests pass
PASS quality.budgets: Performance budgets pass
PASS security.audit: No high or critical dependency findings
PASS security.secrets: Secret scan is clean
WARN security.actions-pinned: CI actions are pinned to commit SHAs
WARN security.csp-reports: No report-only CSP violations in the last 7 days
FAIL a11y.axe: No critical automated accessibility issues
FAIL a11y.keyboard: The main task works with the keyboard alone
FAIL ops.rollback-plan: A rollback plan exists
WARN ops.rollback-tested: Rollback was tested in the last 90 days
FAIL ops.dashboard: A dashboard link is attached
FAIL ops.oncall: On-call acknowledged the release
FAIL ops.canary: Unflagged changes start at 10 percent or less
FAIL docs.breaking-adr: Breaking API changes link a decision record
PASS docs.changelog: A changelog entry exists
7 blocker(s) failing, 3 warning(s). NOT ready to release 2026.12.0
```
Note what is **green**: `quality.budgets` passes because the budget was raised until it passed. The checker confirms that a check ran; it cannot judge whether the check is meaningful. For rung 2, a good design adds a field such as `budgetLimitChangePercent` filled in by a pipeline step that diffs `budgets.json` against the base branch, and a blocker check that fails when it is above zero unless a performance owner approved (a separate boolean). The point of the exercise is that reviewers look at what a check can never see.

</details>

## Check yourself
1. Why does `loadRemote` check the contract number before importing? <details><summary>Answer</summary>A remote with another contract can never work, so downloading and running it wastes time and risks side effects; failing early gives a precise reason.</details>
2. Why is a sticky bucket important for a percentage rollout? <details><summary>Answer</summary>Without it the same user would see old and new behaviour on alternating requests, and metrics for "the 5 percent group" would be meaningless.</details>
3. The readiness checker is green. Does that mean the release is safe? <details><summary>Answer</summary>No. It proves the evidence exists, not that the evidence is good (a rollback plan may not work, a budget may have been raised). People review the rest.</details>
4. Find the bug: a rollout sets `percent: 150` and the code treats anything above 100 as 100. Why does this lesson throw instead? <details><summary>Answer</summary>A value outside the range is a configuration mistake; silently clamping hides it. Failing loudly makes the mistake visible at once.</details>
5. Name two things the micro-frontend approach moves rather than removes. <details><summary>Answer</summary>Coordination (from a release train to a contract), and cost (from build time to duplicated runtime code and performance budgets). Also design consistency and ownership of routing and state.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Invalid release report:` followed by `- operations.dashboardLink must be string\|null` (shape of the message) | The JSON has a missing or wrongly typed field | Fix the file; the message names the path |
| `Release report is not valid JSON` | A trailing comma or a comment in the JSON file | JSON allows neither; remove them |
| `Usage: node dist/check-release.js <report.json>` and exit code 2 | No file argument | Pass the path as in `npm run check` |
| `rollout 50% within tolerance: false` | Your user id pattern or hash changed | Revisit the tolerance, or the hash; do not just widen the tolerance without reading why |
| The demo hangs for a long time | A `timeoutMs` far larger than 50 in the demo entry, or the `reports` importer was replaced by one that never settles and has no timeout | Keep the timeout in `options` |
| `RangeError: percent must be a whole number from 0 to 100, got ...` | A flag configuration outside the range | Fix the configuration |
| The release workflow fails at `readiness` | The sample report has a failing blocker on purpose | Replace the sample with a generated report |
| `npm.ps1 cannot be loaded` | PowerShell execution policy | Use `npm.cmd` |

## Best practice
Make releases boring: small, reversible, observable, and decided against numbers fixed in advance. Source: web.dev, [Performance budgets](https://web.dev/articles/performance-budgets-101) and [Optimize long tasks](https://web.dev/articles/optimize-long-tasks) for the stop conditions; GitHub Docs, [Managing environments for deployment](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment); OWASP, [Content Security Policy Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html) for the CSP part of the review.

## Production checklist
The full list is `PRODUCTION-READINESS.md` (step 8). The five questions to ask when you have only five minutes:
- [ ] If this fails at 17:00 on Friday, who is told, and what do they do first?
- [ ] How do I turn it off without a deployment?
- [ ] What numbers make me stop, and where can I see them?
- [ ] Which users or clients still run the old version, and does it still work?
- [ ] What did we change about this release process because of the last incident?

## Going further
- Capstone link: the two web capstones are single applications ([capstones/web-angular](../../../../capstones/web-angular/README.md), [capstones/web-react](../../../../capstones/web-react/README.md)). As a design exercise, draw the line that would split "Teams" and "Tasks" into two remotes and write the contract between them; then say which of the failure modes above you would meet first.
- MDN: [import maps](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/script/type/importmap) and [custom elements](https://developer.mozilla.org/en-US/docs/Web/API/Web_components/Using_custom_elements).
- Practice capstones ([capstones/_practice](../../../../capstones/_practice/README.md)): pick one and write its production readiness review before you write its first line of code.

## Summary
- You compared integration approaches for micro-frontends and wrote a decision record that says when not to use them.
- You built a loader with a contract check, a timeout and typed failures, and rehearsed five scenarios.
- You built a sticky, monotonic, kill-switch-capable rollout, and a readiness checker with blockers and warnings.
- You reviewed a flawed release as a person, and saw what automated checks can and cannot see.

## Next lesson
This is the last lesson of the Web Foundations 301 level. Continue with the capstones, and use `PRODUCTION-READINESS.md` for the next release you review.
