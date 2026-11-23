---
track: capstone
level: 201
phase: 3
phase_name: auth
lesson: 03
title: "Auth with PKCE"
time: 120 min
prerequisites: [capstone-desktop-cpp-02, platform-primers-04, platform-03]
versions: { cpp: "20", vcpkg_baseline: "9eec002df1cd109f8f104cd966a763daf9751489", openssl: "baseline port", cpp_httplib: "baseline port", keycloak: "26.8.2 (platform)" }
verified: not yet run
source: capstones/desktop-cpp/source/phase-3-auth/03-auth-pkce/
---

# 03. Auth with PKCE

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## Why it matters
A desktop app is a *public client*: anything it ships, a user can read, so it cannot keep a client secret. The standard answer (RFC 8252, with PKCE from RFC 7636) is: open the identity provider's page in the **system browser**, let the user type the password there, and receive the result on a one-shot listener on `127.0.0.1`. The app never sees the password, and a stolen authorization code is useless without the PKCE secret that only this process knows. This chapter builds that flow, keeps the tokens in memory only, and introduces the background-thread machinery that waiting for a browser requires.

## What you will build
A real sign-in: discovery, PKCE, a loopback listener, the code-for-token exchange, a single-flight refresh, and sign out. Plus `UiQueue` and `Worker` (threads and a queue to the UI thread), a `Controller`, and a first screen that shows who you are. Requirements: D-07, D-08, D-09, D-10, D-11, and the first parts of D-19 and D-20.

## Predict before you run
(1) What does the browser address bar show when sign-in finishes? (2) Which thread opens the browser? (3) What happens to the window while the browser page is open? (4) Where does the refresh token live while the app runs, and where after you close it? Write your answers, then read "How it works".

## New C++ in this chapter
- **`std::jthread`** is a thread that joins itself in its destructor and carries a `std::stop_token`: a polite "please stop" flag that long-running code checks.
- **`std::mutex` and `std::lock_guard`**: only one thread at a time may hold the mutex; the guard releases it at the end of the scope even if an exception flies.
- **`std::condition_variable_any`** lets a thread sleep until work arrives, and wakes up when a stop is requested.
- **`std::promise` and `std::future`**: a one-time message from one thread (the HTTP server thread) to another (the waiting worker).
- **`std::call_once`** runs a piece of code exactly once, even if called from several threads.
- **Move-only types**: `Secret` cannot be copied, only moved, so there is never a stray copy of a token to forget.
- **Capturing `this` in a lambda** gives the closure access to the object; the object must outlive every closure that runs later (the member order in `Controller` guarantees that).

## Before you start
- Chapter 02 snapshot or `desktop-cpp-phase-3-auth.zip`; open `03-auth-pkce/code`.
- The platform is running (Keycloak on 8180) and one backend on 8000.
- Read the sign-in diagram in the [design](../../TDD.md) section 7 and platform primer 04.

## The realm has no desktop client yet
The platform's realm file (`realm-tasksteams.json`) defines `tasks-web` and `tasks-mobile`, whose redirect URIs are `http://localhost:4200/*`, `http://localhost:5173/*` and `com.code101.tasks:/oauth2redirect`. None of them accepts `http://127.0.0.1:<port>/callback`. This capstone must not edit the platform, so it ships a Keycloak *partial import* file with one new public client, `tasks-desktop`. Keycloak's documentation says that a valid redirect URI of `http://127.0.0.1` (with a path) allows any port, which is what RFC 8252 requires of an authorization server. A short note belongs in the platform's v1.1 backlog: add this client to the realm file.

**Import it once (Admin console).** Open `http://localhost:8180/admin`, sign in as the admin from the platform `.env.example` (fake local values), choose realm `tasksteams`, then *Realm settings*, the *Action* menu at the top right, *Partial import*. Select the file `keycloak/tasks-desktop-client.json` from this pack, leave the policy as written in the file (`SKIP` if the client already exists) and click Import. Typical result: a message saying one client was added. If the menu names differ in your Keycloak version, look for "Partial import" in the realm's actions.

## Steps
### Step 1. Add the Keycloak client file
**File: `keycloak/tasks-desktop-client.json`**
```json
{
  "ifResourceExists": "SKIP",
  "clients": [
    {
      "clientId": "tasks-desktop",
      "name": "Tasks desktop client (C++)",
      "description": "Public client for the native desktop app. Loopback redirect (RFC 8252): Keycloak ignores the port of http://127.0.0.1 redirect URIs.",
      "enabled": true,
      "protocol": "openid-connect",
      "publicClient": true,
      "standardFlowEnabled": true,
      "implicitFlowEnabled": false,
      "directAccessGrantsEnabled": false,
      "serviceAccountsEnabled": false,
      "fullScopeAllowed": true,
      "redirectUris": ["http://127.0.0.1/callback"],
      "webOrigins": [],
      "attributes": {
        "pkce.code.challenge.method": "S256"
      },
      "defaultClientScopes": ["basic", "profile", "email", "roles", "tasks:read", "tasks:write", "tasks-api-audience"],
      "optionalClientScopes": []
    }
  ]
}
```
Line by line: `publicClient: true` means no client secret. `standardFlowEnabled` is the authorization code flow; implicit flow and the password grant (`directAccessGrantsEnabled`) are off. `pkce.code.challenge.method: S256` makes Keycloak *require* PKCE with SHA-256 for this client. `redirectUris` holds exactly one URI. The default scopes copy those of `tasks-mobile`, including `tasks-api-audience`, the scope that puts `tasks-api` into the token's `aud` claim (the backends reject tokens without it). `tasks:admin` is deliberately not offered.

### Step 2. Replace `vcpkg.json`
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
  ]
}
```
`openssl` supplies SHA-256 and a secure random generator (never write your own cryptography); `cpp-httplib` is a tiny HTTP server for the loopback listener.

### Step 3. Replace `CMakeLists.txt`
**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(tasks_desktop VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

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

# Everything that needs neither a window nor Dear ImGui: unit tests link this library.
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
```
Three more `.cpp` files join the library (PKCE, OIDC, session) and three join the executable (controller, screens). `OpenSSL::Crypto` is OpenSSL's crypto library without the TLS part.

