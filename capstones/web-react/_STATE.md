# Web React state

Last updated: 2026-11-23. Current delivery status: **written (not run)**.
The updated user instruction stops execution verification. No further smoke tests, Docker startup, application builds or servers are authorized in this session.

| Chapter | Status | Requirements | Remaining acceptance |
|---|---|---|---|
| 01 Create the app, generate the client | written (not run) | W-01 to W-05 | Future authorized runtime verification |
| 02 Sign in with Keycloak | written (not run) | W-06 to W-12 | Future runtime and manual browser checks |
| 03 Screens, queries and pagination | written (not run) | W-13 to W-22, W-30 | Future runtime and screen walkthrough |
| 04 Problem details, 412, offline, WCAG | written (not run) | W-23 to W-28, W-33 | Future runtime, conflict/offline/accessibility walkthrough |
| 05 Docker, nginx, CSP | written (not run) | W-29, W-31, W-32 | Future image/runtime and production-auth checks |

## Writing complete
All five chapters, full-app phase code, focused exercise starters/solutions, verify.json manifests, phase PACK-READMEs, glossary and index exist. No chapter remains unwritten.
The manifests are retained for a later authorized run, not executed now. Packaging is allowed. Only text-to-source comparison with verify_labs.py --static may be run.

## Stopped work and cleanup
Stopped the React verification process tree (react-verify-ship). Cleanup discovery found no React-owned containers remaining.
Containers with code101-verify-05-build-run-ship names were checked by their Compose working-directory labels and belong to the parallel Angular smoke-backend fixture, not React's backend fixture; they were not touched.
Earlier React-owned temporary stacks and built images had been removed by their cleanup commands. No React development server or Gradle daemon remains from this task.

## Historical evidence, not current acceptance
captures/ contains real output recorded before the instruction change, including an earlier five-chapter PASS. Chapters explicitly label this evidence as historical. It is not the current written delivery's status.
The final repeated verification/packaging pipeline was stopped; no result from that interrupted run is claimed.

## Human acceptance still outstanding
Actual browser PKCE sign-in; callback/history/token storage inspection; six-minute rotation/single flight; reload re-entry; admin step-up and logout; screen interactions; optimistic visual timing/rollback/conflict decisions; offline timing; keyboard, dialogs, reflow, contrast and screen-reader checks; production-image auth on 5173.

## Scope and disclosures
Only capstones/web-react is authored; the requested pack builder emits its normal dist/packs outputs. No commits. Platform and sibling capstones are untouched.
See IMPLEMENTATION-NOTES.md for copied/generated text-check exclusions, string-catalogue and invalid-cursor recovery deviations, and contract feedback. No new blocking platform defect.

## Static-only text comparison
python scripts/verify_labs.py --static capstones/web-react completed after the status update:
0 passed, 5 static-checked (not run), 0 failed, 0 unverified (missing tools).
This compares lesson text with code and expected-output strings only. It does not execute the app, manifests, exercises, Docker or build tools.
