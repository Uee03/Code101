# Threat model: orders-api (example)

Scope: the orders-api container, its Postgres container, the CI job that builds the image and the registry that stores it.

## Assets
- Customer order data in Postgres.
- The database password and the registry push credential.
- The integrity of the image that runs in production.

## Actors
- External attacker who can send HTTP requests to the API.
- Attacker who controls one dependency (a package or a base image).
- Insider or stolen laptop with access to CI or the registry.

## Trust boundaries
1. Internet to the API port.
2. Container to host kernel.
3. Build system to registry.
4. Registry to runtime host.

## Threats and decisions
| ID | Boundary | Threat | Decision | Lesson |
|----|----------|--------|----------|--------|
| T1 | 1 | Remote code execution in the API | Run as non-root, read-only root, no capabilities | 03 |
| T2 | 2 | Container escape through a kernel or runtime flaw | Default seccomp, patched engine, rootless or user namespaces | 03 |
| T3 | 3 | Poisoned dependency or base image | Pin by digest, SBOM, scan, policy | 02 |
| T4 | 3 | Stolen CI credential pushes a malicious image | Short-lived credentials, sign images, verify before deploy | 02 |
| T5 | 4 | Tag moved to a different image after review | Deploy by digest, promote instead of rebuild | 04 |
| T6 | 1 | Secret leaked through environment or logs | Mount secrets as files, never log values | 03 |

## Out of scope for this version
- Physical access to hosts.
- Denial of service through resource exhaustion (see lesson 08).

## Review
Revisit this file when the architecture changes and after every incident.
