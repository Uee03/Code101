---
track: angular
level: 101
phase: 1
phase_name: first-app
lesson: 01
title: "Install Node and the Angular CLI, create and run your first app"
time: 75 min
prerequisites: [web-101.3.10, web-101.3.11]
versions: { node: "26.13.1 (any ^22.22.3, ^24.15.0 or ^26.0.0 works)", npm: "11.20.0", angular: "22.3.0", angular-cli: "22.3.0", typescript: "6.0.3", rxjs: "7.8.2" }
verified: not yet run
source: source/angular/101-zero-to-hero/phase-1-first-app/01-install-node-and-first-app/
assets: [ui/check-circle]
---

# 01. Install Node and the Angular CLI, create and run your first app

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Install Node.js and check the installed versions in a terminal.
- Create an Angular project with the Angular CLI without installing the CLI globally.
- Start the development server, open the app in the browser and see a saved edit appear.
- Explain in one sentence what Node, npm, the CLI and the development server each do.

## Recap
None in this track, this is the start. Two quick questions from Web 101 that you need today:
1. What is a terminal and how do you move into a folder? <details><summary>Answer</summary>A terminal is a text window where you type commands; `cd folder-name` moves into a folder and the text before `>` or `$` shows where you are.</details>
2. In Web 101 lesson 10 you wrote TypeScript. What turns it into JavaScript the browser understands? <details><summary>Answer</summary>The TypeScript compiler. In Angular the build tool runs it for you, so you never run `tsc` by hand.</details>

## Why it matters
Think of Angular as a prefabricated house kit. A plain HTML page is a pile of bricks: you can build anything, but you place every brick yourself. Angular gives you walls, doors and wiring that already fit together (components, routing, forms, HTTP), and a **command line tool** that unpacks the kit and checks the building for you. Before you build, you need a workshop: Node.js, the engine that runs developer tools on your computer, and a project folder the tool prepared.

## What you will build
A tiny page that shows the heading "My first Angular app" and a short paragraph. It is small on purpose: the goal is to see the whole loop once (create, run, edit, save, see the change, build).

## Before you start
- Web 101 finished (lessons 03, 08, 10 and 11 matter most: HTML, JavaScript, TypeScript and `npm`).
- A terminal and an editor (VS Code is used in Web 101). Time: about 75 minutes for a first-timer, most of it waiting for downloads.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/angular/101-zero-to-hero/phase-1-first-app/01-install-node-and-first-app/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Internet access: the CLI and Angular packages are downloaded (several hundred megabytes in total on the first run).

## Steps

### Step 1. Open a terminal and check whether Node is installed
**Where: any folder.** Open a terminal (Windows: Windows Terminal or PowerShell; macOS: Terminal; Linux: your terminal app) and type:
```text
node --version
npm --version
```
If you see two version numbers, Node is installed. If you see "not recognized" or "command not found", continue with Step 2. If the numbers are older than the ones in the front matter of this lesson, also continue with Step 2.

**What these are.** **Node.js** is a program that runs JavaScript outside the browser; Angular's tools are written for it. **npm** (Node package manager) comes with Node and downloads libraries (called **packages**) from the public registry at npmjs.com.

Expected result (typical, your numbers may differ slightly):
```text
v26.13.1
11.20.0
```