### Step 4. Create `src/core/Concurrency.hpp`
**File: `src/core/Concurrency.hpp`**
```cpp
#pragma once

#include <spdlog/spdlog.h>

#include <condition_variable>
#include <deque>
#include <exception>
#include <functional>
#include <mutex>
#include <stop_token>
#include <thread>
#include <utility>
#include <vector>

namespace tt {

// Worker threads never touch UI state. They post closures here; the UI thread runs them once per frame.
class UiQueue {
public:
    using Task = std::function<void()>;

    void post(Task task) {
        const std::lock_guard lock{mutex_};
        tasks_.push_back(std::move(task));
    }

    // UI thread only. Takes the whole batch under the lock and runs it without the lock, so a task may post again.
    void drain() {
        std::deque<Task> batch;
        {
            const std::lock_guard lock{mutex_};
            batch.swap(tasks_);
        }
        for (auto& task : batch) {
            task();
        }
    }

private:
    std::mutex mutex_;
    std::deque<Task> tasks_;
};

// A small pool of std::jthread workers. Destroying the pool requests stop and joins every thread;
// jobs that were still waiting in the queue are dropped.
class Worker {
public:
    using Job = std::function<void(std::stop_token)>;

    explicit Worker(unsigned threadCount = 2) {
        for (unsigned i = 0; i < threadCount; ++i) {
            threads_.emplace_back([this](std::stop_token shutdown) { run(shutdown); });
        }
    }
    Worker(const Worker&) = delete;
    Worker& operator=(const Worker&) = delete;
    ~Worker() {
        for (auto& thread : threads_) {
            thread.request_stop();
        }
        // The jthread members are destroyed first (declared last) and join here.
    }

    // `cancel` stops this one job; the pool's own stop request (shutdown) always applies as well.
    void submit(Job job, std::stop_token cancel = {}) {
        {
            const std::lock_guard lock{mutex_};
            queue_.push_back(Item{std::move(job), std::move(cancel)});
        }
        wake_.notify_one();
    }

private:
    struct Item {
        Job job;
        std::stop_token cancel;
    };

    void run(std::stop_token shutdown) {
        while (true) {
            Item item;
            {
                std::unique_lock lock{mutex_};
                if (!wake_.wait(lock, shutdown, [this] { return !queue_.empty(); })) {
                    return;  // stop requested and nothing to do
                }
                item = std::move(queue_.front());
                queue_.pop_front();
            }
            std::stop_source merged;
            const std::stop_callback onShutdown{shutdown, [&merged] { merged.request_stop(); }};
            const std::stop_callback onCancel{item.cancel, [&merged] { merged.request_stop(); }};
            try {
                item.job(merged.get_token());
            } catch (const std::exception& error) {
                spdlog::error("background job failed: {}", error.what());
            } catch (...) {
                spdlog::error("background job failed with an unknown exception");
            }
        }
    }

    std::mutex mutex_;
    std::condition_variable_any wake_;
    std::deque<Item> queue_;
    std::vector<std::jthread> threads_;
};

}  // namespace tt
```
`UiQueue` is a mailbox: any thread may `post`, only the UI thread calls `drain`. `drain` swaps the whole list out under the lock and runs it outside the lock, so a task that posts again cannot deadlock. `Worker` starts two `std::jthread`s, each running `run`. A thread sleeps on `wake_` until the queue is not empty *or* a stop is requested (`wait(lock, stopToken, predicate)` returns false in the second case). Every job receives a *merged* stop token: it fires when the pool shuts down **or** when the caller's own `cancel` token fires (the Cancel button during sign-in). A job that throws is caught and logged, because an exception escaping a thread would end the whole program. The members are declared so that `threads_` is last and therefore joined first.

### Step 5. Create `src/auth/Secret.hpp`
**File: `src/auth/Secret.hpp`**
```cpp
#pragma once

#include <openssl/crypto.h>

#include <string>
#include <utility>

namespace tt {

// Holds a token. The bytes are overwritten when the object dies or is replaced.
// Best effort only: copies made by libcurl or the operating system are out of reach.
class Secret {
public:
    Secret() = default;
    explicit Secret(std::string value) : value_{std::move(value)} {}
    Secret(const Secret&) = delete;
    Secret& operator=(const Secret&) = delete;
    Secret(Secret&& other) noexcept : value_{std::exchange(other.value_, std::string{})} {}
    Secret& operator=(Secret&& other) noexcept {
        if (this != &other) {
            wipe();
            value_ = std::exchange(other.value_, std::string{});
        }
        return *this;
    }
    ~Secret() { wipe(); }

    [[nodiscard]] const std::string& reveal() const noexcept { return value_; }
    [[nodiscard]] bool empty() const noexcept { return value_.empty(); }

private:
    void wipe() noexcept {
        if (!value_.empty()) {
            OPENSSL_cleanse(value_.data(), value_.size());
        }
        value_.clear();
    }

    std::string value_;
};

}  // namespace tt
```
`Secret` is a move-only RAII type: the token's bytes are overwritten with `OPENSSL_cleanse` (a function the compiler may not optimise away, unlike a plain `memset` before a free) when the secret dies or is replaced. The name `reveal()` makes every place that reads the token easy to find with a search. This is a best-effort measure: libcurl copies the bearer header while a request runs and the operating system may page memory to disk, so it narrows the exposure window and does not remove it.

### Step 6. Create `src/auth/Pkce.hpp`
**File: `src/auth/Pkce.hpp`**
```cpp
#pragma once

#include "core/Result.hpp"

#include <cstddef>
#include <span>
#include <string>
#include <string_view>

namespace tt {

struct Pkce {
    std::string verifier;   // secret, sent only to the token endpoint
    std::string challenge;  // BASE64URL(SHA-256(verifier)), sent in the browser URL
    std::string state;      // random, comes back unchanged in the redirect
};

// Base64url without padding (RFC 4648 section 5).
[[nodiscard]] std::string base64UrlEncode(std::span<const unsigned char> bytes);

// `byteCount` random bytes from OpenSSL's generator, base64url encoded.
[[nodiscard]] Result<std::string> randomToken(std::size_t byteCount);

// RFC 7636 S256 transform: BASE64URL(SHA-256(verifier)).
[[nodiscard]] Result<std::string> s256Challenge(std::string_view verifier);

[[nodiscard]] Result<Pkce> makePkce();

}  // namespace tt
```
`std::span<const unsigned char>` is "a pointer and a length" for any contiguous bytes: a `std::vector` or a `std::array` converts to it without a copy (Core Guidelines I.13: do not pass an array as a single pointer).

