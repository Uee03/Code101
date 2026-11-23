---
track: web
level: 101
phase: 3
phase_name: typescript-and-project
lesson: 12
title: "Project: personal landing page + todo list"
time: 120-180 min
prerequisites: [101.3.11]
versions: { browser: "current Edge/Chrome/Firefox", node: "26.13.1", npm: "11.20.0", typescript: "7.0.2" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-3-typescript-and-project/12-personal-page-and-todos/
assets: []
---

# 12. Project: personal landing page + todo list

## Why it matters
A pocket notebook remembers your checklist when you close it. This page combines your skills and adds browser storage, so tasks can survive a reload.

## What you will build
A responsive personal landing page and todo list: add, complete, undo and remove tasks; keep changes in this browser.

## Before you start
- Time: 120-180 min. Two sittings; use the marked break in Steps.
- Complete lessons 01 to 11. Keep the [Web glossary](../../GLOSSARY.md) nearby.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Use the VS Code installed in lesson 01.
- Node 26.13.1 and npm 11.20.0 from lesson 08. TypeScript 7.0.2 is installed per project below.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-3-typescript-and-project/12-personal-page-and-todos/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson12 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Make and open your own folder
Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson12**. In VS Code choose **File > Open Folder**, select code101/lesson12, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson12.

Windows: enable **View > Show > File name extensions** (Windows 10: View > File name extensions). This prevents index.html.txt. In VS Code the **Explorer** is the left file panel. Hover beside its top folder name and click **New File** (the small page icon with a plus). Use the exact file name shown. First copy the complete listing from this lesson (not the surrounding backticks), click inside the new file and paste it, press **Ctrl+S** (macOS **Command+S**). A dot on an editor tab means unsaved; save until it disappears. A **folder** groups files; a **file** stores saved text.

### Step 2. Open the project terminal
Choose **Terminal > New Terminal**; select PowerShell on Windows if asked. If policy blocks npm.ps1, use npm.cmd/npx.cmd rather than changing policy. The prompt should end in lesson12; use the recovery commands next if not. Linux users of lesson 08's extracted Node must repeat its PATH export in each new terminal.

### Step 3. Check the working folder
All terminal commands run in lesson12, the folder holding package.json. Use these recovery commands from any folder:

**Folder: any (Windows PowerShell)**
```powershell
Set-Location "$HOME\code101\lesson12"
Get-Location
```

**Folder: any (macOS/Linux)**
```bash
cd "$HOME/code101/lesson12"
pwd
```

Expected result: a path ending code101/lesson12. Windows adds a Path heading; usernames/separators vary. Never type the prompt > or $. Create files using the VS Code explorer, not terminal redirection.

### Step 4. Write package.json
Create package.json directly in the lesson folder and save this full **manifest** (project description). A **module** is a file that shares code using import/export. **JSON** (JavaScript Object Notation) is a text format with double-quoted names and strings, commas between entries and braces around groups; no trailing commas. The exact compiler version prevents silent version changes.

**File: `package.json`**
```json
{
  "name": "web-lesson-12",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "tsc"
  },
  "engines": {
    "node": "26.13.1",
    "npm": "11.20.0"
  },
  "devDependencies": {
    "typescript": "7.0.2"
  }
}
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 5. Copy the unchanged compiler configuration
In the file manager open code101/lesson10, select **tsconfig.json**, copy it, then open this lesson's folder and paste it beside package.json. It is **byte-for-byte identical** to lesson 10 Step 5: no settings or paths change; src still holds source and dist still holds generated JavaScript. The only package.json difference from lesson 10 is the project name (`web-lesson-12`). Its full listing is above. If you did not keep lesson10, use the complete [lesson 10 compiler configuration](10-typescript-first-steps.md#step-5-write-tsconfigjson) to create tsconfig.json here. Expected result: tsconfig.json sits beside package.json, not inside src.

### Step 6. Write src/app.ts
Using the VS Code explorer, make a New Folder named src if it does not exist. Inside it make app.ts and save the full file. This is editable TypeScript, not the browser-loaded file.

**File: `src/app.ts`**
```typescript
interface Todo {
  id: number;
  text: string;
  done: boolean;
}
function taskCount(todos: Todo[]): string {
  return todos.length + " tasks";
}
console.log(taskCount([]));
function start(): void {
  const form = document.querySelector("#todo-form");
  const input = document.querySelector("#task");
  const list = document.querySelector("#tasks");
  const status = document.querySelector("#status");
  if (!(form instanceof HTMLFormElement) ||
      !(input instanceof HTMLInputElement) || !list || !status) return;
  const key = "code101-web-todos-v1";
  let todos: Todo[] = [];
  let storageNotice = "";
  try {
    const saved: unknown = JSON.parse(localStorage.getItem(key) ?? "[]");
    if (Array.isArray(saved)) {
      todos = saved.filter((item): item is Todo =>
        typeof item === "object" && item !== null &&
        typeof item.id === "number" && typeof item.text === "string" &&
        typeof item.done === "boolean");
    }
  } catch {
    storageNotice = " Saved tasks unavailable; starting empty.";
  }
  function save(): void {
    try {
      localStorage.setItem(key, JSON.stringify(todos));
      storageNotice = "";
    } catch {
      storageNotice = " Storage unavailable; changes last only this visit.";
    }
  }
  const render = function (): void {
    list.replaceChildren();
    status.textContent = taskCount(todos) + storageNotice;
    for (const todo of todos) {
      const item = document.createElement("li");
      const label = document.createElement("span");
      label.textContent = todo.text;
      if (todo.done) label.className = "done";
      const toggle = document.createElement("button");
      toggle.type = "button";
      toggle.textContent = todo.done ? "Undo" : "Done";
      toggle.setAttribute("aria-label", "Mark " + todo.text + (todo.done ? " as not done (Undo)" : " as done (Done)"));
      toggle.addEventListener("click", function () {
        todo.done = !todo.done;
        save();
        render();
      });
      const remove = document.createElement("button");
      remove.type = "button";
      remove.textContent = "Remove";
      remove.setAttribute("aria-label", "Remove " + todo.text);
      remove.addEventListener("click", function () {
        todos = todos.filter(function (item) { return item.id !== todo.id; });
        save();
        render();
      });
      item.append(label, toggle, remove);
      list.append(item);
    }
  };
  form.addEventListener("submit", function (event) {
    event.preventDefault();
    const text = input.value.trim();
    if (text === "") return;
    todos.push({ id: Date.now(), text: text, done: false });
    input.value = "";
    save();
    render();
    input.focus();
  });
  render();
}
if (typeof document !== "undefined") {
  start();
}
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

**Break - end of sitting 1.** Save the TypeScript file and close the editor if needed. In sitting 2, add HTML/CSS, install, compile and try the page. Allow 60-90 minutes per sitting; do not try to memorize the whole program at once.

### Step 7. Write index.html
Create index.html in the lesson folder, not inside src. Paste the full file and save. title names the tab; body supplies the page content.

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Ada landing page</title>
  <link rel="stylesheet" href="style.css">
  <script type="module" src="dist/app.js"></script>
</head>
<body>
  <header><h1>Ada's little corner</h1><p>Learner, cook and walker.</p></header>
  <main>
    <section aria-labelledby="about-title">
      <h2 id="about-title">About me</h2>
      <p>I practise one small skill each day.</p>
      <a href="https://developer.mozilla.org/">My learning guide</a>
    </section>
    <section aria-labelledby="todo-title">
      <h2 id="todo-title">My tasks</h2>
      <form id="todo-form">
        <label for="task">New task</label>
        <input id="task" name="task" type="text" maxlength="80" required>
        <button type="submit">Add task</button>
      </form>
      <p id="status" role="status">0 tasks</p>
      <ul id="tasks"></ul>
    </section>
  </main>
  <footer><p>Made while learning Web Foundations.</p></footer>
</body>
</html>
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 8. Write style.css
Create style.css beside index.html. Paste the full file and save; the HTML link points to this spelling.

**File: `style.css`**
```css
* { box-sizing: border-box; }
body { margin: 0; font-family: Arial, sans-serif; color: #172554; background: #f1f5f9; }
header, main, footer { max-width: 900px; margin: auto; padding: 24px; }
main { display: grid; grid-template-columns: 1fr; gap: 24px; }
section { padding: 20px; background: white; border: 2px solid #cbd5e1; }
form { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
input { min-width: 0; max-width: 100%; padding: 8px; }
button { padding: 8px 12px; cursor: pointer; }
li { margin: 12px 0; }
li button { margin-left: 8px; }
.done { text-decoration: line-through; }
:focus-visible { outline: 3px solid #1d4ed8; outline-offset: 3px; }
@media (min-width: 700px) {
  main { grid-template-columns: 1fr 2fr; }
}
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 9. Install the pinned compiler and keep the lockfile
**Folder: lesson12 (all operating systems)**
```powershell
npm install -D --save-exact typescript@7.0.2 --no-audit --no-fund
```

Expected result on a fresh Windows install (captured; counts and time can differ by platform):
```text
added 2 packages in 2s
```
A repeated install can say **up to date** instead. npm creates **node_modules** (downloaded tools) and **package-lock.json** (exact resolved versions). Do not open or type these generated files. The optional source folder keeps a full lockfile for reproducible installs; when using it, run `npm install --no-audit --no-fund` instead of the download command above.

**Before any `npx tsc`:** check that your terminal is in this lesson's folder containing package.json, and that npm install succeeded. npx uses the **locally installed TypeScript compiler only when it is present**. Outside the project it may ask to install the unrelated package **tsc**: answer **n**, return to the correct folder, run npm install, then retry. Do not accept that package prompt. The Windows policy workaround from lesson 08 is still npm.cmd/npx.cmd.

## Run it
**Folder: lesson12 (all operating systems)**
```powershell
npx tsc
```

Expected result: silence and a normal prompt. dist now has generated .js files. If errors appear, stop; repair source before running any old output. Run the compiled entry:

**Folder: lesson12 (all operating systems)**
```powershell
node dist/app.js
```

Expected Node output (captured):
**Output**
```text
0 tasks
```

**Serve the page; do not double-click it:**

1. In VS Code open this lesson folder via **File > Open Folder**. Click **Extensions** (four squares in the far-left strip; Ctrl+Shift+X, macOS Command+Shift+X). Search **Live Server**, select **Ritwick Dey** (ritwickdey.LiveServer), then **Install**. No sign-in is needed; close unrelated sign-in prompts. This extension starts a **local web server**, a program sending your local files to the browser through HTTP, and reloads saved changes.
2. Click **Explorer** (two overlapping sheets at the top-left). Right-click index.html > **Open with Live Server**. The browser normally opens `http://127.0.0.1:5500/index.html`; if it shows a folder listing, add index.html at the end of that address. The **status bar** is VS Code's strip along the bottom: it shows **Port: 5500** or another assigned number. A **port** is the numbered doorway for this server. Use the actual address it opens, not file:///.
3. An **origin** is the combination of protocol, host and port: here **http**, **127.0.0.1**, **5500**. Open DevTools with F12 (macOS Command+Option+I), select **Console**, then reload. Click **Network** (use the **>>** overflow menu if hidden): this panel lists requested files. Reload with it open; index.html and generated JavaScript should show status **200**, meaning served successfully.
4. To stop the server, click the displayed **Port: 5500** label. If that does not work, open **View > Command Palette** (Ctrl+Shift+P; macOS Command+Shift+P), type **Live Server: Stop Live Server**, and press Enter. The status label returns to **Go Live**. Restart by right-clicking index.html > Open with Live Server. Keep the same address (including port) while you test.

**Expected browser result:** The tab reads Ada landing page. Ada's little corner and Learner, cook and walker. appear at the top. At 700px and above About me is left and My tasks right; below 700px they stack. With no saved data status is 0 tasks. Added rows have Done and Remove; completion crosses text out and changes Done to Undo.

**Manual project walkthrough:**
1. At the same Live Server address, with no saved tasks, enter Read lesson 12 and Add task: one row and 1 tasks appear. The intentionally simple counter does not singularize tasks.
2. Choose Done: text is crossed out and the button says Undo. Choose Undo to restore it. Enter Practise CSS and press Enter: a second row and 2 tasks appear.
3. Reload the same URL: both tasks remain if storage works. Remove Read lesson 12, then reload: only Practise CSS remains.
4. **Focus** means the control receiving keyboard input. Tab through the form/buttons and inspect the blue focus outline. Use lesson 05 Step 4's device mode to compare widths 699 and 700, or narrow/widen the window. Enter spaces only: no task is added after trimming.
5. If storage is blocked, Storage unavailable; changes last only this visit. appears. Read failure shows Saved tasks unavailable; starting empty. The app still accepts tasks this visit. Do not use private data.

The Node message only counts an empty array; use the walkthrough above to check page behavior.

## How it works
### Start and check the controls
Todo describes one task. taskCount reads **length**, the number of array items. The terminal prints 0 tasks for the empty array. In the browser start finds the controls. **instanceof** checks an element's kind, so the guard knows form and input have form/input features. A failed lookup returns null; the guard exits before touching absent controls.

### Restore saved tasks
**localStorage** stores strings for one origin (the protocol/host/port defined in lesson 11). getItem returns a string or null. **JSON.parse** turns JSON text into values; **JSON.stringify** turns values into JSON text. **??** (nullish coalescing) uses its right-hand fallback only when the left side is null or undefined. It is JavaScript syntax, not a terminal command. **unknown** means data that must be checked before use. Array.isArray checks that it is an array; **filter** keeps only matching entries. && requires all checks to pass; fields are read only after excluding null.

Keep the saved.filter checking block as supplied. `(item) => ...` is an **arrow function**, a compact function expression (a function used as a value). The `item is Todo` annotation tells TypeScript which shape those checks establish. Do not worry about writing that annotation yourself today; the goal is to reject saved values that are not tasks.

### Save and redraw
save catches failures so blocked storage does not break task entry. render clears the list with replaceChildren, updates the count and creates one li per task. The **ternary operator**, `condition ? first : second`, chooses Undo or Done. ! flips a boolean; className applies the crossing-out style. setAttribute adds an accessible action name including the task text. The label also includes the visible Done/Undo word. Remove uses filter to keep tasks with different IDs. Every task handler saves and redraws.

Keep `const render = function ...` after the missing-control guard, as shown. You do not need the advanced terms closure or hoisting for this project: its handlers use the surrounding task data, and this placement lets TypeScript retain the guard's checks.

### Add a task
The **submit event** fires for Add task or Enter. **preventDefault** stops normal form navigation. input.value is typed text; **trim** removes outer spaces. Empty text exits; **push** adds a Todo object. Date.now supplies a millisecond timestamp for a small single-user demo ID, not a multi-user ID system. The handler clears input, saves, redraws and puts the cursor back with input.focus(). Initial render shows restored tasks.

### Read the page and styles
section groups related content; aria-labelledby points to a heading ID. CSS reuses Grid and Flexbox. **Focus** is the control receiving keyboard input. :focus-visible is a **pseudo-class**, a selector for a state; here it gives keyboard users a blue outline. Storage is not an account or backup: another origin/browser or cleared site data loses the list. Never store secrets. Redrawing replaces focused task buttons; a larger app would restore focus after each change.

## Try it
1. Make this page yours: replace Ada with your name and replace the two sample self-description sentences with your own. The task behavior must stay unchanged. Keep the browser-tab title unchanged so you can still recognize it. The solution below retains sample personal text because your wording will vary.
2. Add a **Clear all** button below the form with id **clear** and type **button**. It must remove every task, update the count and keep the list empty after reload. Put its listener after the submit handler and before the final render call inside start.

**Hint:** querySelector can return null. Check the new control exists, like the other controls, before registering its listener; TypeScript will complain if you skip this check. Use the existing save/redraw functions rather than adding a second storage mechanism.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson12** folder, copy and paste it beside the original, then rename the copy **lesson12-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson12-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. Keep package.json and tsconfig.json unchanged. npm generates package-lock.json; keep it too. Only the working folder name differs: lesson12-try rather than lesson12. 

<details><summary>Starter files</summary>

**File: `index.html` (starter)**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Ada landing page</title>
  <link rel="stylesheet" href="style.css">
  <script type="module" src="dist/app.js"></script>
</head>
<body>
  <header><h1>Ada's little corner</h1><p>Learner, cook and walker.</p></header>
  <main>
    <section aria-labelledby="about-title">
      <h2 id="about-title">About me</h2>
      <p>I practise one small skill each day.</p>
      <a href="https://developer.mozilla.org/">My learning guide</a>
    </section>
    <section aria-labelledby="todo-title">
      <h2 id="todo-title">My tasks</h2>
      <form id="todo-form">
        <label for="task">New task</label>
        <input id="task" name="task" type="text" maxlength="80" required>
        <button type="submit">Add task</button>
      </form>
      <p id="status" role="status">0 tasks</p>
      <ul id="tasks"></ul>
    </section>
  </main>
  <footer><p>Made while learning Web Foundations.</p></footer>
</body>
</html>
```

**File: `src/app.ts` (starter)**
```typescript
interface Todo {
  id: number;
  text: string;
  done: boolean;
}
function taskCount(todos: Todo[]): string {
  return todos.length + " tasks";
}
console.log(taskCount([]));
function start(): void {
  const form = document.querySelector("#todo-form");
  const input = document.querySelector("#task");
  const list = document.querySelector("#tasks");
  const status = document.querySelector("#status");
  if (!(form instanceof HTMLFormElement) ||
      !(input instanceof HTMLInputElement) || !list || !status) return;
  const key = "code101-web-todos-v1";
  let todos: Todo[] = [];
  let storageNotice = "";
  try {
    const saved: unknown = JSON.parse(localStorage.getItem(key) ?? "[]");
    if (Array.isArray(saved)) {
      todos = saved.filter((item): item is Todo =>
        typeof item === "object" && item !== null &&
        typeof item.id === "number" && typeof item.text === "string" &&
        typeof item.done === "boolean");
    }
  } catch {
    storageNotice = " Saved tasks unavailable; starting empty.";
  }
  function save(): void {
    try {
      localStorage.setItem(key, JSON.stringify(todos));
      storageNotice = "";
    } catch {
      storageNotice = " Storage unavailable; changes last only this visit.";
    }
  }
  const render = function (): void {
    list.replaceChildren();
    status.textContent = taskCount(todos) + storageNotice;
    for (const todo of todos) {
      const item = document.createElement("li");
      const label = document.createElement("span");
      label.textContent = todo.text;
      if (todo.done) label.className = "done";
      const toggle = document.createElement("button");
      toggle.type = "button";
      toggle.textContent = todo.done ? "Undo" : "Done";
      toggle.setAttribute("aria-label", "Mark " + todo.text + (todo.done ? " as not done (Undo)" : " as done (Done)"));
      toggle.addEventListener("click", function () {
        todo.done = !todo.done;
        save();
        render();
      });
      const remove = document.createElement("button");
      remove.type = "button";
      remove.textContent = "Remove";
      remove.setAttribute("aria-label", "Remove " + todo.text);
      remove.addEventListener("click", function () {
        todos = todos.filter(function (item) { return item.id !== todo.id; });
        save();
        render();
      });
      item.append(label, toggle, remove);
      list.append(item);
    }
  };
  form.addEventListener("submit", function (event) {
    event.preventDefault();
    const text = input.value.trim();
    if (text === "") return;
    todos.push({ id: Date.now(), text: text, done: false });
    input.value = "";
    save();
    render();
    input.focus();
  });
  render();
}
if (typeof document !== "undefined") {
  start();
}
```

**File: `style.css` (starter)**
```css
* { box-sizing: border-box; }
body { margin: 0; font-family: Arial, sans-serif; color: #172554; background: #f1f5f9; }
header, main, footer { max-width: 900px; margin: auto; padding: 24px; }
main { display: grid; grid-template-columns: 1fr; gap: 24px; }
section { padding: 20px; background: white; border: 2px solid #cbd5e1; }
form { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
input { min-width: 0; max-width: 100%; padding: 8px; }
button { padding: 8px 12px; cursor: pointer; }
li { margin: 12px 0; }
li button { margin-left: 8px; }
.done { text-decoration: line-through; }
:focus-visible { outline: 3px solid #1d4ed8; outline-offset: 3px; }
@media (min-width: 700px) {
  main { grid-template-columns: 1fr 2fr; }
}
```

</details>

Choose Terminal > New Terminal. Check that the prompt ends lesson12-try. Recovery commands run from any folder: Windows PowerShell uses Set-Location "$HOME\code101\lesson12-try"; macOS/Linux uses cd "$HOME/code101/lesson12-try". Linux users repeat their Node PATH export if needed. Then run (Windows npm.cmd/npx.cmd if policy requires):

**Folder: lesson12-try (all operating systems)**
```powershell
npm install --no-audit --no-fund
npx tsc
node dist/app.js
```

For the exercise browser run, repeat the four Live Server actions in Run it with lesson12-try open instead of lesson12. Every filename and setting is identical; stop the previous server first. Keeping the same address (including port) can share saved tasks.

<details><summary>Solution</summary>

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Ada landing page</title>
  <link rel="stylesheet" href="style.css">
  <script type="module" src="dist/app.js"></script>
</head>
<body>
  <header><h1>Ada's little corner</h1><p>Learner, cook and walker.</p></header>
  <main>
    <section aria-labelledby="about-title">
      <h2 id="about-title">About me</h2>
      <p>I practise one small skill each day.</p>
      <a href="https://developer.mozilla.org/">My learning guide</a>
    </section>
    <section aria-labelledby="todo-title">
      <h2 id="todo-title">My tasks</h2>
      <form id="todo-form">
        <label for="task">New task</label>
        <input id="task" name="task" type="text" maxlength="80" required>
        <button type="submit">Add task</button>
      </form>
      <button id="clear" type="button">Clear all</button>
      <p id="status" role="status">0 tasks</p>
      <ul id="tasks"></ul>
    </section>
  </main>
  <footer><p>Made while learning Web Foundations.</p></footer>
</body>
</html>
```

**File: `src/app.ts`**
```typescript
interface Todo {
  id: number;
  text: string;
  done: boolean;
}
function taskCount(todos: Todo[]): string {
  return todos.length + " tasks";
}
console.log(taskCount([]));
function start(): void {
  const form = document.querySelector("#todo-form");
  const input = document.querySelector("#task");
  const list = document.querySelector("#tasks");
  const status = document.querySelector("#status");
  if (!(form instanceof HTMLFormElement) ||
      !(input instanceof HTMLInputElement) || !list || !status) return;
  const key = "code101-web-todos-v1";
  let todos: Todo[] = [];
  let storageNotice = "";
  try {
    const saved: unknown = JSON.parse(localStorage.getItem(key) ?? "[]");
    if (Array.isArray(saved)) {
      todos = saved.filter((item): item is Todo =>
        typeof item === "object" && item !== null &&
        typeof item.id === "number" && typeof item.text === "string" &&
        typeof item.done === "boolean");
    }
  } catch {
    storageNotice = " Saved tasks unavailable; starting empty.";
  }
  function save(): void {
    try {
      localStorage.setItem(key, JSON.stringify(todos));
      storageNotice = "";
    } catch {
      storageNotice = " Storage unavailable; changes last only this visit.";
    }
  }
  const render = function (): void {
    list.replaceChildren();
    status.textContent = taskCount(todos) + storageNotice;
    for (const todo of todos) {
      const item = document.createElement("li");
      const label = document.createElement("span");
      label.textContent = todo.text;
      if (todo.done) label.className = "done";
      const toggle = document.createElement("button");
      toggle.type = "button";
      toggle.textContent = todo.done ? "Undo" : "Done";
      toggle.setAttribute("aria-label", "Mark " + todo.text + (todo.done ? " as not done (Undo)" : " as done (Done)"));
      toggle.addEventListener("click", function () {
        todo.done = !todo.done;
        save();
        render();
      });
      const remove = document.createElement("button");
      remove.type = "button";
      remove.textContent = "Remove";
      remove.setAttribute("aria-label", "Remove " + todo.text);
      remove.addEventListener("click", function () {
        todos = todos.filter(function (item) { return item.id !== todo.id; });
        save();
        render();
      });
      item.append(label, toggle, remove);
      list.append(item);
    }
  };
  form.addEventListener("submit", function (event) {
    event.preventDefault();
    const text = input.value.trim();
    if (text === "") return;
    todos.push({ id: Date.now(), text: text, done: false });
    input.value = "";
    save();
    render();
    input.focus();
  });
  const clear = document.querySelector("#clear");
  if (clear) {
    clear.addEventListener("click", function () {
      todos = [];
      save();
      render();
    });
  }
  render();
}
if (typeof document !== "undefined") {
  start();
}
```

**File: `style.css`**
```css
* { box-sizing: border-box; }
body { margin: 0; font-family: Arial, sans-serif; color: #172554; background: #f1f5f9; }
header, main, footer { max-width: 900px; margin: auto; padding: 24px; }
main { display: grid; grid-template-columns: 1fr; gap: 24px; }
section { padding: 20px; background: white; border: 2px solid #cbd5e1; }
form { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
input { min-width: 0; max-width: 100%; padding: 8px; }
button { padding: 8px 12px; cursor: pointer; }
li { margin: 12px 0; }
li button { margin-left: 8px; }
.done { text-decoration: line-through; }
:focus-visible { outline: 3px solid #1d4ed8; outline-offset: 3px; }
@media (min-width: 700px) {
  main { grid-template-columns: 1fr 2fr; }
}
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. Keep the manifest, compiler config and generated lockfile unchanged. 

Expected Node output (captured from solution):
**Output**
```text
0 tasks
```

Expected browser change: Clear all appears below the form. It empties all rows and shows 0 tasks; reload leaves the list empty if storage worked.

</details>

## Check yourself
1. Why preventDefault on submit?
   <details><summary>Answer</summary>To stay on this page.</details>
2. Why textContent for tasks?
   <details><summary>Answer</summary>To show plain text rather than interpret HTML.</details>
3. Why might another port have no saved tasks?
   <details><summary>Answer</summary>Port is part of the origin.</details>
4. What happens after remove and reload?
   <details><summary>Answer</summary>The task stays absent if storage worked.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `src/app.ts(80,3): error TS18047: 'clear' is possibly 'null'.` | The exercise uses clear before checking that querySelector found it | Check the new control exists before its listener; use the same guarded pattern as the other controls. Positions vary with your edits |
| Three TS18047 errors for list/status after changing render | render was rewritten as a function declaration | Keep the guarded const render function expression as supplied; the three captured diagnostics are below |
| Changes do not appear | Unsaved source or old generated JavaScript | Save src/app.ts; run npx tsc successfully, then reload the same Live Server address |
| npx asks to install tsc | Missing compiler or wrong folder | Answer n; return to lesson12 with package.json, npm install --no-audit --no-fund, then npx tsc |
| Storage unavailable; changes last only this visit. | The browser refused a storage write | Tasks still work for this visit; do not assume reload will preserve them or put private data here |

Captured diagnostics for changing the supplied render expression into a function declaration (three errors, not one):
```text
src/app.ts(40,5): error TS18047: 'list' is possibly 'null'.
src/app.ts(41,5): error TS18047: 'status' is possibly 'null'.
src/app.ts(66,7): error TS18047: 'list' is possibly 'null'.
```
These line numbers refer to the unchanged sample; the Clear all exercise diagnostic is a separate missing-control check.

## Best practice
Treat localStorage as fallible and origin-specific; keep sensitive information out of it. Source: MDN: Window localStorage https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage

## Next lesson
None - Web Foundations 101 is complete. Keep this project as a reference, then personalise its text and colors with the same compile/save/reload workflow. Deployment, accounts and backend services are outside this level.
