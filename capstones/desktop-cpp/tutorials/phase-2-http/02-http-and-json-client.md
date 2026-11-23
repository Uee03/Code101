---
track: capstone
level: 201
phase: 2
phase_name: http
lesson: 02
title: "HTTP and JSON client"
time: 90 min
prerequisites: [capstone-desktop-cpp-01, platform-primers-02, platform-primers-03]
versions: { cpp: "20", cmake: "3.28+", vcpkg_baseline: "9eec002df1cd109f8f104cd966a763daf9751489", cpr: "baseline port", nlohmann_json: "baseline port", tl_expected: "baseline port" }
verified: not yet run
source: capstones/desktop-cpp/source/phase-2-http/02-http-and-json-client/
---

# 02. HTTP and JSON client

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## Why it matters
Every screen in this app is "call the API, show the answer or the problem". If the call layer is a single small interface that returns either a value or a `Problem`, the screens never see libcurl, JSON parsing or status codes. It also makes the layer testable without a network (chapter 05).

## What you will build
`Result<T>` (a value or a `Problem`), a `Transport` interface with a cpr implementation, typed models, and an `ApiClient` with one method per operation: health, me, teams, projects, tasks (list, get, create, update, delete). The window gets two buttons that call the backend on the UI thread, on purpose, so that you can see the freeze that chapter 04 removes. Requirements: D-04, D-05, D-06 (and the request side of D-14, D-15, D-17).

## Predict before you run
With the backend running and no sign-in: what does `GET /health` show, and what does `GET /v1/me` show? With the backend stopped, what does each show? Write your guesses down, then compare after "Run it".

## New C++ in this chapter
- **Templates**: `Result<T>` and `decode<T>` work for any type `T`; the compiler writes one version per type you use. An *alias template* (`template <class T> using Result = ...`) is a name for a family of types.
- **`std::optional<T>`**: "a `T` or nothing". Used for fields the JSON can set to `null` (`dueDate`) and for the paging cursor.
- **`tl::expected<T, E>`**: "a `T` or an error `E`", the same interface as C++23 `std::expected`. `if (result)` asks "is there a value?", `*result` or `result->` reads it, `result.error()` reads the error.
- **Lambdas and `std::function`**: `[](std::stop_token) { ... }` is an unnamed function object; `std::function<R(Args...)>` can hold any such callable. Here it carries "how to get a token".
- **`virtual`, `override`, `final`**: `Transport` is an interface (pure virtual function), `CprTransport` implements it.
- **`std::stop_token`** is passed through every call in this chapter; chapter 03 and 04 explain what it does. Here only know: if someone requests a stop, a running request is aborted.

## Before you start
- Finish chapter 01 or extract `desktop-cpp-phase-2-http.zip` and open `02-http-and-json-client/code`.
- Start the platform and a backend (any one): see [platform README](../../../platform/README.md) and the backend capstone's run command. The backend must answer `http://localhost:8000/health`. Check with `curl http://localhost:8000/health`.
- Read platform primer 02 (HTTP and REST) if status codes and headers are new.

## What is new, what is unchanged
Unchanged from chapter 01 (copy them from the pack or from chapter 01, where they are shown in full): `CMakePresets.json`, `.gitignore`, `src/app/Platform.hpp`, `src/app/Theme.hpp`. New files: `src/core/Result.hpp`, `src/core/Util.hpp`, `src/core/Config.hpp`, `src/net/Transport.hpp`, `src/net/CprTransport.hpp`, `src/net/CprTransport.cpp`, `src/api/Models.hpp`, `src/api/ApiClient.hpp`, `src/api/ApiClient.cpp`. Changed: `vcpkg.json`, `CMakeLists.txt`, `src/main.cpp`, `src/app/App.hpp`, `src/app/App.cpp`.

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
    "tl-expected"
  ]
}
```
Three new libraries: `cpr` (C++ Requests, a friendly wrapper around libcurl), `nlohmann-json` (JSON), `tl-expected` (the `expected` type).

### Step 2. Replace `CMakeLists.txt`
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

add_library(tasks_warnings INTERFACE)
target_compile_options(tasks_warnings INTERFACE
    $<$<CXX_COMPILER_ID:MSVC>:/W4 /permissive- /utf-8>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall -Wextra -Wpedantic>)

# Everything that needs neither a window nor Dear ImGui: unit tests link this library.
add_library(tasks_core STATIC
    src/net/CprTransport.cpp
    src/api/ApiClient.cpp)
target_include_directories(tasks_core PUBLIC src)
target_link_libraries(tasks_core PUBLIC tasks_warnings cpr::cpr nlohmann_json::nlohmann_json tl::expected spdlog::spdlog)

add_executable(tasks_desktop src/main.cpp src/app/App.cpp)
target_link_libraries(tasks_desktop PRIVATE tasks_core SDL3::SDL3 imgui::imgui)
```
The new part is the static library `tasks_core`: the code that needs neither SDL nor Dear ImGui. `PUBLIC` means "my users also get this": anything that links `tasks_core` can include from `src/` and use cpr, JSON, expected and spdlog. The executable now links the library plus the two window libraries. Header-only files such as `Result.hpp` need no entry in the list.

