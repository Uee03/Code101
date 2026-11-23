---
track: architecture
level: 201
phase: 1
phase_name: diagram-depth
lesson: 03
title: "Deployment and network diagrams in draw.io"
time: 70 min
prerequisites: [architecture-201-02, architecture-101-07]
versions: { format: "uncompressed draw.io XML", editor: "diagrams.net in a browser, or the optional VS Code draw.io integration" }
verified: not yet run
source: source/architecture/201-hero-to-super-hero/phase-1-diagram-depth/03-deployment-and-network-diagrams/
assets: []
---

# 03. Deployment and network diagrams in draw.io

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Draw a deployment diagram in draw.io with nested boundaries, labelled connections (protocol and port) and a note on what is not shown.
- Write a connection inventory that agrees with the diagram, one row per arrow.
- Read a deployment diagram for exposure: what is published to the host, what stays inside a network, who initiates each connection.

## Recap
1. In 101 lesson 07, which part of a `.drawio` file links a connector to a shape?
   <details><summary>Answer</summary>The connector's `source` and `target` attributes, which hold the `id` of existing shapes.</details>
2. In lesson 02 of this level, why does an arrow carry a data label?
   <details><summary>Answer</summary>An unlabelled arrow hides what data moves. The same rule applies to connections here: label protocol and port.</details>

## Why it matters
Logical diagrams (C4 containers, sequences) say *what talks to what*. A deployment diagram says *where each part runs and what is reachable*. Most security and operations questions need that second picture: which port is open, which parts share a network, which connection a firewall rule must allow. Mermaid has no good way to nest boundaries and place shapes exactly, which is why this lesson uses draw.io.

## What you will build
Two files for the local Tasks and Teams stack (platform README, "Host ports", and TDD section 11):
1. `deployment.drawio`: the developer machine, with the browser, the web dev server, the backend API and a Docker Compose network holding Keycloak and PostgreSQL.
2. `connection-inventory.md`: five rows, one per arrow.

This is the *local* stack. It does not show HTTPS, a gateway or production hosting; the picture says so itself.

