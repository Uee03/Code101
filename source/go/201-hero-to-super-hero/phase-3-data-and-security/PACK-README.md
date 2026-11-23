# Go 201, Phase 3: Data and Security

Source pack for lessons 08 and 09 of **Go 201 (Hero to Super Hero)**. Every file is also shown in the lessons, so the pack is optional. It is also in the repository https://github.com/Uee03/Code101 under `source/go/201-hero-to-super-hero/phase-3-data-and-security/` (**Code > Download ZIP**, or `git clone`).

| Folder | Lesson | You build / exercise |
|---|---|---|
| `08-postgres-with-pgx` | Postgres with pgx | Postgres 17 in Compose, a pool, a transaction, a stored function / a `Withdraw` function and method |
| `09-auth-middleware-jwt` | Authentication middleware (JWT basics) | token minting and verification, bearer middleware, role checks / `RequireAnyRole` and `RequireSelfOrRole` |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | The finished program, its own module. Lesson 08 also has `docker-compose.yml`, `.env.example`, `.gitignore` and `db/01-schema.sql` |
| `exercise/starter/` | **Files to add** to a copy of your finished lesson folder (not a standalone program): see the lesson's "Try it" |
| `exercise/solution/` | The same files, completed |
| `verify.json` | Maintainer file for automated checks; learners can ignore it |

## `go.sum` is not included

These modules use libraries (`pgx` in lesson 08, `golang-jwt` in lesson 09). `go.mod` pins their versions. **In the lesson folder run `go mod tidy` once**: it downloads the libraries and creates `go.sum`. This needs internet access.

## How to run

1. Install Go 1.22.0 or newer, `curl` (in Windows PowerShell type `curl.exe`) and, for lesson 08, Docker with Compose v2 (the Docker engine must be running).
2. Unzip the pack and open a terminal **in one lesson's `code` folder**.
3. Lesson 08:
   ```text
   cp .env.example .env          (PowerShell: Copy-Item .env.example .env)
   docker compose up -d --wait
   go mod tidy
   ```
   Set `DATABASE_URL` as the lesson shows, then `go run .` and `go test ./...`. Stop with `docker compose down` (add `-v` to delete the data).
4. Lesson 09: set `AUTH_SECRET` (at least 32 characters; the lesson gives a development value), then `go mod tidy`, `go test ./...` and `go run .`.

## Needs

Go 1.22.0 or newer; internet access for `go mod tidy`; Docker with Compose v2 and port 5433 free for lesson 08. The passwords and secrets in this pack are for disposable local use only.

## Status

Written by reading the code and the official documentation; **not yet run**. The lessons say so at the top. Level 201 ends with `phase-4-quality-and-ship`.