### Step 2. Install Node.js (skip if Step 1 showed a recent version)
Angular 22 accepts Node `^22.22.3`, `^24.15.0` or `^26.0.0` (see https://angular.dev/reference/versions). This course used 26.13.1.
- **Windows and macOS:** open https://nodejs.org/en/download, pick the version above (or any later 26.x), download the installer (`.msi` on Windows, `.pkg` on macOS) and accept the defaults.
- **Linux:** use the commands the same page shows for your package manager.

Then **close the terminal and open a new one**: old terminals do not see the new program. Run the two commands from Step 1 again.

> **Windows PowerShell trap.** If `npm` prints "npm.ps1 cannot be loaded because running scripts is disabled on this system", PowerShell is blocking the helper script. Type `npm.cmd` instead of `npm` (and `npx.cmd` instead of `npx`) in every command of this course, or ask your administrator to allow scripts for your user.

### Step 3. Make a folder for the course
**Where: your user folder.** `mkdir` makes a folder and `cd` moves into it.
```powershell
mkdir code101\angular
cd code101\angular
```
```bash
mkdir -p ~/code101/angular
cd ~/code101/angular
```
Check where you are: the text before the `>` or `$` shows the current folder. If you get lost, `cd` to the folder by its full path again (`cd ~/code101/angular`).

### Step 4. Create the project with the CLI
The **Angular CLI** (command line interface) is the program with the command `ng`. It creates projects, starts the development server and builds the app. Many guides tell you to install it globally (`npm install -g @angular/cli`). We do not, for two reasons: a global install is one version for every project on your computer, and it changes your machine. Instead `npx` downloads the exact version we name, runs it once, and leaves nothing behind.

**Where: `code101/angular`.** Type this as **one line**:
```text
npx --yes -p @angular/cli@22.3.0 ng new tasks-first --routing --style=css --ssr=false --skip-git --skip-tests --ai-config=none --package-manager=npm --defaults
```
What each part means:

| Part | Meaning |
|------|---------|
| `npx --yes -p @angular/cli@22.3.0 ng` | Download CLI version 22.3.0 (say yes to the prompt) and run its `ng` command |
| `new tasks-first` | Create a project named `tasks-first` in a new folder of that name |
| `--routing` | Include the router files (lesson 07 uses them) |
| `--style=css` | Plain CSS files for styles (you know CSS from Web 101) |
| `--ssr=false` | No server-side rendering (not needed here) |
| `--skip-git` | Do not start a git repository |
| `--skip-tests` | Do not generate test files (this track does not cover testing) |
| `--ai-config=none` | Do not generate configuration files for AI tools |
| `--package-manager=npm` | Use npm to install the packages |
| `--defaults` | Do not ask questions for options that have a default |

The command downloads packages and takes a few minutes. If it still asks a question, press Enter to accept the default.

Expected result (typical, not yet run: the exact list of files changes between CLI versions):
```text
CREATE tasks-first/README.md
CREATE tasks-first/.editorconfig
CREATE tasks-first/.gitignore
CREATE tasks-first/angular.json
CREATE tasks-first/package.json
CREATE tasks-first/tsconfig.json
CREATE tasks-first/tsconfig.app.json
CREATE tasks-first/public/favicon.ico
CREATE tasks-first/src/index.html
CREATE tasks-first/src/main.ts
CREATE tasks-first/src/styles.css
CREATE tasks-first/src/app/app.config.ts
CREATE tasks-first/src/app/app.routes.ts
CREATE tasks-first/src/app/app.ts
CREATE tasks-first/src/app/app.html
CREATE tasks-first/src/app/app.css
Packages installed successfully.
```

### Step 5. Open the project
```powershell
cd tasks-first
code .
```
`code .` opens the current folder in VS Code (if the command is missing, open the folder from the VS Code menu: **File, Open Folder**). Open a terminal inside VS Code (**Terminal, New Terminal**); it starts in `tasks-first`.

### Step 6. Make your project identical to the course project
The CLI writes some files with slightly different comments or defaults depending on its version. So that everyone has exactly the same project, you now replace a few files with the course versions. Open each file in VS Code, select everything, paste the content below and save. A dot on the editor tab means "not saved yet".

**File: `package.json`** (replaces the generated one: it pins every version exactly and removes everything this track does not use)
```json
{
  "name": "tasks-first",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "ng": "ng",
    "start": "ng serve --host localhost --port 4200",
    "build": "ng build"
  },
  "dependencies": {
    "@angular/common": "22.3.0",
    "@angular/compiler": "22.3.0",
    "@angular/core": "22.3.0",
    "@angular/forms": "22.3.0",
    "@angular/platform-browser": "22.3.0",
    "@angular/router": "22.3.0",
    "rxjs": "7.8.2",
    "tslib": "2.8.1"
  },
  "devDependencies": {
    "@angular/build": "22.3.0",
    "@angular/cli": "22.3.0",
    "@angular/compiler-cli": "22.3.0",
    "typescript": "6.0.3"
  }
}
```

Line by line: `name` is the project name; `private: true` stops an accidental publish to npm; `scripts` are shortcuts you run with `npm run <name>` (`npm start` is a special short form); `dependencies` are packages the **app** needs in the browser; `devDependencies` are tools only needed to build. Exact versions (no `^`) mean everybody installs the same code.

After saving, install again so the packages match. This also creates `package-lock.json`, a file that records the exact version of every package; do not edit it.
```text
npm install --no-audit --no-fund
```
The two flags only hide an audit summary and a funding message.

**File: `angular.json`** (the workspace settings: which file starts the app, which styles and assets to include, what to do for development and production)
```json
{
  "$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "cli": {
    "packageManager": "npm",
    "analytics": false
  },
  "newProjectRoot": "projects",
  "projects": {
    "tasks-first": {
      "projectType": "application",
      "schematics": {
        "@schematics/angular:class": {
          "skipTests": true
        },
        "@schematics/angular:component": {
          "skipTests": true
        },
        "@schematics/angular:directive": {
          "skipTests": true
        },
        "@schematics/angular:guard": {
          "skipTests": true
        },
        "@schematics/angular:interceptor": {
          "skipTests": true
        },
        "@schematics/angular:pipe": {
          "skipTests": true
        },
        "@schematics/angular:resolver": {
          "skipTests": true
        },
        "@schematics/angular:service": {
          "skipTests": true
        }
      },
      "root": "",
      "sourceRoot": "src",
      "prefix": "app",
      "architect": {
        "build": {
          "builder": "@angular/build:application",
          "options": {
            "browser": "src/main.ts",
            "tsConfig": "tsconfig.app.json",
            "assets": [
              {
                "glob": "**/*",
                "input": "public"
              }
            ],
            "styles": [
              "src/styles.css"
            ]
          },
          "configurations": {
            "production": {
              "budgets": [
                {
                  "type": "initial",
                  "maximumWarning": "500kB",
                  "maximumError": "1MB"
                },
                {
                  "type": "anyComponentStyle",
                  "maximumWarning": "4kB",
                  "maximumError": "8kB"
                }
              ],
              "outputHashing": "all"
            },
            "development": {
              "optimization": false,
              "extractLicenses": false,
              "sourceMap": true
            }
          },
          "defaultConfiguration": "production"
        },
        "serve": {
          "builder": "@angular/build:dev-server",
          "configurations": {
            "production": {
              "buildTarget": "tasks-first:build:production"
            },
            "development": {
              "buildTarget": "tasks-first:build:development"
            }
          },
          "defaultConfiguration": "development"
        }
      }
    }
  }
}
```

You do not need to memorise this file. The parts to recognise: `"browser": "src/main.ts"` is where the app starts; `"styles"` lists the global stylesheet; `"assets"` copies everything in `public/` to the site; `skipTests` stops `ng generate` from creating test files; the `production` configuration makes a small, fast build and the `development` configuration keeps it readable for debugging.

**File: `tsconfig.json`** (TypeScript settings for the whole project)
```json
/* To learn more about Typescript configuration file: https://www.typescriptlang.org/docs/handbook/tsconfig-json.html. */
/* To learn more about Angular compiler options: https://angular.dev/reference/configs/angular-compiler-options. */
{
  "compileOnSave": false,
  "compilerOptions": {
    "strict": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "skipLibCheck": true,
    "isolatedModules": true,
    "experimentalDecorators": true,
    "importHelpers": true,
    "target": "ES2022",
    "module": "preserve"
  },
  "angularCompilerOptions": {
    "enableI18nLegacyMessageIdFormat": false,
    "strictInjectionParameters": true,
    "strictInputAccessModifiers": true,
    "strictTemplates": true
  },
  "files": [],
  "references": [
    {
      "path": "./tsconfig.app.json"
    }
  ]
}
```

`"strict": true` turns on TypeScript's strict checks (the same idea as in Web 101). `strictTemplates` makes the Angular compiler check your HTML templates with the same strictness. The file starts with two comments (`/* ... */`), which this format allows.

**File: `tsconfig.app.json`** (settings for the app code only)
```json
/* To learn more about Typescript configuration file: https://www.typescriptlang.org/docs/handbook/tsconfig-json.html. */
/* To learn more about Angular compiler options: https://angular.dev/reference/configs/angular-compiler-options. */
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "types": []
  },
  "include": [
    "src/**/*.ts"
  ],
  "exclude": [
    "src/**/*.spec.ts"
  ]
}
```

If `tsconfig.spec.json` exists in your project it is unused; you can delete it.

### Step 7. Replace the page shell and the icon
The browser loads one HTML file for the whole app, `src/index.html`. Angular fills `<app-root>` with your app.

**File: `src/index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Tasks First</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/svg+xml" href="favicon.svg">
</head>
<body>
  <app-root></app-root>
</body>
</html>
```

`<base href="/">` tells the router that the app lives at the site root. The `<link rel="icon">` line points to an SVG tab icon, so delete the old `public/favicon.ico` and create this file:

**File: `public/favicon.svg`** (the CC0 `ui/check-circle` icon from the course art library, drawn in a fixed blue because a browser tab has no text colour to inherit)
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#1d6fb8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
</svg>
```

**File: `src/main.ts`** (the very first TypeScript file that runs; the generated one is normally identical)
```ts
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';

bootstrapApplication(App, appConfig)
  .catch((err) => console.error(err));
```

`bootstrapApplication` starts the app: it takes the root component `App` and the app configuration. `.catch(...)` prints a start-up error to the browser console.

**File: `src/styles.css`** (global styles: they apply to the whole page)
```css
body {
  font-family: system-ui, sans-serif;
  line-height: 1.5;
  margin: 2rem;
}
```

### Step 8. Check the configuration files and write the first component
The router files are generated by `--routing`. They are empty for now; show the same content in yours.

**File: `src/app/app.config.ts`** (app-wide settings, called the **application config**)
```ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [provideBrowserGlobalErrorListeners(), provideRouter(routes)]
};
```

`provideBrowserGlobalErrorListeners()` reports errors that nobody caught; `provideRouter(routes)` switches routing on (lesson 07).

**File: `src/app/app.routes.ts`** (the list of pages; empty until lesson 07)
```ts
import { Routes } from '@angular/router';

