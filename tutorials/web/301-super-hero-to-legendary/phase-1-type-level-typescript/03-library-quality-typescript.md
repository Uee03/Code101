---
track: web
level: 301
phase: 1
phase_name: type-level-typescript
lesson: 03
title: "Library-quality TypeScript: declaration files, strictness flags, API design"
time: 150 min
prerequisites: [web-301.01, web-301.02, web-201.06]
versions: { node: "26.13.1", npm: "11.20.0", typescript: "7.0.2", "@arethetypeswrong/cli": "0.18.5" }
verified: not yet run
source: source/web/301-super-hero-to-legendary/phase-1-type-level-typescript/03-library-quality-typescript/
assets: []
---

# 03. Library-quality TypeScript: declaration files, strictness flags, API design

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- package a TypeScript library with an `exports` map, generated `.d.ts` files and `isolatedDeclarations`
- choose strictness flags on purpose and explain what each one costs your consumers
- test a library the way a consumer sees it: compile a consumer file against the built package, with a strict and a loose configuration
- review an API change and say whether it is a breaking change for types

## Recap
1. Why must a relative import end in `.js` under `moduleResolution: nodenext` (lesson 02)?
   <details><summary>Answer</summary>Node resolves the emitted file, and TypeScript refuses to guess the extension for you.</details>
2. What does `// @ts-expect-error` give you that `// @ts-ignore` does not (lesson 01)?
   <details><summary>Answer</summary>It fails when the line stops producing an error, so a negative test cannot silently rot.</details>
3. Where did lesson 01 say a cast is acceptable?
   <details><summary>Answer</summary>Inside one small, commented boundary where an invariant the compiler cannot see is enforced elsewhere; never in a public signature.</details>

## Why it matters
An application can change its types every day because it owns all its callers. A library cannot: its types are a contract with code you will never see. Three things go wrong again and again: the published package resolves differently in Node, a bundler and the editor; the `.d.ts` files need a compiler option your consumer does not use; and a harmless-looking change (a narrower parameter type) breaks every caller. This lesson builds a tiny library, `@code101/result-kit`, and a safety net around it.

## What you will build
A library with a `Result` type (success or failure without exceptions), a `parseJson` function and a `ParseError`; a **consumer test** that compiles against the built package under two configurations; an **API surface snapshot** that fails when the exported names change; and a package check with *Are the types wrong?* (`attw`). Since you meet the library through its public entry point only, the lesson also shows what is *not* exported.

## Before you start
- Lessons 01 and 02 finished (Node 26.13.1, npm 11.20.0, TypeScript 7.0.2).
- Builds on Web 201 lesson [06 Modules, Vite and the dev workflow](../../201-hero-to-super-hero/phase-2-typescript-in-depth/06-modules-vite-and-dev-workflow.md) (modules, `tsconfig.json`, building a project).
- Time: 120 to 150 minutes. Break after step 7.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/301-super-hero-to-legendary/phase-1-type-level-typescript/03-library-quality-typescript/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- No `package-lock.json` is shipped; `npm install` creates it.
- Version note: TypeScript 7.0 ships **no programmatic API** (a stable one is expected later). Tools that import `typescript` as a library (for example linters that need type information, and API documentation generators) may need the side-by-side TypeScript 6 compatibility package described in the TypeScript 7.0 announcement. This lesson uses only the `tsc` command line, so it is unaffected; check the tool you adopt.

## Steps

### Step 1. Create the project
```text
mkdir result-kit
cd result-kit
mkdir src
mkdir consumer
mkdir scripts
```
Expected result: a folder `result-kit` with three empty folders: `src` (the library), `consumer` (a pretend user of the library) and `scripts` (checks that run Node on the built output).

