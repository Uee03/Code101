---
track: web
level: 101
phase: 2
phase_name: layout-and-javascript
lesson: 05
title: "Box model and spacing"
time: 45 min
prerequisites: [101.1.04]
versions: { browser: "current Edge/Chrome/Firefox" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-2-layout-and-javascript/05-box-model-and-spacing/
assets: []
---

# 05. Box model and spacing

## Why it matters
A framed photograph has the picture, a mat, a frame, and space before the next picture. A page element has the same layers. Knowing which layer you change prevents mysterious sizes.

## What you will build
One centered, blue-bordered card with predictable outer width and comfortable spacing.

## Before you start
- Time: 45 min.
- Complete lessons 01 to 04. Keep the [Web glossary](../../GLOSSARY.md) nearby.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Use the VS Code installed in lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-2-layout-and-javascript/05-box-model-and-spacing/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson05 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Make and open your own folder
Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson05**. In VS Code choose **File > Open Folder**, select code101/lesson05, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson05.

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
  <title>Box model</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main class="card">
    <h1>A comfortable card</h1>
    <p>Space helps readers focus.</p>
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
body { font-family: Arial, sans-serif; margin: 0; color: #172554; }
.card {
  width: 320px;
  max-width: 100%;
  padding: 24px;
  border: 4px solid #2563eb;
  margin: 24px auto;
  background: #eff6ff;
}
h1 { margin-top: 0; font-size: 1.5rem; }
p { margin-bottom: 0; }
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 4. See the page's measuring tools
The **viewport** is the browser area showing the page, excluding its toolbars. **Developer tools** (**DevTools**) are built-in browser panels for inspecting a page. Open index.html in your browser, then right-click inside the card > **Inspect**. The selected HTML element and its styles appear. The **box model** describes its content area, inside space (padding), edge (border) and outside space (margin). In Edge/Chrome select **Computed** in the styles area and scroll to the colored **box model** diagram; in Firefox select **Layout** and its **Box Model** section. Click the `<main class="card">` element if a heading was selected instead. Its content should measure **264px** wide, surrounded by 24px padding and a 4px border on each side: **320px** total. These numbers assume a window wider than the card. **Content** is the text area, **padding** is space inside the edge, and the **border** is that edge. **px** means CSS pixels, layout units rather than necessarily physical screen dots.

You can also open DevTools with **F12** (some laptops: **Fn+F12**; macOS: **Command+Option+I**). For exact viewport widths in Edge/Chrome, click **Toggle device toolbar** (the phone/tablet icon near the top-left of DevTools), select **Responsive** in the device dropdown, then type a width in the **width** box, such as **1000**. In Firefox click **Responsive Design Mode** (phone/tablet icon at the top-right of DevTools); choose **Responsive** and enter the width. Press Enter. This changes the page's available CSS-pixel width, not your monitor size. Click the same icon to leave device mode, then close DevTools with its X.

## Run it
Save all files. In your file manager open code101/lesson05, right-click index.html > Open with > Edge, Chrome or Firefox (macOS: Open With). Double-click works if HTML is associated with a browser. VS Code's text view is not the page preview. A local address starts file:///. After every edit save, then reload **Ctrl+R** (macOS **Command+R**).

**Expected browser result:** The tab reads Box model. On a wide viewport the card is 320 CSS pixels wide including its blue border, centered horizontally, 24px below the top. Its pale-blue interior contains A comfortable card and Space helps readers focus.

## How it works
The **box model** has four layers: **content** is the text area; **padding** is space between content and border; **border** is the edge; **margin** is space outside that edge. Background paint covers content and padding, not margin.

`*` is the **universal selector**, selecting every element. box-sizing: border-box includes padding and border in the width. Here 320px - 2 x 24px padding - 2 x 4px border = 264px content. **content-box** is the default sizing rule: width counts only content, then padding and border are added outside it. With that rule the same width makes the outer card 376px wide. **px** means CSS pixels, a layout unit not necessarily equal to a physical screen pixel.

The **parent** is the enclosing element, here body. max-width: 100% keeps the card inside that parent's available width. margin: 24px auto is a **shorthand**, one declaration for several sides: 24px above/below, automatic equal left/right margins to center it when room exists. padding: 24px sets all sides. border: 4px solid #2563eb sets thickness, style and color. Body margin 0 removes its default gap. Removing the heading's top margin and paragraph's bottom margin simplifies the interior spacing.

## Try it
Give the card 32px of inner space on every side and a thinner 2px border. Preserve its 320px outer width. Predict the remaining text width (252px), then inspect the box diagram.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson05** folder, copy and paste it beside the original, then rename the copy **lesson05-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson05-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. 

<details><summary>Starter files</summary>

**File: `index.html` (starter)**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Box model</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main class="card">
    <h1>A comfortable card</h1>
    <p>Space helps readers focus.</p>
  </main>
</body>
</html>
```

**File: `style.css` (starter)**
```css
* { box-sizing: border-box; }
body { font-family: Arial, sans-serif; margin: 0; color: #172554; }
.card {
  width: 320px;
  max-width: 100%;
  padding: 24px;
  border: 4px solid #2563eb;
  margin: 24px auto;
  background: #eff6ff;
}
h1 { margin-top: 0; font-size: 1.5rem; }
p { margin-bottom: 0; }
```

</details>

For the browser exercise, open lesson05-try/index.html in the file manager. Save and reload after edits.

<details><summary>Solution</summary>

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Box model</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <main class="card">
    <h1>A comfortable card</h1>
    <p>Space helps readers focus.</p>
  </main>
</body>
</html>
```

**File: `style.css`**
```css
* { box-sizing: border-box; }
body { font-family: Arial, sans-serif; margin: 0; color: #172554; }
.card {
  width: 320px;
  max-width: 100%;
  padding: 32px;
  border: 2px solid #2563eb;
  margin: 24px auto;
  background: #eff6ff;
}
h1 { margin-top: 0; font-size: 1.5rem; }
p { margin-bottom: 0; }
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. 

Expected browser change: The outside width stays 320px; the content is 252px wide, with 32px padding and a 2px border on each side.

</details>

## Check yourself
1. Is padding inside or outside the border?
   <details><summary>Answer</summary>Inside.</details>
2. What keeps outer width at 320px?
   <details><summary>Answer</summary>border-box sizing.</details>
3. What is the original content width?
   <details><summary>Answer</summary>264px.</details>
4. What do the auto margins do?
   <details><summary>Answer</summary>Center the card by sharing free space equally.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Card is 376px rather than 320px in the box diagram | The border-box rule was removed | Restore * { box-sizing: border-box; } |
| Your new spacing does not appear | style.css is unsaved or a different lesson is open | Save; check lesson05 in the address, then reload |
| No card border or background | The stylesheet file/path differs | Keep style.css beside index.html with the exact href spelling |

## Best practice
Use border-box when you want widths to include padding and borders. Source: web.dev: Box model https://web.dev/learn/css/box-model

## Next lesson
[06. Flexbox](../phase-2-layout-and-javascript/06-flexbox.md): Three tool cards that share a row on a wide screen and wrap on narrow screens.
