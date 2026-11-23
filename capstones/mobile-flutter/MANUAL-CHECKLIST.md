# Manual acceptance checklist ? not run

Every checkbox below is **unrun**. A build does not prove a system-browser session, SQLite durability or accessibility.
Keep the Flutter and Kotlin screen names identical: S1 Session check; S2 Login; S3 Teams; S4 Projects; S5 Task list; S6 Task detail; S7 Create or edit task; S8 Conflict sheet; S9 Settings; S10 Sync queue.

## 1. Start a disposable backend session later

First complete the Python backend chapter 05, including its **full** `Dockerfile`, `.dockerignore`, `docker-compose.yml`, `docker-compose.override.yml`, `.env.example`, schema, seed and realm files. Those are existing prerequisite files, not new Flutter configuration; do not reconstruct them from a shortened Compose snippet.
The commands below reuse those exact files unchanged. The only differences from that backend chapter are the disposable project name `mobile-flutter-manual` and making the lock span the whole device session.
Use a fresh terminal at the Code101 repository root. Do not start a second backend or the Kotlin stack on the same ports.

**Terminal: Code101 repository root, Windows PowerShell 5.1**
```powershell
python scripts/stack_lock.py tasksteams -- powershell -NoProfile
```

This opens a child PowerShell and holds the shared lock until you type `exit`. In that child terminal, run:

**Terminal: locked child PowerShell, initially Code101 root**
```powershell
$repo = (Get-Location).Path
$backend = Join-Path $repo 'capstones/backend-python/source/phase-5-hardening/05-hardening/code'
Set-Location $backend
Copy-Item .env.example .env
$project = 'mobile-flutter-manual'
docker compose -p $project up -d --build --wait
docker compose -p $project ps
docker compose -p $project logs --tail 30 api
```

Expected result (not yet run for this checklist): Compose starts the database, Keycloak and Python API. `ps` must show running services; database and Keycloak must be healthy. If startup fails, inspect the displayed logs and **still run cleanup below**. Do not paste token values into issue reports.
The `.env` values are the backend chapter's disposable fake credentials. Leave `KC_HOSTNAME`/issuer at `localhost:8180`; do not change it to the emulator alias.

On macOS/Linux, hold the same lock with `python3 scripts/stack_lock.py tasksteams -- bash` from the repository root. In that child shell:

**Terminal: locked Bash, initially Code101 root**
```bash
repo="$PWD"
backend="$repo/capstones/backend-python/source/phase-5-hardening/05-hardening/code"
cd "$backend"
cp .env.example .env
project=mobile-flutter-manual
docker compose -p "$project" up -d --build --wait
docker compose -p "$project" ps
docker compose -p "$project" logs --tail 30 api
```

Do the device work in another terminal while the lock-holding terminal remains open. Do not start infrastructure from that second terminal.

## 2. Choose a device and URL

- [ ] Install only one mobile twin. Flutter's id is `com.code101.tasks.flutter`; Kotlin's is different, but both receive the same OAuth scheme. Uninstall the other twin before signing in.
- [ ] Use an emulator image with a system browser (for example a Google APIs image with Chrome), or a USB phone with USB debugging authorized. This browser is on Android; the Flutter Doctor desktop-Chrome warning is unrelated.
- [ ] Record whether **you** started the emulator or adb server, so cleanup does not stop someone else's tools.

**Terminal: the chapter's app `code` folder, every OS**
```text
adb devices
adb reverse tcp:8180 tcp:8180
flutter run --dart-define-from-file=config/dev.json
```

Expected behavior (manual, not yet run): `adb devices` lists an authorized device; Flutter launches the app. Emulator API traffic goes to `10.0.2.2:8000`, a host-machine alias. Keycloak goes to `localhost:8180` through the reverse tunnel so its discovery issuer and token issuer remain identical.
For a USB phone, stop Flutter with `q`, then run:

**Terminal: app `code` folder, every OS**
```text
adb reverse tcp:8000 tcp:8000
flutter run --dart-define-from-file=config/usb.json
```

The phone's own `localhost` now reaches both host services. The alias `10.0.2.2` does not work on a physical phone.
The ASP.NET, Python and Go presets deliberately share the configured base URL: stop one backend before selecting the next implementation on port 8000. In Settings choose its label, apply the backend, then Test connection. Use a custom HTTPS URL for a remote deployment. Changing the backend is refused until the outbox is empty.

