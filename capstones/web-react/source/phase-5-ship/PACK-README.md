# Web React ? phase 5: Docker, nginx, CSP

Chapter 05; requirements W-29, W-31, W-32. Full app, not a diff.
Unzip web-react-phase-5-ship.zip (Windows Extract All; macOS double-click; Linux unzip), then open 05-build-run-ship/code.
Tutorial: capstones/web-react/tutorials/phase-5-ship/05-build-run-ship.md.
Node 26.13.1, npm 11.20.0, Docker Linux and free ports 5432/8000/8180/5173 required.
In code: npm ci; npm run build. Follow the tutorial for temporary backend startup (420-second readiness timeout),
npm run smoke once, and ALWAYS down -v --remove-orphans plus docker image rm.
Within the repository: python scripts/verify_labs.py capstones/web-react/source/phase-5-ship/05-build-run-ship
The verifier owns the tasksteams lock; manual shared-port work uses scripts/stack_lock.py.
Browser sign-in, visual layout, accessibility and six-minute renewal remain manual, not automated claims.
exercise/starter and exercise/solution contain a focused runner using code's tsx as described in Try it.
package-lock.json is shipped; schema declarations regenerate. No node_modules, dist, local .env, tokens or real secrets.
backend/ is verbatim from backend-python/source/phase-5-hardening/05-hardening/code; do not edit it here.
The contract copy is SHA-256 checked. Copied upstream/generated files are disclosed skip_lesson_check entries;
every authored app source/config file is shown in full in the tutorial.
Static smoke origin 8201 cannot sign in. For real auth stop Vite and publish nginx on localhost:5173 (WEB_PORT=5173).

Status: written (not run). No execution checks are authorized for the current delivery.

The verification/build/server commands above are for a later authorized run, not authoring-session instructions. Existing captured results predate the no-execution update.

Static-only text comparison: 5 phase chapters checked, 0 failures; no application execution.
