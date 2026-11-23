---
track: capstone
level: 201
phase: 5
phase_name: ship
lesson: 05
title: "Hardening and packaging"
time: 90 min
prerequisites: [capstone-desktop-cpp-04]
versions: { cpp: "20", cmake: "3.28+", catch2: "3 (baseline port)", vcpkg_baseline: "9eec002df1cd109f8f104cd966a763daf9751489" }
verified: not yet run
source: capstones/desktop-cpp/source/phase-5-ship/05-hardening-and-packaging/
---

# 05. Hardening and packaging

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## Why it matters
A feature-complete app is not a shippable app. This chapter closes the gaps that bite later: a mistyped or hostile address in the settings, a server that answers with a gigabyte, a title that is only spaces, a log file that nobody can find, no tests that prove the PKCE code is right, and no way to hand the app to another person. Each one is a small piece of code, and most of them are pure functions that a unit test can pin down.

## What you will build
Validated configuration (https or loopback only), a 4 MiB response cap, input validation by Unicode characters, a rotating log file, a Catch2 test suite for the pure logic (RFC test vectors, request building, problem parsing, the pager, the patch, messages, URL rules), and release presets that produce a ZIP with CPack. Requirements: D-21, D-22, D-23, D-24, D-26, D-27, plus a review of D-03 and D-08.

## Predict before you run
(1) Which of the 20 tests would fail if you changed `s256Challenge` to return the verifier unchanged (the "plain" method)? (2) With `API_BASE_URL=http://api.example.com`, what does the app do at start? (3) What is in the ZIP, and what is not? Write your guesses; the answers are in "How it works".

## New C++ in this chapter
- **Unit tests with Catch2**: `TEST_CASE("sentence")` is one test; `CHECK(a == b)` records a failure and goes on, `REQUIRE(...)` stops the test case at the first failure.
- **Test doubles through an interface**: because `ApiClient` takes a `Transport&`, a test passes a `FakeTransport` that records the request and returns a canned answer. No network, no mocking library.
- **`constexpr` constants** (`kMaxTitleChars`) instead of magic numbers; **`std::string_view`** parameters for "read-only text, no copy".
- **UTF-8 in one paragraph**: a character can take 1 to 4 bytes; the bytes of a multi-byte character all start with the bits `10` *except the first*, so counting the bytes that do not start with `10` counts characters.
- **`std::span` brace construction** (`{data, size}`) in the base64 test.

## Before you start
- Chapter 04 snapshot or `desktop-cpp-phase-5-ship.zip`; open `05-hardening-and-packaging/code`.
- No server is needed for the tests; the manual checks need the platform and a backend as before.
- The first configure after changing `vcpkg.json` installs Catch2; the ship preset installs the dependencies again into its own folder.

## What is new, what is unchanged
New: `src/core/Validation.hpp`, `tests/CMakeLists.txt`, `tests/test_pkce.cpp`, `tests/test_api.cpp`, `tests/test_state.cpp`, `tests/test_config.cpp`. Changed: `vcpkg.json`, `CMakePresets.json`, `CMakeLists.txt`, `src/main.cpp`, `src/core/Config.hpp`, `src/net/CprTransport.cpp`, `src/auth/OidcClient.cpp`, `src/app/Controller.cpp`. Unchanged from chapter 04 (copy from the pack): `.gitignore`, `keycloak/tasks-desktop-client.json`, `src/app/Platform.hpp`, `src/app/Theme.hpp`, `src/app/App.hpp`, `src/app/App.cpp`, `src/app/Controller.hpp`, `src/ui/Screens.hpp`, `src/ui/Screens.cpp`, `src/core/Result.hpp`, `src/core/Util.hpp`, `src/core/Concurrency.hpp`, `src/core/ProblemText.hpp`, `src/net/Transport.hpp`, `src/net/CprTransport.hpp`, `src/api/Models.hpp`, `src/api/ApiClient.hpp`, `src/api/ApiClient.cpp`, `src/state/AppState.hpp`, `src/auth/Secret.hpp`, `src/auth/Pkce.hpp`, `src/auth/Pkce.cpp`, `src/auth/LoopbackServer.hpp`, `src/auth/OidcClient.hpp`, `src/auth/Session.hpp`, `src/auth/Session.cpp`. (Chapter 04 lists where each was first shown.)

## Steps
### Step 1. Replace `vcpkg.json`
**File: `vcpkg.json`**
```json
{
  "$schema": "https://raw.githubusercontent.com/microsoft/vcpkg-tool/main/docs/vcpkg.schema.json",
  "name": "tasks-desktop",
  "version": "0.1.0",
  "builtin-baseline": "9eec002df1cd109f8f104cd966a763daf9751489",
  "dependencies": [
    "sdl3",
    { "name": "imgui", "features": ["sdl3-binding", "sdl3-renderer-binding"] },
    "spdlog",
    "cpr",
    "nlohmann-json",
    "tl-expected",
    "openssl",
    "cpp-httplib"
  ],
  "default-features": ["tests"],
  "features": {
    "tests": {
      "description": "Catch2, for the unit tests in tests/",
      "dependencies": ["catch2"]
    }
  }
}
```
A manifest *feature* is an optional group of dependencies. `tests` is a default feature, so a normal configure installs Catch2; the release presets (Step 3) switch the defaults off, so a shipped build never compiles test-only libraries.

