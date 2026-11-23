# Go 201, Phase 4: Quality and Ship

Source pack for lesson 10 of **Go 201 (Hero to Super Hero)**. Every file is also shown in the lesson, so the pack is optional. It is also in the repository https://github.com/Uee03/Code101 under `source/go/201-hero-to-super-hero/phase-4-quality-and-ship/` (**Code > Download ZIP**, or `git clone`).

| Folder | Lesson | You build / exercise |
|---|---|---|
| `10-testing-and-notes-api` | Testing, and a mini project: the notes API in a container | a tested notes API, a multi-stage non-root `Dockerfile`, `docker-compose.yml` / table-driven tests for a `slug.Make` function, a bug fix and a fuzz test |

## Inside the lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | The finished notes API: Go files with tests, `Dockerfile`, `.dockerignore`, `docker-compose.yml`, `requests/*.json` |
| `exercise/starter/` | A small separate package (`slug`) with an unfinished test table and a bug; its own module `try10` |
| `exercise/solution/` | The fixed code and the full test table, plus a fuzz test |
| `verify.json` | Maintainer file for automated checks; learners can ignore it |

## How to run

1. Install Go 1.22.0 or newer, `curl` (in Windows PowerShell type `curl.exe`) and, for the container steps, Docker with Compose v2 (engine running).
2. Unzip the pack and open a terminal in `10-testing-and-notes-api/code`. There are no dependencies and no `go.sum`.
3. On the host:
   ```text
   go vet ./...
   go test ./...
   go run .
   ```
4. In a container (port 8080 free):
   ```text
   docker compose up -d --build --wait
   docker compose down --rmi local
   ```
5. For the exercise, copy `exercise/starter` to a folder named `try10`, open it and run `go test ./...`.

## Needs

Go 1.22.0 or newer; Docker with Compose v2 for the container part. The first image build downloads two base images (`golang:1.27.4-alpine3.24` and `gcr.io/distroless/static-debian13:nonroot`).

## Status

Written by reading the code and the official documentation; **not yet run**. The lesson says so at the top. This is the last pack of level 201; the capstone [`capstones/backend-go`](https://github.com/Uee03/Code101/tree/main/capstones/backend-go) shows the full production version.
