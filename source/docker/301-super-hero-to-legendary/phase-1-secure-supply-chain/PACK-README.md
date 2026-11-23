# Docker 301, Phase 1: Secure supply chain

Source pack for lessons 01 to 03 of **Docker 301 (Super Hero to Legendary)**. Status: **written (not run)**.

| Folder | What you build |
|---|---|
| `01-threat-model-for-containers` | A threat model, an unsafe and a reviewed Compose file, and a line-based Compose audit script |
| `02-image-provenance-sbom-and-signing` | A digest-pinned build, a base-image policy check, an SBOM query tool and the signing concepts |
| `03-runtime-hardening` | A baseline and a hardened container that report their own privileges, a seccomp profile, an AppArmor profile and a `userns-remap` example |

## Inside each lesson
- `code/`: finished files, identical to the lesson text.
- `exercise/starter/`: where the Try it exercise begins.
- `exercise/solution/`: the answer. Try first, then compare.
- `verify.json`: maintainer specification for a later verification run. The lessons were **not executed** when they were written.

## Unzip and run
1. Windows: right-click the zip > **Extract All**; macOS: double-click; Linux: `unzip <pack>.zip`.
2. Open a terminal in the lesson's `code` folder (Windows: PowerShell; macOS/Linux: Terminal). Do not run from the phase root.
3. Follow the lesson's Steps in order. Lessons 01 and 02 need Python 3.13 (or the container route shown in lesson 01). Lessons 02 and 03 need Docker running.
4. Exercises: copy the starter files into your own `exercise` folder as the lesson says; keep the finished solution closed until you have tried.

## Ports and safety
- Only lesson 03 publishes a port: `127.0.0.1:8090`. Run one lab at a time.
- `docker-compose.insecure.yml` in lesson 01 is a **teaching example that must never be run**: it is privileged and mounts the Docker socket. It is only audited as text.
- Lesson 03's AppArmor, `userns-remap` and rootless steps are for Linux hosts and change host state. They are described, not scripted; read the warnings in the lesson first.
- All passwords, tokens and digests in this pack are public demonstration values or all-zero placeholders, never real credentials or real images.

## Cleanup
Lesson 03: `docker compose -f <file> down` and `docker image rm code101/hardening-demo:1.0.0`. Lesson 02: `docker image rm code101/provenance-demo:1.0.0`, and remove the `code101-builder` builder if you created it (`docker buildx rm code101-builder`). Do not use a global prune to clean one lesson.
