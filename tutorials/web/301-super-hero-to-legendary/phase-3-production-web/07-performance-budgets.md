---
track: web
level: 301
phase: 3
phase_name: production-web
lesson: 07
title: "Performance budgets and browser internals"
time: 150 min
prerequisites: [web-201.06, web-201.11, web-301.05]
versions: { node: "26.13.1", npm: "11.20.0", typescript: "7.0.2", vite: "8.3.8", "web-vitals": "6.2.3", lighthouse: "13.6.0 (run with npx, not installed)" }
verified: not yet run
source: source/web/301-super-hero-to-legendary/phase-3-production-web/07-performance-budgets/
assets: []
---

# 07. Performance budgets and browser internals

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- explain how the browser turns bytes into pixels (parse, style, layout, paint, composite) and which of those steps run on the main thread
- reproduce a long task, see it in the DevTools Performance panel, and fix it by yielding, then explain what that does to Interaction to Next Paint (INP)
- set a size budget that fails CI, and a timing budget that is measured the right way (lab for regressions, field for truth)
- write a measurement plan that records numbers you took yourself, never numbers from this lesson

## Recap
1. In Web 201 you used Vite and a performance audit. What is the difference between a **lab** measurement and a **field** measurement?
   <details><summary>Answer</summary>Lab: a controlled run on one machine and network (Lighthouse). Field: real visitors' devices and networks, collected from the browser (real user monitoring, the Chrome User Experience Report). Lab is repeatable; field is true.</details>
2. What does `defer` do to a classic script?
   <details><summary>Answer</summary>It downloads in parallel with HTML parsing and runs after parsing finishes, in order. Module scripts are deferred by default.</details>
3. In lesson 05 a CI job failed on a type error. How is a size budget similar?
   <details><summary>Answer</summary>Both are checks that turn a quality rule into a failing build, so a regression cannot merge unnoticed.</details>

## Why it matters
Users do not feel your architecture; they feel waiting: a page that appears late, a button that does nothing for half a second, a layout that jumps. These are measurable, and they regress silently: every dependency, every feature, every analytics tag adds a little. A **performance budget** is a limit agreed in advance (bytes of JavaScript, seconds to the main image, milliseconds of blocked input) and enforced by the build, so the conversation happens in a pull request and not after the support tickets arrive.

## What you will build
A small Vite and TypeScript page that lets you **feel** the difference between a long task and a yielding one, plus the measurement and enforcement around it:
- two buttons that do the same work, one as a single long task and one in short slices;
- a long-animation-frame observer and the `web-vitals` library, loaded after the page is interactive in a separate chunk;
- `scripts/check-budget.mjs`, a size budget checked on the gzip size of the build;
- a Lighthouse budget file and a CI workflow.

Nothing in this lesson claims how fast your page is. You will take the measurements yourself and write them down.

## Before you start
- Lessons 01 to 06 finished (Node 26.13.1, npm 11.20.0, TypeScript 7.0.2). Chrome or Edge (for DevTools and Lighthouse).
- Builds on Web 201 lesson [11 Performance and Core Web Vitals](../../201-hero-to-super-hero/phase-4-quality-and-ship/11-performance-and-core-web-vitals.md) (measuring LCP, INP and CLS, Lighthouse, code splitting) and [06 Modules, Vite and the dev workflow](../../201-hero-to-super-hero/phase-2-typescript-in-depth/06-modules-vite-and-dev-workflow.md). This lesson goes inside the browser (why a long task blocks input) and turns measurements into budgets that fail a build.
- Time: 120 to 150 minutes. Break after step 7.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/301-super-hero-to-legendary/phase-3-production-web/07-performance-budgets/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- No `package-lock.json` is shipped; `npm install` creates it. Lighthouse is **not** installed in the project: you run a pinned version with `npx` when you need it.
- This lesson is browser-based. Where I describe how the page should look or behave I am describing it from the code, not from having seen it: check it yourself.

## Steps

### Step 1. Create the project
```text
mkdir perf-lab
cd perf-lab
mkdir src
mkdir scripts
```
Expected result: a folder `perf-lab` with `src` and `scripts` inside.

