---
track: web
level: 101
phase: 2
phase_name: layout-and-javascript
lesson: 08
title: "JavaScript basics"
time: 90 min
prerequisites: [101.2.07]
versions: { browser: "current Edge/Chrome/Firefox", node: "26.13.1", npm: "11.20.0" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-2-layout-and-javascript/08-javascript-basics/
assets: []
---

# 08. JavaScript basics

## Why it matters
A recipe remembers quantities, chooses ingredients and repeats mixing steps. JavaScript gives a page the same abilities. Start with a small program printing a plan before changing the page.

## What you will build
A study plan running in the browser's **Console** (its program-message panel) and **Node.js** (a program that runs JavaScript outside the browser): a greeting, a decision, three topics and a session count.

## Before you start
- Time: 90 min. Two sittings; use the marked break in Steps.
- Complete lessons 01 to 07. Keep the [Web glossary](../../GLOSSARY.md) nearby.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Use the VS Code installed in lesson 01.
- Node 26.13.1 and npm 11.20.0; installation is shown below. 
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-2-layout-and-javascript/08-javascript-basics/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson08 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Make and open your own folder
Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson08**. In VS Code choose **File > Open Folder**, select code101/lesson08, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson08.

Windows: enable **View > Show > File name extensions** (Windows 10: View > File name extensions). This prevents index.html.txt. In VS Code the **Explorer** is the left file panel. Hover beside its top folder name and click **New File** (the small page icon with a plus). Use the exact file name shown. First copy the complete listing from this lesson (not the surrounding backticks), click inside the new file and paste it, press **Ctrl+S** (macOS **Command+S**). A dot on an editor tab means unsaved; save until it disappears. A **folder** groups files; a **file** stores saved text.

### Step 2. Install or confirm Node LTS, then open a terminal
A **terminal** is a window for typing commands to your operating system, unlike the browser's Console for JavaScript. **npm** is the package manager bundled with Node: it downloads reusable code packages in lesson 10. **LTS** means Long-Term Support, a release line receiving extended fixes.

1. Visit [Node 26.13.1's official archive](https://nodejs.org/en/download/archive/v26.13.1). The [release table](https://nodejs.org/en/about/previous-releases) marks v26 as **LTS**, Long-Term Support, a release line receiving extended fixes. Do not choose v27 Alpha. This course pins Node 26.13.1 and bundled npm 11.20.0, checked on 2026-11-23.
2. **Windows:** Settings > System > About lists System type. Most PCs are x64; choose ARM64 only for an ARM-based PC. Download node-v26.13.1-x64.msi (or ARM64 .msi) from the archive. Open it, choose Next, accept the license, keep the default folder and npm/Add to PATH features, then Next > Install > Finish. Optional native-addon build tools are not needed. Approve the installer prompt if your organization permits it.
3. **macOS:** download node-v26.13.1.pkg from the archive, open it, then Continue, accept the license, Install, and Close. Enter your Mac password when requested.
4. **Linux (Ubuntu/Debian x64):** use your browser to download node-v26.13.1-linux-x64.tar.xz from the archive. In Files > Downloads, right-click it > Extract Here. Move the extracted node-v26.13.1-linux-x64 folder into Home. On ARM64 use linux-arm64 and replace x64 with arm64 in the path below. For other platforms choose the matching official binary and documentation. If this archive route does not fit your distribution, use the [official Node download selector](https://nodejs.org/en/download) instead: select **Linux** and your architecture and follow its displayed package-manager instructions for your system. Do not run both install routes.
5. Close VS Code and reopen it: old terminals may not see new **PATH** entries. PATH is the list of folders searched for commands. Open the lesson folder, then **Terminal > New Terminal**; on Windows choose PowerShell if asked. Text before > (or $ on macOS/Linux) is the **prompt**, not part of a command; never type it. The Windows PowerShell script-policy trap is shown immediately below the version command.

**Folder: home (Linux x64 only)**
```bash
export PATH="$HOME/node-v26.13.1-linux-x64/bin:$PATH"
```
Expected result: silence. This sets PATH for this terminal; repeat it in each new terminal. ARM64 users substitute arm64 for x64 in the folder name. No shell configuration file is needed.

**Folder: your lesson folder (Windows PowerShell; identical commands on macOS/Linux)**
```powershell
node --version
npm --version
```
Expected output from the pinned tools, captured on the author machine:
```text
v26.13.1
11.20.0
```

**Windows PowerShell: if the first npm command is blocked**, this is the captured message (installation folder replaced by `<node-install>`):
```text
npm : File <node-install>\npm.ps1 cannot be loaded because running scripts is disabled on this system. For
more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
```
Use **npm.cmd --version** instead; it prints **11.20.0**. For **every later** npm/npx command in this course, use **npm.cmd**/**npx.cmd** if needed, for example `npm.cmd install` and `npx.cmd tsc`. These Windows launchers avoid the blocked PowerShell script; you do not need to weaken your execution policy. If your organization manages it, ask IT rather than changing it. macOS/Linux keep npm and npx.



### Step 3. Check the working folder
All terminal commands run in lesson08, the folder holding index.html. Use these recovery commands from any folder:

**Folder: any (Windows PowerShell)**
```powershell
Set-Location "$HOME\code101\lesson08"
Get-Location
```

**Folder: any (macOS/Linux)**
```bash
cd "$HOME/code101/lesson08"
pwd
```

Expected result: a path ending code101/lesson08. Windows adds a Path heading; usernames/separators vary. Never type the prompt > or $. Create files using the VS Code explorer, not terminal redirection.

**Break - end of sitting 1.** Node and npm work and your terminal is in lesson08. In sitting 2, write and run the study plan.

### Step 4. Write index.html
Create index.html directly in the lesson folder. Paste the full file and save. title names the tab; body supplies the page content.

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>JavaScript practice</title>
  <script src="basics.js" defer></script>
</head>
<body>
  <h1>JavaScript practice</h1>
  <p>Open the browser console to see the practice plan.</p>
</body>
</html>
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 5. Write basics.js
Create basics.js beside index.html. Paste and save; the script runs on browser load and can also run in Node.

**File: `basics.js`**
```javascript
const learner = "Ada";
let sessions = 2;
sessions = sessions + 1;
const ready = sessions >= 3;
function greeting(name) {
  return "Hello, " + name + "!";
}
console.log(greeting(learner));
if (ready === true) {
  console.log("Ready for practice");
} else {
  console.log("Plan one more session");
}
const topics = ["HTML", "CSS", "JavaScript"];
for (const topic of topics) {
  console.log("Study: " + topic);
}
console.log("Sessions: " + sessions);
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

## Run it
Save all files. In your file manager open code101/lesson08, right-click index.html > Open with > Edge, Chrome or Firefox (macOS: Open With). Double-click works if HTML is associated with a browser. VS Code's text view is not the page preview. A local address starts file:///. After every edit save, then reload **Ctrl+R** (macOS **Command+R**).

**Browser Console:** open DevTools with F12 (macOS Command+Option+I), select **Console**, then reload. The six lines below appear; browsers may add source links. Do not paste code into Console or bypass paste protection: the saved script runs when the page reloads.

**Node:** in the lesson08 terminal run:

**Folder: lesson08 (all operating systems)**
```powershell
node basics.js
```

Expected output (captured in Node; browser log lines match):
**Output**
```text
Hello, Ada!
Ready for practice
Study: HTML
Study: CSS
Study: JavaScript
Sessions: 3
```

**Expected browser result:** The tab reads JavaScript practice. The page shows JavaScript practice and Open the browser console to see the practice plan. The six output lines appear in Console, not as page text.

## How it works
**JavaScript** performs actions and makes decisions. A **variable** names a value. const prevents assigning a new value to that name; let permits reassignment. A **string** is quoted text, a **number** is a quantity, a **boolean** is true or false. One = assigns; >= compares greater-than-or-equal; === checks equality without automatic type conversion.

A **function** is a reusable group of instructions. name is its **parameter**, the local name for an incoming value; the variable `learner` supplies the **argument**, the actual passed value. **return** sends the result back. console.log(greeting(learner)) first calls greeting, then logs its result: inner call before outer call. + adds numbers or joins strings depending on the values.

A **condition** is a yes/no expression. if runs its **block**, instructions inside braces, when true; else runs the alternative. An **array** is an ordered collection in square brackets. for...of is a **loop**, repeating a block once per array item; topic receives each value in order.

A **console** shows program messages and lets you enter JavaScript. Browser **developer tools** include it. A **terminal** is a window for operating-system commands, not the browser console. **Node.js** is a **runtime**, a program running JavaScript outside the browser. node basics.js runs a file from the terminal's current folder. Node does not have the browser's page elements; lesson 09 explains how to change them. **npm** is the package manager bundled with Node; lesson 10 installs reusable code with it.

The HTML **script** element loads basics.js. **defer** waits until HTML is parsed (read into elements) before running it. This output-only program does not need page elements but uses a loading habit useful in lesson 09.

## Try it
Make the final count 2 sessions and choose the Plan one more session branch. Add TypeScript as the fourth topic. Predict the six original messages plus the new topic line before running.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson08** folder, copy and paste it beside the original, then rename the copy **lesson08-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson08-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. 

<details><summary>Starter files</summary>

**File: `basics.js` (starter)**
```javascript
const learner = "Ada";
let sessions = 2;
sessions = sessions + 1;
const ready = sessions >= 3;
function greeting(name) {
  return "Hello, " + name + "!";
}
console.log(greeting(learner));
if (ready === true) {
  console.log("Ready for practice");
} else {
  console.log("Plan one more session");
}
const topics = ["HTML", "CSS", "JavaScript"];
for (const topic of topics) {
  console.log("Study: " + topic);
}
console.log("Sessions: " + sessions);
```

**File: `index.html` (starter)**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>JavaScript practice</title>
  <script src="basics.js" defer></script>
</head>
<body>
  <h1>JavaScript practice</h1>
  <p>Open the browser console to see the practice plan.</p>
</body>
</html>
```

</details>

Choose Terminal > New Terminal. Check that the prompt ends lesson08-try. Recovery commands run from any folder: Windows PowerShell uses Set-Location "$HOME\code101\lesson08-try"; macOS/Linux uses cd "$HOME/code101/lesson08-try". Linux users repeat their Node PATH export if needed. Then run (Windows npm.cmd/npx.cmd if policy requires):

**Folder: lesson08-try (all operating systems)**
```powershell
node basics.js
```

For the browser exercise, open lesson08-try/index.html in the file manager. Save and reload after edits.

<details><summary>Solution</summary>

**File: `basics.js`**
```javascript
const learner = "Ada";
let sessions = 1;
sessions = sessions + 1;
const ready = sessions >= 3;
function greeting(name) {
  return "Hello, " + name + "!";
}
console.log(greeting(learner));
if (ready === true) {
  console.log("Ready for practice");
} else {
  console.log("Plan one more session");
}
const topics = ["HTML", "CSS", "JavaScript", "TypeScript"];
for (const topic of topics) {
  console.log("Study: " + topic);
}
console.log("Sessions: " + sessions);
```

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>JavaScript practice</title>
  <script src="basics.js" defer></script>
</head>
<body>
  <h1>JavaScript practice</h1>
  <p>Open the browser console to see the practice plan.</p>
</body>
</html>
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. 

Expected Node output (captured from solution):
**Output**
```text
Hello, Ada!
Plan one more session
Study: HTML
Study: CSS
Study: JavaScript
Study: TypeScript
Sessions: 2
```

</details>

## Check yourself
1. Which declaration allows reassignment?
   <details><summary>Answer</summary>let.</details>
2. What does greeting return?
   <details><summary>Answer</summary>A string such as Hello, Ada!</details>
3. Why does Ready run?
   <details><summary>Answer</summary>sessions becomes 3, so sessions >= 3 is true.</details>
4. Does console.log write paragraphs?
   <details><summary>Answer</summary>No. It writes console messages.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Error: Cannot find module '<project>\basics.js'` | node basics.js was run from a folder without that file | Run Get-Location (macOS/Linux: pwd); return to lesson08 with the Step 3 command, then retry |
| node : The term 'node' is not recognized as the name of a cmdlet, function, script file, or operable program. | Node is not available in this terminal | Finish Step 2 and reopen VS Code; Linux archive users repeat the PATH export |
| npm.ps1 cannot be loaded because running scripts is disabled on this system. | PowerShell blocked the script launcher | Use npm.cmd / npx.cmd as shown beside the first npm command |
| `SyntaxError: Unexpected end of input` | A closing function brace was removed | Compare the greeting function and restore its closing } |
| `TypeError: Assignment to constant variable.` | sessions was changed from let to const | Use let for the reassigned sessions name |
| Old output after an edit | basics.js is unsaved | Save the tab, then rerun node basics.js; browser users reload Console |

`<project>` stands for the folder where you ran the command, not text to type. Error excerpts omit stack traces; the node-not-found row is PowerShell wording (other shells differ).

## Best practice
Use const by default and let only for values you reassign. Source: MDN: Grammar and types https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Grammar_and_types#declarations

## Next lesson
[09. The DOM and events](../phase-3-typescript-and-project/09-dom-and-events.md): A button-driven counter starting at Clicks: 0 and updating on each press.