## Before you start
- **Prerequisites:** [Architecture 201 lesson 02, ER and data-flow diagrams](02-er-and-data-flow-diagrams.md) and [Architecture 101 lesson 07, draw.io editable diagrams](../../101-zero-to-hero/phase-2-diagram-toolkit/07-drawio-editable-diagrams.md).
- Lesson 02 done, and a browser. You use https://app.diagrams.net/ (choose **Device** when it asks where to save) or the optional VS Code integration from 101 lesson 07. Use only invented or public labels in a hosted editor.
- Time: 70 minutes (reading 15, saving and opening files 25, checking 10, exercise 20).
- Work folder: `code101/architecture/201-lesson03`.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/architecture/201-hero-to-super-hero/phase-1-diagram-depth/03-deployment-and-network-diagrams/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`).
- Pictures described below are expected, not yet opened by the author.

## Steps
### Step 1. Name the reader and the question
Reader: an engineer who must open the right ports and reason about exposure. Question: "Which parts run where, which ports does each publish, and who starts each connection?"

> **Why this, not that.** draw.io, not Mermaid, for deployment: you need containers that visually contain other shapes and control over position. Mermaid's flowchart can nest `subgraph` blocks, but its automatic layout moves boxes as the diagram changes, so a diagram you want to read the same way every time suits a canvas better. Keep logical diagrams in Mermaid, where text diffs are small and the layout does not matter.

### Step 2. Save the deployment diagram
Create `deployment.drawio` in `code101/architecture/201-lesson03` (plain text, UTF-8, extension `.drawio`, not `.drawio.txt`).

**File: `deployment.drawio`**

```xml
<mxfile host="app.diagrams.net">
  <diagram id="deploy" name="Local deployment">
    <mxGraphModel dx="1100" dy="700" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1100" pageHeight="700" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="host" value="Developer machine (Windows, macOS or Linux)" style="rounded=0;whiteSpace=wrap;html=1;fillColor=none;dashed=1;verticalAlign=top;align=left;spacingLeft=8;fontStyle=1;container=1;collapsible=0;" vertex="1" parent="1">
          <mxGeometry x="20" y="20" width="1040" height="440" as="geometry"/>
        </mxCell>
        <mxCell id="web" value="Web dev server (Angular 4200 or React 5173)" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="host">
          <mxGeometry x="20" y="50" width="200" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="browser" value="Browser" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;" vertex="1" parent="host">
          <mxGeometry x="340" y="50" width="160" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="api" value="Backend API (Python, ASP.NET, Go or Rust) on port 8000" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="host">
          <mxGeometry x="620" y="50" width="240" height="70" as="geometry"/>
        </mxCell>
        <mxCell id="net" value="Docker Compose network tasksteams-net" style="rounded=0;whiteSpace=wrap;html=1;fillColor=none;dashed=1;verticalAlign=top;align=left;spacingLeft=8;container=1;collapsible=0;" vertex="1" parent="host">
          <mxGeometry x="40" y="190" width="960" height="230" as="geometry"/>
        </mxCell>
        <mxCell id="kc" value="Keycloak 26.8.2, published on 127.0.0.1:8180" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e1d5e7;strokeColor=#9673a6;" vertex="1" parent="net">
          <mxGeometry x="280" y="70" width="200" height="70" as="geometry"/>
        </mxCell>
        <mxCell id="pg" value="PostgreSQL 17, published on 127.0.0.1:5432" style="shape=cylinder3;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" vertex="1" parent="net">
          <mxGeometry x="660" y="60" width="160" height="90" as="geometry"/>
        </mxCell>
        <mxCell id="e1" value="loads the app (HTTP)" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="browser" target="web" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e2" value="API calls with bearer token (HTTP 8000)" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="browser" target="api" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e3" value="sign-in redirect (HTTP 8180)" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="browser" target="kc" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e4" value="SQL as tasks_app (TCP 5432)" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="api" target="pg" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="e5" value="fetches signing keys (JWKS)" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;dashed=1;" edge="1" source="api" target="kc" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
        <mxCell id="note" value="Local development view. Plain HTTP on loopback. HTTPS, a gateway and production hosting are not drawn." style="text;html=1;whiteSpace=wrap;align=left;verticalAlign=top;" vertex="1" parent="1">
          <mxGeometry x="20" y="480" width="700" height="40" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

### Step 3. Save the connection inventory
A picture can hide a missing arrow. A table with one row per arrow can be checked row by row against the picture.

**File: `connection-inventory.md`**

````markdown
# Connection inventory: local Tasks and Teams stack

| From | To | Protocol and port | Initiated by | Credential |
|---|---|---|---|---|
| Browser | Web dev server | HTTP, 4200 or 5173 | Browser | none, the app files are public |
| Browser | Keycloak | HTTP, 8180 on 127.0.0.1 | Browser | username and password typed on the Keycloak page |
| Browser | Backend API | HTTP, 8000 | Browser | bearer access token |
| Backend API | PostgreSQL | SQL over TCP, 5432 on 127.0.0.1 | Backend API | database role tasks_app, secret kept in a git-ignored .env |
| Backend API | Keycloak | HTTP, 8180, signing keys (JWKS) | Backend API | none, the keys are public |

Not shown: HTTPS, a gateway, a cache, mobile clients and any production hosting. They are proposals or other views.
````

The four-backtick fence is only this lesson's wrapper; the file content is what is inside it.

### Step 4. Predict, then open
Predict before opening: (1) how many shapes are *inside* the Compose network, and how many arrows cross its border? (2) Which connection is initiated by the backend rather than the browser?

Open https://app.diagrams.net/, choose **Device**, then **Open Existing Diagram** (or **File > Open From > Device**) and select `deployment.drawio`. In VS Code, open the file with the draw.io editor if you installed it.

## Run it
There is no command. Open the file as in Step 4.

