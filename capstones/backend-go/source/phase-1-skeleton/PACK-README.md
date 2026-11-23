# Backend Go, phase 1: Skeleton

A Go service that starts, shuts down gracefully, answers `GET /health` and a stubbed `GET /v1/me`, validates `POST /v1/teams` and answers every error as RFC 9457 problem details. No database yet. Status: **verified** on 2026-11-23 (Windows 11, Go 1.27.4, curl 8.22.0). Conformance with the platform stack running: 6 passed, 12 failed (the four infrastructure checks, `health` and `problem details shape`).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `01-skeleton` | The skeleton | config, problem details, validation, middleware, router, graceful shutdown |

## Prerequisites and extraction
- Go 1.27 and `curl` (Windows PowerShell: `curl.exe`). Port 8000 free. Docker is not needed in this phase.
- Extract the zip (Windows: right-click, Extract All; macOS: double-click; Linux: `unzip backend-go-phase-1-skeleton.zip`) and open `01-skeleton/code`.

## Run
**Terminal (folder `01-skeleton/code`)**
```bash
go run ./cmd/api
```
In a second terminal: `curl -s http://127.0.0.1:8000/health` prints `{"status":"ok","version":"1.0.0"}`. Stop with Ctrl+C.

## Exercise
Copy `01-skeleton/exercise/starter` to your own folder, run `go mod init exercise`, implement `validateProjectKey` and run `go run .`. The solution is in `exercise/solution`.

## For maintainers
`verify.json` builds the code, starts it in the background, probes five URLs and runs the exercise solution. It takes the exclusive lock `tasksteams` because the API uses port 8000. Every file of `code/` is in the lesson text (no skips).