## 3. S1 Session check and S2 Login ? M-05 to M-09, M-26

- [ ] Cold launch without tokens: S1 goes to S2; canceling the browser returns to Login without treating cancellation as an error.
- [ ] Sign in as `carol`, password `carol-local-fake`, **in the browser only**. Never add a password field or a password grant to the app.
- [ ] Successful PKCE returns to S3 Teams. Inspect the realm's client session outside the app if checking scopes: `openid profile email offline_access tasks:read tasks:write`, no admin scope or client secret.
- [ ] Wait more than six minutes; make another request. A shared refresh should succeed without a second browser login. Check rotation by behavior, never by logging tokens.
- [ ] Revoke the session at the identity provider: the next rejected refresh returns to Login but preserves pending writes.
- [ ] Disconnect from the issuer instead of revoking the session: retain cached screens and the queue. A temporary outage is not proof that the identity is invalid.
- [ ] Exercise the router with an intended task route while signed out; after sign-in it must restore that route rather than always selecting Teams.
- [ ] The manifest registers a **different** task-link scheme, `code101-tasks-flutter://app`, and leaves OAuth callbacks to AppAuth. With the app signed out, run the following later from your device terminal; replace TASK-ID with a visible task UUID: `adb shell am start -a android.intent.action.VIEW -d "code101-tasks-flutter://app/tasks/TASK-ID" com.code101.tasks.flutter`. Sign in and confirm S6 opens. Also test a cold launch, a running app and browser cancellation. This OS-delivery/route-restoration check has not been run.
- [ ] In Settings, sign out without deleting offline data. The browser's Keycloak session must end, tokens must disappear from secure storage, and the queue must survive. If browser logout cannot finish, the app must not claim it ended the provider session.
- [ ] Sign in as the same subject and sync. Try another subject with a nonempty queue: it must not see or send the previous subject's cached work.
- [ ] Sign out again with ?Also delete offline data?; confirm all cached records and pending writes are gone on the next launch.

## 4. S3 Teams, S4 Projects, S5 Task list ? M-10, M-11

- [ ] As alice, Teams includes Platform Team and Mobile Team; as carol, Mobile Team is visible. Test search submission and loading, empty and error states.
- [ ] Open a team, inspect Projects and the archived toggle; return without losing usable navigation.
- [ ] Open a project, filter by two statuses, change sort, pull to refresh, and load another page. The client must send repeated status parameters and copy `page.nextCursor` unchanged.
- [ ] A page size is 25. Seed data alone is smaller than one page: create enough tasks through the backend's documented tools to exercise a second page; do not claim pagination merely because eight seed tasks appeared.

## 5. S6 Task detail, S7 Create or edit task, S8 Conflict sheet ? M-12?M-14, M-16, M-17

- [ ] Confirm every task field, including nullable assignee, due date, completedAt, version and timestamps, is readable.
- [ ] Add a comment and verify it appears at the end. Delete a comment as its author; another ordinary member must not see the author-only delete control.
- [ ] Create with a title length 1?200 and description at most 10000; try an empty title, invalid UUID and impossible date. A comment body must be 1?2000.
- [ ] Double-tap Save and retry one unchanged form: one task should be created. Preserve the idempotency key and body of a dispatched create; never mutate an ambiguous in-flight create.
- [ ] Edit only the due date and then clear it: a changed-fields merge patch must contain `"dueDate": null`, not omit it. The If-Match header is the original version in quotes.
- [ ] Complete a task; status becomes done and completedAt is returned by the server.
- [ ] Edit the same task from two clients. The stale edit must produce 412 and S8. Select mine for one field and theirs for another; the retry must use the latest server version. Taking all theirs drops the local patch.
- [ ] Trigger 422 via the backend's documented validation example. Failed queued tasks must offer Edit, preserve pointer-keyed field errors, and allow correcting a rejected write without changing an already-dispatched idempotent request.
- [ ] Trigger 429 only in a controlled manual session; check both integer and HTTP-date Retry-After forms. A client must not immediately resend before the server's deadline. Unknown problem types show their title, not a raw transport exception.

## 6. S9 Settings and S10 Sync queue ? M-15?M-21