### Step 3. Create `src/core/Result.hpp`
**File: `src/core/Result.hpp`**
```cpp
#pragma once

#include <nlohmann/json.hpp>
#include <tl/expected.hpp>

#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace tt {

enum class ErrorKind { Network, Http, Parse, Auth, Config, Cancelled };

struct FieldError {
    std::string pointer;  // JSON Pointer (RFC 6901), for example "/title"
    std::string detail;
};

// One error type for every layer: transport, HTTP problem details, parsing, sign-in and configuration.
struct Problem {
    ErrorKind kind{ErrorKind::Http};
    int status{0};
    std::string type;
    std::string title;
    std::string detail;
    std::string traceId;
    std::vector<FieldError> errors;
    std::optional<int> retryAfterSeconds;
};

// tl::expected has the interface of C++23 std::expected, so a later move to the standard type is a rename.
template <class T>
using Result = tl::expected<T, Problem>;

[[nodiscard]] inline tl::unexpected<Problem> failure(ErrorKind kind, std::string title, std::string detail = {}) {
    Problem problem;
    problem.kind = kind;
    problem.title = std::move(title);
    problem.detail = std::move(detail);
    return tl::make_unexpected(std::move(problem));
}

// "https://code101.example/problems/not-found" gives "not-found".
[[nodiscard]] inline std::string problemSlug(const Problem& problem) {
    const auto slash = problem.type.rfind('/');
    return slash == std::string::npos ? problem.type : problem.type.substr(slash + 1);
}

[[nodiscard]] inline std::string jsonString(const nlohmann::json& json, const char* key) {
    const auto found = json.find(key);
    return (found != json.end() && found->is_string()) ? found->get<std::string>() : std::string{};
}

[[nodiscard]] inline std::optional<std::string> jsonOptString(const nlohmann::json& json, const char* key) {
    const auto found = json.find(key);
    if (found == json.end() || !found->is_string()) {
        return std::nullopt;
    }
    return found->get<std::string>();
}

}  // namespace tt
```
`Problem` mirrors RFC 9457 (`type`, `title`, `status`, `detail`) plus our extension `traceId`, the `errors` list of invalid fields, and `kind`, which says *where* the failure happened: no connection (`Network`), a non-2xx answer (`Http`), an answer we could not read (`Parse`), a sign-in failure (`Auth`), bad settings (`Config`) or a user cancel (`Cancelled`). `failure(...)` builds the error half of a `Result`. `jsonString` returns an empty string for a missing or non-string member, so reading optional members never throws.

### Step 4. Create `src/core/Util.hpp`
**File: `src/core/Util.hpp`**
```cpp
#pragma once

#include <cstdlib>
#include <memory>
#include <string>
#include <string_view>

namespace tt {

// RFC 3986: letters, digits and - . _ ~ stay; every other byte becomes %XX.
[[nodiscard]] inline std::string urlEncode(std::string_view text) {
    static constexpr char kHex[] = "0123456789ABCDEF";
    std::string out;
    out.reserve(text.size());
    for (const unsigned char c : text) {
        const bool unreserved = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') ||
                                c == '-' || c == '.' || c == '_' || c == '~';
        if (unreserved) {
            out.push_back(static_cast<char>(c));
        } else {
            out.push_back('%');
            out.push_back(kHex[c >> 4]);
            out.push_back(kHex[c & 0x0F]);
        }
    }
    return out;
}

// Builds "a=1&b=2" with every name and value encoded. Used for query strings and form bodies.
class QueryBuilder {
public:
    QueryBuilder& add(std::string_view name, std::string_view value) {
        if (!text_.empty()) {
            text_.push_back('&');
        }
        text_ += urlEncode(name);
        text_.push_back('=');
        text_ += urlEncode(value);
        return *this;
    }

    [[nodiscard]] const std::string& str() const noexcept { return text_; }
    [[nodiscard]] bool empty() const noexcept { return text_.empty(); }

private:
    std::string text_;
};

// The value of an environment variable, or `fallback` when it is unset or empty.
[[nodiscard]] inline std::string envOr(const char* name, std::string fallback) {
#ifdef _MSC_VER
    char* raw = nullptr;
    std::size_t size = 0;
    if (_dupenv_s(&raw, &size, name) != 0 || raw == nullptr) {
        return fallback;
    }
    const std::unique_ptr<char, decltype(&std::free)> holder{raw, &std::free};
    return *holder != '\0' ? std::string{holder.get()} : fallback;
#else
    const char* value = std::getenv(name);
    return (value != nullptr && *value != '\0') ? std::string{value} : fallback;
#endif
}

}  // namespace tt
```
`urlEncode` is the rule that keeps user text, ids and cursors from changing the meaning of a URL (a space becomes `%20`, `&` becomes `%26`). `QueryBuilder` chains `add` calls. `envOr` reads an environment variable; the `#ifdef _MSC_VER` branch exists only because Microsoft's compiler marks `getenv` as unsafe and offers `_dupenv_s`, whose result must be released with `free`: the `unique_ptr` with `std::free` as its deleter does that (the only place the word `free` appears in the app).

### Step 5. Create `src/core/Config.hpp`
**File: `src/core/Config.hpp`**
```cpp
#pragma once

#include "core/Util.hpp"

#include <string>

namespace tt {

struct Config {
    std::string apiBaseUrl;
    std::string issuer;
    std::string clientId{"tasks-desktop"};
    std::string scope{"openid profile email tasks:read tasks:write"};
};

// Defaults match the platform: API on 8000, Keycloak realm tasksteams on 8180.
[[nodiscard]] inline Config loadConfig() {
    Config config;
    config.apiBaseUrl = envOr("API_BASE_URL", "http://localhost:8000");
    config.issuer = envOr("OIDC_ISSUER", "http://localhost:8180/realms/tasksteams");
    return config;
}

}  // namespace tt
```
The scope string is written once, here (requirement D-11). The URLs can be overridden with the environment variables `API_BASE_URL` and `OIDC_ISSUER`. Chapter 05 adds validation of these values.

