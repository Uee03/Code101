---
track: go
level: 101
phase: 1
phase_name: foundations
lesson: 01
title: "Hello, Go"
time: 60 min
prerequisites: [none]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-1-foundations/01-hello-go/
assets: []
---

# 01. Hello, Go

## Why it matters
A recipe turns written instructions into something you can make. A program does the same for a computer: you write instructions, and Go translates them into work the computer can perform. You do not need a technical background to start.

## What you will build
A two-line greeting and a recipe card. Install the tools, create a module, save a file and run it.

## Before you start
- No programming experience needed. Allow an hour for setup. Internet is needed for installers, not for running these examples.
- Time: 60 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-1-foundations/01-hello-go/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Open a terminal
A **terminal** is a window where you type commands and press Enter. The **prompt** is text before your typing area; do not type its > or $ sign. The **current folder** is where commands operate. Windows usually shows it before >; macOS/Linux often show it before $ or %.

- **Windows:** click Start, type **Windows PowerShell**, open it. Use PowerShell for the Windows instructions, not the older Command Prompt.
- **macOS:** open Finder > Applications > Utilities > **Terminal**.
- **Linux (Ubuntu):** press Ctrl+Alt+T, or open **Terminal** from Applications.

In any folder, check where you are. Windows PowerShell:

**File: terminal (not a saved file)**
```powershell
Get-Location
```
macOS/Linux:

**File: terminal (not a saved file)**
```bash
pwd
```
The result is your current folder's path, not the author's path. A **path** locates a file or folder; quote paths with spaces. `cd` changes the current folder. `Set-Location` is PowerShell's `cd`; `Get-Location` shows that folder. `$HOME` means your personal folder, for example `C:\Users\Sam`. Your **home folder** is this personal folder. In Step 4, `New-Item` creates a directory (`-ItemType Directory`), `-Force` accepts an existing folder, `-Path` supplies its location, and `| Out-Null` hides the creation summary. On macOS/Linux, `mkdir -p` creates a folder and any missing parent folders.

### Step 2. Install Go for your OS
Open https://go.dev/doc/install in your browser. Your **operating system (OS)** is Windows, macOS or Linux. Choose its tab, click **Download**, and use the official downloads. You need **Go 1.22.0 or newer**. The filenames below select **1.27.4**, matching the author; you may choose the newest stable version instead. If not featured, find that release at https://go.dev/dl/. When choosing a newer release, substitute its filename in the Linux commands too.

**Processor architecture** means the kind of processor instructions your computer uses. Choose **amd64** for Intel/AMD 64-bit computers, **arm64** for ARM 64-bit computers. macOS: Apple menu > About This Mac shows an Apple chip or Intel processor. Windows: Settings > System > About shows processor and system type. Linux: in any folder run the command below; x86_64 means amd64 and aarch64 means arm64. Follow only your OS branch.

**File: terminal (not a saved file), Linux only**
```bash
uname -m
```
**Windows**
1. Download `go1.27.4.windows-amd64.msi` (ARM: `go1.27.4.windows-arm64.msi`).
2. Open the MSI. Click **Next**, accept the license, click **Next**, keep the default location, **Next**, **Install**, approve the permission prompt if asked, then **Finish**.
3. Close PowerShell and open a new Windows PowerShell window. The installer changes **PATH**, the list of folders searched for commands; old terminals may not see it.

**macOS**
1. Download `go1.27.4.darwin-arm64.pkg` for Apple chips or `go1.27.4.darwin-amd64.pkg` for Intel.
2. Open the PKG, click **Continue**, follow the license prompts, click **Install**, approve the password/Touch ID prompt, then **Close** when done.
3. It installs under /usr/local/go and adds its bin folder to PATH. Close Terminal and open a new Terminal window.

**Linux (official archive route)**
1. Download `go1.27.4.linux-amd64.tar.gz` into Downloads (ARM: `go1.27.4.linux-arm64.tar.gz`). A **compressed archive** bundles files for extraction.
2. Run these commands one at a time. They move to Downloads, confirm the archive exists, then replace the old Go installation, not your projects. **Stop if `cd` fails or `ls` does not list the exact archive**. `rm -rf /usr/local/go` permanently deletes the old Go installation folder and everything in it; it does not delete your lesson folders. sudo asks for administrator permission; passwords may show no characters while typing. Do not extract over an old Go tree.