### Step 2. Write package.json, tsconfig.json and the Vite config
**File: `package.json`**
```json
{
  "name": "web301-07-performance-budgets",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "typecheck": "tsc --noEmit",
    "build": "tsc --noEmit && vite build",
    "preview": "vite preview",
    "budget": "node scripts/check-budget.mjs"
  },
  "engines": {
    "node": ">=26.13.1",
    "npm": ">=11.20.0"
  },
  "dependencies": {
    "web-vitals": "6.2.3"
  },
  "devDependencies": {
    "typescript": "7.0.2",
    "vite": "8.3.8"
  }
}
```
Vite builds the app; TypeScript 7 only **type-checks** it (`tsc --noEmit`), which works because Vite does not need the TypeScript compiler API (lesson 06 explains why some tools do). `web-vitals` is a runtime dependency, because it ships to browsers.

**File: `tsconfig.json`**
```json
{
  "compilerOptions": {
    "target": "ES2023",
    "lib": ["ES2023", "DOM", "DOM.Iterable"],
    "module": "esnext",
    "moduleResolution": "bundler",
    "types": ["vite/client"],
    "noEmit": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "skipLibCheck": true
  },
  "include": ["src", "vite.config.ts"]
}
```
Different from the Node lessons: `module: esnext` with `moduleResolution: bundler` because a bundler resolves imports (no `.js` extensions needed), `DOM` libraries because this code runs in a browser, and `types: ["vite/client"]` for Vite's own globals.

**File: `vite.config.ts`**
```ts
import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    sourcemap: true,
    reportCompressedSize: true,
  },
});
```
`sourcemap: true` writes `.map` files so DevTools can show your TypeScript in profiles; visitors never download them unless they open DevTools. `reportCompressedSize` makes the build print gzip sizes.

Install:
```text
npm install --no-audit --no-fund
```

### Step 3. Write the page
**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Performance lab</title>
  <link rel="stylesheet" href="/src/style.css">
</head>
<body>
  <main>
    <h1>Performance lab</h1>
    <p>Type in the box while a job runs. Notice whether the characters appear at once.</p>
    <label for="typing">Type here</label>
    <input id="typing" type="text" autocomplete="off">
    <p>
      <button id="run-blocking" type="button">Run 20,000 rows (blocking)</button>
      <button id="run-yielding" type="button">Run 20,000 rows (yielding)</button>
    </p>
    <p id="status" role="status">Idle</p>
  </main>
  <script type="module" src="/src/main.ts"></script>
</body>
</html>
```
Points about the critical path, line by line:
- The stylesheet is `<link rel="stylesheet">` in `<head>`: it is **render-blocking**. The browser will not paint until it has downloaded and parsed it, which is correct (painting unstyled content then restyling is worse), so keep critical CSS small.
- The script is `type="module"` at the end of `<body>`. Modules are deferred: they download in parallel and run after the HTML is parsed, so they do not block the first paint. A classic `<script src>` without `defer` in the head would block the parser.
- The `<label for>` and the `role="status"` paragraph are not decoration: the label names the input for screen readers, and `role="status"` is a polite live region, so the result is announced without stealing focus.
- `lang`, `charset` and `viewport` are in the first bytes: the browser needs them before it lays anything out.

**File: `src/style.css`**
```css
body {
  font-family: system-ui, sans-serif;
  margin: 2rem;
}

main {
  max-width: 40rem;
}

input {
  display: block;
  box-sizing: border-box;
  width: 100%;
  margin-block: 0.5rem 1rem;
  padding: 0.5rem;
}

button {
  padding: 0.5rem 1rem;
}
```
`system-ui` uses the visitor's own font: no font download, no layout shift from a late font. A web font is a cost you pay on purpose (see the checklist).

### Step 4. Write the work, the yield helper and the observers
**File: `src/yield.ts`**
```ts
type SchedulerLike = { yield?: () => Promise<void> };

