---
track: web
level: 101
phase: 1
phase_name: html-and-css
lesson: 04
title: "CSS basics"
time: 40 min
prerequisites: [101.1.03]
versions: { browser: "current Edge/Chrome/Firefox" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-1-html-and-css/04-css-basics/
assets: []
---

# 04. CSS basics

## Why it matters
HTML is the furniture list; CSS is the decorating plan. You can change the paint without replacing the chairs. Separating structure and appearance makes changes easier to follow.

## What you will build
A profile with a pale background, readable font, green paragraph and blue welcome message. Competing rules reveal the cascade.

## Before you start
- Time: 40 min.
- Complete lessons 01 to 03. Keep the [Web glossary](../../GLOSSARY.md) nearby.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Use the VS Code installed in lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-1-html-and-css/04-css-basics/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson04 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Make and open your own folder
Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson04**. In VS Code choose **File > Open Folder**, select code101/lesson04, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson04.

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
  <title>Styled profile</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main>
    <h1>My profile</h1>
    <p>I enjoy learning new things.</p>
    <p class="highlight" id="welcome">Welcome to my page.</p>
  </main>
</body>
</html>
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 3. Write style.css
Create style.css beside index.html. Paste the full file and save; the HTML link points to this spelling.

**File: `style.css`**
```css
body {
  font-family: Arial, sans-serif;
  background-color: #f1f5f9;
  color: #172554;
}
p { color: #334155; }
p { color: #166534; }
.highlight { color: #9a3412; }
#welcome { color: #1d4ed8; }
h1 { font-size: 2rem; }
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

## Run it
Save all files. In your file manager open code101/lesson04, right-click index.html > Open with > Edge, Chrome or Firefox (macOS: Open With). Double-click works if HTML is associated with a browser. VS Code's text view is not the page preview. A local address starts file:///. After every edit save, then reload **Ctrl+R** (macOS **Command+R**).

**Expected browser result:** The tab reads Styled profile. The background is pale blue-gray. My profile is dark blue, about twice normal text size. I enjoy learning new things. is green; Welcome to my page. is blue, not orange.

## How it works
**CSS** (Cascading Style Sheets) describes appearance. `<link rel="stylesheet" href="style.css">` loads a **stylesheet**, a CSS file. Both files live in the same folder; changing href to css/style.css would require moving the stylesheet into a css folder.

A **selector** chooses elements: p chooses paragraphs; .highlight chooses elements with that class; #welcome chooses the element with that ID. A **class** is a reusable label; an **ID** uniquely identifies an element. A **declaration** pairs a **property**, what to change, with a **value**, the setting: color: #166534. A rule groups declarations in braces. Colons separate properties and values; semicolons separate declarations.

font-family tries Arial, then a sans-serif fallback (letters without decorative end strokes). color changes text; background-color changes background. Six digits after # describe a **hexadecimal color**, a compact red/green/blue number. The heading's font-size: 2rem means twice the root font size and normally matches its browser default, so this line alone may not look different; the exercise makes it larger. The two p colors intentionally compete so you can see which wins. Here **rem** is a unit relative to the root element's font size.

The **cascade** chooses a winning declaration when rules compete. For the two p rules here, the two p rules have equal **specificity**, selector weight, so the later green rule wins. The class beats the p selector; the ID beats the class, so the welcome text is blue. **Inheritance** passes a parent's text settings to children with no setting of their own. A directly selected paragraph color wins over inherited body color. Last rule wins is not universal: compare the selector weights first, as the blue welcome paragraph demonstrates.

## Try it
Make the background white and the main heading 2.5 times the root text size. Keep the welcome message blue.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson04** folder, copy and paste it beside the original, then rename the copy **lesson04-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson04-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. 

<details><summary>Starter files</summary>

**File: `index.html` (starter)**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Styled profile</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main>
    <h1>My profile</h1>
    <p>I enjoy learning new things.</p>
    <p class="highlight" id="welcome">Welcome to my page.</p>
  </main>
</body>
</html>
```

**File: `style.css` (starter)**
```css
body {
  font-family: Arial, sans-serif;
  background-color: #f1f5f9;
  color: #172554;
}
p { color: #334155; }
p { color: #166534; }
.highlight { color: #9a3412; }
#welcome { color: #1d4ed8; }
h1 { font-size: 2rem; }
```

</details>

For the browser exercise, open lesson04-try/index.html in the file manager. Save and reload after edits.

<details><summary>Solution</summary>

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Styled profile</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main>
    <h1>My profile</h1>
    <p>I enjoy learning new things.</p>
    <p class="highlight" id="welcome">Welcome to my page.</p>
  </main>
</body>
</html>
```

**File: `style.css`**
```css
body {
  font-family: Arial, sans-serif;
  background-color: #ffffff;
  color: #172554;
}
p { color: #334155; }
p { color: #166534; }
.highlight { color: #9a3412; }
#welcome { color: #1d4ed8; }
h1 { font-size: 2.5rem; }
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. 

Expected browser change: The background is white; the heading is 2.5 times the root font size. Welcome text stays blue.

</details>

## Check yourself
1. Where does href style.css look?
   <details><summary>Answer</summary>In the index.html folder.</details>
2. Why is the ordinary paragraph green?
   <details><summary>Answer</summary>The equal-specificity p rule appearing later wins.</details>
3. Why is the welcome paragraph blue?
   <details><summary>Answer</summary>The ID selector outweighs class and element selectors here.</details>
4. What does 2rem mean?
   <details><summary>Answer</summary>Twice the root font size.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Colors stay unchanged after an edit | style.css was not saved or the wrong page is open | Save style.css; confirm lesson04 in the browser address and reload |
| Intended styling is missing | The HTML requests a different file name | Keep href="style.css" and style.css beside index.html; the file name is singular |

## Best practice
Keep CSS in a linked stylesheet and understand the cascade before using !important overrides. Source: MDN: Cascade https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_cascade/Cascade

## Next lesson
[05. Box model and spacing](../phase-2-layout-and-javascript/05-box-model-and-spacing.md): One centered, blue-bordered card with predictable outer width and comfortable spacing.
