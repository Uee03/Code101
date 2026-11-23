# Go 101, Phase 2: Building Blocks

Source pack for lessons 05 to 08 of **Go 101 (Zero to Hero)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-2-building-blocks/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons. Open one lesson code folder, not the parent containing all modules.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `05-loops` | Loops | loop forms / countdown |
| `06-functions` | Functions | rectangle and bill split / delivery charge |
| `07-slices-and-maps` | Slices and maps | shopping collections / repeated item total |
| `08-files` | Files | restricted CSV / third row |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | Finished source from the lesson; its own module with go.mod. |
| `exercise/starter/` | Runnable starting point with TODO markers; copy the whole folder. |
| `exercise/solution/` | Complete answer, also independently runnable. Try first. |
| `verify.json` | Maintainer smoke steps. Learners can ignore this file. |

## How to run any program

1. Install Go 1.22.0 or newer and VS Code with the Go extension (lesson 01).
2. Unzip `go-101-phase-2-building-blocks.zip`: Windows right-click > **Extract All** > **Extract**; macOS double-click; Linux run `unzip go-101-phase-2-building-blocks.zip` in the download folder or use **Extract Here** in your file manager. The archive contains the folder `go-101-phase-2-building-blocks`.
3. Open `go-101-phase-2-building-blocks/05-loops/code` using VS Code **File > Open Folder**. Select **Terminal > New Terminal**; confirm this code folder is current with `Get-Location` (PowerShell) or `pwd` (macOS/Linux).
4. Run `go run .` there on every OS. The dot means the current package. Do not run go mod init on supplied code: go.mod is included. No go test or go vet.

Example, starting in the extracted **go-101-phase-2-building-blocks** folder. Windows PowerShell:

```powershell
Set-Location "05-loops/code"
go run .
```
macOS/Linux:

```bash
cd "05-loops/code"
go run .
```

Allow 40 minutes for lesson 07 and 45 for lesson 08.
Lesson 08 creates/replaces shopping.csv in its working folder. It overwrites its
demo file on each run. Never store valued records in that demonstration file.

To do an exercise, copy the `starter` folder and rename it `try05` for lesson 05 (use the corresponding try name for later lessons). Put it alongside, not inside, the lesson module.
The try folder must directly contain `go.mod` and `main.go`, not another starter folder.
Without the pack, type the starter files shown in the lesson. Open the try folder alone
in VS Code, edit, save, and run `go run .` there. Do not merge starter and solution or
put two main functions together. The lesson shows the full files and input.

## Needs

Go 1.22.0 or newer. Standard library only; no downloads at run time, art or accounts.
Complete Phase 1 first; terms continue in lesson order.
Lesson text: tutorials/go/101-zero-to-hero/phase-2-building-blocks/ in the repository.
Smoke status: four lessons verified on Windows, Go 1.27.4 (2026-11-23).

Next: Phase 3, Real Programs.

Generated module versions may differ from the reference minimum `go 1.22.0`; leave them alone. A supplied module is ready to run. The all-level ZIP adds a `go-101/` parent above the phase-pack folders; repository ZIPs instead use the `source/go/101-zero-to-hero/` layout.
