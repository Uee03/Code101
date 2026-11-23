# Docker 301, Phase 2: Registries and orchestration

Source pack for lessons 04 to 06 of **Docker 301 (Super Hero to Legendary)**. Status: **written (not run)**.

| Folder | What you build |
|---|---|
| `04-registries-and-promotion-pipelines` | A private registry in Compose, promotion by digest and a retention planner |
| `05-from-compose-to-kubernetes` | A Compose file and six Kubernetes manifests for one service on a local `kind` cluster |
| `06-helm-kustomize-and-rollouts` | Kustomize base and overlays, a Helm chart, a rolling update, a broken release and a rollback |

## Inside each lesson
- `code/`: finished files, identical to the lesson text (lesson 06's `app.py` and `Dockerfile` repeat lesson 05's, as the lesson says).
- `exercise/starter/` and `exercise/solution/`: the Try it exercise and its answer.
- `verify.json`: maintainer specification for a later verification run. The lessons were **not executed** when they were written.

## Tools
Docker and Python (lesson 04); plus `kubectl` and `kind` (lessons 05 and 06); plus Helm (lesson 06, optional). The lessons give install routes. `kind` runs a Kubernetes cluster inside Docker on your machine. Check `kubectl config current-context` before every cluster command: it must be `kind-code101`.

## Ports
- Lesson 04: registry on `127.0.0.1:5050` (loopback only, no authentication, no TLS: lab use only).
- Lessons 05 and 06: `kubectl port-forward` on `127.0.0.1:8091`.
Run one lab at a time.

## Safety and cleanup
- Secrets in this pack (`demo-not-a-secret`) are public demonstration values.
- Lesson 04: `docker compose down -v` deletes the registry volume and every image in it.
- Lessons 05 and 06: `kind delete cluster --name code101` removes the cluster; `docker image rm code101/api:1.0.0 code101/api:2.0.0` removes the images.
- Do not use a global prune to clean one lesson.
