---
track: react
level: 101
phase: 1
phase_name: first-app
lesson: 01
title: "Install Node, create a Vite React app and run it"
time: 75 min
prerequisites: [web.101]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3" }
verified: not yet run
source: source/react/101-zero-to-hero/phase-1-first-app/01-install-node-and-run-a-vite-app/
assets: []
---

# 01. Install Node, create a Vite React app and run it

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- check that Node and npm are installed and say what each one is for;
- create a Vite and React project file by file and say what each file does;
- start the development server, open the page and see an edit appear without reloading;
- stop the server and start it again.

## Recap
None, this is the start of the React track. You need the finished **Web 101** track (HTML, CSS, JavaScript, TypeScript, `fetch`, modules); this lesson only reminds you of the Node part.

## Why it matters
Think of a restaurant kitchen. You (the cook) write recipes, and a helper turns them into plates and carries them to the table. In a React project your files are the recipes, **Vite** is the helper that turns them into a page the browser understands, and **Node** is the kitchen in which the helper works. Before you can write a single component you need the kitchen and the helper, so this lesson sets them up.

## What you will build
A project folder named `react-app` that shows a page with the heading "Hello, React" and one sentence. You keep this same folder for lessons 01 to 11 and add to it in every lesson.

## Before you start
- Time: 75 minutes for a first-timer (setup lessons are long; take a break after Step 5).
- Finished Web 101. In particular you used Node, npm and TypeScript in [Web 101 lesson 08](../../../web/101-zero-to-hero/phase-2-layout-and-javascript/08-javascript-basics.md) and [lesson 10](../../../web/101-zero-to-hero/phase-3-typescript-and-project/10-typescript-first-steps.md). The words module, import, export and type annotation are not explained again.
- A current Edge, Chrome or Firefox browser and **VS Code** (installed in Web 101 lesson 01).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/101-zero-to-hero/phase-1-first-app/01-install-node-and-run-a-vite-app/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Glossary: keep [the React glossary](../../GLOSSARY.md) nearby.

## Steps

### Step 1. Open a terminal and check Node
A **terminal** is a text window where you type commands. In VS Code choose **Terminal > New Terminal**. The last characters of the line (the **prompt**) show the folder you are in. Type the two commands below. Do not type the `>` or `$` signs at the start of a prompt.

**Folder: any**
```powershell
node --version
npm --version
```
Expected result: `v26.13.1` and `11.20.0`.

**Node** runs JavaScript outside the browser. **npm** is the program that downloads other people's code (a **package**) into your project. If both commands print numbers, go to Step 2. Newer numbers than these usually work too; this course is written for these exact versions.

If a command is not found, install Node:
- **Windows:** open https://nodejs.org/en/download/archive/v26.13.1, download the **Windows Installer (.msi)** for your machine (64-bit is normal), run it and accept the defaults.
- **macOS:** on the same page download the **macOS Installer (.pkg)**, open it and click **Continue** until it finishes.
- **Linux:** follow the official instructions at https://nodejs.org/en/download for your distribution, or use the binary archive from the page above.

Then **close the terminal and open a new one**: old terminals do not see new programs. If Windows PowerShell prints `npm.ps1 cannot be loaded because running scripts is disabled on this system`, type `npm.cmd` instead of `npm` (and `npx.cmd` instead of `npx`) everywhere in this track.

### Step 2. Make the project folder and open it
Open your user folder (**Windows:** Win+E, click the address bar, type `%USERPROFILE%`, Enter; **macOS:** Finder > Go > Home). Make a folder named **code101** if it does not exist, and inside it a folder named **react-app**. In VS Code choose **File > Open Folder**, select `react-app` and click **Select Folder**. If VS Code asks whether you trust the authors, choose **Yes, I trust the authors** (it is your own folder).

Open a new terminal (**Terminal > New Terminal**). The prompt must end with `react-app`. If it does not, go there from any folder:

**Folder: any (Windows PowerShell)**
```powershell
Set-Location "$HOME\code101\react-app"
```

**Folder: any (macOS/Linux)**
```bash
cd "$HOME/code101/react-app"
```
Expected result: the prompt ends with `react-app`, and the VS Code Explorer (the left panel) shows `react-app` as its top folder with nothing inside.

### Step 3. A look at the official generator (optional)
Vite has a generator that writes a starter project for you. You may try it in a **throw-away** folder to see what it makes; do not run it inside `react-app`.

**Folder: any empty folder (not react-app)**
```powershell
npm create vite@latest scratch -- --template react-ts
```
Typical result: it asks a few questions (for example whether to install and start now; answer **No**), then creates a folder `scratch` containing a `package.json`, an `index.html`, a `src` folder and several `tsconfig` files. The exact list and the sample code change between versions, so in this course you write each file yourself. That way you know why every file exists and every version is fixed. Delete the `scratch` folder when you are done looking.

### Step 4. Write package.json
In the VS Code Explorer, hover over the `react-app` row and click **New File** (the page icon with a plus). Name it exactly `package.json`. Paste the content below and save with **Ctrl+S** (macOS **Command+S**). A dot on the editor tab means the file is not saved yet.

