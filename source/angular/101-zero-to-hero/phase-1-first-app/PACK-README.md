# Angular 101, Phase 1: First app

Source pack for lessons 01 to 04. **Status: written, not yet run.** The code was prepared by reading the code and the official documentation; no install, build or browser check has been executed (see `tutorials/angular/_STATE.md`). If something behaves differently from the lesson, trust what you see and report it.

| Folder | Lesson | You build |
|--------|--------|-----------|
| `01-install-node-and-first-app` | Install Node and the Angular CLI, create and run your first app | A project created with `npx` and the CLI, running on port 4200 |
| `02-project-tour-and-standalone-components` | Project tour and standalone components | A `Greeting` component used by `App` |
| `03-templates-and-data-binding` | Templates and data binding | Interpolation, property, attribute, class and event bindings, first signals |
| `04-control-flow-and-signals-basics` | Control flow and signals basics | A filterable task list with `@if`, `@for`, `@switch`, `computed` |

## Inside each lesson folder
| Folder or file | What it is |
|----------------|------------|
| `code/` | The whole project at the end of the lesson. No `package-lock.json`: `npm install` creates it. |
| `exercise/starter/` | **Overlay files** for the Try it exercise (copy them over your project, same relative paths). |
| `exercise/solution/` | The same files, completed. Try the exercise first. |
| `verify.json` | How the lesson would be checked later (install, build). Not run yet. |

## Needs
Node 22.22.3, 24.15 or 26.x (course target 26.13.1), npm 11.20.0, a current browser. Angular 22.3.0, TypeScript 6.0.3, RxJS 7.8.2, pinned exactly. The Angular CLI is not installed globally: lesson 01 runs it with `npx -p @angular/cli@22.3.0 ng`. Windows PowerShell: use `npm.cmd` if `npm.ps1` is blocked.

## How to run
In the project folder: `npm install --no-audit --no-fund`, then `npm start` and open http://localhost:4200/. `npm run build` makes a production build.

## Where to get the optional files
https://github.com/Uee03/Code101, **Code > Download ZIP**, then `source/angular/101-zero-to-hero/phase-1-first-app/`; or `git clone https://github.com/Uee03/Code101.git`. Prebuilt archives, if supplied, are `angular-101-phase-1-first-app.zip` and `angular-101-all.zip`.

Next: Phase 2, building (lessons 05 to 08).