### Step 2. Write package.json
**File: `package.json`**
```json
{
  "name": "@code101/result-kit",
  "version": "0.1.0",
  "description": "A tiny Result type, used to teach TypeScript library packaging.",
  "private": true,
  "license": "UNLICENSED",
  "type": "module",
  "sideEffects": false,
  "files": [
    "dist"
  ],
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "default": "./dist/index.js"
    },
    "./package.json": "./package.json"
  },
  "scripts": {
    "build": "tsc",
    "demo": "npm run build && node scripts/demo.mjs",
    "check:consumer": "tsc -p tsconfig.consumer.json && tsc -p tsconfig.consumer-loose.json",
    "check:surface": "node scripts/check-surface.mjs",
    "check:package": "attw --pack . --profile esm-only",
    "verify": "npm run build && npm run check:consumer && npm run check:surface && npm run check:package"
  },
  "engines": {
    "node": ">=22.12.0"
  },
  "devDependencies": {
    "@arethetypeswrong/cli": "0.18.5",
    "typescript": "7.0.2"
  }
}
```
Line by line:
- `"name": "@code101/result-kit"`: a *scoped* name. It is also how the package refers to itself in `consumer/consumer.ts` (Node and TypeScript allow a package to import itself by name when it has an `exports` map).
- `"private": true` and `"license": "UNLICENSED"` keep you from publishing this teaching package by accident. Before publishing a real library: remove `private`, choose a license and fill in `repository`.
- `"sideEffects": false` tells bundlers they may drop any module whose exports are unused (tree shaking). Only set it when it is true: a module that registers something on import is a side effect.
- `"files": ["dist"]` is an allow-list: only the build output (plus `package.json`, README and license, which npm adds itself) goes into the tarball. An allow-list cannot leak `.env` files or tests the way an ignore-list can.
- `"exports"` is the **only** public door. A consumer can import `@code101/result-kit` and `@code101/result-kit/package.json`; `@code101/result-kit/dist/errors.js` is blocked. The `types` condition must come **first**: conditions are matched in order, and the first match wins.
- `"engines"`: Node 22.12 and newer can `require()` an ES module, which is why an ESM-only package no longer cuts off CommonJS consumers on current Node (see trade-offs below).
- `check:package` runs `attw` (the *Are the types wrong?* CLI) on the packed tarball. `--profile esm-only` tells it not to complain about the missing CommonJS build.

