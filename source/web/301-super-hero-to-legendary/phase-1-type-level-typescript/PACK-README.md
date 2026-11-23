# Web Foundations 301, Phase 1: Type-level TypeScript

Source pack for lessons 01 to 03 of **Web Foundations 301, Super Hero to Legendary**. Status: **written, not run** (no compile, install or program run has been done; the lesson text and files were checked against each other by a static script only).

| Folder | Lesson | You build |
|---|---|---|
| `01-advanced-generics` | Advanced generics, conditional and mapped types | A toolbox of generic helpers, compile-time tests with `Expect<Equal<>>` and `@ts-expect-error`, and a typed event emitter. |
| `02-template-literal-types` | Template literal types, type-safe routing and exhaustive checks | A route table that types `href()` and parses URLs, an exhaustive `switch`, a tolerant label function and a typed key rewriter. |
| `03-library-quality-typescript` | Library-quality TypeScript | A small `Result` library with an `exports` map, `isolatedDeclarations`, a consumer type test in two configurations, an API surface snapshot and an `attw` check. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project exactly as the lesson builds it. Every file is shown in the lesson. |
| `exercise/starter/` | **Overlay files** for the Try it exercise: copy your finished lesson folder first, then copy these files over it. |
| `exercise/solution/` | The same files with the exercise solved (and any files the solution adds or changes). Try before opening it. |
| `verify.json` | Machine-checkable steps for a later verification run (not needed to follow the lesson). |

## Where to get the optional files
Every file is shown in the lesson, so the pack is optional. Visit https://github.com/Uee03/Code101 and choose **Code > Download ZIP**, then open `Code101-main/source/web/301-super-hero-to-legendary/phase-1-type-level-typescript/` (the top folder name may differ), or run `git clone https://github.com/Uee03/Code101.git`. Prebuilt archives, if your instructor supplies them, are `web-301-phase-1-type-level-typescript.zip` and `web-301-all.zip`; the all archive contains the three phase folders.

## Needs
- Node 26.13.1 and npm 11.20.0 (the versions the capstones pin).
- TypeScript **7.0.2** (the native compiler), installed per project. No global TypeScript.
- Lesson 03 also installs `@arethetypeswrong/cli` 0.18.5 as a dev dependency.
- No `package-lock.json` is shipped: `npm install --no-audit --no-fund` in the lesson folder creates it (commit it in your own repository).

## How to run (every lesson of this phase)
Open the lesson's `code` folder (or your own copy) in a terminal; the prompt should end in that folder. If PowerShell reports `npm.ps1 cannot be loaded`, use `npm.cmd` and `npx.cmd` instead.

```powershell
npm install --no-audit --no-fund
npx tsc --noEmit
npm run build
npm start
```
Lessons 01 and 02 print their output with `npm start`; `npx tsc --noEmit` must print nothing (that is the type tests passing). Lesson 03 uses `npm run demo`, `npm run check:consumer`, `npm run check:surface` and `npm run check:package` instead of `npm start`; see the lesson for the expected output of each.

## Verification boundary
Nothing has been executed. Expected outputs were derived by reading the code; messages marked "typical" come from knowledge of TypeScript and Node, not from a captured run. If your tool prints something different, trust your tool and report it.

Next: phase 2, Systems (`../phase-2-systems/`).
