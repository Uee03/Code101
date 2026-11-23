---
track: web
level: 101
phase: 3
phase_name: typescript-and-project
lesson: 10
title: "TypeScript first steps"
time: 90-120 min
prerequisites: [101.3.09]
versions: { browser: "current Edge/Chrome/Firefox", node: "26.13.1", npm: "11.20.0", typescript: "7.0.2" }
verified: 2026-11-23 on Windows 11; smoke checks only
source: source/web/101-zero-to-hero/phase-3-typescript-and-project/10-typescript-first-steps/
assets: []
---

# 10. TypeScript first steps

## Why it matters
A labelled box stops you putting flour where screws belong. TypeScript labels the shapes of program values and warns when they do not fit. It catches mistakes before Node or the browser runs the JavaScript.

## What you will build
A profile with string, number and boolean fields, compiled to JavaScript and run in Node. Deliberately trigger and repair a real type error.

## Before you start
- Time: 90-120 min. Two sittings; use the marked break in Steps.
- Complete lessons 01 to 09. Keep the [Web glossary](../../GLOSSARY.md) nearby.
- VS Code (an editor, an app for plain-text files) and a current Edge, Chrome or Firefox browser. Use the VS Code installed in lesson 01.
- Node 26.13.1 and npm 11.20.0; installation is shown below. TypeScript 7.0.2 is installed per project below.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/101-zero-to-hero/phase-3-typescript-and-project/10-typescript-first-steps/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Create your own lesson10 first and use code/ to compare. Exercises have separate starter/solution folders; do not edit another lesson by accident.

## Steps

### Step 1. Make and open your own folder
Open your user folder: **Windows**, press Win+E, click the address bar, type %USERPROFILE% and Enter; **macOS**, Finder > Go > Home; **Linux**, your file manager > Home. If **code101** already exists, open it. Otherwise, in an empty area use **right-click > New > Folder** on Windows, **File > New Folder** on macOS, or **New Folder** on Linux; name it **code101** and open it. Inside it, use the same folder-creation clicks and name the new folder **lesson10**. In VS Code choose **File > Open Folder**, select code101/lesson10, then **Select Folder** or **Open**. If asked **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder. Expected result: the left explorer's top folder is lesson10.

Windows: enable **View > Show > File name extensions** (Windows 10: View > File name extensions). This prevents index.html.txt. In VS Code the **Explorer** is the left file panel. Hover beside its top folder name and click **New File** (the small page icon with a plus). Use the exact file name shown. First copy the complete listing from this lesson (not the surrounding backticks), click inside the new file and paste it, press **Ctrl+S** (macOS **Command+S**). A dot on an editor tab means unsaved; save until it disappears. A **folder** groups files; a **file** stores saved text.

