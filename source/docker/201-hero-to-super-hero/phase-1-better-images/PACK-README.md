# Docker 201, Phase 1: Better images

Source pack for lessons 01 to 04 of **Docker 201 (Hero to Super Hero)**. You need Docker 101 first.

> **Status: written but not yet run.** The code in this pack was prepared by reading it and the official documentation. It has not been executed yet. If something does not behave as described, trust your tool's real output and report it.

| Folder | What you build |
|---|---|
| `01-multi-stage-builds` | A Go server and a Node app, each with a multi-stage Dockerfile; compare with a single-stage image |
| `02-build-cache-and-buildkit` | A slow and a fast Dockerfile, a cache mount and a tuned `.dockerignore` |
| `03-non-root-and-hardening` | A non-root, read-only, capability-free container, in `docker run` and Compose |
| `04-scanning-and-supply-chain` | OCI labels, base-image pinning, Docker Scout and Trivy commands, SBOM and provenance |

## Inside each lesson folder
- `code/`: the finished files, identical to the lesson text.
- `exercise/starter/`: where the Try it exercise begins (often only the files that change; copy the rest from `code/`).
- `exercise/solution/`: the answer. Try first, then compare.
- `verify.json`: a machine-readable list of the lesson's steps (used to check the lesson later).

## Unzip and run
1. Docker 29.9.3 (or newer) must be running: `docker info` shows a Server section.
2. Windows: right-click the zip, **Extract All**. macOS: double-click. Linux: `unzip <pack>.zip`.
3. Open a terminal **inside the lesson's `code` folder** (or the sub-folder the lesson names, such as `go-app`). PowerShell on Windows; Terminal on macOS/Linux.
4. Follow the lesson's **Run it** commands in order. Windows uses `curl.exe`; macOS/Linux use `curl`. Ubuntu Engine users prefix Docker commands with `sudo`.
5. Lessons that publish a port use `127.0.0.1:8080`. Stop one lesson's containers before starting the next.
6. Exercises: copy the lesson folder to a folder named `practice`, apply the starter files, work there, never in the pack originals.

## Safety
No real secrets are in this pack. Scanner output depends on today's databases, so the lessons describe what to look for instead of showing results. Clean up with the exact `docker image rm` commands in each lesson; do not use a global prune to remove one lesson's resources.

Unity is never in Docker.