Expected result, not yet opened: a large dashed rectangle titled "Developer machine"; inside it, left to right, a blue web dev server box, a yellow Browser box and a blue Backend API box; below them a second dashed rectangle "Docker Compose network tasksteams-net" holding a purple Keycloak box and a green PostgreSQL cylinder; five labelled arrows; a one-line note below the picture. Moving the Compose rectangle in the editor moves the two shapes inside it, because they are its children.

Your predictions: (1) two shapes are inside; three arrows cross its border (sign-in redirect and JWKS into Keycloak, SQL into PostgreSQL); (2) the SQL arrow and the JWKS arrow both start at the backend.

## How it works
- **Containers.** The `host` and `net` cells have `container=1`. A shape whose `parent` is `host` or `net` belongs to that container; its geometry is relative to the container's top-left corner. That is how nesting is stored: `kc` has `parent="net"`, `net` has `parent="host"`.
- **Edges.** Connectors have `parent="1"` (the default layer) and refer to shapes by `source` and `target`, even when the shapes live inside containers. The editor draws them across the borders.
- **Style.** `dashed=1` and an empty fill make the two boundaries read as areas, not boxes. The dashed JWKS arrow separates a background fetch from request-driven traffic. Colour is secondary: every shape carries its name and port in text.
- **Facts.** The two published ports are on `127.0.0.1` only, as the platform TDD requires (section 11: ports bind to loopback), so nothing outside the machine reaches Postgres or Keycloak in this local stack.

The inventory repeats the picture as rows. Review by walking the table: every row has an arrow, every arrow a row, and each row says who starts the connection and which credential protects it.

**Reading for exposure.** Ask three questions of any deployment diagram. What is published beyond the host or network? What crosses a boundary, and is it authenticated? Who initiates each connection (a firewall or network rule is usually written for the initiator)?

**Misconception:** "one box in the diagram is one machine." Here the browser, dev server and backend are all processes on one machine. A deployment diagram shows *nodes where software runs*; decide the granularity (machine, container, process) and say it in the title.

**Keep the file reviewable.** Save the diagram as uncompressed XML so that a Git diff shows a changed label. If your editor offers a "Compressed" option under **File > Properties**, leave it off. An exported PNG or SVG is a copy for slides; commit the `.drawio` source.

## Try it
### 1. Guided practice
The starter shows the API, the Compose network and PostgreSQL, but Keycloak has a `TODO` label and the dashed JWKS arrow is missing. Copy `exercise/starter` as `201-lesson03-try` (rename the **copy**) or save the file below as `201-lesson03-try/deployment.drawio`, open it, rename the Keycloak shape, then add a dashed arrow from the API to Keycloak. In diagrams.net, hover over the API shape, drag one of the small blue arrows onto the Keycloak shape, then double-click the new arrow to type its label. To make it dashed, select it and use the **Arrow** section of the **Format** panel.