### Step 2. Install or confirm Node LTS, then open a terminal
1. Visit [Node 26.13.1's official archive](https://nodejs.org/en/download/archive/v26.13.1). The [release table](https://nodejs.org/en/about/previous-releases) marks v26 as **LTS**, Long-Term Support, a release line receiving extended fixes. Do not choose v27 Alpha. This course pins Node 26.13.1 and bundled npm 11.20.0, checked on 2026-11-23.
2. **Windows:** Settings > System > About lists System type. Most PCs are x64; choose ARM64 only for an ARM-based PC. Download node-v26.13.1-x64.msi (or ARM64 .msi) from the archive. Open it, choose Next, accept the license, keep the default folder and npm/Add to PATH features, then Next > Install > Finish. Optional native-addon build tools are not needed. Approve the installer prompt if your organization permits it.
3. **macOS:** download node-v26.13.1.pkg from the archive, open it, then Continue, accept the license, Install, and Close. Enter your Mac password when requested.
4. **Linux (Ubuntu/Debian x64):** use your browser to download node-v26.13.1-linux-x64.tar.xz from the archive. In Files > Downloads, right-click it > Extract Here. Move the extracted node-v26.13.1-linux-x64 folder into Home. On ARM64 use linux-arm64 and replace x64 with arm64 in the path below. For other platforms choose the matching official binary and documentation. If this archive route does not fit your distribution, use the [official Node download selector](https://nodejs.org/en/download) instead: select **Linux** and your architecture and follow its displayed package-manager instructions for your system. Do not run both install routes.
5. Close VS Code and reopen it: old terminals may not see new **PATH** entries. PATH is the list of folders searched for commands. Open the lesson folder, then **Terminal > New Terminal**; on Windows choose PowerShell if asked. Text before > (or $ on macOS/Linux) is the **prompt**, not part of a command; never type it. If Windows PowerShell blocks npm.ps1, use npm.cmd and npx.cmd; the captured message and workaround are immediately below the version check.

**Folder: home (Linux x64 only)**
```bash
export PATH="$HOME/node-v26.13.1-linux-x64/bin:$PATH"
```
Expected result: silence. This sets PATH for this terminal; repeat it in each new terminal. ARM64 users substitute arm64 for x64 in the folder name. No shell configuration file is needed.

**Folder: your lesson folder (Windows PowerShell; identical commands on macOS/Linux)**
```powershell
node --version
npm --version
```
Expected output from the pinned tools, captured on the author machine:
```text
v26.13.1
11.20.0
```

**If npm is blocked in Windows PowerShell**, this captured message identifies the script-policy trap (installation folder replaced):
```text
npm : File <node-install>\npm.ps1 cannot be loaded because running scripts is disabled on this system. For
more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
```
Use `npm.cmd --version` instead (11.20.0); substitute **npm.cmd** and **npx.cmd** for every later npm/npx command if needed. No execution-policy change is required. On an organization-managed PC ask IT rather than weakening policy. macOS/Linux keep npm/npx.



### Step 3. Check the working folder
All terminal commands run in lesson10, the folder holding package.json. Use these recovery commands from any folder:

**Folder: any (Windows PowerShell)**
```powershell
Set-Location "$HOME\code101\lesson10"
Get-Location
```

**Folder: any (macOS/Linux)**
```bash
cd "$HOME/code101/lesson10"
pwd
```

Expected result: a path ending code101/lesson10. Windows adds a Path heading; usernames/separators vary. Never type the prompt > or $. Create files using the VS Code explorer, not terminal redirection.

### Step 4. Write package.json
Create package.json directly in the lesson folder and save this full **manifest** (project description). A **module** is a file that shares code using import/export. **JSON** (JavaScript Object Notation) is a text format with double-quoted names and strings, commas between entries and braces around groups; no trailing commas. The exact compiler version prevents silent version changes.

**File: `package.json`**
```json
{
  "name": "web-lesson-10",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "tsc"
  },
  "engines": {
    "node": "26.13.1",
    "npm": "11.20.0"
  },
  "devDependencies": {
    "typescript": "7.0.2"
  }
}
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 5. Write tsconfig.json
Create tsconfig.json beside package.json and save the complete compiler configuration.

**File: `tsconfig.json`**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "Bundler",
    "lib": [
      "ES2022",
      "DOM"
    ],
    "rootDir": "src",
    "outDir": "dist",
    "strict": true,
    "noEmitOnError": true,
    "skipLibCheck": true
  },
  "include": [
    "src/**/*.ts"
  ]
}
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

package.json names the project and pins the development compiler. private prevents accidental publication; type module selects import/export files. scripts.build provides an optional build command; engines records the expected Node/npm versions. devDependencies lists build-time tools.

Keep this configuration exactly as shown: TypeScript reads editable files in **src**, checks them strictly, and writes JavaScript in **dist**. On a compile error it writes no new JavaScript, but old output may remain: **do not run after an error**. You do not need to memorize the option names; the [official configuration reference](https://www.typescriptlang.org/tsconfig/) explains alternatives.

**Break - end of sitting 1.** Your two configuration files are saved. In sitting 2, write the profile, install the compiler and run it.

### Step 6. Write src/app.ts
Using the VS Code explorer, make a New Folder named src if it does not exist. Inside it make app.ts and save the full file. This is editable TypeScript, not the browser-loaded file.

**File: `src/app.ts`**
```typescript
interface Profile {
  name: string;
  sessions: number;
  active: boolean;
}
function describe(profile: Profile): string {
  if (profile.active) {
    return profile.name + " studies " + profile.sessions + " times a week.";
  }
  return profile.name + " is taking a break.";
}
const profile: Profile = { name: "Ada", sessions: 3, active: true };
console.log(describe(profile));
```

Expected result: the file appears at the exact path in the explorer; no unsaved dot remains.

### Step 7. Install the pinned compiler and keep the lockfile
**Folder: lesson10 (all operating systems)**
```powershell
npm install -D --save-exact typescript@7.0.2 --no-audit --no-fund
```

Expected result on a fresh Windows install (captured; counts and time can differ by platform):
```text
added 2 packages in 2s
```
A repeated install can say **up to date** instead. npm creates **node_modules** (downloaded tools) and **package-lock.json** (exact resolved versions). Do not open or type these generated files. The optional source folder keeps a full lockfile for reproducible installs; when using it, run `npm install --no-audit --no-fund` instead of the download command above.

**Before any `npx tsc`:** check that your terminal is in this lesson's folder containing package.json, and that npm install succeeded. npx uses the **locally installed TypeScript compiler only when it is present**. Outside the project it may ask to install the unrelated package **tsc**: answer **n**, return to the correct folder, run npm install, then retry. Do not accept that package prompt. The Windows policy workaround from lesson 08 is still npm.cmd/npx.cmd.

## Run it
**Folder: lesson10 (all operating systems)**
```powershell
npx tsc
```

Expected result: silence and a normal prompt. dist now has generated .js files. If errors appear, stop; repair source before running any old output. Run the compiled entry:

**Folder: lesson10 (all operating systems)**
```powershell
node dist/app.js
```

Expected Node output (captured):
**Output**
```text
Ada studies 3 times a week.
```

**Trigger and read a real compiler error:** in src/app.ts change only sessions: 3 in the object to sessions: "three". Save, then npx tsc in lesson10 gives this captured diagnostic:

**Output**
```text
src/app.ts(12,41): error TS2322: Type 'string' is not assignable to type 'number'.
```

src/app.ts is the file, (12,41) is line/column, TS2322 is the diagnostic code. The words say a string cannot fill a number field. Positions shift if you insert lines. No new JavaScript is emitted. Restore sessions: 3 (the correct full file is in Steps), save, npx tsc again: silence. Then node dist/app.js prints the original sentence. Do not hide the error with any. In the lesson10 terminal, `npx tsc --version` reports:

**Output**
```text
Version 7.0.2
```

**Expected browser result:** There is no HTML page in this lesson. Successful compilation is silent; node dist/app.js prints Ada studies 3 times a week.

## How it works
**TypeScript** adds checking to JavaScript. A **type** describes permitted values. name: string, sessions: number and active: boolean constrain the fields. An **interface** names an object's expected shape. An **object** groups named fields in braces; a **property** is a named field. profile: Profile checks its shape. A **type annotation** is the colon and type; : string after function parameters describes its returned value.

A **compiler** checks source code and converts it to runnable code. tsc is TypeScript's compiler; **compilation** is checking/conversion. Interfaces and annotations disappear from JavaScript. They do not validate incoming data at runtime. The active condition chooses the study sentence or break sentence.

A **package** is reusable code with metadata. package.json is the **manifest**, the project description and dependencies. A **dependency** is a needed package; a **development dependency** is needed to build rather than by the finished browser page. -D records a development dependency; --save-exact prevents adding a floating version range. **npx** runs a command; here it selects the installed project compiler after npm install. Without that local installation it may offer a different download; answer n as warned above. A **lockfile** records exact downloaded versions and integrity checks; npm generates it.

src is the **source folder**, with editable TypeScript; dist is the **output folder**, with generated JavaScript. Fix bugs in src/app.ts, save, then compile; the next build overwrites edits to dist. A **module** is a file sharing code through exports/imports. The module settings prepare for lesson 11. **any** disables useful type checks; do not use it to hide this lesson's diagnostic.

## Try it
Make the same profile describe a break rather than a study schedule, without removing the condition or changing the field types. Compile, then run: the expected sentence is Ada is taking a break.

**Separate exercise folder:** in your file manager, open code101, select your completed **lesson10** folder, copy and paste it beside the original, then rename the copy **lesson10-try**. In VS Code choose **File > Open Folder** and open that copy. If using the optional repository instead, copy the **starter** folder from this lesson's exercise folder and rename the copy **lesson10-try**; do not put starter inside another folder. The starter is identical to your finished lesson files.

Editable starter files follow in full. Keep package.json and tsconfig.json unchanged. npm generates package-lock.json; keep it too. Only the working folder name differs: lesson10-try rather than lesson10. 

<details><summary>Starter files</summary>

**File: `src/app.ts` (starter)**
```typescript
interface Profile {
  name: string;
  sessions: number;
  active: boolean;
}
function describe(profile: Profile): string {
  if (profile.active) {
    return profile.name + " studies " + profile.sessions + " times a week.";
  }
  return profile.name + " is taking a break.";
}
const profile: Profile = { name: "Ada", sessions: 3, active: true };
console.log(describe(profile));
```

</details>

Choose Terminal > New Terminal. Check that the prompt ends lesson10-try. Recovery commands run from any folder: Windows PowerShell uses Set-Location "$HOME\code101\lesson10-try"; macOS/Linux uses cd "$HOME/code101/lesson10-try". Linux users repeat their Node PATH export if needed. Then run (Windows npm.cmd/npx.cmd if policy requires):

**Folder: lesson10-try (all operating systems)**
```powershell
npm install --no-audit --no-fund
npx tsc
node dist/app.js
```

<details><summary>Solution</summary>

**File: `src/app.ts`**
```typescript
interface Profile {
  name: string;
  sessions: number;
  active: boolean;
}
function describe(profile: Profile): string {
  if (profile.active) {
    return profile.name + " studies " + profile.sessions + " times a week.";
  }
  return profile.name + " is taking a break.";
}
const profile: Profile = { name: "Ada", sessions: 3, active: false };
console.log(describe(profile));
```

Only the requested changes are made; unchanged surrounding code is included so you need not infer it. Keep the manifest, compiler config and generated lockfile unchanged. 

Expected Node output (captured from solution):
**Output**
```text
Ada is taking a break.
```

</details>

## Check yourself
1. Does an interface survive into JavaScript?
   <details><summary>Answer</summary>No. It is used during compilation.</details>
2. Where should you edit a bug?
   <details><summary>Answer</summary>src/app.ts, then recompile.</details>
3. What does -D mean?
   <details><summary>Answer</summary>Save a development dependency.</details>
4. Why keep the lockfile?
   <details><summary>Answer</summary>It records exact resolved packages.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `src/app.ts(12,41): error TS2322: Type 'string' is not assignable to type 'number'.` | sessions is quoted text | Restore a number, save and compile again |
| npx asks to install tsc | Wrong folder or TypeScript was not installed there | Answer n. Return to lesson10 containing package.json, run npm install --no-audit --no-fund, then npx tsc |
| `npm error npx canceled due to missing packages and no YES option: ["tsc@2.0.4"]` | The same missing-compiler problem with npx --no-install tsc | Do not install tsc; use the local typescript dependency as above |
| Node prints the old sentence | Source is unsaved or was not recompiled | Save src/app.ts; compile successfully before node dist/app.js |

## Best practice
Install TypeScript per project and keep its pinned dependency and lockfile with the source. Source: TypeScript: Download https://www.typescriptlang.org/download/

## Next lesson
[11. TypeScript in the browser](../phase-3-typescript-and-project/11-typescript-in-the-browser.md): A module page that fetches a local mock profile and shows Meet Ada, a biography and three skills.
