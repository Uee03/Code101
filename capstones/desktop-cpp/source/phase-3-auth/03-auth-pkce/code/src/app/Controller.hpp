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
