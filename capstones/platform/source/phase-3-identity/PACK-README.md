# Platform, phase 3: Identity

Keycloak 26.8.2 added to the Compose project, with the `tasksteams` realm imported from a file, and the first version of the conformance script. The pack holds the whole project so far (contract, database, Keycloak). Status: **verified** on 2026-11-23 (both containers healthy, four infrastructure checks pass, exercise solution prints `bob roles: member`).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `03-keycloak-identity` | Identity with Keycloak | Realm with roles `admin` and `member`, clients `tasks-web`, `tasks-mobile`, `tasks-api`, `tasks-smoke`, users alice, bob and carol; tokens fetched and checked |

## Prerequisites and extraction
- Docker running in Linux-container mode; Python 3.10+.
- Host ports **5432** and **8180** must be free. The first run downloads the Keycloak image (about 450 MB).
- Extract the zip as in phase 1; open `03-keycloak-identity/code`.

## Run
**Terminal (PowerShell; folder: `03-keycloak-identity/code`)**
```powershell
Copy-Item .env.example .env
docker compose -p platform up -d --wait
python scripts/conformance.py --infra-only
```
On macOS and Linux use `cp .env.example .env` and `python3`.

## Exercise
`exercise/starter/show_roles.py` prints the roles in bob's token; edit it in place so it can find `code/scripts`.

## Safety and cleanup
Passwords (`alice-local-fake`, `bob-local-fake`, `carol-local-fake`, `kcadmin_local_only`) are public and fake. The `tasks-smoke` client allows the password grant for the script only. `start-dev` is for development, never production.
```powershell
docker compose -p platform down -v --remove-orphans
```

## For maintainers
`verify.json` starts a throwaway project with `--wait` (timeout 300 s, retried), runs `conformance.py --infra-only` with retries, runs the exercise solution and always runs `down -v --remove-orphans`. Files already shown in chapters 01 and 02 are in `skip_lesson_check`. The realm file (331 lines) and the script are shown completely in the lesson.