### Step 7. Create `src/auth/Pkce.cpp`
**File: `src/auth/Pkce.cpp`**
```cpp
#include "auth/Pkce.hpp"

#include <openssl/evp.h>
#include <openssl/rand.h>

#include <array>
#include <vector>

namespace tt {

std::string base64UrlEncode(std::span<const unsigned char> bytes) {
    static constexpr char kAlphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    std::string out;
    out.reserve((bytes.size() * 4 + 2) / 3);
    std::size_t i = 0;
    for (; i + 3 <= bytes.size(); i += 3) {
        const unsigned value = (static_cast<unsigned>(bytes[i]) << 16) | (static_cast<unsigned>(bytes[i + 1]) << 8) |
                               static_cast<unsigned>(bytes[i + 2]);
        out.push_back(kAlphabet[(value >> 18) & 63U]);
        out.push_back(kAlphabet[(value >> 12) & 63U]);
        out.push_back(kAlphabet[(value >> 6) & 63U]);
        out.push_back(kAlphabet[value & 63U]);
    }
    const std::size_t rest = bytes.size() - i;
    if (rest == 1) {
        const unsigned value = static_cast<unsigned>(bytes[i]) << 16;
        out.push_back(kAlphabet[(value >> 18) & 63U]);
        out.push_back(kAlphabet[(value >> 12) & 63U]);
    } else if (rest == 2) {
        const unsigned value = (static_cast<unsigned>(bytes[i]) << 16) | (static_cast<unsigned>(bytes[i + 1]) << 8);
        out.push_back(kAlphabet[(value >> 18) & 63U]);
        out.push_back(kAlphabet[(value >> 12) & 63U]);
        out.push_back(kAlphabet[(value >> 6) & 63U]);
    }
    return out;
}

Result<std::string> randomToken(std::size_t byteCount) {
    std::vector<unsigned char> bytes(byteCount);
    if (RAND_bytes(bytes.data(), static_cast<int>(bytes.size())) != 1) {
        return failure(ErrorKind::Auth, "No secure random numbers available");
    }
    return base64UrlEncode(bytes);
}

Result<std::string> s256Challenge(std::string_view verifier) {
    std::array<unsigned char, EVP_MAX_MD_SIZE> digest{};
    unsigned int length = 0;
    if (EVP_Digest(verifier.data(), verifier.size(), digest.data(), &length, EVP_sha256(), nullptr) != 1) {
        return failure(ErrorKind::Auth, "Cannot compute the PKCE challenge");
    }
    return base64UrlEncode(std::span<const unsigned char>{digest.data(), length});
}

Result<Pkce> makePkce() {
    auto verifier = randomToken(32);
    if (!verifier) {
        return tl::make_unexpected(std::move(verifier.error()));
    }
    auto state = randomToken(16);
    if (!state) {
        return tl::make_unexpected(std::move(state.error()));
    }
    auto challenge = s256Challenge(*verifier);
    if (!challenge) {
        return tl::make_unexpected(std::move(challenge.error()));
    }
    return Pkce{std::move(*verifier), std::move(*challenge), std::move(*state)};
}

}  // namespace tt
```
Base64url takes three bytes (24 bits) at a time and writes four characters of six bits each from an alphabet that uses `-` and `_` instead of `+` and `/`, with no `=` padding. The last one or two bytes produce two or three characters. 32 random bytes become a 43-character verifier, which is inside the 43 to 128 characters RFC 7636 allows. `EVP_Digest` hashes in one call; `EVP_MAX_MD_SIZE` is large enough for any digest, and `length` tells how many bytes SHA-256 really wrote (32). Chapter 05 checks this code against the RFC's own test vector.

### Step 8. Create `src/auth/LoopbackServer.hpp`
**File: `src/auth/LoopbackServer.hpp`**
```cpp
#pragma once

#include "core/Result.hpp"

#include <httplib.h>

#include <chrono>
#include <future>
#include <mutex>
#include <stop_token>
#include <string>
#include <thread>
#include <utility>

namespace tt {

struct CallbackParams {
    std::string code;
    std::string state;
    std::string error;
    std::string errorDescription;
};

// RFC 8252 section 7.3: a one-shot HTTP listener on 127.0.0.1 and a port chosen by the operating system.
// It accepts only GET /callback with the expected `state`, answers once and hands the parameters to wait().
class LoopbackServer {
public:
    explicit LoopbackServer(std::string expectedState) : expectedState_{std::move(expectedState)} {
        server_.Get("/callback", [this](const httplib::Request& request, httplib::Response& response) {
            handle(request, response);
        });
        port_ = server_.bind_to_any_port("127.0.0.1");
        if (port_ <= 0) {
            port_ = 0;
            return;
        }
        thread_ = std::jthread{[this] { server_.listen_after_bind(); }};
        for (int i = 0; i < 200 && !server_.is_running(); ++i) {
            std::this_thread::sleep_for(std::chrono::milliseconds{10});
        }
    }
    LoopbackServer(const LoopbackServer&) = delete;
    LoopbackServer& operator=(const LoopbackServer&) = delete;
    ~LoopbackServer() { server_.stop(); }  // thread_ is joined right after, because it is declared later

    [[nodiscard]] bool listening() const { return port_ != 0 && server_.is_running(); }
    [[nodiscard]] int port() const noexcept { return port_; }

    // Waits for the browser to arrive, for at most `timeout`, polling the stop token every 100 ms.
    Result<CallbackParams> wait(std::chrono::seconds timeout, std::stop_token stop) {
        auto answer = promise_.get_future();
        const auto deadline = std::chrono::steady_clock::now() + timeout;
        while (std::chrono::steady_clock::now() < deadline) {
            if (stop.stop_requested()) {
                return failure(ErrorKind::Cancelled, "Sign-in cancelled");
            }
            if (answer.wait_for(std::chrono::milliseconds{100}) == std::future_status::ready) {
                return answer.get();
            }
        }
        return failure(ErrorKind::Auth, "Sign-in timed out", "The browser did not come back in time.");
    }

private:
    static constexpr const char* kDonePage =
        "<!doctype html><html lang=\"en\"><meta charset=\"utf-8\"><title>Tasks and Teams</title>"
        "<p>You are signed in. You can close this tab and return to Tasks and Teams.</p></html>";
    static constexpr const char* kFailedPage =
        "<!doctype html><html lang=\"en\"><meta charset=\"utf-8\"><title>Tasks and Teams</title>"
        "<p>Sign-in was not completed. You can close this tab and return to Tasks and Teams.</p></html>";

    void handle(const httplib::Request& request, httplib::Response& response) {
        const bool hostOk = request.get_header_value("Host").rfind("127.0.0.1:", 0) == 0;
        if (!hostOk || request.get_param_value("state") != expectedState_) {
            response.status = 400;
            return;
        }
        CallbackParams params{request.get_param_value("code"), request.get_param_value("state"),
                              request.get_param_value("error"), request.get_param_value("error_description")};
        const bool failed = !params.error.empty();
        response.set_header("Cache-Control", "no-store");
        response.set_header("Referrer-Policy", "no-referrer");
        response.set_content(failed ? kFailedPage : kDonePage, "text/html; charset=utf-8");
        std::call_once(once_, [&] { promise_.set_value(std::move(params)); });
    }

    std::string expectedState_;
    httplib::Server server_;
    std::promise<CallbackParams> promise_;
    std::once_flag once_;
    std::jthread thread_;
    int port_{0};
};

}  // namespace tt
```
The listener is bound in the constructor: `bind_to_any_port("127.0.0.1")` asks the OS for a free port on the loopback interface only (so other machines cannot reach it) and returns it; `listen_after_bind()` then serves requests on a `std::jthread`. The constructor waits (at most 2 seconds) until the server reports `is_running()`, so the browser never races an unready listener. The handler is strict: it answers only if the `Host` header is `127.0.0.1:<port>` (a defence against DNS rebinding) **and** the `state` equals the random value we generated; anything else gets 400 and is ignored, so a local program that fires a request with a wrong state cannot use up the one-shot. The first valid callback sets the promise (`std::call_once` makes "only the first" safe even if two arrive together), and `wait` polls the future every 100 ms so that it can also notice a stop request or the deadline. The reply page contains no data from the request (nothing to inject into). The destructor stops the server; the `jthread` member is declared after the server, so it is joined before the server is destroyed.

