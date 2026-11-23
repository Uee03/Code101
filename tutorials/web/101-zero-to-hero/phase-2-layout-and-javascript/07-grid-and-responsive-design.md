---
track: web
level: 101
phase: 2
phase_name: layout-and-javascript
lesson: 07
title: "Grid and responsive design"
time: 40 min
prerequisites: [101.2.06]
versions: { browser: "current Edge/Chrome/Firefox" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-2-layout-and-javascript/07-grid-and-responsive-design/
assets: []
---

# 07. Grid and responsive design

## Why it matters
A notebook table organizes both rows and columns. Grid is the page-layout equivalent; a media query switches the table shape when the available space changes.

## What you will build
An interests grid: one column on small screens and three equal columns on wider screens.

## Before you start
- Time: 40 min.
- Complete lessons 01 to 06. Keep the [Web glossary](../../GLOSSARY.md) nearby.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Use the VS Code installed in lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-2-layout-and-javascript/07-grid-and-responsive-design/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson07 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Make and open your own folder
Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson07**. In VS Code choose **File > Open Folder**, select code101/lesson07, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson07.

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
  <title>Responsive interests</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main>
    <h1>My interests</h1>
    <div class="grid">
      <article><h2>Cooking</h2><p>Try a new recipe.</p></article>
      <article><h2>Music</h2><p>Learn a new song.</p></article>
      <article><h2>Walking</h2><p>Explore a new path.</p></article>
    </div>
  </main>
</body>
</html>
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 3. Write style.css
Create style.css beside index.html. Paste the full file and save; the HTML link points to this spelling.

**File: `style.css`**
```css
* { box-sizing: border-box; }
body { font-family: Arial, sans-serif; margin: 24px; color: #172554; }
.grid { display: grid; grid-template-columns: 1fr; gap: 16px; }
article { padding: 16px; background: #eff6ff; border: 2px solid #2563eb; }
@media (min-width: 700px) {
  .grid { grid-template-columns: repeat(3, 1fr); }
}
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

## Run it
Save all files. In your file manager open code101/lesson07, right-click index.html > Open with > Edge, Chrome or Firefox (macOS: Open With). Double-click works if HTML is associated with a browser. VS Code's text view is not the page preview. A local address starts file:///. After every edit save, then reload **Ctrl+R** (macOS **Command+R**).

**Expected browser result:** The tab reads Responsive interests. Below My interests, Cooking, Music and Walking stack below 700px. At 700px and above they form one row of three equal-width pale-blue cards with 16px gaps.

Drag the window: narrow means stacked cards; wide means three across. To check the exact boundary, repeat lesson 05 Step 4: F12 > phone/tablet icon > Responsive; type 699 in the width box (one column), then 700 and 1000 (three columns). min-width includes 700 itself. Leave device mode with the same icon; monitor width is not viewport width.

## How it works
**Grid** organizes items in rows and columns. display: grid makes a **grid container**. grid-template-columns defines columns; **fr**, a fraction unit, is a share of available space after fixed sizes and gaps. repeat(3, 1fr) creates three equal shares.

A **viewport** is the browser's page-display area. A **media query** applies CSS conditionally depending on the viewing environment. @media (min-width: 700px) applies its rule at widths of at least 700 CSS pixels. 700px is this page's **breakpoint**, where layout changes. The default is one column. The later media-query rule has equal selector specificity, so it wins when eligible.

**Responsive design** adapts layout to available space. **Mobile-first** CSS starts small and adds wider-screen changes. The viewport meta line makes mobile browsers use device width rather than a pretend desktop canvas. Grid deals with two axes; Flexbox emphasizes one. A site can use both.

## Try it
Use two columns at viewport widths of 700px or greater. The third card must start a new row. Keep one column below 700px.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson07** folder, copy and paste it beside the original, then rename the copy **lesson07-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson07-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. 

<details><summary>Starter files</summary>

**File: `index.html` (starter)**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Responsive interests</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main>
    <h1>My interests</h1>
    <div class="grid">
      <article><h2>Cooking</h2><p>Try a new recipe.</p></article>
      <article><h2>Music</h2><p>Learn a new song.</p></article>
      <article><h2>Walking</h2><p>Explore a new path.</p></article>
    </div>
  </main>
</body>
</html>
```

**File: `style.css` (starter)**
```css
* { box-sizing: border-box; }
body { font-family: Arial, sans-serif; margin: 24px; color: #172554; }
.grid { display: grid; grid-template-columns: 1fr; gap: 16px; }
article { padding: 16px; background: #eff6ff; border: 2px solid #2563eb; }
@media (min-width: 700px) {
  .grid { grid-template-columns: repeat(3, 1fr); }
}
```

</details>

For the browser exercise, open lesson07-try/index.html in the file manager. Save and reload after edits.

<details><summary>Solution</summary>

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Responsive interests</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main>
    <h1>My interests</h1>
    <div class="grid">
      <article><h2>Cooking</h2><p>Try a new recipe.</p></article>
      <article><h2>Music</h2><p>Learn a new song.</p></article>
      <article><h2>Walking</h2><p>Explore a new path.</p></article>
    </div>
  </main>
</body>
</html>
```

**File: `style.css`**
```css
* { box-sizing: border-box; }
body { font-family: Arial, sans-serif; margin: 24px; color: #172554; }
.grid { display: grid; grid-template-columns: 1fr; gap: 16px; }
article { padding: 16px; background: #eff6ff; border: 2px solid #2563eb; }
@media (min-width: 700px) {
  .grid { grid-template-columns: repeat(2, 1fr); }
}
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. 

Expected browser change: At 700px and above Cooking and Music share row one, Walking begins row two; below 700px they stack.

</details>

## Check yourself
1. What is fr?
   <details><summary>Answer</summary>A share of available grid space.</details>
2. Does min-width: 700px include 700px?
   <details><summary>Answer</summary>Yes.</details>
3. What layout appears below the breakpoint?
   <details><summary>Answer</summary>One column.</details>
4. Why keep the viewport meta line?
   <details><summary>Answer</summary>It makes mobile layout use device width.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Cards stay in one column on a wide window | The media-query column rule was deleted or the breakpoint was changed | Compare the complete @media block including its closing brace |
| Layout changes do not appear | Unsaved style.css or wrong page | Save and reload lesson07/index.html |
| Mobile page remains desktop-wide | The viewport meta line was removed | Restore the complete viewport line in head |

## Best practice
Choose breakpoints when content needs another layout, not by a particular phone model. Source: web.dev: Media queries https://web.dev/learn/design/media-queries

## Next lesson
[08. JavaScript basics](../phase-2-layout-and-javascript/08-javascript-basics.md): A study plan running in browser Console and Node: a greeting, a decision, three topics and a session count.
