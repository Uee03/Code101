# Desktop C++ phase 3: Auth with PKCE

Status: written (not run). No verification claim applies to this snapshot.

## Open
Extract the zip. Open `03-auth-pkce/code`. The folder holds the whole project at the end of this chapter, not a patch.
Read `tutorials/phase-3-auth/03-auth-pkce.md` in the capstone repository.

## Prerequisites
Everything from phase 2, plus Keycloak (realm `tasksteams`) on `http://localhost:8180` and a web browser.
**One manual step:** the platform realm has no desktop client. In the Keycloak Admin console choose realm `tasksteams`, Realm settings, Action, Partial import, and import `code/keycloak/tasks-desktop-client.json` once.
Test users and their fake passwords are in the platform TDD (for example `carol`).

## Later commands (not executed during this writing-only block)
```powershell
cmake --preset windows
cmake --build --preset windows-debug
.\build\windows\out\tasks_desktop.exe
```
Click Sign in. Settings: `API_BASE_URL`, `OIDC_ISSUER` (default `http://localhost:8180/realms/tasksteams`, it must match the realm's issuer exactly).
The exercise is an overlay: copy `exercise/starter/src` or `exercise/solution/src` over `code/src`.

## Chapter
03. Auth with PKCE, 120 minutes.

## Secrets
There are none in this pack. Tokens exist only in memory while the app runs. Never write a token to a file or a log.
