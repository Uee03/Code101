---
track: web
level: 301
phase: 1
phase_name: type-level-typescript
lesson: 02
title: "Template literal types, type-safe routing and exhaustive checks"
time: 120 min
prerequisites: [web-301.01, web-201.04]
versions: { node: "26.13.1", npm: "11.20.0", typescript: "7.0.2", "@types/node": "26.6.6" }
verified: not yet run
source: source/web/301-super-hero-to-legendary/phase-1-type-level-typescript/02-template-literal-types/
assets: []
---

# 02. Template literal types, type-safe routing and exhaustive checks

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- write template literal types that extract and rewrite parts of a string type
- build a route table where `href('team', { teamId })` is checked at compile time, and parse a URL back into a typed match
- make a `switch` exhaustive and explain when exhaustive is wrong (data from a server that is newer than your client)
- name the failure modes of string-level types: union explosion, drift between type and runtime, and slow checking

## Recap
1. What does `[T] extends [never]` do that `T extends never` does not (lesson 01)?
   <details><summary>Answer</summary>It stops distribution, so <code>never</code> is tested as a value instead of producing an empty union.</details>
2. What is the difference between `as const` and `satisfies`?
   <details><summary>Answer</summary><code>as const</code> freezes literal types; <code>satisfies</code> checks a value against a type without widening it. Together they give exact literals that are still validated.</details>
3. Why does `import './types.js'` end in `.js` when the source file is `types.ts`?
   <details><summary>Answer</summary>Node resolves the emitted file. With <code>nodenext</code>, TypeScript keeps the import exactly as Node will see it.</details>

## Why it matters
Strings are how the web talks to itself: URLs, event names, CSS custom property names, header names, JSON keys. Most of those strings follow a pattern, and a pattern is something the type system can check. A wrong link in a router is a classic production bug that tests rarely catch; a template literal type turns it into a red squiggle. The other half of the lesson is the opposite risk: types that look precise but describe data you do not control.

## What you will build
A typed route table with three functions: `href` (build a URL), `matchRoute` (parse a pathname) and `describe` (an exhaustive `switch`). You also add a tolerant label function for server data and a `camelizeKeys` helper whose type and runtime must agree. The program prints eight lines.

## Before you start
- Lesson 01 finished (the same toolchain: Node 26.13.1, npm 11.20.0, TypeScript 7.0.2).
- Builds on Web 201 lesson [04 Unions, narrowing and utility types](../../201-hero-to-super-hero/phase-2-typescript-in-depth/04-unions-narrowing-utility-types.md), which introduced discriminated unions and `assertNever`; here the same idea is applied to strings and to data you do not control.
- Time: 90 to 120 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/301-super-hero-to-legendary/phase-1-type-level-typescript/02-template-literal-types/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- No `package-lock.json` is shipped; `npm install` creates it.
- Version note: TypeScript 7 treats a Unicode code point as one unit when inferring from template literal types (earlier versions split an emoji into two halves). Type-level string utilities that count characters can therefore change result when you upgrade. Nothing in this lesson depends on it, because route names are ASCII.

## Steps

### Step 1. Create the project
```text
mkdir web301-02
cd web301-02
mkdir src
```
Expected result: an empty `web301-02` folder with an empty `src` folder inside it, and the terminal's current folder is `web301-02`.

### Step 2. Write package.json
This is the same file as lesson 01 with only the `name` changed. The reasons for each line are in lesson 01, step 2.