// scheduler.yield() resumes your code at the front of the task queue; setTimeout is the fallback.
export function yieldToMain(): Promise<void> {
  const scheduler = (globalThis as unknown as { scheduler?: SchedulerLike }).scheduler;
  if (typeof scheduler?.yield === 'function') {
    return scheduler.yield();
  }
  return new Promise((resolve) => setTimeout(resolve, 0));
}
```
Yielding means "give the browser a chance to do other work, then continue me". `scheduler.yield()` (where supported) puts the continuation at the front of the queue, so other work does not starve your task. The fallback `setTimeout(…, 0)` puts it at the back, which is slower to resume but works everywhere. The feature is checked at runtime because browser support differs: check MDN's compatibility table for `Scheduler.yield()` for your support matrix.

**File: `src/work.ts`**
```ts
import { yieldToMain } from './yield';

export const ROWS = 20_000;
const STEPS_PER_ROW = 2_000;
const MODULUS = 1_000_003;

// Deterministic CPU work standing in for "parse, filter and sort a big response".
function rowCost(index: number): number {
  let value = index;
  for (let step = 0; step < STEPS_PER_ROW; step += 1) {
    value = (value * 31 + step) % MODULUS;
  }
  return value;
}

// One long task: the page cannot respond to input, or paint, until the loop ends.
export function processBlocking(rows: number): number {
  let checksum = 0;
  for (let index = 0; index < rows; index += 1) {
    checksum = (checksum + rowCost(index)) % MODULUS;
  }
  return checksum;
}

// Same result, many short tasks: between chunks the browser can handle input and paint.
export async function processYielding(rows: number, chunk = 500): Promise<number> {
  let checksum = 0;
  for (let index = 0; index < rows; index += 1) {
    checksum = (checksum + rowCost(index)) % MODULUS;
    if ((index + 1) % chunk === 0) {
      await yieldToMain();
    }
  }
  return checksum;
}
```
Both functions return the same checksum for the same input: that is your correctness check, and it is the first rule of performance work: **a faster result that is wrong is not an optimisation**. `STEPS_PER_ROW` sets how heavy the work is. If the blocking run is too quick on your machine to notice (under about 100 milliseconds in the Performance panel), raise it; if it freezes the tab for many seconds, lower it. Write down the value you settled on.

**File: `src/long-tasks.ts`**
```ts
// Long tasks (older API) and long animation frames (newer, more detail) tell you the main thread was busy.
export interface LongFrameReport {
  startTime: number;
  duration: number;
}

export function observeLongFrames(report: (entry: LongFrameReport) => void): () => void {
  const supported = PerformanceObserver.supportedEntryTypes;
  const type = supported.includes('long-animation-frame') ? 'long-animation-frame' : 'longtask';
  if (!supported.includes(type)) {
    return () => {};
  }
  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      report({ startTime: entry.startTime, duration: entry.duration });
    }
  });
  observer.observe({ type, buffered: true });
  return () => observer.disconnect();
}
```
A **long task** is any task on the main thread that runs for more than 50 milliseconds. A **long animation frame** (LoAF) is a frame that takes more than 50 milliseconds to render, and its entries can say which scripts were responsible (the extra fields are not used here). The code asks the browser which entry types it supports, because neither is available in every browser, and returns a function that stops observing.

**File: `src/vitals.ts`**
```ts
import { onCLS, onINP, onLCP, type Metric } from 'web-vitals';

export interface VitalReport {
  name: string;
  value: number;
  rating: string;
}

// Real-user measurement: the numbers come from your visitors' browsers, not from your laptop.
export function reportVitals(send: (report: VitalReport) => void): void {
  const forward = (metric: Metric): void => {
    send({ name: metric.name, value: metric.value, rating: metric.rating });
  };
  onCLS(forward);
  onINP(forward);
  onLCP(forward);
}
```
The three Core Web Vitals: **LCP** (Largest Contentful Paint: when the main content appears), **INP** (Interaction to Next Paint: how long the page takes to show a response after a click, tap or key press, worst interaction roughly) and **CLS** (Cumulative Layout Shift: how much visible content jumps). Each metric object has a `rating` (`good`, `needs-improvement` or `poor`) computed against published thresholds, so you can chart the share of good visits. In production, `send` posts the report to your own endpoint with `navigator.sendBeacon`; here it will print to the console.

### Step 5. Write the entry script
**File: `src/main.ts`**
```ts
import { observeLongFrames } from './long-tasks';
import { processBlocking, processYielding, ROWS } from './work';

