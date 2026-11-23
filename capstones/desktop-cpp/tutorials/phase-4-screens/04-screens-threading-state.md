---
track: capstone
level: 201
phase: 4
phase_name: screens
lesson: 04
title: "Screens, threading and state"
time: 150 min
prerequisites: [capstone-desktop-cpp-03, platform-primers-03]
versions: { cpp: "20", imgui: "baseline port (SDL3 renderer backend)", vcpkg_baseline: "9eec002df1cd109f8f104cd966a763daf9751489" }
verified: not yet run
source: capstones/desktop-cpp/source/phase-4-screens/04-screens-threading-state/
---

# 04. Screens, threading and state

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## Why it matters
This is where the app becomes useful, and where most desktop apps go wrong: a slow network freezes the window, an old answer overwrites a new one, an error is shown as "failed" with no reason, and a double click creates two items. Each of these has a small, specific cure, and the cures are all in this chapter.

## What you will build
Teams, projects and a filtered, sorted, paged task table; a form that creates and edits tasks; a conflict dialog for the 412 case; delete with confirmation; a banner that shows RFC 9457 problems in plain words with the technical details below; and field errors from 422 answers next to the fields. All requests run on workers and are applied on the UI thread, stale answers are dropped, and the window closes cleanly. Requirements: D-12 to D-20 and D-25.

## Predict before you run
(1) You click a team, then a different team a moment later, and the first answer arrives *after* the second. Which projects are shown? (2) You double-click Save on a new task. How many tasks are created? (3) You close the window while a task list is loading. What happens to that request? Write your answers; they are in "How it works".

## New C++ in this chapter
- **Generation counters** (a plain `std::uint64_t`) to recognise stale answers.
- **Function templates with deduced parameters**: `applyPage(PagedList<T>&, ..., Result<Page<T>>)` works for teams, projects and tasks with one body.
- **`std::exchange`**: "take the value and leave a replacement behind" in one step, used to move a pending item out of the state.
- **Structured initialisation of aggregates** (`Conflict{taskId, title, patch}`) and **`std::array` as a fixed text buffer** for Dear ImGui text fields.
- **Lambdas with init-captures** (`[this, id = form.taskId, patch]`): copies of exactly the values the background job needs, so the job never touches state owned by the UI thread.

## Before you start
- Chapter 03 snapshot or `desktop-cpp-phase-4-screens.zip`; open `04-screens-threading-state/code`.
- Platform, one backend and the imported `tasks-desktop` client running (chapter 03).
- Know the contract's task rules: `If-Match`, merge patch, idempotency keys, cursor paging (platform TDD section 6).

## What is new, what is unchanged
New: `src/core/ProblemText.hpp`. Changed: `src/state/AppState.hpp`, `src/app/Controller.hpp`, `src/app/Controller.cpp`, `src/ui/Screens.cpp`. Unchanged from earlier chapters (copy them from the pack): `CMakeLists.txt`, `CMakePresets.json`, `vcpkg.json`, `.gitignore`, `keycloak/tasks-desktop-client.json`, `src/main.cpp`, `src/app/Platform.hpp`, `src/app/Theme.hpp`, `src/app/App.hpp`, `src/app/App.cpp`, `src/ui/Screens.hpp`, `src/core/Result.hpp`, `src/core/Util.hpp`, `src/core/Config.hpp`, `src/core/Concurrency.hpp`, `src/net/Transport.hpp`, `src/net/CprTransport.hpp`, `src/net/CprTransport.cpp`, `src/api/Models.hpp`, `src/api/ApiClient.hpp`, `src/api/ApiClient.cpp`, `src/auth/Secret.hpp`, `src/auth/Pkce.hpp`, `src/auth/Pkce.cpp`, `src/auth/LoopbackServer.hpp`, `src/auth/OidcClient.hpp`, `src/auth/OidcClient.cpp`, `src/auth/Session.hpp`, `src/auth/Session.cpp`. Chapter 02 shows `Result.hpp` to `ApiClient.cpp`; chapter 03 shows the `auth` files, `Concurrency.hpp`, `App.*`, `Screens.hpp` and the Keycloak file; chapter 01 shows the rest. No CMake change is needed: `ProblemText.hpp` is a header, and `Controller.cpp` and `Screens.cpp` were already in the build.