### Step 2. Replace `CMakeLists.txt`
**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(tasks_desktop VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

option(TASKS_BUILD_TESTS "Build the Catch2 unit tests (needs the vcpkg feature 'tests')" ON)

find_package(SDL3 CONFIG REQUIRED)
find_package(imgui CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(cpr CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(tl-expected CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(httplib CONFIG REQUIRED)

add_library(tasks_warnings INTERFACE)
target_compile_options(tasks_warnings INTERFACE
    $<$<CXX_COMPILER_ID:MSVC>:/W4 /permissive- /utf-8>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall -Wextra -Wpedantic>)

# Everything that needs neither a window nor Dear ImGui: the unit tests link this library.
add_library(tasks_core STATIC
    src/net/CprTransport.cpp
    src/api/ApiClient.cpp
    src/auth/Pkce.cpp
    src/auth/OidcClient.cpp
    src/auth/Session.cpp)
target_include_directories(tasks_core PUBLIC src)
target_link_libraries(tasks_core PUBLIC tasks_warnings cpr::cpr nlohmann_json::nlohmann_json tl::expected
    spdlog::spdlog OpenSSL::Crypto httplib::httplib)

add_executable(tasks_desktop
    src/main.cpp
    src/app/App.cpp
    src/app/Controller.cpp
    src/ui/Screens.cpp)
target_link_libraries(tasks_desktop PRIVATE tasks_core SDL3::SDL3 imgui::imgui)

if(TASKS_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

# `cpack --preset ship-<os>` makes tasks-desktop-<version>-<system>.zip from a static release build.
install(TARGETS tasks_desktop RUNTIME DESTINATION .)
install(FILES keycloak/tasks-desktop-client.json DESTINATION keycloak)
set(CPACK_PACKAGE_NAME "tasks-desktop")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_FILE_NAME "tasks-desktop-${PROJECT_VERSION}-${CMAKE_SYSTEM_NAME}")
set(CPACK_GENERATOR "ZIP")
include(CPack)
```
New: the `option` and the `tests` subfolder (only when the option is on, because the `Catch2` package exists only with the `tests` feature); `install(...)` says what goes into a package (the program at the top level and the Keycloak client file in a `keycloak` folder); the `CPACK_*` variables name the ZIP; `include(CPack)` adds the packaging step.

### Step 3. Replace `CMakePresets.json`
**File: `CMakePresets.json`**
```json
{
  "version": 6,
  "cmakeMinimumRequired": { "major": 3, "minor": 28, "patch": 0 },
  "configurePresets": [
    {
      "name": "base",
      "hidden": true,
      "binaryDir": "${sourceDir}/build/${presetName}",
      "toolchainFile": "$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
    },
    {
      "name": "windows",
      "displayName": "Windows, Visual Studio generator, static libraries, with tests",
      "inherits": "base",
      "condition": { "type": "equals", "lhs": "${hostSystemName}", "rhs": "Windows" },
      "cacheVariables": { "VCPKG_TARGET_TRIPLET": "x64-windows-static-md" }
    },
    {
      "name": "linux",
      "displayName": "Linux, Ninja Multi-Config, with tests",
      "inherits": "base",
      "generator": "Ninja Multi-Config",
      "condition": { "type": "equals", "lhs": "${hostSystemName}", "rhs": "Linux" },
      "cacheVariables": { "VCPKG_TARGET_TRIPLET": "x64-linux" }
    },
    {
      "name": "macos",
      "displayName": "macOS on Apple silicon, Ninja Multi-Config, with tests",
      "inherits": "base",
      "generator": "Ninja Multi-Config",
      "condition": { "type": "equals", "lhs": "${hostSystemName}", "rhs": "Darwin" },
      "cacheVariables": { "VCPKG_TARGET_TRIPLET": "arm64-osx" }
    },
    {
      "name": "ship-windows",
      "displayName": "Windows release package, no tests",
      "inherits": "windows",
      "cacheVariables": { "TASKS_BUILD_TESTS": "OFF", "VCPKG_MANIFEST_NO_DEFAULT_FEATURES": "ON" }
    },
    {
      "name": "ship-linux",
      "displayName": "Linux release package, no tests",
      "inherits": "linux",
      "cacheVariables": { "TASKS_BUILD_TESTS": "OFF", "VCPKG_MANIFEST_NO_DEFAULT_FEATURES": "ON" }
    },
    {
      "name": "ship-macos",
      "displayName": "macOS release package, no tests",
      "inherits": "macos",
      "cacheVariables": { "TASKS_BUILD_TESTS": "OFF", "VCPKG_MANIFEST_NO_DEFAULT_FEATURES": "ON" }
    }
  ],
  "buildPresets": [
    { "name": "windows-debug", "configurePreset": "windows", "configuration": "Debug" },
    { "name": "windows-release", "configurePreset": "windows", "configuration": "Release" },
    { "name": "linux-debug", "configurePreset": "linux", "configuration": "Debug" },
    { "name": "linux-release", "configurePreset": "linux", "configuration": "Release" },
    { "name": "macos-debug", "configurePreset": "macos", "configuration": "Debug" },
    { "name": "macos-release", "configurePreset": "macos", "configuration": "Release" },
    { "name": "ship-windows", "configurePreset": "ship-windows", "configuration": "Release" },
    { "name": "ship-linux", "configurePreset": "ship-linux", "configuration": "Release" },
    { "name": "ship-macos", "configurePreset": "ship-macos", "configuration": "Release" }
  ],
  "testPresets": [
    { "name": "windows", "configurePreset": "windows", "configuration": "Debug", "output": { "outputOnFailure": true } },
    { "name": "linux", "configurePreset": "linux", "configuration": "Debug", "output": { "outputOnFailure": true } },
    { "name": "macos", "configurePreset": "macos", "configuration": "Debug", "output": { "outputOnFailure": true } }
  ],
  "packagePresets": [
    { "name": "ship-windows", "configurePreset": "ship-windows", "configurations": ["Release"], "generators": ["ZIP"] },
    { "name": "ship-linux", "configurePreset": "ship-linux", "configurations": ["Release"], "generators": ["ZIP"] },
    { "name": "ship-macos", "configurePreset": "ship-macos", "configurations": ["Release"], "generators": ["ZIP"] }
  ]
}
```
Three new kinds of preset. The `ship-*` configure presets *inherit* the dev preset (so they keep the triplet) and switch the tests and the default vcpkg features off. The build presets `ship-*` build Release. `testPresets` run `ctest` for the Debug build and print the output of a failing test. `packagePresets` run CPack for the Release configuration and produce a ZIP. A different build folder per preset (`build/<name>`) keeps the test build and the ship build apart.

### Step 4. Create `src/core/Validation.hpp`
**File: `src/core/Validation.hpp`**
```cpp
#pragma once

#include "core/Result.hpp"

#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

namespace tt {

inline constexpr std::size_t kMaxTitleChars = 200;
inline constexpr std::size_t kMaxDescriptionChars = 10'000;

// The number of Unicode characters in UTF-8 text: every byte that is not a continuation byte (10xxxxxx) starts one.
// The contract counts characters, so 200 letters with accents are fine even though they take 400 bytes.
[[nodiscard]] inline std::size_t utf8Length(std::string_view text) {
    std::size_t count = 0;
    for (const unsigned char c : text) {
        if ((c & 0xC0U) != 0x80U) {
            ++count;
        }
    }
    return count;
}

[[nodiscard]] inline bool isBlank(std::string_view text) {
    return text.find_first_not_of(" \t\r\n") == std::string_view::npos;
}

// Empty means "no due date". Today this only checks the length; the server rejects impossible dates with a 422.
// Exercise: make it check digits, the dashes and the real calendar.
[[nodiscard]] inline bool isValidDueDate(std::string_view text) { return text.empty() || text.size() == 10; }

// The contract's limits as one list of field errors (JSON Pointers into the request body). The server still has the last word.
[[nodiscard]] inline std::vector<FieldError> validateTask(std::string_view title, std::string_view description,
                                                          std::string_view dueDate) {
    std::vector<FieldError> errors;
    if (isBlank(title)) {
        errors.push_back(FieldError{"/title", "Enter a title."});
    } else if (utf8Length(title) > kMaxTitleChars) {
        errors.push_back(FieldError{"/title", "Use at most 200 characters."});
    }
    if (utf8Length(description) > kMaxDescriptionChars) {
        errors.push_back(FieldError{"/description", "Use at most 10000 characters."});
    }
    if (!isValidDueDate(dueDate)) {
        errors.push_back(FieldError{"/dueDate", "Use the format YYYY-MM-DD."});
    }
    return errors;
}

}  // namespace tt
```
Client-side validation is a *convenience*, not security: the server enforces the same limits and has the last word (a 422 still shows next to the field, chapter 04). The checks follow the OpenAPI limits: a title of 1 to 200 characters that is not just spaces, a description of at most 10000 characters. They count *characters* with `utf8Length`, not bytes, which is what the contract means. The due date check is deliberately weak (the exercise strengthens it); this shows that the client and the server can disagree about edge cases, and that the server's 422 must always be handled anyway.

### Step 5. Replace `src/core/Config.hpp`
**File: `src/core/Config.hpp`**
```cpp
#pragma once

#include "core/Result.hpp"
#include "core/Util.hpp"

#include <initializer_list>
#include <string>
#include <string_view>

namespace tt {

struct Config {
    std::string apiBaseUrl;
    std::string issuer;
    std::string clientId{"tasks-desktop"};
    std::string scope{"openid profile email tasks:read tasks:write"};
};

// https anywhere; plain http only for the loopback names. No credentials, query or fragment in the URL.
// A token must never travel in clear text across a network, and "http://localhost.evil.example" is not localhost.
[[nodiscard]] inline bool isAllowedUrl(std::string_view url) {
    const auto schemeEnd = url.find("://");
    if (schemeEnd == std::string_view::npos) {
        return false;
    }
    const std::string_view scheme = url.substr(0, schemeEnd);
    const std::string_view rest = url.substr(schemeEnd + 3);
    if (rest.find_first_of("?#") != std::string_view::npos) {
        return false;
    }
    const std::string_view authority = rest.substr(0, rest.find('/'));
    if (authority.empty() || authority.find('@') != std::string_view::npos) {
        return false;
    }
    std::string_view host = authority;
    if (host.front() == '[') {  // IPv6 literal such as [::1]:8000
        const auto close = host.find(']');
        host = close == std::string_view::npos ? std::string_view{} : host.substr(0, close + 1);
    } else {
        host = host.substr(0, host.find(':'));
    }
    if (host.empty()) {
        return false;
    }
    if (scheme == "https") {
        return true;
    }
    return scheme == "http" && (host == "localhost" || host == "127.0.0.1" || host == "[::1]");
}

[[nodiscard]] inline std::string withoutTrailingSlash(std::string url) {
    while (!url.empty() && url.back() == '/') {
        url.pop_back();
    }
    return url;
}

// Defaults match the platform: API on 8000, Keycloak realm tasksteams on 8180. Both addresses are checked.
[[nodiscard]] inline Result<Config> loadConfig() {
    Config config;
    config.apiBaseUrl = withoutTrailingSlash(envOr("API_BASE_URL", "http://localhost:8000"));
    config.issuer = withoutTrailingSlash(envOr("OIDC_ISSUER", "http://localhost:8180/realms/tasksteams"));
    for (const std::string* url : {&config.apiBaseUrl, &config.issuer}) {
        if (!isAllowedUrl(*url)) {
            return failure(ErrorKind::Config, "Refusing to use this address",
                           *url + " must be https, or http on localhost, 127.0.0.1 or [::1], without credentials, query or fragment.");
        }
    }
    return config;
}

}  // namespace tt
```
`isAllowedUrl` parses just enough of a URL to decide: scheme, then the authority (everything up to the first `/`), then the host inside it. It rejects `user:password@host` (credentials in a URL leak into logs), `?` and `#`, and anything that is not `https` or `http` on a loopback *name that matches exactly*: `http://localhost.evil.example` has the host `localhost.evil.example`, which is not `localhost`. `loadConfig` now returns a `Result<Config>`, so a bad `API_BASE_URL` stops the program at start with a clear message instead of sending tokens to the wrong place. `OidcClient::discover` applies the same rule to the addresses in the discovery document (Step 7).

### Step 6. Replace `src/net/CprTransport.cpp`
**File: `src/net/CprTransport.cpp`**
```cpp
#include "net/CprTransport.hpp"

#include <cpr/cpr.h>
#include <spdlog/spdlog.h>

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <string_view>

namespace tt {
namespace {

constexpr std::size_t kMaxBodyBytes = 4U * 1024U * 1024U;

const char* methodName(Method method) {
    switch (method) {
        case Method::Get: return "GET";
        case Method::Post: return "POST";
        case Method::Put: return "PUT";
        case Method::Patch: return "PATCH";
        case Method::Delete: return "DELETE";
    }
    return "?";
}

cpr::Response perform(cpr::Session& session, Method method) {
    switch (method) {
        case Method::Post: return session.Post();
        case Method::Put: return session.Put();
        case Method::Patch: return session.Patch();
        case Method::Delete: return session.Delete();
        case Method::Get: break;
    }
    return session.Get();
}

}  // namespace

Result<HttpResponse> CprTransport::send(const HttpRequest& request, std::stop_token stop) {
    cpr::Session session;
    session.SetUrl(cpr::Url{request.url});
    cpr::Header headers;
    for (const auto& [name, value] : request.headers) {
        headers[name] = value;
    }
    session.SetHeader(headers);
    session.SetTimeout(cpr::Timeout{request.timeout});
    session.SetConnectTimeout(cpr::ConnectTimeout{std::chrono::milliseconds{3000}});
    session.SetRedirect(cpr::Redirect(false));
    // libcurl calls this regularly during a transfer; returning false aborts it (clean shutdown, cancel).
    session.SetProgressCallback(cpr::ProgressCallback{
        [&stop](auto, auto, auto, auto, std::intptr_t) { return !stop.stop_requested(); }});
    if (!request.body.empty()) {
        session.SetBody(cpr::Body{request.body});
    }

    // The body is collected here, chunk by chunk, so that an oversized answer stops the transfer early.
    std::string body;
    bool tooLarge = false;
    session.SetWriteCallback(cpr::WriteCallback{[&body, &tooLarge](std::string_view chunk, std::intptr_t) {
        if (body.size() + chunk.size() > kMaxBodyBytes) {
            tooLarge = true;
            return false;
        }
        body.append(chunk);
        return true;
    }});

    cpr::Response reply = perform(session, request.method);
    if (tooLarge) {
        return failure(ErrorKind::Network, "The answer is too large", "The server sent more than 4 MiB.");
    }
    if (reply.error.code == cpr::ErrorCode::ABORTED_BY_CALLBACK) {
        return failure(ErrorKind::Cancelled, "Cancelled");
    }
    if (reply.error.code != cpr::ErrorCode::OK) {
        return failure(ErrorKind::Network, "Cannot reach the server", reply.error.message);
    }
    spdlog::debug("{} {} -> {}", methodName(request.method), request.url, reply.status_code);

    HttpResponse response;
    response.status = static_cast<int>(reply.status_code);
    response.body = std::move(body);
    for (const auto& [name, value] : reply.header) {
        response.headers.emplace(name, value);
    }
    return response;
}

}  // namespace tt
```
The new part is the *write callback*: libcurl hands the answer to our function chunk by chunk, so the app sees the size *while* it downloads and stops at 4 MiB (returning `false` aborts the transfer) instead of filling memory first. Because we collect the body ourselves, `reply.text` is not used any more; the headers still come from `reply.header`. Everything else is unchanged from chapter 02.

### Step 7. Replace `src/auth/OidcClient.cpp`
**File: `src/auth/OidcClient.cpp`**
```cpp
#include "auth/OidcClient.hpp"

#include <nlohmann/json.hpp>

namespace tt {
namespace {

constexpr int kDefaultLifetimeSeconds = 60;

Headers formHeaders() {
    return Headers{{"Content-Type", "application/x-www-form-urlencoded"}, {"Accept", "application/json"}};
}

}  // namespace

OidcClient::OidcClient(Config config, Transport& transport) : config_{std::move(config)}, transport_{&transport} {}

Result<Endpoints> OidcClient::discover(std::stop_token stop) const {
    HttpRequest request;
    request.url = config_.issuer + "/.well-known/openid-configuration";
    request.headers = Headers{{"Accept", "application/json"}};
    const auto response = transport_->send(request, stop);
    if (!response) {
        return tl::make_unexpected(response.error());
    }
    if (response->status != 200) {
        return tl::make_unexpected(problemFromResponse(*response));
    }
    const auto document = nlohmann::json::parse(response->body, nullptr, false);
    if (!document.is_object() || jsonString(document, "issuer") != config_.issuer) {
        return failure(ErrorKind::Auth, "Unexpected identity provider",
                       "The discovery document names a different issuer than the configured one.");
    }
    Endpoints endpoints{jsonString(document, "authorization_endpoint"), jsonString(document, "token_endpoint"),
                        jsonString(document, "end_session_endpoint")};
    if (endpoints.authorization.empty() || endpoints.token.empty()) {
        return failure(ErrorKind::Parse, "The discovery document is incomplete");
    }
    // The document comes from the network: its addresses must obey the same rule as our own configuration.
    for (const std::string* url : {&endpoints.authorization, &endpoints.token, &endpoints.endSession}) {
        if (!url->empty() && !isAllowedUrl(*url)) {
            return failure(ErrorKind::Auth, "Unexpected identity provider",
                           "The discovery document points to an address that is neither https nor loopback.");
        }
    }
    return endpoints;
}

std::string OidcClient::authorizationUrl(const Endpoints& endpoints, const std::string& redirectUri,
                                         const Pkce& pkce) const {
    QueryBuilder query;
    query.add("response_type", "code")
        .add("client_id", config_.clientId)
        .add("redirect_uri", redirectUri)
        .add("scope", config_.scope)
        .add("state", pkce.state)
        .add("code_challenge", pkce.challenge)
        .add("code_challenge_method", "S256");
    return endpoints.authorization + "?" + query.str();
}

Result<TokenSet> OidcClient::exchangeCode(const Endpoints& endpoints, const std::string& code,
                                          const std::string& verifier, const std::string& redirectUri,
                                          std::stop_token stop) const {
    QueryBuilder form;
    form.add("grant_type", "authorization_code")
        .add("code", code)
        .add("redirect_uri", redirectUri)
        .add("client_id", config_.clientId)
        .add("code_verifier", verifier);
    return tokenRequest(endpoints, form, stop);
}

Result<TokenSet> OidcClient::refresh(const Endpoints& endpoints, const std::string& refreshToken,
                                     std::stop_token stop) const {
    QueryBuilder form;
    form.add("grant_type", "refresh_token").add("refresh_token", refreshToken).add("client_id", config_.clientId);
    return tokenRequest(endpoints, form, stop);
}

Result<void> OidcClient::endSession(const Endpoints& endpoints, const std::string& refreshToken,
                                    std::stop_token stop) const {
    if (endpoints.endSession.empty()) {
        return {};
    }
    QueryBuilder form;
    form.add("client_id", config_.clientId).add("refresh_token", refreshToken);
    HttpRequest request;
    request.method = Method::Post;
    request.url = endpoints.endSession;
    request.headers = formHeaders();
    request.body = form.str();
    request.timeout = std::chrono::seconds{5};
    const auto response = transport_->send(request, stop);
    if (!response) {
        return tl::make_unexpected(response.error());
    }
    if (response->status < 200 || response->status >= 300) {
        return tl::make_unexpected(problemFromResponse(*response));
    }
    return {};
}

Result<TokenSet> OidcClient::tokenRequest(const Endpoints& endpoints, const QueryBuilder& form,
                                          std::stop_token stop) const {
    HttpRequest request;
    request.method = Method::Post;
    request.url = endpoints.token;
    request.headers = formHeaders();
    request.body = form.str();
    const auto response = transport_->send(request, stop);
    if (!response) {
        return tl::make_unexpected(response.error());
    }
    const auto json = nlohmann::json::parse(response->body, nullptr, false);
    if (response->status != 200) {
        // OAuth errors are {"error": "invalid_grant", "error_description": "..."} (RFC 6749 section 5.2).
        Problem problem = problemFromResponse(*response);
        problem.kind = ErrorKind::Auth;
        problem.title = "Sign-in failed";
        problem.type = "oauth/" + jsonString(json, "error");
        problem.detail = jsonString(json, "error_description");
        return tl::make_unexpected(std::move(problem));
    }
    if (!json.is_object() || jsonString(json, "access_token").empty()) {
        return failure(ErrorKind::Parse, "The identity provider answer was not understood");
    }
    int lifetime = kDefaultLifetimeSeconds;
    if (const auto found = json.find("expires_in"); found != json.end() && found->is_number_integer()) {
        lifetime = found->get<int>();
    }
    TokenSet tokens;
    tokens.access = Secret{jsonString(json, "access_token")};
    tokens.refresh = Secret{jsonString(json, "refresh_token")};
    tokens.accessExpiresAt = std::chrono::steady_clock::now() + std::chrono::seconds{lifetime};
    return tokens;
}

}  // namespace tt
```
The only change is the loop in `discover`: the discovery document is data from the network, so the addresses in it (authorization, token and end-session endpoints) must pass the same `isAllowedUrl` rule as our own configuration. Without it, a compromised or misconfigured identity provider could point the app at a plain-http host and receive the authorization code and the verifier.

### Step 8. Replace `src/app/Controller.cpp`
**File: `src/app/Controller.cpp`**
```cpp
#include "app/Controller.hpp"

#include "auth/Pkce.hpp"
#include "core/Validation.hpp"

#include <spdlog/spdlog.h>

#include <utility>

namespace tt {

Controller::Controller(Config config, Transport& transport, UrlOpener openUrl)
    : session_{config, transport,
               [this, openUrl = std::move(openUrl)](const std::string& url) {
                   // Called on a worker thread: hand the URL to the UI thread, because SDL_OpenURL needs the main thread.
                   ui_.post([this, openUrl, url] {
                       if (!openUrl(url)) {
                           showBrowserFailure(url);
                       }
                   });
                   return true;
               }},
      api_{transport, config.apiBaseUrl, [this](std::stop_token stop) { return session_.accessToken(stop); }} {}

// The pattern behind every operation: compute on a worker thread, apply the result on the UI thread.
template <class Call, class Apply>
void Controller::run(Call call, Apply apply) {
    worker_.submit([this, call = std::move(call), apply = std::move(apply)](std::stop_token stop) {
        auto result = call(stop);  // on a worker thread
        ui_.post([apply, result = std::move(result)]() mutable { apply(std::move(result)); });  // on the UI thread
    });
}

template <class T>
void Controller::applyPage(PagedList<T>& list, std::uint64_t id, Result<Page<T>> result) {
    if (!list.finish(id, std::move(result))) {
        return;  // a newer request replaced this one
    }
    if (list.error) {
        report(*list.error);
    }
}

void Controller::report(Problem problem) {
    if (problem.kind == ErrorKind::Cancelled) {
        return;
    }
    if (problem.status == 401 || problem.kind == ErrorKind::Auth) {
        session_.forget();
        state_.clearSession();
        state_.auth = AuthPhase::SignedOut;
    }
    state_.notice = std::move(problem);
}

void Controller::showBrowserFailure(const std::string& url) {
    Problem problem;
    problem.kind = ErrorKind::Auth;
    problem.title = "Cannot open the browser";
    problem.detail = "Open this address yourself to sign in: " + url;
    state_.notice = std::move(problem);
}

void Controller::signIn() {
    if (state_.auth != AuthPhase::SignedOut) {
        return;
    }
    state_.auth = AuthPhase::SigningIn;
    state_.notice.reset();
    signInStop_ = std::stop_source{};
    worker_.submit(
        [this](std::stop_token stop) {
            auto result = session_.signIn(stop);  // blocks until the browser returns
            ui_.post([this, result = std::move(result)] { onSignedIn(result); });
        },
        signInStop_.get_token());
}

void Controller::cancelSignIn() { signInStop_.request_stop(); }

void Controller::onSignedIn(const Result<void>& result) {
    if (!result) {
        state_.auth = AuthPhase::SignedOut;
        if (result.error().kind != ErrorKind::Cancelled) {
            state_.notice = result.error();
        }
        return;
    }
    state_.auth = AuthPhase::SignedIn;
    loadMe();
    loadTeams(false);
}

void Controller::signOut() {
    cancelSignIn();
    state_.clearSession();
    state_.auth = AuthPhase::SignedOut;
    worker_.submit([this](std::stop_token stop) {
        if (const auto result = session_.signOut(stop); !result) {
            spdlog::warn("sign-out at the identity provider failed: {}", result.error().title);
        }
    });
}

void Controller::loadMe() {
    run([this](std::stop_token stop) { return api_.me(stop); },
        [this](Result<Me> result) {
            if (state_.auth != AuthPhase::SignedIn) {
                return;  // the user signed out while the request was running
            }
            if (!result) {
                report(std::move(result.error()));
                return;
            }
            state_.me = std::move(*result);
        });
}

void Controller::loadTeams(bool more) {
    auto& list = state_.teams;
    if (more && (list.phase == LoadPhase::Loading || !list.nextCursor)) {
        return;
    }
    const std::optional<std::string> cursor = more ? list.nextCursor : std::nullopt;
    const auto id = list.begin(!more);
    run([this, cursor](std::stop_token stop) { return api_.listTeams(cursor, stop); },
        [this, id](Result<Page<Team>> result) { applyPage(state_.teams, id, std::move(result)); });
}

void Controller::selectTeam(const std::string& teamId) {
    state_.teamId = teamId;
    state_.projectId.clear();
    state_.tasks.clear();
    loadProjects(false);
}

void Controller::loadProjects(bool more) {
    auto& list = state_.projects;
    if (state_.teamId.empty() || (more && (list.phase == LoadPhase::Loading || !list.nextCursor))) {
        return;
    }
    const std::optional<std::string> cursor = more ? list.nextCursor : std::nullopt;
    const auto id = list.begin(!more);
    run([this, teamId = state_.teamId, cursor](std::stop_token stop) { return api_.listProjects(teamId, cursor, stop); },
        [this, id](Result<Page<Project>> result) { applyPage(state_.projects, id, std::move(result)); });
}

void Controller::selectProject(const std::string& projectId) {
    state_.projectId = projectId;
    loadTasks(false);
}

void Controller::loadTasks(bool more) {
    auto& list = state_.tasks;
    if (state_.projectId.empty() || (more && (list.phase == LoadPhase::Loading || !list.nextCursor))) {
        return;
    }
    TaskQuery query;
    for (std::size_t i = 0; i < kStatuses.size(); ++i) {
        if (state_.statusFilter[i]) {
            query.statuses.emplace_back(kStatuses[i]);
        }
    }
    query.text = state_.search.data();
    query.sort = kSorts[static_cast<std::size_t>(state_.sortIndex)];
    const std::optional<std::string> cursor = more ? list.nextCursor : std::nullopt;
    const auto id = list.begin(!more);
    run([this, projectId = state_.projectId, query, cursor](std::stop_token stop) {
            return api_.listTasks(projectId, query, cursor, stop);
        },
        [this, id](Result<Page<Task>> result) { applyPage(state_.tasks, id, std::move(result)); });
}

void Controller::openCreateForm() {
    auto& form = state_.form;
    form = TaskForm{};
    form.open = true;
    form.creating = true;
    form.idempotencyKey = randomToken(16).value_or(std::string{});
}

void Controller::openEditForm(const Task& task) {
    auto& form = state_.form;
    form = TaskForm{};
    form.open = true;
    form.creating = false;
    form.taskId = task.id;
    form.baseVersion = task.version;
    form.original = task;
    copyInto(form.title, task.title);
    copyInto(form.description, task.description);
    copyInto(form.dueDate, task.dueDate.value_or(""));
    form.status = indexOf(kStatuses, task.status);
    form.priority = indexOf(kPriorities, task.priority);
}

void Controller::saveForm() {
    auto& form = state_.form;
    if (form.saving) {
        return;
    }
    form.errors = validateTask(form.title.data(), form.description.data(), form.dueDate.data());
    if (!form.errors.empty()) {
        return;
    }
    if (form.creating) {
        form.saving = true;
        run([this, projectId = state_.projectId, body = form.toCreate(), key = form.idempotencyKey](std::stop_token stop) {
                return api_.createTask(projectId, body, key, stop);
            },
            [this](Result<Task> result) { onSaved(std::move(result), std::string{}, nlohmann::json::object()); });
        return;
    }
    const nlohmann::json patch = form.makePatch();
    if (patch.empty()) {
        form.open = false;  // nothing changed, nothing to send
        return;
    }
    form.saving = true;
    run([this, id = form.taskId, version = form.baseVersion, patch](std::stop_token stop) {
            return api_.updateTask(id, version, patch, stop);
        },
        [this, id = form.taskId, patch](Result<Task> result) { onSaved(std::move(result), id, patch); });
}

void Controller::onSaved(Result<Task> result, const std::string& taskId, const nlohmann::json& patch) {
    auto& form = state_.form;
    form.saving = false;
    if (result) {
        form.open = false;
        loadTasks(false);
        return;
    }
    const Problem& problem = result.error();
    if (problem.status == 412 && !taskId.empty()) {
        form.open = false;  // one modal at a time: the conflict dialog takes over
        state_.conflict = Conflict{taskId, form.original.title, patch};
        return;
    }
    if (problem.status == 422 && !problem.errors.empty()) {
        form.errors = problem.errors;  // shown next to the fields
        return;
    }
    report(problem);
}

void Controller::keepMine() {
    auto conflict = std::exchange(state_.conflict, std::nullopt);
    if (!conflict) {
        return;
    }
    // Fetch the current version, then send the same change against it.
    run([this, taskId = conflict->taskId, patch = conflict->patch](std::stop_token stop) -> Result<Task> {
            auto latest = api_.getTask(taskId, stop);
            if (!latest) {
                return latest;
            }
            return api_.updateTask(taskId, latest->version, patch, stop);
        },
        [this, taskId = conflict->taskId, patch = conflict->patch](Result<Task> result) {
            onSaved(std::move(result), taskId, patch);
        });
}

void Controller::dropConflict() {
    state_.conflict.reset();
    loadTasks(false);
}

void Controller::confirmDelete() {
    auto task = std::exchange(state_.pendingDelete, std::nullopt);
    if (!task) {
        return;
    }
    run([this, id = task->id, version = task->version](std::stop_token stop) { return api_.deleteTask(id, version, stop); },
        [this](Result<void> result) {
            if (!result) {
                report(result.error());
            }
            loadTasks(false);
        });
}

}  // namespace tt
```
Two changes from chapter 04: `#include "core/Validation.hpp"` and `saveForm`, where the one-line "empty title" check became `validateTask(...)` over title, description and due date. The messages are keyed by JSON Pointer, so they appear next to the same fields that a server 422 would use.

### Step 9. Replace `src/main.cpp`
**File: `src/main.cpp`**
```cpp
#include "app/App.hpp"
#include "core/Config.hpp"

#include <SDL3/SDL.h>
#include <spdlog/cfg/env.h>
#include <spdlog/sinks/rotating_file_sink.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/spdlog.h>

#include <exception>
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace {

// Console plus a rotating file (1 MiB, three files) in the user's preferences folder.
// Request lines hold method, URL and status only; tokens and bodies are never logged.
void initLogging() {
    std::vector<spdlog::sink_ptr> sinks{std::make_shared<spdlog::sinks::stdout_color_sink_mt>()};
    const std::unique_ptr<char, decltype(&SDL_free)> folder{SDL_GetPrefPath("code101", "tasks-desktop"), &SDL_free};
    if (folder) {
        try {
            sinks.push_back(std::make_shared<spdlog::sinks::rotating_file_sink_mt>(std::string{folder.get()} + "tasks.log",
                                                                                   1024U * 1024U, 3U));
        } catch (const spdlog::spdlog_ex&) {
            // No log file: the console sink is enough.
        }
    }
    auto logger = std::make_shared<spdlog::logger>("tasks", sinks.begin(), sinks.end());
    logger->set_pattern("%Y-%m-%d %H:%M:%S.%e [%^%l%$] %v");
    logger->flush_on(spdlog::level::warn);
    spdlog::set_default_logger(std::move(logger));
    spdlog::cfg::load_env_levels();
}

}  // namespace

int main() {
    try {
        initLogging();
        auto config = tt::loadConfig();
        if (!config) {
            spdlog::critical("{}: {}", config.error().title, config.error().detail);
            return 2;
        }
        spdlog::info("Tasks and Teams desktop starting, API at {}", config->apiBaseUrl);
        tt::App app{std::move(*config)};
        const int exitCode = app.run();
        spdlog::info("clean shutdown");
        spdlog::shutdown();
        return exitCode;
    } catch (const std::exception& error) {
        spdlog::critical("fatal: {}", error.what());
        return 1;
    }
}
```
`SDL_GetPrefPath("code101", "tasks-desktop")` returns the per-user folder where an app should keep its files (on Windows under `%APPDATA%`, on Linux under `~/.local/share`, on macOS under `~/Library/Application Support`); SDL allocates the string, so the `unique_ptr` with `SDL_free` as deleter frees it (RAII again). A bad configuration ends with exit code 2 and a log line; a start-up exception ends with 1. `load_env_levels` still honours `SPDLOG_LEVEL`. What is logged: the API address at start, method, URL and status of each request at debug level, and the words "signed in" and "clean shutdown". What is never logged: tokens, authorization codes, request or response bodies, passwords.

### Step 10. Create `tests/CMakeLists.txt`
**File: `tests/CMakeLists.txt`**
```cmake
find_package(Catch2 3 CONFIG REQUIRED)
include(Catch)

# Every tests/test_*.cpp file is picked up; add a file and re-run cmake (CONFIGURE_DEPENDS also re-checks at build time).
file(GLOB TEST_SOURCES CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/test_*.cpp)

add_executable(tasks_tests ${TEST_SOURCES})
target_link_libraries(tasks_tests PRIVATE tasks_core Catch2::Catch2WithMain)
catch_discover_tests(tasks_tests)
```
`Catch2::Catch2WithMain` supplies `main`, so test files contain only test cases. `catch_discover_tests` asks the finished executable for its list of test cases and registers each one with CTest, so `ctest` runs and reports them one by one. `file(GLOB ... CONFIGURE_DEPENDS)` means "every `test_*.cpp`", which is why the exercise can add a file without editing CMake.

### Step 11. Create `tests/test_pkce.cpp`
**File: `tests/test_pkce.cpp`**
```cpp
#include "auth/Pkce.hpp"
#include "auth/Secret.hpp"

#include <catch2/catch_test_macros.hpp>

#include <string>
#include <string_view>
#include <utility>

namespace {

std::string encode(std::string_view text) {
    const auto* data = reinterpret_cast<const unsigned char*>(text.data());
    return tt::base64UrlEncode({data, text.size()});
}

}  // namespace

TEST_CASE("base64url has no padding and uses - and _ (RFC 4648 examples)") {
    CHECK(encode("").empty());
    CHECK(encode("f") == "Zg");
    CHECK(encode("fo") == "Zm8");
    CHECK(encode("foo") == "Zm9v");
    CHECK(encode("foobar") == "Zm9vYmFy");
    const unsigned char bytes[] = {0xFB, 0xFF};
    CHECK(tt::base64UrlEncode(bytes) == "-_8");
}

TEST_CASE("the S256 challenge matches the example of RFC 7636 appendix B") {
    const auto challenge = tt::s256Challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk");
    REQUIRE(challenge.has_value());
    CHECK(*challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM");
}

TEST_CASE("makePkce gives a 43 character verifier, a matching challenge and a fresh state") {
    const auto first = tt::makePkce();
    const auto second = tt::makePkce();
    REQUIRE(first.has_value());
    REQUIRE(second.has_value());
    CHECK(first->verifier.size() == 43);
    CHECK(first->verifier != second->verifier);
    CHECK(first->state != second->state);
    CHECK(tt::s256Challenge(first->verifier).value() == first->challenge);
}

TEST_CASE("a moved Secret leaves nothing behind") {
    tt::Secret first{"token-value"};
    tt::Secret second{std::move(first)};
    CHECK(first.empty());
    CHECK(second.reveal() == "token-value");
}
```
The standard's own examples are the best tests for security code: the RFC 4648 vectors prove the encoder, and the RFC 7636 appendix B pair (verifier and challenge) proves the whole S256 path, *including* the OpenSSL call. `0xFB 0xFF` is chosen because its base64 would contain `+` and `/`; base64url must show `-` and `_`. The last test documents the contract of the `Secret` move.

### Step 12. Create `tests/test_api.cpp`
**File: `tests/test_api.cpp`**
```cpp
#include "api/ApiClient.hpp"

#include <catch2/catch_test_macros.hpp>

#include <optional>
#include <stop_token>
#include <string>

namespace {

// Records the last request and answers with whatever `reply` holds.
class FakeTransport final : public tt::Transport {
public:
    tt::Result<tt::HttpResponse> send(const tt::HttpRequest& request, std::stop_token) override {
        last = request;
        return reply;
    }

    tt::HttpRequest last;
    tt::Result<tt::HttpResponse> reply{tt::HttpResponse{200, "{}", {}}};
};

std::string headerOf(const tt::HttpRequest& request, const std::string& name) {
    for (const auto& [key, value] : request.headers) {
        if (key == name) {
            return value;
        }
    }
    return {};
}

constexpr const char* kTaskJson =
    R"({"id":"t1","projectId":"p1","title":"Write","description":"","status":"todo","priority":"low",)"
    R"("assigneeId":null,"dueDate":null,"version":4,"updatedAt":"2026-01-01T00:00:00Z"})";

tt::ApiClient makeClient(FakeTransport& http) {
    return tt::ApiClient{http, "http://localhost:8000",
                         [](std::stop_token) { return tt::Result<std::string>(std::string{"tok"}); }};
}

}  // namespace

TEST_CASE("updateTask sends If-Match with the quoted version and a merge patch") {
    FakeTransport http;
    http.reply = tt::HttpResponse{200, kTaskJson, {}};
    const auto api = makeClient(http);
    nlohmann::json patch = nlohmann::json::object();
    patch["dueDate"] = nullptr;

    const auto result = api.updateTask("t1", 3, patch);

    REQUIRE(result.has_value());
    CHECK(result->version == 4);
    CHECK(http.last.method == tt::Method::Patch);
    CHECK(http.last.url == "http://localhost:8000/v1/tasks/t1");
    CHECK(headerOf(http.last, "If-Match") == "\"3\"");
    CHECK(headerOf(http.last, "Content-Type") == "application/merge-patch+json");
    CHECK(headerOf(http.last, "Authorization") == "Bearer tok");
    CHECK(http.last.body == R"({"dueDate":null})");
}

TEST_CASE("createTask sends the Idempotency-Key it was given") {
    FakeTransport http;
    http.reply = tt::HttpResponse{201, kTaskJson, {}};
    const auto api = makeClient(http);
    tt::TaskCreate body;
    body.title = "Write";

    const auto result = api.createTask("p1", body, "key-1234567890");

    REQUIRE(result.has_value());
    CHECK(http.last.method == tt::Method::Post);
    CHECK(headerOf(http.last, "Idempotency-Key") == "key-1234567890");
}

TEST_CASE("deleteTask sends If-Match") {
    FakeTransport http;
    http.reply = tt::HttpResponse{204, "", {}};
    const auto api = makeClient(http);

    const auto result = api.deleteTask("t1", 7);

    REQUIRE(result.has_value());
    CHECK(http.last.method == tt::Method::Delete);
    CHECK(headerOf(http.last, "If-Match") == "\"7\"");
}

TEST_CASE("listTasks repeats status, encodes the search text and copies the cursor") {
    FakeTransport http;
    http.reply = tt::HttpResponse{200, R"({"items":[],"page":{"limit":25,"nextCursor":null}})", {}};
    const auto api = makeClient(http);
    tt::TaskQuery query;
    query.statuses = {"todo", "blocked"};
    query.text = "a b";

    const auto page = api.listTasks("p1", query, std::optional<std::string>{"abc"});

    REQUIRE(page.has_value());
    CHECK_FALSE(page->nextCursor.has_value());
    CHECK(http.last.url ==
          "http://localhost:8000/v1/projects/p1/tasks?limit=25&sort=-createdAt&status=todo&status=blocked&q=a%20b&cursor=abc");
}

TEST_CASE("a 412 answer becomes a Problem with its RFC 9457 members") {
    FakeTransport http;
    http.reply = tt::HttpResponse{
        412,
        R"({"type":"https://code101.example/problems/precondition-failed","title":"Precondition failed",)"
        R"("status":412,"detail":"stale","traceId":"abc"})",
        {}};
    const auto api = makeClient(http);

    const auto result = api.updateTask("t1", 1, nlohmann::json::object());

    REQUIRE_FALSE(result.has_value());
    CHECK(result.error().kind == tt::ErrorKind::Http);
    CHECK(result.error().status == 412);
    CHECK(tt::problemSlug(result.error()) == "precondition-failed");
    CHECK(result.error().traceId == "abc");
}

TEST_CASE("a 429 answer keeps Retry-After") {
    FakeTransport http;
    tt::HttpResponse response{429, "{}", {}};
    response.headers.emplace("retry-after", "7");
    http.reply = response;
    const auto api = makeClient(http);

    const auto result = api.getTask("t1");

    REQUIRE_FALSE(result.has_value());
    CHECK(result.error().retryAfterSeconds == std::optional<int>{7});
}

TEST_CASE("an answer of the wrong shape is a Parse problem, not a crash") {
    FakeTransport http;
    http.reply = tt::HttpResponse{200, R"({"id":1})", {}};
    const auto api = makeClient(http);

    const auto result = api.getTask("t1");

    REQUIRE_FALSE(result.has_value());
    CHECK(result.error().kind == tt::ErrorKind::Parse);
}

TEST_CASE("a transport failure is passed on as a Network problem") {
    FakeTransport http;
    http.reply = tt::failure(tt::ErrorKind::Network, "down");
    const auto api = makeClient(http);

    const auto result = api.me();

    REQUIRE_FALSE(result.has_value());
    CHECK(result.error().kind == tt::ErrorKind::Network);
}
```
`FakeTransport` is a *test double*: the same interface as the real transport, but it records the last request and returns a canned reply. Thanks to the `Transport` interface of chapter 02, the whole API layer is tested without a network. Notice what the tests pin down: the quoted `If-Match`, the Merge Patch content type, the explicit `null`, the idempotency header, the exact query string (including the encoded space and the repeated `status`), RFC 9457 parsing, the case-insensitive header lookup (`retry-after` stored, `Retry-After` read), and that malformed data becomes a `Parse` problem.

### Step 13. Create `tests/test_state.cpp`
**File: `tests/test_state.cpp`**
```cpp
#include "core/ProblemText.hpp"
#include "core/Validation.hpp"
#include "state/AppState.hpp"

#include <catch2/catch_test_macros.hpp>

#include <string>

namespace {

tt::Result<tt::Page<tt::Team>> pageWith(const char* id, const char* nextCursor = nullptr) {
    tt::Page<tt::Team> page;
    page.items.push_back(tt::Team{id, "name", "", 1, 1});
    if (nextCursor != nullptr) {
        page.nextCursor = std::string{nextCursor};
    }
    return page;
}

}  // namespace

TEST_CASE("an answer for a superseded request is dropped") {
    tt::PagedList<tt::Team> list;
    const auto first = list.begin(true);
    const auto second = list.begin(true);

    CHECK_FALSE(list.finish(first, pageWith("old")));
    CHECK(list.items.empty());
    CHECK(list.finish(second, pageWith("new")));
    REQUIRE(list.items.size() == 1);
    CHECK(list.items.front().id == "new");
    CHECK(list.phase == tt::LoadPhase::Ready);
}

TEST_CASE("load more appends, a fresh load starts again, clear makes answers stale") {
    tt::PagedList<tt::Team> list;
    REQUIRE(list.finish(list.begin(true), pageWith("a", "cursor-1")));
    REQUIRE(list.nextCursor.has_value());

    REQUIRE(list.finish(list.begin(false), pageWith("b")));
    CHECK(list.items.size() == 2);
    CHECK_FALSE(list.nextCursor.has_value());

    const auto inFlight = list.begin(true);
    list.clear();
    CHECK_FALSE(list.finish(inFlight, pageWith("late")));
    CHECK(list.items.empty());
}

TEST_CASE("a failed request is kept as the list's error") {
    tt::PagedList<tt::Team> list;
    const auto id = list.begin(true);

    REQUIRE(list.finish(id, tt::failure(tt::ErrorKind::Network, "down")));

    CHECK(list.phase == tt::LoadPhase::Failed);
    REQUIRE(list.error.has_value());
    CHECK(list.error->kind == tt::ErrorKind::Network);
}

TEST_CASE("makePatch holds only changed fields and null clears the due date") {
    tt::TaskForm form;
    form.original.title = "Write";
    form.original.status = "todo";
    form.original.priority = "medium";
    form.original.dueDate = "2026-12-01";
    tt::copyInto(form.title, "Write");
    tt::copyInto(form.dueDate, "2026-12-01");
    form.status = 0;    // todo
    form.priority = 1;  // medium
    CHECK(form.makePatch().empty());

    tt::copyInto(form.title, "Write more");
    CHECK(form.makePatch().size() == 1);
    CHECK(form.makePatch().at("title") == "Write more");

    tt::copyInto(form.dueDate, "");
    const auto patch = form.makePatch();
    REQUIRE(patch.contains("dueDate"));
    CHECK(patch.at("dueDate").is_null());
}

TEST_CASE("userMessage chooses by problem type and falls back to the title") {
    tt::Problem problem;
    problem.kind = tt::ErrorKind::Http;
    problem.status = 412;
    problem.title = "Something else";
    problem.type = "https://code101.example/problems/precondition-failed";
    CHECK(tt::userMessage(problem) == "Someone else changed this item. Reload it and try again.");

    problem.type = "https://code101.example/problems/new-kind-of-problem";
    CHECK(tt::userMessage(problem) == "Something else");

    problem.type = "https://code101.example/problems/rate-limited";
    problem.retryAfterSeconds = 7;
    CHECK(tt::userMessage(problem) == "Too many requests. Try again in 7 seconds.");
}

TEST_CASE("validateTask counts characters, not bytes") {
    CHECK(tt::validateTask("", "", "").size() == 1);
    CHECK(tt::validateTask("   ", "", "").size() == 1);
    CHECK(tt::validateTask(std::string(200, 'a'), "", "").empty());
    CHECK(tt::validateTask(std::string(201, 'a'), "", "").size() == 1);

    std::string accents;
    for (int i = 0; i < 200; ++i) {
        accents += "\xC3\xA9";  // 200 characters, 400 bytes
    }
    CHECK(tt::validateTask(accents, "", "").empty());
    CHECK(tt::validateTask("title", std::string(10'001, 'a'), "").size() == 1);
    CHECK(tt::validateTask("title", "", "2026-12-01").empty());
    CHECK(tt::validateTask("title", "", "2026-1").size() == 1);
}
```
These tests exist because the logic lives in plain structs (chapter 04): no window, no thread, no network. The pager tests are the proof of "no stale answers"; the patch test is the proof of "only changed fields, null clears"; the message test proves that the *type* beats the *title*; the validation test proves that 200 accented letters are allowed although they take 400 bytes.

### Step 14. Create `tests/test_config.cpp`
**File: `tests/test_config.cpp`**
```cpp
#include "core/Config.hpp"

#include <catch2/catch_test_macros.hpp>

TEST_CASE("isAllowedUrl accepts https and loopback http only") {
    CHECK(tt::isAllowedUrl("https://api.example.com"));
    CHECK(tt::isAllowedUrl("https://api.example.com:8443/v1"));
    CHECK(tt::isAllowedUrl("http://localhost:8000"));
    CHECK(tt::isAllowedUrl("http://127.0.0.1:8180/realms/tasksteams"));
    CHECK(tt::isAllowedUrl("http://[::1]:8000"));

    CHECK_FALSE(tt::isAllowedUrl("http://api.example.com"));
    CHECK_FALSE(tt::isAllowedUrl("http://localhost.evil.example"));
    CHECK_FALSE(tt::isAllowedUrl("https://user:secret@api.example.com"));
    CHECK_FALSE(tt::isAllowedUrl("https://api.example.com/?debug=1"));
    CHECK_FALSE(tt::isAllowedUrl("https://api.example.com/#top"));
    CHECK_FALSE(tt::isAllowedUrl("ftp://localhost"));
    CHECK_FALSE(tt::isAllowedUrl("localhost:8000"));
    CHECK_FALSE(tt::isAllowedUrl("https://"));
    CHECK_FALSE(tt::isAllowedUrl(""));
}

TEST_CASE("withoutTrailingSlash removes every closing slash") {
    CHECK(tt::withoutTrailingSlash("http://localhost:8000/") == "http://localhost:8000");
    CHECK(tt::withoutTrailingSlash("http://localhost:8000") == "http://localhost:8000");
}
```
The second half of the first test lists the attacks: plain http to a real host, a host that merely *starts with* `localhost`, credentials in the URL, a query or fragment, a wrong scheme, a missing scheme and empty input.

### Step 15. Unchanged files
All other files are identical to chapter 04.

## Run it
**For a later session only; this snapshot has not been run.** The tests need no server.

**Command (Windows, PowerShell):**
```powershell
cmake --preset windows
cmake --build --preset windows-debug
ctest --preset windows
```
**Command (Linux and macOS):** the same with `linux` or `macos`. Typical output of the last command: one line per test case with `Passed`, ending with `100% tests passed, 0 tests failed out of 20` (the number is the count of `TEST_CASE`s in the four files: 4 + 8 + 6 + 2). A failing check prints Catch2's message with the expression and both values.

Then the manual security checks:
1. `API_BASE_URL=http://api.example.com` (PowerShell: `$env:API_BASE_URL = "http://api.example.com"`) and start the app: typical result is a `critical` log line `Refusing to use this address: ...` and exit code 2; no window.
2. Start normally, sign in, then open the log file in the folder that `SDL_GetPrefPath("code101", "tasks-desktop")` names (on Windows typically under `%APPDATA%\code101\tasks-desktop`). Search it for a token: a `Bearer ` or `eyJ` search must find nothing.
3. Type 201 letters into a title: "Use at most 200 characters." appears and no request is sent.

**Package.**

**Command (Windows, PowerShell):**
```powershell
cmake --preset ship-windows
cmake --build --preset ship-windows
cpack --preset ship-windows
```
Typical result: `build\ship-windows\tasks-desktop-0.1.0-Windows.zip`, holding `tasks_desktop.exe` and `keycloak\tasks-desktop-client.json`. (Linux and macOS: the `ship-linux` or `ship-macos` presets.)

## How it works
- **Prediction answers.** (1) Only the RFC 7636 appendix B test fails (the challenge would not match the published one); the `makePkce` test compares the function with itself and still passes, and the other 18 pass. This is what a known-answer test is for. (2) `loadConfig` returns a `Config` problem, `main` logs `Refusing to use this address` and returns 2 before any window or thread exists. (3) In the ZIP: the executable and the Keycloak client file. Not in it: the tests, the vcpkg folders, the log files, any token, the `.env` of the platform, or any Dear ImGui settings file (`IniFilename` is off).
- **Defence in depth, one layer at a time.** URL policy at start and on the discovery document; no redirects; TLS verification; a response cap; client-side validation for comfort and the server's 422 for truth; tokens in `Secret` and nowhere on disk; logs without bodies and tokens; `Host` and `state` checks on the loopback listener.
- **Why unit tests only cover pure logic.** Windows, sockets and browsers are expensive to test and flaky; PKCE, request building, parsing, paging and validation are cheap and are where subtle bugs hide. The seams that made this possible are decisions of earlier chapters: the `Transport` interface, `Result<T>`, `PagedList`, header-only state.
- **Static linking and the package.** The `static-md` triplet links libraries statically and the C++ runtime dynamically, so the target machine needs the Microsoft Visual C++ Redistributable; the static CRT triplet (`x64-windows-static`) removes that need at the cost of a larger file. Linux executables still depend on the system's C library and display libraries; macOS binaries run on the same OS version and architecture family they were built for.

### What a real release adds (named, not taught)
| Topic | Why | Where to read |
|-------|-----|---------------|
| Code signing and notarisation | Windows SmartScreen and macOS Gatekeeper warn about unsigned programs | Microsoft Authenticode and Apple notarisation documentation |
| Linux packaging | A ZIP does not install icons, menu entries or dependencies | AppImage, Flatpak or a distribution package |
| OS secret store for the refresh token | The app asks the user to sign in after every start | Windows Credential Manager, macOS Keychain, Linux Secret Service (libsecret) |
| Crash reports | Crash dumps can contain tokens in memory | decide what to collect and where to send it; never attach memory dumps without consent |
| Updates | Fixed vulnerabilities must reach users | a signed update channel; do not invent your own cryptography |
| Third-party licences | Static linking requires the notices of SDL, Dear ImGui, libcurl, OpenSSL and the rest | `vcpkg` copies each port's licence into `vcpkg_installed/.../share/<port>/copyright` |
| Dependency updates | A pinned baseline does not receive security fixes | change `builtin-baseline` on purpose, rebuild, run the tests |
| Accessibility | Dear ImGui has no screen-reader support | a native UI toolkit for products that need it |

## Try it
Make the due-date check strict and let the tests prove it. Two files: `src/core/Validation.hpp` and `tests/test_validation.cpp`.

Where: the `code` folder.

**Command (Windows, PowerShell):**
```powershell
Copy-Item ..\exercise\starter\src\core\Validation.hpp src\core\Validation.hpp -Force
Copy-Item ..\exercise\starter\tests\test_validation.cpp tests\test_validation.cpp -Force
cmake --preset windows
cmake --build --preset windows-debug
ctest --preset windows
```
**Command (macOS and Linux):**
```bash
cp ../exercise/starter/src/core/Validation.hpp src/core/Validation.hpp
cp ../exercise/starter/tests/test_validation.cpp tests/test_validation.cpp
cmake --preset linux && cmake --build --preset linux-debug && ctest --preset linux
```
(Use `macos` on macOS.) The starter's test file fails on purpose until `isValidDueDate` is implemented: that is rung 1 (run it and read the failures). Rung 2: digits and dashes. Rung 3: real calendar dates. The starter `Validation.hpp` is the file from Step 4 with a longer comment on `isValidDueDate`, and the starter test file is:

**File: `../exercise/starter/tests/test_validation.cpp`**
```cpp
#include "core/Validation.hpp"

#include <catch2/catch_test_macros.hpp>

TEST_CASE("isValidDueDate accepts empty and real calendar dates") {
    CHECK(tt::isValidDueDate(""));
    CHECK(tt::isValidDueDate("2026-12-01"));
    CHECK(tt::isValidDueDate("2028-02-29"));  // 2028 is a leap year
}

TEST_CASE("isValidDueDate rejects shapes and dates that do not exist") {
    CHECK_FALSE(tt::isValidDueDate("2026-02-29"));  // 2026 is not a leap year
    CHECK_FALSE(tt::isValidDueDate("2026-13-01"));
    CHECK_FALSE(tt::isValidDueDate("2026-00-10"));
    CHECK_FALSE(tt::isValidDueDate("2026-12-32"));
    CHECK_FALSE(tt::isValidDueDate("2026/12/01"));
    CHECK_FALSE(tt::isValidDueDate("12/01/2026"));
    CHECK_FALSE(tt::isValidDueDate("2026-1-01"));
    CHECK_FALSE(tt::isValidDueDate("abcd-ef-gh"));
}

TEST_CASE("validateTask reports a bad due date next to the field") {
    const auto errors = tt::validateTask("title", "", "2026-13-45");
    REQUIRE(errors.size() == 1);
    CHECK(errors.front().pointer == "/dueDate");
}
```
<details><summary>Solution</summary>

**File: `../exercise/solution/src/core/Validation.hpp`**
```cpp
#pragma once

#include "core/Result.hpp"

#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

namespace tt {

inline constexpr std::size_t kMaxTitleChars = 200;
inline constexpr std::size_t kMaxDescriptionChars = 10'000;

// The number of Unicode characters in UTF-8 text: every byte that is not a continuation byte (10xxxxxx) starts one.
// The contract counts characters, so 200 letters with accents are fine even though they take 400 bytes.
[[nodiscard]] inline std::size_t utf8Length(std::string_view text) {
    std::size_t count = 0;
    for (const unsigned char c : text) {
        if ((c & 0xC0U) != 0x80U) {
            ++count;
        }
    }
    return count;
}

[[nodiscard]] inline bool isBlank(std::string_view text) {
    return text.find_first_not_of(" \t\r\n") == std::string_view::npos;
}

// Empty means "no due date". Otherwise YYYY-MM-DD with a real calendar date (leap years included).
[[nodiscard]] inline bool isValidDueDate(std::string_view text) {
    if (text.empty()) {
        return true;
    }
    if (text.size() != 10 || text[4] != '-' || text[7] != '-') {
        return false;
    }
    const auto number = [&text](std::size_t from, std::size_t count) {
        int value = 0;
        for (std::size_t i = from; i < from + count; ++i) {
            if (text[i] < '0' || text[i] > '9') {
                return -1;
            }
            value = value * 10 + (text[i] - '0');
        }
        return value;
    };
    const int year = number(0, 4);
    const int month = number(5, 2);
    const int day = number(8, 2);
    if (year < 1 || month < 1 || month > 12 || day < 1) {
        return false;
    }
    static constexpr int kDays[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    const bool leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    const int limit = (month == 2 && leap) ? 29 : kDays[month - 1];
    return day <= limit;
}

// The contract's limits as one list of field errors (JSON Pointers into the request body). The server still has the last word.
[[nodiscard]] inline std::vector<FieldError> validateTask(std::string_view title, std::string_view description,
                                                          std::string_view dueDate) {
    std::vector<FieldError> errors;
    if (isBlank(title)) {
        errors.push_back(FieldError{"/title", "Enter a title."});
    } else if (utf8Length(title) > kMaxTitleChars) {
        errors.push_back(FieldError{"/title", "Use at most 200 characters."});
    }
    if (utf8Length(description) > kMaxDescriptionChars) {
        errors.push_back(FieldError{"/description", "Use at most 10000 characters."});
    }
    if (!isValidDueDate(dueDate)) {
        errors.push_back(FieldError{"/dueDate", "Use the format YYYY-MM-DD."});
    }
    return errors;
}

}  // namespace tt
```
The solution's `tests/test_validation.cpp` is identical to the starter's (the tests are the specification). The lambda `number` returns `-1` for a non-digit, so one range check handles every malformed field; the leap-year rule is "divisible by 4, except centuries, except every fourth century".

</details>

## Check yourself
1. Why test with the RFC's own example values?
   <details><summary>Answer</summary>They are independent, published right answers; a test written from the code's own output could encode the same mistake.</details>
2. Why does `isAllowedUrl("http://localhost.evil.example")` return false?
   <details><summary>Answer</summary>The check compares the whole host with `localhost`; it does not look for a prefix.</details>
3. Why does the ship preset switch the default vcpkg features off?
   <details><summary>Answer</summary>So that test-only libraries (Catch2) are not built or shipped in a release.</details>
4. What does the write callback buy compared with checking `reply.text.size()` afterwards?
   <details><summary>Answer</summary>The transfer stops as soon as the limit is crossed; checking afterwards would have downloaded and stored everything first.</details>
5. Which requirement does an unsigned executable still violate in a real release?
   <details><summary>Answer</summary>None of D-01 to D-27 (signing is out of scope), but users will see operating-system warnings; the table above names the work.</details>

## Common mistakes
| Symptom (typical message) | Cause | Fix |
|---|---|---|
| `Could not find a package configuration file provided by "Catch2"` | configured with the ship preset's features but `TASKS_BUILD_TESTS` on, or the `tests` feature missing | use the dev presets for tests; `ship-*` turn both off |
| `ctest` says `No tests were found` | tests not built yet | run `cmake --build --preset <os>-debug` before `ctest` |
| A new `test_*.cpp` is ignored | CMake was not re-run | run `cmake --preset <os>` again |
| `include(Catch)` fails | Catch2 not found first | `find_package(Catch2 3 CONFIG REQUIRED)` must come before it |
| Exit code 2 at start | `API_BASE_URL` or `OIDC_ISSUER` rejected | use https or `http://localhost`, no query, no credentials |
| The log folder is empty | `SDL_GetPrefPath` failed (read-only profile) | the console sink still works; fix the folder permissions |
| ZIP missing | `cpack` was run before the Release build | run the `ship-*` build preset first |
| The program does not start on another PC (Windows) | Visual C++ Redistributable missing | install it, or use a static-CRT triplet |

## Best practice
- Core Guidelines I.5 (state preconditions; here as validation), E.12 (use `noexcept` and clean failure paths where throwing is impossible), ES.46 (avoid lossy conversions), P.4 and P.5 (ideally a program is statically type safe; check at compile time what you can), T.1 (use templates to raise the level of abstraction: `Result<T>`, `PagedList<T>`), CP.20 and CP.25 again for the worker pool, SL.con.2 (prefer `std::vector` by default), NL.1 and NL.2 (comments explain the *why*), and the whole *Resource management* section for the `Secret`, `Window`, `Worker`.
- OWASP ASVS and the OWASP API Security Top 10 (client side) are the checklist for the table in the design document, section 7.
- Treat *every* byte from the network as untrusted: the discovery document, error bodies, server text in the UI, headers.
- Keep tests fast, deterministic and offline; put the slow, flaky checks in a manual checklist.
- Measure before you claim: if you add a performance budget, measure frame time and request latency on your own machine and write the real numbers down.

## Going further
- Add a fuzz-style test: feed `problemFromResponse` and `decode<Page<Task>>` random byte strings and assert that nothing throws.
- Add a `Session` test with a fake `Transport` that counts refreshes while ten threads ask for a token (use `std::latch`).
- Run the tests under the compiler's sanitizers (`-fsanitize=address,undefined` on GCC and Clang, `/fsanitize=address` on MSVC) with a debug preset of your own.
- Create a `CMakeUserPresets.json` with a `ci` preset and think about what a CI job for this repository must do (restore the vcpkg binary cache, configure, build, test, package).

## Summary
The app refuses unsafe addresses, bounds what it reads and what it logs, validates input by characters, and has twenty offline tests that pin the security-critical and subtle logic, including two RFC test vectors. One command produces a ZIP; the table above lists honestly what a real release still needs.

## Next lesson
This is the last chapter of the capstone. Continue with another client capstone (web or mobile) or a backend capstone, or take the "going further" ideas as your own sprint. The [capstone README](../../README.md) lists them.
