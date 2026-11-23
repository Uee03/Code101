---
track: architecture
level: 101
phase: 3
phase_name: documenting-decisions
lesson: 08
title: "Architecture decision records"
time: 70 min
prerequisites: [architecture-101-07]
versions: { format: "Markdown and conservative Mermaid syntax; renderer-dependent" }
verified: not yet run
source: source/architecture/101-zero-to-hero/phase-3-documenting-decisions/08-architecture-decision-records/
assets: []
---

# 08. Architecture decision records

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Write an ADR with context, options, a decision and consequences.
- Explain the platform choices of PostgreSQL, Keycloak and OpenAPI-first.
- Record a review trigger without pretending a decision has no cost.

## Recap
1. What is lost when only an ordinary screenshot is retained?
   <details><summary>Answer</summary>Shape-level editability and structured source connections.</details>

2. What boundary did our Tasks and Teams views choose?
   <details><summary>Answer</summary>Work planning, with identity shown as a neighbouring capability.</details>

## Why it matters
A restaurant might record why it chose one supplier: reliable deliveries, higher prices and a plan to review after shortages. A list saying only Supplier A would lose that reasoning. Architecture decisions need the same short memory aid.

## What you will build
An ADR template and three short example decisions for Tasks and Teams. They paraphrase choices already present in the platform design; they are teaching records, not newly approved historical governance documents. Take two sittings, pausing after the first example.