**File: `package.json`**
```json
{
  "name": "web301-02-template-literal-types",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "typecheck": "tsc --noEmit",
    "build": "tsc",
    "start": "node dist/index.js"
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

### Step 3. Write tsconfig.json
Identical to lesson 01, step 3 (strict flags, `nodenext`, explicit `rootDir` and `types`). Shown in full so you can copy it:

**File: `tsconfig.json`**
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
Then install:
```text
npm install --no-audit --no-fund
```
Expected result: `node_modules` and `package-lock.json` appear; the summary line count varies.

### Step 4. Write the test helpers
**File: `src/testing.ts`**
```ts
// Compile-time test helpers (the same three as lesson 01).
export type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends (<T>() => T extends B ? 1 : 2) ? true : false;
export type Expect<T extends true> = T;
export type CanAssign<From, To> = [From] extends [To] ? true : false;
```
These are the same three helpers as lesson 01, step 5 (the differences: none). They are copied rather than shared because each lesson is a standalone project; lesson 05 shows how a monorepo removes that copying.

### Step 5. Write the route-level types
**File: `src/route-types.ts`**
```ts
// Split "a.b.c" at a delimiter into ["a", "b", "c"].
export type Split<S extends string, D extends string> = S extends `${infer Head}${D}${infer Tail}`
  ? [Head, ...Split<Tail, D>]
  : [S];

// Extract the names of ":param" segments from a route pattern.
export type PathParams<P extends string> = P extends `${string}:${infer Param}/${infer Rest}`
  ? Param | PathParams<`/${Rest}`>
  : P extends `${string}:${infer Param}`
    ? Param
    : never;

export type RouteParams<P extends string> = { [K in PathParams<P>]: string };

// Routes without parameters take no second argument; others take exactly one params object.
export type ParamArgs<P extends string> = [PathParams<P>] extends [never]
  ? []
  : [params: RouteParams<P>];

// "due_date" becomes "dueDate" (type level).
export type SnakeToCamel<S extends string> = S extends `${infer Head}_${infer Tail}`
  ? `${Head}${Capitalize<SnakeToCamel<Tail>>}`
  : S;

// Rename every string key of an object type.
export type CamelizeKeys<T> = {
  [K in keyof T as K extends string ? SnakeToCamel<K> : K]: T[K];
};
```
Walk through `PathParams<'/teams/:teamId/projects/:projectId'>` by hand, the way the compiler does:
1. The first branch asks: does the string look like `<anything>:<name>/<rest>`? `${string}` matches `/teams/` (up to the first `:`), `Param` matches `teamId` (up to the next `/`) and `Rest` is `projects/:projectId`.
2. The result is `'teamId' | PathParams<'/projects/:projectId'>`. The recursion puts the `/` back so the same pattern can match the next segment.
3. For `/projects/:projectId` there is no `/` after the `:`, so the first branch fails and the second branch (`<anything>:<name>`) gives `'projectId'`.
4. Final answer: `'teamId' | 'projectId'`. A route without `:` falls through both branches to `never`.

`ParamArgs` turns that union into function arguments: no parameters means an empty tuple (the caller writes nothing), parameters mean one required object. `SnakeToCamel` and `CamelizeKeys` use the same idea with `Capitalize`, one of four built-in string helpers (`Uppercase`, `Lowercase`, `Capitalize`, `Uncapitalize`).

### Step 6. Write the route table
**File: `src/routes.ts`**
```ts
import type { ParamArgs, PathParams } from './route-types.js';

// "as const" keeps the exact strings; "satisfies" checks the shape without widening them.
export const routes = {
  home: '/',
  teams: '/teams',
  team: '/teams/:teamId',
  project: '/teams/:teamId/projects/:projectId',
  task: '/tasks/:taskId',
} as const satisfies Record<string, `/${string}`>;

export type Routes = typeof routes;
export type RouteName = keyof Routes;

// One union member per route: the params type depends on the route name.
export type Match = {
  [N in RouteName]: { name: N; params: Record<PathParams<Routes[N]>, string> };
}[RouteName];

const PARAM = /:([A-Za-z0-9_]+)/g;

