---
track: architecture
level: 101
phase: 3
phase_name: documenting-decisions
lesson: 09
title: "Quality attributes and trade-offs"
time: 45 min
prerequisites: [architecture-101-08]
versions: { format: "Markdown and conservative Mermaid syntax; renderer-dependent" }
verified: not yet run
source: source/architecture/101-zero-to-hero/phase-3-documenting-decisions/09-quality-attributes-and-trade-offs/
assets: []
---

# 09. Quality attributes and trade-offs

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Turn performance, security and availability into concrete quality scenarios.
- Calculate a weighted comparison and explain its assumptions.
- Apply a non-negotiable security gate before choosing an option.

## Recap
1. Why put a cost in an ADR?
   <details><summary>Answer</summary>To preserve the trade-off rather than presenting a choice as free.</details>

2. Who still checks team access after Keycloak signs someone in?
   <details><summary>Answer</summary>The backend API. Authentication is not authorization.</details>

3. Why must a cache not become accidental truth?
   <details><summary>Answer</summary>Its replaceable or stale copies may not reflect authoritative records.</details>

## Why it matters
A restaurant can serve food quickly, protect allergy information and remain open when a delivery is late. Buying speed by ignoring allergies would not be an acceptable trade. Architecture quality choices also have both negotiable preferences and non-negotiable limits.

## What you will build
A short worksheet comparing direct database reads with a possible team-scoped cache for Tasks and Teams. It has measurable scenarios, a scoring table and a reasoned starting choice. The platform does not currently have this response cache.