## Steps
### Step 1. Create `src/core/ProblemText.hpp`
**File: `src/core/ProblemText.hpp`**
```cpp
#pragma once

#include "core/Result.hpp"

#include <string>

namespace tt {

// The friendly sentence for a problem. The technical members (status, type, trace id) are shown on a second line.
[[nodiscard]] inline std::string userMessage(const Problem& problem) {
    switch (problem.kind) {
        case ErrorKind::Network:
            return "Cannot reach the server. Check that the backend is running and that the address is right.";
        case ErrorKind::Parse:
            return "The server sent an answer this app does not understand.";
        case ErrorKind::Cancelled:
            return "Cancelled.";
        case ErrorKind::Auth:
        case ErrorKind::Config:
            return problem.title;
        case ErrorKind::Http:
            break;
    }
    const std::string slug = problemSlug(problem);
    if (slug == "unauthorized") {
        return "Your session has ended. Sign in again.";
    }
    if (slug == "forbidden") {
        return "You are not allowed to do this.";
    }
    if (slug == "not-found") {
        return "This item no longer exists, or you cannot see it.";
    }
    if (slug == "conflict") {
        return "This conflicts with existing data, for example a duplicate name.";
    }
    if (slug == "precondition-failed") {
        return "Someone else changed this item. Reload it and try again.";
    }
    if (slug == "precondition-required") {
        return "The app did not send the version it was editing. This is a bug; please report it.";
    }
    if (slug == "validation-error") {
        return "Some fields are not valid. See the messages next to them.";
    }
    if (slug == "bad-request") {
        return "The request was not valid. Reload the list and try again.";
    }
    if (slug == "rate-limited") {
        if (problem.retryAfterSeconds) {
            return "Too many requests. Try again in " + std::to_string(*problem.retryAfterSeconds) + " seconds.";
        }
        return "Too many requests. Try again in a moment.";
    }
    if (slug == "internal-error") {
        return "The server had a problem. Try again later and give the trace id to support.";
    }
    if (!problem.title.empty()) {
        return problem.title;
    }
    return "The request failed (status " + std::to_string(problem.status) + ").";
}

}  // namespace tt
```
The rule: the **`type`** of a problem (its last path segment, the "slug") is the stable identifier, so it selects the sentence. The `title` is only the fallback for types this version of the app does not know, and a friendly sentence never contains server text that could be misleading. Network, parse and cancelled problems have no type, so the `kind` decides. The sentences follow the platform's table of problem types (`bad-request`, `unauthorized`, `forbidden`, `not-found`, `conflict`, `precondition-failed`, `validation-error`, `precondition-required`, `rate-limited`, `internal-error`). A 429 shows the `Retry-After` seconds that `problemFromResponse` parsed in chapter 02.

### Step 2. Replace `src/state/AppState.hpp`
**File: `src/state/AppState.hpp`**
```cpp
#pragma once

#include "api/Models.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace tt {

enum class AuthPhase { SignedOut, SigningIn, SignedIn };
enum class LoadPhase { Idle, Loading, Ready, Failed };

inline constexpr std::array<const char*, 3> kSorts{"-createdAt", "createdAt", "dueDate"};

// A list that is loaded page by page. Every request gets an id from begin(); finish() applies an answer
// only when its id is still the newest, so a slow answer for an old filter can never overwrite a newer list.
template <class T>
struct PagedList {
    LoadPhase phase{LoadPhase::Idle};
    std::vector<T> items;
    std::optional<std::string> nextCursor;
    std::optional<Problem> error;
    std::uint64_t generation{0};

    // Starts a request and returns its id. A fresh load (`reset`) empties the list, "load more" keeps it.
    std::uint64_t begin(bool reset) {
        ++generation;
        phase = LoadPhase::Loading;
        error.reset();
        if (reset) {
            items.clear();
            nextCursor.reset();
        }
        return generation;
    }

    // Applies the answer of request `id`. Returns false when a newer request has started: the answer is dropped.
    bool finish(std::uint64_t id, Result<Page<T>> result) {
        if (id != generation) {
            return false;
        }
        if (!result) {
            phase = LoadPhase::Failed;
            error = std::move(result.error());
            return true;
        }
        items.insert(items.end(), std::make_move_iterator(result->items.begin()),
                     std::make_move_iterator(result->items.end()));
        nextCursor = std::move(result->nextCursor);
        phase = LoadPhase::Ready;
        return true;
    }

    // Empties the list and makes every answer that is still on its way stale.
    void clear() {
        ++generation;
        phase = LoadPhase::Idle;
        items.clear();
        nextCursor.reset();
        error.reset();
    }
};

// Copies text into a fixed buffer for Dear ImGui's InputText. The buffers below are large enough for the
// contract's limits even when every character takes four bytes, so a value from the server is never cut.
template <std::size_t N>
void copyInto(std::array<char, N>& buffer, const std::string& text) {
    buffer.fill('\0');
    std::copy_n(text.begin(), std::min(text.size(), N - 1), buffer.begin());
}

template <std::size_t N>
[[nodiscard]] int indexOf(const std::array<const char*, N>& values, const std::string& wanted) {
    for (std::size_t i = 0; i < N; ++i) {
        if (wanted == values[i]) {
            return static_cast<int>(i);
        }
    }
    return 0;
}

// The create and edit dialog. `original` is the task as the server sent it; the patch holds only what differs.
struct TaskForm {
    bool open{false};
    bool creating{true};
    bool saving{false};
    std::string taskId;
    int baseVersion{0};
    std::string idempotencyKey;  // made when the form opens, so every retry of one form carries the same key
    std::array<char, 801> title{};          // 200 characters, up to 4 bytes each, and the terminator
    std::array<char, 40'001> description{};  // 10000 characters
    std::array<char, 11> dueDate{};          // YYYY-MM-DD
    int status{0};
    int priority{1};
    Task original;
    std::vector<FieldError> errors;  // client-side and 422 answers, matched to fields by JSON Pointer

    [[nodiscard]] TaskCreate toCreate() const {
        TaskCreate task;
        task.title = title.data();
        task.description = description.data();
        task.priority = kPriorities[static_cast<std::size_t>(priority)];
        if (dueDate[0] != '\0') {
            task.dueDate = std::string{dueDate.data()};
        }
        return task;
    }

    // RFC 7396 JSON Merge Patch: absent members stay as they are, null clears.
    [[nodiscard]] nlohmann::json makePatch() const {
        nlohmann::json patch = nlohmann::json::object();
        if (const std::string value{title.data()}; value != original.title) {
            patch["title"] = value;
        }
        if (const std::string value{description.data()}; value != original.description) {
            patch["description"] = value;
        }
        if (const std::string value{kStatuses[static_cast<std::size_t>(status)]}; value != original.status) {
            patch["status"] = value;
        }
        if (const std::string value{kPriorities[static_cast<std::size_t>(priority)]}; value != original.priority) {
            patch["priority"] = value;
        }
        if (const std::string value{dueDate.data()}; value != original.dueDate.value_or("")) {
            patch["dueDate"] = value.empty() ? nlohmann::json(nullptr) : nlohmann::json(value);
        }
        return patch;
    }
};

// The user's edit that the server refused with 412, kept so that "Keep my change" can send it again.
struct Conflict {
    std::string taskId;
    std::string title;
    nlohmann::json patch;
};

// Plain data that the UI draws. Only the UI thread reads or writes it.
struct AppState {
    AuthPhase auth{AuthPhase::SignedOut};
    std::optional<Me> me;
    std::optional<Problem> notice;  // the last error, shown until dismissed

    PagedList<Team> teams;
    PagedList<Project> projects;
    PagedList<Task> tasks;
    std::string teamId;
    std::string projectId;

    std::array<bool, kStatuses.size()> statusFilter{};
    std::array<char, 101> search{};
    int sortIndex{0};

    TaskForm form;
    std::optional<Conflict> conflict;
    std::optional<Task> pendingDelete;

    // Forgets everything that belongs to the signed-in user. The list generations keep counting up,
    // so answers that are still on their way are recognised as stale and dropped.
    void clearSession() {
        me.reset();
        teams.clear();
        projects.clear();
        tasks.clear();
        teamId.clear();
        projectId.clear();
        form = TaskForm{};
        conflict.reset();
        pendingDelete.reset();
    }
};

}  // namespace tt
```
Everything the UI shows is here as plain data, and the file has no `#include` of Dear ImGui or SDL, so it can be unit-tested (chapter 05).
- **`PagedList<T>`** is the heart of "no stale answers": `begin()` increments `generation` and hands out the new number; the job carries that number; `finish(id, ...)` ignores an answer whose number is not the current generation. "Load more" calls `begin(false)`, which keeps the items and appends the next page; a new filter calls `begin(true)`, which empties the list. `clear()` also increments the generation, so a sign-out makes every answer on its way stale.
- **Buffers.** Dear ImGui edits `char` arrays. 200 characters can take 800 UTF-8 bytes, so the title buffer has 801 bytes, and the description buffer holds 10000 characters in 40001 bytes; a value from the server therefore never gets cut (a cut value would be written back by the next edit). The terminator takes the last byte.
- **`makePatch()`** compares each field with `original` and writes *only the differences*. The due date is the interesting case: an empty field where the server had a date becomes `"dueDate": null`, which in a Merge Patch means "clear it". Absent members are left alone, which is why a patch built from a stale copy cannot overwrite fields the user never touched.
- **`Conflict`** keeps the patch, so "Keep my change" can send it again against the newest version.
- `form.idempotencyKey` is made when the form opens, not when Save is pressed.

