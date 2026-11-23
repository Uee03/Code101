---
track: architecture
level: 101
phase: 2
phase_name: diagram-toolkit
lesson: 07
title: "draw.io: editable diagrams"
time: 60 min
prerequisites: [architecture-101-06]
versions: { format: "uncompressed draw.io XML", editor: "diagrams.net or VS Code integration" }
verified: not yet run
source: source/architecture/101-zero-to-hero/phase-2-diagram-toolkit/07-drawio-editable-diagrams/
assets: []
---

# 07. draw.io: editable diagrams

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Save an editable draw.io diagram as uncompressed XML.
- Open and edit the file in diagrams.net or VS Code.
- Explain how identifiers, geometry and references keep shapes connected.

## Recap
1. What does the C4 container view add to context?
   <details><summary>Answer</summary>The applications and data stores inside the named system boundary, with responsibilities and relationships.</details>

2. Is Keycloak's physical location what sets our boundary?
   <details><summary>Answer</summary>No. We chose the work-planning responsibility boundary and stated identity as external to it.</details>

## Why it matters
A city planner may start with a written route description, then move buildings around on a reusable drawing. Saving only a screenshot loses that freedom. draw.io gives us a canvas while keeping an editable diagram source.

## What you will build
A three-shape Tasks and Teams request-path sketch in a `.drawio` file. This small view intentionally omits sign-in, users and access-check detail; it is not the complete C4 model from lesson 06.

## Before you start
- Complete lesson 06. Use the same text editor and a browser. The browser route requires no installed drawing app. A VS Code extension is an optional alternative, explained below.
- Time: 60 minutes including reading, saving the files and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/architecture/101-zero-to-hero/phase-2-diagram-toolkit/07-drawio-editable-diagrams/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`). Cloning is optional; no terminal is used in the steps below.
- If using a downloaded ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, right-click it in the file manager and choose **Extract Here** or **Extract**. Open the extracted folder, not the compressed ZIP. Phase packs start at the phase's folder; the full repository starts above `source/`.
- Here, “source code” means editable diagram text and short documents, not an application. No command, server or database needs to run. The picture descriptions below are expected output, not yet run or rendered by the author.

## Steps
### Step 1. Prepare a separate work folder
A **folder** groups files; a **file** stores saved content. Open your home folder: on Windows press **Win+E**, type `%USERPROFILE%` in the address bar and press Enter; on macOS use **Finder > Go > Home**; on Linux open your file manager's **Home**. Create `code101` if it is absent, open it, create `architecture` if absent, then open it and create `lesson07`. Windows uses **right-click > New > Folder**, macOS **File > New Folder**, and Linux the file manager's **New Folder** action. Do not put this work inside the optional source pack.

Use a plain-text editor. On Windows open **Notepad** from Start. On macOS open **TextEdit**, choose **Format > Make Plain Text**, and use UTF-8 if an encoding choice appears when saving. On Linux use the desktop's text editor. VS Code, if already available, is also suitable. For each file below choose **File > New**, paste the complete listing and use **File > Save As** in `code101/architecture/lesson07` with the exact shown filename. On Windows choose **All files** if offered so `.txt` is not appended. On macOS decline an offer to append `.txt`. Use UTF-8, a text encoding for international characters, and plain text rather than a word processor's rich-text format. In VS Code an unsaved dot on the tab means save with **Ctrl+S** (macOS **Command+S**).

Windows: enable **File Explorer > View > Show > File name extensions** (Windows 10: **View > File name extensions**) to check filenames. In every OS inspect the final name in the file manager. The folder should now exist and contain only this lesson's files as you add them.

### Step 2. Name the reader and question
**draw.io**, also called **diagrams.net**, is a diagram editor. A `.drawio` file can hold **XML**, Extensible Markup Language: structured text with named elements and attributes. An **element** is a named part between angle brackets; an **attribute** is a named value such as `id="web"`. A **vertex** means a shape in the drawing; its **geometry** gives position and size. You can copy this complete file without becoming an XML programmer. The diagram remains editable; a screenshot alone would not preserve these shapes and connectors.

### Step 3. Save the complete editable diagram
In `code101/architecture/lesson07`, create `system.drawio`. Save this as plain text with the exact extension `.drawio`, not `.xml.txt`. It is deliberately uncompressed XML: readable text rather than an opaque encoded diagram. No XML comments or external image assets are used.

**File: `lesson07/system.drawio`**
```xml
<mxfile host="app.diagrams.net">
  <diagram id="tasks" name="Tasks and Teams">
    <mxGraphModel dx="1000" dy="600" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1100" pageHeight="700" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="web" value="Web client" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="40" y="40" width="140" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="api" value="Backend API" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="220" y="40" width="140" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="db" value="PostgreSQL" style="shape=cylinder3;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" vertex="1" parent="1">
          <mxGeometry x="400" y="40" width="100" height="70" as="geometry"/>
        </mxCell>
        <mxCell id="call" value="Read tasks" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="web" target="api" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="query" value="Read records" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="api" target="db" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

