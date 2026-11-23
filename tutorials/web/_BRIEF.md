# Web Foundations 101 - Zero to Hero

## Audience and outcome
Complete beginners from any field. Build a readable, responsive personal landing page with a TypeScript todo list that remembers tasks. Analogy first; every file, folder, configuration, command and expected screen shown. No previous terminal experience. Allow 40-45 minutes for lessons 01-07; lessons 08-11 take 90-120 minutes in two sittings, and project lesson 12 takes 120-180 minutes in two sittings. Lessons are not split or renumbered.

## Plan (12 lessons, three downloadable phases)
| Phase | Lesson | Outcome |
|---|---|---|
| 1 html-and-css | 01 How the web works + your first HTML page | VS Code, index.html, browser; no terminal; Live Server optional |
| 1 | 02 Text, links, images, lists | Headings, paragraphs, relative paths; save the complete CC0 ui/search SVG shown in the lesson |
| 1 | 03 Forms and semantic HTML | header/main/footer, labels, input types, keyboard access |
| 1 | 04 CSS basics | style.css, selectors, color, fonts, cascade |
| 2 layout-and-javascript | 05 Box model and spacing | Content, padding, border, margin, border-box |
| 2 | 06 Flexbox | Row layout, alignment, gap, wrapping |
| 2 | 07 Grid and responsive design | Columns, viewport, media queries |
| 2 | 08 JavaScript basics | Variables, functions, if/else, loops; browser console and Node |
| 3 typescript-and-project | 09 The DOM and events | Click handlers, textContent, DOM-ready scripts |
| 3 | 10 TypeScript first steps | Node LTS install, write manifest, exact dependency, full configs, types/interfaces, real compiler diagnostic |
| 3 | 11 TypeScript in the browser | Compile modules; fetch local mock JSON over HTTP |
| 3 | 12 Project: personal landing page + todo list | HTML/CSS/TS; safe text, localStorage, completion/removal |

## Versions and evidence (checked 2026-11-23)
Node **26.13.1** LTS, bundled npm **11.20.0** (author machine); TypeScript **7.0.2**, exact package.json dependency and generated lockfile. No global TypeScript. Browser: current Edge/Chrome/Firefox; no browser screenshot claims. Official sources: [Node download](https://nodejs.org/en/download), [Node release status](https://nodejs.org/en/about/previous-releases), [TypeScript download](https://www.typescriptlang.org/download/), [7.0.2 official release](https://github.com/microsoft/TypeScript/releases/tag/v7.0.2), [VS Code setup](https://code.visualstudio.com/docs/setup/windows).

## Teaching references (Tier 1: authoritative)
[MDN learning web development](https://developer.mozilla.org/en-US/docs/Learn_web_development), [semantic HTML](https://developer.mozilla.org/en-US/docs/Glossary/Semantics), [forms](https://developer.mozilla.org/en-US/docs/Learn_web_development/Extensions/Forms/Your_first_form), [CSS cascade](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_cascade/Cascade), [web.dev CSS](https://web.dev/learn/css/), [MDN JavaScript guide](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide), [DOM](https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model/Introduction), [TypeScript handbook](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html), [tsconfig reference](https://www.typescriptlang.org/tsconfig/), [fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch), [localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage).

## Delivery and verification boundaries
Matching lessons and code/starter/solution/verify.json; phase PACK-README; glossary and state. Only tutorials/web and source/web authored; requested pack builder creates dist zips. Smoke only: local Python HTTP servers on 18101-18112 (solutions 18201-18212), retrying 200/title probes; Node once per JavaScript example/solution; npm install, npx tsc and Node compiled entry once per TypeScript example/solution. Browser rendering and interaction described for learner inspection, not claimed automated. Art only assets/art, front matter ui/search; explicit copying. No suites, commits or unrelated edits.