### Step 9. Create `src/auth/OidcClient.hpp`
**File: `src/auth/OidcClient.hpp`**
```cpp
#pragma once

#include "auth/Pkce.hpp"
#include "auth/Secret.hpp"
#include "core/Config.hpp"
#include "core/Util.hpp"
#include "net/Transport.hpp"

#include <chrono>
#include <stop_token>
#include <string>

namespace tt {

struct Endpoints {
    std::string authorization;
    std::string token;
    std::string endSession;
};

struct TokenSet {
    Secret access;
    Secret refresh;
    std::chrono::steady_clock::time_point accessExpiresAt{};
};

// The OpenID Connect protocol steps. It holds no tokens; Session does.
class OidcClient {
public:
    OidcClient(Config config, Transport& transport);

    // Fetches the discovery document and requires its `issuer` to equal the configured issuer exactly.
    [[nodiscard]] Result<Endpoints> discover(std::stop_token stop) const;

    [[nodiscard]] std::string authorizationUrl(const Endpoints& endpoints, const std::string& redirectUri,
                                                const Pkce& pkce) const;

    [[nodiscard]] Result<TokenSet> exchangeCode(const Endpoints& endpoints, const std::string& code,
                                                 const std::string& verifier, const std::string& redirectUri,
                                                 std::stop_token stop) const;

    [[nodiscard]] Result<TokenSet> refresh(const Endpoints& endpoints, const std::string& refreshToken,
                                            std::stop_token stop) const;

    // Back-channel logout: ends the Keycloak session that belongs to the refresh token.
    [[nodiscard]] Result<void> endSession(const Endpoints& endpoints, const std::string& refreshToken,
                                           std::stop_token stop) const;

private:
    [[nodiscard]] Result<TokenSet> tokenRequest(const Endpoints& endpoints, const QueryBuilder& form,
                                                 std::stop_token stop) const;

    Config config_;
    Transport* transport_;  // not owned
};

}  // namespace tt
```
`TokenSet` is move-only because `Secret` is, and so is a `Result<TokenSet>`. The expiry uses `steady_clock`, which never jumps when the user changes the system time (a `system_clock` would).

### Step 10. Create `src/auth/OidcClient.cpp`
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
Key points: **discovery** reads `/.well-known/openid-configuration` and refuses a document whose `issuer` differs from the configured one (RFC 8414 and the mix-up defence of RFC 9700). The **authorization URL** carries `response_type=code`, the client id, the exact redirect URI, the scope, our `state`, the PKCE `code_challenge` and the method `S256`; every value passes through `QueryBuilder`, so spaces in the scope become `%20`. The **token request** is a form POST (`application/x-www-form-urlencoded`), as OAuth requires, and contains the `code_verifier`, which is the only thing that proves we are the app that started the flow. An OAuth error answer (`{"error": "invalid_grant", ...}`) becomes a `Problem` of kind `Auth`. The bodies of these requests hold secrets, so `CprTransport` never logs them. There is no `client_secret`: this is a public client.

### Step 11. Create `src/auth/Session.hpp`
**File: `src/auth/Session.hpp`**
```cpp
#pragma once

#include "auth/OidcClient.hpp"
#include "core/Config.hpp"

#include <cstdint>
#include <functional>
#include <mutex>
#include <optional>
#include <stop_token>
#include <string>

namespace tt {

// Receives the authorization URL. The app opens it in the system browser.
using BrowserOpener = std::function<bool(const std::string& url)>;

// Signed-in state: tokens in memory only, one refresh at a time. Safe to call from several threads.
class Session {
public:
    Session(Config config, Transport& transport, BrowserOpener openBrowser);
    Session(const Session&) = delete;
    Session& operator=(const Session&) = delete;

    // Authorization code flow with PKCE through the system browser. Blocks until the browser returns,
    // the 180 second limit passes or `stop` is requested, so call it from a worker thread.
    [[nodiscard]] Result<void> signIn(std::stop_token stop);

    // A valid access token. Refreshes first when fewer than 60 seconds are left.
    [[nodiscard]] Result<std::string> accessToken(std::stop_token stop);

    // Ends the identity provider session, then forgets the tokens. The tokens are forgotten even when the call fails.
    [[nodiscard]] Result<void> signOut(std::stop_token stop);

    // Forgets the tokens without any network call.
    void forget();

    [[nodiscard]] bool signedIn() const;

private:
    [[nodiscard]] bool fresh() const;  // the caller holds stateMutex_

    OidcClient oidc_;
    BrowserOpener openBrowser_;
    mutable std::mutex stateMutex_;  // short: guards the fields below, never held during network calls
    std::mutex refreshMutex_;        // long: makes refreshing single-flight
    std::optional<Endpoints> endpoints_;
    TokenSet tokens_;
    std::uint64_t epoch_{0};  // changes on every sign-in, sign-out and forget
};

}  // namespace tt
```
Two mutexes with two jobs. `stateMutex_` protects the fields for a few instructions at a time and is never held during a network call, so reading the token never waits for the network. `refreshMutex_` is held for the whole refresh, so a second thread that needs a token waits for the first, then finds a fresh token and skips its own refresh. The `epoch_` number lets a refresh notice that the user signed out while it was running.

