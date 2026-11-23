---
track: web
level: 301
phase: 1
phase_name: type-level-typescript
lesson: 01
title: "Advanced generics, conditional and mapped types"
time: 120 min
prerequisites: [web-201.04, web-201.05]
versions: { node: "26.13.1", npm: "11.20.0", typescript: "7.0.2", "@types/node": "26.6.6" }
verified: not yet run
source: source/web/301-super-hero-to-legendary/phase-1-type-level-typescript/01-advanced-generics/
assets: []
---

# 01. Advanced generics, conditional and mapped types

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- write mapped, conditional and recursive types and explain when a conditional type distributes over a union
- test types at compile time with an `Expect<Equal<...>>` helper and `@ts-expect-error` negative tests
- design a generic API (typed event emitter) whose misuse is a compile error, and name the one cast it needs
- decide when type-level code is worth its cost and when a plain interface is the better design

## Recap
1. In Web 201 you used `keyof`, `typeof` and indexed access types. What is the type of `T[K]` when `T = { id: string }` and `K = 'id'`?
   <details><summary>Answer</summary><code>string</code>. The indexed access type looks up the property type.</details>
2. What does `strict: true` change about `null` and `undefined`?
   <details><summary>Answer</summary>They are no longer assignable to every type, so you must narrow them before use.</details>
3. What is the difference between a type and a value in TypeScript?
   <details><summary>Answer</summary>Types are erased at compile time; values exist at runtime. A type-level test therefore costs nothing in the shipped bundle but costs checker time while you build.</details>

## Why it matters
At level 201 you used types to describe data. At level 301 you use them to make whole classes of mistakes impossible: a misspelled event name, a payload with the wrong shape, an exhaustive `switch` that stops compiling when a new case appears. The same tools can also wreck a codebase: types that take seconds to check, error messages nobody can read, and clever code only one person understands. This lesson teaches the tools and the judgement.

## What you will build
A small project with three parts: `types.ts` (a toolbox of generic helpers), `emitter.ts` (a typed event emitter) and `type-tests.ts` (compile-time tests that prove the helpers behave). The program prints three lines. The real output of this lesson is that `tsc --noEmit` prints nothing and exits with code 0.

## Before you start
- Node 26.13.1 and npm 11.20.0 (the versions the capstones in this repository pin). Check with `node --version` and `npm --version`. If `npm` is blocked by PowerShell (`npm.ps1 cannot be loaded`), use `npm.cmd` and `npx.cmd`.
- TypeScript 7.0.2 is installed per project (step 2). It is the native, much faster compiler. It has no programmatic API yet, which matters in lesson 03 and lesson 05.
- Builds on Web 201 lessons [04 Unions, narrowing and utility types](../../201-hero-to-super-hero/phase-2-typescript-in-depth/04-unions-narrowing-utility-types.md) and [05 Generics and type-safe API clients](../../201-hero-to-super-hero/phase-2-typescript-in-depth/05-generics-and-typed-api-clients.md): this lesson goes where they stop (conditional, mapped and recursive types, variance, testing types).
- Time: 90 to 120 minutes for a developer who finished Web 201. Break after step 5.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/301-super-hero-to-legendary/phase-1-type-level-typescript/01-advanced-generics/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- No `package-lock.json` is shipped. The first `npm install` creates it; commit it in your own project.

## Steps

### Step 1. Create the project folder
Where: any folder you keep projects in. Windows PowerShell and macOS/Linux use the same commands.

```text
mkdir web301-01
cd web301-01
mkdir src
```
Expected result: an empty folder `web301-01` containing an empty `src` folder. The text before the prompt `>` or `$` shows the current folder; if you lose it, `cd` back into `web301-01`.

