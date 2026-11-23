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