const status = document.querySelector<HTMLElement>('#status');
const blocking = document.querySelector<HTMLButtonElement>('#run-blocking');
const yielding = document.querySelector<HTMLButtonElement>('#run-yielding');

if (!status || !blocking || !yielding) {
  throw new Error('index.html is missing an element this script needs');
}

let running = false;

blocking.addEventListener('click', () => {
  if (running) {
    return;
  }
  // This text will not appear before the loop finishes: the browser cannot paint while the loop runs.
  status.textContent = 'Working...';
  const checksum = processBlocking(ROWS);
  status.textContent = `Blocking run done: ${ROWS} rows, checksum ${checksum}`;
});

async function runYielding(): Promise<void> {
  if (running || !status) {
    return;
  }
  running = true;
  status.textContent = 'Working...';
  const checksum = await processYielding(ROWS);
  status.textContent = `Yielding run done: ${ROWS} rows, checksum ${checksum}`;
  running = false;
}

yielding.addEventListener('click', () => {
  void runYielding();
});

observeLongFrames((entry) => {
  console.log(`[long frame] started ${Math.round(entry.startTime)} ms, lasted ${Math.round(entry.duration)} ms`);
});

// Load the measurement code after the page is interactive, in its own chunk.
function startVitals(): void {
  void import('./vitals').then(({ reportVitals }) => {
    reportVitals((report) => console.log('[vitals]', JSON.stringify(report)));
  });
}

addEventListener('load', () => {
  if ('requestIdleCallback' in window) {
    requestIdleCallback(startVitals);
  } else {
    setTimeout(startVitals, 200);
  }
});
```
What to notice:
- The blocking handler sets `Working...` and immediately runs the loop. **The text will never be seen before the work ends**: setting `textContent` only changes the DOM; the browser paints at the next rendering opportunity, which cannot happen while your loop holds the main thread. The yielding version gives the browser those opportunities.
- `await processYielding(...)` returns control to the browser between chunks; the `running` flag stops a second click from starting a second job while one is in progress. It is a simple guard; the button is deliberately **not** disabled, because disabling the focused button drops keyboard focus.
- `import('./vitals')` is a **dynamic import**: the bundler puts `web-vitals` in its own file, downloaded only after the page's `load` event and during idle time. The measurement code must never be the thing that slows the page it measures.

### Step 6. Build and run
```text
npm run build
npm run preview
```
Expected result of the build: no type errors, then Vite prints a list of the files it wrote in `dist` (an HTML file, a CSS file, and a few JavaScript chunks, with their sizes). The names contain hashes and the sizes are yours to read: write them down. `npm run preview` serves `dist` and prints the address it chose (by default `http://localhost:4173/`). Open that address.

What the page should look like, from the code: a heading, one paragraph, a labelled text box that fills the width, two buttons side by side and a line that says `Idle`. I describe this from the CSS; confirm it.

### Step 7. Feel the long task (and measure it)
1. Click **Run 20,000 rows (blocking)** and, while it is running, try to type in the box. If the work is heavy enough on your machine, the page should seem frozen: no new characters, no `Working...` text, then everything appears at once with the result. Click **Run 20,000 rows (yielding)** and type again. Characters should appear while the job runs, and `Working...` should show.
2. The same checksum must appear for both runs. If it does not, stop: your fix changed behaviour.
3. Record a profile. Open DevTools (F12; macOS: Command+Option+I) and the **Performance** panel. Press the record button (or Ctrl+E), click the blocking button, wait for the result, stop recording. In the flame chart, the main thread track shows one wide task; long tasks are marked with a red triangle in the corner. Hover it: the duration is the thing you are looking for. Record a second profile for the yielding button: the single wide block should be replaced by many short ones with gaps between them.
4. In the same panel, the **Interactions** track shows each click or key press with three parts: *input delay* (waiting for the main thread to be free), *processing time* (your event handlers) and *presentation delay* (until the next paint). INP is built from these three. The blocking run should show a very long processing time on the click; typing during the job shows long input delay for each keypress.
5. Open the Console. You should see `[long frame] ...` lines if your browser supports the long-animation-frame or long-task entries, and, after the page is idle, `[vitals] ...` lines as the metrics become available (CLS and INP report when you leave or hide the tab, or at the end of an interaction).