export function href<N extends RouteName>(name: N, ...args: ParamArgs<Routes[N]>): string {
  // Boundary cast: TypeScript cannot index a rest tuple that depends on N.
  const params = (args as unknown as [Readonly<Record<string, string>>?])[0] ?? {};
  return routes[name].replace(PARAM, (_match, key: string) => {
    const value = params[key];
    if (value === undefined) {
      throw new Error(`Missing route param: ${key}`);
    }
    return encodeURIComponent(value);
  });
}

const patterns = (Object.keys(routes) as RouteName[]).map((name) => ({
  name,
  regex: new RegExp(`^${routes[name].replace(PARAM, '(?<$1>[^/]+)')}$`),
}));

function decode(value: string): string | undefined {
  try {
    return decodeURIComponent(value);
  } catch {
    return undefined;
  }
}

export function matchRoute(pathname: string): Match | undefined {
  for (const { name, regex } of patterns) {
    const found = regex.exec(pathname);
    if (!found) {
      continue;
    }
    const params: Record<string, string> = {};
    for (const [key, raw] of Object.entries(found.groups ?? {})) {
      const value = decode(raw);
      if (value === undefined) {
        return undefined;
      }
      params[key] = value;
    }
    return { name, params } as Match;
  }
  return undefined;
}
```
How it works:
- The route table is the **single source of truth**. Everything else (names, parameter names, parsing regexes) is derived from it, so there is no second list to forget to update.
- `satisfies Record<string, `/${string}`>` is itself a template literal type: every route must start with `/`.
- `Match` is a *distributive object type*: a mapped type indexed by its own keys builds a union with one member per route, where `name` is the discriminant. After `if (match?.name === 'task')`, TypeScript knows `match.params.taskId` exists.
- `href` runs the table's string through the same pattern as the type. Values are passed through `encodeURIComponent`, so `p/9` becomes `p%2F9`, not an extra path segment: a classic route bug if you concatenate strings.
- `matchRoute` compiles each route into a regular expression with named groups, once, at module load. `decodeURIComponent` throws `URIError` on malformed input like `%E0%A4%A`; `decode` catches it and the route simply does not match.
- Two casts remain, both at a boundary and both commented: one in `href` (rest tuple depending on `N`) and one for `Match` (a regex result is a plain record).

### Step 7. Write the exhaustive checks
**File: `src/exhaustive.ts`**
```ts
export type TaskStatus = 'todo' | 'in_progress' | 'blocked' | 'done' | 'cancelled';

// Passing anything other than never is a compile error, so a forgotten case is caught.
// If bad data still arrives at runtime, it fails loudly with the offending value.
export function assertNever(value: never, context: string): never {
  throw new Error(`Unhandled ${context}: ${JSON.stringify(value)}`);
}

// Exhaustive map: adding a status to the union without a label is a compile error.
export const statusLabels = {
  todo: 'To do',
  in_progress: 'In progress',
  blocked: 'Blocked',
  done: 'Done',
  cancelled: 'Cancelled',
} satisfies Record<TaskStatus, string>;

export type TaskEvent =
  | { type: 'created'; id: string; title: string }
  | { type: 'status_changed'; id: string; to: TaskStatus }
  | { type: 'deleted'; id: string };

// Strict: for events this program defines itself. A new variant stops this from compiling.
export function describe(event: TaskEvent): string {
  switch (event.type) {
    case 'created':
      return `Created ${event.title}`;
    case 'status_changed':
      return `${event.id} is now ${statusLabels[event.to]}`;
    case 'deleted':
      return `Deleted ${event.id}`;
    default:
      return assertNever(event, 'task event');
  }
}

export function isTaskStatus(value: string): value is TaskStatus {
  return Object.hasOwn(statusLabels, value);
}

