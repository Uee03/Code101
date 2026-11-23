# Web Foundations 301, Phase 2: Systems

Source pack for lessons 04 to 06 of **Web Foundations 301, Super Hero to Legendary**. Status: **written, not run** (no compile, install, build or program run has been done; the lesson text and files were checked against each other by a static script only).

| Folder | Lesson | You build |
|---|---|---|
| `04-design-systems-tokens` | Design systems and design tokens | A token pipeline (JSON to CSS custom properties, TypeScript names and a documentation page) with per-theme contrast checks, plus a light/dark demo page. |
| `05-monorepos-build-tooling` | Monorepos and build tooling | An npm workspaces repository with three packages, TypeScript project references, an affected-workspaces script and a CI workflow. |
| `06-openapi-clients` | API clients generated from OpenAPI | A typed client from an OpenAPI 3.1 contract, Zod runtime validation checked against the generated types, a scripted fake server and a contract CI workflow. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project exactly as the lesson builds it. Every file is shown in the lesson, **except** the one generated file named below. |
| `exercise/starter/` | **Overlay files** for the Try it exercise: copy your finished lesson folder first, then copy these files over it (folders keep their structure). |
| `exercise/solution/` | The same files with the exercise solved. Try before opening it. |
| `verify.json` | Machine-checkable steps for a later verification run. |

Generated file not shipped: lesson 06 creates `src/api/schema.d.ts` with `npm run generate` (the lesson shows the kind of output to expect).

## Where to get the optional files
Every file is shown in the lesson, so the pack is optional. Visit https://github.com/Uee03/Code101 and choose **Code > Download ZIP**, then open `Code101-main/source/web/301-super-hero-to-legendary/phase-2-systems/` (the top folder name may differ), or run `git clone https://github.com/Uee03/Code101.git`. Prebuilt archives, if supplied, are `web-301-phase-2-systems.zip` and `web-301-all.zip`.

## Needs
- Node 26.13.1 and npm 11.20.0.
- Lessons 04 and 05: TypeScript 7.0.2 and `@types/node` 26.6.6.
- **Lesson 06: TypeScript 5.9.3, not 7.0.2.** `openapi-typescript` 7.13.0 needs the TypeScript compiler API and declares a peer dependency on TypeScript 5; TypeScript 7.0 has no programmatic API. The lesson explains this and the alternatives. It also installs `openapi-fetch` 0.17.0, `zod` 4.6.7 and `openapi-typescript` 7.13.0.
- Lesson 05 needs Git. The `.github/workflows` files in the lessons only run on GitHub.
- No `package-lock.json` is shipped. `npm install --no-audit --no-fund` creates it; commit it in your own repository (the workflows use `npm ci`, which needs it).

## How to run
Open the lesson's `code` folder in a terminal; the prompt should end in that folder. If PowerShell reports `npm.ps1 cannot be loaded`, use `npm.cmd` and `npx.cmd`.

```powershell
npm install --no-audit --no-fund
```
Then, per lesson:
- **04:** `npm run tokens --silent`, then open `demo/index.html` and `build/tokens.html` in a browser.
- **05:** `npm run build`, `npm test`, `npm start`, and `npm run affected --silent -- packages/tokens/src/index.ts`.
- **06:** `npm run build`, then `npm start`.

## Verification boundary
Nothing has been executed. Expected outputs were derived by reading the code; browser appearance is described from the CSS and code, never claimed seen. Messages marked "typical" are not captured output. Lesson 06 shows an excerpt of the generated types as the *kind* of output to expect, not as a captured file.

Previous: phase 1 (`../phase-1-type-level-typescript/`). Next: phase 3, Production web (`../phase-3-production-web/`).
