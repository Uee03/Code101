# Mobile Flutter glossary

## ARB
Application Resource Bundle: a JSON-based file holding the English UI messages and localization keys.

## Access token
A short-lived bearer credential sent to the API, never to the screen or database.

## AppAuth
A native OAuth/OIDC library used through flutter_appauth; the password stays in the system browser.

## Application id
The Android install identity; com.code101.tasks.flutter deliberately differs from the Kotlin app.

## AsyncValue
Riverpod?s immutable loading/data/error representation.

## Backoff
An increasing delay between retryable failed attempts; jitter adds a small random delay.

## Cache
A local copy of previously loaded server data; it can be stale and is not an authorization decision.

## Canonical id
The server id resolved from a temporary client-generated UUID after an offline create is accepted.

## Clean room
A temporary source copy with no developer build outputs or machine-local properties.

## Cursor
An opaque server continuation value; copy it to the next request without decoding it.

## Dart define
A compile-time configuration value passed with --dart-define-from-file, not a secret store.

## Deep link
A URL that requests a route directly; Android delivery and a router guard are separate responsibilities.

## Drift
A typed SQLite library whose generated database code is rebuilt from the authored schema.

## ETag
An HTTP entity tag. This contract uses the quoted numeric version, for example "3".

## Feature-first
Keep one feature?s view and ViewModel together instead of grouping every screen in one folder.

## Idempotency key
A stable key for retrying the same create request without producing duplicate server objects.

## If-Match
A request precondition containing the version the user edited; a stale version gets 412.

## Isolate
A separate Dart execution context with its own memory; a background worker does not share foreground Futures.

## JSON Merge Patch
A partial JSON object: absent means unchanged; explicit null clears a nullable property.

## Keystore
Android?s protected storage for encryption keys; tokens are encrypted by flutter_secure_storage.

## Lease
A time-limited claim on draining the outbox; an abandoned claim expires after a crash.

## MVVM
Model?View?ViewModel: widgets present immutable state and delegate commands to a ViewModel.

## Notifier
A Riverpod state owner exposing commands that replace immutable screen state.

## OIDC
OpenID Connect: the identity protocol layered on OAuth that supplies the signed-in subject.

## Outbox
Durable rows describing local writes that still need to reach the server.

## PKCE
Proof Key for Code Exchange: an intercepted authorization code cannot be redeemed without its verifier.

## Problem details
An RFC 9457 error object; a type chooses a message and validation pointers identify fields.

## Refresh rotation
A refresh may invalidate the old refresh token; serialize refresh and persist the replacement first.

## Repository
The data layer?s source of truth for one kind of data; it coordinates services and cache.

## Riverpod
The single state-management and dependency-injection approach used here.

## Semantics
Labels, reading order and live-region announcements exposed to accessibility services.

## Service
A boundary around one external API, native plugin or data source; widgets do not call it directly.

## Smoke check
One small execution showing that an environment and program run; not a unit-test suite or UX approval.

## Source of truth
The place screens read from; from phase 4 it is the SQLite cache, updated by network work.

## Transaction
A group of database changes committed together or rolled back together.

## URL policy
The Dart allow-list permitting only HTTPS or debug-only loopback HTTP.

## WorkManager
Android?s deferred background work scheduler; a 15-minute periodic request is not an exact deadline.

## Write-ahead log
SQLite?s WAL mode, which improves coordination of readers and a writer.

