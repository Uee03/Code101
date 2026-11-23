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
