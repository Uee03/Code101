---
track: csharp
level: 101
phase: 1
phase_name: foundations
lesson: 01
title: "Hello, C#"
time: 100-120 min
prerequisites: [none]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-1-foundations/01-hello-csharp/
assets: []
---

# 01. Hello, C#

## Why it matters
A recipe is a list of instructions a cook can follow. A program is a list of instructions a computer can follow. C# (say "C sharp") is the language we will use; .NET supplies the tools that build and run it.

## What you will build
A **terminal** is a window for typing commands and seeing text replies. You will build a **console program**, which uses text in that window rather than buttons, then print a recipe card of your own.

## Before you start
- No programming experience needed. Installation and editor setup are included below.
- Time: 100-120 min, including installation, typing and the exercise; follow only your own operating system's install route.
- Tools: .NET and Visual Studio Code, installed below. Commands were run on Windows; macOS/Linux install routes are documentation-based.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-1-foundations/01-hello-csharp/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it, **Extract All**, **Extract**; macOS, double-click it; Linux, right-click, **Extract Here**. Open the extracted Code101 folder to find `source/csharp`.
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Open a terminal
A **terminal** is a window for typing commands and seeing text replies. On Windows press Start, type **PowerShell**, then open **Windows PowerShell**. On macOS press Command+Space, type **Terminal**, then Return. On Ubuntu Linux press Ctrl+Alt+T.

The text before `>` (PowerShell) or `$` (many macOS/Linux terminals) is the **prompt**; do not type it. A **command** is an instruction you type and submit with Enter. Your **current folder**, also called working directory, is where relative file names are resolved. PowerShell's prompt normally includes it. If unsure, run Get-Location (Windows) or pwd (macOS/Linux) from any folder; the result is your own folder path, which varies by account.

`~` and `$HOME` mean your user home folder, not this repository. In a Windows file dialog, `%USERPROFILE%` in the address bar opens that home folder; then open code101, csharp and the named lesson or exercise folder. On macOS, press Command+Shift+G in a file dialog and enter the shown ~/ path. On Linux, Ctrl+L in most file managers lets you enter the ~/ path. In the terminal, use the commands below rather than typing a path on its own.