### Step 12. Create `src/auth/Session.cpp`
**File: `src/auth/Session.cpp`**
```cpp
#include "auth/Session.hpp"

#include "auth/LoopbackServer.hpp"

#include <spdlog/spdlog.h>

#include <chrono>

namespace tt {
namespace {

constexpr auto kLeeway = std::chrono::seconds{60};
constexpr auto kLoginTimeout = std::chrono::seconds{180};

}  // namespace

Session::Session(Config config, Transport& transport, BrowserOpener openBrowser)
    : oidc_{std::move(config), transport}, openBrowser_{std::move(openBrowser)} {}

bool Session::fresh() const {
    return !tokens_.access.empty() && std::chrono::steady_clock::now() + kLeeway < tokens_.accessExpiresAt;
}

bool Session::signedIn() const {
    const std::lock_guard lock{stateMutex_};
    return !tokens_.refresh.empty();
}

Result<void> Session::signIn(std::stop_token stop) {
    auto endpoints = oidc_.discover(stop);
    if (!endpoints) {
        return tl::make_unexpected(std::move(endpoints.error()));
    }
    auto pkce = makePkce();
    if (!pkce) {
        return tl::make_unexpected(std::move(pkce.error()));
    }

    LoopbackServer server{pkce->state};
    if (!server.listening()) {
        return failure(ErrorKind::Auth, "Cannot listen on the loopback interface",
                       "No local port on 127.0.0.1 could be opened for the browser to return to.");
    }
    const std::string redirectUri = "http://127.0.0.1:" + std::to_string(server.port()) + "/callback";
    if (!openBrowser_(oidc_.authorizationUrl(*endpoints, redirectUri, *pkce))) {
        return failure(ErrorKind::Auth, "Cannot open the system browser");
    }

    const auto callback = server.wait(kLoginTimeout, stop);
    if (!callback) {
        return tl::make_unexpected(callback.error());
    }
    if (!callback->error.empty()) {
        return failure(ErrorKind::Auth, "Sign-in was not completed",
                       callback->errorDescription.empty() ? callback->error : callback->errorDescription);
    }
    if (callback->code.empty()) {
        return failure(ErrorKind::Auth, "The browser returned no authorization code");
    }

    auto tokens = oidc_.exchangeCode(*endpoints, callback->code, pkce->verifier, redirectUri, stop);
    if (!tokens) {
        return tl::make_unexpected(std::move(tokens.error()));
    }
    const std::lock_guard lock{stateMutex_};
    endpoints_ = std::move(*endpoints);
    tokens_ = std::move(*tokens);
    ++epoch_;
    spdlog::info("signed in");
    return {};
}

Result<std::string> Session::accessToken(std::stop_token stop) {
    {
        const std::lock_guard lock{stateMutex_};
        if (fresh()) {
            return tokens_.access.reveal();
        }
        if (tokens_.refresh.empty()) {
            return failure(ErrorKind::Auth, "Not signed in");
        }
    }

    // Keycloak rotates refresh tokens: a second refresh with the old token would fail, so only one thread refreshes.
    const std::lock_guard single{refreshMutex_};
    Endpoints endpoints;
    Secret refreshToken;
    std::uint64_t epoch = 0;
    {
        const std::lock_guard lock{stateMutex_};
        if (fresh()) {
            return tokens_.access.reveal();  // another thread refreshed while this one waited
        }
        if (tokens_.refresh.empty() || !endpoints_) {
            return failure(ErrorKind::Auth, "Not signed in");
        }
        endpoints = *endpoints_;
        refreshToken = Secret{tokens_.refresh.reveal()};
        epoch = epoch_;
    }

    auto renewed = oidc_.refresh(endpoints, refreshToken.reveal(), stop);

    const std::lock_guard lock{stateMutex_};
    if (epoch != epoch_) {
        return failure(ErrorKind::Cancelled, "Signed out while refreshing");
    }
    if (!renewed) {
        if (renewed.error().kind == ErrorKind::Auth) {  // rejected: the session is over; a network error keeps the tokens
            tokens_ = TokenSet{};
            ++epoch_;
        }
        return tl::make_unexpected(std::move(renewed.error()));
    }
    tokens_ = std::move(*renewed);  // the rotated refresh token replaces the old one before anyone uses the new access token
    return tokens_.access.reveal();
}

Result<void> Session::signOut(std::stop_token stop) {
    Endpoints endpoints;
    Secret refreshToken;
    {
        const std::lock_guard lock{stateMutex_};
        if (endpoints_) {
            endpoints = *endpoints_;
        }
        refreshToken = std::move(tokens_.refresh);
        tokens_ = TokenSet{};
        ++epoch_;
    }
    if (refreshToken.empty()) {
        return {};
    }
    return oidc_.endSession(endpoints, refreshToken.reveal(), stop);
}

void Session::forget() {
    const std::lock_guard lock{stateMutex_};
    tokens_ = TokenSet{};
    ++epoch_;
}

}  // namespace tt
```
`signIn`, in order: discover, make the PKCE values, start the listener (its `state` is the random value we just made), build the redirect URI from the port the OS gave us, open the browser (the opener only *queues* the URL for the UI thread, see Step 15), wait, check for an `error` or a missing `code`, exchange the code, store the tokens. The loopback server is a local variable: it closes when `signIn` returns, whatever the outcome. `accessToken` uses a classic double-checked pattern: cheap check under the short lock, then take the long lock, check again (someone may have refreshed meanwhile), refresh *without* holding the short lock, and store the result as a whole. A refresh rejected by the server ends the session (tokens wiped); a refresh that failed only because the network was down keeps the tokens, so the app recovers when the network returns. `signOut` first moves the refresh token out and clears the state (so the UI is already signed out), then calls the logout endpoint with the token it still holds.

### Step 13. Create `src/state/AppState.hpp`
**File: `src/state/AppState.hpp`**
```cpp
#pragma once

#include "api/Models.hpp"

#include <optional>

namespace tt {

enum class AuthPhase { SignedOut, SigningIn, SignedIn };

// Plain data that the UI draws. Only the UI thread reads or writes it.
struct AppState {
    AuthPhase auth{AuthPhase::SignedOut};
    std::optional<Me> me;
    std::optional<Problem> notice;  // the last error, shown until dismissed

    void clearSession() { me.reset(); }
};

}  // namespace tt
```
The state is a plain struct: no mutex, because exactly one thread (the UI thread) touches it. Workers never get a reference to it.

