# Docker 201: Hero to Super Hero (brief)

Audience: finished Docker 101, with 1 to 2 years of experience. Assume 101; explain the why; "Why this, not that" tables; Mermaid diagrams; Tier 1 sources (docs.docker.com) first.
Scope: ten lessons in three phases, Linux containers only. Local development, CI and small deployments; orchestration, registries at scale and deeper hardening belong to Docker 301.
Author baseline: Docker Engine/CLI 29.9.3, Compose v5.7.0 (as in 101). Date: 2026-11-23.
**Verification policy (owner instruction, 2026-11-23):** lessons and source code are written **without being run**. Every lesson carries the "Draft: written but not yet run" notice under its title and `verified: not yet run`. The only check done is `python scripts\verify_labs.py --static docker/201-hero-to-super-hero`, which executes nothing. No invented image digests, sizes, scan results or error text; unknown output is labelled "typical message" or described instead of shown.
Unity is never in Docker. No art (`assets: []`). No real secrets: `.env.example` and `*.example` files only.

| Phase | Lesson | Outcome |
|---|---|---|
| 1 better-images | 01 Multi-stage builds | Go (scratch) and Node multi-stage Dockerfiles; `COPY --from`, `--target`; stage trade-offs |
| 1 better-images | 02 Build cache, BuildKit and .dockerignore | Layer order, cache mounts, context size, `--progress=plain` |
| 1 better-images | 03 Non-root, read-only, capabilities and hardening | `USER`, root-owned code, `read_only`, `tmpfs`, `cap_drop`, `no-new-privileges`, `pids_limit` |
| 1 better-images | 04 Image scanning and supply-chain basics | Docker Scout and Trivy commands (no invented results), OCI labels, digests, SBOM and provenance |
| 2 compose-in-depth | 05 Profiles, overrides and extension fields | Base + dev + prod files, profiles, `x-` fields and anchors, `!override`, `docker compose config` |
| 2 compose-in-depth | 06 Secrets and configs | File secrets, `_FILE` convention, Compose configs, build secrets, leak checks |
| 2 compose-in-depth | 07 Networking in depth and resource limits | User-defined and internal networks, DNS scope, published vs exposed, loopback, memory/CPU/pids limits, OOM, full `.wslconfig` |
| 3 workflows | 08 Dev containers and bind-mount dev loops | Full `devcontainer.json`, dev Dockerfile, `compose watch`, bind mount, WSL pitfalls |
| 3 workflows | 09 CI builds with GitHub Actions and registries | Full workflow (build, test, scan, push to ghcr.io), `GITHUB_TOKEN`, cache, least privilege, Dependabot |
| 3 workflows | 10 Backups, upgrades and cleanup | `pg_dump` restore, volume `tar`, Postgres 16 to 17 by dump/restore, `docker system df`, scoped prune |

Delivery: `tutorials/docker/201-hero-to-super-hero/phase-{1-better-images,2-compose-in-depth,3-workflows}/NN-slug.md`; source in `source/docker/201-hero-to-super-hero/phase-N-slug/NN-slug/{code,exercise/starter,exercise/solution,verify.json}` with one `PACK-README.md` per phase. Numbering restarts at 01.
Real full stacks (API, database, identity) are not duplicated here: lessons link `capstones/platform`.

## Approved sources (Tier 1: official)
- Multi-stage: https://docs.docker.com/build/building/multi-stage/
- Dockerfile reference and best practices: https://docs.docker.com/reference/dockerfile/ and https://docs.docker.com/build/building/best-practices/
- Build cache: https://docs.docker.com/build/cache/
- Build secrets: https://docs.docker.com/build/building/secrets/
- Attestations: https://docs.docker.com/build/metadata/attestations/ and https://docs.docker.com/build/ci/github-actions/attestations/
- Docker Scout: https://docs.docker.com/scout/
- Compose files and merging: https://docs.docker.com/compose/how-tos/multiple-compose-files/ ; profiles: https://docs.docker.com/compose/how-tos/profiles/ ; secrets: https://docs.docker.com/compose/how-tos/use-secrets/ ; watch: https://docs.docker.com/compose/how-tos/file-watch/
- Compose reference (services, networks, secrets, configs, extension, develop): https://docs.docker.com/reference/compose-file/
- Networking and ports: https://docs.docker.com/engine/network/ and https://docs.docker.com/engine/network/port-publishing/
- Resource constraints: https://docs.docker.com/engine/containers/resource_constraints/
- WSL configuration: https://learn.microsoft.com/en-us/windows/wsl/wsl-config
- Dev containers: https://containers.dev/ and https://code.visualstudio.com/docs/devcontainers/containers
- GitHub Actions for Docker: https://docs.docker.com/build/ci/github-actions/ ; GitHub security hardening: https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions
- Volumes and pruning: https://docs.docker.com/engine/storage/volumes/ and https://docs.docker.com/engine/manage-resources/pruning/
- PostgreSQL backup: https://www.postgresql.org/docs/current/backup.html ; image: https://hub.docker.com/_/postgres