### Step 6. Create `src/net/Transport.hpp`
**File: `src/net/Transport.hpp`**
```cpp
#pragma once

#include "core/Result.hpp"

#include <algorithm>
#include <cctype>
#include <charconv>
#include <chrono>
#include <map>
#include <stop_token>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

namespace tt {

enum class Method { Get, Post, Put, Patch, Delete };

using Headers = std::vector<std::pair<std::string, std::string>>;

// HTTP header names are case-insensitive (platform TDD section 12.1: Go sends "Etag").
struct CaseInsensitiveLess {
    bool operator()(const std::string& a, const std::string& b) const {
        return std::lexicographical_compare(a.begin(), a.end(), b.begin(), b.end(), [](unsigned char x, unsigned char y) {
            return std::tolower(x) < std::tolower(y);
        });
    }
};

struct HttpRequest {
    Method method{Method::Get};
    std::string url;
    Headers headers;
    std::string body;
    std::chrono::milliseconds timeout{10'000};
};

struct HttpResponse {
    int status{0};
    std::string body;
    std::map<std::string, std::string, CaseInsensitiveLess> headers;

    [[nodiscard]] std::string header(const std::string& name) const {
        const auto found = headers.find(name);
        return found == headers.end() ? std::string{} : found->second;
    }
};

// The only door to the network. Tests use a fake; the app uses CprTransport.
class Transport {
public:
    Transport() = default;
    Transport(const Transport&) = delete;
    Transport& operator=(const Transport&) = delete;
    virtual ~Transport() = default;

    // A reply with any HTTP status is a success here; only "no reply" is an error.
    virtual Result<HttpResponse> send(const HttpRequest& request, std::stop_token stop) = 0;
};

// Turns a non-2xx reply into a Problem. Reads RFC 9457 members when the body has them.
[[nodiscard]] inline Problem problemFromResponse(const HttpResponse& response) {
    Problem problem;
    problem.kind = ErrorKind::Http;
    problem.status = response.status;
    problem.title = "HTTP " + std::to_string(response.status);

    const std::string retry = response.header("Retry-After");
    int seconds = 0;
    if (!retry.empty() && std::from_chars(retry.data(), retry.data() + retry.size(), seconds).ec == std::errc{}) {
        problem.retryAfterSeconds = seconds;
    }

    const auto json = nlohmann::json::parse(response.body, nullptr, false);
    if (!json.is_object()) {
        return problem;
    }
    problem.type = jsonString(json, "type");
    if (auto title = jsonString(json, "title"); !title.empty()) {
        problem.title = std::move(title);
    }
    problem.detail = jsonString(json, "detail");
    problem.traceId = jsonString(json, "traceId");
    const auto errors = json.find("errors");
    if (errors != json.end() && errors->is_array()) {
        for (const auto& item : *errors) {
            problem.errors.push_back(FieldError{jsonString(item, "pointer"), jsonString(item, "detail")});
        }
    }
    return problem;
}

}  // namespace tt
```
`Transport` is an *interface*: one pure virtual function `send`. The deleted copy operations and the virtual destructor are the standard recipe for a polymorphic base class (Core Guidelines C.35, C.67). `HttpResponse::headers` uses a `std::map` with `CaseInsensitiveLess`, so `response.header("etag")` finds `ETag` and `Etag`. The important design decision is in the comment: a 404 or a 500 is still a *reply*, so `send` succeeds; the next layer decides what a status means. `problemFromResponse` reads `Retry-After` (seconds) and the RFC 9457 members. `json::parse(text, nullptr, false)` is the non-throwing form: it returns a "discarded" value for bad JSON, and `is_object()` is then false, so a body that is not JSON (an HTML error page from a proxy) just keeps the generic title "HTTP 502".

### Step 7. Create `src/net/CprTransport.hpp`
**File: `src/net/CprTransport.hpp`**
```cpp
#pragma once

#include "net/Transport.hpp"

namespace tt {

// Transport on top of cpr (libcurl). Every call builds its own cpr::Session, so one object can be shared by threads.
class CprTransport final : public Transport {
public:
    Result<HttpResponse> send(const HttpRequest& request, std::stop_token stop) override;
};

}  // namespace tt
```
`override` makes the compiler check that this really replaces a base function; `final` says nobody derives from this class.

### Step 8. Create `src/net/CprTransport.cpp`
**File: `src/net/CprTransport.cpp`**
```cpp
#include "net/CprTransport.hpp"

#include <cpr/cpr.h>
#include <spdlog/spdlog.h>

#include <chrono>
#include <cstdint>

namespace tt {
namespace {

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

    cpr::Response reply = perform(session, request.method);
    if (reply.error.code == cpr::ErrorCode::ABORTED_BY_CALLBACK) {
        return failure(ErrorKind::Cancelled, "Cancelled");
    }
    if (reply.error.code != cpr::ErrorCode::OK) {
        return failure(ErrorKind::Network, "Cannot reach the server", reply.error.message);
    }
    spdlog::debug("{} {} -> {}", methodName(request.method), request.url, reply.status_code);

    HttpResponse response;
    response.status = static_cast<int>(reply.status_code);
    response.body = std::move(reply.text);
    for (const auto& [name, value] : reply.header) {
        response.headers.emplace(name, value);
    }
    return response;
}

}  // namespace tt
```
Reading it in order: a fresh `cpr::Session` per call (no shared state, so any thread may call `send`); URL, headers, a 10 second total timeout (`request.timeout`) and a 3 second connect timeout; **redirects off** (`Redirect(false)`), because libcurl would otherwise follow a 301 to another host and could send the bearer token there; TLS verification stays at libcurl's default (on). The progress callback is the cancellation hook: libcurl calls it during the transfer, and returning `false` aborts with `ABORTED_BY_CALLBACK`, which we turn into `ErrorKind::Cancelled`. The generic lambda `[&stop](auto, auto, auto, auto, std::intptr_t)` accepts the four byte counters and the user-data value and ignores them. A curl-level failure (no connection, DNS, timeout) is `ErrorKind::Network` with curl's own message. Only method, URL and status are logged, never headers or bodies (D-05).