**File: terminal (not a saved file), Linux amd64**
```bash
cd "$HOME/Downloads"
ls go1.27.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.27.4.linux-amd64.tar.gz
export PATH="$PATH:/usr/local/go/bin"
```
ARM: repeat those exact five commands, changing the filename in **both** `ls` and `tar` to `go1.27.4.linux-arm64.tar.gz`. The `ls` command must list that file before you continue.
3. Persist PATH: in your home file-manager folder show hidden files (Ctrl+H on Ubuntu), open .profile in the text editor, append the line below on its own line and save. If absent, create .profile with that line. Do not replace existing contents.

**File: `~/.profile` (line to append to your existing file)**
```bash
export PATH="$PATH:/usr/local/go/bin"
```
4. Log out and back in to apply the profile, then open a new terminal. Alternatively, in the current Linux terminal run `source "$HOME/.profile"` to apply its saved lines immediately. The export above already enables Go in the current terminal. Source and alternatives: https://go.dev/doc/install.

**All OSes**, in any folder run:

**File: terminal (not a saved file)**
```text
go version
```
Actual author-machine output:

**File: `terminal output (not a saved file)`**
```text
go version go1.27.4 windows/amd64
```

Your release and OS/processor suffix can differ. Confirm at least 1.22.0; a Mac/Linux computer will not show the Windows suffix.

### Step 3. Install VS Code and the Go extension
An **editor** helps you write and save source files. Open https://code.visualstudio.com/download and follow your branch:

- **Windows:** choose **User Installer** for your processor. Open the .exe, accept the agreement, keep defaults, click **Next** through the pages, then **Install** and **Finish**. Open **Visual Studio Code** from Start.
- **macOS:** download the Mac build, open its zip, drag **Visual Studio Code.app** to Applications, then open it there. Approve **Open** if asked.
- **Linux (Ubuntu/Debian):** download the .deb for your processor. Keep the downloaded filename in Downloads. In your file manager, click it and press F2 then Ctrl+C to copy its exact name, then Escape to cancel renaming. Replace `<downloaded name>.deb` below with that full name (do not type the angle brackets). In Terminal run the commands below, approve package-manager prompts, then open **Visual Studio Code** in Applications. Other distributions: choose your matching official route at https://code.visualstudio.com/docs/setup/linux instead of this Debian command.

