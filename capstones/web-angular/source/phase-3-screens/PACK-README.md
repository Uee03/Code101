# web-angular phase 3: Screens and state

Chapter 03: Screens, stores and pagination. Requirements: W-13 to W-22, W-30.

Unzip (Windows: right-click Extract All; macOS: double-click; Linux: unzip). Open 03-screens-stores-pagination/code. This is the complete app, not a delta. Read tutorials/phase-3-screens/03-screens-stores-pagination.md in the repository for every file/command and the human acceptance checklist.

Need Node 26.13.1, npm 11.20.0, Python 3.10+, Docker Desktop/Linux containers. In code: npm ci --no-audit --no-fund; npm run build; npm start. Client generation runs before build/start; package-lock.json is shipped; src/app/api is generated/git-ignored. No global CLI.

contract/openapi.yaml comes verbatim from platform final code. smoke-backend is byte-identical final backend-python app/database/realm/Compose, solely for temporary smoke. Every configuration is shown in the chapter. Copy smoke-backend/.env.example to smoke-backend/.env, enter smoke-backend, docker compose -p angular-manual up -d --build --wait --wait-timeout 400. Fake credentials only. From code npm run smoke runs one scenario. Human sign-in uses http://localhost:4200, never 127.0.0.1.

In a clone hold the whole session with python scripts/stack_lock.py tasksteams -- powershell -NoProfile (bash on macOS/Linux) from clone root, then cd to code. Never overlap another stack on 8000/8180/5432/4200. Stop npm start with Ctrl+C; in smoke-backend run docker compose -p angular-manual down -v --remove-orphans and docker image rm angular-manual-api before exiting the lock. The verifier uses its own project and always cleans up. For a standalone zip, coordinate exclusive access manually.

Copy exercise/starter elsewhere, run node main.mjs, edit and compare exercise/solution. Both run; no unit suites/ng test/lint.

Status: **written (not run)**. Runtime verification was stopped at the user's request. Earlier captures are historical references only, not a current PASS claim. Run/build/serve/Docker commands here are future learner instructions, not completed current verification. Only static lesson/source comparison is permitted during the pause. See repository _STATE.md. Browser authentication/storage/renewal, screen interactions, contrast and assistive technology remain HUMAN acceptance, not claimed verified.

Static comparison: all five chapters text/source-aligned, 0 failed. This is not a runtime PASS; status remains written (not run). Source packs contain no node_modules, dist or .angular; generated client is restored by the documented future api:gen command, and package-lock.json is included.
