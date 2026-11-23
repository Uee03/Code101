# Web Foundations 101, Phase 3: Typescript And Project

Source pack for lessons 09 to 12. Each lesson is verified by smoke checks on Windows 11; browser appearance and actions are manual learner checks.

| Folder | Lesson | You build |
|---|---|---|
| `09-dom-and-events` | The DOM and events | A button-driven counter starting at Clicks: 0 and updating on each press. |
| `10-typescript-first-steps` | TypeScript first steps | A profile with string, number and boolean fields, compiled to JavaScript and run in Node. Deliberately trigger and repair a real type error. |
| `11-typescript-in-the-browser` | TypeScript in the browser | A module page that fetches a local mock profile and shows Meet Ada, a biography and three skills. |
| `12-personal-page-and-todos` | Project: personal landing page + todo list | A responsive personal landing page and todo list: add, complete, undo and remove tasks; keep changes in this browser. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| code/ | Finished runnable files matching the lesson. Every editable file is shown in the tutorial; compare here if useful. |
| exercise/starter/ | Working baseline for the Try it change. |
| exercise/solution/ | Full exercise answer; try before opening it. |

## Where to get the optional files
Every editable file and starter is in the matching lesson, so the pack is optional. Visit https://github.com/Uee03/Code101 and choose **Code > Download ZIP**, then open `Code101-main/source/web/101-zero-to-hero/phase-3-typescript-and-project/` in the extracted repository (the top folder name may differ). Or use `git clone https://github.com/Uee03/Code101.git` if Git is already installed.

If your instructor supplies prebuilt archives, they are named `web-101-phase-3-typescript-and-project.zip` and `web-101-all.zip`. The all archive contains **three phase folders**, not three nested zip files. In the repository's dist/packs these may be present locally but are not required downloads; no pack-building command is needed to follow a lesson.

## Unzip and open
1. Windows: right-click zip > Extract All > Extract. macOS: double-click zip. Linux: right-click > Extract Here.
2. Open the extracted phase directory, then the chosen lesson, then code in VS Code via File > Open Folder. Do not open the zip preview.
3. Or create Home/code101/lessonNN and write the files from the matching tutorial. For the exercise, copy your completed lessonNN folder beside itself and rename the copy lessonNN-try. Alternatively copy the starter folder and rename the copy lessonNN-try; do not put starter inside a second folder.
4. Save every edited file (Ctrl+S; macOS Command+S). An editor-tab dot means unsaved.

## Needs
- A current Edge/Chrome/Firefox and VS Code from lesson 01.
- Node 26.13.1 LTS and npm 11.20.0 (installation in lesson 08; repeated in lesson 10). Official pinned archive: https://nodejs.org/en/download/archive/v26.13.1
- TypeScript 7.0.2, installed per project using the full package.json/lockfile. No global TypeScript. Official release: https://github.com/microsoft/TypeScript/releases/tag/v7.0.2

## How to run
For JavaScript (09), open **09-dom-and-events/code/index.html** in the browser. Press F12 (macOS Command+Option+I), choose **Console**, and reload to see the starting message. Try the button with mouse, Enter and Space; watch the page count. No terminal run is needed for this lesson.

For TypeScript (10-12), open the desired code folder in VS Code; Terminal > New Terminal starts there. Run these identical commands on Windows/macOS/Linux (if PowerShell blocks npm.ps1, use npm.cmd/npx.cmd for all commands):

**Folder: selected lesson/code**
```powershell
npm install --no-audit --no-fund
npx tsc
node dist/app.js
```
If npx offers to install tsc, answer n: return to the code folder with package.json and install its dependencies first.

Expected: install status (counts/timing vary), silent compilation, then the lesson's one-line Node helper output. Stop on compiler error; fix src, save, recompile. dist and node_modules are generated, not shipped.

Lesson 10 runs only in Node. For 11/12, install the VS Code Live Server extension by Ritwick Dey, right-click index.html > Open with Live Server. Use the actual HTTP address (normally http://127.0.0.1:5500/index.html), not file:///. The lessons show every server action and expected browser result. Click the displayed Port label to stop. For 12 keep the same protocol/host/port so localStorage can restore tasks. It is not an account or backup.

## Verification boundary
Lessons are checked by temporary local-file serving and, where applicable, one program run or compilation. No screenshots, click automation or test suites are claimed; temporary servers are stopped. The track state records the smoke result; browser appearance and interaction still need a human check.

Next: none. Level 101 concludes with the personal-page project.

## Time planning
Lessons 09 and 11 allow 90 minutes, lesson 10 allows 90-120, and project lesson 12 allows 120-180. Each has a marked break for two sittings.