### Step 2. Write package.json
**File: `package.json`**
```json
{
  "name": "web301-01-advanced-generics",
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
Line by line:
- `"private": true` makes `npm publish` refuse to publish this folder by accident.
- `"type": "module"` makes every `.js` file an ES module. The compiled output in `dist` therefore uses `import` and `export`.
- `typecheck` runs the compiler without writing files; `build` writes `dist`; `start` runs the compiled program.
- `engines` documents the runtime. npm only warns on a mismatch unless `engine-strict` is set (lesson 08 sets it).
- The two dependencies are **exact** versions, no `^`. A caret lets a type-checker upgrade change your errors overnight; exact versions plus a lockfile make a build reproducible.

### Step 3. Write tsconfig.json
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
Why each non-obvious line exists:
- `module` and `moduleResolution` `nodenext` follow Node's real ESM rules. Relative imports must end in `.js` (the name of the *output* file), which is why the code below imports `./types.js` from a file called `types.ts`.
- `rootDir: "src"` is required explicitly in TypeScript 7: the default `rootDir` is now the folder holding `tsconfig.json`, so without it the output would land in `dist/src/`.
- `types: ["node"]` is also explicit: TypeScript 7 no longer loads every `@types/*` package automatically (the default is an empty list).
- `strict` is already the default in TypeScript 7; writing it makes the intent visible to readers and to older tools.
- `noUncheckedIndexedAccess` types `array[i]` as `T | undefined`. `exactOptionalPropertyTypes` makes `{ a?: string }` mean "absent or a string", not "absent, undefined or a string". Both catch real bugs and both cost some convenience; lesson 03 weighs them.
- `verbatimModuleSyntax` forces `import type` for type-only imports, so the emitted JavaScript imports exactly what you wrote.
- `skipLibCheck` skips type-checking of `.d.ts` files in `node_modules`. It saves time and hides errors inside dependencies; keep it for applications, think twice for libraries (lesson 03).

### Step 4. Install
```text
npm install --no-audit --no-fund
```
Expected result: npm creates `node_modules` and `package-lock.json`, and prints a summary line such as `added N packages` (the count and timing vary, because TypeScript 7 installs a platform-specific compiler binary). If the folder is not the one holding `package.json`, npm prints an `ENOENT` error mentioning `package.json`: `cd` into the project first.

### Step 5. Write the type toolbox
**File: `src/types.ts`**
```ts
// Compile-time test helpers. They cost nothing at runtime.
export type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends (<T>() => T extends B ? 1 : 2) ? true : false;
export type Expect<T extends true> = T;
export type CanAssign<From, To> = [From] extends [To] ? true : false;

// Mapped type modifiers: remove readonly from every key.
export type Mutable<T> = { -readonly [K in keyof T]: T[K] };

// Flatten an intersection into one readable object type.
export type Prettify<T> = { [K in keyof T]: T[K] } & {};

// Key remapping with a filter: keep only the keys whose value is a function.
export type MethodsOf<T> = {
  [K in keyof T as T[K] extends (...args: never[]) => unknown ? K : never]: T[K];
};

// Recursive conditional type. Functions and arrays are handled before objects.
export type DeepReadonly<T> = T extends (...args: never[]) => unknown
  ? T
  : T extends readonly (infer U)[]
    ? readonly DeepReadonly<U>[]
    : T extends object
      ? { readonly [K in keyof T]: DeepReadonly<T[K]> }
      : T;

// Distributive: a union input is split, mapped member by member, and joined again.
export type ElementOf<T> = T extends readonly (infer U)[] ? U : never;

// Non-distributive: wrapping both sides in a tuple stops the split, so never is testable.
export type IsNever<T> = [T] extends [never] ? true : false;

// Distribute over K to build a union of "at least this key is present" shapes.
export type RequireAtLeastOne<T, K extends keyof T = keyof T> = K extends keyof T
  ? Prettify<Required<Pick<T, K>> & Partial<Omit<T, K>>>
  : never;

// A const type parameter keeps literal types without the caller writing "as const".
export function defineKeys<const T extends readonly string[]>(keys: T): T {
  return keys;
}

// NoInfer stops "value" from widening T: T is inferred from "options" only.
export function oneOf<T extends string>(options: readonly T[], value: NoInfer<T>): T {
  return value;
}

// Explicit variance annotations: out = produces T, in = consumes T.
export interface Producer<out T> {
  get: () => T;
}
export interface Consumer<in T> {
  accept: (value: T) => void;
}
```
Take the pieces one at a time:
- **`Equal`** compares two types by asking whether two generic functions are identical. It is the widely used trick (for example in the type-challenges project) because `A extends B` alone treats `any` and some intersections as equal when they are not. **`Expect<T extends true>`** fails to compile unless `T` is exactly `true`, so a false test is a compile error with the code TS2344.
- **`Mutable`** is a *homomorphic mapped type* (it maps over `keyof T`), which keeps optionality; the `-readonly` modifier removes `readonly`. `+readonly`, `-?` and `+?` work the same way.
- **`Prettify`** forces the editor to show one flat object instead of `A & B & C`. The trailing `& {}` stops TypeScript from simplifying the type away again.
- **`MethodsOf`** uses key remapping (`as`). When the `as` clause yields `never`, the key is dropped. This is how you filter keys in a mapped type.
- **`DeepReadonly`** is recursive. Order matters: functions first (they are objects too), then arrays, then plain objects. `infer U` names the array element type.
- **`ElementOf`** is *distributive*: when `T` is a bare type parameter on the left of `extends`, TypeScript runs the conditional once per union member. `string[] | number[]` becomes `string | number`.
- **`IsNever`** wraps `T` in a tuple. Without the tuple, `T = never` is an empty union, the conditional distributes over zero members and the result is `never`, not `true`. This is the most common conditional-type surprise.
- **`RequireAtLeastOne`** distributes over `K` (the second parameter defaults to all keys) to produce one object shape per key, each with that key required.
- **`defineKeys`** uses a `const` type parameter (TypeScript 5.0) so `defineKeys(['todo', 'done'])` is typed as `readonly ['todo', 'done']` without `as const` at the call site.
- **`oneOf`** uses `NoInfer<T>` (TypeScript 5.4). Without it, TypeScript would infer `T` from both arguments and quietly widen to include `'medium'`. With it, only `options` decides `T`.
- **`Producer<out T>` and `Consumer<in T>`** declare variance. A producer of `'a'` can stand in for a producer of `string` (covariant); a consumer of `string` can stand in for a consumer of `'a'` (contravariant). The annotations are checked against the members and make the checker faster on large generic types.

### Step 6. Write the typed emitter
**File: `src/emitter.ts`**
```ts
type AnyHandler = (payload: never) => void;

export class TypedEmitter<E extends Record<keyof E, unknown>> {
  private readonly handlers = new Map<keyof E, Set<AnyHandler>>();

  on<K extends keyof E>(event: K, handler: (payload: E[K]) => void): () => void {
    const set = this.handlers.get(event) ?? new Set<AnyHandler>();
    set.add(handler);
    this.handlers.set(event, set);
    return () => {
      set.delete(handler);
    };
  }

  emit<K extends keyof E>(event: K, payload: E[K]): void {
    for (const handler of this.handlers.get(event) ?? []) {
      // The one unavoidable cast: the map stores handlers for many events,
      // but the key K ties this handler to E[K]. It is safe because on() enforced it.
      (handler as (payload: E[K]) => void)(payload);
    }
  }
}
```
How it works:
- `E` is a map from event name to payload type. `E extends Record<keyof E, unknown>` accepts both `type` aliases and `interface`s (an `interface` does not satisfy `Record<string, unknown>` because interfaces have no implicit index signature; this form avoids that trap).
- `on<K extends keyof E>` links the event name to its payload: choosing `'task.created'` fixes `K`, and `E[K]` becomes the handler's parameter type.
- The map stores handlers for *different* events side by side, so its value type has to be a handler of "some payload". `(payload: never) => void` is the widest function type: any handler is assignable to it because `never` is assignable to every parameter type.
- In `emit`, the stored handler must be narrowed again. The cast is a lie the compiler cannot check, but the invariant holds because `on` is the only way to add a handler. Keep such casts inside one small class and comment why they are safe; never let them leak into the public signature.
- `on` returns an unsubscribe function, so callers do not need a second `off` method taking the same handler reference.

### Step 7. Write the compile-time tests
**File: `src/type-tests.ts`**
```ts
import { TypedEmitter } from './emitter.js';
import type {
  CanAssign,
  Consumer,
  DeepReadonly,
  ElementOf,
  Equal,
  Expect,
  IsNever,
  MethodsOf,
  Mutable,
  Producer,
  RequireAtLeastOne,
} from './types.js';
import { oneOf } from './types.js';

type Contact = { email?: string; phone?: string };
type Service = { id: string; save: () => void; load: () => number };

// Every entry must be true, otherwise tsc reports an error on that line.
export type TypeTests = [
  Expect<Equal<Mutable<{ readonly a: 1; readonly b: 2 }>, { a: 1; b: 2 }>>,
  Expect<Equal<DeepReadonly<{ a: { b: number[] } }>, { readonly a: { readonly b: readonly number[] } }>>,
  Expect<Equal<ElementOf<string[] | number[]>, string | number>>,
  Expect<Equal<IsNever<never>, true>>,
  Expect<Equal<IsNever<string>, false>>,
  Expect<Equal<MethodsOf<Service>, { save: () => void; load: () => number }>>,
  Expect<Equal<CanAssign<{ email: string }, RequireAtLeastOne<Contact>>, true>>,
  Expect<Equal<CanAssign<{}, RequireAtLeastOne<Contact>>, false>>,
  Expect<Equal<CanAssign<Producer<'a'>, Producer<string>>, true>>,
  Expect<Equal<CanAssign<Producer<string>, Producer<'a'>>, false>>,
  Expect<Equal<CanAssign<Consumer<string>, Consumer<'a'>>, true>>,
  Expect<Equal<CanAssign<Consumer<'a'>, Consumer<string>>, false>>,
];

type Events = {
  'task.created': { id: string; title: string };
  'task.deleted': { id: string };
};

// Negative tests: each directive below must hide exactly one real error.
// If the types ever stop rejecting the line, the directive itself becomes an error.
export function negativeTests(): void {
  const emitter = new TypedEmitter<Events>();
  emitter.on('task.created', (payload) => payload.title);
  // @ts-expect-error task.deleted has no title
  emitter.on('task.deleted', (payload) => payload.title);
  // @ts-expect-error unknown event name
  emitter.emit('task.updated', { id: 'x' });
  // @ts-expect-error title is missing
  emitter.emit('task.created', { id: 'x' });
  // @ts-expect-error 'medium' is not one of the options
  oneOf(['low', 'high'], 'medium');
}
```
How it works:
- `TypeTests` is an exported tuple type so `noUnusedLocals` does not complain, and so a failing entry points at its own line.
- Types that are easier to reason about as "can this value go there?" use `CanAssign` (a one-directional assignability check). `Equal` is stricter and sometimes fails on types that print identically; when that happens, prefer `CanAssign` in both directions rather than weakening to `any`.
- `@ts-expect-error` is the opposite of `@ts-ignore`: the line **must** produce an error. If your types later become too loose and the error disappears, the directive itself fails with the message `Unused '@ts-expect-error' directive.` (code TS2578). Never use `@ts-ignore` in a test.
- `negativeTests` is an exported function that nobody calls. It exists only to give the directives a place to live; `tsc` checks its body.

### Step 8. Write the runnable program
**File: `src/index.ts`**
```ts
import { TypedEmitter } from './emitter.js';
import { defineKeys, oneOf } from './types.js';

interface TaskEvents {
  created: { id: string; title: string };
  completed: { id: string; by: string };
}

const emitter = new TypedEmitter<TaskEvents>();
const log: string[] = [];

const stopListening = emitter.on('created', (payload) => log.push(`created ${payload.title}`));
emitter.on('completed', (payload) => log.push(`completed ${payload.id} by ${payload.by}`));

emitter.emit('created', { id: 't1', title: 'Write ADR' });
emitter.emit('completed', { id: 't1', by: 'ada' });
stopListening();
emitter.emit('created', { id: 't2', title: 'Never logged' });

console.log(log.join('\n'));

const statuses = defineKeys(['todo', 'done']);
const picked = oneOf(statuses, 'done');
console.log(`${statuses.length} statuses, picked ${picked}`);
```
Note that `TaskEvents` is an `interface`, which works because of the `Record<keyof E, unknown>` constraint. The `created` handler returns a number (the result of `push`); a handler type that returns `void` accepts that, because a `void` return type means "the caller ignores the result".

## Run it
**Predict first** (write your answers down before running):
1. Does `npx tsc --noEmit` print anything? What exit code do you expect?
2. How many lines does `npm start` print, and does `Never logged` appear?
3. What would happen to `type-tests.ts` if you deleted the `-readonly` from `Mutable`?

```text
npx tsc --noEmit
```
Expected output (nothing; the exit code is 0). Your shell prompt simply returns:
```text

```
Then build and run:
```text
npm run build
npm start
```
Expected output:
```text
created Write ADR
completed t1 by ada
2 statuses, picked done
```
Answers to the predictions: (1) nothing, exit code 0; (2) three lines, and `Never logged` does not appear because `stopListening()` removed the handler first; (3) the first entry of `TypeTests` fails with the typical message `Type 'false' does not satisfy the constraint 'true'.` (TS2344) on that line. Try it: change `-readonly` to `readonly`, run `npx tsc --noEmit`, read the error, then undo it.

## How it works
The compiler does three different jobs on this code:
1. **Inference** decides `K` and `T` at every call. `emitter.on('task.created', ...)` infers `K = 'task.created'` from the literal; the handler's `payload` is then contextually typed as `E['task.created']`.
2. **Assignability** decides whether an argument fits. Variance (`in`/`out`) is the rule behind "a producer of a narrower type is acceptable".
3. **Type-level evaluation** runs your conditional and mapped types. This is real computation: each instantiation is cached, but a recursive type over a large object can be expensive.

**Common misconception:** "A conditional type is an `if` at runtime." It is evaluated by the compiler and erased. Nothing of `Equal` or `DeepReadonly` is in `dist/`. Open `dist/types.js` after the build to see only the two functions.

**Why this, not that (ADR style)**

| Decision | Chosen | Alternative | Why |
|---|---|---|---|
| Event typing | `TypedEmitter<E>` with an event map | `string` event names and `any` payloads | A rename of one event becomes a compile error at every call site |
| Type tests | `Expect<Equal<>>` inside `tsc` | A test library for types | Zero dependencies and the editor shows the failure on the line; a library is worth it only if you need many reusable assertions |
| Filtering keys | `as` clause in a mapped type | `Pick<T, FunctionKeys<T>>` with a helper | One type instead of two, and the result stays homomorphic |
| Handler storage | One cast inside the class | `any` in the map | The cast is local and documented; `any` would leak into callers |

**Failure modes you will meet in real code**
- **Excessively deep types.** A recursive type that never bottoms out, or one applied to a huge type, stops with the typical message `Type instantiation is excessively deep and possibly infinite.` (TS2589). Fix by adding a base case, limiting depth with a counter tuple, or replacing the recursion with a plain interface.
- **Unreadable errors.** The more machinery sits between the user and the error, the longer the message. Wrap public types in `Prettify` and keep helpers in the signature you export short.
- **Slow editors.** Measure instead of guessing: run `npx tsc --noEmit --extendedDiagnostics` and compare *Check time* before and after a change; `npx tsc --noEmit --generateTrace trace-out` writes a trace you can open in the browser tools (see the TypeScript performance wiki page linked below). Write down your own numbers.
- **Distribution surprises.** A bare `T` on the left of `extends` distributes; `[T]` does not. When a conditional "returns `never` for `never`", this is the cause.
- **Interfaces and index signatures.** `interface X {...}` does not satisfy `Record<string, unknown>`. Constrain with `Record<keyof E, unknown>` as above.

**When not to use type-level programming**
- When a plain `interface` and a `switch` say the same thing. Clever types are code you must maintain, review and teach.
- On hot paths of the compiler: types over thousands of keys, deeply recursive utilities in a shared library that every package imports.
- When the runtime needs the same information. A type cannot validate data from the network (lesson 06 uses a runtime schema for that). Do not build a type-level parser when a runtime parser plus `z.infer`-style derivation exists.
- When a teammate cannot read the error. If nobody can explain the message in a code review, the abstraction costs more than the bug it prevents.

## Try it
Rung 1 (guided), rung 2 (change) and rung 3 (stretch) all use the exercise folder. Copy your finished project to `web301-01-try`, then add one file.

1. **Guided.** Create `src/exercise.ts` with the starter below. Two types are wrong on purpose. Run `npx tsc --noEmit` and read the two errors. Replace the placeholders so `PickByValue` keeps only keys whose value type fits `V`, and `DeepPartial` makes every property optional at every depth while leaving functions and arrays alone. The tests at the bottom of the file must compile.
2. **Change.** Add a third test: `DeepPartial` of a type containing a function-valued property must keep that property's function type unchanged (only the `?` is added at the property level). Predict whether `Equal` will pass before you run it.
3. **Stretch (no single answer).** Design an `Opaque<T, Name>` "branded" type for ids so a `TeamId` cannot be passed where a `TaskId` is expected. Decide, and write down in three sentences, who creates a branded value (a parse function? a cast at the boundary?) and what the cost is for the people who have to use it.

**Starter file (`exercise/starter/src/exercise.ts`)**
```ts
import type { Equal, Expect } from './types.js';

// TODO 1: keep only the keys of T whose value type is assignable to V.
// This placeholder is wrong on purpose so the type tests below fail until you replace it.
export type PickByValue<T, V> = T extends V ? T : never;

// TODO 2: make every property optional at every depth. Functions and arrays stay as they are.
// This placeholder is shallow and wrong on purpose.
export type DeepPartial<T> = Partial<T>;

type Settings = {
  theme: 'light' | 'dark';
  pageSize: number;
  filters: { status: string[]; owner: string };
};

export type ExerciseTests = [
  Expect<Equal<PickByValue<{ a: string; b: number; c: string }, string>, { a: string; c: string }>>,
  Expect<
    Equal<
      DeepPartial<Settings>,
      { theme?: 'light' | 'dark'; pageSize?: number; filters?: { status?: string[]; owner?: string } }
    >
  >,
];
```

<details><summary>Solution</summary>

**File: `exercise/solution/src/exercise.ts`**
```ts
import type { Equal, Expect } from './types.js';

export type PickByValue<T, V> = {
  [K in keyof T as T[K] extends V ? K : never]: T[K];
};

export type DeepPartial<T> = T extends (...args: never[]) => unknown
  ? T
  : T extends readonly unknown[]
    ? T
    : T extends object
      ? { [K in keyof T]?: DeepPartial<T[K]> }
      : T;

type Settings = {
  theme: 'light' | 'dark';
  pageSize: number;
  filters: { status: string[]; owner: string };
};

export type ExerciseTests = [
  Expect<Equal<PickByValue<{ a: string; b: number; c: string }, string>, { a: string; c: string }>>,
  Expect<
    Equal<
      DeepPartial<Settings>,
      { theme?: 'light' | 'dark'; pageSize?: number; filters?: { status?: string[]; owner?: string } }
    >
  >,
];
```
`PickByValue` reuses the key-remapping filter from `MethodsOf`. `DeepPartial` is `DeepReadonly` with the modifier changed: check functions first, then arrays (left whole on purpose: partial arrays are rarely what you want), then objects. For the stretch: a common answer is `type Brand<T, Name extends string> = T & { readonly __brand: Name }` created only by a `parseTaskId(value: string): TaskId` function that validates; the cost is that every test and fixture must go through the parser.

</details>

## Check yourself
1. What does `ElementOf<string[] | number[]>` evaluate to, and which property of conditional types causes it? <details><summary>Answer</summary><code>string | number</code>. The conditional type distributes over the union because <code>T</code> is a naked type parameter.</details>
2. Why does `IsNever<T>` wrap both sides in `[ ]`? <details><summary>Answer</summary>To stop distribution. A bare <code>never</code> is an empty union, so the distributive form returns <code>never</code> instead of <code>true</code>.</details>
3. The line `// @ts-expect-error` stays in the file but the error beneath it disappears. What does <code>tsc</code> report and why is that useful? <details><summary>Answer</summary>TS2578, <code>Unused '@ts-expect-error' directive.</code> It tells you your types became too permissive.</details>
4. Find the bug: `oneOf<T extends string>(options: readonly T[], value: T): T`. What does `oneOf(['low', 'high'], 'medium')` do? <details><summary>Answer</summary>It compiles: <code>T</code> is inferred from both arguments as <code>'low' | 'high' | 'medium'</code>. <code>NoInfer</code> on <code>value</code> fixes it.</details>
5. Why is the cast in `emit` acceptable, and what makes it unacceptable? <details><summary>Answer</summary>Acceptable because <code>on</code> is the only writer and it enforces the key-to-payload link. It would be unacceptable if a second method could add handlers without that link, or if the cast appeared in a public signature.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Cannot find module './types.js' or its corresponding type declarations.` (typical) | File missing, misspelled or saved in the wrong folder | Check that `src/types.ts` exists and that you ran the command in the project folder |
| `Relative import paths need explicit file extensions in ECMAScript imports when '--moduleResolution' is 'node16' or 'nodenext'.` (typical) | Import written as `./types` | Write `./types.js`: the extension of the *output* file |
| `Type 'false' does not satisfy the constraint 'true'.` (TS2344) | A type test failed | Read which entry in `TypeTests` the error points at; either the helper or the expectation is wrong |
| `Unused '@ts-expect-error' directive.` (TS2578) | The line beneath no longer errors | Tighten the type, or delete the test if the behaviour change was intended |
| `Type instantiation is excessively deep and possibly infinite.` (TS2589) | Recursive type without a base case or applied to a very large type | Add a base case or a depth counter, or simplify |
| `npm.ps1 cannot be loaded` (PowerShell policy) | Execution policy blocks the npm script shim | Use `npm.cmd` and `npx.cmd` instead of changing the policy |
| `npx tsc` offers to install a package | You are outside the folder with `package.json` | Answer no, `cd` into the project and run `npm install` first |

## Best practice
Test types the way you test code: positive tests for what must compile, negative tests (`@ts-expect-error`) for what must not, and a budget for check time. Source: TypeScript handbook, [Conditional Types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html) and [Mapped Types](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html).

## Production checklist
- [ ] Generic helpers live in one module with tests (positive and negative), not copied into feature code.
- [ ] Every cast inside a generic implementation has a comment saying which invariant makes it safe.
- [ ] You measured check time with `--extendedDiagnostics` before and after adding a heavy type (record your numbers, do not guess).
- [ ] Public types are wrapped in `Prettify` where error messages matter.
- [ ] `ts-expect-error` is used in tests; `ts-ignore` is not.
- [ ] No type-level code that duplicates a runtime validator.

## Going further
- TypeScript handbook: [Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html), [Creating Types from Types](https://www.typescriptlang.org/docs/handbook/2/types-from-types.html), [Variance annotations in the 4.7 release notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-7.html).
- Performance: the TypeScript wiki page *Performance* explains `--extendedDiagnostics` and `--generateTrace`.
- Capstone link: the generated API client in [capstones/web-react/tutorials/phase-1-setup/01-create-app.md](../../../../capstones/web-react/tutorials/phase-1-setup/01-create-app.md) relies on exactly these mapped types; lesson 06 shows why.

## Summary
- You wrote mapped, conditional and recursive types and explained distribution.
- You tested types at compile time with positive and negative tests.
- You built a typed emitter and isolated its single cast.
- You listed when type-level code is not worth its cost.

## Next lesson
02. Template literal types, type-safe routing and exhaustive checks: use string types to make route names and parameters impossible to get wrong.