## Before you start
- Complete lesson 08 and recall storage from lesson 04. Use a text editor and paper or a calculator. No measurements, benchmark tools or running platform are required.
- Time: 45 minutes including reading, saving the files and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/architecture/101-zero-to-hero/phase-3-documenting-decisions/09-quality-attributes-and-trade-offs/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`). Cloning is optional; no terminal is used in the steps below.
- If using a downloaded ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, right-click it in the file manager and choose **Extract Here** or **Extract**. Open the extracted folder, not the compressed ZIP. Phase packs start at the phase's folder; the full repository starts above `source/`.
- Here, “source code” means editable diagram text and short documents, not an application. No command, server or database needs to run. The picture descriptions below are expected output, not yet run or rendered by the author.

## Steps
### Step 1. Prepare a separate work folder
A **folder** groups files; a **file** stores saved content. Open your home folder: on Windows press **Win+E**, type `%USERPROFILE%` in the address bar and press Enter; on macOS use **Finder > Go > Home**; on Linux open your file manager's **Home**. Create `code101` if it is absent, open it, create `architecture` if absent, then open it and create `lesson09`. Windows uses **right-click > New > Folder**, macOS **File > New Folder**, and Linux the file manager's **New Folder** action. Do not put this work inside the optional source pack.

Use a plain-text editor. On Windows open **Notepad** from Start. On macOS open **TextEdit**, choose **Format > Make Plain Text**, and use UTF-8 if an encoding choice appears when saving. On Linux use the desktop's text editor. VS Code, if already available, is also suitable. For each file below choose **File > New**, paste the complete listing and use **File > Save As** in `code101/architecture/lesson09` with the exact shown filename. On Windows choose **All files** if offered so `.txt` is not appended. On macOS decline an offer to append `.txt`. Use UTF-8, a text encoding for international characters, and plain text rather than a word processor's rich-text format. In VS Code an unsaved dot on the tab means save with **Ctrl+S** (macOS **Command+S**).

Windows: enable **File Explorer > View > Show > File name extensions** (Windows 10: **View > File name extensions**) to check filenames. In every OS inspect the final name in the file manager. The folder should now exist and contain only this lesson's files as you add them.

### Step 2. Name the reader and question
A **quality attribute** is a property of how well a system serves a need, not just which feature it has. **Performance** concerns how quickly work completes under stated load. **Security** includes keeping data accessible only to permitted people. **Availability** concerns successful service when needed, under a stated way of measuring it.

A **quality scenario** names the situation and a checkable result. A **trade-off** is a benefit gained while accepting a cost elsewhere. A **weight** expresses how important a scored criterion is in this decision. A **hard gate** is a must-pass condition: other scores cannot compensate for failing it.

### Step 3. Write and compare explicit scenarios
In `code101/architecture/lesson09`, create `quality.md`. The targets below are illustrative production-planning goals for discussion, not measured platform results or promises. They are separate from the platform TDD's local teaching target. Milliseconds (`ms`) are thousandths of a second; 20 concurrent users means 20 using the system at the same time.

**File: `lesson09/quality.md`**
````markdown
# Tasks and Teams: quality decision worksheet

Audience: product, support and implementation teams.
Scope: choosing the first production task-list read design.
Scores below are discussion estimates, not measured evidence.
The platform does not currently have a response cache.

## Scenarios and hard gates
- Performance: 95 of 100 task-list reads finish within 500 ms at 20 concurrent users.
- Security: a signed-in non-member never receives another team's task data.
- Availability: 99.5 percent of task-list reads succeed over a calendar month.
- Hard gate: reject a design that cannot enforce team access on every read.

## Comparison
Scale: 1 poor fit, 2 partial fit, 3 good fit for these scenarios.
Weights: performance 2, security 3, availability 2.

| Option | Performance | Security | Availability | Weighted total |
|---|---:|---:|---:|---:|
| A: API reads PostgreSQL | 2 | 3 | 2 | 17 |
| B: API checks access then reads a team-scoped cache | 3 | 2 | 2 | 16 |

A total: 2 x 2 + 3 x 3 + 2 x 2 = 17.
B total: 3 x 2 + 2 x 3 + 2 x 2 = 16.
B's security score reflects extra risks to manage, not permission to leak data.
B needs permission-aware cache keys, invalidation and a safe database fallback.

## Decision and uncertainty
Start with A because it has fewer moving parts and no cache invalidation burden.
Neither option proves the security gate or the availability target by scoring well.
Measure read durations and denied cross-team reads before accepting production readiness.
Review failed reads over a month; plan backups and test recovery separately.
Revisit caching if the performance scenario fails after query review.
Owner: Tasks and Teams maintainers.
````

The performance scenario counts response durations; the availability scenario counts successful reads over a calendar month. Neither says that a fast but unauthorized reply is acceptable. Each weighted total multiplies the score by its weight, then adds the three products.

Expected saved result: `lesson09/quality.md` contains the listing above. This is a file-content expectation, not a captured renderer result.

### Step 4. Predict, then inspect
Before reading the totals, predict whether B must win because its performance score is higher. Which condition can reject B even if its weighted total wins?

## Run it
No command is needed. Open the saved Markdown documents from `code101/architecture/lesson09` in your text editor and read each section. If using VS Code, open the `.md` file and right-click its tab > **Open Preview**. A plain text view is sufficient for checking the reasoning and the table.

**Expected output, not yet run:** Option A totals 17 and option B totals 16 under the initial weights. The worksheet chooses A as a starting hypothesis, not as measured proof. Team-access enforcement is a gate for both options.

<details><summary>Recorded documentation-only check</summary>

The repository's static check reported the following. This checks source-text coverage and verification specifications, not diagram rendering or application behaviour. It does not remove this lesson's draft notice.

**Recorded output (not application output):**
```text
0 passed, 10 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

</details>

## How it works
A gets a good security-fit score because the proposed read path has fewer permission-sensitive copies to maintain. B may improve repeated reads, but a permission-aware **cache key**, the identifier used to retrieve a cached result, must distinguish the right access context. **Invalidation** means removing or updating a cached copy when relevant facts or permissions change. A **fallback** is a safe alternative path if a dependency fails. B needs all three concerns addressed.

The scores are ordinal discussion estimates: 3 is a better fit than 2 under these assumptions, not a claim of 50 percent improvement. Combining them is a decision aid. Changing weights can change the ranking without changing either design.

**Misconception:** the largest total proves a system is secure or available. **Correction:** hard gates still apply and claims need evidence. The present exercise calculates and reviews assumptions; it does not perform load tests, security tests or recovery drills. Record the chosen approach and uncertainty in an ADR like lesson 08's examples.

## Try it
### 1. Guided practice
Use the starter's new performance weight of 4 while keeping security at 3 and availability at 2. Fill both TODO totals, name the higher-ranked option under those weights and state the evidence still required. Do not weaken the team-access hard gate.

In your file manager open `code101/architecture` and create `lesson09-try`. If using the optional source pack, delete this empty folder, then copy this lesson's `exercise/starter` folder beside `lesson09` and rename the **copy itself** to `lesson09-try`; do not put a folder named starter inside it. Otherwise create each starter file listed below directly inside `lesson09-try` using **File > New > Save As** in your editor. The full starters are shown; no earlier file is assumed to exist in this exercise folder. A `TODO` is an instruction placeholder to replace, not a special Mermaid command.