### Step 3. Write tsconfig.json (the library build)
**File: `tsconfig.json`**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "rootDir": "src",
    "outDir": "dist",
    "types": [],
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "isolatedDeclarations": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noPropertyAccessFromIndexSignature": true,
    "noImplicitOverride": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "erasableSyntaxOnly": true,
    "noEmitOnError": true,
    "skipLibCheck": false
  },
  "include": ["src/**/*.ts"]
}
```
Why each flag is here, and its cost to someone:

| Flag | What it does | Who pays |
|---|---|---|
| `target` / `lib` `ES2022` | Emit syntax and assume built-ins from ES2022 (includes `Error` `cause`) | Consumers on older runtimes. Pick the oldest runtime you promise to support |
| `types: []` | Do not load any `@types/*` globals; the library must not depend on Node or DOM | You: you must import what you use. Benefit: no accidental `process` or `window` |
| `declaration`, `declarationMap` | Emit `.d.ts` files, and maps so "Go to definition" opens your `.ts` source | Package size (the maps) |
| `isolatedDeclarations` | Every exported function, variable and class member needs an *explicit* type annotation, so `.d.ts` can be generated from one file at a time, in parallel, without a type checker | Authors: more writing. Benefit: fast declaration emit and exact public types that cannot change by accident |
| `noUncheckedIndexedAccess` | `array[i]` is `T \| undefined` | Authors of the library only (it does not leak into your `.d.ts` unless you expose indexed access) |
| `exactOptionalPropertyTypes` | `{ a?: string }` rejects `{ a: undefined }` | Callers who pass `undefined` explicitly. It also changes your *public* types, so test your consumers with it on and off (step 9) |
| `noPropertyAccessFromIndexSignature` | `obj.key` on an index signature must be written `obj['key']` | Authors; makes typos on known keys visible |
| `noImplicitOverride` | `override` is required when overriding | Authors; catches a base-class rename |
| `verbatimModuleSyntax` | Imports and exports are emitted exactly as written; types need `import type` | Authors; makes output predictable |
| `erasableSyntaxOnly` | Forbids syntax that is not just types (enums, namespaces, constructor parameter properties). The output is then your source with the types removed, which Node can run directly with type stripping | Authors who like enums: use union types of string literals instead |
| `skipLibCheck: false` | Checks the `.d.ts` files of your dependencies too | Build time. For a library it is worth it: it proves your own `.d.ts` is valid. For an application most teams turn it on (true) because dependency errors are not theirs to fix |

Rule of thumb: strictness flags that affect only the **inside** of your code (`noUnusedLocals`, `noImplicitOverride`) are free for consumers. Flags that change **public types** (`exactOptionalPropertyTypes`, `strict`) must be tested from the consumer's side.

### Step 4. Write the Result type
**File: `src/result.ts`**
```ts
export interface Ok<T> {
  readonly ok: true;
  readonly value: T;
}

export interface Err<E> {
  readonly ok: false;
  readonly error: E;
}

export type Result<T, E> = Ok<T> | Err<E>;

export function ok<T>(value: T): Ok<T> {
  return { ok: true, value };
}

export function err<E>(error: E): Err<E> {
  return { ok: false, error };
}

export function map<T, U, E>(result: Result<T, E>, fn: (value: T) => U): Result<U, E> {
  return result.ok ? ok(fn(result.value)) : result;
}

export function andThen<T, U, E, F>(
  result: Result<T, E>,
  fn: (value: T) => Result<U, F>,
): Result<U, E | F> {
  return result.ok ? fn(result.value) : result;
}

// NoInfer: the fallback must match the value type; it must not widen T.
export function unwrapOr<T, E>(result: Result<T, E>, fallback: NoInfer<T>): T {
  return result.ok ? result.value : fallback;
}

export function match<T, E, R>(
  result: Result<T, E>,
  handlers: { ok: (value: T) => R; err: (error: E) => R },
): R {
  return result.ok ? handlers.ok(result.value) : handlers.err(result.error);
}
```
API design decisions in this file (ADR style):

| Decision | Chosen | Alternative | Why |
|---|---|---|---|
| Error channel | A discriminated union (`ok: true / false`) | Throwing exceptions | The type forces callers to look at the failure; exceptions are invisible in signatures |
| Tag | A boolean `ok` | A string `kind` | Cheapest to narrow (`if (result.ok)`); a boolean tag is fine for exactly two cases, use strings once there are three |
| Functions | Standalone functions that take the result first | Methods on a class | Functions tree-shake; methods drag the whole class in, and a class cannot be extended by consumers without subclassing |
| Mutability | `readonly` properties | Mutable | Consumers cannot corrupt a value you passed on |
| Fallback typing | `NoInfer<T>` | `T` | `unwrapOr(title, 42)` must fail (the consumer test checks that) |
| Overloads | None | Many overloads for each arity | Overloads make error messages long and ordering matters; one generic signature is easier to evolve |

Because of `isolatedDeclarations` every function has an explicit return type. That is not decoration: it pins the public type so a refactor of the body cannot change what consumers see.

### Step 5. Write the error class
**File: `src/errors.ts`**
```ts
export class ParseError extends Error {
  override readonly name: string = 'ParseError';
  // A short preview, never the whole input: inputs can be large or contain secrets.
  readonly inputPreview: string;

  constructor(message: string, inputPreview: string, options?: ErrorOptions) {
    super(message, options);
    this.inputPreview = inputPreview;
  }
}
```
- The field is declared and assigned separately, not as a constructor parameter property, because `erasableSyntaxOnly` forbids parameter properties.
- `options?: ErrorOptions` lets callers pass `{ cause }`, so the original `SyntaxError` is preserved for debugging (`error.cause`).
- The error stores a **preview** of the input, not the input: error objects end up in logs and error trackers, and inputs may contain tokens or personal data.
- `override` is required by `noImplicitOverride` because `Error` already has a `name`.

### Step 6. Write parseJson and the public entry point
**File: `src/parse.ts`**
```ts
import { ParseError } from './errors.js';
import { err, ok, type Result } from './result.js';

export type Guard<T> = (value: unknown) => value is T;

export function parseJson<T>(text: string, guard: Guard<T>): Result<T, ParseError> {
  let data: unknown;
  try {
    data = JSON.parse(text);
  } catch (cause) {
    return err(new ParseError('Invalid JSON', text.slice(0, 40), { cause }));
  }
  return guard(data)
    ? ok(data)
    : err(new ParseError('JSON does not match the expected shape', text.slice(0, 40)));
}
```
**File: `src/index.ts`**
```ts
export type { Err, Ok, Result } from './result.js';
export { andThen, err, map, match, ok, unwrapOr } from './result.js';
export { ParseError } from './errors.js';
export type { Guard } from './parse.js';
export { parseJson } from './parse.js';
```
`index.ts` is the **public surface**. Everything not re-exported here is private, and the `exports` map makes that enforceable. Writing the list by name (not `export *`) means a new function in `result.ts` is not public until someone decides it should be. The `Guard` type is exported because it appears in `parseJson`'s signature: a type that appears in a public signature but is not exported leaves consumers unable to name it.

`parseJson` takes a *guard* rather than a schema so the library has **no dependency**. Lesson 06 shows the other design: validate with a schema library at the network boundary.

### Step 7. Install and build
```text
npm install --no-audit --no-fund
npm run build
```
Expected result: `npm run build` prints the script header lines and no errors. A folder `dist` appears with `index.js`, `index.d.ts`, `index.d.ts.map`, `index.js.map`, and the same four files for `result`, `errors` and `parse` (typical listing; names follow your source files). Open `dist/result.d.ts`: you should see the declarations without function bodies. That is what a consumer's editor reads.

**Take a break here if you need one.**

### Step 8. Write the consumer test
**File: `consumer/consumer.ts`**
```ts
import {
  andThen,
  err,
  map,
  match,
  ok,
  type ParseError,
  parseJson,
  type Result,
  unwrapOr,
} from '@code101/result-kit';

type Task = { id: string; title: string };

function isTask(value: unknown): value is Task {
  if (typeof value !== 'object' || value === null) {
    return false;
  }
  const record = value as Record<string, unknown>;
  return typeof record['id'] === 'string' && typeof record['title'] === 'string';
}

export const parsed: Result<Task, ParseError> = parseJson('{"id":"1","title":"x"}', isTask);
export const title: Result<string, ParseError> = map(parsed, (task) => task.title);
export const chained: Result<number, ParseError | string> = andThen(title, (text) =>
  text.length > 0 ? ok(text.length) : err('empty title'),
);
export const label: string = match(chained, {
  ok: (length) => `length ${length}`,
  err: (error) => `failed: ${String(error)}`,
});
export const fallback: string = unwrapOr(title, 'untitled');

// @ts-expect-error the fallback must have the value type: NoInfer stops T widening to string | number
export const wrong = unwrapOr(title, 42);

export function increment(result: Result<number, string>): string {
  if (result.ok) {
    return String(result.value + 1);
  }
  return result.error.toUpperCase();
}
```
This file imports the package **by name**, so TypeScript resolves it through `exports` to `dist/index.d.ts`: exactly the path a real consumer takes. It never imports from `../src`. That is the point: it tests the *published* types, not the source. The annotations on each export are assertions: if the library's signature changes, the assignment stops compiling.

**File: `tsconfig.consumer.json`**
```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "rootDir": "consumer",
    "noEmit": true,
    "declaration": false,
    "declarationMap": false,
    "sourceMap": false,
    "isolatedDeclarations": false
  },
  "include": ["consumer/**/*.ts"]
}
```
The consumer config inherits the strict library flags and turns off only what makes no sense without emit (`isolatedDeclarations` is only allowed together with `declaration`).

**File: `tsconfig.consumer-loose.json`**
```json
{
  "extends": "./tsconfig.consumer.json",
  "compilerOptions": {
    "strict": false,
    "exactOptionalPropertyTypes": false,
    "noUncheckedIndexedAccess": false,
    "verbatimModuleSyntax": false,
    "skipLibCheck": true
  }
}
```
Your consumers will not all be as strict as you. The loose configuration checks that your declarations still compile for them, and that the `@ts-expect-error` line still errors (a wrong argument type is an error in any mode).

### Step 9. Write the runtime checks
**File: `scripts/demo.mjs`**
```js
import { err, map, match, ok, parseJson, unwrapOr } from '../dist/index.js';