Fill in this table in your notes (the lesson cannot give you the numbers):

| Measure | Blocking | Yielding |
|---|---|---|
| Longest task in the Performance panel (ms) | | |
| Time from click to result text visible (ms) | | |
| Could you type while it ran? (yes/no) | | |
| Worst interaction duration shown in the Interactions track (ms) | | |
| Chrome version, device, CPU throttling setting | | |

Use **CPU throttling** (the gear in the Performance panel, "CPU: 4x slowdown") to approximate a slower phone, and record that you used it. Your laptop is the fastest device your visitors do not own.

### Step 8. Write the size budget check
**File: `budgets.json`**
```json
{
  "gzipBytes": {
    "js": 25000,
    "css": 3000
  }
}
```
These two numbers are **illustrative starting limits**, not recommendations. The correct procedure: build, read your own current gzip sizes from the check below, then set each limit a little above today's value (for example 10 percent headroom) and **ratchet it down** as you improve. A budget far above your baseline never fails and teaches nothing; a budget far below it is ignored.

**File: `scripts/check-budget.mjs`**
```js
import { readdirSync, readFileSync } from 'node:fs';
import { extname, join } from 'node:path';
import { gzipSync } from 'node:zlib';

const limits = JSON.parse(readFileSync(new URL('../budgets.json', import.meta.url), 'utf8')).gzipBytes;
const assets = 'dist/assets';
const totals = { js: 0, css: 0 };

for (const name of readdirSync(assets)) {
  const kind = { '.js': 'js', '.css': 'css' }[extname(name)];
  if (kind === undefined) {
    continue; // source maps and other files are not downloaded by visitors
  }
  const size = gzipSync(readFileSync(join(assets, name)), { level: 9 }).length;
  totals[kind] += size;
  console.log(`${name}: ${size} bytes gzip`);
}

const exceeded = Object.keys(totals).filter((kind) => totals[kind] > limits[kind]);
for (const kind of Object.keys(totals)) {
  console.log(`${kind}: ${totals[kind]} / ${limits[kind]} bytes`);
}

if (exceeded.length > 0) {
  console.error(`Budget exceeded: ${exceeded.join(', ')}`);
  process.exitCode = 1;
} else {
  console.log('Budget OK');
}
```
How it works: it walks `dist/assets`, gzip-compresses each JavaScript and CSS file (the way a server typically sends them; use brotli if your host does) and adds the sizes per kind. Then it compares totals against the limits and sets a failing exit code. Run it:
```text
npm run budget
```
Expected output: one line per JavaScript or CSS file, with hashed names that differ per build, then two total lines and a last line. The shape is:
```text
<file name>: <number> bytes gzip
js: <number> / 25000 bytes
css: <number> / 3000 bytes
Budget OK
```
The numbers are yours to read: write them in your notes as the **baseline**. To see the check fail, lower `"js"` in `budgets.json` below your baseline, run `npm run budget` again and read `Budget exceeded: js`, then restore it.

**File: `lighthouse-budget.json`**
```json
[
  {
    "path": "/*",
    "resourceSizes": [
      { "resourceType": "script", "budget": 25 },
      { "resourceType": "stylesheet", "budget": 3 },
      { "resourceType": "total", "budget": 60 }
    ],
    "timings": [
      { "metric": "largest-contentful-paint", "budget": 2500 },
      { "metric": "total-blocking-time", "budget": 200 },
      { "metric": "cumulative-layout-shift", "budget": 0.1 }
    ]
  }
]
```
This is the budget format that Lighthouse reads. `resourceSizes` are in **kilobytes**; `timings` are in milliseconds (the layout shift value has no unit). The timing values here are the "good" thresholds Google publishes for LCP (2.5 seconds), Total Blocking Time (200 milliseconds, the lab stand-in for INP) and CLS (0.1), used as starting points; the size limits are placeholders to replace with your baseline.

Run Lighthouse against the preview server (Chrome must be installed; `npx` downloads the pinned version the first time):
```text
npx lighthouse@13.6.0 http://localhost:4173/ --budget-path=lighthouse-budget.json --view
```
The report opens in the browser. Look for the **Budgets** section and the performance score; Lighthouse varies from run to run, so run it three times and keep the median.

