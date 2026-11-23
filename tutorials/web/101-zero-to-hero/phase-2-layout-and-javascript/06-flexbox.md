---
track: web
level: 101
phase: 2
phase_name: layout-and-javascript
lesson: 06
title: "Flexbox"
time: 40 min
prerequisites: [101.2.05]
versions: { browser: "current Edge/Chrome/Firefox" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-2-layout-and-javascript/06-flexbox/
assets: []
---

# 06. Flexbox

## Why it matters
Arranging people on a bench is a one-direction problem: share space and keep sensible gaps. Flexbox does that for page elements, even when the bench becomes shorter.

## What you will build
Three tool cards that share a row on a wide screen and wrap on narrow screens.

## Before you start
- Time: 40 min.
- Complete lessons 01 to 05. Keep the [Web glossary](../../GLOSSARY.md) nearby.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Use the VS Code installed in lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-2-layout-and-javascript/06-flexbox/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson06 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Make and open your own folder
Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson06**. In VS Code choose **File > Open Folder**, select code101/lesson06, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson06.

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
  <title>Flexible tools</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main>
    <h1>My learning tools</h1>
    <div class="tools">
      <article><h2>Editor</h2><p>Write the files.</p></article>
      <article><h2>Browser</h2><p>Read the page.</p></article>
      <article><h2>Notes</h2><p>Remember discoveries.</p></article>
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
.tools {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  justify-content: center;
  align-items: stretch;
  gap: 16px;
}
article { flex: 1 1 180px; padding: 16px; border: 2px solid #2563eb; }
h2 { margin-top: 0; }
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

## Run it
Save all files. In your file manager open code101/lesson06, right-click index.html > Open with > Edge, Chrome or Firefox (macOS: Open With). Double-click works if HTML is associated with a browser. VS Code's text view is not the page preview. A local address starts file:///. After every edit save, then reload **Ctrl+R** (macOS **Command+R**).

**Expected browser result:** The tab reads Flexible tools. My learning tools is above Editor, Browser and Notes. At a viewport about 1000px wide they share one blue-bordered row with 16px gaps and equal widths. At about 500px two cards share the first row and the lone third card grows to fill the second row; at about 350px each card gets a row.

First drag the window: wide gives one row; medium gives two rows with a full-width last card; narrow gives one card per row. For measured checks use lesson 05 Step 4: F12 > phone/tablet icon > Responsive, enter width 1000, then 500, then 350. Leave device mode with the same icon. These are viewport widths, not monitor widths.

## How it works
**Flexbox** arranges items along one main direction. display: flex makes .tools a **flex container**; its immediate articles become **flex items**. `<div>` is a generic group; `<article>` is a self-contained item.

flex-direction: row makes the **main axis**, the primary layout direction, horizontal in this English page. The **cross axis** is perpendicular. justify-content: center positions leftover main-axis space; align-items: stretch makes items in the same row share cross-axis height. **gap** is space between items. flex-wrap: wrap permits new rows rather than squeezing all items into one.

flex: 1 1 180px sets grow, shrink and basis. **Flex basis** is starting size along the main axis; grow 1 shares extra room and shrink 1 permits shrinking. Growing items often use all the room, leaving no space for justify-content to distribute. A grow value of 0 leaves extra space unused. A basis of auto takes its starting size from the content unless a size was set elsewhere. In a column the main direction is vertical, so basis affects height rather than width.

## Try it
Make the tools a vertical stack with 24px between cards. Each card should follow its content height, not grow to fill spare height or start at a fixed 180px. Keep the borders and text unchanged.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson06** folder, copy and paste it beside the original, then rename the copy **lesson06-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson06-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. 

<details><summary>Starter files</summary>

**File: `index.html` (starter)**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Flexible tools</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main>
    <h1>My learning tools</h1>
    <div class="tools">
      <article><h2>Editor</h2><p>Write the files.</p></article>
      <article><h2>Browser</h2><p>Read the page.</p></article>
      <article><h2>Notes</h2><p>Remember discoveries.</p></article>
    </div>
  </main>
</body>
</html>
```

**File: `style.css` (starter)**
```css
* { box-sizing: border-box; }
body { font-family: Arial, sans-serif; margin: 24px; color: #172554; }
.tools {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  justify-content: center;
  align-items: stretch;
  gap: 16px;
}
article { flex: 1 1 180px; padding: 16px; border: 2px solid #2563eb; }
h2 { margin-top: 0; }
```

</details>

For the browser exercise, open lesson06-try/index.html in the file manager. Save and reload after edits.

<details><summary>Solution</summary>

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Flexible tools</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main>
    <h1>My learning tools</h1>
    <div class="tools">
      <article><h2>Editor</h2><p>Write the files.</p></article>
      <article><h2>Browser</h2><p>Read the page.</p></article>
      <article><h2>Notes</h2><p>Remember discoveries.</p></article>
    </div>
  </main>
</body>
</html>
```

**File: `style.css`**
```css
* { box-sizing: border-box; }
body { font-family: Arial, sans-serif; margin: 24px; color: #172554; }
.tools {
  display: flex;
  flex-direction: column;
  flex-wrap: wrap;
  justify-content: center;
  align-items: stretch;
  gap: 24px;
}
article { flex: 0 1 auto; padding: 16px; border: 2px solid #2563eb; }
h2 { margin-top: 0; }
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. 

Expected browser change: The cards stack vertically with 24px gaps and content-based heights.

</details>

## Check yourself
1. Which elements become flex items?
   <details><summary>Answer</summary>Immediate children of the flex container.</details>
2. Which setting permits another row?
   <details><summary>Answer</summary>flex-wrap: wrap.</details>
3. Does gap add outer-edge spacing?
   <details><summary>Answer</summary>No. It adds space between items.</details>
4. What does column do to the main axis?
   <details><summary>Answer</summary>Makes it vertical.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Cards never wrap as the window narrows | Wrapping was removed or applied to article instead of .tools | Keep display: flex and flex-wrap: wrap on .tools |
| Spacing changes do not appear | Unsaved stylesheet or wrong lesson folder | Save style.css; open lesson06/index.html and reload |
| Cards are plain blocks with no blue borders | Stylesheet is missing | Keep style.css beside index.html and its exact link |

## Best practice
Use Flexbox for primarily one-axis layouts and gap for space between items. Source: web.dev: Flexbox https://web.dev/learn/css/flexbox

## Next lesson
[07. Grid and responsive design](../phase-2-layout-and-javascript/07-grid-and-responsive-design.md): An interests grid: one column on small screens and three equal columns on wider screens.
