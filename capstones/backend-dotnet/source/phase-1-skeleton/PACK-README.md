# Backend ASP.NET Core, phase 1: Skeleton

The ASP.NET Core 11 solution with FastEndpoints: three working endpoints (`/health`, a stub for `/v1/me`, a stub for `POST /v1/teams`), RFC 9457 problem details for every failure and a validation error shape with JSON Pointers. No database and no sign-in yet. Status: **verified** on 2026-11-23 (build, start, `curl` calls for the working and failing cases, exercise solution builds).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `01-skeleton` | The ASP.NET Core skeleton | the API starts on `127.0.0.1:8000`, answers `/health` and returns problem documents for 400, 404, 405, 415, 422 |

## Prerequisites and extraction
- .NET SDK 11.0.100 or newer 11.0.x (`dotnet --version`). Docker is not needed in this phase.
- Extract the zip (Windows: right-click, Extract All; macOS: double-click; Linux: `unzip backend-dotnet-phase-1-skeleton.zip`) and open `01-skeleton/code`.
- Host port 8000 must be free.

## Run
**Terminal (PowerShell; folder: `01-skeleton/code`)**
```powershell
dotnet build --nologo
cd src/TasksApi
dotnet run
```
In a second terminal: `curl.exe -s http://127.0.0.1:8000/health` (macOS and Linux: `curl`). Expected: `{"status":"ok","version":"1.0.0"}`. Stop the API with Ctrl+C.

## Exercise
`exercise/starter/src/TasksApi/Features/Platform/PingEndpoint.cs`: make it answer `GET /v1/ping`. The solution must build.

## Safety and cleanup
Nothing is created outside the folder. Delete `bin` and `obj` folders to remove build output.

## For maintainers
`verify.json` builds, starts the API on port 8000 under the `tasksteams` lock (other capstone labs use the same ports), calls it with `curl` and builds the exercise solution. `openapi.yaml` is the platform file and is skipped by the lesson check.