### Step 14. Create `src/app/Controller.hpp`
**File: `src/app/Controller.hpp`**
```cpp
#pragma once

#include "api/ApiClient.hpp"
#include "auth/Session.hpp"
#include "core/Concurrency.hpp"
#include "core/Config.hpp"
#include "state/AppState.hpp"

#include <functional>
#include <stop_token>
#include <string>

namespace tt {

// Opens a URL in the system browser. SDL requires this to run on the main thread.
using UrlOpener = std::function<bool(const std::string& url)>;

// The only place where UI events become background jobs and job results become state changes.
// Every public function is called on the UI thread.
class Controller {
public:
    Controller(Config config, Transport& transport, UrlOpener openUrl);
    Controller(const Controller&) = delete;
    Controller& operator=(const Controller&) = delete;

    // Runs the closures that workers posted. Call once per frame.
    void pump() { ui_.drain(); }

    [[nodiscard]] AppState& state() noexcept { return state_; }

    void signIn();
    void cancelSignIn();
    void signOut();
    void loadMe();
    void dismissNotice() { state_.notice.reset(); }

private:
    template <class Call, class Apply>
    void run(Call call, Apply apply);

    void report(Problem problem);
    void onSignedIn(const Result<void>& result);
    void showBrowserFailure(const std::string& url);

    // Declaration order is destruction order in reverse: the worker comes last, so its threads
    // are joined first and can never touch a destroyed queue, state or session.
    UiQueue ui_;
    AppState state_;
    Session session_;
    ApiClient api_;
    std::stop_source signInStop_;
    Worker worker_;
};

}  // namespace tt
```
The comment on the members is a rule you must keep: the worker threads use `ui_`, `session_` and `api_`; if those were destroyed first, a thread could touch freed memory. `run` is a private function template: the call and the apply step have different types for every operation.

### Step 15. Create `src/app/Controller.cpp`
**File: `src/app/Controller.cpp`**
```cpp
#include "app/Controller.hpp"

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

template <class Call, class Apply>
void Controller::run(Call call, Apply apply) {
    worker_.submit([this, call = std::move(call), apply = std::move(apply)](std::stop_token stop) {
        auto result = call(stop);  // on a worker thread
        ui_.post([apply, result = std::move(result)]() mutable { apply(std::move(result)); });  // on the UI thread
    });
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

}  // namespace tt
```
The constructor wires two lambdas: the *browser opener* given to the session (it posts the URL to the UI queue; if opening fails, the UI shows the address so the user can paste it) and the *token provider* given to the API client (`session_.accessToken`). `run` is the whole threading pattern in six lines: **submit a job; on the worker compute a result; post a closure that applies the result on the UI thread.** Every later operation in chapter 04 is `run(call, apply)` with different lambdas. `report` is the single place that decides what an error means: a 401 or a rejected refresh ends the session. `signIn` is a no-op unless the state is `SignedOut` (so a double click cannot start two flows); the job gets `signInStop_.get_token()` so the Cancel button can stop it. `signOut` updates the UI first and tells Keycloak in the background.

### Step 16. Create `src/ui/Screens.hpp`
**File: `src/ui/Screens.hpp`**
```cpp
#pragma once

namespace tt {
class Controller;
}

namespace tt::ui {

// Draws the whole window for one frame and forwards user actions to the controller.
void drawRoot(Controller& controller);

}  // namespace tt::ui
```
A forward declaration (`class Controller;`) is enough here, so this header does not pull in the controller's includes.

### Step 17. Create `src/ui/Screens.cpp`
**File: `src/ui/Screens.cpp`**
```cpp
#include "ui/Screens.hpp"

#include "app/Controller.hpp"

#include <imgui.h>

#include <string>
#include <vector>

namespace tt::ui {
namespace {

constexpr ImVec4 kErrorColour{1.0F, 0.60F, 0.60F, 1.0F};

std::string join(const std::vector<std::string>& values) {
    std::string out;
    for (const auto& value : values) {
        if (!out.empty()) {
            out += ", ";
        }
        out += value;
    }
    return out;
}

void drawTopBar(Controller& controller) {
    const AppState& state = controller.state();
    ImGui::TextUnformatted("Tasks and Teams");
    ImGui::SameLine();
    switch (state.auth) {
        case AuthPhase::SignedOut:
            if (ImGui::Button("Sign in")) {
                controller.signIn();
            }
            break;
        case AuthPhase::SigningIn:
            ImGui::TextUnformatted("Waiting for the browser...");
            ImGui::SameLine();
            if (ImGui::Button("Cancel")) {
                controller.cancelSignIn();
            }
            break;
        case AuthPhase::SignedIn:
            ImGui::TextDisabled("%s", state.me ? state.me->displayName.c_str() : "loading...");
            ImGui::SameLine();
            if (ImGui::Button("Sign out")) {
                controller.signOut();
            }
            break;
    }
}

// Shows every member of the problem: this chapter has no friendly messages yet.
void drawNotice(Controller& controller) {
    const auto& notice = controller.state().notice;
    if (!notice) {
        return;
    }
    ImGui::Separator();
    ImGui::TextColored(kErrorColour, "Problem: %s", notice->title.c_str());
    if (notice->status != 0) {
        ImGui::Text("Status: %d", notice->status);
    }
    if (!notice->detail.empty()) {
        ImGui::TextWrapped("%s", notice->detail.c_str());
    }
    if (!notice->traceId.empty()) {
        ImGui::TextDisabled("trace id %s", notice->traceId.c_str());
    }
    if (ImGui::Button("Dismiss")) {
        controller.dismissNotice();
    }
}

void drawAccount(const Me& me) {
    ImGui::SeparatorText("Signed in");
    ImGui::Text("User: %s (%s)", me.displayName.c_str(), me.username.c_str());
    ImGui::TextWrapped("Roles: %s", join(me.roles).c_str());
    ImGui::TextWrapped("Scopes: %s", join(me.scopes).c_str());
    ImGui::TextUnformatted("Teams:");
    for (const auto& team : me.teams) {
        ImGui::BulletText("%s (%s)", team.name.c_str(), team.role.c_str());
    }
}

}  // namespace

void drawRoot(Controller& controller) {
    const ImGuiViewport* viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(viewport->WorkPos);
    ImGui::SetNextWindowSize(viewport->WorkSize);
    constexpr ImGuiWindowFlags kFlags =
        ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoSavedSettings;
    if (ImGui::Begin("Tasks and Teams", nullptr, kFlags)) {
        drawTopBar(controller);
        drawNotice(controller);
        ImGui::Separator();
        const AppState& state = controller.state();
        if (state.auth == AuthPhase::SignedIn && state.me) {
            drawAccount(*state.me);
        } else if (state.auth == AuthPhase::SignedOut) {
            ImGui::TextWrapped(
                "Sign in to see your teams. The sign-in page opens in your web browser; this app never sees your password.");
        }
    }
    ImGui::End();
}

}  // namespace tt::ui
```
The screen is a function of the state: signed out shows the Sign in button, signing in shows Cancel, signed in shows the name and Sign out. The problem is shown in words and a status number, not only in colour. Every piece of server text goes through `"%s"`.