### Step 9. Write the CI workflow
**File: `.github/workflows/performance.yml`**
```yaml
name: performance

on:
  pull_request:

permissions:
  contents: read

jobs:
  budget:
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

      - name: Build
        run: npm run build

      - name: Check size budgets (hard limit)
        run: npm run budget

      - name: Keep the build for inspection
        if: failure()
        uses: actions/upload-artifact@v7
        with:
          name: dist-over-budget
          path: dist
          retention-days: 3
```
Only **size** budgets fail the build. Size is deterministic: the same code gives the same bytes on every machine. Timing budgets (LCP, TBT) vary with the runner's load, so in CI they should be *recorded* (and alerted on trends or compared as a median of several runs), not used as a hard gate on a single run, or the build becomes flaky and people stop trusting it. The `if: failure()` step keeps the over-budget build so a reviewer can look inside.

## Run it
**Predict first:**
1. Which button produces the `[long frame]` console line, and roughly how long is it compared with the work?
2. If you move `import('./vitals')` into a normal top-level `import`, what changes in the build output and in the budget check?
3. Does the yielding run finish sooner or later than the blocking run? Why might that be acceptable?

Answers: (1) the blocking button: one long frame, about as long as the whole job (read the number); the yielding run produces many short frames, most below the 50 millisecond threshold. (2) `web-vitals` moves into the main JavaScript file: one fewer chunk, a larger entry file, a larger `js` total for the first load. The size budget counts all chunks, so the total stays about the same; a per-entry budget would show the difference, which is why you should budget the *initial* load separately. (3) Usually later, because every yield adds overhead and gives other work a turn. It is acceptable (and usually right) because the page stayed responsive; a faster-but-frozen page scores worse on INP.

## How it works
1. **Pipeline.** The browser parses HTML into the **DOM** and CSS into the **CSSOM**; combines them into styled boxes (**style**); computes sizes and positions (**layout**); draws pixels into layers (**paint**); and composes the layers on the GPU (**composite**). Changing a property that affects layout (width, top, font-size) triggers layout, paint and composite; one that affects only paint (colour) skips layout; `transform` and `opacity` can often be handled at the composite step, off the main thread. Animate those.
2. **Main thread.** JavaScript, style, layout, paint preparation and event handlers share **one** thread. While a task runs, nothing else on that thread can: not a click handler, not a paint. That is why a long task makes the page feel frozen.
3. **Critical path.** The first paint needs HTML, then render-blocking CSS, then (for scripts without `defer`, `async` or `type="module"`) any script that appears before it. Shorten the chain: fewer bytes, fewer round trips, nothing blocking that does not need to.
4. **INP** is the longest interaction latency (input delay plus processing plus presentation delay, ignoring a few outliers on busy pages) a visitor experienced on a page. Fix the biggest of the three parts first: long tasks cause input delay; slow handlers cause processing time; heavy rendering after the handler causes presentation delay.

**Common misconception:** "`async`/`await` makes code non-blocking." It does not. An `async` function runs synchronously until its first `await` that actually yields to the event loop. A loop that does CPU work with `await` on an already-resolved value never gives the browser a turn. Only real yielding does (`scheduler.yield()`, `setTimeout`, waiting for I/O, or moving work to a Web Worker).

**Why this, not that (ADR style)**

| Decision | Chosen | Alternative | Why / when to switch |
|---|---|---|---|
| Fix for the long task | Yield in slices | Move the work to a Web Worker | Yielding is a two-line change and keeps access to the DOM. A Worker removes the work from the main thread entirely, which is better for heavy, DOM-free computation, but needs message passing and copying of data; switch when slices are still long or the work is large |
| Slice policy | Fixed chunk of rows (in the lesson); time-sliced (exercise) | Always chunk by count | A count assumes every row costs the same; a time budget adapts to slow devices. The exercise implements it |
| Size budget in CI | Hard fail on gzip bytes | Report only | Bytes are deterministic and the most common regression cause (a new dependency). Hard fail with a visible escape hatch (a reviewed edit of `budgets.json`) |
| Timing budget | Lab check in a scheduled job, field monitoring for the truth | Hard fail on Lighthouse score in every pull request | Lab timings vary; a flaky gate is turned off. Use lab to find regressions, field to know whether they matter |
| Measurement library | `web-vitals`, loaded late | Hand-rolled `PerformanceObserver` | The library matches how Chrome computes the metrics, including edge cases; your own observer is for diagnostics |
| Where numbers come from | Measured on target devices | This lesson's examples | There are no numbers here on purpose: yours differ by device, network and day |

