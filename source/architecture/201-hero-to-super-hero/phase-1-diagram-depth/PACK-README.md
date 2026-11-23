# Architecture 201: phase 1 - diagram depth

Draw real flows (sequence), stored data and data movement (ER and data-flow), and where things run (deployment in draw.io).

## Prerequisites and status
Architecture 101, especially lessons 05 to 07. All material is **written (not run)**. Lesson front matter remains `verified: not yet run`; static documentation checking does not render diagrams or execute an application. No compiler, server, database or Docker is required.

## Open the pack
1. Windows: right-click the ZIP and choose **Extract All**. macOS: double-click the ZIP. Linux: use the file manager's **Extract** action. Do not work inside the compressed archive.
2. Open this extracted phase folder and find the numbered lesson folder. `code/` holds the finished diagram and document files, `exercise/starter/` the guided practice and `exercise/solution/` one answer. The empty steps in `verify.json` mean nothing is executed.
3. Make your own `code101/architecture/201-lessonNN` folder and type the files from the lesson, or copy the finished files only to compare. For practice, copy the **starter folder itself** and rename the copy `201-lessonNN-try`; do not nest `starter` inside it.
4. `.mmd` files are raw Mermaid. `diagram-sources.md` repeats them inside Mermaid fences so a Markdown preview (VS Code's built-in preview) can draw them; keep both in step when you edit. Paste one raw `.mmd` file at a time into https://mermaid.live/ for a browser preview, and never paste confidential diagrams into a hosted editor.
5. `.drawio` files open in https://app.diagrams.net/ (choose **Device** for storage) or in VS Code with the optional draw.io integration.

## Lessons
- **01. Sequence diagrams for real flows** - `01-sequence-diagrams-real-flows/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/201-hero-to-super-hero/phase-1-diagram-depth/01-sequence-diagrams-real-flows.md).
- **02. ER and data-flow diagrams** - `02-er-and-data-flow-diagrams/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/201-hero-to-super-hero/phase-1-diagram-depth/02-er-and-data-flow-diagrams.md).
- **03. Deployment and network diagrams in draw.io** - `03-deployment-and-network-diagrams/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/201-hero-to-super-hero/phase-1-diagram-depth/03-deployment-and-network-diagrams.md).

## Verification scope
The repository's static checker compares the Markdown source lines with the lesson text and parses `verify.json`. It does not parse Mermaid or draw.io XML. A clean static result does not prove that a diagram renders, and nothing here was rendered or run.