// Tolerant: for data from a server that may be newer than this client.
export function labelFor(status: string): string {
  return isTaskStatus(status) ? statusLabels[status] : `Unknown (${status})`;
}
```
This file shows two opposite policies for one concept:
- **Strict (`describe`)**: the union is yours. After the three `case` branches TypeScript narrows `event` to `never`; passing it to `assertNever` compiles only if nothing is left. Add a fourth event type and the `default` branch stops compiling: the compiler lists every place to update.
- **Tolerant (`labelFor`)**: the value comes from a server that deploys on its own schedule. A newer server may send `'archived'`. If the client throws, a harmless new status takes the whole screen down. `isTaskStatus` is a type guard that admits the unknown, and the UI shows a fallback.
- `Object.hasOwn` (ES2022) is used instead of `value in statusLabels`, which would accept inherited names such as `toString`.

### Step 8. Write the key rewriter
**File: `src/keys.ts`**
```ts
import type { CamelizeKeys, SnakeToCamel } from './route-types.js';

export function camelize<S extends string>(value: S): SnakeToCamel<S> {
  const result = value.replace(/_([a-z0-9])/g, (_match, char: string) => char.toUpperCase());
  // Boundary cast: the type and this regex must agree. type-tests.ts and index.ts check that.
  return result as unknown as SnakeToCamel<S>;
}

export function camelizeKeys<T extends Record<string, unknown>>(input: T): CamelizeKeys<T> {
  const output: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(input)) {
    output[camelize(key)] = value;
  }
  return output as unknown as CamelizeKeys<T>;
}
```
The cast is a promise that the regex does what the type says. That promise can be broken: for `a__b` the type computes `aB` (it splits at the first underscore, leaving `_b`, which has an empty head), while the regex produces `a_B`. Types describe your *intent*; only a runtime test shows they match. Try it in the exercise's "Change" rung.

### Step 9. Write the compile-time tests
**File: `src/type-tests.ts`**
```ts
import { describe } from './exhaustive.js';
import type { CamelizeKeys, ParamArgs, PathParams, SnakeToCamel, Split } from './route-types.js';
import { href, matchRoute } from './routes.js';
import type { Equal, Expect } from './testing.js';

export type TypeTests = [
  Expect<Equal<Split<'a.b.c', '.'>, ['a', 'b', 'c']>>,
  Expect<Equal<PathParams<'/'>, never>>,
  Expect<Equal<PathParams<'/teams/:teamId'>, 'teamId'>>,
  Expect<Equal<PathParams<'/teams/:teamId/projects/:projectId'>, 'teamId' | 'projectId'>>,
  Expect<Equal<ParamArgs<'/teams'>, []>>,
  Expect<Equal<ParamArgs<'/teams/:teamId'>, [params: { teamId: string }]>>,
  Expect<Equal<SnakeToCamel<'due_date'>, 'dueDate'>>,
  Expect<Equal<CamelizeKeys<{ due_date: string; id: number }>, { dueDate: string; id: number }>>,
];

// Each directive must hide exactly one real error.
export function negativeTests(): void {
  href('home');
  href('team', { teamId: 't1' });
  // @ts-expect-error the team route needs its parameter
  href('team');
  // @ts-expect-error wrong parameter name
  href('team', { id: 't1' });
  // @ts-expect-error the home route takes no parameters
  href('home', { teamId: 'x' });
  // @ts-expect-error unknown route name
  href('settings');
  // @ts-expect-error projectId is missing
  href('project', { teamId: 't1' });
  // @ts-expect-error 'archived' is not a known event type
  describe({ type: 'archived', id: 'x' });

  const match = matchRoute('/tasks/t1');
  if (match?.name === 'task') {
    // Narrowing on name gives params the right shape.
    const id: string = match.params.taskId;
    void id;
  }
}
```

### Step 10. Write the program
**File: `src/index.ts`**
```ts
import { describe, labelFor } from './exhaustive.js';
import { camelizeKeys } from './keys.js';
import { href, matchRoute } from './routes.js';