### Step 18. Replace `src/app/App.hpp`
**File: `src/app/App.hpp`**
```cpp
#pragma once

#include "app/Controller.hpp"
#include "app/Platform.hpp"
#include "core/Config.hpp"
#include "net/CprTransport.hpp"

namespace tt {

class App {
public:
    explicit App(Config config);

    // Runs until the window is closed. Returns the process exit code.
    int run();

private:
    SdlRuntime sdl_;
    Window window_;
    ImGuiLayer imgui_;
    Config config_;
    CprTransport transport_;
    Controller controller_;  // after transport_: it uses it; its destructor joins the worker threads
    bool quit_{false};
};

}  // namespace tt
```
### Step 19. Replace `src/app/App.cpp`
**File: `src/app/App.cpp`**
```cpp
#include "app/App.hpp"

#include "ui/Screens.hpp"

#include <utility>

namespace tt {

App::App(Config config)
    : window_{"Tasks and Teams", 1100, 720},
      imgui_{window_, window_.displayScale()},
      config_{std::move(config)},
      controller_{config_, transport_, [](const std::string& url) { return SDL_OpenURL(url.c_str()); }} {}

int App::run() {
    while (!quit_) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            imgui_.processEvent(event);
            const bool closeRequested = event.type == SDL_EVENT_QUIT ||
                                        (event.type == SDL_EVENT_WINDOW_CLOSE_REQUESTED &&
                                         event.window.windowID == SDL_GetWindowID(window_.window()));
            if (closeRequested) {
                quit_ = true;
            }
        }
        if ((SDL_GetWindowFlags(window_.window()) & SDL_WINDOW_MINIMIZED) != 0) {
            SDL_Delay(50);
            continue;
        }
        controller_.pump();  // apply what the workers finished since the last frame
        imgui_.beginFrame();
        ui::drawRoot(controller_);
        imgui_.endFrame(window_.renderer());
    }
    return 0;
}

}  // namespace tt
```
`SDL_OpenURL` (an SDL call that must run on the main thread) is passed in as a lambda: this is the only place where the app touches it. The frame loop gains exactly one line, `controller_.pump()`. When the window closes, `run` returns, the `App` destructor destroys `controller_` first (it is the last member), which requests stop on both worker threads, aborts any running request or sign-in wait and joins them; only then do the transport, the window and SDL go away.

### Step 20. Unchanged files
Copy these from chapter 02 (shown in full there); they have not changed: `CMakePresets.json`, `.gitignore`, `src/main.cpp`, `src/app/Platform.hpp`, `src/app/Theme.hpp`, `src/core/Result.hpp`, `src/core/Util.hpp`, `src/core/Config.hpp`, `src/net/Transport.hpp`, `src/net/CprTransport.hpp`, `src/net/CprTransport.cpp`, `src/api/Models.hpp`, `src/api/ApiClient.hpp`, `src/api/ApiClient.cpp`. (`Platform.hpp`, `Theme.hpp`, `CMakePresets.json` and `.gitignore` were first shown in chapter 01.)

## Run it
**For a later session only; this snapshot has not been run.** Platform, a backend and Keycloak must be running, and the client file must be imported (above).

**Command (Windows, PowerShell):**
```powershell
cmake --preset windows
cmake --build --preset windows-debug
.\build\windows\out\tasks_desktop.exe
```
(Linux and macOS: the matching presets and `./build/<preset>/out/tasks_desktop`.) Click **Sign in**: the browser opens the Keycloak page; sign in as `carol` with the fake password from the platform TDD. Typical result: the browser tab shows "You are signed in. You can close this tab..."; the app shows `Signed in`, the display name, the roles (`member`), the scopes including `tasks:read` and `tasks:write`, and the teams with the role `lead` for Mobile Team (from the seed data). Click **Sign out**: the window returns to the sign-in text. Click **Sign in** and then **Cancel**: the status returns to signed out without an error message.

## How it works
- The answers to the prediction: (1) `http://127.0.0.1:<port>/callback?...` for a moment, then the "signed in" page: the address is the loopback listener, and the code and state are in the query string; (2) the **UI (main) thread** opens the browser, because the worker only posts the URL; (3) it stays responsive (the Sign in button turns into Waiting and Cancel) because the wait runs on a worker thread; (4) in a `Secret` inside `Session` in memory, and nowhere after you close the app.
- **Why PKCE matters on a desktop.** Any local program can listen on loopback or read a redirect URL. Without PKCE, a stolen code could be traded for tokens. With S256 the thief also needs the verifier, which never leaves this process before the exchange, and the browser URL only holds its hash.
- **Why `state`.** It binds the redirect to *this* sign-in attempt. The listener ignores requests with another value, so an unrelated page that sends the browser to our port cannot inject a code.
- **Tokens and memory.** Nothing is written to disk. The price: after a restart you sign in again, but Keycloak's session cookie in the browser usually makes that one click. **In production** you would keep only the refresh token, in the operating system's secret store: Windows Credential Manager (DPAPI), macOS Keychain, Linux Secret Service (libsecret with GNOME Keyring or KWallet), never in a settings file.
- **Refresh and rotation.** Fewer than 60 seconds before expiry, the next API call refreshes first. The realm rotates refresh tokens, so concurrent refreshes would break each other; the second mutex makes them take turns.
- **Threads.** Two workers, a mailbox to the UI thread, no shared state: the UI owns `AppState`, the workers own nothing. The stop token flows from the pool or the Cancel button, through `LoopbackServer::wait` and the HTTP progress callback.

## Try it
Make accidental logging of a token safe. One file: `src/auth/Secret.hpp`.

Where: the `code` folder.

