# Platform, phase 4: Conformance

The finished platform: contract, database, Keycloak, Compose and the full conformance script. Status: **verified** on 2026-11-23 for the infrastructure checks (`--infra-only`: 4 passed) and for `--help`. The 14 API checks need a backend and are run in each backend capstone.

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `04-conformance-script` | The conformance script | `scripts/conformance.py` with 18 ordered checks; you know what each proves |

## Prerequisites and extraction
- Docker running in Linux-container mode; Python 3.10+; host ports 5432 and 8180 free.
- Extract the zip as in phase 1; open `04-conformance-script/code`.

## Run
**Terminal (PowerShell; folder: `04-conformance-script/code`)**
```powershell
Copy-Item .env.example .env
docker compose -p platform up -d --wait
python scripts/conformance.py --infra-only
```
Later, with a backend listening on port 8000: `python scripts/conformance.py` expects `18 passed, 0 failed`. Use `BASE_URL` to point at another address.

## Exercise
`exercise/starter/check_complete_task.py`: write a 19th check. The solution must compile; it can only run against a backend.

## Safety and cleanup
Fake local passwords only. Remove everything when done:
```powershell
docker compose -p platform down -v --remove-orphans
```

## For maintainers
`verify.json` starts a throwaway project, runs `--help` and `--infra-only` (with retries), compiles the exercise solution and always cleans up. Only `scripts/conformance.py` is checked against the lesson text; every other file is unchanged from earlier chapters and is in `skip_lesson_check`. Do not add API checks to the verification until a backend exists.
