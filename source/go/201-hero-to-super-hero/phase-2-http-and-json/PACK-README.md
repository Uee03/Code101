# Go 201, Phase 2: HTTP and JSON

Source pack for lessons 05 to 07 of **Go 201 (Hero to Super Hero)**. Every file is also shown in the lessons, so the pack is optional. It is also in the repository https://github.com/Uee03/Code101 under `source/go/201-hero-to-super-hero/phase-2-http-and-json/` (**Code > Download ZIP**, or `git clone`).

| Folder | Lesson | You build / exercise |
|---|---|---|
| `05-net-http-server` | net/http server | a books API with routes and middleware / a `/hello` service with a `nosniff` middleware |
| `06-json-dtos-and-problems` | JSON DTOs, validation and problem+json | a safe `POST /books` with RFC 9457 errors / sign-up validation and strict decoding |
| `07-config-slog-shutdown` | Configuration, slog and graceful shutdown | environment config, structured logs, clean exit / `PORT` and `DEBUG` settings and a quiet logger |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | The finished program, its own module with `go.mod`, with tests. Lesson 06 also has `code/requests/` with sample request bodies |
| `exercise/starter/` | The exercise starting point, driven by tests; its own module (`try05`, `try06`, `try07`) |
| `exercise/solution/` | The complete answer; try the exercise first |
| `verify.json` | Maintainer file for automated checks; learners can ignore it |

## How to run

1. Install Go 1.22.0 or newer and `curl` (in Windows PowerShell type `curl.exe`).
2. Unzip the pack (Windows: right-click > **Extract All**; macOS: double-click; Linux: `unzip go-201-phase-2-http-and-json.zip`).
3. Open a terminal **in one lesson's `code` folder**, check with `pwd` (or `Get-Location`), and run:
   ```text
   go test ./...
   go run .
   ```
   The server listens on `http://127.0.0.1:8080`; stop it with Ctrl+C. Run only one server at a time (they share port 8080). Use a second terminal for `curl`, from the same `code` folder in lesson 06 (it reads `requests/*.json`). Lesson 07 reads `APP_*` environment variables; see the lesson.
4. For an exercise, copy `exercise/starter` to `try05`, `try06` or `try07`, open that folder and run `go test ./...`.

## Needs

Go 1.22.0 or newer and `curl`. Standard library only: no downloads.

## Status

Written by reading the code and the official documentation; **not yet run**. The lessons say so at the top. Level 201 continues with `phase-3-data-and-security`.
