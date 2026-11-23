# Platform, phase 0: Primers

Four short background lessons for developers who have not met Git, HTTP and REST, OpenAPI or OAuth 2 and Keycloak. They come before chapter 01 and need no Docker (lesson 04 has one optional step that uses the project from chapter 03). Status: **written (not run)**: nothing in this pack has been executed yet, and each lesson says so under its title.

| Folder | Lesson | Outcome |
|--------|--------|---------|
| `01-git-and-github` | Git and GitHub | A repository with commits, a branch, a `.gitignore` that hides `.env`, a push to GitHub and a clone of Code101 |
| `02-http-and-rest` | HTTP and REST | Requests, responses, methods, status codes, headers and JSON; first calls with `curl` and `Invoke-RestMethod` against a stand-in API on port 8000 |
| `03-reading-an-openapi-file` | Reading an OpenAPI file | An excerpt of the platform contract read section by section; a script that lists operations |
| `04-oauth2-oidc-and-keycloak` | OAuth 2, OpenID Connect and Keycloak | A JWT taken apart, PKCE explained and computed, the `tasksteams` realm excerpts, the checks a backend makes |

## Prerequisites and extraction
- Lesson 01: Git 2.28 or newer, a GitHub account for Step 9. Lesson 02: Python 3.10+ and `curl` (`curl.exe` on Windows). Lesson 03: Python 3.10+ and `pip` (installs PyYAML 6.0.4). Lesson 04: Python 3.10+ only.
- Windows: right-click the zip, **Extract All**. macOS: double-click. Linux: `unzip platform-phase-0-primers.zip`. Each lesson folder holds `code`, and `exercise/starter` and `exercise/solution`.
- Port 8000 must be free in lesson 02 (the stand-in API uses it; stop it before running a real backend).

## Run
Each lesson shows every command. In short:

**Terminal (PowerShell)**
```powershell
cd 02-http-and-rest\code
python mock_api.py
```
In a second terminal in the same folder: `curl.exe -i http://127.0.0.1:8000/health`. Lesson 03: `pip install -r requirements.txt`, `python list_operations.py`. Lesson 04: `python decode_token.py`, `python pkce_challenge.py`. On macOS and Linux use `python3` and `curl`.

## Safety
- All passwords in these lessons (`alice-local-fake`, `bob-local-fake`, `kcadmin_local_only`, `tasks_admin_local_only`) are public, fake and for local practice only.
- Lesson 01 teaches the rule: commit `.env.example`, never `.env`.
- The stand-in API of lesson 02 accepts any bearer token; it is for learning HTTP and must never be exposed.

## For maintainers
No lesson text or code has been run (project rule for this batch). `verify.json` files are prepared for a later run of `scripts/verify_labs.py`: lesson 01 needs `git` and `python`; lesson 02 starts `mock_api.py` in the background and needs `curl`; lesson 03 installs PyYAML into a throwaway `.deps` folder; lesson 04 needs only `python`. Lesson 03 reuses text copied from `phase-1-contract/.../openapi.yaml`, lesson 04 from `phase-3-identity/.../realm-tasksteams.json`; if those files change, update the excerpts.
