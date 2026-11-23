---
track: web
level: 101
phase: 1
phase_name: html-and-css
lesson: 01
title: "How the web works + your first HTML page"
time: 45 min
prerequisites: [none]
versions: { browser: "current Edge/Chrome/Firefox" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-1-html-and-css/01-first-html-page/
assets: []
---

# 01. How the web works + your first HTML page

## Why it matters
A restaurant menu describes what you can order; a waiter carries requests and brings back dishes. The web is similar: a browser asks a server for a page, then displays what it receives. Today your own computer supplies the file; you only need an editor and a browser.

## What you will build
Your first page: a browser tab called My first page, a large Hello, web! heading and one sentence underneath.

## Before you start
- Time: 45 min.
- No previous programming knowledge is required.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Installation is shown below; use the app menus today.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-1-html-and-css/01-first-html-page/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson01 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Install and open VS Code
Visit [code.visualstudio.com/download](https://code.visualstudio.com/download). **Windows:** open Settings > System > About and read System type; choose the x64 User Installer for an x64 PC or ARM64 for an ARM PC. Open the downloaded installer, accept the license, keep the default folder, click Next through the options, Install, then Finish. Open Visual Studio Code from Start. **macOS:** download the .dmg, open it, drag Visual Studio Code.app into Applications, then open it there. **Ubuntu/Debian Linux:** download the .deb, open it in the graphical software center, choose Install, then launch Visual Studio Code. For another distribution use [official Linux setup](https://code.visualstudio.com/docs/setup/linux); managed computers may require IT approval.

Close the Welcome tab. Use menus and the explorer, not command-line tools. Expected result: VS Code is open. Sources: [Windows setup](https://code.visualstudio.com/docs/setup/windows), [macOS setup](https://code.visualstudio.com/docs/setup/mac).

### Step 2. Make and open your own folder
A **folder** groups files; a **file** stores saved text. Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson01**. In VS Code choose **File > Open Folder**, select code101/lesson01, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson01.

Windows: enable **View > Show > File name extensions** (Windows 10: View > File name extensions). This prevents index.html.txt. In VS Code the **Explorer** is the left file panel. Hover beside its top folder name and click **New File** (the small page icon with a plus). Use the exact file name shown. First copy the complete listing from this lesson (not the surrounding backticks), click inside the new file and paste it, press **Ctrl+S** (macOS **Command+S**). A dot on an editor tab means unsaved; save until it disappears. A **folder** groups files; a **file** stores saved text.

### Step 3. Write index.html
Create index.html directly in the lesson folder. Paste the full file and save. title names the tab; body supplies the page content.

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>My first page</title>
</head>
<body>
  <h1>Hello, web!</h1>
  <p>I am learning to build websites.</p>
</body>
</html>
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 4. Open your saved page
In your file manager open code101/lesson01. Right-click index.html > **Open with** and choose Edge, Chrome or Firefox (macOS: **Open With**). Look at the browser's address bar: **file:///** means this is a file on your computer, not a page downloaded from the internet. Expected result: your heading and sentence appear. Lesson 11 teaches automatic reload with Live Server; it is not needed here.

## Run it
Save all files. In your file manager open code101/lesson01, right-click index.html > Open with > Edge, Chrome or Firefox (macOS: Open With). Double-click works if HTML is associated with a browser. VS Code's text view is not the page preview. A local address starts file:///. After every edit save, then reload **Ctrl+R** (macOS **Command+R**).

**Expected browser result:** The tab reads My first page. On a plain white page, Hello, web! appears as a large bold heading; underneath is I am learning to build websites. There are no buttons or pictures.

## How it works
A **browser** (Edge, Chrome or Firefox) reads web files and displays them. A **server** is a program that answers requests for files; your browser is the **client**, the program making the request. **HTTP** (Hypertext Transfer Protocol) is the set of rules for those requests and responses. A **URL** (Uniform Resource Locator) is an address: an https:// address asks a server, while file:/// opens a local file. **HTTPS** is HTTP protected by encryption during transport.

**HTML** (Hypertext Markup Language) describes a page's structure. A **tag** is a marker in angle brackets: `<p>` begins a paragraph and `</p>` ends it. An **element** is the opening tag, contents and closing tag together. **Nesting** means placing an element inside another; close the inside element first.

`<!doctype html>` asks the browser to use modern HTML rules. `<html>` wraps the document; `lang="en"` tells reading tools the language is English. An **attribute** is extra information inside an opening tag, such as lang. `<head>` contains information about the page, not the main visible content. `charset="utf-8"` allows international text. The **viewport** is the part of the browser window where the page shows. The viewport line makes the page use the device's available width; lesson 07 explains responsive layout. `<title>` names the browser tab. `<body>` contains visible content. `<h1>` is the main heading, and `<p>` is a paragraph. CSS controls appearance in lesson 04; JavaScript adds behavior in lesson 08.

## Try it
Make the page greet Ada and describe her as a web beginner. The heading should read Hello, Ada! and the paragraph I am a web beginner. Keep the tab title unchanged.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson01** folder, copy and paste it beside the original, then rename the copy **lesson01-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson01-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. 

<details><summary>Starter files</summary>

**File: `index.html` (starter)**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>My first page</title>
</head>
<body>
  <h1>Hello, web!</h1>
  <p>I am learning to build websites.</p>
</body>
</html>
```

</details>

For the browser exercise, open lesson01-try/index.html in the file manager. Save and reload after edits.

<details><summary>Solution</summary>

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>My first page</title>
</head>
<body>
  <h1>Hello, Ada!</h1>
  <p>I am a web beginner.</p>
</body>
</html>
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. 

Expected browser change: Hello, Ada! is the heading; I am a web beginner. is the paragraph. The tab title is unchanged.

</details>

## Check yourself
1. Does title put a heading on the page?
   <details><summary>Answer</summary>No. It names the browser tab; h1 is the visible heading.</details>
2. Do you need the internet to open this file?
   <details><summary>Answer</summary>No. This file is stored on your computer.</details>
3. Which part contains the visible paragraph?
   <details><summary>Answer</summary>The body.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Source text appears or file ends .html.txt | Windows extensions are hidden, or wrong app opened it | Enable file extensions, rename to index.html and Open with a browser |
| Changes do not appear | Unsaved editor tab, or reloading another folder | Save every changed file; confirm the address; reload |
| Content looks unexpectedly nested | A closing tag is missing or nesting crossed | Match tags inside-out against the full HTML |

## Best practice
Use the HTML document skeleton, including the page language, so browsers and reading tools understand your document. Source: MDN: Basic HTML syntax https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Structuring_content/Basic_HTML_syntax

## Next lesson
[02. Text, links, images, lists](../phase-1-html-and-css/02-text-links-images-lists.md): A learning shelf with a heading hierarchy, an MDN link, a search icon, a bullet list and a numbered routine.
