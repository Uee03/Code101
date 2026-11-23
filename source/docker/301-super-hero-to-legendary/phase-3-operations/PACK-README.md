# Docker 301, Phase 3: Operations

Source pack for lessons 07 to 09 of **Docker 301 (Super Hero to Legendary)**. Status: **written (not run)**.

| Folder | What you build |
|---|---|
| `07-observability-for-containers` | An instrumented service with Prometheus, Grafana and an OpenTelemetry collector in Compose |
| `08-resources-autoscaling-and-cost` | Memory and CPU limit experiments, a quota, an autoscaler and a cost model |
| `09-production-readiness` | A database backup, restore drill and recovery, runbooks, a disruption budget and a readiness review |

## Inside each lesson
- `code/`: finished files, identical to the lesson text.
- `exercise/starter/` and `exercise/solution/`: the Try it exercise and its answer.
- `verify.json`: maintainer specification for a later verification run. The lessons were **not executed** when they were written.

## Unzip and run
1. Windows: right-click the zip > **Extract All**; macOS: double-click; Linux: `unzip <pack>.zip`.
2. Open a terminal in the lesson's `code` folder. Copy `.env.example` to `.env` where the lesson says so; the pack never contains a `.env`.
3. Follow the Steps in order. Lesson 08's Kubernetes steps also need `kubectl` and `kind` (see Docker 301 lesson 05).

## Ports (loopback only)
- Lesson 07: 8090 (service), 9090 (Prometheus), 3000 (Grafana).
- Lesson 08: no host ports; the autoscaling load comes from inside the cluster.
- Lesson 09: none (the database is never published).
Run one lab at a time.

## Safety and cleanup
- Passwords in `.env.example` files are public demonstration values.
- Lesson 08 keeps a CPU core busy for 60 seconds and installs the metrics-server add-on from the internet into a throwaway `kind` cluster: read the lesson's warnings first.
- Lesson 07: `docker compose down -v` deletes stored metrics and Grafana state. Lesson 09: `docker compose down -v` deletes the database **and the backups** of the lab.
- Never commit backup files or `.env`. Do not use a global prune to clean one lesson.
