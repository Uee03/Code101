# Web Foundations 101, Phase 1: Html And Css

Source pack for lessons 01 to 04. Each lesson is verified by smoke checks on Windows 11; browser appearance and actions are manual learner checks.

| Folder | Lesson | You build |
|---|---|---|
| `01-first-html-page` | How the web works + your first HTML page | Your first page: a browser tab called My first page, a large Hello, web! heading and one sentence underneath. |
| `02-text-links-images-lists` | Text, links, images, lists | A learning shelf with a heading hierarchy, an MDN link, a search icon, a bullet list and a numbered routine. |
| `03-forms-and-semantic-html` | Forms and semantic HTML | A study-club form with labelled name, email and number fields between a header, main area and footer. This is a local demo, not a registration service. |
| `04-css-basics` | CSS basics | A profile with a pale background, readable font, green paragraph and blue welcome message. Competing rules reveal the cascade. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| code/ | Finished runnable files matching the lesson. Every editable file is shown in the tutorial; compare here if useful. |
| exercise/starter/ | Working baseline for the Try it change. |
| exercise/solution/ | Full exercise answer; try before opening it. |
| assets/ (lesson 02, phase 1 only) | Course CC0 icon; code/assets also holds it for direct runs. |

## Where to get the optional files
Every editable file and starter is in the matching lesson, so the pack is optional. Visit https://github.com/Uee03/Code101 and choose **Code > Download ZIP**, then open `Code101-main/source/web/101-zero-to-hero/phase-1-html-and-css/` in the extracted repository (the top folder name may differ). Or use `git clone https://github.com/Uee03/Code101.git` if Git is already installed.

If your instructor supplies prebuilt archives, they are named `web-101-phase-1-html-and-css.zip` and `web-101-all.zip`. The all archive contains **three phase folders**, not three nested zip files. In the repository's dist/packs these may be present locally but are not required downloads; no pack-building command is needed to follow a lesson.

## Unzip and open
1. Windows: right-click zip > Extract All > Extract. macOS: double-click zip. Linux: right-click > Extract Here.
2. Open the extracted phase directory, then the chosen lesson, then code in VS Code via File > Open Folder. Do not open the zip preview.
3. Or create Home/code101/lessonNN and write the files from the matching tutorial. For the exercise, copy your completed lessonNN folder beside itself and rename the copy lessonNN-try. Alternatively copy the starter folder and rename the copy lessonNN-try; do not put starter inside a second folder.
4. Save every edited file (Ctrl+S; macOS Command+S). An editor-tab dot means unsaved.

## Needs
- A current Edge/Chrome/Firefox and VS Code from lesson 01.

## How to run
For HTML/CSS (01-07), open code/index.html with your browser from the file manager. Save changes and reload (Ctrl+R; macOS Command+R). No terminal. Live Server is optional. Copy the lesson 02 search.svg as shown in that lesson if making your own folder; finished code already includes it. The phase 1 pack's LICENSE-ICONS-CC0.txt covers the supplied icon.

## Verification boundary
Lessons are checked by temporary local-file serving and, where applicable, one program run or compilation. No screenshots, click automation or test suites are claimed; temporary servers are stopped. The track state records the smoke result; browser appearance and interaction still need a human check.

Next: Phase 2, layout and javascript.

## Time planning
Allow 40-45 minutes per lesson, including typing and the exercise.