const isCount = (value) =>
  typeof value === 'object' && value !== null && typeof value.count === 'number';

const describe = {
  ok: (value) => `ok ${value}`,
  err: (error) => `err ${error.message}`,
};

const good = parseJson('{"count": 2}', isCount);
const wrongShape = parseJson('{"count": "two"}', isCount);
const broken = parseJson('{oops', isCount);

console.log(match(map(good, (value) => value.count * 10), describe));
console.log(match(wrongShape, describe));
console.log(match(broken, describe));
console.log(!broken.ok && broken.error.cause instanceof SyntaxError);
console.log(unwrapOr(ok(5), 0), unwrapOr(err('x'), 0));
```
This is plain JavaScript on purpose: it shows the library works for a consumer who does not use TypeScript at all.

**File: `scripts/check-surface.mjs`**
```js
import { readFileSync } from 'node:fs';
import * as lib from '../dist/index.js';

const expected = readFileSync(new URL('../api-surface.txt', import.meta.url), 'utf8')
  .trim()
  .split(/\r?\n/);
const actual = Object.keys(lib).sort();
const added = actual.filter((name) => !expected.includes(name));
const removed = expected.filter((name) => !actual.includes(name));

if (added.length > 0 || removed.length > 0) {
  console.error(`Public API changed. Added: [${added.join(', ')}] Removed: [${removed.join(', ')}]`);
  process.exit(1);
}
console.log(`Public API unchanged: ${actual.length} exports`);
```
**File: `api-surface.txt`**
```text
ParseError
andThen
err
map
match
ok
parseJson
unwrapOr
```
The snapshot is a cheap, dependency-free guard: a pull request that adds or removes an export must also edit `api-surface.txt`, so a reviewer sees the change. It covers **runtime** names only (types are erased from `dist/index.js`); the consumer test covers type changes. Dedicated tools such as API Extractor track types too, at the price of another dependency and, with TypeScript 7, the compiler-API caveat in "Before you start".

## Run it
**Predict first:**
1. How many lines does `node scripts/demo.mjs` print?
2. What does `npm run check:consumer` print when everything is right?
3. What happens to `check:surface` if you add `export { map as transform } from './result.js';` to `index.ts` and rebuild?

```text
npm run demo
```
Expected output (the build prints its own script header first; these are the program lines):
```text
ok 20
err JSON does not match the expected shape
err Invalid JSON
true
5 0
```
```text
npm run check:consumer --silent
```
Expected output (nothing; exit code 0):
```text

