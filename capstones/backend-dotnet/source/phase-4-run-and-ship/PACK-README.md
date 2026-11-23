# Backend ASP.NET Core, phase 4: Run and ship

A multi-stage Dockerfile with pinned images and a non-root user, a `.dockerignore`, and a Compose override that adds the `api` service to the platform stack on the network `tasksteams-net`, published on `127.0.0.1:8000` with a health check. Status: **verified** on 2026-11-23: the API runs as `uid=1654(app)` and the conformance script prints `17 passed, 1 failed`.

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `04-run-and-ship` | Docker image and Compose | `docker compose up -d --build --wait` starts Postgres, Keycloak and the API, all healthy |

## Prerequisites and extraction
- Docker running in Linux-container mode (the first build downloads about 1 GB of base images); Python 3.10+; host ports 5432, 8180, 8000 free. The .NET SDK is not needed on the host in this phase.
- Extract the zip as in phase 1 and open `04-run-and-ship/code`.

## Run
**Terminal (PowerShell; folder: `04-run-and-ship/code`)**
```powershell
Copy-Item .env.example .env
docker compose -p backend up -d --build --wait
python scripts/conformance.py
```

## Exercise
`exercise/starter/docker-compose.override.yml`: add a memory limit and a process limit to the `api` service. Check with `docker compose config`.

## Safety and cleanup
```powershell
docker compose -p backend down -v --remove-orphans
docker image rm code101/tasksteams-backend-dotnet:1.0
```

## For maintainers
`verify.json` builds the image under a throwaway project, checks health, the user id and the conformance result, validates the exercise solution with `docker compose config`, and always removes containers, network, volume and the image it built. Base images `mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24` and `aspnet:11.0.0-alpine3.24` stay in the Docker cache.