**Command (Windows, PowerShell):**
```powershell
Copy-Item ..\exercise\starter\src\auth\Secret.hpp src\auth\Secret.hpp -Force
```
**Command (macOS and Linux):**
```bash
cp ../exercise/starter/src/auth/Secret.hpp src/auth/Secret.hpp
```
**File: `../exercise/starter/src/auth/Secret.hpp`**
```cpp
#pragma once

#include <openssl/crypto.h>

#include <string>
#include <utility>

namespace tt {

// Exercise: make accidental logging safe.
// Rung 1 (guided): add `[[nodiscard]] std::string redacted() const` that returns "<empty>" for an empty
//   secret and "<secret, N characters>" otherwise (N is the length). It must never contain the value.
// Rung 2 (partial): use it in a log line in Session::signIn, for example spdlog::debug("token {}", ...).
// Rung 3 (open): why is "<secret, N characters>" still a small information leak? Write down one sentence.
class Secret {
public:
    Secret() = default;
    explicit Secret(std::string value) : value_{std::move(value)} {}
    Secret(const Secret&) = delete;
    Secret& operator=(const Secret&) = delete;
    Secret(Secret&& other) noexcept : value_{std::exchange(other.value_, std::string{})} {}
    Secret& operator=(Secret&& other) noexcept {
        if (this != &other) {
            wipe();
            value_ = std::exchange(other.value_, std::string{});
        }
        return *this;
    }
    ~Secret() { wipe(); }

    [[nodiscard]] const std::string& reveal() const noexcept { return value_; }
    [[nodiscard]] bool empty() const noexcept { return value_.empty(); }

    // TODO rung 1: redacted()

private:
    void wipe() noexcept {
        if (!value_.empty()) {
            OPENSSL_cleanse(value_.data(), value_.size());
        }
        value_.clear();
    }

    std::string value_;
};

}  // namespace tt
```
<details><summary>Solution (rung 1; rungs 2 and 3 are yours)</summary>

**File: `../exercise/solution/src/auth/Secret.hpp`**
```cpp
#pragma once

#include <openssl/crypto.h>

#include <string>
#include <utility>

namespace tt {

// Holds a token. The bytes are overwritten when the object dies or is replaced.
// Best effort only: copies made by libcurl or the operating system are out of reach.
class Secret {
public:
    Secret() = default;
    explicit Secret(std::string value) : value_{std::move(value)} {}
    Secret(const Secret&) = delete;
    Secret& operator=(const Secret&) = delete;
    Secret(Secret&& other) noexcept : value_{std::exchange(other.value_, std::string{})} {}
    Secret& operator=(Secret&& other) noexcept {
        if (this != &other) {
            wipe();
            value_ = std::exchange(other.value_, std::string{});
        }
        return *this;
    }
    ~Secret() { wipe(); }

    [[nodiscard]] const std::string& reveal() const noexcept { return value_; }
    [[nodiscard]] bool empty() const noexcept { return value_.empty(); }

    // Safe to log. The length is a small leak: it tells an attacker that reads the log which kind of token it is.
    [[nodiscard]] std::string redacted() const {
        if (value_.empty()) {
            return "<empty>";
        }
        return "<secret, " + std::to_string(value_.size()) + " characters>";
    }

private:
    void wipe() noexcept {
        if (!value_.empty()) {
            OPENSSL_cleanse(value_.data(), value_.size());
        }
        value_.clear();
    }

    std::string value_;
};

}  // namespace tt
```
For rung 3: the length reveals the token's kind and encoding (an access token and a refresh token have different lengths), and a change in length between log lines can show that a refresh happened. A `Secret` that cannot be printed at all is safer than one that prints a description.

</details>

## Check yourself
1. Why can the app not keep a client secret?
   <details><summary>Answer</summary>The executable is in the user's hands; anything inside it can be extracted. A public client relies on PKCE instead.</details>
2. What stops another local program from using the loopback port?
   <details><summary>Answer</summary>It does not stop it from connecting, but it cannot send a request with the right random `state`, and the code it might steal needs our verifier.</details>
3. Why is `SDL_OpenURL` called from the UI thread?
   <details><summary>Answer</summary>SDL documents that it must run on the main thread; the worker posts the URL through the queue.</details>
4. What would go wrong without the second mutex?
   <details><summary>Answer</summary>Two threads could refresh with the same refresh token; Keycloak rotates it, so the second call would be rejected and the user signed out.</details>
5. Why are tokens not logged even at debug level?
   <details><summary>Answer</summary>Logs live on disk and in bug reports; a token in a log file is a token on disk.</details>

## Common mistakes
| Symptom (typical message) | Cause | Fix |
|---|---|---|
| Browser shows "Invalid parameter: redirect_uri" | the `tasks-desktop` client is not imported, or the redirect URI differs | import `keycloak/tasks-desktop-client.json`; the URI must be `http://127.0.0.1/callback` |
| Browser shows "Client not found" | wrong realm or the import was skipped | import into realm `tasksteams` |
| The app says "Unexpected identity provider" | `OIDC_ISSUER` differs from the issuer in the discovery document | use exactly `http://localhost:8180/realms/tasksteams` (not `127.0.0.1`) |
| After sign-in every call is 401 | the token has no `tasks-api` audience | the client file lists `tasks-api-audience`; import it again |
| "Sign-in timed out" | the browser was closed or never opened | click Sign in again; if no browser opened, copy the address from the message |
| Window title says "Not Responding" | a call blocks the UI thread | all network calls go through `run`; find the direct call |
| Link error for `httplib` | `cpp-httplib` missing in `vcpkg.json` | restore Step 2 |

## Best practice
- Core Guidelines CP.1 (assume your code runs as part of a multi-threaded program), CP.20 (use RAII, never plain `lock()` and `unlock()`), CP.25 and CP.26 (prefer `std::jthread` over `std::thread`; do not detach), CP.42 (do not wait without a condition), CP.43 (minimise time in a critical section: no network call under `stateMutex_`), CP.50 (define a mutex together with the data it guards), R.1 and C.31 (a class that owns a resource cleans it up), E.6.
- RFC 8252 (native apps), RFC 7636 (PKCE), RFC 9700 (security best current practice): no embedded web views, no secrets in the app, exact redirect URIs, `state` checked.
- Log decisions, not values: "signed in", "refresh failed", never a token or an authorization code.
- Keep the browser step honest in the UI: show the state, offer Cancel, and show the URL if the browser cannot be opened.

## Going further
- Add a unit test for `Session::accessToken` with a fake `Transport` that counts refresh calls while ten threads ask for a token (chapter 05 shows the fake).
- Revoke the refresh token also when the window closes (RFC 7009 revocation endpoint).
- Replace the in-memory design with the OS secret store for the refresh token only; list what you must handle when the store is locked or missing.
- Read how `private_key_jwt` and DPoP would change this flow if the platform needed sender-constrained tokens.

## Summary
The app signs in through the system browser with PKCE and a one-shot loopback listener, holds tokens only in memory inside move-only `Secret` objects, refreshes with a single flight, signs out at the identity provider, and runs everything that can block on worker threads with a queue back to the UI thread.

## Next lesson
[04. Screens, threading and state](../phase-4-screens/04-screens-threading-state.md): teams, projects and tasks, forms, conflicts and problem details on top of this machinery.
