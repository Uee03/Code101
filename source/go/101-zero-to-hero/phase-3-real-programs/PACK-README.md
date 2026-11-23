# Go 101, Phase 3: Real Programs

Source pack for lessons 09 to 12 of **Go 101 (Zero to Hero)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-3-real-programs/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons. Open one lesson code folder, not the parent containing all modules.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `09-errors` | Errors | amount retry loop / minimum amount |
| `10-structs-and-methods` | Structs and methods | expense record / discount method |
| `11-interfaces-and-packages` | Interfaces and packages | receipt package / second reporter |
| `12-expense-tracker` | Project: expense tracker | CSV expense tracker / count command |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | Finished source from the lesson; its own module with go.mod. |
| `exercise/starter/` | Runnable starting point with TODO markers; copy the whole folder. |
| `exercise/solution/` | Complete answer, also independently runnable. Try first. |
| `verify.json` | Maintainer smoke steps. Learners can ignore this file. |

## How to run any program

1. Install Go 1.22.0 or newer and VS Code with the Go extension (lesson 01).
2. Unzip `go-101-phase-3-real-programs.zip`: Windows right-click > **Extract All** > **Extract**; macOS double-click; Linux run `unzip go-101-phase-3-real-programs.zip` in the download folder or use **Extract Here** in your file manager. The archive contains the folder `go-101-phase-3-real-programs`.
3. Open `go-101-phase-3-real-programs/09-errors/code` using VS Code **File > Open Folder**. Select **Terminal > New Terminal**; confirm this code folder is current with `Get-Location` (PowerShell) or `pwd` (macOS/Linux).
4. Run `go run .` there on every OS. The dot means the current package. Do not run go mod init on supplied code: go.mod is included. No go test or go vet.

Example, starting in the extracted **go-101-phase-3-real-programs** folder. Windows PowerShell:

```powershell
Set-Location "09-errors/code"
go run .
```
macOS/Linux:

```bash
cd "09-errors/code"
go run .
```

Lesson 09: at consecutive prompts enter tea, 0, 12, each followed by Enter.
Lesson 12: start without expenses.csv for the sample, then enter add, Coffee, 350,
list, total, quit, each on its own line. Only quit saves; later runs load saved
entries. Preserve an existing CSV before repeating the first-run demonstration.
The tiny self-check uses plain checks. Allow 90 minutes in two sittings for lesson 12; break after Step 4, once expense.go and check.go are saved. Lesson 10 allows 50 minutes, with receiver mechanics optional.

To do an exercise, copy the `starter` folder and rename it `try09` for lesson 09 (use the corresponding try name for later lessons). Put it alongside, not inside, the lesson module.
The try folder must directly contain `go.mod` and `main.go`, not another starter folder.
Without the pack, type the starter files shown in the lesson. Open the try folder alone
in VS Code, edit, save, and run `go run .` there. Do not merge starter and solution or
put two main functions together. The lesson shows the full files and input.

## Needs

Go 1.22.0 or newer. Standard library only; no downloads at run time, art or accounts.
Complete Phase 2 first; terms continue in lesson order.
Lesson text: tutorials/go/101-zero-to-hero/phase-3-real-programs/ in the repository.
Smoke status: four lessons verified on Windows, Go 1.27.4 (2026-11-23).

101 complete. The all-level archive contains all three phase folders.

Generated module versions may differ from the reference minimum `go 1.22.0`; leave them alone. A supplied module is ready to run. The all-level ZIP adds a `go-101/` parent above the phase-pack folders; repository ZIPs instead use the `source/go/101-zero-to-hero/` layout.