console.log(href('home'));
console.log(href('team', { teamId: 't 1' }));
console.log(href('project', { teamId: 'core', projectId: 'p/9' }));
console.log(JSON.stringify(matchRoute('/teams/core/projects/p%2F9')));
console.log(matchRoute('/nope'));
console.log(describe({ type: 'status_changed', id: 't1', to: 'blocked' }));
console.log(labelFor('archived'));
console.log(JSON.stringify(camelizeKeys({ due_date: '2026-12-01', assigned_to_id: null })));
```

## Run it
**Predict first:** what does `href('team', { teamId: 't 1' })` print (think about the space)? What does `matchRoute('/nope')` print? Is `JSON.stringify(undefined)` a string?

```text
npx tsc --noEmit
npm run build
npm start
```
Expected output of `tsc` (nothing, exit code 0). Expected output of `npm start` (not yet run):
```text
/
/teams/t%201
/teams/core/projects/p%2F9
{"name":"project","params":{"teamId":"core","projectId":"p/9"}}
undefined
t1 is now Blocked
Unknown (archived)
{"dueDate":"2026-12-01","assignedToId":null}
```
Answers: the space becomes `%20` because of `encodeURIComponent`; `matchRoute('/nope')` returns `undefined`, which `console.log` prints as the word `undefined` (the code does not wrap it in `JSON.stringify`, because `JSON.stringify(undefined)` returns the value `undefined`, not a string, even though its declared type is `string`).

**Break it on purpose (two minutes).** Add `| 'archived'` to `TaskStatus` and run `npx tsc --noEmit`. You should see errors in `exhaustive.ts` (the `statusLabels` object no longer satisfies `Record<TaskStatus, string>`, typical message: `Property 'archived' is missing in type ...`). Add `archived: 'Archived'` and run again. Now add a fourth variant to `TaskEvent` and watch `describe` stop compiling at `assertNever` (typical message: `Argument of type '...' is not assignable to parameter of type 'never'.`). Undo both changes.

## How it works
1. **Pattern matching on strings.** `S extends `${infer Head}_${infer Tail}`` is a regular-expression-like match on a *type*. `infer` captures a part; the capture is then usable on the true branch.
2. **Cross products.** `` `${A}-${B}` `` with unions `A` and `B` produces every combination. Three methods and 40 paths already make 120 members; the compiler stops at about 100,000 with the typical message `Expression produces a union type that is too complex to represent.` (TS2590).
3. **Narrowing.** A discriminant such as `event.type` or `match.name` tells the compiler which union member it is looking at; `default` receives what is left.
4. **Two validations.** The compiler validates your own code. Nothing validates the data from the network: types are erased before the program runs.

**Common misconception:** "The compiler type-checks my URLs." It checks the URLs *you build through `href`*. A string typed into the address bar, a link from an email or a path from the server still arrives as a plain string; `matchRoute` is where it is checked, at runtime, and the result is a union that includes `undefined`.

**Why this, not that (ADR style)**

| Decision | Chosen | Alternative | Why |
|---|---|---|---|
| Route source of truth | One `as const` table, types and regexes derived from it | Parallel lists of names, patterns and param types | Cannot get out of sync; adding a route is one line |
| Param extraction | Template literal recursion | Hand-written param types per route | Zero maintenance, bounded cost (one recursion step per `:`) |
| Router library | Thin typed `href` over any router | Replace the router with a framework-specific typed one | Keep the framework you have; compare your router's own typed-route support before building more |
| Unknown server values | Tolerant fallback (`labelFor`) | `assertNever` everywhere | A server upgrade must not crash an older client |
| Exhaustiveness | `satisfies Record<Union, V>` and `assertNever` | Lint rules only | The compiler is already running; no extra tool |

**Failure modes**
- **Union explosion** (TS2590) from cross products. Break the product into steps or accept `string` at that boundary.
- **Drift between type and runtime** (`a__b` above). Keep the cast in one function and give it a runtime test.
- **Slow checking.** Recursion over long strings costs one instantiation per character. Prefer splitting on delimiters (as `PathParams` does) over character-by-character walks, and measure with `--extendedDiagnostics`.
- **False confidence.** A typed route does not mean the page exists, the user may open it, or the parameter is a valid id. Authorisation and validation stay on the server (see the capstone auth chapters).
- **Over-strict exhaustiveness on external data.** Use the tolerant pattern for anything a server, a stored value or a URL can supply.

**When not to use this**
- To parse a grammar (SQL, CSS, JSON) at the type level. It is clever, slow and unmaintainable; use a runtime parser and derive types from its output.
- When your router already generates types for its routes: use that and delete your table.
- For dynamic route tables built at runtime: `as const` needs literals known at compile time.

## Try it
Copy your finished project to `web301-02-try`.
1. **Guided.** Create `src/exercise.ts` from the starter below. Replace the two placeholder types and the runtime function so the four type tests compile and `node dist/exercise.js` (after `npm run build`) prints `due_date assigned_to_id`.
2. **Change.** In `route-types.ts`, test `SnakeToCamel<'a__b'>` and compare it with `camelize('a__b')` at runtime. Which is wrong, the type or the regex? Decide what the correct behaviour is for double underscores, change one of them, and add a test that would have caught it.
3. **Stretch (no single answer).** Add a route `comment: '/tasks/:taskId/comments/:commentId'`, then design optional parameters (`/teams/:teamId?`). Does the type need a second table? Does `matchRoute` need a different regular expression? Write down which you would ship and what you would not support.

**Starter file (`exercise/starter/src/exercise.ts`)**
```ts
import type { Equal, Expect } from './testing.js';