**File: `package.json`**
```json
{
  "name": "react-app",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "19.3.1",
    "react-dom": "19.3.1"
  },
  "devDependencies": {
    "@types/react": "19.3.0",
    "@types/react-dom": "19.3.0",
    "@vitejs/plugin-react": "6.3.0",
    "typescript": "5.9.3",
    "vite": "8.3.8"
  }
}
```
Expected result: the file appears in the Explorer without a dot on its tab.

A `package.json` is the project's **manifest**: its name, its commands (**scripts**) and its packages. `dependencies` are packages the finished page needs (`react` makes components, `react-dom` draws them in the browser). `devDependencies` are only tools for you while you build. The numbers are exact on purpose: everyone gets the same versions. `"type": "module"` means the files use `import` and `export`, as you learned in Web 101. TypeScript is 5.9.3 here (Web 101 used 7.0.2) because the larger projects that follow use tools that officially support the 5.x compiler; the language you learned is the same.

### Step 5. Write the Vite and TypeScript settings
Create these five files, each in the `react-app` folder, one at a time, and save each. They are settings, not code you will change often.

**File: `vite.config.ts`**
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: { host: 'localhost', port: 5173, strictPort: true },
});
```

**File: `tsconfig.json`**
```json
{
  "files": [],
  "references": [
    { "path": "./tsconfig.app.json" },
    { "path": "./tsconfig.node.json" }
  ]
}
```

**File: `tsconfig.app.json`**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "noEmit": true,
    "strict": true,
    "skipLibCheck": true,
    "jsx": "react-jsx",
    "types": ["vite/client"],
    "tsBuildInfoFile": "./node_modules/.tmp/tsconfig.app.tsbuildinfo"
  },
  "include": ["src"]
}
```

**File: `tsconfig.node.json`**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "noEmit": true,
    "strict": true,
    "skipLibCheck": true,
    "tsBuildInfoFile": "./node_modules/.tmp/tsconfig.node.tsbuildinfo"
  },
  "include": ["vite.config.ts"]
}
```

**File: `.gitignore`**
```text
node_modules
dist
.env
*.log
*.tsbuildinfo
```
Expected result: five new files in the Explorer, none with an unsaved dot. (The `.gitignore` name starts with a dot on purpose.)

### Step 6. Write index.html and the three source files
`index.html` goes in `react-app` itself. Then make a folder `src` (hover the top folder, **New Folder**) and create `main.tsx`, `App.tsx` and `styles.css` inside it.

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Reading list</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

**File: `src/main.tsx`**
```tsx
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './styles.css';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
```

**File: `src/App.tsx`**
```tsx
export default function App() {
  return (
    <main>
      <h1>Hello, React</h1>
      <p>This page is drawn by a function called App.</p>
    </main>
  );
}
```

**File: `src/styles.css`**
```css
body {
  font-family: system-ui, sans-serif;
  margin: 0;
}

main {
  max-width: 40rem;
  margin: 0 auto;
  padding: 1rem;
}
```
Expected result: `src` holds three files and the project folder holds `index.html` plus the files from Steps 4 and 5. Files that contain JSX (the HTML-like syntax you meet in lesson 02) end in `.tsx`, plain TypeScript ends in `.ts`.

### Step 7. Install the packages
In the terminal, with the prompt ending in `react-app`:

**Folder: `react-app`**
```powershell
npm install
```
Expected result: after some seconds to a minute npm prints a summary such as `added 70 packages` (the number varies) and the Explorer gains a `node_modules` folder (all downloaded code) and a `package-lock.json` file (the exact versions npm chose). Do not edit either one and do not copy them to other folders: `npm install` creates them. Also, `package-lock.json` is not part of the course pack for that reason.

### Step 8. Start the development server
**Folder: `react-app`**
```powershell
npm run dev
```
Typical output (timing and wording can differ):
```text
  VITE v8.3.8  ready in 412 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```
Hold **Ctrl** and click the `Local` address, or type `http://localhost:5173/` into the browser. Expected result: a white page with the large heading **Hello, React** and, below it, the sentence "This page is drawn by a function called App.". The terminal stays busy: that is the server working. Do not type in it.

### Step 9. Change a file and watch the page update
In `src/App.tsx` change `Hello, React` to `Hello, world`, save with Ctrl+S, and look at the browser without clicking anything. Expected result: the heading changes within a moment, without a reload of the whole page. Change it back to `Hello, React` and save.

### Step 10. Stop and start the server
Click inside the terminal and press **Ctrl+C** (also on macOS). The server stops and the prompt returns; the browser page no longer updates. Start it again with `npm run dev`.

## Run it
**Folder: `react-app`**
```powershell
npm run dev
```
Expected output: the Vite banner above, and in the browser the heading "Hello, React". To prove the project also builds for production, stop the server and run:

**Folder: `react-app`**
```powershell
npm run build
```
Typical result: a few lines naming `dist/index.html` and `dist/assets/...` files with sizes. The numbers differ on your machine; no line should say `error`.

