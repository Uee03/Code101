# Go 101: Zero to Hero

For complete beginners from any field. Start at 01 and work in order.
Minimum Go 1.22.0; verified on Windows with Go 1.27.4. Standard library only.

Finished 101? Continue with [Go 201: Hero to Super Hero](201-hero-to-super-hero/README.md).

| Lesson | Read | Phase |
|---|---|---|
| 01 | [Hello, Go](101-zero-to-hero/phase-1-foundations/01-hello-go.md) | foundations |
| 02 | [Variables and types](101-zero-to-hero/phase-1-foundations/02-variables-and-types.md) | foundations |
| 03 | [Input and math](101-zero-to-hero/phase-1-foundations/03-input-and-math.md) | foundations |
| 04 | [Making decisions](101-zero-to-hero/phase-1-foundations/04-making-decisions.md) | foundations |
| 05 | [Loops](101-zero-to-hero/phase-2-building-blocks/05-loops.md) | building-blocks |
| 06 | [Functions](101-zero-to-hero/phase-2-building-blocks/06-functions.md) | building-blocks |
| 07 | [Slices and maps](101-zero-to-hero/phase-2-building-blocks/07-slices-and-maps.md) | building-blocks |
| 08 | [Files](101-zero-to-hero/phase-2-building-blocks/08-files.md) | building-blocks |
| 09 | [Errors](101-zero-to-hero/phase-3-real-programs/09-errors.md) | real-programs |
| 10 | [Structs and methods](101-zero-to-hero/phase-3-real-programs/10-structs-and-methods.md) | real-programs |
| 11 | [Interfaces and packages](101-zero-to-hero/phase-3-real-programs/11-interfaces-and-packages.md) | real-programs |
| 12 | [Project: expense tracker](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) | real-programs |

## How every lesson works

The source is optional: each lesson shows the code and starter, and later changes show the exact replacement region. Start with lesson 01 to install Go and VS Code; then follow the numbered lessons.

### Get the optional source

Open https://github.com/Uee03/Code101 and choose **Code > Download ZIP**. Or, if you already use Git, run `git clone https://github.com/Uee03/Code101.git` in a folder where you keep projects. Git is not needed for this course.

Extract the downloaded repository ZIP: **Windows**, right-click > **Extract All** > **Extract**; **macOS**, double-click; **Linux**, right-click > **Extract Here**, or run `unzip Code101-main.zip` in Downloads (use the actual downloaded filename if different). Open the extracted `Code101-main/source/go/101-zero-to-hero` folder to find `phase-1-foundations`, `phase-2-building-blocks`, and `phase-3-real-programs`. A cloned repository has the same `source/go/101-zero-to-hero` path. Each lesson's Before you start gives its full source path.

If an instructor gives you built phase ZIPs instead, extract them the same way. A phase ZIP extracts to `go-101-phase-1-foundations` (or its phase 2/3 name). **The all-level ZIP adds one level:** `go-101/go-101-phase-1-foundations/01-hello-go/code`, for example. Repository ZIPs use the `source/go/101-zero-to-hero/phase-1-foundations/...` layout instead; both contain the same lesson folders.

To run supplied code, in VS Code choose **File > Open Folder**, select the particular lesson's **code** folder, and choose **Select Folder** (Windows) or **Open** (macOS/Linux). Select **Terminal > New Terminal**, confirm its location with `Get-Location` (PowerShell) or `pwd` (macOS/Linux), then run `go run .` there. Do not initialize a supplied module again. Open only one lesson's folder, not the parent holding all modules.

### Working folder

Type your own finished example in a fresh folder outside the source download. These are exactly lesson 01's folder steps. Later lessons repeat them with every occurrence of `lesson01` replaced by the folder name explicitly listed in that lesson.

From any folder, **Windows PowerShell**:

**File: terminal (not a saved file)**
```powershell
New-Item -ItemType Directory -Force -Path "$HOME/code101/go/lesson01" | Out-Null
Set-Location "$HOME/code101/go/lesson01"
```

**macOS/Linux**:

**File: terminal (not a saved file)**
```bash
mkdir -p "$HOME/code101/go/lesson01"
cd "$HOME/code101/go/lesson01"
```

These commands create and select the folder without printing a result. `$HOME` means your personal folder. `Set-Location` is PowerShell's `cd`; `New-Item` creates the directory, `-Force` accepts an existing one, `-Path` supplies its location and `| Out-Null` hides the creation summary. `mkdir -p` creates a folder and any missing parents on macOS/Linux. Stop if a command reports an error.

In VS Code choose **File > Open Folder**, select that single lesson folder, then **Terminal > New Terminal**. The Explorer is the file list on the left. Hover over the folder name for **New File** (page with a plus) or **New Folder** (folder with a plus). Create each file with its shown relative path. Save with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS); a dot on a tab means unsaved. On Windows enable **File Explorer > View > Show > File name extensions** to avoid `main.go.txt`.

Check the folder with `Get-Location` (PowerShell) or `pwd` (macOS/Linux); the displayed path must end in your lesson folder. The prompt usually shows that folder before `>` or `$` (sometimes `%` on macOS). If you are elsewhere, use that lesson's recovery command. Do not put one module inside another. Trust only your own folders or source obtained from this repository at the VS Code workspace-trust prompt.

### Module file

Each typed example runs the shown `go mod init example.com/code101/lessonNN` command **once**, inside its own new folder. The `NN` is replaced by the exact number shown in the lesson; do not type NN literally. Its output confirms the module name. `go.mod` describes that module; a **module path** is the practice name on its first line, also used to locate local package imports in lesson 11. The generated `go` number reflects your Go installation; **leave it alone**. The supplied reference and starter use the same structure with minimum `go 1.22.0`, which also works on newer Go.

Only the module name changes between lessons. Do not rerun initialization or edit the go line when working from supplied files. There are no downloaded library dependencies.

### Exercise folders

The lesson shows the full starter files, so no download is necessary. To type them yourself, create its named `tryNN` folder next to `lessonNN`, open it alone in VS Code, and create the files at the relative paths shown. Create any subfolders first. Do not run `go mod init`: type the shown starter `go.mod` too.

If you have the source, **copy the `starter` folder and rename it `try01`** for lesson 01; substitute each later lesson's explicitly listed try name. In your file manager, select `exercise/starter`, copy it, go to `$HOME/code101/go`, paste it, then rename that copied folder. Do not create try01 and paste starter inside it. The try folder must directly contain `go.mod` and `main.go` and, where shown, the helper files or child package folder.

Open only the try folder in VS Code, select **Terminal > New Terminal**, make your changes, save and run `go run .` there. The lesson gives the exact output to aim for. Try before opening Solution. Solution blocks contain changed regions with surrounding lines to locate them; replace those regions, not the whole file, and leave all other files unchanged. Never combine starter and solution into one module: two main functions conflict.

The lessons use only Go's standard library. The project saves on `quit`, not on Ctrl+C; keep copies of any saved data you value.