### Step 9. Create `src/api/Models.hpp`
**File: `src/api/Models.hpp`**
```cpp
#pragma once

#include "core/Result.hpp"

#include <array>
#include <optional>
#include <string>
#include <vector>

namespace tt {

inline constexpr std::array<const char*, 5> kStatuses{"todo", "in_progress", "blocked", "done", "cancelled"};
inline constexpr std::array<const char*, 4> kPriorities{"low", "medium", "high", "urgent"};

struct Health {
    std::string status;
    std::string database;
};

struct MeTeam {
    std::string teamId;
    std::string name;
    std::string role;
};

struct Me {
    std::string id;
    std::string username;
    std::string displayName;
    std::vector<std::string> roles;
    std::vector<std::string> scopes;
    std::vector<MeTeam> teams;
};

struct Team {
    std::string id;
    std::string name;
    std::string description;
    int memberCount{0};
    int version{0};
};

struct Project {
    std::string id;
    std::string teamId;
    std::string key;
    std::string name;
    bool archived{false};
    int version{0};
};

struct Task {
    std::string id;
    std::string projectId;
    std::string title;
    std::string description;
    std::string status;
    std::string priority;
    std::optional<std::string> assigneeId;
    std::optional<std::string> dueDate;
    int version{0};
    std::string updatedAt;
};

struct TaskCreate {
    std::string title;
    std::string description;
    std::string priority{"medium"};
    std::optional<std::string> dueDate;
};

template <class T>
struct Page {
    std::vector<T> items;
    std::optional<std::string> nextCursor;  // empty on the last page; opaque, never parse it
};

// nlohmann/json finds these through argument-dependent lookup when `.get<T>()` is called.
inline void from_json(const nlohmann::json& json, Health& health) {
    health.status = jsonString(json, "status");
    health.database = jsonString(json, "database");
}

inline void from_json(const nlohmann::json& json, MeTeam& team) {
    team.teamId = json.at("teamId").get<std::string>();
    team.name = json.at("name").get<std::string>();
    team.role = json.at("role").get<std::string>();
}

inline void from_json(const nlohmann::json& json, Me& me) {
    me.id = json.at("id").get<std::string>();
    me.username = json.at("username").get<std::string>();
    me.displayName = json.at("displayName").get<std::string>();
    me.roles = json.at("roles").get<std::vector<std::string>>();
    me.scopes = json.at("scopes").get<std::vector<std::string>>();
    me.teams = json.at("teams").get<std::vector<MeTeam>>();
}

inline void from_json(const nlohmann::json& json, Team& team) {
    team.id = json.at("id").get<std::string>();
    team.name = json.at("name").get<std::string>();
    team.description = jsonString(json, "description");
    team.memberCount = json.at("memberCount").get<int>();
    team.version = json.at("version").get<int>();
}

inline void from_json(const nlohmann::json& json, Project& project) {
    project.id = json.at("id").get<std::string>();
    project.teamId = json.at("teamId").get<std::string>();
    project.key = json.at("key").get<std::string>();
    project.name = json.at("name").get<std::string>();
    project.archived = json.at("archived").get<bool>();
    project.version = json.at("version").get<int>();
}

inline void from_json(const nlohmann::json& json, Task& task) {
    task.id = json.at("id").get<std::string>();
    task.projectId = json.at("projectId").get<std::string>();
    task.title = json.at("title").get<std::string>();
    task.description = jsonString(json, "description");
    task.status = json.at("status").get<std::string>();
    task.priority = json.at("priority").get<std::string>();
    task.assigneeId = jsonOptString(json, "assigneeId");
    task.dueDate = jsonOptString(json, "dueDate");
    task.version = json.at("version").get<int>();
    task.updatedAt = jsonString(json, "updatedAt");
}

template <class T>
void from_json(const nlohmann::json& json, Page<T>& page) {
    page.items = json.at("items").get<std::vector<T>>();
    page.nextCursor = jsonOptString(json.at("page"), "nextCursor");
}

[[nodiscard]] inline nlohmann::json toJson(const TaskCreate& task) {
    nlohmann::json json = nlohmann::json::object();
    json["title"] = task.title;
    json["description"] = task.description;
    json["priority"] = task.priority;
    if (task.dueDate) {
        json["dueDate"] = *task.dueDate;
    }
    return json;
}

// A bad UTF-8 byte is replaced instead of throwing from dump().
[[nodiscard]] inline std::string dumpJson(const nlohmann::json& json) {
    return json.dump(-1, ' ', false, nlohmann::json::error_handler_t::replace);
}

// Parses a body into T. Any missing or mistyped field becomes a Parse problem.
template <class T>
[[nodiscard]] Result<T> decode(const std::string& body) {
    try {
        return nlohmann::json::parse(body).get<T>();
    } catch (const nlohmann::json::exception& error) {
        return failure(ErrorKind::Parse, "The server answer was not understood", error.what());
    }
}

}  // namespace tt
```
Only the fields the screens use are modelled; extra JSON members are ignored, which keeps the client working when the server adds optional fields (additive changes stay in `/v1`). A function named `from_json(const json&, T&)` in the same namespace as `T` is all `nlohmann::json` needs: `json.get<Task>()` finds it. `.at("id")` throws if the key is missing, `jsonString` does not: required fields use `.at`, tolerant ones use the helpers. Exceptions from nlohmann are caught in exactly one place, `decode`, and become a `Parse` problem (the "no exceptions across layers" rule, D-04). `kStatuses` and `kPriorities` are the allowed enum values; the form combos use them in chapter 04.

