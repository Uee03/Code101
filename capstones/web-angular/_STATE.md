# Web Angular state

2026-11-23: Five chapters/source snapshots/exercise pairs/future verify.json plans are written. User explicitly stopped all runtime verification. The in-progress clean-room verifier and its process tree were stopped, then its phase-5 Python/Keycloak/Postgres project was removed with compose down -v --remove-orphans and its built API image deleted. No further smoke tests, builds, servers or Docker runs are authorized. Cleanup inventory: zero containers, zero volumes, only bridge/host/none networks. No final runtime PASS count is claimed.

| Chapter | Status |
|---|---|
| 01 Create the app, generate the client | written (not run) |
| 02 Sign in with Keycloak | written (not run) |
| 03 Screens, stores and pagination | written (not run) |
| 04 Problem details, 412, offline, WCAG | written (not run) |
| 05 Docker, nginx, CSP | written (not run) |

Front matter: verified: not yet run in every chapter. Historical captures from before the pause are retained in evidence/ and explicitly labelled, not treated as current runtime verification. Browser sign-in/storage/renewal, step-up/logout, UI interactions, conflict choices and WCAG checks remain manual/unrun. Other backends were not exercised.

Static comparison: 5 static-checked (not run), 0 failed, using the explicitly permitted --static command. Captured output: evidence/static-check.txt. Packaging: five phase zips plus one all-in-one requested via build_packs.py; no application execution. All chapter status rows remain written (not run).

Findings/deviations: see CONTRACT-NOTES.md and ACCEPTANCE.md. No platform/sibling file was edited. Keep the approved archived nginxinc image pin pending approval of a maintained replacement; resolve the W-08/W-11 ID-token-hint wording. The Node-only private injector hook is isolated. English UI strings remain feature-local rather than a translation catalogue.
