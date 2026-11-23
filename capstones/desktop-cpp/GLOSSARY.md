# Glossary (desktop-cpp)

| Term | Meaning |
|------|---------|
| RAII | Resource acquisition is initialisation: an object acquires a resource in its constructor and releases it in its destructor |
| vcpkg manifest mode | the project lists its libraries in `vcpkg.json`; vcpkg builds exactly those into the build folder |
| builtin-baseline | a vcpkg commit id that pins the version of every port |
| triplet | the target platform and linkage that vcpkg builds for, for example `x64-windows-static-md` |
| CMake preset | a named set of configure, build, test or package options stored in `CMakePresets.json` |
| immediate-mode GUI | a GUI whose widget code runs every frame and returns "was clicked"; Dear ImGui is one |
| frame loop | the loop that handles events, builds the UI and presents one frame |
| `tl::expected<T, E>` | a value or an error; the C++23 `std::expected` interface for C++20 |
| `Result<T>` | this project's `tl::expected<T, Problem>` |
| Problem | the app's one error type: kind, status, RFC 9457 members, field errors, retry delay |
| RFC 9457 | "problem details for HTTP APIs": `application/problem+json` with `type`, `title`, `status`, `detail` |
| Transport | the interface through which all HTTP goes; the real one uses cpr, tests use a fake |
| `std::jthread` | a thread that joins in its destructor and carries a stop token |
| `std::stop_token` | a cooperative "please stop" signal checked by long-running code |
| UiQueue | the thread-safe mailbox that carries closures from worker threads to the UI thread |
| generation (request id) | a number that makes an old answer recognisable, so it can be dropped |
| PKCE | proof key for code exchange (RFC 7636): a secret verifier whose SHA-256 hash is sent first |
| S256 | the PKCE method that sends BASE64URL(SHA-256(verifier)) |
| loopback redirect | RFC 8252 section 7.3: the browser returns to `http://127.0.0.1:<port>/...` where the app listens |
| public client | an OAuth client that cannot keep a secret, such as a desktop app |
| state | a random value that binds the redirect to the sign-in attempt |
| discovery document | `/.well-known/openid-configuration`, which lists the identity provider's endpoints |
| refresh token rotation | each refresh returns a new refresh token and invalidates the old one |
| Secret | the app's move-only token holder that overwrites its bytes when destroyed |
| ETag and `If-Match` | the version of a resource and the header that says "only change this version" |
| JSON Merge Patch | RFC 7396: send only changed members; `null` removes |
| Idempotency-Key | a client-made key that lets the server recognise a repeated create |
| CPack | CMake's packaging tool; here it makes a ZIP |
| Catch2 | a C++ unit test framework; `TEST_CASE`, `CHECK`, `REQUIRE` |
| test double | a stand-in object (here `FakeTransport`) used in a test instead of the real one |