### Step 10. Create `src/api/ApiClient.hpp`
**File: `src/api/ApiClient.hpp`**
```cpp
#pragma once

#include "api/Models.hpp"
#include "net/Transport.hpp"

#include <functional>
#include <optional>
#include <stop_token>
#include <string>
#include <vector>

namespace tt {

// Returns the access token for the next call. An empty string means "send no Authorization header".
using TokenProvider = std::function<Result<std::string>(std::stop_token)>;

struct TaskQuery {
    std::vector<std::string> statuses;  // repeated `status` parameter
    std::string text;                   // `q`, a substring of the title
    std::string sort{"-createdAt"};
    int limit{25};
};

class ApiClient {
public:
    ApiClient(Transport& transport, std::string baseUrl, TokenProvider tokens);

    [[nodiscard]] Result<Health> health(std::stop_token stop = {}) const;
    [[nodiscard]] Result<Me> me(std::stop_token stop = {}) const;
    [[nodiscard]] Result<Page<Team>> listTeams(const std::optional<std::string>& cursor, std::stop_token stop = {}) const;
    [[nodiscard]] Result<Page<Project>> listProjects(const std::string& teamId, const std::optional<std::string>& cursor,
                                                      std::stop_token stop = {}) const;
    [[nodiscard]] Result<Page<Task>> listTasks(const std::string& projectId, const TaskQuery& query,
                                                const std::optional<std::string>& cursor, std::stop_token stop = {}) const;
    [[nodiscard]] Result<Task> getTask(const std::string& id, std::stop_token stop = {}) const;
    // `idempotencyKey` stays the same for every retry of one form; an empty key sends no header.
    [[nodiscard]] Result<Task> createTask(const std::string& projectId, const TaskCreate& body,
                                           const std::string& idempotencyKey, std::stop_token stop = {}) const;
    // `mergePatch` is an RFC 7396 JSON Merge Patch: only changed fields, null clears a nullable field.
    [[nodiscard]] Result<Task> updateTask(const std::string& id, int version, const nlohmann::json& mergePatch,
                                           std::stop_token stop = {}) const;
    [[nodiscard]] Result<void> deleteTask(const std::string& id, int version, std::stop_token stop = {}) const;

private:
    [[nodiscard]] Result<HttpResponse> call(Method method, const std::string& path, Headers headers, std::string body,
                                             bool authenticated, std::stop_token stop) const;

    template <class T>
    [[nodiscard]] Result<T> fetch(Method method, const std::string& path, Headers headers, std::string body,
                                   bool authenticated, std::stop_token stop) const;

    Transport* transport_;  // not owned
    std::string baseUrl_;
    TokenProvider tokens_;
};

}  // namespace tt
```
Every operation of the contract that the app uses is one method. `Transport*` is a *non-owning* pointer (Core Guidelines R.3): the caller owns the transport and must keep it alive longer than the client. `[[nodiscard]]` on every method means the compiler warns if you call `listTeams(...)` and throw the result away.