## How it works
1. `index.html` is the only page. It has an empty `<div id="root">` and a `<script type="module" src="/src/main.tsx">` line that loads your code.
2. `src/main.tsx` imports `createRoot` from `react-dom/client`, finds the empty div with `document.getElementById('root')` and asks React to draw `<App />` inside it. The `!` after the call is TypeScript's **non-null assertion**: you promise the element exists (it does, in `index.html`), otherwise TypeScript would complain that it might be `null`.
3. `App` is a **component**: a function that returns a description of what the page should look like. The tag-like text it returns is **JSX** (lesson 02).
4. `StrictMode` is a helper wrapper that makes React run some checks twice while you develop, to expose mistakes early. It does nothing in the finished site.
5. `import './styles.css'` makes Vite include the stylesheet. Vite is the **dev server**: it serves your files, converts TypeScript and JSX to JavaScript the browser understands, and pushes changes to the page when you save (**hot reload**).
6. `npm run dev` runs the `dev` script from `package.json`, which runs `vite`. `npm run build` runs `tsc -b` (the type check) and then `vite build`, which writes the finished site into a `dist` folder.
7. The `tsconfig` files tell TypeScript how strict to be and where your files are; `strict: true` switches on all the careful checks you learned in Web 101.

**Common misconception:** "React is a programming language." It is not. React is a JavaScript **library** (packages of ready-made code). You write TypeScript, and React is code you call.

## Try it
Starter: `exercise/starter/src/App.tsx` (a copy of the finished `App.tsx` with two TODO comments).
1. **Guided.** Open `src/App.tsx` in your project. Follow the two TODOs: put your own name in the heading and add a second paragraph about what you want to build with React. Expected result: the browser shows your heading and two paragraphs after you save.
2. **Change.** Add a third paragraph and a level-2 heading (`h2`) above it. Expected result: the page shows the new heading and text; the heading is smaller than the `h1`.
3. **Stretch (optional).** Open `src/styles.css` and make the page background light yellow and the text color dark brown. There is no single right answer; check that the text is still easy to read.

<details><summary>Solution</summary>

**File: `exercise/solution/src/App.tsx`**
```tsx
export default function App() {
  return (
    <main>
      <h1>Hello, Ada</h1>
      <p>This page is drawn by a function called App.</p>
      <p>I want to build a small reading list.</p>
    </main>
  );
}
```
The heading and the new paragraph are just more text inside the same `main` element. Rungs 2 and 3 are small edits of the same file and of `styles.css`.

</details>

## Check yourself
1. What is the difference between Node and npm? <details><summary>Answer</summary>Node runs JavaScript outside the browser; npm downloads packages into your project.</details>
2. Which file lists the packages the project needs? <details><summary>Answer</summary><code>package.json</code> (and <code>package-lock.json</code> records the exact versions chosen).</details>
3. You press Ctrl+C in the terminal and the browser stops updating. Why? <details><summary>Answer</summary>Ctrl+C stopped the Vite dev server that pushes changes; start it again with <code>npm run dev</code>.</details>
4. Predict: you delete the `node_modules` folder and run `npm run dev`. What happens, and what fixes it? <details><summary>Answer</summary>The command fails because `vite` is missing (typical message: <code>'vite' is not recognized as an internal or external command</code>). Run <code>npm install</code> again.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `npm : The term 'npm' is not recognized as the name of a cmdlet...` (typical message) | Node is not installed, or the terminal was opened before installing | Install Node (Step 1), close the terminal and open a new one |
| `npm.ps1 cannot be loaded because running scripts is disabled on this system` | PowerShell blocks script files | Use `npm.cmd` and `npx.cmd` instead of `npm` and `npx` |
| `npm error code ENOENT` ... `Could not read package.json` (typical message) | The terminal is in the wrong folder | Check the prompt ends with `react-app`; use the `Set-Location` or `cd` line from Step 2 |
| `Error: Port 5173 is already in use` (typical message) | Another server (maybe an old terminal) uses the port, and `strictPort` forbids another port | Stop the other one with Ctrl+C in its terminal, then start again |
| A blank white page and red text in the browser console | A typo or an unsaved file | Save every file (no dot on the tabs); compare with the listing; read the first line of the red message |
| You typed the `>` of the prompt | The prompt is not part of the command | Type only the command that follows it |

## Best practice
Pin exact package versions in `package.json` and let `npm install` create the lock file, so every machine builds the same project. Source: npm documentation, `package.json` and `package-lock.json` https://docs.npmjs.com/cli/v11/configuring-npm/package-lock-json

## Going further
- Vite guide: https://vite.dev/guide/
- React, Quick Start: https://react.dev/learn

## Summary
- You checked Node and npm and said what each does.
- You wrote every file of a Vite and React project and installed its packages with `npm install`.
- You started the dev server, saw the page and watched a saved edit appear.
- You stopped and restarted the server and built the site once.

## Next lesson
02. JSX and components: you write your own components and learn the rules of JSX.