### Step 3. Replace `src/app/Controller.hpp`
**File: `src/app/Controller.hpp`**
```cpp
#pragma once

#include "api/ApiClient.hpp"
#include "auth/Session.hpp"
#include "core/Concurrency.hpp"
#include "core/Config.hpp"
#include "state/AppState.hpp"

#include <cstdint>
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

    // Session
    void signIn();
    void cancelSignIn();
    void signOut();
    void dismissNotice() { state_.notice.reset(); }

    // Lists. `more` appends the next page; otherwise the list restarts at page 1.
    void loadTeams(bool more);
    void selectTeam(const std::string& teamId);
    void loadProjects(bool more);
    void selectProject(const std::string& projectId);
    void loadTasks(bool more);

    // Task form, conflict and delete
    void openCreateForm();
    void openEditForm(const Task& task);
    void closeForm() { state_.form.open = false; }
    void saveForm();
    void keepMine();
    void dropConflict();
    void askDelete(const Task& task) { state_.pendingDelete = task; }
    void confirmDelete();
    void cancelDelete() { state_.pendingDelete.reset(); }

private:
    template <class Call, class Apply>
    void run(Call call, Apply apply);

    template <class T>
    void applyPage(PagedList<T>& list, std::uint64_t id, Result<Page<T>> result);

    void loadMe();
    void report(Problem problem);
    void onSignedIn(const Result<void>& result);
    void onSaved(Result<Task> result, const std::string& taskId, const nlohmann::json& patch);
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
The public functions are the vocabulary of the UI: the screens only ever call these.

### Step 4. Replace `src/app/Controller.cpp`
**File: `src/app/Controller.cpp`**
```cpp
#include "app/Controller.hpp"