### Step 11. Create `src/api/ApiClient.cpp`
**File: `src/api/ApiClient.cpp`**
```cpp
#include "api/ApiClient.hpp"

#include "core/Util.hpp"

namespace tt {
namespace {

Headers jsonHeaders() { return Headers{{"Content-Type", "application/json"}}; }

std::string withQuery(std::string path, const QueryBuilder& query) {
    if (!query.empty()) {
        path += '?';
        path += query.str();
    }
    return path;
}

// A strong ETag is the quoted version: version 3 is sent as "3" including the quotes.
std::string quoted(int version) { return '"' + std::to_string(version) + '"'; }

}  // namespace

ApiClient::ApiClient(Transport& transport, std::string baseUrl, TokenProvider tokens)
    : transport_{&transport}, baseUrl_{std::move(baseUrl)}, tokens_{std::move(tokens)} {}

Result<HttpResponse> ApiClient::call(Method method, const std::string& path, Headers headers, std::string body,
                                     bool authenticated, std::stop_token stop) const {
    HttpRequest request;
    request.method = method;
    request.url = baseUrl_ + path;
    request.headers = std::move(headers);
    request.headers.emplace_back("Accept", "application/json");
    request.body = std::move(body);
    if (authenticated && tokens_) {
        auto token = tokens_(stop);
        if (!token) {
            return tl::make_unexpected(std::move(token.error()));
        }
        if (!token->empty()) {
            request.headers.emplace_back("Authorization", "Bearer " + *token);
        }
    }
    auto response = transport_->send(request, stop);
    if (!response) {
        return response;
    }
    if (response->status < 200 || response->status >= 300) {
        return tl::make_unexpected(problemFromResponse(*response));
    }
    return response;
}

template <class T>
Result<T> ApiClient::fetch(Method method, const std::string& path, Headers headers, std::string body,
                           bool authenticated, std::stop_token stop) const {
    auto response = call(method, path, std::move(headers), std::move(body), authenticated, stop);
    if (!response) {
        return tl::make_unexpected(std::move(response.error()));
    }
    return decode<T>(response->body);
}

Result<Health> ApiClient::health(std::stop_token stop) const {
    return fetch<Health>(Method::Get, "/health", {}, {}, false, stop);
}

Result<Me> ApiClient::me(std::stop_token stop) const {
    return fetch<Me>(Method::Get, "/v1/me", {}, {}, true, stop);
}

Result<Page<Team>> ApiClient::listTeams(const std::optional<std::string>& cursor, std::stop_token stop) const {
    QueryBuilder query;
    query.add("limit", "25");
    if (cursor) {
        query.add("cursor", *cursor);
    }
    return fetch<Page<Team>>(Method::Get, withQuery("/v1/teams", query), {}, {}, true, stop);
}

Result<Page<Project>> ApiClient::listProjects(const std::string& teamId, const std::optional<std::string>& cursor,
                                              std::stop_token stop) const {
    QueryBuilder query;
    query.add("limit", "25");
    if (cursor) {
        query.add("cursor", *cursor);
    }
    return fetch<Page<Project>>(Method::Get, withQuery("/v1/teams/" + urlEncode(teamId) + "/projects", query), {}, {},
                                true, stop);
}

Result<Page<Task>> ApiClient::listTasks(const std::string& projectId, const TaskQuery& query,
                                        const std::optional<std::string>& cursor, std::stop_token stop) const {
    QueryBuilder params;
    params.add("limit", std::to_string(query.limit));
    params.add("sort", query.sort);
    for (const auto& status : query.statuses) {
        params.add("status", status);
    }
    if (!query.text.empty()) {
        params.add("q", query.text);
    }
    if (cursor) {
        params.add("cursor", *cursor);
    }
    return fetch<Page<Task>>(Method::Get, withQuery("/v1/projects/" + urlEncode(projectId) + "/tasks", params), {}, {},
                             true, stop);
}

Result<Task> ApiClient::getTask(const std::string& id, std::stop_token stop) const {
    return fetch<Task>(Method::Get, "/v1/tasks/" + urlEncode(id), {}, {}, true, stop);
}

Result<Task> ApiClient::createTask(const std::string& projectId, const TaskCreate& body, const std::string& idempotencyKey,
                                   std::stop_token stop) const {
    Headers headers = jsonHeaders();
    if (!idempotencyKey.empty()) {
        headers.emplace_back("Idempotency-Key", idempotencyKey);
    }
    return fetch<Task>(Method::Post, "/v1/projects/" + urlEncode(projectId) + "/tasks", std::move(headers),
                       dumpJson(toJson(body)), true, stop);
}

Result<Task> ApiClient::updateTask(const std::string& id, int version, const nlohmann::json& mergePatch,
                                   std::stop_token stop) const {
    Headers headers{{"Content-Type", "application/merge-patch+json"}, {"If-Match", quoted(version)}};
    return fetch<Task>(Method::Patch, "/v1/tasks/" + urlEncode(id), std::move(headers), dumpJson(mergePatch), true,
                       stop);
}

Result<void> ApiClient::deleteTask(const std::string& id, int version, std::stop_token stop) const {
    auto response = call(Method::Delete, "/v1/tasks/" + urlEncode(id), Headers{{"If-Match", quoted(version)}}, {}, true,
                         stop);
    if (!response) {
        return tl::make_unexpected(std::move(response.error()));
    }
    return {};
}

}  // namespace tt
```
Walk through `call`: it builds the URL, adds `Accept`, asks the token provider for a token (only for authenticated calls, and sends no header when the provider returns an empty string, which is how this chapter shows a 401), sends, and turns a non-2xx reply into a `Problem`. `fetch<T>` adds decoding. Everything else is a thin method per operation:
- **IDs in paths** go through `urlEncode`: the ids come from the server, and we do not trust any string to be safe inside a path.
- **Paging**: `limit` is 25 and `cursor` is copied unchanged from `page.nextCursor`.
- **Filtering**: `status` is added once per selected status (repeatable parameter), `q` only when not empty.
- **Create**: the `Idempotency-Key` header, supplied by the caller and identical for every retry of the same form.
- **Update**: `If-Match` carries the *quoted* version (`"3"`), `Content-Type: application/merge-patch+json` tells the server this is a Merge Patch.
- **Delete**: `If-Match` too; success is 204 with no body, so `Result<void>`.

### Step 12. Replace `src/app/App.hpp`
**File: `src/app/App.hpp`**
```cpp
#pragma once

#include "api/ApiClient.hpp"
#include "app/Platform.hpp"
#include "core/Config.hpp"
#include "net/CprTransport.hpp"

#include <string>

namespace tt {

class App {
public:
    explicit App(Config config);

    // Runs until the window is closed or Quit is pressed. Returns the process exit code.
    int run();

private:
    void drawFrame();
    void drawProbe();

    SdlRuntime sdl_;
    Window window_;
    ImGuiLayer imgui_;
    Config config_;
    CprTransport transport_;
    ApiClient api_;
    std::string probeText_{"Press a button."};
    bool quit_{false};
};

}  // namespace tt
```
`transport_` is declared before `api_` because the client keeps a pointer to it: construction order is declaration order.