**File: `201-lesson03-try/deployment.drawio` (starter)**
```xml
<mxfile host="app.diagrams.net">
  <diagram id="deploy-try" name="Practice">
    <mxGraphModel dx="1000" dy="600" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1100" pageHeight="700" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="api" value="Backend API on port 8000" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" vertex="1" parent="1">
          <mxGeometry x="40" y="60" width="200" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="net" value="Docker Compose network tasksteams-net" style="rounded=0;whiteSpace=wrap;html=1;fillColor=none;dashed=1;verticalAlign=top;align=left;spacingLeft=8;container=1;collapsible=0;" vertex="1" parent="1">
          <mxGeometry x="40" y="200" width="560" height="200" as="geometry"/>
        </mxCell>
        <mxCell id="kc" value="TODO name the service and its published port" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e1d5e7;strokeColor=#9673a6;" vertex="1" parent="net">
          <mxGeometry x="40" y="70" width="200" height="70" as="geometry"/>
        </mxCell>
        <mxCell id="pg" value="PostgreSQL 17, published on 127.0.0.1:5432" style="shape=cylinder3;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" vertex="1" parent="net">
          <mxGeometry x="360" y="60" width="160" height="90" as="geometry"/>
        </mxCell>
        <mxCell id="e1" value="SQL as tasks_app (TCP 5432)" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;" edge="1" source="api" target="pg" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

Goal: Keycloak is labelled with its version and published port, and the API reaches it with a dashed, labelled arrow.

### 2. Change practice
Add a second row to your own copy of the inventory idea: write the inventory table for this practice drawing (two rows).

### 3. Stretch (optional)
Draw, on paper or in a copy, where a reverse proxy that terminates HTTPS would sit if you added one in front of the API. Which row of the inventory changes, and which new boundary appears? There is no single answer; mark it as a proposal.

<details><summary>Solution to guided practice</summary>

The solution file equals the starter with exactly two changes. First, the Keycloak shape's `value` becomes `Keycloak 26.8.2, published on 127.0.0.1:8180`:

```xml
        <mxCell id="kc" value="Keycloak 26.8.2, published on 127.0.0.1:8180" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e1d5e7;strokeColor=#9673a6;" vertex="1" parent="net">
```

Second, a new connector is added directly before `</root>`:

```xml
        <mxCell id="e2" value="fetches signing keys (JWKS)" style="edgeStyle=orthogonalEdgeStyle;rounded=1;html=1;endArrow=block;endFill=1;dashed=1;" edge="1" source="api" target="kc" parent="1">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
```

The full file is in `exercise/solution/deployment.drawio`. Inventory for change practice: API to PostgreSQL (SQL over TCP 5432, initiated by the API, credential: database role) and API to Keycloak (HTTP 8180, initiated by the API, none because the keys are public). A tool save may rewrite ids or layout; that is fine as long as every connector still refers to existing shapes.

</details>

## Check yourself
1. Why is the arrow from the browser to Keycloak labelled "sign-in redirect" and not "login API call"? <details><summary>Answer</summary>The browser is sent to Keycloak's login page; the web client does not call a login API itself, and never sees the password.</details>
2. Predict: you delete the `net` container but keep `kc` and `pg`. What happens to their `parent` references? <details><summary>Answer</summary>They point to an id that no longer exists, so the file is broken or the shapes are lost. Delete or move children together with their container in the editor.</details>
3. Which three questions do you ask of any deployment diagram? <details><summary>Answer</summary>What is published beyond its boundary; what crosses a boundary and how it is authenticated; who initiates each connection.</details>
4. The diagram is correct for the local stack. Why is it unsafe to present it as the production design? <details><summary>Answer</summary>It shows plain HTTP, loopback publishing and development settings. Production would add TLS, secret stores, a different network layout; the note on the picture says so.</details>

## Common mistakes
Typical symptoms; the editors' wording differs by version.

| Symptom | Cause | Fix |
|---|---|---|
| Raw XML shows instead of shapes | The file opened in a text editor | Open it in diagrams.net or choose the draw.io editor |
| Shapes inside a container appear far away | A child's geometry was written in page coordinates | Use coordinates relative to the container's corner |
| An arrow ends in empty space | `source` or `target` refers to an id that does not exist | Fix the id or reconnect in the editor |
| A hosted editor offers to store the file in a cloud account | The default storage choice | Choose **Device**; never upload private architecture to a public editor |

## Best practice
Give every arrow a protocol and a port, state the scope in a note, and store the diagram as editable text. Source: [draw.io integration for VS Code](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio); [C4 model, deployment diagram](https://c4model.com/diagrams/deployment).

## Going further
The platform TDD section 11 lists ports and settings; compare each row of your inventory with it. Lesson 06 of level 301 returns to this picture to add trust boundaries.

## Summary
- You drew a deployment diagram with nested boundaries, labelled connections and a scope note.
- You wrote a connection inventory that agrees with the picture.
- You read the diagram for exposure and for who initiates each connection.

## Next lesson
04. REST, events and gRPC: choose how two parts of a system should talk to each other.