The expected canvas has Web client, Backend API and PostgreSQL in a horizontal row. The connectors say Read tasks and Read records. Colours are optional cues; text labels carry all meaning.

Expected saved result: `lesson07/system.drawio` contains the listing above. This is a file-content expectation, not a captured renderer result.

### Step 4. Save the readable companion
In `code101/architecture/lesson07`, create `diagram-sources.md` with the complete content below. **Markdown** is plain text with lightweight formatting markers; `.md` is its usual extension. A **fence** is a line of backticks marking a block. This companion repeats the diagram files inside fences so a Markdown **preview**, a displayed view of the source, can render them. The outer four-backtick boundary is only this lesson's display wrapper; copy the content inside it, including the inner three-backtick lines. If you change a raw diagram later, replace its corresponding fenced content here too; the two files do not synchronise automatically. No hidden file or configuration is required.

<details><summary>Complete companion document</summary>

**File: `lesson07/diagram-sources.md`**
````markdown
# Diagram source listings

These listings reproduce the editable diagram sources in this folder.

## system.drawio

```xml
<mxfile host="app.diagrams.net">
  <diagram id="tasks" name="Tasks and Teams">
    <mxGraphModel dx="1000" dy="600" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1100" pageHeight="700" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="web" value="Web client" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="40" y="40" width="140" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="api" value="Backend API" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="220" y="40" width="140" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="db" value="PostgreSQL" style="shape=cylinder3;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" vertex="1" parent="1">
          <mxGeometry x="400" y="40" width="100" height="70" as="geometry"/>
        </mxCell>
        <mxCell id="call" value="Read tasks" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="web" target="api" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="query" value="Read records" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="api" target="db" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```
````

</details>

### Step 5. Predict, then inspect
Before opening the file, predict: how many vertices and edges are there? If api is renamed as an identifier but the edges still target api, will those references still identify a shape?