### Step 13. Replace `src/app/App.cpp`
**File: `src/app/App.cpp`**
```cpp
#include "app/App.hpp"

#include <utility>

namespace tt {
namespace {

const char* kindName(ErrorKind kind) {
    switch (kind) {
        case ErrorKind::Network: return "network";
        case ErrorKind::Http: return "http";
        case ErrorKind::Parse: return "parse";
        case ErrorKind::Auth: return "auth";
        case ErrorKind::Config: return "config";
        case ErrorKind::Cancelled: return "cancelled";
    }
    return "?";
}

// Every field of the problem, so that you can see what the server really sent.
std::string describe(const Problem& problem) {
    std::string text = std::string{"kind: "} + kindName(problem.kind) + "\n";
    text += "status: " + std::to_string(problem.status) + "\n";
    text += "type: " + problem.type + "\n";
    text += "title: " + problem.title + "\n";
    text += "detail: " + problem.detail + "\n";
    text += "traceId: " + problem.traceId + "\n";
    for (const auto& error : problem.errors) {
        text += "field " + error.pointer + ": " + error.detail + "\n";
    }
    return text;
}

}  // namespace

App::App(Config config)
    : window_{"Tasks and Teams", 1100, 720},
      imgui_{window_, window_.displayScale()},
      config_{std::move(config)},
      api_{transport_, config_.apiBaseUrl, [](std::stop_token) { return Result<std::string>(std::string{}); }} {}

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
        imgui_.beginFrame();
        drawFrame();
        imgui_.endFrame(window_.renderer());
    }
    return 0;
}

void App::drawFrame() {
    const ImGuiViewport* viewport = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(viewport->WorkPos);
    ImGui::SetNextWindowSize(viewport->WorkSize);
    constexpr ImGuiWindowFlags kFlags =
        ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoSavedSettings;
    if (ImGui::Begin("Tasks and Teams", nullptr, kFlags)) {
        ImGui::TextUnformatted("Tasks and Teams");
        ImGui::Separator();
        drawProbe();
        ImGui::Separator();
        ImGui::Text("%.1f frames per second", ImGui::GetIO().Framerate);
        if (ImGui::Button("Quit")) {
            quit_ = true;
        }
    }
    ImGui::End();
}

void App::drawProbe() {
    ImGui::SeparatorText("Probe the API");
    ImGui::TextWrapped("API base URL: %s", config_.apiBaseUrl.c_str());
    ImGui::TextDisabled("These buttons call the backend on the UI thread, so the window freezes until the answer or the timeout. Chapter 04 fixes that.");
    if (ImGui::Button("GET /health")) {
        const auto health = api_.health();
        probeText_ = health ? "status: " + health->status + "\ndatabase: " + health->database : describe(health.error());
    }
    ImGui::SameLine();
    if (ImGui::Button("GET /v1/me without a token")) {
        const auto me = api_.me();
        probeText_ = me ? "Hello " + me->username : describe(me.error());
    }
    ImGui::TextWrapped("%s", probeText_.c_str());
}

}  // namespace tt
```
The token provider here is `[](std::stop_token) { return Result<std::string>(std::string{}); }`: "success, with an empty token", so the second button sends the request *without* an `Authorization` header and the backend must answer 401. `describe` prints every `Problem` field so that you see exactly what RFC 9457 looks like on the wire. Server text is drawn with `"%s"` as the argument, never as the format string (`TextWrapped("%s", probeText_.c_str())`).

### Step 14. Replace `src/main.cpp`
**File: `src/main.cpp`**
```cpp
#include "app/App.hpp"
#include "core/Config.hpp"

#include <spdlog/cfg/env.h>
#include <spdlog/spdlog.h>

#include <exception>

int main() {
    try {
        spdlog::cfg::load_env_levels();
        spdlog::set_pattern("%H:%M:%S.%e [%^%l%$] %v");
        spdlog::info("Tasks and Teams desktop starting");
        tt::App app{tt::loadConfig()};
        const int exitCode = app.run();
        spdlog::info("clean shutdown");
        return exitCode;
    } catch (const std::exception& error) {
        spdlog::critical("fatal: {}", error.what());
        return 1;
    }
}
```
`spdlog::cfg::load_env_levels()` reads the `SPDLOG_LEVEL` environment variable, so `SPDLOG_LEVEL=debug` shows the request lines from `CprTransport`.

## Run it
**For a later session only; this snapshot has not been run.** From the `code` folder, with the platform and a backend running.

**Command (Windows, PowerShell):**
```powershell
cmake --preset windows
cmake --build --preset windows-debug
$env:SPDLOG_LEVEL = "debug"
.\build\windows\out\tasks_desktop.exe
```
**Command (Linux and macOS):** the same with the `linux` or `macos` presets, `export SPDLOG_LEVEL=debug` and `./build/<preset>/out/tasks_desktop`.

Expected, typical, backend running: after "GET /health" the text area shows `status: ok` and `database: up`; the log shows `GET http://localhost:8000/health -> 200`. After "GET /v1/me without a token" it shows `kind: http`, `status: 401`, a `type` that ends with `/unauthorized`, the title `Unauthorized` and a `traceId`. The exact wording and the trace id come from your backend. Backend stopped: both buttons show `kind: network`, the title `Cannot reach the server` and a libcurl message (typical: "Could not connect to server" or "Failed to connect to localhost port 8000"); the window is frozen for up to the connect timeout of 3 seconds while you wait.

## How it works
- The answers to the prediction are the previous paragraph. The freeze is the lesson: `api_.health()` runs *inside* the frame function, so the frame cannot finish until the network answers.
- **Layers.** `ApiClient` knows paths, headers and JSON but not libcurl; `CprTransport` knows libcurl but not paths. A test can pass a fake `Transport`; chapter 05 does.
- **Errors are values.** Every function that can fail returns `Result<T>`. The caller cannot forget the failure path without the code looking wrong (`*result` on an error is a bug you can see). Exceptions remain only for "cannot start at all".
- **Three levels of "failed".** No connection (`Network`), a non-2xx answer with a body (`Http` with RFC 9457 members), and a 2xx answer with a body we cannot read (`Parse`).
- **Why a custom `Problem`, not `std::error_code`.** The UI needs a title, detail, trace id and field errors; an error code carries none of them.
- **Security by default.** No redirects (a redirect could carry the bearer token to another host), TLS verification on, timeouts on every call, ids encoded before they enter a path, no secrets in logs.

## Try it
Extend `QueryBuilder` (one file, `src/core/Util.hpp`).

Where: the `code` folder.

**Command (Windows, PowerShell):**
```powershell
Copy-Item ..\exercise\starter\src\core\Util.hpp src\core\Util.hpp -Force
```
**Command (macOS and Linux):**
```bash
cp ../exercise/starter/src/core/Util.hpp src/core/Util.hpp
```
The starter is the file from Step 4 with two `TODO` comments. Rung 1: add `addAll(name, values)` that repeats a parameter. Rung 2: add `addIf(name, optional)`. Rung 3 (open, not in the solution file): use both in `ApiClient::listTasks` instead of the `for` loop and the `if` statements, and check that the URL is unchanged.