- [ ] Test connection performs `/health` then `/v1/me`; inspect database state, display name, roles and scopes. Backend product labels are presets for the same endpoint, not evidence that all three implementations were exercised.
- [ ] Airplane mode and cold start: cached Teams, Projects and loaded tasks remain readable, even after the access token has expired. Screens read SQLite; a failed network refresh must not erase the cache.
- [ ] Queue one create, edit, complete and comment. Verify the offline banner announces its state and pending count, offers Sync now and opens Sync queue.
- [ ] Force-stop during queuing, relaunch, reconnect: no write should disappear and a replay must not duplicate a create. Repeat the kill-durability check 20 times before making the TDD's durability claim.
- [ ] Queue edits for two entities; park one in conflict. The other entity should drain; the conflicted entity's later writes must wait in order.
- [ ] A synced create changes its temporary UUID to the server id atomically; dependent comments, later writes and cached page membership must follow it.
- [ ] Retry a transient failure, resolve a conflict, and discard an entity chain. ?Discard? here explicitly discards that entity's dependent local changes too; it is not undoing a server write.
- [ ] Leave the app in the background with queued work. WorkManager requests network-constrained work no more often than 15 minutes; the operating system may defer it. Test battery restrictions and secure-storage availability after a reboot. A 15-minute exact deadline is not guaranteed.

## 7. Accessibility and locale ? M-22, M-23

- [ ] Run TalkBack through all ten named screens in reading order; check icon semantics, text labels, error announcements and the offline live region.
- [ ] Use Android Accessibility Scanner: targets at least 48?48 dp and adequate contrast. Never infer this solely from Material defaults.
- [ ] Set font scale to 200%; inspect all form fields, chips, navigation, modal choices and long localized text without clipping.
- [ ] Set a non-English device locale; verify date/number formatting and English ARB fallback. Account names, server content, product names and ids are data, not translated UI labels.
- [ ] Status must remain understandable without color. Check portrait, landscape and keyboard-open layouts.
- [ ] Measure cold-start cached Teams under 2 seconds and first page under 1 second on the specified device profile; no timings are claimed by this delivery.

## 8. Build and ship ? M-03, M-24, M-25

- [ ] Run the chapter's future smoke commands after execution is authorized again. Inspect actual manifests; a text match is not a device network-security test.
- [ ] Build an AAB with **real HTTPS configuration** and a private upload key. `config/release.example.json` is intentionally unusable for contacting a real service.
- [ ] Confirm a release does not accept HTTP and contains no debug networkSecurityConfig.
- [ ] Confirm `android:allowBackup` is false and no token appears in SQLite, preferences, logs, screenshots or crash reports.
- [ ] Search tracked files for key.properties, `.jks` and `.keystore`; none may be tracked. Debug-signed release bundles are NOT FOR STORE.
- [ ] Repeat the happy-path checklist against ASP.NET, Python and Go separately after each backend reports its own conformance result. This delivery does not certify backend interchangeability.

## 9. Always clean up the manual session

Stop Flutter with `q` in its terminal. In the device terminal, remove only the reverse mappings from this session (or all mappings only when it is your dedicated device):

**Terminal: device session terminal, every OS**
```text
adb reverse --remove tcp:8180
adb reverse --remove tcp:8000
```

The second command is needed only if you added the API reverse. Use `adb reverse --remove-all` instead only when no one else owns a mapping.
Stop an emulator you launched through its Android Studio **Device Manager ? Stop** button. If you started a private adb server and no one else uses it, `adb kill-server` stops it; do not kill someone else's session.
In the original lock-holding backend terminal, always run:

**Terminal: locked PowerShell at the backend `code` folder**
```powershell
docker compose -p $project down -v --remove-orphans
docker image rm "$project-api"
Remove-Item .env
exit
```

**Terminal: locked Bash at the backend `code` folder**
```bash
docker compose -p "$project" down -v --remove-orphans
docker image rm "$project-api"
rm .env
exit
```

Expected result (not yet run): the project's containers, project volume and tasksteams network are removed and its built API image is removed; `exit` releases the lock. Keep shared base images unless you deliberately pulled them solely for this session and no other work uses them.
After cleanup, `docker ps -a`, `docker volume ls` and `docker network ls` should contain no resources owned by your manual project. Other agents' unrelated resources must not be deleted.
