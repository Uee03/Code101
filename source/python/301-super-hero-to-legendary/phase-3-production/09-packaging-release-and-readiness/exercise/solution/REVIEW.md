# Production readiness review: candidate service (worked answer)

Reviewer: example
Decision: **no-go until R1 to R5 are fixed; go with conditions after that**

## Findings
| Id | Severity | Evidence | Risk | Fix | Owner |
|----|----------|----------|------|-----|-------|
| R1 | blocker | `compose.yml`: `DATABASE_PASSWORD: admin` | A weak credential committed in a file that is copied everywhere | Mount a secret file and read it with `DATABASE_PASSWORD_FILE`; rotate the password | platform |
| R2 | blocker | `compose.yml`: `ports: "8000:8000"` | Published on every interface, reachable from the network | Bind to `127.0.0.1` (or put a reverse proxy in front) | platform |
| R3 | blocker | `Dockerfile`: no `USER` | The process runs as root; a code-execution bug becomes root in the container | Create a user and set `USER 10001` | service |
| R4 | major | `compose.yml`: `DEBUG: "true"` | Debug output and detailed errors reach clients | Remove it; make production the default | service |
| R5 | major | `Dockerfile`: `FROM python:latest` | The base image changes without review; builds are not reproducible | Pin a version tag (and consider a digest) | service |
| R6 | major | `requirements.txt`: `fastapi`, `uvicorn>=0.30` | Different builds install different versions | Pin with `==` and use a hash lock | service |
| R7 | major | no `HEALTHCHECK`, no readiness endpoint reviewed | The orchestrator cannot tell a stuck process from a healthy one | Add a health check and a separate readiness probe | service |
| R8 | minor | `__version__ = "1.4"`, changelog lacks 1.4 | Releases cannot be traced to a change list | Use MAJOR.MINOR.PATCH and a changelog entry | service |
| R9 | minor | no `.dockerignore`, no CI | `.env` or `.git` can enter the image; nothing runs the checks | Add both | service |

## Checklist areas not covered by `readiness_check.py`
- Observability: no logging, metrics or tracing is visible in the candidate. Add structured logs and request metrics (lesson 07) before go.
- Security: `restart: always` hides crash loops; `read_only`, `cap_drop` and a memory limit are missing (fixed in the solution compose file).
- Resilience: no timeout or retry policy can be reviewed because no application code was provided; request it.
- Release and rollback: no previous image tag is recorded; keep the last good tag and document the rollback command.
- Operations: no runbook, no alert, no backup statement for the database; the owner must provide them.

## Conditions for go
1. R1 to R5 closed and verified by `python readiness_check.py candidate`.
2. A dashboard with request rate, error rate and latency exists and an alert is routed to a named on-call person.
3. A rollback was rehearsed once.
