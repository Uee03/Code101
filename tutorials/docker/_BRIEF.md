# Docker 101: Zero to Hero

Audience: complete beginners from any field. Analogy first; one runnable example and one exercise per lesson.
Scope: eight lessons in two phases, Linux containers only, local development (not production deployment).
Author baseline: Windows 11, Docker Engine/CLI 29.9.3, Desktop 4.99.0, Compose v5.7.0, WSL2 Ubuntu-26.04.
Date: 2026-11-23. Check the running engine and image tags before authoring. Installation is 60 minutes; other lessons 25-40 minutes.

| Phase | Lesson | Outcome |
|---|---|---|
| 1 containers | 01 What is a container + install Docker | Shipping-container analogy; Windows WSL2/Desktop, optional full .wslconfig, macOS Desktop, Ubuntu Engine; hello-world |
| 1 containers | 02 Images and containers | nginx at 127.0.0.1:8080; pull/run/ps/logs/exec/stop/rm; ports |
| 1 containers | 03 Your first Dockerfile | Python HTTP page; FROM/WORKDIR/COPY/RUN/CMD; full .dockerignore |
| 1 containers | 04 Data that survives | Named volume survives container removal; contrast a read-only bind mount |
| 2 compose | 05 Environment variables and secrets | .env and .env.example; ignored local secrets; file-mounted Compose secret |
| 2 compose | 06 Networks and Compose basics | Python web + Postgres; service-name networking; full Compose keys; no database host port |
| 2 compose | 07 Healthchecks, logs and cleaning up | Readiness-based dependency; logs/down -v/system df; narrowly scoped safe cleanup |
| 2 compose | 08 Project: a two-service app | Small Python API + persistent Postgres, healthchecks; Connect your IDE and host vs service names |

Delivery: tutorials/docker/101-zero-to-hero/phase-{1-containers,2-compose}; matching source lesson folders
with code, exercise/starter, exercise/solution, verify.json; PACK-README per phase. No art (assets: []).
Every configuration appears in full with line-by-line explanation; outputs/errors are captured, never invented.
Use only throwaway code101-verify-* resources for authoring; smoke probes with retries; cleanup runs on failure,
including built images. Do not change Desktop settings. Postgres stays internal; 5432 belongs to Databases.
Commands use PowerShell 5.1 on Windows and POSIX shells on macOS/Linux; never assume Python installed on host.

## Approved sources (Tier 1: official)
- Docker Windows: https://docs.docker.com/desktop/setup/install/windows-install/
- Docker macOS: https://docs.docker.com/desktop/setup/install/mac-install/
- Ubuntu Engine: https://docs.docker.com/engine/install/ubuntu/
- Other Linux distributions: https://docs.docker.com/engine/install/
- WSL install/config: https://learn.microsoft.com/en-us/windows/wsl/install and https://learn.microsoft.com/en-us/windows/wsl/wsl-config
- Dockerfile: https://docs.docker.com/reference/dockerfile/
- Ports: https://docs.docker.com/engine/network/port-publishing/
- Storage: https://docs.docker.com/engine/storage/volumes/ and https://docs.docker.com/engine/storage/bind-mounts/
- Compose: https://docs.docker.com/reference/compose-file/ and https://docs.docker.com/compose/how-tos/startup-order/
- Secrets: https://docs.docker.com/compose/how-tos/use-secrets/
- Cleanup: https://docs.docker.com/engine/manage-resources/pruning/
- Image manifests: https://hub.docker.com/_/python and https://hub.docker.com/_/postgres
- Scoped builder cache cleanup: https://docs.docker.com/reference/cli/docker/buildx/prune/
