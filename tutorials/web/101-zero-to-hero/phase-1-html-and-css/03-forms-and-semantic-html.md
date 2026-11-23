---
track: web
level: 101
phase: 1
phase_name: html-and-css
lesson: 03
title: "Forms and semantic HTML"
time: 40 min
prerequisites: [101.1.02]
versions: { browser: "current Edge/Chrome/Firefox" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-1-html-and-css/03-forms-and-semantic-html/
assets: []
---

# 03. Forms and semantic HTML

## Why it matters
A paper form becomes easier when every blank has a label. Rooms become easier to navigate when doors say reception, work area and exit. Semantic HTML brings both ideas to a page.

## What you will build
A study-club form with labelled name, email and number fields between a header, main area and footer. This is a local demo, not a registration service.

## Before you start
- Time: 40 min.
- Complete lessons 01 to 02. Keep the [Web glossary](../../GLOSSARY.md) nearby.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Use the VS Code installed in lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-1-html-and-css/03-forms-and-semantic-html/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson03 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Make and open your own folder
Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson03**. In VS Code choose **File > Open Folder**, select code101/lesson03, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson03.

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
  <title>Study club</title>
</head>
<body>
  <header><h1>Join my study club</h1></header>
  <main>
    <h2>Contact details</h2>
    <form action="index.html" method="get">
      <p><label for="name">Name</label>
        <input id="name" name="name" type="text" required></p>
      <p><label for="email">Email</label>
        <input id="email" name="email" type="email" required></p>
      <p><label for="sessions">Sessions per week</label>
        <input id="sessions" name="sessions" type="number" min="1" max="7" value="1"></p>
      <button type="submit">Preview details</button>
    </form>
    <p>This demo reloads this page. It does not send email or join a real club.</p>
  </main>
  <footer><p>A beginner-friendly club.</p></footer>
</body>
</html>
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

## Run it
Save all files. In your file manager open code101/lesson03, right-click index.html > Open with > Edge, Chrome or Firefox (macOS: Open With). Double-click works if HTML is associated with a browser. VS Code's text view is not the page preview. A local address starts file:///. After every edit save, then reload **Ctrl+R** (macOS **Command+R**).

**Expected browser result:** The tab reads Study club. Join my study club is above Contact details and Name, Email, Sessions per week fields. Sessions starts at 1. Preview details is followed by the demo notice and A beginner-friendly club. at the bottom.

1. Press Tab to visit Name, Email, Sessions and Preview details in order.
2. Click the Name label: the cursor appears in its input.
3. Choose Preview details with empty required fields. The browser blocks navigation and asks you to fill them (wording varies).
4. Use only demo data: **Ada**, **ada@example.com**, **2**; choose Preview details. The address should end `index.html?name=Ada&email=ada%40example.com&sessions=2`. The part after **?** is the **query string**, named values sent with the address. **%40** is the URL-safe spelling of **@** (encoding replaces some characters so they fit in an address). The same blank form returns; nothing is stored and no email is sent.

If submission from file:/// is refused, serve this folder instead:
1. In VS Code click **Extensions** (four squares in the far-left strip), search **Live Server**, choose **Ritwick Dey** (ritwickdey.LiveServer), then **Install**. No sign-in is needed; close any unrelated sign-in prompt.
2. In Explorer right-click index.html > **Open with Live Server**. Use the browser address it opens, usually `http://127.0.0.1:5500/index.html`. HTTP is the request/response system from lesson 01. Here 5500 is the **port**, the numbered doorway for this local server. Retry checks 1-4 there.
3. In VS Code's **status bar** (the strip along the bottom), click **Port: 5500** (or its actual number) to stop. Lesson 11 explains the server in more detail.

## How it works
**Semantic HTML** means choosing elements for meaning, not just appearance. `<header>` is introductory content, `<main>` is primary content (use one visible main), and `<footer>` is closing information. These form **landmarks**, recognizable regions assistive tools can navigate.

A **form** groups controls and submits their values. action="index.html" names the destination; method="get" places named values in the URL's **query string**, the part after ?. This exercise reloads its own page. Never enter private information: a query string is visible and this example has no **backend**, server-side code to process submissions.

A **label** gives a control a visible name. Its for must exactly match the input's unique id. The input's name is the key used during submission. type="text" accepts text; email checks email-shaped input; number accepts numbers, and min/max bound the range. value="1" supplies the initial number. required prevents an empty submission. These browser checks are **validation**, checking that input meets rules; they are not security guarantees.

`<button type="submit">` submits. A date input (in the exercise) chooses a calendar date; its appearance differs between browsers. **Accessibility** means making content usable by people with different abilities, including keyboard-only users and people using a **screen reader**, software that speaks page content or presents it as braille. Labels and meaningful headings help those users.

## Try it
Let a visitor optionally choose a start date before submitting. Its visible label should be Start date. Use start as the control identifier and submitted field name; keep the other fields unchanged.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson03** folder, copy and paste it beside the original, then rename the copy **lesson03-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson03-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. 

<details><summary>Starter files</summary>

**File: `index.html` (starter)**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Study club</title>
</head>
<body>
  <header><h1>Join my study club</h1></header>
  <main>
    <h2>Contact details</h2>
    <form action="index.html" method="get">
      <p><label for="name">Name</label>
        <input id="name" name="name" type="text" required></p>
      <p><label for="email">Email</label>
        <input id="email" name="email" type="email" required></p>
      <p><label for="sessions">Sessions per week</label>
        <input id="sessions" name="sessions" type="number" min="1" max="7" value="1"></p>
      <button type="submit">Preview details</button>
    </form>
    <p>This demo reloads this page. It does not send email or join a real club.</p>
  </main>
  <footer><p>A beginner-friendly club.</p></footer>
</body>
</html>
```

</details>

For the browser exercise, open lesson03-try/index.html in the file manager. Save and reload after edits.

<details><summary>Solution</summary>

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Study club</title>
</head>
<body>
  <header><h1>Join my study club</h1></header>
  <main>
    <h2>Contact details</h2>
    <form action="index.html" method="get">
      <p><label for="name">Name</label>
        <input id="name" name="name" type="text" required></p>
      <p><label for="email">Email</label>
        <input id="email" name="email" type="email" required></p>
      <p><label for="sessions">Sessions per week</label>
        <input id="sessions" name="sessions" type="number" min="1" max="7" value="1"></p>
      <p><label for="start">Start date</label>
        <input id="start" name="start" type="date"></p>
      <button type="submit">Preview details</button>
    </form>
    <p>This demo reloads this page. It does not send email or join a real club.</p>
  </main>
  <footer><p>A beginner-friendly club.</p></footer>
</body>
</html>
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. 

Expected browser change: Start date is an optional date/calendar control above the button.

</details>

## Check yourself
1. How do label and input connect?
   <details><summary>Answer</summary>label for must match input id.</details>
2. What does name do?
   <details><summary>Answer</summary>It supplies the field key for submission.</details>
3. Does this form actually register you?
   <details><summary>Answer</summary>No. It reloads its own page.</details>
4. Does type email prove the address exists?
   <details><summary>Answer</summary>No. It checks the shape only.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Source text appears or file ends .html.txt | Windows extensions are hidden, or wrong app opened it | Enable file extensions, rename to index.html and Open with a browser |
| Changes do not appear | Unsaved editor tab, or reloading another folder | Save every changed file; confirm the address; reload |
| Content looks unexpectedly nested | A closing tag is missing or nesting crossed | Match tags inside-out against the full HTML; input is void |
| Clicking a label does not select its input | for and id differ | Match those identifiers exactly |
| The form reloads but no club membership appears | HTML-only GET demo | Read the demo notice; there is no backend |

## Best practice
Use explicit labels rather than placeholders as the only names for form controls. Source: MDN: Your first form https://developer.mozilla.org/en-US/docs/Learn_web_development/Extensions/Forms/Your_first_form

## Next lesson
[04. CSS basics](../phase-1-html-and-css/04-css-basics.md): A profile with a pale background, readable font, green paragraph and blue welcome message. Competing rules reveal the cascade.
