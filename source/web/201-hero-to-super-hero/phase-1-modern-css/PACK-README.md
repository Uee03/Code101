# Web Foundations 201, Phase 1: Modern CSS

Source pack for lessons 01 to 03. **Status: written, not yet run.** The code was prepared by reading the code and the official documentation; no smoke test has been executed yet (see `tutorials/web/_STATE-201.md`). If something behaves differently from the lesson, trust what you see and report it.

| Folder | Lesson | You build |
|---|---|---|
| `01-custom-properties-and-theming` | Custom properties and theming | A light and dark "Theme lab" page with tokens, `light-dark()`, a per-card override and a saved theme toggle |
| `02-modern-layout` | Modern layout | One product component that changes layout by container width, fluid `clamp()` sizes and left-to-right plus right-to-left notes with logical properties |
| `03-css-architecture-and-animation` | CSS architecture and animation | A layered, BEM-named stylesheet with buttons, toasts, transitions and reduced-motion handling |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | Finished files, identical to the listings in the lesson. Open `code/index.html` in a browser. |
| `exercise/starter/` | **Overlay files** for the Try it exercise: here a single `exercise.css` with TODO comments. |
| `exercise/solution/` | The completed overlay file. Try the exercise before you open it. |
| `assets/` | Only in the built zips: the CC0 icons the lesson uses (lesson 01: `weather/sun` and `weather/moon`) and the license file. |

**How the exercise overlay works.** Copy your finished lesson folder (or `code/`) to a new folder, for example `lesson01-try`, and put the starter file *into that copy*, next to `index.html`. Then link it after `styles.css` in `index.html` as the lesson says. Do not edit `code/` itself.

## Where to get the optional files
Every file and every starter is shown in the lesson, so the pack is optional. Visit https://github.com/Uee03/Code101 and choose **Code > Download ZIP**, then open `source/web/201-hero-to-super-hero/phase-1-modern-css/`. Or run `git clone https://github.com/Uee03/Code101.git` if Git is installed. If you were given prebuilt archives they are named `web-201-phase-1-modern-css.zip` and `web-201-all.zip` (the all archive contains the four phase folders, not nested zips).

## Needs
- A current Edge, Chrome, Firefox or Safari. `light-dark()`, container queries and cascade layers need current versions of these browsers; check the MDN compatibility tables if yours is older.
- VS Code from Web 101 lesson 01. No Node, no terminal and no server are needed in this phase. (A local server such as Live Server is only a fallback if your browser does not remember `localStorage` for files opened from disk.)

## How to run
Open `code/index.html` by double-clicking it or with **Open with** your browser. Browser behaviour described in the lessons was derived from reading the CSS, not from screenshots; the manual checklist is in the track state file.

## Time planning
Lessons 01 and 02 take about 45 minutes each, lesson 03 about 50 minutes.

Next: Phase 2, TypeScript in depth (lessons 04 to 06).
