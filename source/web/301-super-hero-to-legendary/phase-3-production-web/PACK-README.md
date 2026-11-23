# Web Foundations 301, Phase 3: Production web

Source pack for lessons 07 to 09 of **Web Foundations 301, Super Hero to Legendary**. Status: **written, not run** (no compile, install, build, server start, browser session or program run has been done; the lesson text and files were checked against each other by a static script only).

| Folder | Lesson | You build |
|---|---|---|
| `07-performance-budgets` | Performance budgets and browser internals | A Vite and TypeScript page with a blocking and a yielding job, long-animation-frame and Web Vitals measurement, a gzip size budget script, a Lighthouse budget file and a CI workflow. |
| `08-security-hardening` | Security hardening | A typed CSP builder and linter, security headers, a `__Host-` cookie serializer, a local "security lab" server and page (CSP and Trusted Types), a package policy check, `.npmrc`, a security workflow and a Dependabot configuration. |
| `09-micro-frontends-release-readiness` | Micro-frontends, release strategy and a production readiness checklist | A remote loader with contract check and timeout, a sticky rollout flag with a kill switch, a release readiness checker, the human checklist, a staged release workflow and a pull request review exercise. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project exactly as the lesson builds it. Every file is shown in the lesson. |
| `exercise/starter/` | **Overlay files** for the Try it exercise: copy your finished lesson folder first, then copy these files over it (folders keep their structure). Lesson 09's starter is a review exercise (documents and data, no code). |
| `exercise/solution/` | The same files with the exercise solved. Try before opening it. |
| `verify.json` | Machine-checkable steps for a later verification run. |

## Where to get the optional files
Every file is shown in the lesson, so the pack is optional. Visit https://github.com/Uee03/Code101 and choose **Code > Download ZIP**, then open `Code101-main/source/web/301-super-hero-to-legendary/phase-3-production-web/` (the top folder name may differ), or run `git clone https://github.com/Uee03/Code101.git`. Prebuilt archives, if supplied, are `web-301-phase-3-production-web.zip` and `web-301-all.zip`.

## Needs
- Node 26.13.1 and npm 11.20.0; TypeScript 7.0.2.
- Lesson 07: Vite 8.3.8, `web-vitals` 6.2.3, Chrome or Edge (DevTools and Lighthouse). Lighthouse 13.6.0 is run with `npx`, not installed.
- Lesson 08: a browser with Trusted Types support (all current major browsers); the server listens on `127.0.0.1:8301` only.
- Lesson 09: nothing beyond Node.
- No `package-lock.json` is shipped. `npm install --no-audit --no-fund` creates it; commit it in your own repository (the workflows use `npm ci`).

## How to run
Open the lesson's `code` folder in a terminal; the prompt should end in that folder. If PowerShell reports `npm.ps1 cannot be loaded`, use `npm.cmd` and `npx.cmd`.

```powershell
npm install --no-audit --no-fund
```
Then, per lesson:
- **07:** `npm run build`, `npm run budget`, `npm run preview` (open the printed address), then follow the measurement steps in the lesson.
- **08:** `npm run policy --silent`, `npm run check:packages --silent`, and `npm run serve` (open `http://127.0.0.1:8301/`).
- **09:** `npm run demo --silent` and `npm run check --silent` (the second exits with code 1 on purpose: the sample release has a failing blocker).

## Verification boundary
Nothing has been executed. No performance numbers are given anywhere: you measure your own. Browser behaviour in lessons 04, 07 and 08 is described from the code, not from having seen it. The release workflows are outlines: their deployment steps print a message because the real command depends on your platform.

Previous: phase 2 (`../phase-2-systems/`). This is the last phase of the level.
