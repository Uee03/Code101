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