// TODO 1: turn camelCase into snake_case at the type level: 'dueDate' -> 'due_date'.
// This placeholder is wrong on purpose.
export type CamelToSnake<S extends string> = S;

// TODO 2: rename every string key of T with CamelToSnake. This placeholder is wrong on purpose.
export type SnakeKeys<T> = T;

export function snake<S extends string>(value: S): CamelToSnake<S> {
  // TODO 3: implement the runtime half so it agrees with the type for the examples below.
  return value as unknown as CamelToSnake<S>;
}

export type ExerciseTests = [
  Expect<Equal<CamelToSnake<'dueDate'>, 'due_date'>>,
  Expect<Equal<CamelToSnake<'assignedToId'>, 'assigned_to_id'>>,
  Expect<Equal<CamelToSnake<'id'>, 'id'>>,
  Expect<Equal<SnakeKeys<{ dueDate: string; id: number }>, { due_date: string; id: number }>>,
];

console.log(snake('dueDate'), snake('assignedToId'));
```

<details><summary>Solution</summary>

**File: `exercise/solution/src/exercise.ts`**
```ts
import type { Equal, Expect } from './testing.js';

// Lowercase the head; put an underscore before any character whose tail starts with a capital.
export type CamelToSnake<S extends string> = S extends `${infer Head}${infer Tail}`
  ? Tail extends Uncapitalize<Tail>
    ? `${Lowercase<Head>}${CamelToSnake<Tail>}`
    : `${Lowercase<Head>}_${CamelToSnake<Tail>}`
  : S;

export type SnakeKeys<T> = {
  [K in keyof T as K extends string ? CamelToSnake<K> : K]: T[K];
};

export function snake<S extends string>(value: S): CamelToSnake<S> {
  const result = value.replace(/[A-Z]/g, (char) => `_${char.toLowerCase()}`);
  return result as unknown as CamelToSnake<S>;
}

export type ExerciseTests = [
  Expect<Equal<CamelToSnake<'dueDate'>, 'due_date'>>,
  Expect<Equal<CamelToSnake<'assignedToId'>, 'assigned_to_id'>>,
  Expect<Equal<CamelToSnake<'id'>, 'id'>>,
  Expect<Equal<SnakeKeys<{ dueDate: string; id: number }>, { due_date: string; id: number }>>,
];