**File: terminal (not a saved file), Ubuntu/Debian only**
```bash
cd "$HOME/Downloads"
sudo apt install "./<downloaded name>.deb"
```
In VS Code click the Extensions icon (four small squares) in the left sidebar. Search **Go**, select the **Go** extension from **Go Team at Google** (identifier golang.go), then click **Install**. After opening a `.go` file, a notification may offer missing editing tools such as `gopls` (Go's code-completion helper). Click **Install All** if offered and wait; downloads can take several minutes. These optional tools are separate from running the program. If the prompt reports Go is missing, close and reopen VS Code after confirming `go version` in a new terminal. The example itself needs only Go. No account, AI tools or extra settings are required.

On macOS/Linux, editing tools normally go in `$HOME/go/bin`. If VS Code cannot find installed tools, follow the official [Go installation](https://go.dev/doc/install) tools-PATH note; the course programs do not need them.

Close and reopen VS Code if it was open during tool installation so it sees PATH. Use **File > Open Folder** below, not a code command that may not be on PATH. Sources: https://code.visualstudio.com/docs/getstarted/overview and https://code.visualstudio.com/docs/languages/go.

### Step 4. Create a separate working folder
Do not put this module inside a previous lesson's module. From any folder, Windows PowerShell:

**File: terminal (not a saved file)**
```powershell
New-Item -ItemType Directory -Force -Path "$HOME/code101/go/lesson01" | Out-Null
Set-Location "$HOME/code101/go/lesson01"
```
macOS/Linux:

**File: terminal (not a saved file)**
```bash
mkdir -p "$HOME/code101/go/lesson01"
cd "$HOME/code101/go/lesson01"
```
These create and select your working folder. In VS Code choose **File > Open Folder**, navigate to `lesson01` under your home folder's `code101/go`, then **Select Folder** (Windows) or **Open** (macOS/Linux). The **Explorer** is VS Code's file list on the left; hover over the folder name to see the **New File** (page with a plus) and **New Folder** (folder with a plus) icons. Always open the single lesson folder, not `code101/go`. If VS Code asks **Do you trust the authors of the files in this folder?**, choose **Yes, I trust the authors** only for your own folder or this course's source. On Windows, enable **File Explorer > View > Show > File name extensions** so `main.go.txt` cannot hide as `main.go`.

Choose **Terminal > New Terminal**. It should start in the open folder. To recover, run `Set-Location "$HOME/code101/go/lesson01"` in PowerShell or `cd "$HOME/code101/go/lesson01"` on macOS/Linux. Get-Location (PowerShell) or pwd (macOS/Linux) confirms it. Commands below run here unless stated otherwise.

### Step 5. Create and inspect the module
In `lesson01`, on every OS run:

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson01
```
Go creates go.mod. Do this once in a fresh folder. If you copied the pack's code, go.mod exists: skip only init and inspect that file instead.

Actual initialization output:

**File: `terminal output (not a saved file)`**
```text
go: creating new go.mod: module example.com/code101/lesson01
```

In the Explorer click `go.mod`. Your generated file may show a different `go` number; **leave it alone**. On the author's toolchain it contains:

**File: `go.mod` (generated example)**
```text
module example.com/code101/lesson01

go 1.27.4
```

A **module** groups packages (Go files compiled together) under a **module path**, its practice name in `go.mod`. This path is not a website you must create. The `go` line gives the minimum Go version. The supplied reference and starter use `go 1.22.0`; your newer generated number works too. Nothing needs editing or downgrading.

### Step 6. Write the complete program
A source file is a text file containing program instructions; Go filenames end in .go.

In the Explorer select the root `lesson01` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import "fmt"

func main() {
	fmt.Println("Hello, Go!")
	fmt.Println("I can write a program.")
}
```

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

## Run it
Inside your own lesson01 folder (or the pack's 01-hello-go/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
Hello, Go!
I can write a program.
```

## How it works
1. `package main` groups this file into the runnable **package**, a collection of Go files in one folder. A runnable program uses the package name main.
2. An **import** brings another package's tools into a file. `import "fmt"` makes formatting functions available. The **standard library** is the collection of packages supplied with Go; no extra downloads are needed here.
3. `func main()` defines the starting **function**, a named group of instructions. Parentheses hold inputs; main takes none. Go calls main when your program starts.
4. Braces surround a **block**, the instructions belonging to this function. **Indentation** is the leading whitespace that makes it easier to read.
5. `fmt.Println(...)` is a **call**, an instruction to run a function. A **string** is text between double quotes. Println prints it and moves to a new line. Capital letters matter.
6. `go run .` compiles and runs this folder's package. A **compiler** checks and translates source code; the **toolchain** is the set of Go tools doing this work.

A **module** groups packages under a name in go.mod. example.com/code101/lesson01 is a practice name, not a website you must create. This program has no downloaded **dependencies** (other people's modules).

## Try it
Recipe card: replace the TODO output with three Println calls. Print Recipe: tea, then 1. Heat water., then 2. Add tea and water to a cup. Use the greeting as a guide to quotes and parentheses.

If using the optional source, find `01-hello-go/exercise/starter`, then copy the `starter` folder and rename it `try01` alongside `lesson01` in `$HOME/code101/go`. `try01` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try01` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try01` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try01"`; macOS/Linux `cd "$HOME/code101/go/try01"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson01

go 1.22.0
```

**File: `main.go (starter)`**
```go
package main

import "fmt"

func main() {
	// TODO: replace these lines with three recipe steps.
	fmt.Println("Recipe: TODO")
}
```

In `try01` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
Recipe: tea
1. Heat water.
2. Add tea and water to a cup.
```

<details><summary>Solution</summary>

In `try01`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 3-9)**
```go
import "fmt"

func main() {
	fmt.Println("Recipe: tea")
	fmt.Println("1. Heat water.")
	fmt.Println("2. Add tea and water to a cup.")
}
```

</details>

## Check yourself
1. Which file contains instructions?
   <details><summary>Answer</summary>main.go; go.mod describes the module.</details>
2. Why capitalize Println?
   <details><summary>Answer</summary>Names are case-sensitive; fmt exports Println with that spelling.</details>
3. What does the dot in go run . mean?
   <details><summary>Answer</summary>The current folder.</details>

## Common mistakes
These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson01` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 4 to return to the folder holding `go.mod`. For an exercise, return to its `try01` folder. |
| `.\main.go:6:6: undefined: fmt.println (but have Println)` | Changed `Println` to `println` | Use the exact capital P: `fmt.Println`. |
| `.\main.go:8:1: syntax error: unexpected EOF, expected }` | Deleted the closing brace of main | Restore the final `}` on its own line. |
| `go: cannot determine module path for source directory <project> (outside GOPATH, module path must be specified)` | Left the module name off go mod init | In `lesson01`, run the whole command: `go mod init example.com/code101/lesson01`. GOPATH is Go's tools/work folder; you do not need to change it. |

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Keep a new program in its own module folder so its files and dependencies stay together. Source: Go: Create a module https://go.dev/doc/tutorial/create-module

## Next lesson
**[02. Variables and types](02-variables-and-types.md):** remember facts with variables and types.
