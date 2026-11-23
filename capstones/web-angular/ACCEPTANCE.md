# W-xx acceptance ledger

Current status is **written (not run)**. Runtime verification was stopped by the user; no final clean-room PASS is claimed. The evidence/ excerpts and execution facts in this ledger are historical captures from before the pause, not new runs. Future verification plans remain in verify.json. Only --static text/source comparison is allowed now. No browser acceptance was automated. UI code was compiled, not visually certified. All backend scenarios used the Python final phase, not the other three backends.

| Id | Phase | Implementation / evidence boundary |
|---|---|---|
| W-01 | 1 | CLI scaffold, build, temporary localhost:4200 GET 200. |
| W-02 | 1 | All five copied contracts byte-compared to platform; SHA-256 printed in chapter 01. |
| W-03 | 1 | api:gen, prebuild/prestart, generated 27 operation functions. |
| W-04 | 1 | environment.ts/development replacement; public URL/id/scope defaults. |
| W-05 | 1 | Node injector spike + actual generated getHealth/getMe: health ok, alice admin. Private root marker isolated to smoke. |
| W-06 | 2 | Actual library initCodeFlow URL has S256; Keycloak login page 200. Human exchange remains manual. |
| W-07 | 2 | Callback exchange, safe return route, replaceState/replaceUrl; human URL/history inspection required. |
| W-08 | 2 | SplitStorage routing probed with stand-in; human storage inspection required. W-11 ID-token logout-hint URL exception documented in CONTRACT-NOTES.md. |
| W-09 | 2 | Single-flight renewal code reviewed; six-minute browser renewal/rotation still manual. |
| W-10 | 2 | API origin/path boundary and URL check in Node; one renewal/retry in interceptor; human network inspection required. |
| W-11 | 2 | Library logout clears memory and uses ID-token hint; full Keycloak logout is manual. |
| W-12 | 2 | authGuard/adminGuard, silent extra-scope request, bob refusal panel; browser role walkthrough manual. |
| W-13 | 3 | Shell/skip/nav/account/main/title-focus compiled; keyboard walkthrough manual. |
| W-14 | 3 | Dashboard store getMe/getHealth, two seed teams; screen rendering manual. |
| W-15 | 3 | Teams cursor smoke prints teams: 2; admin CRUD compiled, delete has scope step-up. |
| W-16 | 3 | Team exact-tag edit and paginated member management compiled; last-lead errors handled. Human controls manual. |
| W-17 | 3 | Project form key pattern, create/archive/restore/delete compiled; duplicate-key feedback manual. |
| W-18 | 3 | List/board/filter URL compiled; generated listTasks walks 2,2,1 items to null. |
| W-19 | 3 | Creation retains payload/key until success; phase 4 real replay confirms server support. |
| W-20 | 3 | Edit/complete/reassign/delete via generated operations compiled; browser completion state manual. |
| W-21 | 3 | Comments paging/create/delete compiled; author/lead controls; create loads through final page. Human check manual. |
| W-22 | 3 | Lazy Audit log, scope guard, URL filters/cursors compiled; alice/bob walkthrough manual. |
| W-23 | 4 | Optimistic team/task/project/board snapshots with rollback; exact ETag headers. Human timing/rollback manual. |
| W-24 | 4 | Real stale-tag 412 printed; dialog with retained local patch/server values compiled. Dialog choices manual. |
| W-25 | 4 | Framework-free parser used on real 404/422; JSON Pointer-to-form directive compiled. Field focus manual. |
| W-26 | 4 | Status table/interceptors compiled; canned 429 Retry-After parsed, not a claimed live limiter scenario. |
| W-27 | 4 | RxJS online/offline + failed requests; disabled controls and Actions write gate compiled. DevTools Offline manual. |
| W-28 | 4 | Per-screen WCAG 2.2 checklist; human assessment required, no certification claimed. |
| W-29 | 5 | Production / and /teams 200 with CSP/security headers; deep-link body checked. |
| W-30 | 3 | Fourteen CC0 SVG files/licence copied; thirteen used in phase 3 and conflict alert added phase 4. Accessible names compiled, human check manual. |
| W-31 | 5 | Actual multi-stage docker build, user=101 health=healthy; container 8080. |
| W-32 | 5 | Always cleanup compose down -v --remove-orphans and built images; final inventories recorded. |
| W-33 | 4 | Task-only focus If-None-Match/304 handling compiled; dirty drafts skip it. Human Network check manual. |

## Design limitations
English UI strings remain close to their feature templates rather than an i18n catalogue; translation/localization is out of scope. The small exercise programs practice individual protocol concepts, not copies of the whole application. The inherited Python/SQL/realm fixture is explicitly excluded from line-by-line lesson checks, with source provenance and every Docker configuration shown in full. All newly authored app files are shown in full, even on later edits.