export const routes: Routes = [];
```

Now the part you will edit all course long. An Angular app is a tree of **components**: a component is a TypeScript class plus an HTML template plus CSS. `App` is the root component.

**File: `src/app/app.ts`**
```ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = 'My first Angular app';
}
```

**File: `src/app/app.html`**
```html
<main class="page">
  <h1>{{ title }}</h1>
  <p>Angular is running. Edit <code>src/app/app.html</code> and save to see this page change.</p>
</main>
```

**File: `src/app/app.css`**
```css
.page {
  max-width: 40rem;
  margin: 0 auto;
}

h1 {
  color: #1d6fb8;
}
```

`{{ title }}` in the HTML is **interpolation**: Angular replaces it with the value of `title` from the class. Lesson 03 explains it fully.

## Run it
**Where: the `tasks-first` folder.**
```text
npm start
```
`npm start` runs the `start` script from `package.json`, which is `ng serve --host localhost --port 4200`. That starts the **development server**: it builds the app in memory, serves it at an address and rebuilds whenever you save a file.

**Predict before you look:** which address will you open, and what text will be the page heading?

Expected output (typical, not yet run):
```text
Application bundle generation complete.
Watch mode enabled. Watching for file changes...
  Local:   http://localhost:4200/
```
Open http://localhost:4200/ in your browser. You should see the heading "My first Angular app" in blue and the paragraph below it. Use `localhost`, not `127.0.0.1`: the capstones later depend on that exact name.

Now edit `src/app/app.html`: change the word "Edit" to "Change" in the paragraph and save. The browser tab reloads by itself in a moment. Stop the server with **Ctrl+C** in the terminal (answer `y` if it asks to terminate the batch job).

Finally make a **production build**, the optimised files you would put on a web server:
```text
npm run build
```
Expected output (typical, not yet run): a table of the generated files with their sizes and a line like `Output location: .../tasks-first/dist/tasks-first`. The build fails with a message on any TypeScript or template error, which makes it a good last check.

## How it works
1. `index.html` is the only page. It contains `<app-root>`.
2. `main.ts` calls `bootstrapApplication(App, appConfig)`. Angular finds the component whose `selector` is `app-root` (it is `App`) and renders its template inside the `<app-root>` element.
3. The `@Component` text above the class is a **decorator**: a label that tells Angular "this class is a component, here are its selector, template file and style file".
4. The development server watches your files. When you save, it rebuilds and tells the browser to reload.

**Misconception:** "Angular runs in my terminal." No: `ng serve` only prepares and delivers files. The app itself runs in the browser, like the JavaScript you wrote in Web 101.

**Two TypeScript versions.** Web 101 teaches TypeScript 7.0.2. Angular 22 only accepts TypeScript 6.0.x, so this project pins 6.0.3. The language you learned is the same; only the compiler inside the project differs.

## Try it
Copy the starter file `exercise/starter/src/app/app.html` over your `src/app/app.html` (or open it and use it as a guide), then:
1. **Guided:** complete the three TODO comments in `app.html`: an `<h2>`, a paragraph and a list of three items.
2. **Change:** in `app.ts` change the value of `title`, and in `app.css` change the heading colour. Predict what you will see before you save.
3. **Stretch (optional):** add a `<footer>` with your name. There is no single right answer: where on the page does it read best?

<details><summary>Solution for rung 1</summary>

**File: `exercise/solution/src/app/app.html`**
```html
<main class="page">
  <h1>{{ title }}</h1>
  <p>Angular is running. Edit <code>src/app/app.html</code> and save to see this page change.</p>
  <h2>About me</h2>
  <p>I am learning Angular to build web apps that talk to a real server.</p>
  <ul>
    <li>A task list</li>
    <li>A small team dashboard</li>
    <li>A form that checks its own input</li>
  </ul>
