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