console.log(snake('dueDate'), snake('assignedToId'));
```
The type walks one character at a time: `Tail extends Uncapitalize<Tail>` is true when the tail does not start with a capital, so no underscore is inserted. That is the character-by-character recursion the lesson warned about; it is acceptable for short key names and would not be for long strings. For the change rung, the `a__b` mismatch is a real design decision: either forbid double underscores in the contract or make both type and regex treat `_` followed by `_` the same way.

</details>

## Check yourself
1. What is `PathParams<'/teams/:teamId'>`? <details><summary>Answer</summary><code>'teamId'</code></details>
2. Why does `href('home', { teamId: 'x' })` fail to compile? <details><summary>Answer</summary><code>PathParams</code> of <code>'/'</code> is <code>never</code>, so <code>ParamArgs</code> is the empty tuple and a second argument is too many.</details>
3. When is `assertNever` the wrong tool? <details><summary>Answer</summary>For data you do not control, such as server responses; a newer server would crash an older client. Use a tolerant fallback.</details>
4. Find the bug: `camelize('a__b')` returns `a_B` but `SnakeToCamel<'a__b'>` is `'aB'`. What kind of failure is this and how do you prevent it? <details><summary>Answer</summary>Drift between the type and the runtime. Prevent it with a test that runs the function and asserts the same value the type claims, and decide the intended behaviour for edge cases.</details>
5. Why use `Object.hasOwn(statusLabels, value)` and not `value in statusLabels`? <details><summary>Answer</summary><code>in</code> also finds inherited properties such as <code>toString</code>, so a malicious or odd server value would pass the guard.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Expected 2 arguments, but got 1.` (typical, on `href('team')`) | The route has parameters | Pass the params object; this is the check working |
| `Expression produces a union type that is too complex to represent.` (TS2590) | A template literal cross product is too large | Split the product or accept `string` at that boundary |
| `Type instantiation is excessively deep and possibly infinite.` (TS2589) | Character-by-character recursion on a long string | Split on delimiters, or limit the input |
| `Unused '@ts-expect-error' directive.` (TS2578) | The line stopped failing, so a type became too loose | Restore the strictness, or remove the test if the change was intended |
| `href` prints `/teams/undefined` in your own variant | You built the URL with a template string instead of `href` | Use `href` everywhere; add a lint rule against hand-built paths |
| `Cannot find module './route-types.js'` (typical) | File saved in the wrong folder or misspelled | Check that every file is in `src/` |

## Best practice
Derive types from one runtime table (`as const` plus `satisfies`) instead of writing the same facts twice. Source: TypeScript handbook, [Template Literal Types](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html) and the [`satisfies` operator](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html).

## Production checklist
- [ ] Routes are generated or derived from one table; no hand-built URL strings in components.
- [ ] Every value from a URL, storage or the network is parsed at runtime (`matchRoute`, a schema) before it is trusted.
- [ ] Exhaustive `switch` on your own unions; tolerant fallback on server enums.
- [ ] Cross products of template literal types are bounded (count the members).
- [ ] Every cast at a type/runtime boundary has a runtime test.
- [ ] You measured check time (`--extendedDiagnostics`) after adding recursive string types; record your numbers.

## Going further
- The capstone routers: [capstones/web-react](../../../../capstones/web-react/README.md) (React Router) and [capstones/web-angular](../../../../capstones/web-angular/README.md) (Angular router): compare how each handles route parameters before adding your own `href`.
- TypeScript handbook: [Narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html) (exhaustiveness checking with `never` is documented there).

## Summary
- You wrote template literal types that extract and rewrite string parts.
- You built a route table where building and parsing URLs is checked and derived from one source.
- You made a `switch` exhaustive and explained when exhaustiveness is the wrong policy.
- You listed the failure modes: explosion, drift, slow checking and false confidence.

## Next lesson
03. Library-quality TypeScript (declaration files, strictness flags, API design): package your types so other teams can consume them without surprises.