<details><summary>Complete starter files</summary>

**File: `lesson09-try/quality.md` (starter)**
````markdown
# Reweight the Tasks and Teams options

These are hypothetical estimates, not measurements.
Scale: 1 poor fit, 2 partial fit, 3 good fit.
Keep the team-access security gate unchanged.
New weights: performance 4, security 3, availability 2.

| Option | Performance | Security | Availability | Weighted total |
|---|---:|---:|---:|---:|
| A: API reads PostgreSQL | 2 | 3 | 2 | TODO |
| B: API checks access then reads a team-scoped cache | 3 | 2 | 2 | TODO |

Decision: TODO use the totals and state what still needs evidence.
````

</details>

Save every changed file. For a diagram, use the same raw-source preview procedure from Run it with the exercise file, not the original. For Markdown, reopen the saved exercise document and check its headings and claims. Do not edit the solution before trying.

### 2. Change practice
Write a single new security scenario about a membership being revoked. Explain what cached data would have to stop being returned. Do not invent a result that has been measured.

### 3. Stretch (optional)
Propose a support-cost criterion and explain why adding it could change the decision. There is no single correct weight.

<details><summary>Solution to guided practice</summary>

**File: `lesson09-try/quality.md` (solution)**
````markdown
# Reweight the Tasks and Teams options

These are hypothetical estimates, not measurements.
Scale: 1 poor fit, 2 partial fit, 3 good fit.
Keep the team-access security gate unchanged.
New weights: performance 4, security 3, availability 2.

| Option | Performance | Security | Availability | Weighted total |
|---|---:|---:|---:|---:|
| A: API reads PostgreSQL | 2 | 3 | 2 | 21 |
| B: API checks access then reads a team-scoped cache | 3 | 2 | 2 | 22 |

A total: 4 x 2 + 3 x 3 + 2 x 2 = 21.
B total: 4 x 3 + 3 x 2 + 2 x 2 = 22.
Decision: B ranks first under these new weights, not as a universal winner.
Do not adopt B until team-access checks and cache invalidation are evidenced.
The security gate can reject B regardless of its total.
````

Compare the saved sources, not just their appearance. The solution addresses the guided goal; your change and stretch choices may differ. All displayed behaviour remains an expectation, not a captured execution result.

</details>

## Check yourself
1. Which is a better performance goal: Fast or 95 of 100 reads within 500 ms at 20 concurrent users?
   <details><summary>Answer</summary>The second: it states a load and a checkable result. It remains a target until evidence is collected.</details>

2. Predict whether increasing performance weight can change the winner without new measurements.
   <details><summary>Answer</summary>Yes. The priorities change the weighted totals. In the exercise A becomes 21 and B becomes 22, but the evidence is unchanged.</details>

3. Can a score of 22 excuse leaking another team's task data?
   <details><summary>Answer</summary>No. Team access is a hard gate, not a preference that can be outweighed.</details>

## Common mistakes
These are likely symptoms to inspect, not captured error messages.

| Symptom | Cause | Fix |
|---|---|---|
| A total is called a benchmark | Discussion estimates were mistaken for measurements | Label scores hypothetical and collect evidence separately. |
| A fast design is accepted despite cross-team exposure | A hard gate was treated as a preference | Reject or repair the design before comparing its remaining scores. |
| Availability is described as fast responses | Different quality attributes were conflated | Specify successful reads separately from response duration. |

## Best practice
Tie a quality choice to user needs and explicit trade-offs, not a universal best architecture. Source: ByteByteGo, [Software Architecture](https://bytebytego.com/guides/software-architecture/) (Tier 2).

## Going further
The [platform TDD](../../../../capstones/platform/TDD.md) contains existing requirements; do not silently replace them with these illustrative goals. Lesson 10 assembles views and decisions with a review checklist.

## Summary
- You practised how to turn performance, security and availability into concrete quality scenarios.
- You practised how to calculate a weighted comparison and explain its assumptions.
- You practised how to apply a non-negotiable security gate before choosing an option.

## Next lesson
[10. Project: document a system end to end](../phase-3-documenting-decisions/10-document-a-system.md): assemble and review a complete documentation bundle.