### Open the file in diagrams.net
1. In your browser open [app.diagrams.net](https://app.diagrams.net/). If asked where to store diagrams, choose **Device**; do not connect a cloud account for this exercise.
2. If the start screen offers **Open Existing Diagram**, choose it, then select `code101/architecture/lesson07/system.drawio`. If a blank canvas is already open, use **File > Open From > Device** and select that file instead. Dismiss an optional save-location prompt if necessary and choose the local file.
3. Click the Backend API shape once to select it. Double-click its label to edit, type `API: enforce team access`, and click the blank canvas to finish. This changes documentation, not the actual API's behaviour.
4. Choose **File > Save As**, select a local-device save if prompted, and save a separate file named `system-edited.drawio` in `lesson07`. With browser-managed downloads, move the downloaded file from Downloads to that folder using your file manager. Keep the original unchanged.
5. Close the drawing and reopen `system-edited.drawio` with **File > Open From > Device**. Confirm that the new label remains and that a shape can still be selected separately. You have checked editability, not just exported a picture. Use only these invented public labels in a hosted editor; use your organisation's approved offline tool for private architecture.

### Optional: open the same file locally in VS Code
1. If VS Code is not already available, use lesson 05's **Preview choices** installation steps; they are identical on each operating system. The only folder difference is `lesson07` rather than `lesson05`.
2. Open **View > Extensions**, search the exact identifier **hediet.vscode-drawio**, confirm the publisher is **Henning Dieterichs**, and choose **Install**. This is an unofficial integration that uses an offline draw.io editor by default; approve extensions according to your organisation's policy.
3. Choose **File > Open File**, select `lesson07/system.drawio`, then select a shape. If raw XML opens, right-click the tab, choose **Reopen Editor With** and select the draw.io editor. To inspect XML instead, choose **Text Editor** from the same menu.
4. Edit a label, save with **Ctrl+S** on Windows/Linux or **Command+S** on macOS, close and reopen the file. The menu route is the same on all three systems; no terminal command is required.



## Run it
There is no application command. Use the diagrams.net or VS Code opening steps above, then save and reopen the edited drawing. Do not confuse the XML text view with the drawing canvas.

**Expected output, not yet run:** Three selectable shapes and two labelled connectors. Moving Backend API should keep both attached connectors connected. The XML source remains the editable original; an edited tool save may use a different but equivalent XML representation.

<details><summary>Recorded documentation-only check</summary>

The repository's static check reported the following. This checks source-text coverage and verification specifications, not diagram rendering or application behaviour. It does not remove this lesson's draft notice.

**Recorded output (not application output):**
```text
0 passed, 10 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

</details>

## How it works
Read the XML from outside in. `mxfile` is the file wrapper; its `host` names the editor. `diagram` names one page with a unique id. `mxGraphModel` holds canvas settings. `root` contains all cells. Cells `0` and `1` establish the root and default layer.

Each shape is an `mxCell` with `vertex="1"`. Its `id` is the reference name, `value` the visible label, `style` the semicolon-separated appearance settings, and `parent="1"` its layer. Its `mxGeometry` supplies x/y position and width/height; `as="geometry"` identifies that child's role. Shapes use columns 40, 220 and 400 on a grid rather than overlapping.

Each connector has `edge="1"`, `source` and `target` referencing existing ids, and a geometry child with `relative="1"`. `edgeStyle=orthogonalEdgeStyle` routes right-angle lines. `endArrow=block` and `endFill=1` make filled arrowheads at targets; `rounded=1` softens corners. `whiteSpace=wrap` wraps shape text, `html=1` enables label formatting, and `fillColor`/`strokeColor` set fill/outline colours. `shape=cylinder3` distinguishes the database shape without relying on colour. No waypoints or hand-attached endpoints are needed.

The model settings `dx`/`dy` retain editor view information; `grid`/`gridSize` set the visible grid; `guides`, `tooltips`, `connect`, `arrows` and `fold` enable editing aids. `page`, `pageScale`, `pageWidth` and `pageHeight` configure the page. `math="0"` and `shadow="0"` disable optional equation rendering and shadows. Page size does not describe a server's capacity.

All ids are unique, every reference exists, and every shape/edge has geometry. In XML attribute text, a literal ampersand must be written `&amp;` and a less-than sign as `&lt;`. This file has no such label characters.

**PNG** is a common image-file format. **Misconception:** a PNG export is the editable source. **Correction:** an ordinary PNG screenshot contains pixels, not these separate shapes and references. Keep the `.drawio` original even if you later export an image.

## Try it
### 1. Guided practice
Replace the starter's TODO label with a short API responsibility: enforce team access. Change only the visible label, not its id or connector references. The canvas should still have three shapes and two connectors.

In your file manager open `code101/architecture` and create `lesson07-try`. If using the optional source pack, delete this empty folder, then copy this lesson's `exercise/starter` folder beside `lesson07` and rename the **copy itself** to `lesson07-try`; do not put a folder named starter inside it. Otherwise create each starter file listed below directly inside `lesson07-try` using **File > New > Save As** in your editor. The full starters are shown; no earlier file is assumed to exist in this exercise folder. A `TODO` is an instruction placeholder to replace, not a special Mermaid command.

<details><summary>Complete starter files</summary>

**File: `lesson07-try/system.drawio` (starter)**
```xml
<mxfile host="app.diagrams.net">
  <diagram id="tasks" name="Tasks and Teams">
    <mxGraphModel dx="1000" dy="600" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1100" pageHeight="700" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="web" value="Web client" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="40" y="40" width="140" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="api" value="TODO responsibility" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="220" y="40" width="140" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="db" value="PostgreSQL" style="shape=cylinder3;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" vertex="1" parent="1">
          <mxGeometry x="400" y="40" width="100" height="70" as="geometry"/>
        </mxCell>
        <mxCell id="call" value="Read tasks" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="web" target="api" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="query" value="Read records" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="api" target="db" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

</details>

Save every changed file. For this draw.io diagram, open `lesson07-try/system.drawio` using the same Device-open or local VS Code procedure as the worked example; do not paste XML into Mermaid Live Editor. For Markdown, reopen the saved exercise document and check its headings and claims. Do not edit the solution before trying.

### 2. Change practice
Move the database shape on the canvas, then save and reopen the file. Confirm its connector still refers to the same shape. A different position is not a different system design.

### 3. Stretch (optional)
Explain which omitted identity relationship would matter if this were a complete access-security review. Do not add unknown platform services.

<details><summary>Solution to guided practice</summary>

**File: `lesson07-try/system.drawio` (solution)**
```xml
<mxfile host="app.diagrams.net">
  <diagram id="tasks" name="Tasks and Teams">
    <mxGraphModel dx="1000" dy="600" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1100" pageHeight="700" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="web" value="Web client" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="40" y="40" width="140" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="api" value="API: enforce team access" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="220" y="40" width="140" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="db" value="PostgreSQL" style="shape=cylinder3;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" vertex="1" parent="1">
          <mxGeometry x="400" y="40" width="100" height="70" as="geometry"/>
        </mxCell>
        <mxCell id="call" value="Read tasks" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="web" target="api" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="query" value="Read records" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="api" target="db" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

Compare the saved sources, not just their appearance. The solution addresses the guided goal; your change and stretch choices may differ. All displayed behaviour remains an expectation, not a captured execution result.

</details>

## Check yourself
1. What makes the supplied .drawio source different from a screenshot?
   <details><summary>Answer</summary>It retains structured cells, geometry and connections in editable XML.</details>

2. Predict the reference problem if id="api" becomes id="backend" but edges still refer to api.
   <details><summary>Answer</summary>The edges would reference an id that no longer exists. Rename only the visible value unless you update every reference too.</details>

3. Where can the learner open this file without installing a programming language?
   <details><summary>Answer</summary>In diagrams.net using a local-device open, or in VS Code with the optional draw.io integration.</details>

## Common mistakes
These are likely symptoms to inspect, not captured error messages.

| Symptom | Cause | Fix |
|---|---|---|
| Raw XML is shown instead of shapes | The file opened in a text editor | Open it through diagrams.net, or select the draw.io editor in VS Code. |
| A shape or connector disappears after a hand edit | An id/reference or geometry was removed | Compare against the complete original and restore the missing structure. |
| An image cannot be edited shape by shape | An ordinary screenshot/export was opened | Reopen the .drawio original, not the screenshot. |

## Best practice
Preserve the editable .drawio source, not only an exported picture. Source: the draw.io integration publisher, [Draw.io Integration](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio).

## Going further
Phase 2 mixed review: choose sequence for message order, class for concepts, ER for stored keys, state for one task's lifecycle, and a C4 context view for neighbours. Explain why the three shapes here are neither three logical layers nor a complete system context. Lesson 08 records why design choices were made.

## Summary
- You practised how to save an editable draw.io diagram as uncompressed XML.
- You practised how to open and edit the file in diagrams.net or VS Code.
- You practised how to explain how identifiers, geometry and references keep shapes connected.

## Next lesson
[08. Architecture decision records](../phase-3-documenting-decisions/08-architecture-decision-records.md): record why a choice was made, including its costs.
