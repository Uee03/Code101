---
track: web
level: 101
phase: 3
phase_name: typescript-and-project
lesson: 11
title: "TypeScript in the browser"
time: 90 min
prerequisites: [101.3.10]
versions: { browser: "current Edge/Chrome/Firefox", node: "26.13.1", npm: "11.20.0", typescript: "7.0.2" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-3-typescript-and-project/11-typescript-in-the-browser/
assets: []
---

# 11. TypeScript in the browser

## Why it matters
A noticeboard keeps its frame while someone replaces the announcement. A browser app keeps page structure and loads data separately. Use a tiny local JSON file, not a remote service or secret key.

## What you will build
A module page that fetches a local mock profile and shows Meet Ada, a biography and three skills.

## Before you start
- Time: 90 min. Two sittings; use the marked break in Steps.
- Complete lessons 01 to 10. Keep the [Web glossary](../../GLOSSARY.md) nearby.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Use the VS Code installed in lesson 01.
- Node 26.13.1 and npm 11.20.0 from lesson 08. TypeScript 7.0.2 is installed per project below.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-3-typescript-and-project/11-typescript-in-the-browser/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson11 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Make and open your own folder
Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson11**. In VS Code choose **File > Open Folder**, select code101/lesson11, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson11.

Windows: enable **View > Show > File name extensions** (Windows 10: View > File name extensions). This prevents index.html.txt. In VS Code the **Explorer** is the left file panel. Hover beside its top folder name and click **New File** (the small page icon with a plus). Use the exact file name shown. First copy the complete listing from this lesson (not the surrounding backticks), click inside the new file and paste it, press **Ctrl+S** (macOS **Command+S**). A dot on an editor tab means unsaved; save until it disappears. A **folder** groups files; a **file** stores saved text.

### Step 2. Open the project terminal
Choose **Terminal > New Terminal**; select PowerShell on Windows if asked. If policy blocks npm.ps1, use npm.cmd/npx.cmd rather than changing policy. The prompt should end in lesson11; use the recovery commands next if not. Linux users of lesson 08's extracted Node must repeat its PATH export in each new terminal.

### Step 3. Check the working folder
All terminal commands run in lesson11, the folder holding package.json. Use these recovery commands from any folder:

**Folder: any (Windows PowerShell)**
```powershell
Set-Location "$HOME\code101\lesson11"
Get-Location
```

**Folder: any (macOS/Linux)**
```bash
cd "$HOME/code101/lesson11"
pwd
```

Expected result: a path ending code101/lesson11. Windows adds a Path heading; usernames/separators vary. Never type the prompt > or $. Create files using the VS Code explorer, not terminal redirection.

### Step 4. Write package.json
Create package.json directly in the lesson folder and save this full **manifest** (project description). A **module** is a file that shares code using import/export. **JSON** (JavaScript Object Notation) is a text format with double-quoted names and strings, commas between entries and braces around groups; no trailing commas. The exact compiler version prevents silent version changes.

**File: `package.json`**
```json
{
  "name": "web-lesson-11",
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
In the file manager open code101/lesson10, select **tsconfig.json**, copy it, then open this lesson's folder and paste it beside package.json. It is **byte-for-byte identical** to lesson 10 Step 5: no settings or paths change; src still holds source and dist still holds generated JavaScript. The only package.json difference from lesson 10 is the project name (`web-lesson-11`). Its full listing is above. If you did not keep lesson10, use the complete [lesson 10 compiler configuration](10-typescript-first-steps.md#step-5-write-tsconfigjson) to create tsconfig.json here. Expected result: tsconfig.json sits beside package.json, not inside src.

### Step 6. Write src/profile.ts
In the VS Code explorer make a New Folder named src if it does not exist. Inside it create profile.ts and save the full file. It exports a data shape and heading function.

**File: `src/profile.ts`**
```typescript
export interface Profile {
  name: string;
  bio: string;
  skills: string[];
}
export function heading(name: string): string {
  return "Meet " + name;
}
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 7. Write src/app.ts
Using the VS Code explorer, make a New Folder named src if it does not exist. Inside it make app.ts and save the full file. This is editable TypeScript, not the browser-loaded file.

**File: `src/app.ts`**
```typescript
import { heading, type Profile } from "./profile.js";
console.log(heading("Ada"));
async function loadProfile(): Promise<void> {
  const name = document.querySelector("#name");
  const bio = document.querySelector("#bio");
  const skills = document.querySelector("#skills");
  if (!name || !bio || !skills) return;
  try {
    const response = await fetch("./profile.json");
    if (!response.ok) throw new Error("Could not load profile");
    const profile: Profile = await response.json();
    name.textContent = heading(profile.name);
    bio.textContent = profile.bio;
    skills.replaceChildren();
    for (const skill of profile.skills) {
      const item = document.createElement("li");
      item.textContent = skill;
      skills.append(item);
    }
  } catch {
    name.textContent = "Profile unavailable";
    bio.textContent = "Check profile.json, then reload.";
  }
}
if (typeof document !== "undefined") {
  void loadProfile();
}
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

**Break - end of sitting 1.** The two TypeScript files and configuration are saved. In sitting 2, add the page/data, install, compile and serve them.

### Step 8. Write index.html
Create index.html in the lesson folder, not inside src. Paste the full file and save. title names the tab; body supplies the page content.

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Local profile</title>
  <script type="module" src="dist/app.js"></script>
</head>
<body>
  <main>
    <h1 id="name">Loading profile...</h1>
    <p id="bio" role="status">Please wait.</p>
    <ul id="skills"></ul>
  </main>
</body>
</html>
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 9. Write profile.json
Create profile.json beside index.html, not inside src or dist. Save the full mock data. This matches fetch("./profile.json").

**File: `profile.json`**
```json
{
  "name": "Ada",
  "bio": "I am learning the web.",
  "skills": [
    "HTML",
    "CSS",
    "TypeScript"
  ]
}
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 10. Install the pinned compiler and keep the lockfile
**Folder: lesson11 (all operating systems)**
```powershell
npm install -D --save-exact typescript@7.0.2 --no-audit --no-fund
```

Expected result on a fresh Windows install (captured; counts and time can differ by platform):
```text
added 2 packages in 3s
```
A repeated install can say **up to date** instead. npm creates **node_modules** (downloaded tools) and **package-lock.json** (exact resolved versions). Do not open or type these generated files. The optional source folder keeps a full lockfile for reproducible installs; when using it, run `npm install --no-audit --no-fund` instead of the download command above.

**Before any `npx tsc`:** check that your terminal is in this lesson's folder containing package.json, and that npm install succeeded. npx uses the **locally installed TypeScript compiler only when it is present**. Outside the project it may ask to install the unrelated package **tsc**: answer **n**, return to the correct folder, run npm install, then retry. Do not accept that package prompt. The Windows policy workaround from lesson 08 is still npm.cmd/npx.cmd.

## Run it
**Folder: lesson11 (all operating systems)**
```powershell
npx tsc
```

Expected result: silence and a normal prompt. dist now has generated .js files. If errors appear, stop; repair source before running any old output. Run the compiled entry:

**Folder: lesson11 (all operating systems)**
```powershell
node dist/app.js
```

Expected Node output (captured):
**Output**
```text
Meet Ada
```

**Serve the page; do not double-click it:**

1. In VS Code open this lesson folder via **File > Open Folder**. Click **Extensions** (four squares in the far-left strip; Ctrl+Shift+X, macOS Command+Shift+X). Search **Live Server**, select **Ritwick Dey** (ritwickdey.LiveServer), then **Install**. No sign-in is needed; close unrelated sign-in prompts. This extension starts a **local web server**, a program sending your local files to the browser through HTTP, and reloads saved changes.
2. Click **Explorer** (two overlapping sheets at the top-left). Right-click index.html > **Open with Live Server**. The browser normally opens `http://127.0.0.1:5500/index.html`; if it shows a folder listing, add index.html at the end of that address. The **status bar** is VS Code's strip along the bottom: it shows **Port: 5500** or another assigned number. A **port** is the numbered doorway for this server. Use the actual address it opens, not file:///.
3. An **origin** is the combination of protocol, host and port: here **http**, **127.0.0.1**, **5500**. Open DevTools with F12 (macOS Command+Option+I), select **Console**, then reload. Click **Network** (use the **>>** overflow menu if hidden): this panel lists requested files. Reload with it open; index.html and generated JavaScript should show status **200**, meaning served successfully.
4. To stop the server, click the displayed **Port: 5500** label. If that does not work, open **View > Command Palette** (Ctrl+Shift+P; macOS Command+Shift+P), type **Live Server: Stop Live Server**, and press Enter. The status label returns to **Go Live**. Restart by right-clicking index.html > Open with Live Server. Keep the same address (including port) while you test.

**Expected browser result:** The tab reads Local profile. Loading profile... and Please wait. may briefly appear. After fetch, the heading is Meet Ada, the paragraph is I am learning the web., and bullets are HTML, CSS and TypeScript.

In Network, look for profile.json with status 200 plus app.js and profile.js. The console helper log Meet Ada does not prove fetch worked. Rename profile.json to profile-missing.json in VS Code and reload: the heading becomes Profile unavailable and the status Check profile.json, then reload. Restore profile.json and reload; the skills return. This is a manual failure-path check, not an automated browser claim.

## How it works
**export** shares Profile and heading from one module. **import** brings them into app.ts; type Profile is a checking-only import removed from JavaScript. The path ends .js because browser/Node load compiled dist/profile.js, not src/profile.ts. The script type module entry loads dist/app.js; its import loads profile.js. Module scripts wait for HTML parsing without defer.

**JSON** (JavaScript Object Notation) is plain-text data with quoted names and string values. string[] means an array of strings. profile.json is **mock data**, a small stand-in for a service response. **fetch** requests ./profile.json relative to the page URL, not the source folder.

An **asynchronous** operation finishes later. A **Promise** represents a future result. **async** permits **await**, pausing that function until a promise completes while other browser work continues. `Promise<void>` means completion without a useful return value. response.ok checks a successful HTTP status; fetch does not reject merely for a 404 response. **throw** creates a failure with new Error. **try/catch** attempts work and handles thrown failures. `catch {` omits an error-variable name because this handler only shows a friendly message, not the error object.

response.json() parses the body. The Profile annotation documents our trusted local mock but does not validate JSON at runtime. Unknown public data needs runtime checking. !name means not found; || is logical or. The early guard returns on any missing target. **replaceChildren** empties the list, **createElement** makes a list item and **append** inserts it. Each skill is plain text through textContent.

A **local web server** serves files from your computer through HTTP. Browsers restrict modules/fetch on file:///; use the Live Server steps above. void loadProfile() ignores its promise because it handles failures internally. Node runs heading once without calling loadProfile. The Node message checks the imported helper only; use the page and Network panel to check loading.

## Try it
Make the loaded profile show a fourth skill, Accessibility. Keep the TypeScript unchanged and retain valid JSON. The page should show four bullets after reload.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson11** folder, copy and paste it beside the original, then rename the copy **lesson11-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson11-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. Keep package.json and tsconfig.json unchanged. npm generates package-lock.json; keep it too. Only the working folder name differs: lesson11-try rather than lesson11. 

<details><summary>Starter files</summary>

**File: `index.html` (starter)**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Local profile</title>
  <script type="module" src="dist/app.js"></script>
</head>
<body>
  <main>
    <h1 id="name">Loading profile...</h1>
    <p id="bio" role="status">Please wait.</p>
    <ul id="skills"></ul>
  </main>
</body>
</html>
```

**File: `profile.json` (starter)**
```json
{
  "name": "Ada",
  "bio": "I am learning the web.",
  "skills": [
    "HTML",
    "CSS",
    "TypeScript"
  ]
}
```

**File: `src/app.ts` (starter)**
```typescript
import { heading, type Profile } from "./profile.js";
console.log(heading("Ada"));
async function loadProfile(): Promise<void> {
  const name = document.querySelector("#name");
  const bio = document.querySelector("#bio");
  const skills = document.querySelector("#skills");
  if (!name || !bio || !skills) return;
  try {
    const response = await fetch("./profile.json");
    if (!response.ok) throw new Error("Could not load profile");
    const profile: Profile = await response.json();
    name.textContent = heading(profile.name);
    bio.textContent = profile.bio;
    skills.replaceChildren();
    for (const skill of profile.skills) {
      const item = document.createElement("li");
      item.textContent = skill;
      skills.append(item);
    }
  } catch {
    name.textContent = "Profile unavailable";
    bio.textContent = "Check profile.json, then reload.";
  }
}
if (typeof document !== "undefined") {
  void loadProfile();
}
```

**File: `src/profile.ts` (starter)**
```typescript
export interface Profile {
  name: string;
  bio: string;
  skills: string[];
}
export function heading(name: string): string {
  return "Meet " + name;
}
```

</details>

Choose Terminal > New Terminal. Check that the prompt ends lesson11-try. Recovery commands run from any folder: Windows PowerShell uses Set-Location "$HOME\code101\lesson11-try"; macOS/Linux uses cd "$HOME/code101/lesson11-try". Linux users repeat their Node PATH export if needed. Then run (Windows npm.cmd/npx.cmd if policy requires):

**Folder: lesson11-try (all operating systems)**
```powershell
npm install --no-audit --no-fund
npx tsc
node dist/app.js
```

For the exercise browser run, repeat the four Live Server actions in Run it with lesson11-try open instead of lesson11. Every filename and setting is identical; stop the previous server first. This profile page has no saved-task storage; just confirm the address points at lesson11-try.

<details><summary>Solution</summary>

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Local profile</title>
  <script type="module" src="dist/app.js"></script>
</head>
<body>
  <main>
    <h1 id="name">Loading profile...</h1>
    <p id="bio" role="status">Please wait.</p>
    <ul id="skills"></ul>
  </main>
</body>
</html>
```

**File: `profile.json`**
```json
{
  "name": "Ada",
  "bio": "I am learning the web.",
  "skills": [
    "HTML",
    "CSS",
    "TypeScript",
    "Accessibility"
  ]
}
```

**File: `src/app.ts`**
```typescript
import { heading, type Profile } from "./profile.js";
console.log(heading("Ada"));
async function loadProfile(): Promise<void> {
  const name = document.querySelector("#name");
  const bio = document.querySelector("#bio");
  const skills = document.querySelector("#skills");
  if (!name || !bio || !skills) return;
  try {
    const response = await fetch("./profile.json");
    if (!response.ok) throw new Error("Could not load profile");
    const profile: Profile = await response.json();
    name.textContent = heading(profile.name);
    bio.textContent = profile.bio;
    skills.replaceChildren();
    for (const skill of profile.skills) {
      const item = document.createElement("li");
      item.textContent = skill;
      skills.append(item);
    }
  } catch {
    name.textContent = "Profile unavailable";
    bio.textContent = "Check profile.json, then reload.";
  }
}
if (typeof document !== "undefined") {
  void loadProfile();
}
```

**File: `src/profile.ts`**
```typescript
export interface Profile {
  name: string;
  bio: string;
  skills: string[];
}
export function heading(name: string): string {
  return "Meet " + name;
}
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. Keep the manifest, compiler config and generated lockfile unchanged. 

Expected Node output (captured from solution):
**Output**
```text
Meet Ada
```

Expected browser change: Four skill bullets appear, with Accessibility last.

</details>

## Check yourself
1. Why does the import end .js?
   <details><summary>Answer</summary>The runtime loads generated JavaScript.</details>
2. Does Profile validate JSON at runtime?
   <details><summary>Answer</summary>No.</details>
3. Where does ./profile.json resolve?
   <details><summary>Answer</summary>Next to index.html at the page URL.</details>
4. Why check response.ok?
   <details><summary>Answer</summary>HTTP error responses do not automatically reject fetch.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Error [ERR_MODULE_NOT_FOUND]: Cannot find module '<project>\lesson11\dist\profile' imported from <project>\lesson11\dist\app.js` | The import says ./profile without .js; this configuration compiles it but the runtime cannot load it | Restore ./profile.js in src/app.ts, save, compile and reload; do not change it to .ts even if a suggestion mentions JSON |
| Loading profile... remains | The compiled entry is missing or the page was opened as file:/// | Run npx tsc in lesson11, then Open with Live Server; inspect F12 > Console and Network |
| Profile unavailable | profile.json is missing or invalid JSON | Restore profile.json beside index.html; keep quoted keys/strings, save and reload |
| npx asks to install tsc | Wrong working folder or missing local compiler | Answer n; return to lesson11 with package.json, npm install --no-audit --no-fund, then npx tsc |

The module error is the captured Node message, with machine folders replaced by `<project>`. In Network, the same missing extension makes the browser request **/dist/profile** rather than **/dist/profile.js**.

## Best practice
Check response.ok and handle failure instead of assuming every fetch succeeds. Source: MDN: Using Fetch https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch

## Next lesson
[12. Project: personal landing page + todo list](../phase-3-typescript-and-project/12-personal-page-and-todos.md): A responsive personal landing page and todo list: add, complete, undo and remove tasks; keep changes in this browser.