</main>
```

</details>

## Check yourself
1. What is the difference between Node and npm? <details><summary>Answer</summary>Node runs JavaScript programs and tools outside the browser; npm downloads the packages those programs use.</details>
2. Why do we run the CLI with `npx -p @angular/cli@22.3.0 ng` instead of installing it globally? <details><summary>Answer</summary>It pins one exact version per project and leaves nothing installed on the computer.</details>
3. Which file contains `<app-root>` and which file decides which component fills it? <details><summary>Answer</summary>`src/index.html` contains the element; `src/main.ts` passes `App` (whose selector is `app-root`) to `bootstrapApplication`.</details>
4. You change `title` in `app.ts` but the page does not change. Name two likely reasons. <details><summary>Answer</summary>The file is not saved (dot on the tab) or the development server is not running (or shows a build error in the terminal).</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `ng` is not recognized (Windows) or `ng: command not found` | The CLI is not installed globally (on purpose) | Use `npx --yes -p @angular/cli@22.3.0 ng ...`, or inside the project `npm run ng -- <command>` |
| `npm.ps1 cannot be loaded because running scripts is disabled on this system` | PowerShell's script policy | Use `npm.cmd` and `npx.cmd` |
| Typical message: the serve command "requires to be run in an Angular project, but a project definition could not be found" | The terminal is not inside `tasks-first` | `cd` into the folder that contains `angular.json` |
| Typical message: npm cannot find `package.json` (`ENOENT`) | Wrong folder for an `npm` command | `cd tasks-first` first |
| The page shows `{{ title }}` as text or a blank page | `app.html` or `app.ts` was not saved, or the browser console shows an error | Save both files, read the terminal and the browser console (F12) |
| Typical message: port 4200 is already in use | An older `npm start` is still running | Stop it with Ctrl+C, or accept the different port Angular offers |

## Best practice
Pin versions and run the CLI through the project: the same command then does the same thing for everybody, today and in a year. Source: Angular, Setting up the local environment https://angular.dev/tools/cli/setup-local

## Going further
- Read the version table at https://angular.dev/reference/versions to see which Node and TypeScript each Angular version needs.
- The full list of `ng new` options: https://angular.dev/cli/new

## Summary
- You installed (or checked) Node and npm and read their versions.
- You created an Angular project with `npx` and the CLI, and replaced the configuration with the course versions.
- You started the development server, saw the page at http://localhost:4200/ and watched an edit appear.
- You built the app once for production.

## Next lesson
02. Project tour and standalone components: what every file does, and how to make your own component.

<details>
<summary>Files that did not change in this lesson (listed so this page is complete)</summary>

**File: `.gitignore`**

```
node_modules/
dist/
.angular/
.env
*.log
```

</details>