```
```text
npm run check:surface --silent
```
Expected output:
```text
Public API unchanged: 8 exports
```
```text
npm run check:package
```
Expected output: `attw` prints a table of how the package resolves under different module systems. With `--profile esm-only` you should see no problem entries for the `.` entry point. I cannot print the exact table before running it: read it, and treat any red entry as a bug in `exports` or `types`.

Answers to the predictions: (1) five lines; (2) nothing; (3) `check:surface` exits with code 1 and prints `Public API changed. Added: [transform] Removed: []`.

## How it works
1. **Build.** `tsc` reads `src`, writes `.js`, `.d.ts` and maps to `dist`. Because `isolatedDeclarations` is on, each `.d.ts` can be produced from its own file.
2. **Resolution.** When a consumer writes `import ... from '@code101/result-kit'`, Node and TypeScript read `exports['.']`, match the first condition they understand (`types` for TypeScript, `default` for Node), and load that file. Anything outside `exports` does not exist for them.
3. **Consumer test.** `tsc -p tsconfig.consumer.json` type-checks `consumer.ts` against `dist/index.d.ts`, so a wrong `types` path, a missing re-export or a changed signature fails here, in your repository, not in your user's editor.
4. **Surface snapshot.** The runtime namespace of the built entry point is compared with `api-surface.txt`.

**Common misconception:** "If it compiles in my repository, the published package works." Source files resolve through relative paths and your own `tsconfig`; the published package resolves through `exports` and the *consumer's* `tsconfig`. Only the consumer test and `attw` exercise that path.

**Which changes are breaking for types (a reviewer's table)**

| Change | Breaking? | Reason |
|---|---|---|
| Add an optional parameter or property to an *input* type | No | Existing callers still compile |
| Add a **required** property to an input type | **Yes** | Existing callers are missing it |
| Add a property to an *output* type | Usually no | Callers that read the old properties still work; callers that spread or compare exact shapes may notice |
| Narrow an input type (`string` to `'a' \| 'b'`) | **Yes** | Callers passing other strings stop compiling |
| Widen an output type (`T` to `T \| undefined`) | **Yes** | Callers must now handle `undefined` |
| Add a member to a union that consumers `switch` over | **Yes** for exhaustive consumers (lesson 02) | Their `assertNever` stops compiling. Document unions as "may grow" if you intend to extend them |
| Rename or remove an export | **Yes** | The snapshot catches this |
| Change a flag that affects emitted declarations (`exactOptionalPropertyTypes` in your own build) | Possibly | Your `.d.ts` can change shape; the consumer test with both configs shows it |

**Trade-offs and decisions**

| Decision | Chosen | Alternative | Why / when to switch |
|---|---|---|---|
| Module format | ESM only | Dual ESM and CommonJS | Dual packages risk loading two copies of the code ("dual package hazard"), and `instanceof ParseError` then fails across copies. Node 22.12+ can `require()` ESM, which removes most of the reason to ship CommonJS. Switch if you must support older Node |
| Types location | Emitted next to `.js`, `types` condition first | A hand-written `index.d.ts` | Generated types cannot drift from the code. Write `.d.ts` by hand only for code you cannot type (a plain-JavaScript dependency, a global added by a script) |
| `private` and `files` allow-list | Allow-list | `.npmignore` | An ignore-list leaks whatever you forgot to list |
| API tracking | A 20-line snapshot + consumer test | API Extractor or similar | Start cheap; add the tool when the surface is large or several teams depend on it |
| Error handling | `Result` | Throw | Good at boundaries where failure is expected (parsing). Not worth it for programmer errors (a bug should throw) |

**Failure modes**
- **`types` after `default`** in `exports`: TypeScript matches `default` first, finds a `.js` file without types, and your consumers silently get `any`. `attw` reports this.
- **A type in a public signature that is not exported:** consumers cannot name it, and tools produce error messages that mention a path inside your package.
- **Declaration files that need a flag:** a `.d.ts` that uses a feature only your flags allow (for example a very new syntax) breaks consumers on an older compiler. Test the **oldest TypeScript version you promise to support** in CI (install it under an alias such as `typescript-min`) and run the consumer test with it.
- **Leaking Node or DOM types:** with `types: []` the library cannot reference `process` or `window` by accident; if you need `Buffer`, say so in your documentation and declare it as a peer dependency of `@types/node`.
- **Deep imports:** consumers that import `@code101/result-kit/dist/errors.js` used to work in the age of `main`; `exports` now blocks them. That is a feature, and a breaking change for anyone who relied on it: announce it in the changelog.

**When not to build a library**
- When one application uses the code. Keep it in the application (or a folder in the monorepo of lesson 05) until a second consumer exists. A package has release, versioning and support costs.
- When the code changes every week. A library's types are a contract; a contract that changes weekly is just friction.
- When a good library already exists and you only wrap it with different names.

## Try it
Copy your finished project to `result-kit-try`.
1. **Guided.** Create `src/collect.ts` from the starter below and implement `all` and `mapErr`. Export both from `src/index.ts`, run `npm run build` and `npm run check:surface`. It must fail. Read the message, then update `api-surface.txt` on purpose and run it again.
2. **Change.** Add consumer tests for `all` and `mapErr` to `consumer/consumer.ts`: one positive annotation each, and one `@ts-expect-error` (for example, `all` over results with two different error types).
3. **Stretch (no single answer).** `ParseError` is a class. Should the library offer a plain-object error with a `code` field instead, so errors survive `structuredClone` and `postMessage` (classes lose their prototype when cloned)? Write down your decision as a four-line ADR: context, decision, consequence, and what would make you change it.

**Starter file (`exercise/starter/src/collect.ts`)**
```ts
import type { Result } from './result.js';

