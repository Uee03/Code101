---
track: web
level: 101
phase: 1
phase_name: html-and-css
lesson: 02
title: "Text, links, images, lists"
time: 40 min
prerequisites: [101.1.01]
versions: { browser: "current Edge/Chrome/Firefox" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-1-html-and-css/02-text-links-images-lists/
assets: [ui/search]
---

# 02. Text, links, images, lists

## Why it matters
A well-organized shelf has labels, directions and pictures. A page needs the same signposts so people can scan it without reading every word. HTML has separate elements for each job.

## What you will build
A learning shelf with a heading hierarchy, an MDN link, a search icon, a bullet list and a numbered routine.

## Before you start
- Time: 40 min.
- Complete lesson 01. Keep the [Web glossary](../../GLOSSARY.md) nearby.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Use the VS Code installed in lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-1-html-and-css/02-text-links-images-lists/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson02 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Make and open your own folder
Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson02**. In VS Code choose **File > Open Folder**, select code101/lesson02, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson02.

Windows: enable **View > Show > File name extensions** (Windows 10: View > File name extensions). This prevents index.html.txt. In VS Code the **Explorer** is the left file panel. Hover beside its top folder name and click **New File** (the small page icon with a plus). Use the exact file name shown. First copy the complete listing from this lesson (not the surrounding backticks), click inside the new file and paste it, press **Ctrl+S** (macOS **Command+S**). A dot on an editor tab means unsaved; save until it disappears. A **folder** groups files; a **file** stores saved text.

### Step 2. Save the supplied icon
In the file manager, inside lesson02 create **assets**, open it and create **icons**, then open icons and create **ui**. Use right-click > New > Folder on Windows, File > New Folder on macOS, or New Folder on Linux for each folder.

In VS Code expand those folders in Explorer. Select **ui**, click New File, name it **search.svg**, paste the complete SVG below and save. This is the course's **SVG** (Scalable Vector Graphics) icon, a picture described with shapes. Its **CC0** public-domain dedication permits reuse. It comes from `assets/art/icons/ui/search.svg`. No download is required. If using the optional source pack, the identical file is also at `02-text-links-images-lists/assets/icons/ui/search.svg` in the phase archive (and inside code/assets/icons/ui in the repository).

**File: `assets/icons/ui/search.svg`**
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Search">
  <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
</svg>
```

Expected result: search.svg sits in **lesson02/assets/icons/ui**; index.html will sit directly in **lesson02**. This is decoration, not a search control. The HTML uses `alt=""` so screen readers skip it; there is no search box to operate. A **screen reader** is software that speaks page content or presents braille. Keep that empty attribute even though the reusable SVG itself has a label.

### Step 3. Write index.html
Create index.html directly in the lesson folder. Paste the full file and save. title names the tab; body supplies the page content.

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Learning shelf</title>
</head>
<body>
  <h1>My learning shelf</h1>
  <h2>Useful places</h2>
  <p>I practise <strong>a little every day</strong>.</p>
  <p><a href="https://developer.mozilla.org/">Visit MDN</a></p>
  <img src="assets/icons/ui/search.svg" width="24" height="24" alt="">
  <h2>Topics</h2>
  <ul>
    <li>HTML</li>
    <li>CSS</li>
  </ul>
  <h2>My routine</h2>
  <ol>
    <li>Read one lesson</li>
    <li>Try the example</li>
  </ol>
</body>
</html>
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

## Run it
Save all files. In your file manager open code101/lesson02, right-click index.html > Open with > Edge, Chrome or Firefox (macOS: Open With). Double-click works if HTML is associated with a browser. VS Code's text view is not the page preview. A local address starts file:///. After every edit save, then reload **Ctrl+R** (macOS **Command+R**).

**Expected browser result:** The tab reads Learning shelf. My learning shelf appears above Useful places, a sentence with a little every day in bold, and the Visit MDN link. A small black magnifying-glass icon, about the size of a letter (24 by 24 pixels), appears below it. Topics has HTML and CSS bullets; My routine has 1. Read one lesson and 2. Try the example.

## How it works
`<h1>` names the whole page; `<h2>` names a section. `<strong>` gives text importance, normally shown bold. An **anchor** (`<a>`) makes a link; href is its destination. The full https:// MDN address is an **absolute URL**, an address with its protocol and host.

`<img>` is a **void element**: it has no contents or closing tag. src tells the browser where the image file is; width and height reserve 24 by 24 **pixels**, small units of screen layout. alt supplies a **text alternative**, words used when a meaningful picture cannot be seen. Our icon is only decoration, so `alt=""` deliberately supplies no spoken text. The icon is an **SVG** (Scalable Vector Graphics) file, a picture described with shapes rather than a fixed pixel grid. Its **CC0** public-domain dedication permits reuse; the pack includes the license.

`assets/icons/ui/search.svg` is a **relative path**, an address measured from the folder containing index.html. Each slash enters a folder. A **file extension** is the ending such as .html or .svg, which helps programs recognize the kind of file. `<ul>` is an unordered (bullet) list; `<ol>` is an ordered (numbered) list. Every `<li>` is one list item. The browser supplies the numbers, so do not type 1. and 2. into the items.

## Try it
Extend Topics to include JavaScript as its third item. Make the existing MDN link read Read the MDN guides without changing where it goes.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson02** folder, copy and paste it beside the original, then rename the copy **lesson02-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson02-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. The copied assets/icons/ui/search.svg is the same supplied icon; keep its path. 

<details><summary>Starter files</summary>

**File: `index.html` (starter)**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Learning shelf</title>
</head>
<body>
  <h1>My learning shelf</h1>
  <h2>Useful places</h2>
  <p>I practise <strong>a little every day</strong>.</p>
  <p><a href="https://developer.mozilla.org/">Visit MDN</a></p>
  <img src="assets/icons/ui/search.svg" width="24" height="24" alt="">
  <h2>Topics</h2>
  <ul>
    <li>HTML</li>
    <li>CSS</li>
  </ul>
  <h2>My routine</h2>
  <ol>
    <li>Read one lesson</li>
    <li>Try the example</li>
  </ol>
</body>
</html>
```

</details>

For the browser exercise, open lesson02-try/index.html in the file manager. Save and reload after edits.

<details><summary>Solution</summary>

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Learning shelf</title>
</head>
<body>
  <h1>My learning shelf</h1>
  <h2>Useful places</h2>
  <p>I practise <strong>a little every day</strong>.</p>
  <p><a href="https://developer.mozilla.org/">Read the MDN guides</a></p>
  <img src="assets/icons/ui/search.svg" width="24" height="24" alt="">
  <h2>Topics</h2>
  <ul>
    <li>HTML</li>
    <li>CSS</li>
    <li>JavaScript</li>
  </ul>
  <h2>My routine</h2>
  <ol>
    <li>Read one lesson</li>
    <li>Try the example</li>
  </ol>
</body>
</html>
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. 

Expected browser change: Topics has HTML, CSS, JavaScript bullets; the link reads Read the MDN guides.

</details>

## Check yourself
1. What does href control?
   <details><summary>Answer</summary>The link destination.</details>
2. Where must search.svg be stored?
   <details><summary>Answer</summary>Inside assets/icons/ui relative to index.html.</details>
3. Which list supplies numbers?
   <details><summary>Answer</summary>ol.</details>
4. Why have alt text?
   <details><summary>Answer</summary>It communicates meaningful image content when unseen; alt="" tells screen readers to skip decoration like this icon.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Source text appears or file ends .html.txt | Windows extensions are hidden, or wrong app opened it | Enable file extensions, rename to index.html and Open with a browser |
| Changes do not appear | Unsaved editor tab, or reloading another folder | Save every changed file; confirm the address; reload |
| Content looks unexpectedly nested | A closing tag is missing or nesting crossed | Match tags inside-out against the full HTML; img is void |
| The small black icon is missing | Wrong image path | Check assets/icons/ui/search.svg exists beneath the index.html folder |

## Best practice
Give meaningful images a useful text alternative; purely decorative images should use empty alt text instead. Source: MDN: img alt https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img#alt

## Next lesson
[03. Forms and semantic HTML](../phase-1-html-and-css/03-forms-and-semantic-html.md): A study-club form with labelled name, email and number fields between a header, main area and footer. This is a local demo, not a registration service.
