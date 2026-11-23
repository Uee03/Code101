---
track: web
level: 101
phase: 3
phase_name: typescript-and-project
lesson: 09
title: "The DOM and events"
time: 90 min
prerequisites: [101.2.08]
versions: { browser: "current Edge/Chrome/Firefox", node: "26.13.1", npm: "11.20.0" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-3-typescript-and-project/09-dom-and-events/
assets: []
---

# 09. The DOM and events

## Why it matters
A doorbell waits for a press, then responds. An interactive page works the same way: listen for an event, then change the relevant page text.

## What you will build
A button-driven counter starting at Clicks: 0 and updating on each press.

## Before you start
- Time: 90 min. Two sittings; use the marked break in Steps.
- Complete lessons 01 to 08. Keep the [Web glossary](../../GLOSSARY.md) nearby.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Use the VS Code installed in lesson 01.
- Node 26.13.1 and npm 11.20.0 from lesson 08. 
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-3-typescript-and-project/09-dom-and-events/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson09 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Make and open your own folder
Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson09**. In VS Code choose **File > Open Folder**, select code101/lesson09, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson09.

Windows: enable **View > Show > File name extensions** (Windows 10: View > File name extensions). This prevents index.html.txt. In VS Code the **Explorer** is the left file panel. Hover beside its top folder name and click **New File** (the small page icon with a plus). Use the exact file name shown. First copy the complete listing from this lesson (not the surrounding backticks), click inside the new file and paste it, press **Ctrl+S** (macOS **Command+S**). A dot on an editor tab means unsaved; save until it disappears. A **folder** groups files; a **file** stores saved text.

### Step 2. Write index.html
Create index.html directly in the lesson folder. Paste the full file and save. title names the tab; body supplies the page content.

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>DOM events</title>
  <script src="app.js" defer></script>
</head>
<body>
  <main>
    <h1>A page that listens</h1>
    <button id="greet" type="button">Count a click</button>
    <p id="status" aria-live="polite">Clicks: 0</p>
  </main>
</body>
</html>
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

**Break - end of sitting 1.** The HTML button and starting text are saved. In sitting 2, add the listener and check mouse and keyboard use.

### Step 3. Write app.js
Create app.js beside index.html. Paste and save; keep the element IDs equal to the HTML IDs.

**File: `app.js`**
```javascript
function message(count) {
  return "Clicks: " + count;
}
console.log(message(0));
if (typeof document !== "undefined") {
  const button = document.querySelector("#greet");
  const status = document.querySelector("#status");
  let clicks = 0;
  button.addEventListener("click", function () {
    clicks = clicks + 1;
    status.textContent = message(clicks);
  });
}
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

## Run it
Save all files. In your file manager open code101/lesson09, right-click index.html > Open with > Edge, Chrome or Firefox (macOS: Open With). Double-click works if HTML is associated with a browser. VS Code's text view is not the page preview. A local address starts file:///. After every edit save, then reload **Ctrl+R** (macOS **Command+R**).

Click Count a click twice; Tab to it and Enter or Space activates it without a mouse. Reload resets the count. Open DevTools with F12 (macOS Command+Option+I), select **Console**, then reload. The initial message is:
```text
Clicks: 0
```
This is only the starting message; watch the page text for the click updates. You do not need a terminal run for this lesson.

**Expected browser result:** The tab reads DOM events. A page that listens is above Count a click and Clicks: 0. One click gives Clicks: 1; a second gives Clicks: 2. Reload resets to Clicks: 0.

## How it works
The **DOM** (Document Object Model) is the browser's in-memory HTML representation. document provides access. **querySelector** finds the first element matching a CSS selector; #greet and #status use the HTML IDs. It returns **null**, a value meaning no element found, on a miss. Exact HTML and defer loading ensure our elements exist.

An **event** notifies that something happened, such as a click. addEventListener registers an **event handler**, a function to run on that event. The unnamed function () is a **callback**, a function passed for later use. It is not called during registration. It can access clicks in its surrounding **scope**, the region where a name is available. A press increments clicks, calls message, then assigns status.textContent.

**textContent** replaces text without interpreting it as HTML. **ARIA** (Accessible Rich Internet Applications) attributes add extra information for screen readers. aria-live="polite" asks assistive tools to announce updates at a suitable pause. Native buttons support keyboard activation; type button prevents accidental form submission if moved into a form.

**typeof** tells us the kind of a value. typeof document !== "undefined" checks whether document exists; **undefined** means absent/not supplied here, and !== means not equal without type conversion. Node has no document, so this outer check skips page-specific work there. Keep this compatibility wrapper unchanged; this lesson's task is to listen for a click in the browser.

## Try it
Make one press count as two clicks, with the button labelled Count two clicks. The page starts at Clicks: 0 and shows Clicks: 2 after one press.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson09** folder, copy and paste it beside the original, then rename the copy **lesson09-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson09-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. 

<details><summary>Starter files</summary>

**File: `app.js` (starter)**
```javascript
function message(count) {
  return "Clicks: " + count;
}
console.log(message(0));
if (typeof document !== "undefined") {
  const button = document.querySelector("#greet");
  const status = document.querySelector("#status");
  let clicks = 0;
  button.addEventListener("click", function () {
    clicks = clicks + 1;
    status.textContent = message(clicks);
  });
}
```

**File: `index.html` (starter)**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>DOM events</title>
  <script src="app.js" defer></script>
</head>
<body>
  <main>
    <h1>A page that listens</h1>
    <button id="greet" type="button">Count a click</button>
    <p id="status" aria-live="polite">Clicks: 0</p>
  </main>
</body>
</html>
```

</details>

For the browser exercise, open lesson09-try/index.html in the file manager. Save and reload after edits.

<details><summary>Solution</summary>

**File: `app.js`**
```javascript
function message(count) {
  return "Clicks: " + count;
}
console.log(message(0));
if (typeof document !== "undefined") {
  const button = document.querySelector("#greet");
  const status = document.querySelector("#status");
  let clicks = 0;
  button.addEventListener("click", function () {
    clicks = clicks + 2;
    status.textContent = message(clicks);
  });
}
```

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>DOM events</title>
  <script src="app.js" defer></script>
</head>
<body>
  <main>
    <h1>A page that listens</h1>
    <button id="greet" type="button">Count two clicks</button>
    <p id="status" aria-live="polite">Clicks: 0</p>
  </main>
</body>
</html>
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. 

Expected starting Console message (unchanged):
**Output**
```text
Clicks: 0
```

Expected browser change: One click gives Clicks: 2, two give Clicks: 4; reload resets to Clicks: 0.

</details>

## Check yourself
1. What does querySelector return on a miss?
   <details><summary>Answer</summary>null.</details>
2. When does the registered function run?
   <details><summary>Answer</summary>On a click event.</details>
3. What does textContent change?
   <details><summary>Answer</summary>Plain element text.</details>
4. Can Node verify button clicks here?
   <details><summary>Answer</summary>No. It runs only the helper.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `TypeError: Cannot read properties of null (reading 'addEventListener')` | querySelector did not find #greet, often a mistyped ID | Open Console with F12; match greet in HTML and JavaScript and keep defer |
| Old click behavior after editing | app.js was not saved | Save app.js; reload lesson09/index.html and try again |
| No starting Console message | The script file/path differs | Keep app.js beside index.html and src="app.js"; reload with Console open |

The null-error text above was captured with a missing-element result in Node; browsers may prefix it with Uncaught or format source locations differently. Use F12 > Console to find the corresponding error, not the terminal.

## Best practice
Use native buttons and textContent for plain-text updates instead of constructing HTML strings. Source: MDN: Node textContent https://developer.mozilla.org/en-US/docs/Web/API/Node/textContent

## Next lesson
[10. TypeScript first steps](../phase-3-typescript-and-project/10-typescript-first-steps.md): A profile with string, number and boolean fields, compiled to JavaScript and run in Node. Deliberately trigger and repair a real type error.