// TODO 1: return the first error, otherwise ok(every value in order).
export function all<T, E>(_results: readonly Result<T, E>[]): Result<T[], E> {
  throw new Error('TODO: implement all');
}

// TODO 2: transform only the error side; leave an ok result untouched.
export function mapErr<T, E, F>(_result: Result<T, E>, _fn: (error: E) => F): Result<T, F> {
  throw new Error('TODO: implement mapErr');
}

// TODO 3: export both from src/index.ts, run "npm run build", then run "npm run check:surface".
// It must fail. Read the message, then update api-surface.txt on purpose.
```

<details><summary>Solution</summary>

**File: `exercise/solution/src/collect.ts`**
```ts
import { err, ok, type Result } from './result.js';

export function all<T, E>(results: readonly Result<T, E>[]): Result<T[], E> {
  const values: T[] = [];
  for (const result of results) {
    if (!result.ok) {
      return result;
    }
    values.push(result.value);
  }
  return ok(values);
}

export function mapErr<T, E, F>(result: Result<T, E>, fn: (error: E) => F): Result<T, F> {
  return result.ok ? result : err(fn(result.error));
}
```
**File: `exercise/solution/src/index.ts`**
```ts
export type { Err, Ok, Result } from './result.js';
export { andThen, err, map, match, ok, unwrapOr } from './result.js';
export { all, mapErr } from './collect.js';
export { ParseError } from './errors.js';
export type { Guard } from './parse.js';
export { parseJson } from './parse.js';
```
**File: `exercise/solution/api-surface.txt`**
```text
ParseError
all
andThen
err
map
mapErr
match
ok
parseJson
unwrapOr
```
After the update, `npm run check:surface` prints `Public API unchanged: 10 exports`. `all` returns the failing result itself in the loop; that is safe because an `Err<E>` is assignable to `Result<T[], E>`. For the `@ts-expect-error` in rung 2: `all([ok(1) as Result<number, string>, err(2) as Result<number, number>])` fails because the two results do not share one `E`.

</details>

## Check yourself
1. Why must `types` come before `default` in an `exports` condition list? <details><summary>Answer</summary>Conditions are matched in order; if <code>default</code> is first, TypeScript takes the <code>.js</code> file and consumers get no types.</details>
2. What does `isolatedDeclarations` force you to write, and what does it buy? <details><summary>Answer</summary>Explicit types on exported functions, variables and class members. It buys declaration emit from one file at a time (fast, parallel) and public types that cannot change by accident when you refactor a body.</details>
3. Is changing `parse(input: string)` to `parse(input: string | Buffer)` breaking for callers? What about changing the return type from `T` to `T | undefined`? <details><summary>Answer</summary>Widening an input is not breaking. Widening an output is: every caller must now handle <code>undefined</code>.</details>
4. Find the bug: `exports` is `{ ".": { "default": "./dist/index.js", "types": "./dist/index.d.ts" } }`. What do TypeScript consumers get? <details><summary>Answer</summary>The condition order is wrong: matching stops at <code>default</code>, so TypeScript finds JavaScript without declarations and the import is effectively untyped. <code>attw</code> flags this.</details>
5. Why does the consumer test run twice, with two configurations? <details><summary>Answer</summary>Your declarations must work for consumers with different flags. The strict run proves the types are right; the loose run proves they do not require your strictness.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Cannot find module '@code101/result-kit' or its corresponding type declarations.` (typical) | You did not build first, so `dist/index.d.ts` is missing | Run `npm run build` before `npm run check:consumer` |
| `Function must have an explicit return type annotation with --isolatedDeclarations.` (typical) | An exported function lacks a return type | Write the return type |
| `Option 'isolatedDeclarations' can only be used when either option 'declaration' or option 'composite' is set.` (typical) | A config turns declaration off but leaves `isolatedDeclarations` on | Turn both off, as `tsconfig.consumer.json` does |
| `This syntax is not allowed when 'erasableSyntaxOnly' is enabled.` (typical) | An `enum`, `namespace` or constructor parameter property | Use a string-literal union or declare the field and assign it in the constructor |
| `attw` reports `Masquerading as CJS` or a missing-types entry (typical wording) | `exports` or `type` wrong, or `types` after `default` | Fix the `exports` map; for an ESM-only package use the `esm-only` profile |
| `Public API changed. Added: [...] Removed: [...]` | You changed the exports | If intended, update `api-surface.txt` in the same commit |
| `npm.ps1 cannot be loaded` | PowerShell execution policy | Use `npm.cmd` and `npx.cmd` |

