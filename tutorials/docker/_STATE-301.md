# Docker 301 state

Updated: 2026-11-23. Status: **written (not run)**. Nine lessons, three phases. Docker 101 files (`_BRIEF.md`, `_STATE.md`, `_verification.json`, `_VERIFICATION.md`) are unchanged; `GLOSSARY.md` had the 301 terms appended.

| Lesson | Phase | Status | Evidence |
|---|---|---|---|
| 01-threat-model-for-containers | phase-1-secure-supply-chain | written (not run) | Lesson, code, exercise, verify.json authored. Audit output (11 findings insecure, none reviewed; 5 starter) derived by reading the script. |
| 02-image-provenance-sbom-and-signing | phase-1-secure-supply-chain | written (not run) | Policy-check and SBOM-query outputs derived by reading the code. Digest and SBOM from a real build are described, not shown. Signing is reference commands only. |
| 03-runtime-hardening | phase-1-secure-supply-chain | written (not run) | JSON reports derived from the code; `cap_bounding` of the baseline and error texts shown as typical. AppArmor, userns-remap, rootless are Linux-host reading steps. |
| 04-registries-and-promotion-pipelines | phase-2-registries-and-orchestration | written (not run) | Retention outputs derived by hand; registry API outputs derived from the documented API. Digests shown as placeholders. |
| 05-from-compose-to-kubernetes | phase-2-registries-and-orchestration | written (not run) | Manifests checked against Kubernetes docs by reading; kubectl outputs typical. NetworkPolicy enforcement on kind not claimed. |
| 06-helm-kustomize-and-rollouts | phase-2-registries-and-orchestration | written (not run) | Rendered lines derived by reading templates and overlays; rollout behaviour from documented Deployment semantics. |
| 07-observability-for-containers | phase-3-operations | written (not run) | Metric counts derived from the code; bucket values and collector span layout deliberately not claimed. |
| 08-resources-autoscaling-and-cost | phase-3-operations | written (not run) | Cost-model outputs derived by hand (placeholders, not prices); OOM and HPA behaviour described, last allocation number not predicted. |
| 09-production-readiness | phase-3-operations | written (not run) | Row counts derived from the seed SQL; durations and file names shown as placeholders. |

## Scope and honesty
- Nothing was executed: no Docker, Compose, kubectl, kind, helm, docker buildx or any lab. Allowed commands only: Docker Hub, PyPI and GitHub release lookups (tags and versions), official-docs fetches, `verify_labs.py --static` and `build_packs.py`.
- Every lesson carries the draft notice and `verified: not yet run`. Static checking never upgrades the status.
- Docker 201 is written. Each lesson's front matter and "Before you start" now cite the 201 lessons by id and link (01 multi-stage builds, 03 non-root and hardening, 05 Compose profiles, 06 secrets, 07 networking and limits, 09 CI, 10 backups and upgrades) and Docker 101 lesson 07 for healthchecks. Overlaps with 201 (multi-stage builds, healthchecks, secrets, Compose profiles, CI builds, dev containers) are still to be reconciled in a review pass.
- Source facts checked against official docs on 2026-11-23: seccomp default-profile behaviour, rootless known limitations (AppArmor, overlay network and privileged ports), `userns-remap`, SBOM generation with the local exporter, registry v3 config path `/etc/distribution/config.yml`, HPA example manifest and walkthrough commands.

## Pending runtime review (what to check first when the labs are run)
1. Lesson 01: regex rule behaviour on the three compose files; the reviewed Postgres service (`user: 70:70`, read-only root, dropped capabilities, tmpfs) has never been started.
2. Lesson 02: `docker buildx build --sbom=true --provenance=mode=max --output type=local` on the default builder versus the containerd image store; which attestation files appear; the reference to `imagetools inspect` output.
3. Lesson 03: hardened JSON values (`cap_bounding`, `no_new_privs`, `seccomp`); the seccomp mkdir profile on Docker Desktop; `tmpfs ... :size=16m` short syntax; `cpus: 0.5`.
4. Lesson 04: `registry:3.1.2` accepting the configuration; `Docker-Content-Digest` with the four-type Accept header on the containerd image store; DELETE and garbage-collect commands.
5. Lessons 05 and 06: Pod Security `restricted` with `fsGroup` and `defaultMode: 0440`; secret file readable by uid 10001; `kubectl kustomize` and `helm template` output lines; `kind load` with two images; probe pod behaviour during a rolling update; stalled rollout message after the 60 s deadline.
6. Lesson 07: the OpenTelemetry Python 1.45.2 packages install and export; collector 0.165.0 accepts the configuration (recent releases changed telemetry settings, which this config avoids); Grafana 12.4 loads the hand-written dashboard JSON; Prometheus rule check output text.
7. Lesson 08: memory kill with `memswap_limit`; `docker compose up --exit-code-from`; metrics-server v0.9.1 with the insecure-TLS patch on kind; HPA scale-up behaviour and quota interaction on a single-node cluster.
8. Lesson 09: `up --wait`; backup, drill and recovery scripts under Alpine's `sh`; `dropdb --if-exists` notice text; `docker compose cp` of a volume path.
9. Every `winget` package id (`Kubernetes.kubectl`, `Kubernetes.kind`, `Helm.Helm`) is taken from memory of the package names and has a "search if not found" fallback in the text.

## Static and packaging evidence
Completed on 2026-11-23, repository root:

    python scripts\verify_labs.py --static docker/301     9 static-checked (not run), 0 failed
    python scripts\build_packs.py docker-301              3 phase zips + docker-301-all.zip built in dist\packs

`verify_labs.py` filters are path substrings, so `docker/301` is the static filter; `build_packs.py` filters on zip names, so `docker-301` is the pack filter. No commits were made.