### Step 2. Install the .NET SDK for your operating system
The **SDK** (software development kit) includes tools that build programs. The **runtime** executes built programs; the SDK includes it. Start at the [official install hub](https://learn.microsoft.com/dotnet/core/install/). Choose just your operating system below, not all three.

**Version choice, checked 2026-11-23:** the [official support policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core) lists .NET 11 as supported STS (standard-term support), released November 10, 2026 with support through November 14, 2028. A **feature band** is an SDK update family: `11.0.1xx` begins at `11.0.100`. A **servicing patch** is an update within that family. The installed SDK is 11.0.100, so these lessons pin that feature band. The **target framework**, written `net11.0`, selects the .NET version the program uses. STS describes the support period, not a preview. Install current servicing updates; later 11.0.1xx patches are allowed by our pin. Check your OS against the install page's supported-versions table first.

**Windows 11 route (official SDK installer):**
1. Open the [Windows instructions](https://learn.microsoft.com/dotnet/core/install/windows), then [Download .NET 11](https://dotnet.microsoft.com/en-us/download/dotnet/11.0).
2. In **Build apps - SDK**, find **SDK 11.0.100** (or a newer 11.0.1xx servicing patch), row **Windows**, column **Installers**. Most Intel/AMD PCs use **x64**; Windows on ARM uses **Arm64**. The **x86** column is for 32-bit apps, not this 64-bit Windows 11 route. Check **Settings > System > About > System type** if unsure. Do not choose only a Runtime download.
3. Open the downloaded .exe. Select **Install**, approve the administrator prompt if asked, wait for completion and select **Close**. If the installer offers Modify/Repair because it is already installed, close it and check the version instead.
4. Close PowerShell and open a new PowerShell window; old terminals may not see the updated **PATH**, the list of folders searched for commands.

**macOS route (official SDK package):**
1. Check **Apple menu > About This Mac**. Apple M-series chips use Arm64; Intel uses x64. .NET 11 requires a supported macOS version (the official table currently includes macOS 15, 26 and 27).
2. Open the [macOS instructions](https://learn.microsoft.com/dotnet/core/install/macos), then the [.NET 11 download page](https://dotnet.microsoft.com/en-us/download/dotnet/11.0).
3. Under **SDK 11.0.100**, **macOS**, **Installers**, choose **Arm64 (Apple Silicon)** or **x64 (Intel)**. Open the downloaded .pkg.
4. In Installer choose **Continue**, follow the license prompts, **Agree**, then **Install**. Authorize installation when asked and choose **Close** when complete. Close Terminal and open a new one.

**Linux route (Ubuntu 26.04, Bash, per-user official install script):** Linux distributions differ, so this is one concrete route, not a claim that apt works everywhere. For another distribution, start at the hub's distribution page and install its listed dependencies before using the [official scripted-install instructions](https://learn.microsoft.com/dotnet/core/install/linux-scripted-manual). On Ubuntu 26.04, open Terminal and run the following from any folder. sudo requests your login password; typing it displays no characters.

**Folder: `~` (Ubuntu terminal only)**
```bash
sudo apt-get update
sudo apt-get install -y curl bash ca-certificates libbrotli1 libc6 libgcc-s1 libgssapi-krb5-2 libicu78 libssl3t64 libstdc++6 tzdata zlib1g
cd "$HOME"
curl -L https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh
bash dotnet-install.sh --version 11.0.100 --install-dir "$HOME/.dotnet"
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$DOTNET_ROOT:$PATH"
```
The first two commands install system dependencies; stop if they report a failure. curl downloads Microsoft's installer script; Bash runs that script. The SDK goes in .dotnet under your home folder, not in this course. The two exports make this terminal find that SDK. Installer/download progress depends on the system and network; the version check below is the success check. Close and reopen Terminal now, then **repeat the two export lines**: these environment settings last only for one terminal. Repeat them in every new Linux terminal when using this per-user route. You do not need to download the SDK again.

### Step 3. Check the SDK
From any folder, all three operating systems:

**Folder: `~` (terminal, all operating systems)**
```text
dotnet --version
dotnet --list-sdks
```
The author's actual version check:

**Captured version output**
```text
11.0.100
```
The author's actual installed-SDK listing (installation path varies by OS):

**Captured SDK listing**
```text
11.0.100 [C:\Program Files\dotnet\sdk]
```
Your version may be a newer 11.0.1xx patch; that is fine. If dotnet cannot be found, reopen the terminal (or repeat the Linux export lines) before reinstalling anything. If there are no SDKs, a runtime-only installation is not enough.

### Step 4. Install an editor
An **editor** is a program for editing plain-text code files. An **extension** is an add-on that gives the editor extra features. We use **Visual Studio Code (VS Code)**, which is not the larger Visual Studio product.
1. Open [code.visualstudio.com](https://code.visualstudio.com/) and choose the download for your OS. Windows: run the User Installer, accept the license and complete Next / Install / Finish with the default choices. macOS: open the downloaded archive and drag Visual Studio Code into Applications. Ubuntu: download the .deb, open it in your software installer and choose Install. Launch VS Code from the Start menu, Applications or app launcher.
2. No extension or account sign-in is required for this course: editing files and running terminal commands is enough. Optionally click **Extensions** (four squares), search **C#**, choose **C#** by **Microsoft** (not C# Dev Kit), then **Install** for language help.
3. **C# Dev Kit uses Visual Studio subscription sign-in and license checks; we do not use it in this course.** If prompted, dismiss it; do not create an account or pay to follow these lessons. The plain C# extension or no extension is our default. [Official VS Code guide](https://code.visualstudio.com/docs/csharp/get-started).

### Step 5. Make your lesson folder
Windows PowerShell (any current folder):
**Folder: `~` (terminal)**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101/csharp/lesson01" | Out-Null
Set-Location "$HOME/code101/csharp/lesson01"
```
macOS/Linux terminal (any current folder):
**Folder: `~` (terminal)**
```bash
mkdir -p "$HOME/code101/csharp/lesson01"
cd "$HOME/code101/csharp/lesson01"
```
Expected result: the terminal is now in `~/code101/csharp/lesson01`; these commands intentionally print no text. On Windows, `Out-Null` hides the new-folder listing. `-Force` / `-p` allow existing parent folders. Do not reuse a folder containing work you need to keep.

### Step 6. Open the folder and pin the SDK
In VS Code choose **File > Open Folder**, select `~/code101/csharp/lesson01` and click **Select Folder** / **Open**. If asked, trust only this folder you created yourself. A **JSON** file stores named settings using braces, colons and commas. In the Explorer pane choose **New File**, name it `global.json` (not global.json.txt), and enter the complete file below. On Windows turn on **File Explorer > View > Show > File name extensions** so you can check the ending. Save with Ctrl+S (Windows/Linux) or Command+S (macOS). A dot on a tab means it is not saved.

**File: `global.json`**
```json
{
  "sdk": {
    "version": "11.0.100",
    "rollForward": "latestPatch"
  }
}
```
An **SDK pin** selects the building tool. A **target framework**, written `net11.0` here, selects the .NET version the program uses. A **servicing patch** is an update within that release. In global.json, sdk groups the SDK settings, version selects the minimum version, and rollForward latestPatch permits later patches in that band, not .NET 12. Keep the quotes and commas.

### Step 7. Generate and run the first console project
Return to the terminal in `~/code101/csharp/lesson01`. The following command is identical in PowerShell, macOS Terminal and Linux Bash. `--name Lesson` names the project, `--output .` puts files in the current folder (the dot), `--framework net11.0` sets the target, and `--no-restore` postpones **restore**, preparation of the libraries and framework information the build needs. A **build** translates the source instructions into runnable files. We let dotnet run restore just once below.

Before this first project command, disable automatic web-development certificate setup **in this terminal only**. These text-only programs need no HTTPS certificate. Do not run any certificate trust command.

**Folder: `~/code101/csharp/lesson01` (Windows PowerShell)**
```powershell
$env:DOTNET_GENERATE_ASPNET_CERTIFICATE = "false"
```
**Folder: `~/code101/csharp/lesson01` (macOS/Linux Bash)**
```bash
export DOTNET_GENERATE_ASPNET_CERTIFICATE=false
```
These settings print no output and end when the terminal closes; they do not change user-level settings. If another SDK notice suggests trusting an HTTPS certificate, ignore it for this course.

**Folder: `~/code101/csharp/lesson01` (terminal)**
```powershell
dotnet new console --name Lesson --output . --framework net11.0 --no-restore
```
On a fresh .NET command-line home, this once-only welcome banner appears before the template result. Captured with certificate generation disabled as above and DOTNET_NOLOGO unset; later runs normally show only the template result. **Telemetry** means tool-usage data collection. To opt out, set `DOTNET_CLI_TELEMETRY_OPTOUT` to `1` in your terminal (PowerShell `$env:DOTNET_CLI_TELEMETRY_OPTOUT = "1"`; Bash `export DOTNET_CLI_TELEMETRY_OPTOUT=1`). That also hides the telemetry paragraph.

**Captured first-run output**
```text

Welcome to .NET 11.0!
---------------------
SDK Version: 11.0.100

Telemetry
---------
The .NET tools collect usage data in order to help us improve your experience. It is collected by Microsoft and shared with the community. You can opt-out of telemetry by setting the DOTNET_CLI_TELEMETRY_OPTOUT environment variable to '1' or 'true' using your favorite shell.

Read more about .NET CLI Tools telemetry: https://aka.ms/dotnet-cli-telemetry

----------------
Write your first app: https://aka.ms/dotnet-hello-world
Find out what's new: https://aka.ms/dotnet-whats-new
Explore documentation: https://aka.ms/dotnet-docs
Report issues and find source on GitHub: https://github.com/dotnet/core
Use 'dotnet --help' to see available commands or visit: https://aka.ms/dotnet-cli
--------------------------------------------------------------------------------------
The template "Console App" was created successfully.
```

A **type** names a kind of value or a set of operations. `Console` is a built-in type; its `WriteLine` **method** (named operation) prints text followed by a new line. A **string** is an ordered series, or **sequence**, of characters inside double quotes. Parentheses hold the text passed to the method, and `;` ends a **statement**, one instruction.

The command creates **exactly two source files** with --no-restore; global.json is the file you made yourself. Open both generated files in VS Code. Here they are in full:

**File: `Lesson.csproj` (generated)**
```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net11.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

</Project>
```

**File: `Program.cs` (generated)**
```csharp
Console.WriteLine("Hello, World!");
```

Lesson.csproj is the project manifest (build settings). Program.cs is the C# source file (instructions). Do not mix the file contents: .csproj contains **XML**, a settings format using named tags; Program.cs contains C# instructions. Run the generated program from the same folder:

**Folder: `~/code101/csharp/lesson01` (terminal)**
```powershell
dotnet run --project . --nologo
```
Captured output:
**Captured output**
```text
Hello, World!
```
dotnet run restores any needed SDK dependencies, builds, then runs the program. **Restore** prepares dependencies; **build** translates source. --project . selects the current project; --nologo hides the build logo, not your output. It does not create an editor window. The first restore may need internet.
The SDK also creates obj (intermediate build bookkeeping) and bin (compiled output). These are disposable generated folders, not files to type or copy into exercises. The source pack excludes them. The generated source files above are the ones you edit; no solution file, launch.json, tasks.json or package file is required.


Only these three files need your attention:

| File | Your action |
|---|---|
| `global.json` | Create the SDK pin once, then copy it unchanged. |
| `Lesson.csproj` | Keep the generated project settings; copy this file for later lessons. |
| `Program.cs` | Edit the program instructions. |

`bin/` and `obj/` are disposable build output; never type or copy their contents.

### Step 8. Read the project settings (no edits)
Keep the generated Lesson.csproj shown in Step 7. **Do not rewrite it**: the source pack contains this same complete file.

The **compiler** translates C# to runnable instructions. An **error** prevents a build; a **warning** lets it continue but flags something to check. The project file is **XML** (Extensible Markup Language): named tags structure settings, not C# instructions. A **project manifest** is the file describing how the source should be built.
| Setting | Meaning; what changing it does |
|---|---|
| Project Sdk="Microsoft.NET.Sdk" | Selects the standard .NET build rules; changing the SDK selects different rules. |
| PropertyGroup | Groups build settings; it is not part of the running program. |
| OutputType Exe | Builds a runnable application; Library would not be a console entry program. |
| TargetFramework net11.0 | Targets .NET 11; an older runtime cannot run it just because it has dotnet installed. |
| ImplicitUsings enable | Makes common names such as Console, List and File available without repeated using lines; disabling it requires explicit imports. |
| Nullable enable | Enables warnings about possibly missing reference values; disabling it hides useful warnings, not runtime risks. |

Closing XML tags end each setting/group/project. These projects require no external packages (separately supplied libraries). If only a later SDK feature band is installed, install the pinned band or deliberately update global.json after checking support; see Common mistakes.

### Step 9. Plan the instructions
Our instructions will do two jobs in order: print a greeting, then print a second sentence. You have already run the unmodified generated example; now replace its greeting with your own two instructions.

### Step 10. Write the complete program
Replace the generated Program.cs entirely. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
Console.WriteLine("Hello, C#!");
Console.WriteLine("I can run a program.");
```

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson01` (or `source/csharp/101-zero-to-hero/phase-1-foundations/01-hello-csharp/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson01"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson01"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson01` (terminal)**
```powershell
dotnet run --project . --nologo
```
No keyboard input is needed after starting this program.

Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
```text
Hello, C#!
I can run a program.
```


## How it works
1. `Console` is a built-in type offering terminal input and output. A **type** describes what a value is or what operations are available.
2. The dot selects a named operation. `WriteLine` is a **method**, a named operation; it prints text and moves to the next line. Capital letters matter: Console is not console.
3. Text in double quotes is a **string**, a sequence of characters. Parentheses surround the information passed to a method. The semicolon ends a **statement**, one instruction.
4. These are **top-level statements**: instructions written directly in Program.cs, without extra surrounding setup. The **compiler**, the translator from C# to runnable instructions, supplies the **entry point**, where execution begins.
5. The program runs top to bottom and ends after the second statement. `//` starts a **comment**, a note ignored by the compiler; the exercise uses one to mark your task.

## Try it
Print a fruit-bowl recipe card on three lines: the title, one apple, then one banana. Replace the TODO line with three WriteLine statements. Use only text and WriteLine; no input is needed.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-1-foundations/01-hello-csharp/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise01`**. Do not copy starter *into* an existing exercise01 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise01` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise01; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise01`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

**File: `~/code101/csharp/exercise01/Program.cs` (starter)**
```csharp
// TODO: print a recipe title, then its two ingredients.
Console.WriteLine("Recipe: TODO");
```

4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise01"`; macOS/Linux `cd "$HOME/code101/csharp/exercise01"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise01` (terminal)**
```powershell
dotnet run --project . --nologo
```
Unchanged starter output (before your work):

**Captured starter output**
```text
Recipe: TODO
```

<details><summary>Solution</summary>

Keep `global.json` and `Lesson.csproj` unchanged from lesson 01. Replace only the C# files shown below to compare.

**File: `~/code101/csharp/exercise01/Program.cs` (solution)**
```csharp
Console.WriteLine("Recipe: fruit bowl");
Console.WriteLine("1 apple");
Console.WriteLine("1 banana");
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
```text
Recipe: fruit bowl
1 apple
1 banana
```

The solution follows the task directly: compare each changed instruction with the rule in the task and trace its values from top to bottom. The unchanged setup is shared with the main example.

</details>

## Check yourself
1. What prints after the first WriteLine in the finished program, and why is it on a new line?
   <details><summary>Answer</summary>I can run a program. Each WriteLine ends its line before the next statement runs.</details>
2. How do SDK and runtime differ?
   <details><summary>Answer</summary>The SDK builds programs and includes the runtime; the runtime executes built programs.</details>
3. Why can Program.cs omit Main?
   <details><summary>Answer</summary>Top-level statements let the compiler supply the entry point.</details>
4. Does changing a file run it?
   <details><summary>Answer</summary>No. Save the file, then run dotnet run again.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `dotnet : The term 'dotnet' is not recognized as the name of a cmdlet, function, script file, or operable program.` | The new terminal cannot find dotnet on PATH. | Close and reopen PowerShell after SDK installation; check SDK, not only Runtime, was installed. |
| `A compatible .NET SDK was not found.` | global.json requests an uninstalled SDK band, reproduced with 11.0.200. | Run dotnet --list-sdks; restore the lesson pin 11.0.100 if a compatible 11.0.1xx SDK is installed, otherwise install that band. Do not delete the pin blindly. |
| `error CS1002: ; expected` | The last WriteLine lost its semicolon. | Restore the semicolon and save Program.cs. |
| `error CS0103: The name 'console' does not exist in the current context` | console was typed with a lowercase c. | Use Console with capital C; names are case-sensitive. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

The compatible-SDK failure also printed these lines (temporary path replaced):

**Captured SDK-pin diagnostic excerpt**
```text
      A compatible .NET SDK was not found.
Requested SDK version: 11.0.200
global.json file: <project>\global.json
Install the [11.0.200] .NET SDK or update [<project>\global.json] to match an installed SDK.
```

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

## Best practice
Install the SDK, not only a runtime, when writing programs. Keep supported servicing updates installed.
Source: Microsoft Learn, Install .NET on Windows, Linux, and macOS https://learn.microsoft.com/dotnet/core/install/

## Next lesson
**[02. Variables and types](02-variables-and-types.md)**: remember values instead of printing fixed text.