<details><summary>Solution (rungs 1 and 2)</summary>

**File: `../exercise/solution/src/core/Util.hpp`**
```cpp
#pragma once

#include <cstdlib>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace tt {

// RFC 3986: letters, digits and - . _ ~ stay; every other byte becomes %XX.
[[nodiscard]] inline std::string urlEncode(std::string_view text) {
    static constexpr char kHex[] = "0123456789ABCDEF";
    std::string out;
    out.reserve(text.size());
    for (const unsigned char c : text) {
        const bool unreserved = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') ||
                                c == '-' || c == '.' || c == '_' || c == '~';
        if (unreserved) {
            out.push_back(static_cast<char>(c));
        } else {
            out.push_back('%');
            out.push_back(kHex[c >> 4]);
            out.push_back(kHex[c & 0x0F]);
        }
    }
    return out;
}

// Builds "a=1&b=2" with every name and value encoded. Used for query strings and form bodies.
class QueryBuilder {
public:
    QueryBuilder& add(std::string_view name, std::string_view value) {
        if (!text_.empty()) {
            text_.push_back('&');
        }
        text_ += urlEncode(name);
        text_.push_back('=');
        text_ += urlEncode(value);
        return *this;
    }

    // Repeats the parameter once per value: addAll("status", {"todo", "done"}) gives status=todo&status=done.
    QueryBuilder& addAll(std::string_view name, const std::vector<std::string>& values) {
        for (const auto& value : values) {
            add(name, value);
        }
        return *this;
    }

    // Adds the parameter only when the optional holds a value.
    QueryBuilder& addIf(std::string_view name, const std::optional<std::string>& value) {
        if (value) {
            add(name, *value);
        }
        return *this;
    }

    [[nodiscard]] const std::string& str() const noexcept { return text_; }
    [[nodiscard]] bool empty() const noexcept { return text_.empty(); }

private:
    std::string text_;
};

// The value of an environment variable, or `fallback` when it is unset or empty.
[[nodiscard]] inline std::string envOr(const char* name, std::string fallback) {
#ifdef _MSC_VER
    char* raw = nullptr;
    std::size_t size = 0;
    if (_dupenv_s(&raw, &size, name) != 0 || raw == nullptr) {
        return fallback;
    }
    const std::unique_ptr<char, decltype(&std::free)> holder{raw, &std::free};
    return *holder != '\0' ? std::string{holder.get()} : fallback;
#else
    const char* value = std::getenv(name);
    return (value != nullptr && *value != '\0') ? std::string{value} : fallback;
#endif
}

}  // namespace tt
```
Each new method returns `*this`, like `add`, so calls can be chained. `addAll` reuses `add`, so encoding stays in one place.

</details>

## Check yourself
1. Why does `Transport::send` succeed for a 500 reply?
   <details><summary>Answer</summary>Because the network worked; what a status means is a decision of the API layer, which turns it into a `Problem`.</details>
2. What does `Redirect(false)` protect against?
   <details><summary>Answer</summary>A redirect to another host would make libcurl resend the request there, possibly with the bearer token.</details>
3. Why is the `Idempotency-Key` a parameter and not created inside `createTask`?
   <details><summary>Answer</summary>A retry must use the same key as the first attempt; only the caller knows what a retry is.</details>
4. Why are ids passed through `urlEncode`?
   <details><summary>Answer</summary>Server data is not trusted to be path-safe; encoding keeps `/`, `?` and `#` from changing the URL.</details>

## Common mistakes
| Symptom (typical message) | Cause | Fix |
|---|---|---|
| `Could not find a package configuration file provided by "tl-expected"` | wrong package name in `find_package` | it is `tl-expected` with a hyphen; the target is `tl::expected` |
| Compile error about `from_json` ambiguity | a `from_json` declared in the wrong namespace | keep it in `namespace tt`, next to the type |
| `kind: network`, "Could not connect to server" | backend not started, wrong port or `API_BASE_URL` | start the backend; check `curl http://localhost:8000/health` |
| Window frozen for a few seconds on a click | expected in this chapter (blocking call on the UI thread) | chapter 04 |
| Link error about `cpr::` symbols | `cpr::cpr` missing from `tasks_core` | restore Step 2 |
| `kind: parse` after a successful reply | the server sent a field of another type | read the `detail` text; it names the JSON member |

## Best practice
- Core Guidelines E.27 (if you cannot use exceptions, use error codes systematically: here `Result` everywhere), I.10 (signal a failure to do a required task; here with `Result`), F.16 (pass cheap types by value, others by `const &`), F.20 (return values, not output parameters), C.35 (a base class destructor is virtual), C.67 (a polymorphic class suppresses copying), R.3 (a raw pointer is non-owning), ES.45 (no magic numbers: named timeouts in the transport grow into constants in chapter 05).
- Parse at the edge: after `decode`, the rest of the app only sees typed data.
- One translation point per concern: status to `Problem` in `ApiClient::call`, JSON errors to `Parse` in `decode`.

## Going further
- Replace the `Transport` pointer with `std::reference_wrapper` or `gsl::not_null` and discuss the trade-off.
- Read how `Retry-After` can also be an HTTP date; add that case to `problemFromResponse`.
- Add `listMembers(teamId)` for the contract's members endpoint and decode `Member`.

## Summary
The app can talk to the contract through one interface that returns values or problems, with timeouts, no redirects, encoded paths, `If-Match`, merge patch and idempotency keys already in place. The blocking probe shows why the next chapters move calls off the UI thread, but first the app has to sign in.

## Next lesson
[03. Auth with PKCE](../phase-3-auth/03-auth-pkce.md): sign in with the system browser and keep the tokens in memory.