**Failure modes**
- **A budget with invented numbers.** A limit not derived from a baseline is either never hit or always ignored. Measure first.
- **Lab green, field red.** Lighthouse runs on a fast machine with an empty cache; real visitors have slow phones and busy main threads. Compare the lab INP proxy (TBT) with field INP before you trust either.
- **Averages hide the tail.** Report percentiles. The Core Web Vitals assessment uses the **75th percentile** of page loads. One slow device class can hide behind a good average.
- **Yielding that never yields.** A `for` loop with `await Promise.resolve()` does not give the browser a turn (the misconception above). Test by recording a profile, not by reading the code.
- **Measurement that costs.** A synchronous analytics tag, a large RUM library or an observer that logs every frame can create the long tasks it reports. Load measurement late and keep it small, as in step 5.
- **Third-party scripts.** Tag managers, chat widgets and A/B testing add the most unexplained main-thread time. Budget them like your own code, load them after the page is interactive, and review them on a schedule.
- **Layout shift from late content.** Images and embeds without `width` and `height` (or CSS `aspect-ratio`), late-injected banners and font swaps move content under the user's finger. Reserve space.
- **Caching hides regressions in tests.** Always measure cold (empty cache) and warm separately.
- **Over-optimising a non-bottleneck.** Profile first. A 5-millisecond win on a 600-millisecond task is noise.

