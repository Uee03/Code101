# Go 101, Phase 1: Foundations

Source pack for lessons 01 to 04 of **Go 101 (Zero to Hero)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-1-foundations/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons. Open one lesson code folder, not the parent containing all modules.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `01-hello-go` | Hello, Go | greeting / recipe card |
| `02-variables-and-types` | Variables and types | inventory / stock update |
| `03-input-and-math` | Input and math | tip calculator / service charge |
| `04-making-decisions` | Making decisions | ticket rules / grade checker |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | Finished source from the lesson; its own module with go.mod. |
| `exercise/starter/` | Runnable starting point with TODO markers; copy the whole folder. |
| `exercise/solution/` | Complete answer, also independently runnable. Try first. |
| `verify.json` | Maintainer smoke steps. Learners can ignore this file. |

## How to run any program

1. Install Go 1.22.0 or newer and VS Code with the Go extension (lesson 01).
2. Unzip `go-101-phase-1-foundations.zip`: Windows right-click > **Extract All** > **Extract**; macOS double-click; Linux run `unzip go-101-phase-1-foundations.zip` in the download folder or use **Extract Here** in your file manager. The archive contains the folder `go-101-phase-1-foundations`.
3. Open `go-101-phase-1-foundations/01-hello-go/code` using VS Code **File > Open Folder**. Select **Terminal > New Terminal**; confirm this code folder is current with `Get-Location` (PowerShell) or `pwd` (macOS/Linux).
4. Run `go run .` there on every OS. The dot means the current package. Do not run go mod init on supplied code: go.mod is included. No go test or go vet.

Example, starting in the extracted **go-101-phase-1-foundations** folder. Windows PowerShell:

```powershell
Set-Location "01-hello-go/code"
go run .
```
macOS/Linux:

```bash
cd "01-hello-go/code"
go run .
```

Allow 60 minutes each for lessons 01 and 03; lesson 03's extra Scan comparison is optional.
Lesson 03 calculator: at its three prompts enter 80, 15, 2 on separate lines.
Its optional separate token demo runs from the same code root with `go run ./scan-demo`,
then enter 2. It is in the same module, not mixed into the main input reader.

To do an exercise, copy the `starter` folder and rename it `try01` for lesson 01 (use the corresponding try name for later lessons). Put it alongside, not inside, the lesson module.
The try folder must directly contain `go.mod` and `main.go`, not another starter folder.
Without the pack, type the starter files shown in the lesson. Open the try folder alone
in VS Code, edit, save, and run `go run .` there. Do not merge starter and solution or
put two main functions together. The lesson shows the full files and input.

## Needs

Go 1.22.0 or newer. Standard library only; no downloads at run time, art or accounts.
No prior programming knowledge. Allow extra time for setup in lesson 01.
Lesson text: tutorials/go/101-zero-to-hero/phase-1-foundations/ in the repository.
Smoke status: four lessons verified on Windows, Go 1.27.4 (2026-11-23).

Next: Phase 2, Building Blocks.

Generated module versions may differ from the reference minimum `go 1.22.0`; leave them alone. A supplied module is ready to run. The all-level ZIP adds a `go-101/` parent above the phase-pack folders; repository ZIPs instead use the `source/go/101-zero-to-hero/` layout.
