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