**When not to chase budgets**
- An internal tool used by ten people on fast machines: set a loose size budget to catch accidents and spend your time elsewhere.
- A page whose cost is dominated by content you do not control (a customer's embed). Budget what you own and document the rest.
- Before you have a baseline. Measure for a week, then set limits.

## Try it
Copy your project to `perf-lab-try`. The starter is in `exercise/starter`.
1. **Guided.** Copy the three starter files over your own (`index.html`, `src/main.ts`, `src/work.ts`): they add a third button, **time-sliced**, whose function `processByTime` is a placeholder that never yields. Implement it so it yields when the current slice has used `sliceMs` milliseconds (use `performance.now()`), then record a profile and compare it with the fixed-chunk version. The checksum must still match.
2. **Change.** Add a `css` and a `js` **per-file** limit to `scripts/check-budget.mjs` so one oversized chunk fails even when the total is fine. Which chunk would you most want to catch, and what does it cost the budget file's readability?
3. **Stretch (no single answer).** Design the budget policy for a product with three page types (marketing, app shell, report). Which limits are shared, which differ, and who may raise a limit and how? Write it as a four-line ADR.

<details><summary>Solution</summary>

The solution differs from the starter only in `processByTime`:

**File: `exercise/solution/src/work.ts`** (the new function; the rest of the file is unchanged)
```ts
// Yield when the current slice has used its time budget, not after a fixed number of rows.
export async function processByTime(rows: number, sliceMs = 8): Promise<number> {
  let checksum = 0;
  let sliceStart = performance.now();
  for (let index = 0; index < rows; index += 1) {
    checksum = (checksum + rowCost(index)) % MODULUS;
    if (performance.now() - sliceStart >= sliceMs) {
      await yieldToMain();
      sliceStart = performance.now();
    }
  }
  return checksum;
}
```
The loop checks the clock after each row, which costs a little; calling `performance.now()` every row is fine here because a row is expensive, but for very cheap rows you would check every N rows. The slice length (8 ms) is chosen to leave room inside a 16-millisecond frame (60 frames per second) for the browser's own work; tune it by recording profiles. The three files in `exercise/solution` (`index.html`, `src/main.ts`, `src/work.ts`) match the starter except for this function.

</details>

## Check yourself
1. Why can the browser not show `Working...` before the blocking loop ends? <details><summary>Answer</summary>Painting happens on the main thread, which the loop is holding. The DOM was updated but nothing can be drawn until the task ends.</details>
2. A page has a good LCP and a poor INP. Which kind of problem is it likely to be? <details><summary>Answer</summary>Main-thread work after load: long tasks, slow event handlers or expensive rendering after interactions, not slow loading.</details>
3. Why does the CI job hard-fail on bytes but only record timings? <details><summary>Answer</summary>Bytes are deterministic; timings vary between runs and runners, so a hard gate on them is flaky.</details>
4. Find the bug: `for (...) { work(); await Promise.resolve(); }`. Does this make the page responsive? <details><summary>Answer</summary>No. A resolved promise continues in a microtask, before the browser can handle input or paint. Yield with <code>scheduler.yield()</code> or a task (<code>setTimeout</code>).</details>
5. Which of LCP, INP and CLS would a late-loading banner that pushes the article down hurt? <details><summary>Answer</summary>CLS (layout shift); it can also affect LCP if it delays the largest element.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Cannot find module 'vite/client'` or types for `import.meta` missing (typical) | `types` does not list `vite/client`, or Vite is not installed | Install dependencies; keep `"types": ["vite/client"]` |
| `ENOENT: no such file or directory, scandir 'dist/assets'` | You ran the budget before building | Run `npm run build` first |
| `Budget exceeded: js` | The bundle grew past the limit | Find what grew (build output, bundle analysis); raise the limit only in a reviewed change |
| No `[long frame]` lines in the console | The browser does not support the entry types, or the work was under 50 ms | Raise `STEPS_PER_ROW` or try Chrome or Edge |
| Typing is smooth during the blocking run | The machine is fast; the task is too short to notice | Raise `STEPS_PER_ROW` or use CPU throttling in the Performance panel |
| Lighthouse says it cannot connect or find Chrome | The preview server is not running, or Chrome is not installed | Start `npm run preview` in another terminal; install Chrome |
| `npm.ps1 cannot be loaded` | PowerShell execution policy | Use `npm.cmd` and `npx.cmd` |

## Best practice
Write the budget down before the regression: measure a baseline, set a limit, enforce size in CI, watch the field. Source: web.dev, [Interaction to Next Paint](https://web.dev/articles/inp), [Optimize long tasks](https://web.dev/articles/optimize-long-tasks), and [Performance budgets 101](https://web.dev/articles/performance-budgets-101).

## Production checklist
- [ ] A baseline for LCP, INP and CLS **from field data** (or a documented plan to get it), by device class.
- [ ] Size budgets for initial JavaScript, CSS, images and total, enforced in CI on gzip or brotli bytes.
- [ ] Timing budgets recorded from lab runs (median of several), alerting on trends.
- [ ] No task on the main thread longer than 50 ms in the interactions that matter; long work yields or moves to a Worker.
- [ ] Critical CSS is small; scripts are `defer` or modules; fonts have a fallback and `font-display`; images have dimensions.
- [ ] Third-party scripts are listed, loaded after interactivity and reviewed.
- [ ] Measurement code is small, late and tested for its own cost.
- [ ] Measurements record device, network, throttling and cache state; your own numbers, not borrowed ones.
- [ ] Performance regressions block merge (size) or open an issue automatically (timing).

## Going further
- web.dev: [Understanding the critical path](https://web.dev/learn/performance/understanding-the-critical-path), [Use Lighthouse for performance budgets](https://web.dev/articles/use-lighthouse-for-performance-budgets), [Web Vitals](https://web.dev/articles/vitals).
- MDN: [Critical rendering path](https://developer.mozilla.org/en-US/docs/Web/Performance/Guides/Critical_rendering_path) and the `PerformanceObserver` reference.
- Capstone link: take the production build of either web capstone ([capstones/web-react](../../../../capstones/web-react/README.md), [capstones/web-angular](../../../../capstones/web-angular/README.md)), record the table from step 7 for its slowest screen, and set a size budget from its baseline.

## Summary
- You described the rendering pipeline and which steps share the main thread.
- You reproduced a long task, fixed it by yielding and compared the profiles yourself.
- You wrote a size budget that fails the build and a Lighthouse budget with documented thresholds.
- You separated lab from field measurement and listed the failure modes of each.

## Next lesson
08. Security hardening: CSP in depth, Trusted Types, dependency risk and where to keep tokens.
