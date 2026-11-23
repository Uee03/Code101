# Web Foundations 101, Phase 2: Layout And Javascript

Source pack for lessons 05 to 08. Each lesson is verified by smoke checks on Windows 11; browser appearance and actions are manual learner checks.

| Folder | Lesson | You build |
|---|---|---|
| `05-box-model-and-spacing` | Box model and spacing | One centered, blue-bordered card with predictable outer width and comfortable spacing. |
| `06-flexbox` | Flexbox | Three tool cards that share a row on a wide screen and wrap on narrow screens. |
| `07-grid-and-responsive-design` | Grid and responsive design | An interests grid: one column on small screens and three equal columns on wider screens. |
| `08-javascript-basics` | JavaScript basics | A study plan running in browser Console and Node: a greeting, a decision, three topics and a session count. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| code/ | Finished runnable files matching the lesson. Every editable file is shown in the tutorial; compare here if useful. |
| exercise/starter/ | Working baseline for the Try it change. |
| exercise/solution/ | Full exercise answer; try before opening it. |

## Where to get the optional files
Every editable file and starter is in the matching lesson, so the pack is optional. Visit https://github.com/Uee03/Code101 and choose **Code > Download ZIP**, then open `Code101-main/source/web/101-zero-to-hero/phase-2-layout-and-javascript/` in the extracted repository (the top folder name may differ). Or use `git clone https://github.com/Uee03/Code101.git` if Git is already installed.

If your instructor supplies prebuilt archives, they are named `web-101-phase-2-layout-and-javascript.zip` and `web-101-all.zip`. The all archive contains **three phase folders**, not three nested zip files. In the repository's dist/packs these may be present locally but are not required downloads; no pack-building command is needed to follow a lesson.

## Unzip and open
1. Windows: right-click zip > Extract All > Extract. macOS: double-click zip. Linux: right-click > Extract Here.
2. Open the extracted phase directory, then the chosen lesson, then code in VS Code via File > Open Folder. Do not open the zip preview.
3. Or create Home/code101/lessonNN and write the files from the matching tutorial. For the exercise, copy your completed lessonNN folder beside itself and rename the copy lessonNN-try. Alternatively copy the starter folder and rename the copy lessonNN-try; do not put starter inside a second folder.
4. Save every edited file (Ctrl+S; macOS Command+S). An editor-tab dot means unsaved.

## Needs
- A current Edge/Chrome/Firefox and VS Code from lesson 01.
- Node 26.13.1 LTS and npm 11.20.0 (installation in lesson 08; repeated in lesson 10). Official pinned archive: https://nodejs.org/en/download/archive/v26.13.1

## How to run
For HTML/CSS (01-07), open code/index.html with your browser from the file manager. Save changes and reload (Ctrl+R; macOS Command+R). No terminal. Live Server is optional.

For JavaScript (08), open index.html and developer tools Console (F12; macOS Command+Option+I). In VS Code Terminal > New Terminal, make sure the current folder is the code folder containing the file. From the extracted phase directory, use the commands below. Windows Set-Location and macOS/Linux cd differ; node commands are identical.

**Folder: extracted phase directory (Windows PowerShell)**
```powershell
Set-Location "08-javascript-basics\code"
node basics.js
```

**Folder: extracted phase directory (macOS/Linux)**
```bash
cd "08-javascript-basics/code"
node basics.js
```

Expected output is in each lesson. Linux users of the extracted Node binary must set its PATH as shown in lesson 08 for every new terminal.


## Verification boundary
Lessons are checked by temporary local-file serving and, where applicable, one program run or compilation. No screenshots, click automation or test suites are claimed; temporary servers are stopped. The track state records the smoke result; browser appearance and interaction still need a human check.

Next: Phase 3, typescript and project.

## Time planning
Lessons 05-07 allow 40-45 minutes; lesson 08 allows 90 minutes in two sittings with a marked break.