#include "auth/Pkce.hpp"

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
    form.errors.clear();
    if (form.title[0] == '\0') {
        form.errors.push_back(FieldError{"/title", "Enter a title."});
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
Read it as five small patterns:
1. **`run(call, apply)`** (unchanged from chapter 03): the job computes on a worker, `apply` runs on the UI thread. The job lambdas capture *copies* (`projectId = state_.projectId`, `query`, `cursor`); a worker never reads `state_`, which the UI thread keeps changing.
2. **Paging.** `loadX(false)` restarts and `loadX(true)` appends. "Load more" is ignored while a load is running or when there is no cursor. The cursor is copied from the previous page and never inspected.
3. **Stale answers.** `begin()` returns an id and the apply lambda captures it; `applyPage` hands it to `finish`, which drops an answer whose id is no longer current. This is the answer to the prediction about two quick team clicks.
4. **Create and edit.** `saveForm` first checks the form; `form.saving` blocks a second Save while a request is running, *and* the idempotency key made when the form opened would make a repeated POST harmless even if one got through. An edit sends only `makePatch()`; an empty patch closes the form without a request. `onSaved` is the single place that turns the answer into UI state: success closes the form and reloads the list; **412** keeps the user's patch in a `Conflict` and closes the form so that the conflict dialog is the only modal; **422** puts the `errors[]` array on the form, where the fields find their messages by JSON Pointer; anything else goes to `report`.
5. **Keep my change** (`keepMine`) runs *two* requests in one job: `GET` the task to learn the current `version`, then `PATCH` the same merge patch with `If-Match` set to that new version. `std::exchange` moves the pending conflict out of the state in one step, so a second click cannot start a second resend. A second 412 (someone changed it again) re-opens the dialog.

`report` is still the only place that decides what a 401 means.

### Step 5. Replace `src/ui/Screens.cpp`
**File: `src/ui/Screens.cpp`**
```cpp
#include "ui/Screens.hpp"

#include "app/Controller.hpp"
#include "core/ProblemText.hpp"

#include <imgui.h>

#include <algorithm>
#include <string>

namespace tt::ui {
namespace {

constexpr ImVec4 kErrorColour{1.0F, 0.60F, 0.60F, 1.0F};

// Sizes are multiples of the font size, so they follow the display scale.
float em(float factor) { return ImGui::GetFontSize() * factor; }

// A modal dialog that opens when `wanted` becomes true and closes when it becomes false.
template <class Body>
void drawModal(const char* name, bool wanted, Body body) {
    if (wanted && !ImGui::IsPopupOpen(name)) {
        ImGui::OpenPopup(name);
    }
    if (ImGui::BeginPopupModal(name, nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        if (wanted) {
            body();
        } else {
            ImGui::CloseCurrentPopup();
        }
        ImGui::EndPopup();
    }
}

void append(std::string& line, const std::string& part) {
    if (part.empty()) {
        return;
    }
    if (!line.empty()) {
        line += ", ";
    }
    line += part;
}

std::string technicalLine(const Problem& problem) {
    std::string line;
    append(line, problem.status != 0 ? "status " + std::to_string(problem.status) : std::string{});
    append(line, problem.type.empty() ? std::string{} : "type " + problemSlug(problem));
    append(line, problem.traceId.empty() ? std::string{} : "trace id " + problem.traceId);
    return line;
}

std::string roleIn(const std::optional<Me>& me, const std::string& teamId) {
    if (me) {
        for (const auto& team : me->teams) {
            if (team.teamId == teamId) {
                return team.role;
            }
        }
    }
    return {};
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

// A friendly sentence first, the technical members below it, then the invalid fields.
void drawNotice(Controller& controller) {
    const auto& notice = controller.state().notice;
    if (!notice) {
        return;
    }
    ImGui::Separator();
    ImGui::TextColored(kErrorColour, "Problem: %s", userMessage(*notice).c_str());
    const std::string technical = technicalLine(*notice);
    if (!technical.empty()) {
        ImGui::TextDisabled("%s", technical.c_str());
    }
    if (!notice->detail.empty()) {
        ImGui::TextWrapped("%s", notice->detail.c_str());
    }
    for (const auto& error : notice->errors) {
        ImGui::BulletText("%s: %s", error.pointer.c_str(), error.detail.c_str());
    }
    if (ImGui::Button("Dismiss")) {
        controller.dismissNotice();
    }
}

void drawNav(Controller& controller) {
    AppState& state = controller.state();
    ImGui::SeparatorText("Teams");
    for (const auto& team : state.teams.items) {
        ImGui::PushID(team.id.c_str());
        const std::string role = roleIn(state.me, team.id);
        const std::string label = team.name + (role.empty() ? "" : " (" + role + ")");
        if (ImGui::Selectable(label.c_str(), team.id == state.teamId)) {
            controller.selectTeam(team.id);
        }
        ImGui::PopID();
    }
    if (state.teams.phase == LoadPhase::Loading) {
        ImGui::TextDisabled("Loading teams...");
    } else if (state.teams.phase == LoadPhase::Ready && state.teams.items.empty()) {
        ImGui::TextDisabled("You are not in any team yet.");
    } else if (state.teams.nextCursor && ImGui::Button("More teams")) {
        controller.loadTeams(true);
    }

    if (state.teamId.empty()) {
        return;
    }
    ImGui::SeparatorText("Projects");
    for (const auto& project : state.projects.items) {
        ImGui::PushID(project.id.c_str());
        const std::string label = project.key + "  " + project.name;
        if (ImGui::Selectable(label.c_str(), project.id == state.projectId)) {
            controller.selectProject(project.id);
        }
        ImGui::PopID();
    }
    if (state.projects.phase == LoadPhase::Loading) {
        ImGui::TextDisabled("Loading projects...");
    } else if (state.projects.phase == LoadPhase::Ready && state.projects.items.empty()) {
        ImGui::TextDisabled("This team has no projects.");
    } else if (state.projects.nextCursor && ImGui::Button("More projects")) {
        controller.loadProjects(true);
    }
}

void drawTasks(Controller& controller) {
    AppState& state = controller.state();
    if (state.projectId.empty()) {
        ImGui::TextDisabled("Choose a team and a project on the left.");
        return;
    }

    bool filtersChanged = false;
    for (std::size_t i = 0; i < kStatuses.size(); ++i) {
        if (i != 0) {
            ImGui::SameLine();
        }
        filtersChanged |= ImGui::Checkbox(kStatuses[i], &state.statusFilter[i]);
    }
    ImGui::SetNextItemWidth(em(14.0F));
    filtersChanged |= ImGui::InputTextWithHint("##search", "title contains, Enter", state.search.data(),
                                               state.search.size(), ImGuiInputTextFlags_EnterReturnsTrue);
    ImGui::SameLine();
    ImGui::SetNextItemWidth(em(10.0F));
    filtersChanged |= ImGui::Combo("sort", &state.sortIndex, kSorts.data(), static_cast<int>(kSorts.size()));
    if (filtersChanged) {
        controller.loadTasks(false);
    }
    if (ImGui::Button("New task")) {
        controller.openCreateForm();
    }
    ImGui::SameLine();
    if (ImGui::Button("Reload")) {
        controller.loadTasks(false);
    }

    const float height = std::max(ImGui::GetContentRegionAvail().y - ImGui::GetFrameHeightWithSpacing() * 2.0F, em(6.0F));
    constexpr ImGuiTableFlags kTableFlags =
        ImGuiTableFlags_RowBg | ImGuiTableFlags_Borders | ImGuiTableFlags_Resizable | ImGuiTableFlags_ScrollY;
    if (ImGui::BeginTable("tasks", 6, kTableFlags, ImVec2{0.0F, height})) {
        ImGui::TableSetupScrollFreeze(0, 1);
        ImGui::TableSetupColumn("Title", ImGuiTableColumnFlags_WidthStretch, 3.0F);
        ImGui::TableSetupColumn("Status");
        ImGui::TableSetupColumn("Priority");
        ImGui::TableSetupColumn("Due");
        ImGui::TableSetupColumn("Version");
        ImGui::TableSetupColumn("Actions");
        ImGui::TableHeadersRow();
        for (const auto& task : state.tasks.items) {
            ImGui::PushID(task.id.c_str());
            ImGui::TableNextRow();
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(task.title.c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(task.status.c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(task.priority.c_str());
            ImGui::TableNextColumn();
            ImGui::TextUnformatted(task.dueDate ? task.dueDate->c_str() : "-");
            ImGui::TableNextColumn();
            ImGui::Text("%d", task.version);
            ImGui::TableNextColumn();
            if (ImGui::SmallButton("Edit")) {
                controller.openEditForm(task);
            }
            ImGui::SameLine();
            if (ImGui::SmallButton("Delete")) {
                controller.askDelete(task);
            }
            ImGui::PopID();
        }
        ImGui::EndTable();
    }

    if (state.tasks.phase == LoadPhase::Loading) {
        ImGui::TextDisabled("Loading tasks...");
    } else if (state.tasks.phase == LoadPhase::Ready && state.tasks.items.empty()) {
        ImGui::TextDisabled("No tasks match.");
    } else if (state.tasks.nextCursor && ImGui::Button("More tasks")) {
        controller.loadTasks(true);
    }
}

void drawFieldError(const TaskForm& form, const char* pointer) {
    for (const auto& error : form.errors) {
        if (error.pointer == pointer) {
            ImGui::TextColored(kErrorColour, "%s", error.detail.c_str());
        }
    }
}

void drawForm(Controller& controller) {
    TaskForm& form = controller.state().form;
    drawModal("Task", form.open, [&] {
        ImGui::TextUnformatted(form.creating ? "New task" : "Edit task");
        ImGui::SetNextItemWidth(em(32.0F));
        ImGui::InputText("Title", form.title.data(), form.title.size());
        drawFieldError(form, "/title");
        ImGui::InputTextMultiline("Description", form.description.data(), form.description.size(),
                                  ImVec2{em(32.0F), em(8.0F)});
        drawFieldError(form, "/description");
        ImGui::BeginDisabled(form.creating);
        ImGui::Combo("Status", &form.status, kStatuses.data(), static_cast<int>(kStatuses.size()));
        ImGui::EndDisabled();
        ImGui::Combo("Priority", &form.priority, kPriorities.data(), static_cast<int>(kPriorities.size()));
        ImGui::InputTextWithHint("Due date", "YYYY-MM-DD", form.dueDate.data(), form.dueDate.size());
        drawFieldError(form, "/dueDate");
        ImGui::Separator();
        ImGui::BeginDisabled(form.saving);
        if (ImGui::Button("Save")) {
            controller.saveForm();
        }
        ImGui::EndDisabled();
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) {
            controller.closeForm();
        }
        if (form.saving) {
            ImGui::SameLine();
            ImGui::TextUnformatted("Saving...");
        }
    });
}

void drawConflict(Controller& controller) {
    const AppState& state = controller.state();
    drawModal("Conflict", state.conflict.has_value() && !state.form.open, [&] {
        ImGui::TextWrapped("Someone else changed \"%s\" while you were editing it.", state.conflict->title.c_str());
        ImGui::TextWrapped("Keep my change: load the current version and send my change again. Reload: drop my change.");
        if (ImGui::Button("Keep my change")) {
            controller.keepMine();
        }
        ImGui::SameLine();
        if (ImGui::Button("Reload")) {
            controller.dropConflict();
        }
    });
}

void drawDelete(Controller& controller) {
    const AppState& state = controller.state();
    drawModal("Delete task", state.pendingDelete.has_value(), [&] {
        ImGui::TextWrapped("Delete \"%s\"? This cannot be undone.", state.pendingDelete->title.c_str());
        if (ImGui::Button("Delete")) {
            controller.confirmDelete();
        }
        ImGui::SameLine();
        if (ImGui::Button("Keep")) {
            controller.cancelDelete();
        }
    });
}

void drawWorkspace(Controller& controller) {
    if (ImGui::BeginChild("nav", ImVec2{em(22.0F), 0.0F}, ImGuiChildFlags_Borders)) {
        drawNav(controller);
    }
    ImGui::EndChild();
    ImGui::SameLine();
    if (ImGui::BeginChild("tasks-pane", ImVec2{0.0F, 0.0F}, ImGuiChildFlags_Borders)) {
        drawTasks(controller);
    }
    ImGui::EndChild();
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
        switch (controller.state().auth) {
            case AuthPhase::SignedOut:
                ImGui::TextWrapped("Sign in to see your teams. The sign-in page opens in your web browser; this app never "
                                   "sees your password.");
                break;
            case AuthPhase::SigningIn:
                ImGui::TextWrapped("Finish signing in in your web browser, then come back to this window.");
                break;
            case AuthPhase::SignedIn:
                drawWorkspace(controller);
                break;
        }
        drawForm(controller);
        drawConflict(controller);
        drawDelete(controller);
    }
    ImGui::End();
}

}  // namespace tt::ui
```
Immediate-mode patterns used here:
- **Every frame the whole UI is rebuilt from the state.** A button returns `true` on the frame it is clicked and the click handler is the `if` around it. `PushID(task.id)` gives each row's buttons a unique identity (several rows have an "Edit" button).
- **Modals.** `drawModal` opens the popup when the state says it should be open and closes it when the state says it should not. The *state* decides, not the widget: when a save succeeds, the controller sets `form.open = false` and the dialog disappears on the next frame. All popups are drawn inside the main window so that `OpenPopup` and `BeginPopupModal` see the same ID scope. Only one is wanted at a time (the conflict dialog waits until the form is closed).
- **Filters** reload when a widget reports a change; the search box reloads on Enter (`ImGuiInputTextFlags_EnterReturnsTrue`), not on every key.
- **Loading, empty and error states** are visible: "Loading teams...", "No tasks match.", and a failed load puts the problem in the banner.
- **Accessibility (D-25).** Keyboard navigation was switched on in chapter 01: Tab moves between widgets, Space or Enter presses a button. Sizes are multiples of the font size, so a larger display scale enlarges everything. Status and priority are *words* in the table; red is only an extra cue. **Dear ImGui does not expose an accessibility tree**, so a screen reader cannot read these widgets; if that matters for your users, a native toolkit is the right choice (the web and mobile clients in Code101 have screen-reader support).
- **Untrusted text** goes through `TextUnformatted` or `"%s"`, never as the format string.

### Step 6. Unchanged files
All other files are identical to chapter 03 (see "What is new, what is unchanged").

## Run it
**For a later session only; this snapshot has not been run.** Platform, backend and the `tasks-desktop` client must be running.

**Command (Windows, PowerShell):**
```powershell
cmake --preset windows
cmake --build --preset windows-debug
.\build\windows\out\tasks_desktop.exe
```
(Linux and macOS: the matching presets and path.) Typical manual run, signed in as `carol`:
1. After sign-in the left pane shows **Mobile Team (lead)**. Click it: projects appear (seed project key `MOB`); click the project: the task table fills.
2. Tick a status filter (for example `todo`): the table reloads with only those tasks. Change the sort combo to `dueDate`.
3. **New task**: leave the title empty and press Save: "Enter a title." appears next to the field and no request is sent. Type a title, double-click Save quickly: one task appears.
4. **Edit** a task, change only the priority, Save: the version column goes up by one. Clear the due date of a task that has one and Save: the date shows as `-` (the request carried `"dueDate": null`; with `SPDLOG_LEVEL=debug` you see `PATCH ... -> 200`).
5. **Conflict.** Start a second copy of the app, edit the same task in both. Save in the first, then in the second: the second shows the conflict dialog. "Keep my change" sends your change again on top of the first copy's version; "Reload" drops it.
6. **422.** Type `2026-13-45` as due date and Save: the backend answers 422 and the message appears next to "Due date" (typical wording from the backend; the pointer is `/dueDate`).
7. **Delete** a task (as a team lead) and confirm. As a non-lead the backend answers 403 and the banner says "You are not allowed to do this."
8. **Backend stopped**: Reload shows the banner "Cannot reach the server..." while the window stays responsive.
9. Close the window while a list is loading: the process ends within the request timeout (10 seconds at most, usually immediately).

## How it works
- **Prediction answers.** (1) The second team's projects: the first answer carries an old generation number, `finish` returns false and it is dropped. (2) One task: the first Save sets `saving`, the Save button is disabled, and even a second POST would carry the same `Idempotency-Key`, so the backend would replay the first response instead of creating another task. (3) The progress callback in the transport sees the stop token, aborts the transfer (`Cancelled`), the job finishes, and the `Worker` joins its threads while `Controller` is destroyed.
- **One thread owns the state.** The UI thread alone reads and writes `AppState`. Jobs get *copies* of what they need; results come back as closures. There is no lock around `AppState` because there is no sharing, which is the simplest correct design for a GUI.
- **Why a generation instead of cancelling.** Cancelling a request that has already been answered is a race. A number that says "I am the newest" is a fact that can be checked on the UI thread after the fact, and it also handles "the user selected something else" and "signed out" with the same code.
- **Optimistic concurrency, seen from the client.** The task row remembers the `version` it showed; Save sends it in `If-Match`; 412 means somebody else saved first. The merge patch is why "Keep my change" is safe: it carries only your edits, not a whole copy of the old task.
- **Error handling in one place.** Controllers call `report` for anything that is not a field error or a conflict, so every error looks the same and nothing is shown twice.
- **Shutdown (D-20).** `Controller` is destroyed first (last member of `App`). Its `Worker` requests stop on every thread; waiting threads wake up; running requests abort through the progress callback; the sign-in wait notices the stop within 100 ms. Threads are joined, then the queue, state, session and transport are destroyed. Pending jobs that never started are dropped.

## Try it
Add messages for two problems that the platform describes in section 12.1 of its TDD. One file: `src/core/ProblemText.hpp`.

Where: the `code` folder.

**Command (Windows, PowerShell):**
```powershell
Copy-Item ..\exercise\starter\src\core\ProblemText.hpp src\core\ProblemText.hpp -Force
```
**Command (macOS and Linux):**
```bash
cp ../exercise/starter/src/core/ProblemText.hpp src/core/ProblemText.hpp
```
**File: `../exercise/starter/src/core/ProblemText.hpp`**
```cpp
#pragma once

#include "core/Result.hpp"

#include <string>

namespace tt {

// Exercise: platform TDD section 12.1 says that a body over 1 MiB gets a 413 problem whose `type` ends with
// `payload-too-large`, and that a database outage gives a 503 with `Retry-After`.
// Rung 1 (guided): add a message for the slug "payload-too-large".
// Rung 2 (partial): add a message for status 503 whatever the slug is (the type name is not fixed by the contract);
//   when `retryAfterSeconds` has a value, say how many seconds.
// Rung 3 (open): the contract says 5xx and network errors are retryable. Where would a "Retry" button go,
//   and which problems would show it? Sketch it; do not build it.
[[nodiscard]] inline std::string userMessage(const Problem& problem) {
    switch (problem.kind) {
        case ErrorKind::Network:
            return "Cannot reach the server. Check that the backend is running and that the address is right.";
        case ErrorKind::Parse:
            return "The server sent an answer this app does not understand.";
        case ErrorKind::Cancelled:
            return "Cancelled.";
        case ErrorKind::Auth:
        case ErrorKind::Config:
            return problem.title;
        case ErrorKind::Http:
            break;
    }
    const std::string slug = problemSlug(problem);
    if (slug == "unauthorized") {
        return "Your session has ended. Sign in again.";
    }
    if (slug == "forbidden") {
        return "You are not allowed to do this.";
    }
    if (slug == "not-found") {
        return "This item no longer exists, or you cannot see it.";
    }
    if (slug == "conflict") {
        return "This conflicts with existing data, for example a duplicate name.";
    }
    if (slug == "precondition-failed") {
        return "Someone else changed this item. Reload it and try again.";
    }
    if (slug == "precondition-required") {
        return "The app did not send the version it was editing. This is a bug; please report it.";
    }
    if (slug == "validation-error") {
        return "Some fields are not valid. See the messages next to them.";
    }
    if (slug == "bad-request") {
        return "The request was not valid. Reload the list and try again.";
    }
    // TODO rung 1: slug "payload-too-large"
    // TODO rung 2: status 503
    if (slug == "rate-limited") {
        if (problem.retryAfterSeconds) {
            return "Too many requests. Try again in " + std::to_string(*problem.retryAfterSeconds) + " seconds.";
        }
        return "Too many requests. Try again in a moment.";
    }
    if (slug == "internal-error") {
        return "The server had a problem. Try again later and give the trace id to support.";
    }
    if (!problem.title.empty()) {
        return problem.title;
    }
    return "The request failed (status " + std::to_string(problem.status) + ").";
}

}  // namespace tt
```
<details><summary>Solution (rungs 1 and 2; rung 3 is a sketch)</summary>

**File: `../exercise/solution/src/core/ProblemText.hpp`**
```cpp
#pragma once

#include "core/Result.hpp"

#include <string>

namespace tt {

// The friendly sentence for a problem. The technical members (status, type, trace id) are shown on a second line.
[[nodiscard]] inline std::string userMessage(const Problem& problem) {
    switch (problem.kind) {
        case ErrorKind::Network:
            return "Cannot reach the server. Check that the backend is running and that the address is right.";
        case ErrorKind::Parse:
            return "The server sent an answer this app does not understand.";
        case ErrorKind::Cancelled:
            return "Cancelled.";
        case ErrorKind::Auth:
        case ErrorKind::Config:
            return problem.title;
        case ErrorKind::Http:
            break;
    }
    const std::string slug = problemSlug(problem);
    if (slug == "unauthorized") {
        return "Your session has ended. Sign in again.";
    }
    if (slug == "forbidden") {
        return "You are not allowed to do this.";
    }
    if (slug == "not-found") {
        return "This item no longer exists, or you cannot see it.";
    }
    if (slug == "conflict") {
        return "This conflicts with existing data, for example a duplicate name.";
    }
    if (slug == "precondition-failed") {
        return "Someone else changed this item. Reload it and try again.";
    }
    if (slug == "precondition-required") {
        return "The app did not send the version it was editing. This is a bug; please report it.";
    }
    if (slug == "validation-error") {
        return "Some fields are not valid. See the messages next to them.";
    }
    if (slug == "bad-request") {
        return "The request was not valid. Reload the list and try again.";
    }
    if (slug == "payload-too-large") {
        return "The text is too large to send. Shorten the description and try again.";
    }
    if (problem.status == 503) {
        if (problem.retryAfterSeconds) {
            return "The service is not ready. Try again in " + std::to_string(*problem.retryAfterSeconds) + " seconds.";
        }
        return "The service is not ready. Try again in a moment.";
    }
    if (slug == "rate-limited") {
        if (problem.retryAfterSeconds) {
            return "Too many requests. Try again in " + std::to_string(*problem.retryAfterSeconds) + " seconds.";
        }
        return "Too many requests. Try again in a moment.";
    }
    if (slug == "internal-error") {
        return "The server had a problem. Try again later and give the trace id to support.";
    }
    if (!problem.title.empty()) {
        return problem.title;
    }
    return "The request failed (status " + std::to_string(problem.status) + ").";
}

}  // namespace tt
```
The 503 test uses the *status*, because the contract's v1.1 notes fix the status and `Retry-After` but not the type name. Rung 3, a sketch: a "Retry" button in `drawNotice`, shown when `kind == Network` or the status is 502, 503 or 504, calling a `controller.retryLast()` that stores the last `run` call; it needs an upper limit and a backoff to stay polite.

</details>

## Check yourself
1. Why must a job not read `AppState`?
   <details><summary>Answer</summary>The UI thread changes it at any time; reading it from another thread is a data race. Jobs capture copies.</details>
2. What does `PagedList::finish` return when it drops an answer, and who benefits?
   <details><summary>Answer</summary>`false`. The caller then does nothing, so an old answer cannot overwrite a newer list or raise an error for a request nobody wants any more.</details>
3. Which three mechanisms prevent a duplicate task on a double click?
   <details><summary>Answer</summary>The disabled Save button (`saving`), the `saving` check in `saveForm`, and the `Idempotency-Key` that is the same for the whole form.</details>
4. Why does a patch with `"dueDate": null` clear the date but a patch without `dueDate` leaves it?
   <details><summary>Answer</summary>That is the JSON Merge Patch rule (RFC 7396): `null` means "remove", an absent member means "no change".</details>
5. What happens to jobs that are still queued when the window closes?
   <details><summary>Answer</summary>They are dropped; running jobs are asked to stop and aborted by the progress callback.</details>

## Common mistakes
| Symptom (typical message) | Cause | Fix |
|---|---|---|
| Window freezes on every click | a network call was made in a screen function instead of through the controller | call a `Controller` function; the controller uses `run` |
| Crash after sign-out | a lambda used `state_` data that was cleared | capture copies, apply through `report`/`applyPage`, which check state |
| A list shows old rows after a filter change | `begin(false)` instead of `begin(true)` | a new filter is a fresh load: `loadTasks(false)` resets |
| ImGui asserts about popups or IDs | `OpenPopup` and `BeginPopupModal` called in different windows or ID scopes | draw all modals inside the main window, as here |
| Every row's Edit button reacts together | missing `PushID` per row | `ImGui::PushID(task.id.c_str())` |
| 428 "precondition-required" | a PATCH without `If-Match` | always go through `ApiClient::updateTask` |
| Text from a long description looks cut | buffer too small for the server value | keep the buffer sizes from `TaskForm` |
| Link error `undefined reference` for `applyPage` | template defined in a header the `.cpp` does not see | keep it defined in `Controller.cpp` above its first use |

## Best practice
- Core Guidelines CP.2 (avoid data races), CP.3 (minimise sharing of writable data: here, none), CP.25 (prefer `std::jthread` and its stop token to ad hoc flags), CP.24 (think of a thread as a global container: give it exactly what it needs), CP.31 (pass small amounts of data by value between threads: copies, not references), F.16 (pass cheap values by value), ES.20 (always initialise an object), ES.45 (avoid magic numbers: buffer sizes are explained), I.4 (make interfaces precisely and strongly typed).
- UI state is data. A frame function that only reads state and calls commands is easy to reason about and easy to test.
- Show every failure in words and keep the technical details one line away.
- Never format untrusted text: Dear ImGui's `Text(fmt, ...)` is `printf`.

## Going further
- Add the contract's `complete` operation (`POST /v1/tasks/{id}/complete`) as a button; it also needs `If-Match`.
- Show the members of the selected team (`GET /v1/teams/{id}/members`) in a third pane, with its own `PagedList<Member>`.
- Add a "Retry" button for network and 5xx problems (rung 3 of the exercise) with a limited number of attempts.
- Measure: show the frame time while a list loads and check that it stays flat (take the measurement; none is claimed here).

## Summary
You have the full workflow of the app on top of a threading model with one rule (workers compute, the UI thread owns state), plus the four defences a client needs: stale-answer dropping, idempotent creates, conflict handling with `If-Match`, and problem details shown in words. Closing the window stops everything cleanly.

## Next lesson
[05. Hardening and packaging](../phase-5-ship/05-hardening-and-packaging.md): validate configuration and input, cap responses, log safely, test the pure logic with Catch2 and ship a release ZIP.
