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