## Before you start
- Complete lessons 05 to 07. Use a plain-text editor. Mermaid rendering and a running platform are not needed for this lesson. Markdown preview is optional.
- Time: 70 minutes including reading, saving the files and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/architecture/101-zero-to-hero/phase-3-documenting-decisions/08-architecture-decision-records/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`). Cloning is optional; no terminal is used in the steps below.
- If using a downloaded ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, right-click it in the file manager and choose **Extract Here** or **Extract**. Open the extracted folder, not the compressed ZIP. Phase packs start at the phase's folder; the full repository starts above `source/`.
- Here, “source code” means editable diagram text and short documents, not an application. No command, server or database needs to run. The picture descriptions below are expected output, not yet run or rendered by the author.

## Steps
### Step 1. Prepare a separate work folder
A **folder** groups files; a **file** stores saved content. Open your home folder: on Windows press **Win+E**, type `%USERPROFILE%` in the address bar and press Enter; on macOS use **Finder > Go > Home**; on Linux open your file manager's **Home**. Create `code101` if it is absent, open it, create `architecture` if absent, then open it and create `lesson08`. Windows uses **right-click > New > Folder**, macOS **File > New Folder**, and Linux the file manager's **New Folder** action. Do not put this work inside the optional source pack.

Use a plain-text editor. On Windows open **Notepad** from Start. On macOS open **TextEdit**, choose **Format > Make Plain Text**, and use UTF-8 if an encoding choice appears when saving. On Linux use the desktop's text editor. VS Code, if already available, is also suitable. For each file below choose **File > New**, paste the complete listing and use **File > Save As** in `code101/architecture/lesson08` with the exact shown filename. On Windows choose **All files** if offered so `.txt` is not appended. On macOS decline an offer to append `.txt`. Use UTF-8, a text encoding for international characters, and plain text rather than a word processor's rich-text format. In VS Code an unsaved dot on the tab means save with **Ctrl+S** (macOS **Command+S**).

Windows: enable **File Explorer > View > Show > File name extensions** (Windows 10: **View > File name extensions**) to check filenames. In every OS inspect the final name in the file manager. The folder should now exist and contain only this lesson's files as you add them.

### Step 2. Name the reader and question
An **ADR**, architecture decision record, preserves one important choice and its reasons. **Context** describes the problem and constraints. **Options** are the alternatives considered. **Consequences** include benefits and costs. **Status** distinguishes a proposal from an accepted or replaced decision. An **owner** is responsible for revisiting it; a **review trigger** is an observable change that makes review useful.

A **transaction** groups changes so they succeed together or not at all. A **constraint** is an enforced data rule, such as a required reference. A **migration** is a controlled change to stored structure. These terms explain the PostgreSQL choice; they are not commands to configure it.

**OpenAPI** is a format for describing an HTTP API. A **contract** is an agreed description of interactions. **OpenAPI-first** means reviewing that shared description before implementing changes, rather than allowing every backend to define its own incompatible interface.

### Step 3. Save a reusable decision template
In `code101/architecture/lesson08`, create `adr-template.md`. Keep this template unchanged. `NNN` is a placeholder for a numbered record; `YYYY-MM-DD` marks the date format. Each actual decision goes in its own new file.

**File: `lesson08/adr-template.md`**
````markdown
# ADR NNN: Decision title

Status: Proposed
Date: YYYY-MM-DD
Owner: Named team

## Context
What problem and constraints require a decision?

## Options
- Option A and its cost.
- Option B and its cost.

## Decision
Choose one option and explain why it fits the context.

## Consequences
- Benefit:
- Cost or risk:

## Revisit when
Name an observable trigger and the person who reviews it.
````

The template deliberately asks for a cost and a review trigger. A proposed record is not silently accepted just because somebody saved it.

Expected saved result: `lesson08/adr-template.md` contains the listing above. This is a file-content expectation, not a captured renderer result.

### Step 4. Document the shared data choice
In `code101/architecture/lesson08`, create `001-postgres.md`. The platform already chooses PostgreSQL and shared stored functions. A **stored function** is named work carried out in the database; it can keep a shared atomic rule in one place.

**File: `lesson08/001-postgres.md`**
````markdown
# ADR 001: Keep shared work records in PostgreSQL

Status: Accepted for the teaching platform
Date: 2026-11-23
Owner: Tasks and Teams maintainers

## Context
Four alternative backends must share teams, projects and tasks.
Related changes must be saved together or not at all.

## Options
- PostgreSQL with relationships and transactions.
- Separate JSON files with application-managed consistency.

## Decision
Use PostgreSQL as the source of truth for work records.
Keep shared atomic work rules in the platform stored functions.

## Consequences
- Benefit: constraints and atomic changes are shared by all backends.
- Cost or risk: schema changes need migrations and database skills.

## Revisit when
Maintainers review if a required client cannot use the shared schema.
````

This record compares real database responsibilities against a simpler file approach. It does not claim PostgreSQL is always better. **Break here** if taking two sittings.

Expected saved result: `lesson08/001-postgres.md` contains the listing above. This is a file-content expectation, not a captured renderer result.

### Step 5. Document the identity boundary
In `code101/architecture/lesson08`, create `002-keycloak.md`. The platform delegates interactive sign-in to Keycloak. The client follows the sign-in flow; work backends do not collect user passwords.

**File: `lesson08/002-keycloak.md`**
````markdown
# ADR 002: Delegate sign-in to Keycloak

Status: Accepted for the teaching platform
Date: 2026-11-23
Owner: Tasks and Teams maintainers

## Context
Web and mobile clients need one identity service.
Backends must not collect or store user passwords.

## Options
- Keycloak as a separate identity service.
- A custom password and sign-in implementation per backend.

## Decision
Use Keycloak with OpenID Connect and PKCE for interactive clients.
Backends validate access tokens and still check team permissions.

## Consequences
- Benefit: clients share sign-in rather than duplicating passwords.
- Cost or risk: sign-in depends on another service and its configuration.

## Revisit when
Maintainers review if identity operations exceed the support budget.
````

**Authentication** establishes identity; **authorization** decides what that identity may do. Keycloak handles sign-in, but the API must still check team permissions. Delegation adds an operational dependency rather than removing all security work.

Expected saved result: `lesson08/002-keycloak.md` contains the listing above. This is a file-content expectation, not a captured renderer result.

### Step 6. Document the shared interface choice
In `code101/architecture/lesson08`, create `003-openapi-first.md`. The platform contract lives in `capstones/platform` as `openapi.yaml`. It is the one description used across interchangeable backend implementations and their clients.

**File: `lesson08/003-openapi-first.md`**
````markdown
# ADR 003: Agree the OpenAPI contract first

Status: Accepted for the teaching platform
Date: 2026-11-23
Owner: Tasks and Teams maintainers

## Context
Different client and backend teams must agree on request shapes.
A client should not change when a conforming backend is swapped.

## Options
- Agree one OpenAPI description before implementation.
- Let each backend publish an independently generated description.

## Decision
Use the platform openapi.yaml as the shared contract first.
Review contract changes with client and backend maintainers.

## Consequences
- Benefit: teams can work against one agreed interface.
- Cost or risk: the description and implementations can drift apart.

## Revisit when
Maintainers review when a breaking client change is proposed.
````

An agreed description helps coordination, but it does not guarantee implementations conform. A review trigger gives a named owner a reason to check the decision again. This lesson does not execute contract checks or modify the platform.

Expected saved result: `lesson08/003-openapi-first.md` contains the listing above. This is a file-content expectation, not a captured renderer result.

### Step 7. Predict, then inspect
Predict what is lost if the Consequences section is deleted. Then find which ADR mentions the risk of implementation drift.

## Run it
No command is needed. Open the saved Markdown documents from `code101/architecture/lesson08` in your text editor and read each section. If using VS Code, open the `.md` file and right-click its tab > **Open Preview**. A plain text view is sufficient for checking the reasoning and the table.

**Expected output, not yet run:** Four readable Markdown documents: one template and three decision records. Every example contains Context, Options, Decision, Consequences and Revisit when, plus a status, date and owner. No program output is produced.

<details><summary>Recorded documentation-only check</summary>

The repository's static check reported the following. This checks source-text coverage and verification specifications, not diagram rendering or application behaviour. It does not remove this lesson's draft notice.

**Recorded output (not application output):**
```text
0 passed, 10 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

</details>

## How it works
Read an ADR as a chain: because of this situation, we considered these options, chose this one, accepted these costs and will review when this condition changes. The date records when the teaching record was written; it is not evidence of when the platform was first designed.

**Misconception:** an ADR is a permanent rule or a product advertisement. **Correction:** its purpose is a reviewable reason under stated constraints. If circumstances change, write a new record that says which old one it replaces rather than rewriting the old reasoning invisibly. A **superseded** record is one replaced by a later decision, not a decision that never existed.

