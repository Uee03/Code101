# Desktop C glossary

Terms used by the five chapters. All chapters are written (not run).

| Term | Meaning |
|---|---|
| ASan, AddressSanitizer | A compiler feature that checks every memory access at run time and reports overflows, use after free and double free with a stack trace. |
| ASLR | Address space layout randomisation: the program and its libraries load at random addresses, so an attacker cannot hard-code them. |
| Authorization code | A short-lived, single-use value the browser brings back after login; the app exchanges it for tokens. |
| base64url | Base64 with `-` and `_` instead of `+` and `/`, and no `=` padding; safe inside URLs. |
| Baseline (vcpkg) | A commit of the vcpkg ports registry that pins the version of every dependency. |
| Bearer token | A token sent in `Authorization: Bearer ...`; whoever holds it can use it. |
| Borrowed pointer | A pointer to memory somebody else owns; valid only for the stated time and never freed by the borrower. |
| Bounded copy | A copy function that is told the size of the destination and never writes past it (`ts_copy`). |
| Callback (loopback) | The redirect the identity server sends the browser to after login: `http://127.0.0.1:PORT/callback`. |
| Code challenge, code verifier | PKCE pair: the verifier is a random secret kept in the app; the challenge is its SHA-256 hash, sent first. |
| CPack | CMake's packaging tool; here it makes a zip of the install prefix. |
| Conflict view | The part of the form that shows "mine" and "theirs" after a 412. |
| Counted allocator | `ts_malloc` and friends: they count live blocks so a run can end with "outstanding: 0". |
| Discovery document | `/.well-known/openid-configuration`: the identity server's list of endpoints and its issuer. |
| ETag | A quoted version tag of a resource, here the task's version number such as `"3"`. |
| FetchContent | CMake module that downloads a dependency at configure time. |
| FORTIFY_SOURCE | Compiler/libc feature that checks buffer sizes in `memcpy`, `snprintf` and similar calls. |
| Idempotency-Key | A random key on a create request; repeating the request with the same key and body returns the first answer. |
| Immediate mode | A GUI style in which the program describes the whole screen every frame and keeps no widget objects. |
| If-Match | A request header with the version the client saw; a changed resource answers 412. |
| Issuer | The exact address that identifies the identity server's realm; compared as text. |
| Job (`ts_job`) | A heap context plus `run`, `done` and `release` functions that move between the main and the worker thread. |
| JSON Merge Patch | RFC 7396: send only the changed keys; `null` removes a key. |
| Loopback interface | The network address `127.0.0.1`, reachable only from the same computer. |
| Manifest mode | vcpkg reads `vcpkg.json` next to the project and installs exactly those libraries. |
| Move (ownership) | Copying a struct into its new owner and zeroing the old copy so only one side frees it. |
| Nuklear | A single-header C library for immediate-mode graphical user interfaces. |
| Opaque cursor | A page marker the client passes back unchanged and never builds or parses. |
| PKCE | Proof Key for Code Exchange (RFC 7636): makes a stolen authorization code useless. |
| Preset (CMake) | A named set of configure and build options stored in `CMakePresets.json`. |
| Problem details | RFC 9457 error body: `type`, `title`, `status`, `detail`, plus `errors[]` for field problems. |
| RELRO | A linker option that makes parts of the program's tables read-only after start-up. |
| SDL3 | Simple DirectMedia Layer 3: window, input, timers and threads for C programs. |
| Stack protector | A compiler feature that detects a stack buffer overflow before the function returns. |
| State (OAuth) | A random value sent with the sign-in request and checked on the way back. |
| Store | The one struct (`ts_store`) that holds all application state; only the main thread touches it. |
| Stale answer | A response for a selection or filter the person has already left; it is dropped and freed. |
| vcpkg | A C and C++ library manager from Microsoft that builds libraries for your platform. |
| Worker thread | The single background thread that runs blocking network calls. |
