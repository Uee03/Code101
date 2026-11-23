# Docker 301: Super Hero to Legendary

Audience: developers who finished Docker 101 and Docker 201 (multi-stage builds, healthchecks, secrets, Compose profiles, dev containers, CI builds, per `docs/CURRICULUM.md`; the 201 lessons now exist, see [Docker 201](201-hero-to-super-hero/phase-1-better-images/01-multi-stage-builds.md), and each 301 lesson links the ones it needs in "Before you start").
Voice: trade-offs, failure modes, "when not to use this", measurements to take (never invented numbers), production checklists and ADR-style decisions.
Scope: nine lessons in three phases, Linux containers, security and operations of container workloads. Unity is never built or run in Docker in this course (local only).
Status: written (not run), per the repository owner's instruction of 2026-11-23. Tool and image versions were looked up on 2026-11-23 (tags and package versions only; nothing was pulled, built or installed).
Filters: `docker/301` for `python scripts\verify_labs.py --static`; `docker-301` for `python scripts\build_packs.py`.

| Phase | Lesson | Outcome |
|---|---|---|
| 1 secure-supply-chain | 01 Threat model for containers and images | Trust boundaries, attacker moves, a threat-model table with verifiable decisions, a line-based Compose audit script |
| 1 secure-supply-chain | 02 Image provenance, SBOM and signing | Tags versus digests, digest pinning, base-image policy as code, BuildKit SBOM (local exporter), SBOM query, cosign concepts and verification placement |
| 1 secure-supply-chain | 03 Runtime hardening | Read-only root, dropped capabilities, no-new-privileges, limits, custom seccomp profile, AppArmor profile, `userns-remap`, rootless Docker and their costs |
| 2 registries-and-orchestration | 04 Registries and promotion pipelines | Local `registry:3` in Compose, push, API reads, promotion by digest, retention planner, garbage collection, registry choice |
| 2 registries-and-orchestration | 05 From Compose to Kubernetes | Concept mapping, six manifests in full (Namespace, ConfigMap, Secret example, Deployment with three probes, Service, NetworkPolicy) on `kind`, Pod Security `restricted` |
| 2 registries-and-orchestration | 06 Helm, Kustomize and rollout strategies | Kustomize base and overlays with generated ConfigMaps, a Helm chart, rolling update, stalled bad release, rollback; blue/green, canary and shadow as concepts with trade-offs |
| 3 operations | 07 Observability for containers | Compose stack: instrumented Python service, Prometheus (rules), Grafana (provisioned), OpenTelemetry collector; RED metrics, histograms, cardinality, trace id in logs |
| 3 operations | 08 Resources, autoscaling and cost | OOM kill and CPU limit in Compose, ResourceQuota and LimitRange, HPA on the Kubernetes docs example, a cost model with placeholder inputs |
| 3 operations | 09 Production readiness | Backup, restore drill and recovery on Postgres, RPO demonstration, runbooks, PodDisruptionBudget, upgrade plan per layer, scored readiness review and a review exercise |

Delivery: `tutorials/docker/301-super-hero-to-legendary/phase-{1-secure-supply-chain,2-registries-and-orchestration,3-operations}`; matching `source/docker/301-super-hero-to-legendary/...` lesson folders with `code`, `exercise/starter`, `exercise/solution`, `verify.json`; a `PACK-README.md` per phase. No art (`assets: []`).
Every lesson carries the draft notice under its H1 and `verified: not yet run`.

## Host ports used (one lab at a time, loopback only)
| Port | Lesson |
|---|---|
| 8090 | 03 hardening demo, 07 observability API |
| 9090, 3000 | 07 Prometheus, Grafana |
| 5050 | 04 local registry |
| 8091 | 05, 06 `kubectl port-forward` |
No lesson publishes 5432, 8080, 8081, 8000, 8180 (reserved by other tracks and capstones). The Postgres of lesson 09 is never published.

## Pinned versions (looked up 2026-11-23)
`registry:3.1.2`, `prom/prometheus:v3.16.0`, `grafana/grafana:12.4.15`, `otel/opentelemetry-collector:0.165.0`, `nginxinc/nginx-unprivileged:1.31-alpine`, `postgres:17-alpine`, `python:3.13-slim`, `alpine:3.22`, `busybox:1.37`, Python packages `opentelemetry-sdk` and `opentelemetry-exporter-otlp-proto-http` 1.45.2, metrics-server v0.9.1 (manifest URL). Kubernetes, kind and Helm versions are deliberately not pinned (current stable). Lab exception recorded in lesson 08: `registry.k8s.io/hpa-example` is used untagged exactly as in the Kubernetes documentation.

## Approved sources
Tier 1 (used for claims):
- Docker security: https://docs.docker.com/engine/security/ , seccomp https://docs.docker.com/engine/security/seccomp/ , AppArmor https://docs.docker.com/engine/security/apparmor/ , user namespaces https://docs.docker.com/engine/security/userns-remap/ , rootless https://docs.docker.com/engine/security/rootless/ and its troubleshooting page (known limitations)
- Docker build: best practices https://docs.docker.com/build/building/best-practices/ , SBOM attestations https://docs.docker.com/build/metadata/attestations/sbom/
- Docker resources and logging: https://docs.docker.com/engine/containers/resource_constraints/ , https://docs.docker.com/engine/logging/drivers/json-file/
- Kubernetes: https://kubernetes.io/docs/concepts/ , Pod Security Standards, probes, Deployments, Kustomize, Secrets good practices, network policies, resource management, HPA walkthrough, quotas and limit ranges, PDB, version skew
- OWASP Docker Security Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html and Threat Modeling Cheat Sheet
- OCI specs: https://github.com/opencontainers/image-spec/blob/main/spec.md , https://github.com/opencontainers/distribution-spec/blob/main/spec.md , https://github.com/opencontainers/runtime-spec
Tier 2 (project documentation, flagged in the lesson text, used only for tool behaviour): Sigstore cosign, Distribution registry, Helm, kind, Prometheus, Grafana, OpenTelemetry, PostgreSQL backup.

## Design decisions (this level)
- Python stdlib scripts are the lab "code" where no Docker is needed (audit, policy check, SBOM query, retention plan, cost model) so every expected output is derivable by reading the code; Docker and Kubernetes outputs are marked "not yet run" or "typical".
- No lesson invents a digest, scan result, size, timing, price or cluster output. Digests in samples are all-zero placeholders and say so; prices are labelled placeholders; variable values are shown as placeholders.
- Lesson 06's `app.py` and `Dockerfile` repeat lesson 05's (declared in the text, `skip_lesson_check` in `verify.json`); everything else is shown in full.
- Capstones are mentioned only as a target for the lesson 09 review; no capstone chapter is linked because none for Docker 301 exists.