Diagrams explain arrangement, while ADRs explain choice. Use both. Keep secrets and personal information out of examples; an ADR needs the reason for a credential policy, not the credential.

## Try it
### 1. Guided practice
Complete the TODOs in a proposed ADR about who reviews platform diagram changes. Compare one central reviewer with any client reviewer; choose a review arrangement, state a coordination cost, name an owner and give an observable review trigger. This is a proposal, not a change to actual platform policy.

In your file manager open `code101/architecture` and create `lesson08-try`. If using the optional source pack, delete this empty folder, then copy this lesson's `exercise/starter` folder beside `lesson08` and rename the **copy itself** to `lesson08-try`; do not put a folder named starter inside it. Otherwise create each starter file listed below directly inside `lesson08-try` using **File > New > Save As** in your editor. The full starters are shown; no earlier file is assumed to exist in this exercise folder. A `TODO` is an instruction placeholder to replace, not a special Mermaid command.

<details><summary>Complete starter files</summary>

**File: `lesson08-try/004-review-ownership.md` (starter)**
````markdown
# ADR 004: Assign documentation review ownership

Status: Proposed
Date: 2026-11-23
Owner: TODO team

## Context
The platform has several clients and interchangeable backends.
Diagram changes can become inconsistent with the shared contract.

## Options
- TODO first owner option and cost.
- TODO second owner option and cost.

## Decision
TODO choose who reviews a changed diagram.

## Consequences
- Benefit: TODO
- Cost or risk: TODO

## Revisit when
TODO observable review trigger.
````

</details>

Save every changed file. For a diagram, use the same raw-source preview procedure from Run it with the exercise file, not the original. For Markdown, reopen the saved exercise document and check its headings and claims. Do not edit the solution before trying.

### 2. Change practice
Choose one consequence in your proposal and describe what evidence would make you revisit it. Keep the original three accepted teaching examples unchanged.

### 3. Stretch (optional)
Imagine a future provider replacement. Outline how a new ADR would link to a superseded identity decision while preserving its original context.

<details><summary>Solution to guided practice</summary>

**File: `lesson08-try/004-review-ownership.md` (solution)**
````markdown
# ADR 004: Assign documentation review ownership

Status: Proposed
Date: 2026-11-23
Owner: Tasks and Teams maintainers

## Context
The platform has several clients and interchangeable backends.
Diagram changes can become inconsistent with the shared contract.

## Options
- One platform reviewer: consistent but can delay changes.
- Any client reviewer: faster but can miss backend effects.

## Decision
Ask one platform maintainer and one affected client maintainer to review.

## Consequences
- Benefit: both ends of a contract change are represented.
- Cost or risk: two reviewers need time to coordinate.

## Revisit when
Maintainers review if three consecutive changes wait over five working days.
````

Compare the saved sources, not just their appearance. The solution addresses the guided goal; your change and stretch choices may differ. All displayed behaviour remains an expectation, not a captured execution result.

</details>

## Check yourself
1. What must an ADR preserve beyond the selected product name?
   <details><summary>Answer</summary>The situation, alternatives, reason for the choice, consequences and a way to revisit it, with status and ownership.</details>

2. Which example explains how interchangeable implementations agree on request shapes?
   <details><summary>Answer</summary>ADR 003, OpenAPI-first. PostgreSQL addresses shared records, and Keycloak addresses shared identity.</details>

3. Predict the weakness of an ADR whose only consequence is Faster.
   <details><summary>Answer</summary>It omits costs, conditions and evidence. A reviewable decision must admit trade-offs and name a useful review trigger.</details>

## Common mistakes
These are likely symptoms to inspect, not captured error messages.

| Symptom | Cause | Fix |
|---|---|---|
| The document lists only a chosen tool | The reasoning was omitted | Add context, compared options and at least one cost. |
| A proposed exercise record is labelled Accepted | Status was copied without an actual decision | Keep Proposed until the responsible people accept it. |
| Three unrelated choices fill one record | Decision scope is too broad | Keep one important decision per record and link related records. |

## Best practice
Keep reasons and trade-offs near architecture views so a new reader can understand both arrangement and intent. Source: freeCodeCamp, [System Architecture Documentation Best Practices and Tools](https://www.freecodecamp.org/news/system-architecture-documentation-best-practices-and-tools/) (Tier 2). The specific decisions above come from [platform TDD section 4](../../../../capstones/platform/TDD.md#4-architecture).

## Going further
Read the [platform design](../../../../capstones/platform/TDD.md) without running its setup commands. Lesson 09 makes quality trade-offs explicit rather than hiding them behind a tool name.

## Summary
- You practised how to write an ADR with context, options, a decision and consequences.
- You practised how to explain the platform choices of PostgreSQL, Keycloak and OpenAPI-first.
- You practised how to record a review trigger without pretending a decision has no cost.

## Next lesson
[09. Quality attributes and trade-offs](../phase-3-documenting-decisions/09-quality-attributes-and-trade-offs.md): compare measurable quality needs without hiding hard limits.
