# Go 301, Phase 3: Production

Source pack for lessons 07 to 09 of **Go 301 (Super Hero to Legendary)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/go/301-super-hero-to-legendary/phase-3-production/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons. Open **one** lesson `code` folder at a time.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `07-observability` | Observability | `slog` JSON logs with trace IDs, Prometheus metrics on an admin port, OpenTelemetry traces, Dockerfile, Compose with Prometheus / a self-redacting `Token` |
| `08-security-and-supply-chain` | Security and supply chain | strict decoding and validation, secrets, Ed25519 JWTs with `kid`, mutual TLS, `govulncheck` / harden a JWT verifier |
| `09-release-engineering` | Release engineering and the production checklist | version stamping, reproducible builds, multi-stage distroless image, Compose hardening, SBOM and multi-arch recipe, the checklist / **review** a flawed service |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | Finished source from the lesson; its own module with `go.mod` (and Docker files where the lesson uses them). |
| `exercise/starter/` | Starting point (lesson 09: a flawed `service/` folder to review). |
| `exercise/solution/` | Answer (lesson 09: `REVIEW.md` and a fixed `main.go`). Try the exercise first. |
| `verify.json` | Maintainer check steps. Learners can ignore this file. |

## How to run

1. Go **1.26.0 or newer**.
2. Lessons 07 and 08: run `go mod tidy` once (downloads dependencies, creates `go.sum`, which is not shipped), then `go test ./...` and `go run .`.
3. Lesson 07 and 09 containers: Docker with Compose v2 (lesson 09 also Buildx). In lesson 07 run `go mod tidy` **before** `docker compose up --build`, because the Dockerfile copies `go.sum`. Copy `.env.example` to `.env`; never commit `.env`.
4. Lesson 09 needs no `go.sum` (no dependencies). SBOM, signing and multi-architecture push commands are a recipe: they need tools and a registry you provide.
5. Exercises: copy `starter` and rename the copy `try07`, `try08`, `try09`.

## Needs

Go 1.26.0 or newer; Docker with Compose v2 for the container parts; internet access for `go mod tidy` and image pulls (`golang:1.27.4-alpine`, `gcr.io/distroless/static-debian13:nonroot`, `prom/prometheus:v3.16.0`).
Lesson text: `tutorials/go/301-super-hero-to-legendary/phase-3-production/` in the repository.
Status: all three lessons are **written (not run)**. Go 301 is complete after this phase.
