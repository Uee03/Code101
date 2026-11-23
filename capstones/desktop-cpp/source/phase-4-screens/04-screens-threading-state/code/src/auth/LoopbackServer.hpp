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
