# Web Foundations 201, Phase 2: TypeScript in depth

Source pack for lessons 04 to 06. **Status: written, not yet run.** The code was prepared by reading the code and the official documentation; no compile, build or run has been executed yet (see `tutorials/web/_STATE-201.md`). If a command behaves differently from the lesson, trust your tool's real output and report it.

| Folder | Lesson | You build |
|---|---|---|
| `04-unions-narrowing-utility-types` | Unions, narrowing and utility types | A Node program applying task events with a discriminated union, `assertNever`, type guards and utility types |
| `05-generics-and-typed-api-clients` | Generics and type-safe API clients | A generic `ApiClient` with typed endpoints, validating parsers and `Result<T>`, driven by a fake network |
| `06-modules-vite-and-dev-workflow` | Modules, Vite and the dev workflow | A hand-written Vite and TypeScript project ("Release notes") with a complete `vite.config.ts`, `.env` handling and a lazily loaded module |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | Finished, runnable project. No `package-lock.json`: `npm install` creates it. |
| `exercise/starter/` | **Overlay files** for the Try it exercise (only the files the exercise changes). |
| `exercise/solution/` | The same files, completed. Try the exercise first. |

**How the exercise overlay works.** Copy `code/` (without `node_modules` and `dist`) to a new folder such as `lesson04-try`, run `npm install` there, then copy the files from `exercise/starter/` over the copy, keeping the same relative paths (`src/app.ts` replaces `src/app.ts`). Do not edit `code/` itself.

## Where to get the optional files
Every file and starter is shown in the lesson, so the pack is optional. Visit https://github.com/Uee03/Code101 and choose **Code > Download ZIP**, then open `source/web/201-hero-to-super-hero/phase-2-typescript-in-depth/`. Or run `git clone https://github.com/Uee03/Code101.git`. Prebuilt archives, if supplied, are `web-201-phase-2-typescript-in-depth.zip` and `web-201-all.zip`.

## Needs
- Node 22.12 or newer (the course target is Node 26.13.1) with npm 11.20.0, from Web 101 lesson 08. Check with `node --version` and `npm --version`.
- Exact tool versions in the manifests: TypeScript 7.0.2; lesson 06 also Vite 8.3.8 and `@types/node` 26.6.6. Versions were taken from the npm registry on 2026-11-23.
- Windows PowerShell: if `npm.ps1 cannot be loaded because running scripts is disabled on this system`, use `npm.cmd` and `npx.cmd` instead of changing the execution policy.

## How to run
**Lessons 04 and 05** (Node programs). Run in the lesson folder (`code/` or your copy):
```powershell
npm install --no-audit --no-fund
npx tsc
node dist/app.js
```
If `npx` asks to install a package named `tsc`, answer `n`: you are in the wrong folder or the install has not run.

**Lesson 06** (Vite project):
```powershell
npm install --no-audit --no-fund
npm run typecheck
npm run dev
```
Then open the `Local:` address Vite prints (configured as `http://localhost:5173/`). `npm run build` type-checks and builds to `dist/`; `npm run preview` serves the build on `http://localhost:4173/`.

## Verification boundary
`verify.json` files describe how each lesson would be checked (install, compile, run, build); they have not been run. Expected outputs of lessons 04 and 05 were derived by reading the code. Vite's own banner text is described as typical output.

## Time planning
Lessons 04 and 05 take about 50 to 55 minutes each. Lesson 06 takes about 60 minutes in two sittings.

Next: Phase 3, app patterns (lessons 07 to 09).