## Best practice
Test the package the way a consumer receives it: through `exports`, from a separate compilation, with at least one stricter and one looser configuration. Source: TypeScript docs, [Publishing: declaration files](https://www.typescriptlang.org/docs/handbook/declaration-files/publishing.html) and the [TSConfig reference](https://www.typescriptlang.org/tsconfig/); Node.js documentation on package `exports`.

## Production checklist
- [ ] `exports` map with `types` first; no `main`/`types` fields that disagree with it.
- [ ] `files` allow-list; `npm pack --dry-run` lists only what you intend to ship (run it and read the list).
- [ ] `isolatedDeclarations` on; every exported symbol has an explicit type.
- [ ] A consumer test compiles against the built package with a strict and a loose config, and with the oldest TypeScript version you support.
- [ ] `attw` (or equivalent) passes in CI.
- [ ] Public API snapshot reviewed in every pull request.
- [ ] No secrets or whole inputs in error objects.
- [ ] A changelog entry for every breaking type change; a deprecation period (`@deprecated` JSDoc) before removal.

## Going further
- TypeScript docs: [Modules reference](https://www.typescriptlang.org/docs/handbook/modules/reference.html) (including `exports` and self-referencing) and the TSConfig reference entries for `isolatedDeclarations` and `erasableSyntaxOnly`.
- The TypeScript 7.0 announcement on the TypeScript team blog: the list of new defaults, the removed options and the `--checkers`, `--builders` and `--singleThreaded` flags. Lesson 05 uses `--builders`.
- Capstone link: the Angular capstone pins TypeScript 6.0.3 for its compiler plugin ([capstones/web-angular/VERSIONS.md](../../../../capstones/web-angular/VERSIONS.md)): your library's declarations must work for consumers on older compilers, which is exactly what the "oldest supported TypeScript" checklist item tests.

## Summary
- You packaged a library with an `exports` map, generated declarations and `isolatedDeclarations`.
- You chose strictness flags deliberately and named who pays for each.
- You tested the package as a consumer, under two configurations, plus a surface snapshot.
- You classified type changes as breaking or not.

## Next lesson
04. Design systems and design tokens: apply the same discipline (one source of truth, a build pipeline, documentation) to CSS.
